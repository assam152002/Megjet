-- Customer requests are owned by the account; decisions are admin-only.
CREATE TABLE public.order_service_requests (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), order_id uuid NOT NULL REFERENCES public.orders(id),
 customer_user_id uuid NOT NULL REFERENCES auth.users(id), kind text NOT NULL CHECK(kind IN ('cancellation','refund')),
 reason text NOT NULL CHECK(length(reason) BETWEEN 3 AND 1000),
 status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','denied','completed')),
 amount numeric NOT NULL DEFAULT 0 CHECK(amount>=0),admin_note text NOT NULL DEFAULT '',
 created_at timestamptz NOT NULL DEFAULT now(),resolved_at timestamptz,
 UNIQUE(order_id,kind)
);
ALTER TABLE public.order_service_requests ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.order_service_requests FROM anon,authenticated;
GRANT SELECT ON public.order_service_requests TO authenticated;
CREATE POLICY "Own service requests" ON public.order_service_requests FOR SELECT TO authenticated
 USING(customer_user_id=(select auth.uid()) OR EXISTS(SELECT 1 FROM public.admin_users WHERE user_id=(select auth.uid())));
CREATE FUNCTION public.customer_request_order_service(p_order_id uuid,p_kind text,p_reason text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE o public.orders%ROWTYPE;r public.order_service_requests%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Customer sign-in required';END IF;
 SELECT * INTO o FROM public.orders WHERE id=p_order_id AND auth_user_id=auth.uid() FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Order not found in this account';END IF;
 IF p_kind NOT IN ('cancellation','refund') OR length(trim(coalesce(p_reason,''))) NOT BETWEEN 3 AND 1000 THEN RAISE EXCEPTION 'Choose a request type and enter a reason (3–1000 characters)';END IF;
 IF p_kind='cancellation' AND o.status IN ('delivered','cancelled') THEN RAISE EXCEPTION 'This order can no longer be cancelled';END IF;
 IF p_kind='refund' AND o.payment_status<>'paid' THEN RAISE EXCEPTION 'Only paid orders can have a refund request';END IF;
 INSERT INTO public.order_service_requests(order_id,customer_user_id,kind,reason)
 VALUES(o.id,auth.uid(),p_kind,trim(p_reason)) ON CONFLICT(order_id,kind) DO NOTHING;
 SELECT * INTO r FROM public.order_service_requests WHERE order_id=o.id AND kind=p_kind;
 RETURN to_jsonb(r);
END $$;
CREATE FUNCTION public.admin_resolve_order_service(p_request_id uuid,p_action text,p_amount numeric DEFAULT 0,p_note text DEFAULT '')
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r public.order_service_requests%ROWTYPE;o public.orders%ROWTYPE;
BEGIN
 PERFORM public.megjet_require_admin();
 -- Consistent lock order with customer requests, cancellation and payment verification.
 SELECT o1.* INTO o FROM public.orders o1 JOIN public.order_service_requests r1 ON r1.order_id=o1.id WHERE r1.id=p_request_id FOR UPDATE OF o1;
 SELECT * INTO r FROM public.order_service_requests WHERE id=p_request_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Request not found';END IF;
 IF length(coalesce(p_note,''))>1000 THEN RAISE EXCEPTION 'Note is too long';END IF;
 IF p_action='deny' AND r.status='pending' THEN
  UPDATE public.order_service_requests SET status='denied',admin_note=coalesce(p_note,''),resolved_at=now() WHERE id=r.id;
 ELSIF p_action='approve' AND r.status='pending' THEN
  IF r.kind='cancellation' THEN
   IF o.status='delivered' THEN RAISE EXCEPTION 'Delivered orders cannot be cancelled';END IF;
   IF o.status<>'cancelled' THEN UPDATE public.orders SET status='cancelled' WHERE id=o.id;END IF;
   UPDATE public.order_service_requests SET status='completed',admin_note=coalesce(p_note,''),resolved_at=now() WHERE id=r.id;
   IF o.payment_status='paid' THEN
    INSERT INTO public.order_service_requests(order_id,customer_user_id,kind,reason,amount,status)
    VALUES(o.id,r.customer_user_id,'refund','Paid order cancelled. Admin must return the payment.',o.total,'approved') ON CONFLICT(order_id,kind) DO NOTHING;
   END IF;
  ELSE
   IF o.payment_status<>'paid' OR p_amount IS NULL OR p_amount<=0 OR p_amount>o.total THEN RAISE EXCEPTION 'Refund amount must be greater than zero and no more than the paid order total';END IF;
   UPDATE public.order_service_requests SET status='approved',amount=p_amount,admin_note=coalesce(p_note,''),resolved_at=now() WHERE id=r.id;
  END IF;
 ELSIF p_action='complete' AND r.kind='refund' AND r.status='approved' THEN
  IF length(trim(coalesce(p_note,'')))<3 THEN RAISE EXCEPTION 'Enter the refund reference or receipt note';END IF;
  UPDATE public.order_service_requests SET status='completed',admin_note=p_note,resolved_at=now() WHERE id=r.id;
 ELSE RAISE EXCEPTION 'This request has already changed. Refresh before continuing';END IF;
 SELECT * INTO r FROM public.order_service_requests WHERE id=p_request_id;
 RETURN to_jsonb(r);
END $$;
-- Fix the existing pending-cancellation race: success only after a locked update.
CREATE OR REPLACE FUNCTION public.cancel_customer_order_account(p_order_id uuid)
RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE o public.orders%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Customer sign-in required';END IF;
 SELECT * INTO o FROM public.orders WHERE id=p_order_id AND auth_user_id=auth.uid() FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Order not found in this account';END IF;
 IF o.status<>'pending' THEN RAISE EXCEPTION 'Only Pending orders can be cancelled';END IF;
 UPDATE public.orders SET status='cancelled' WHERE id=o.id;
 IF o.payment_status='paid' THEN
  INSERT INTO public.order_service_requests(order_id,customer_user_id,kind,reason,amount,status)
  VALUES(o.id,auth.uid(),'refund','Paid pending order cancelled. Admin must return the payment.',o.total,'approved') ON CONFLICT(order_id,kind) DO NOTHING;
 END IF;
 RETURN json_build_object('success',true,'status','cancelled');
END $$;
CREATE TABLE public.megjet_delivery_coverage(
 id integer PRIMARY KEY CHECK(id=1),enabled boolean NOT NULL DEFAULT false,
 center_lat double precision CHECK(center_lat BETWEEN -90 AND 90),center_lng double precision CHECK(center_lng BETWEEN -180 AND 180),
 radius_m integer NOT NULL DEFAULT 10000 CHECK(radius_m BETWEEN 100 AND 100000),
 CHECK(NOT enabled OR (center_lat IS NOT NULL AND center_lng IS NOT NULL))
);
ALTER TABLE public.megjet_delivery_coverage ENABLE ROW LEVEL SECURITY;
INSERT INTO public.megjet_delivery_coverage(id) VALUES(1);
REVOKE ALL ON public.megjet_delivery_coverage FROM anon,authenticated;
GRANT SELECT ON public.megjet_delivery_coverage TO anon,authenticated;
CREATE POLICY "Public delivery coverage" ON public.megjet_delivery_coverage FOR SELECT TO anon,authenticated USING(true);
CREATE FUNCTION public.admin_save_delivery_coverage(p_enabled boolean,p_lat double precision,p_lng double precision,p_radius integer)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.megjet_require_admin();
 IF p_enabled IS NULL OR p_radius IS NULL OR p_radius NOT BETWEEN 100 AND 100000 OR (p_enabled AND (p_lat IS NULL OR p_lng IS NULL)) OR p_lat NOT BETWEEN -90 AND 90 OR p_lng NOT BETWEEN -180 AND 180 THEN RAISE EXCEPTION 'Enter a valid centre pin and radius (100–100000 metres)';END IF;
 UPDATE public.megjet_delivery_coverage SET enabled=p_enabled,center_lat=p_lat,center_lng=p_lng,radius_m=p_radius WHERE id=1;
END $$;
CREATE FUNCTION public.megjet_check_delivery_coverage(p_address text)
RETURNS void LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE c public.megjet_delivery_coverage%ROWTYPE;pin text[];lat double precision;lng double precision;
BEGIN
 SELECT * INTO c FROM public.megjet_delivery_coverage WHERE id=1;
 IF NOT c.enabled THEN RETURN;END IF;
 pin:=regexp_match(p_address,E'\\nMap pin: https://www\\.google\\.com/maps\\?q=(-?[0-9]+(?:\\.[0-9]+)?),(-?[0-9]+(?:\\.[0-9]+)?)[[:space:]]*$');
 IF pin IS NULL THEN RAISE EXCEPTION 'Mark your delivery address on the map';END IF;
 lat:=pin[1]::double precision;lng:=pin[2]::double precision;
 IF lat NOT BETWEEN -90 AND 90 OR lng NOT BETWEEN -180 AND 180 THEN RAISE EXCEPTION 'Choose a valid delivery location';END IF;
 IF public.megjet_distance_metres(lat,lng,c.center_lat,c.center_lng)>c.radius_m+0.000001 THEN RAISE EXCEPTION 'Delivery is not available at this location';END IF;
END $$;
CREATE FUNCTION public.megjet_enforce_delivery_coverage() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN PERFORM public.megjet_check_delivery_coverage(NEW.delivery_address);RETURN NEW;END $$;
CREATE TRIGGER megjet_enforce_delivery_coverage BEFORE INSERT OR UPDATE OF delivery_address ON public.orders FOR EACH ROW EXECUTE FUNCTION public.megjet_enforce_delivery_coverage();
CREATE FUNCTION public.admin_operations_report(p_from date DEFAULT NULL,p_to date DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.megjet_require_admin();
 IF p_from IS NOT NULL AND p_to IS NOT NULL AND p_to<p_from THEN RAISE EXCEPTION 'End date must follow start date';END IF;
 WITH selected AS(SELECT * FROM public.orders WHERE (p_from IS NULL OR (created_at AT TIME ZONE 'Europe/Nicosia')::date>=p_from) AND(p_to IS NULL OR (created_at AT TIME ZONE 'Europe/Nicosia')::date<=p_to)),
 delivered AS(SELECT * FROM selected WHERE status='delivered')
 SELECT jsonb_build_object(
 'delivered_orders',(SELECT count(*) FROM delivered),'order_revenue',(SELECT coalesce(sum(total),0) FROM delivered),
 'product_sales',(SELECT coalesce(sum(subtotal),0) FROM delivered),'delivery_fees',(SELECT coalesce(sum(delivery_fee),0) FROM delivered),
 'discounts',(SELECT coalesce(sum(discount_amount),0) FROM delivered),
 'bank_pending',(SELECT count(*) FROM selected WHERE payment_method='Bank Transfer' AND payment_status<>'paid' AND status<>'cancelled'),
 'bank_pending_amount',(SELECT coalesce(sum(total),0) FROM selected WHERE payment_method='Bank Transfer' AND payment_status<>'paid' AND status<>'cancelled'),
 'refund_pending',(SELECT count(*) FROM public.order_service_requests WHERE kind='refund' AND status IN('pending','approved')),
 'refunds_completed',(SELECT coalesce(sum(r.amount),0) FROM public.order_service_requests r JOIN selected o ON o.id=r.order_id WHERE r.kind='refund' AND r.status='completed'),
 'vendors',coalesce((SELECT jsonb_agg(v) FROM(SELECT i.vendor_id,max(i.vendor_name) name,sum(i.total_price) sales,count(DISTINCT i.order_id) orders FROM public.order_items i JOIN delivered o ON o.id=i.order_id GROUP BY i.vendor_id ORDER BY sum(i.total_price) DESC)v),'[]'::jsonb),
 'riders',coalesce((SELECT jsonb_agg(e) FROM(SELECT e.rider_id,max(r.name) name,coalesce(sum(e.amount) FILTER(WHERE e.status<>'paid'),0) unpaid,coalesce(sum(e.amount) FILTER(WHERE e.status='paid'),0) paid,count(*) deliveries FROM public.rider_earnings e JOIN delivered o ON o.id::text=e.order_id LEFT JOIN public.riders r ON r.id::text=e.rider_id GROUP BY e.rider_id)e),'[]'::jsonb)) INTO result;
 RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.customer_request_order_service(uuid,text,text),public.admin_resolve_order_service(uuid,text,numeric,text),public.admin_save_delivery_coverage(boolean,double precision,double precision,integer),public.admin_operations_report(date,date) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.customer_request_order_service(uuid,text,text),public.admin_resolve_order_service(uuid,text,numeric,text),public.admin_save_delivery_coverage(boolean,double precision,double precision,integer),public.admin_operations_report(date,date) TO authenticated;
REVOKE ALL ON FUNCTION public.megjet_check_delivery_coverage(text),public.megjet_enforce_delivery_coverage() FROM PUBLIC,anon,authenticated;
CREATE INDEX order_service_requests_customer ON public.order_service_requests(customer_user_id);
CREATE INDEX order_service_requests_queue ON public.order_service_requests(status,created_at);

CREATE OR REPLACE FUNCTION public.quote_nearby_delivery(p_items jsonb,p_delivery_address text)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE s public.megjet_delivery_tiers%ROWTYPE;pin text[];lat double precision;lng double precision;vendors integer;pinned integer;distance double precision;items_count integer;found_count integer;price numeric;tier text;
BEGIN
 PERFORM public.megjet_check_delivery_coverage(p_delivery_address);
 SELECT * INTO s FROM public.megjet_delivery_tiers WHERE id=1;
 IF p_items IS NULL OR jsonb_typeof(p_items)<>'array' THEN RAISE EXCEPTION 'Invalid cart'; END IF;
 items_count:=jsonb_array_length(p_items);
 IF items_count<1 OR items_count>100 THEN RETURN jsonb_build_object('fee',s.first_fee,'nearby',false,'reason','cart'); END IF;
 pin:=regexp_match(p_delivery_address,E'\\nMap pin: https://www\\.google\\.com/maps\\?q=(-?[0-9]+(?:\\.[0-9]+)?),(-?[0-9]+(?:\\.[0-9]+)?)[[:space:]]*$');
 IF pin IS NULL THEN RETURN jsonb_build_object('fee',s.first_fee,'nearby',false,'reason','address_pin'); END IF;
 lat:=pin[1]::double precision;lng:=pin[2]::double precision;
 IF lat NOT BETWEEN -90 AND 90 OR lng NOT BETWEEN -180 AND 180 THEN RETURN jsonb_build_object('fee',s.first_fee,'nearby',false,'reason','address_pin'); END IF;
 SELECT count(*) INTO found_count FROM jsonb_array_elements(p_items) i JOIN public.products p ON p.id=(i->>'product_id')::uuid;
 IF found_count<>items_count THEN RETURN jsonb_build_object('fee',s.first_fee,'nearby',false,'reason','cart'); END IF;
 SELECT count(*),count(pin.vendor_id),max(public.megjet_distance_metres(lat,lng,pin.latitude::double precision,pin.longitude::double precision))
 INTO vendors,pinned,distance
 FROM (SELECT DISTINCT p.vendor_id FROM jsonb_array_elements(p_items) i JOIN public.products p ON p.id=(i->>'product_id')::uuid) v LEFT JOIN public.vendor_pickup_pins pin ON pin.vendor_id=v.vendor_id;
 IF vendors=0 OR pinned<vendors THEN RETURN jsonb_build_object('fee',s.first_fee,'nearby',false,'reason','vendor_pin'); END IF;
 IF s.near_enabled AND distance<=s.near_radius+0.000001 THEN price:=s.near_fee;tier:='nearby';
 ELSIF distance<=s.first_radius+0.000001 THEN price:=s.first_fee;tier:='first';
 ELSIF distance<=s.second_radius+0.000001 THEN price:=s.second_fee;tier:='second';
 ELSE price:=s.far_fee;tier:='far'; END IF;
 RETURN jsonb_build_object('fee',price,'nearby',tier='nearby','reason','distance','tier',tier,'radius',CASE tier WHEN 'nearby' THEN s.near_radius WHEN 'first' THEN s.first_radius WHEN 'second' THEN s.second_radius ELSE null END);
END;
$$;
