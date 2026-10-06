BEGIN;
DO $$
DECLARE v uuid:=gen_random_uuid();p uuid:=gen_random_uuid();q jsonb;d double precision;expected integer;cases double precision[]:=ARRAY[0,25,25.1,1499.9,1500,1500.1,3499.9,3500,3500.1];fees integer[]:=ARRAY[50,50,100,100,100,130,130,130,150];o uuid:=gen_random_uuid();r json;
BEGIN
 INSERT INTO public.vendors(id,name,active,accepting_orders,preparation_minutes) VALUES(v,'Transactional tier test',true,true,10);
 INSERT INTO public.products(id,vendor_id,name,price,available) VALUES(p,v,'Transactional tier meal',200,true);
 INSERT INTO public.vendor_pickup_pins(vendor_id,latitude,longitude) VALUES(v,35,33);
 FOR i IN 1..array_length(cases,1) LOOP
  d:=cases[i];expected:=fees[i];
  q:=public.quote_nearby_delivery(jsonb_build_array(jsonb_build_object('product_id',p)),E'Test address\nMap pin: https://www.google.com/maps?q='||(35+d/111194.926644559)::text||',33');
  IF(q->>'fee')::numeric<>expected THEN RAISE EXCEPTION 'Boundary % failed: %',d,q; END IF;
 END LOOP;
 UPDATE public.megjet_launch_settings SET store_active=true,open_time='00:00',close_time='23:59',min_order=0 WHERE id=1;
 r:=public.create_customer_order_retry(o,'Tier test','0000000000',E'Test address\nMap pin: https://www.google.com/maps?q=35.04,33','Bank Transfer',null,jsonb_build_array(jsonb_build_object('product_id',p,'quantity',1,'customizations','{}'::jsonb)));
 IF(r->>'total')::numeric<>350 OR (SELECT delivery_fee FROM public.orders WHERE id=o)<>150 THEN RAISE EXCEPTION 'Saved far-distance bank order fee failed'; END IF;
 PERFORM set_config('request.jwt.claim.sub',(SELECT user_id::text FROM public.admin_users LIMIT 1),true);
 PERFORM public.admin_save_delivery_tiers(false,25,50,1500,110,3500,140,160);
 q:=public.quote_nearby_delivery(jsonb_build_array(jsonb_build_object('product_id',p)),E'Test address\nMap pin: https://www.google.com/maps?q=35,33');
 IF(q->>'fee')::numeric<>110 THEN RAISE EXCEPTION 'Admin edit or disabled nearby tier failed'; END IF;
 BEGIN
  PERFORM public.admin_save_delivery_tiers(true,25,50,3500,100,1500,130,150);
  RAISE EXCEPTION 'Invalid radii allowed';
 EXCEPTION WHEN OTHERS THEN
  IF sqlerrm='Invalid radii allowed' THEN RAISE; END IF;
 END;
 PERFORM set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
 BEGIN
  PERFORM public.admin_save_delivery_tiers(true,25,50,1500,100,3500,130,150);
  RAISE EXCEPTION 'Non-admin allowed';
 EXCEPTION WHEN OTHERS THEN
  IF sqlerrm<>'Admin access required' THEN RAISE; END IF;
 END;
END $$;
ROLLBACK;
