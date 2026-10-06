CREATE TABLE public.megjet_delivery_tiers(
 id integer PRIMARY KEY CHECK(id=1),near_enabled boolean NOT NULL DEFAULT true,
 near_radius integer NOT NULL DEFAULT 25 CHECK(near_radius>=0),near_fee numeric NOT NULL DEFAULT 50 CHECK(near_fee>=0),
 first_radius integer NOT NULL DEFAULT 1500 CHECK(first_radius>0),first_fee numeric NOT NULL DEFAULT 100 CHECK(first_fee>=0),
 second_radius integer NOT NULL DEFAULT 3500,second_fee numeric NOT NULL DEFAULT 130 CHECK(second_fee>=first_fee),
 far_fee numeric NOT NULL DEFAULT 150 CHECK(far_fee>=second_fee),
 CHECK(near_radius<first_radius AND second_radius>first_radius AND near_fee<=first_fee)
);
ALTER TABLE public.megjet_delivery_tiers ENABLE ROW LEVEL SECURITY;
INSERT INTO public.megjet_delivery_tiers(id) VALUES(1);
REVOKE ALL ON public.megjet_delivery_tiers FROM anon,authenticated;
GRANT SELECT ON public.megjet_delivery_tiers TO anon,authenticated;
CREATE POLICY "Public delivery prices" ON public.megjet_delivery_tiers FOR SELECT TO anon,authenticated USING(true);
CREATE FUNCTION public.admin_save_delivery_tiers(p_near_enabled boolean,p_near_radius integer,p_near_fee numeric,p_first_radius integer,p_first_fee numeric,p_second_radius integer,p_second_fee numeric,p_far_fee numeric)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.megjet_require_admin();
 IF p_near_radius<0 OR p_first_radius<=p_near_radius OR p_second_radius<=p_first_radius OR p_second_radius>100000 OR p_near_fee<0 OR p_first_fee<p_near_fee OR p_second_fee<p_first_fee OR p_far_fee<p_second_fee OR p_far_fee>10000 THEN RAISE EXCEPTION 'Use increasing distances and fees. Maximum radius 100000 m and fee 10000 TRY.'; END IF;
 UPDATE public.megjet_delivery_tiers SET near_enabled=p_near_enabled,near_radius=p_near_radius,near_fee=p_near_fee,first_radius=p_first_radius,first_fee=p_first_fee,second_radius=p_second_radius,second_fee=p_second_fee,far_fee=p_far_fee WHERE id=1;
 UPDATE public.megjet_delivery_settings SET delivery_fee=p_first_fee WHERE id=1;
END;
$$;
REVOKE ALL ON FUNCTION public.admin_save_delivery_tiers(boolean,integer,numeric,integer,numeric,integer,numeric,numeric) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_save_delivery_tiers(boolean,integer,numeric,integer,numeric,integer,numeric,numeric) TO authenticated;
CREATE OR REPLACE FUNCTION public.quote_nearby_delivery(p_items jsonb,p_delivery_address text)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE s public.megjet_delivery_tiers%ROWTYPE;pin text[];lat double precision;lng double precision;vendors integer;pinned integer;distance double precision;items_count integer;found_count integer;price numeric;tier text;
BEGIN
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
