-- Fee quotes expose prices only; pickup coordinates remain behind existing access controls.
CREATE OR REPLACE FUNCTION public.megjet_distance_metres(a_lat double precision,a_lng double precision,b_lat double precision,b_lng double precision)
RETURNS double precision LANGUAGE sql IMMUTABLE SECURITY INVOKER SET search_path='' AS $$
 SELECT 2*6371000*asin(least(1.0,sqrt(power(sin(radians(b_lat-a_lat)/2),2)+cos(radians(a_lat))*cos(radians(b_lat))*power(sin(radians(b_lng-a_lng)/2),2))));
$$;
CREATE OR REPLACE FUNCTION public.quote_nearby_delivery(p_items jsonb,p_delivery_address text)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE standard numeric:=public.get_delivery_fee();pin text[];lat double precision;lng double precision;vendors integer;pinned integer;nearby integer;items_count integer;found_count integer;
BEGIN
 IF p_items IS NULL OR jsonb_typeof(p_items)<>'array' THEN RAISE EXCEPTION 'Invalid cart'; END IF;
 items_count:=jsonb_array_length(p_items);
 IF items_count<1 OR items_count>100 THEN RETURN jsonb_build_object('fee',standard,'nearby',false,'reason','cart','radius',25); END IF;
 pin:=regexp_match(p_delivery_address,E'\\nMap pin: https://www\\.google\\.com/maps\\?q=(-?[0-9]+(?:\\.[0-9]+)?),(-?[0-9]+(?:\\.[0-9]+)?)[[:space:]]*$');
 IF pin IS NULL THEN RETURN jsonb_build_object('fee',standard,'nearby',false,'reason','address_pin','radius',25); END IF;
 lat:=pin[1]::double precision;lng:=pin[2]::double precision;
 IF lat NOT BETWEEN -90 AND 90 OR lng NOT BETWEEN -180 AND 180 THEN RETURN jsonb_build_object('fee',standard,'nearby',false,'reason','address_pin','radius',25); END IF;
 SELECT count(*) INTO found_count FROM jsonb_array_elements(p_items) i JOIN public.products p ON p.id=(i->>'product_id')::uuid;
 IF found_count<>items_count THEN RETURN jsonb_build_object('fee',standard,'nearby',false,'reason','cart','radius',25); END IF;
 SELECT count(*),count(pin.vendor_id),count(*) FILTER(WHERE public.megjet_distance_metres(lat,lng,pin.latitude::double precision,pin.longitude::double precision)<=25.0)
 INTO vendors,pinned,nearby
 FROM (SELECT DISTINCT p.vendor_id FROM jsonb_array_elements(p_items) i JOIN public.products p ON p.id=(i->>'product_id')::uuid) v
 LEFT JOIN public.vendor_pickup_pins pin ON pin.vendor_id=v.vendor_id;
 IF vendors>0 AND pinned=vendors AND nearby=vendors THEN RETURN jsonb_build_object('fee',least(standard,50),'nearby',true,'reason','nearby','radius',25); END IF;
 RETURN jsonb_build_object('fee',standard,'nearby',false,'reason',CASE WHEN pinned<vendors THEN 'vendor_pin' ELSE 'distance' END,'radius',25);
END;
$$;
REVOKE ALL ON FUNCTION public.quote_nearby_delivery(jsonb,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.quote_nearby_delivery(jsonb,text) TO anon,authenticated;

CREATE OR REPLACE FUNCTION public.create_customer_order(p_order_id uuid, p_customer_name text, p_customer_phone text, p_delivery_address text, p_payment_method text, p_coupon_code text DEFAULT NULL::text, p_items jsonb DEFAULT '[]'::jsonb)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
 SET row_security TO 'off'
AS $function$
DECLARE
item jsonb;
v_subtotal numeric := 0;
v_discount numeric := 0;
v_total numeric := 0;
v_delivery numeric := 0;
v_count integer := 0;
BEGIN
IF p_order_id IS NULL THEN
RAISE EXCEPTION 'Invalid order ID';
END IF;
IF NULLIF(trim(p_customer_name),'') IS NULL
OR NULLIF(trim(p_customer_phone),'') IS NULL
OR NULLIF(trim(p_delivery_address),'') IS NULL THEN
RAISE EXCEPTION 'Name, phone and delivery address are required';
END IF;
IF p_payment_method NOT IN ('Cash on Delivery', 'Card at Doorstep (POS)', 'Bank Transfer') THEN
RAISE EXCEPTION 'Invalid payment method';
END IF;
IF jsonb_typeof(p_items) <> 'array'
OR jsonb_array_length(p_items) = 0 THEN
RAISE EXCEPTION 'Cart is empty';
END IF;
IF EXISTS (
SELECT 1
FROM public.orders
WHERE id = p_order_id
) THEN
RAISE EXCEPTION 'Order already exists';
END IF;
v_delivery := (public.quote_nearby_delivery(p_items,p_delivery_address)->>'fee')::numeric;
INSERT INTO public.orders (
id,
customer_name,
customer_phone,
delivery_address,
payment_method,
delivery_fee,
discount_amount,
coupon_code,
total,
status,
payment_status
)
VALUES (
p_order_id,
trim(p_customer_name),
trim(p_customer_phone),
trim(p_delivery_address),
p_payment_method,
v_delivery,
0,
NULLIF(trim(p_coupon_code),''),
v_delivery,
'pending',
'pending'
);
FOR item IN SELECT * FROM jsonb_array_elements(p_items)
LOOP
IF (item->>'product_id') IS NULL
OR (item->>'quantity')::integer < 1 THEN
RAISE EXCEPTION 'Invalid cart item';
END IF;
INSERT INTO public.order_items (
order_id,
product_id,
quantity,
customizations
)
VALUES (
p_order_id,
(item->>'product_id')::uuid,
(item->>'quantity')::integer,
coalesce(item->'customizations','{}'::jsonb)
);
v_count := v_count + 1;
END LOOP;
SELECT COALESCE(SUM(total_price),0)
INTO v_subtotal
FROM public.order_items
WHERE order_id = p_order_id;
IF v_count = 0 OR v_subtotal <= 0 THEN
DELETE FROM public.orders WHERE id = p_order_id;
RAISE EXCEPTION 'No valid products in cart';
END IF;
IF NULLIF(trim(p_coupon_code),'') IS NOT NULL THEN
v_discount := public.calculate_coupon_discount(
trim(p_coupon_code),
v_subtotal
);
END IF;
v_discount := LEAST(
GREATEST(COALESCE(v_discount,0),0),
v_subtotal + v_delivery
);
v_total := GREATEST(
0,
v_subtotal + v_delivery - v_discount
);
UPDATE public.orders
SET
subtotal = v_subtotal,
discount_amount = v_discount,
total = v_total
WHERE id = p_order_id;
RETURN json_build_object(
'success', true,
'order_id', p_order_id,
'subtotal', v_subtotal,
'delivery_fee', v_delivery,
'discount_amount', v_discount,
'total', v_total
);
END;
$function$;
CREATE OR REPLACE FUNCTION public.create_customer_order_account(p_order_id uuid, p_customer_name text, p_customer_phone text, p_delivery_address text, p_payment_method text, p_coupon_code text, p_items jsonb)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
result json;
uid uuid := auth.uid();
o public.orders%ROWTYPE;
fee numeric := 0;
credit numeric := 0;
applied numeric := 0;
new_discount numeric := 0;
new_total numeric := 0;
BEGIN
result := public.create_customer_order(
p_order_id,
p_customer_name,
p_customer_phone,
p_delivery_address,
p_payment_method,
p_coupon_code,
p_items
);
IF uid IS NOT NULL THEN
UPDATE public.orders
SET auth_user_id=uid
WHERE id=p_order_id;
SELECT *
INTO o
FROM public.orders
WHERE id=p_order_id
FOR UPDATE;
fee := (public.quote_nearby_delivery(p_items,p_delivery_address)->>'fee')::numeric;
SELECT reward_credit
INTO credit
FROM public.customer_loyalty_accounts
WHERE auth_user_id=uid
FOR UPDATE;
credit := COALESCE(credit,0);
applied := LEAST(
credit,
GREATEST(
COALESCE(o.subtotal,0)
- COALESCE(o.discount_amount,0),
0
)
);
new_discount :=
COALESCE(o.discount_amount,0)
+ applied;
new_total :=
GREATEST(
COALESCE(o.subtotal,0)
- new_discount
+ COALESCE(fee,0),
0
);
UPDATE public.orders
SET delivery_fee=COALESCE(fee,0),
discount_amount=new_discount,
total=new_total
WHERE id=p_order_id;
IF applied>0 THEN
UPDATE public.customer_loyalty_accounts
SET reward_credit=
GREATEST(
reward_credit-applied,
0
),
updated_at=now()
WHERE auth_user_id=uid;
INSERT INTO public.customer_loyalty_ledger(
auth_user_id,
points,
reason,
order_id
)
VALUES(
uid,
0,
'Reward credit used: ₺ '||applied::text,
p_order_id
);
END IF;
ELSE
fee := (public.quote_nearby_delivery(p_items,p_delivery_address)->>'fee')::numeric;
UPDATE public.orders
SET delivery_fee=COALESCE(fee,0),
total=GREATEST(
COALESCE(subtotal,0)
- COALESCE(discount_amount,0)
+ COALESCE(fee,0),
0
)
WHERE id=p_order_id;
END IF;
RETURN result;
END;
$function$;
