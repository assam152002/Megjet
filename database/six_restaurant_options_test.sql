-- Real checkout functions and pricing triggers, rolled back with no live orders.
BEGIN;
DO $test$
DECLARE p record; g jsonb; c jsonb; selection jsonb; item jsonb; oid uuid;
 expected numeric; actual numeric; result json; maximum boolean; blocked boolean; n integer:=0;
BEGIN
 PERFORM set_config('request.jwt.claim.sub','',true);
 PERFORM set_config('request.jwt.claims','{}',true);
 FOR p IN SELECT x.id,x.price,o.groups FROM public.products x
 JOIN public.vendors v ON v.id=x.vendor_id
 LEFT JOIN public.product_options o ON o.product_id=x.id
 WHERE x.available AND v.name IN ('Kebap Dünyası (Sakarya)','Köz Adası (Salamis Yolu)','Garson Ali (Dumlupınar)','O''Feel Du Grill','Island Coffee','Coffeeholic Boutique Bakery House')
 LOOP
  FOREACH maximum IN ARRAY ARRAY[false,true] LOOP
   selection:='{}'::jsonb;expected:=p.price;
   FOR g IN SELECT * FROM jsonb_array_elements(coalesce(p.groups,'[]'::jsonb)) LOOP
    IF maximum AND (g->>'max')::integer>1 THEN
     selection:=selection||jsonb_build_object(g->>'id',(SELECT jsonb_agg(x->>'id') FROM jsonb_array_elements(g->'choices') x));
     expected:=expected+(SELECT coalesce(sum((x->>'extra')::numeric),0) FROM jsonb_array_elements(g->'choices') x);
    ELSIF maximum OR (g->>'min')::integer>0 THEN
     SELECT x INTO c FROM jsonb_array_elements(g->'choices') x ORDER BY CASE WHEN maximum THEN (x->>'extra')::numeric ELSE -((x->>'extra')::numeric) END DESC LIMIT 1;
     selection:=selection||jsonb_build_object(g->>'id',jsonb_build_array(c->>'id'));
     expected:=expected+coalesce((c->>'extra')::numeric,0);
    ELSE selection:=selection||jsonb_build_object(g->>'id','[]'::jsonb);
    END IF;
   END LOOP;
   oid:=gen_random_uuid();item:=jsonb_build_array(jsonb_build_object('product_id',p.id,'quantity',2,'customizations',selection));
   result:=public.create_customer_order_retry(oid,'Rollback menu test','0000000000','Rollback verification address','Card at Doorstep (POS)',NULL,item);
   IF coalesce((result->>'success')::boolean,false) IS NOT TRUE THEN RAISE EXCEPTION 'Checkout failed for %',p.id; END IF;
   SELECT unit_price INTO actual FROM public.order_items WHERE order_id=oid;
   IF actual IS DISTINCT FROM expected THEN RAISE EXCEPTION 'Price mismatch for %: % versus %',p.id,actual,expected; END IF;
   result:=public.create_customer_order_retry(oid,'Rollback menu test','0000000000','Rollback verification address','Card at Doorstep (POS)',NULL,item);
   IF coalesce((result->>'replayed')::boolean,false) IS NOT TRUE THEN RAISE EXCEPTION 'Retry failed'; END IF;
   n:=n+1;
  END LOOP;
  blocked:=false;
  BEGIN
   PERFORM public.create_customer_order_retry(gen_random_uuid(),'Rollback menu test','0000000000','Rollback verification address','Cash on Delivery',NULL,jsonb_build_array(jsonb_build_object('product_id',p.id,'quantity',1,'customizations',jsonb_build_object('invalid-group',jsonb_build_array('invalid-choice')))));
  EXCEPTION WHEN OTHERS THEN
   IF SQLERRM IN ('Unknown choice group','This item does not offer choices') THEN blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT blocked THEN RAISE EXCEPTION 'Invalid choices accepted for %',p.id; END IF;
 END LOOP;
 IF n<>754 THEN RAISE EXCEPTION 'Expected 754 pricing cases; tested %',n; END IF;
END $test$;
ROLLBACK;
SELECT 'Passed: 754 checkouts, minimum/maximum option prices, quantity 2, matching retry, and invalid-choice rejection for every available imported product. No live test orders retained.' AS result;
