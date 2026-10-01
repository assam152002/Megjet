-- Rollback-only checkout checks: no test orders or activation persist.
BEGIN;
UPDATE public.vendors SET active=true WHERE id='5792a8da-aa87-5a06-8421-657261c3800c';
DO $$
DECLARE
  p record; g jsonb; c jsonb; selections jsonb; items jsonb; oid uuid;
  mode integer; expected numeric; result json; rejected boolean;
  base_prices numeric[]:=ARRAY[350,350,350,450,700,700,700,700,800,60,60,60,25,60,60,60,20,20];
  max_prices numeric[]:=ARRAY[675,675,675,775,1000,1000,1000,1000,1250,60,60,60,25,60,60,60,20,20];
BEGIN
  FOR mode IN 0..1 LOOP
    FOR p IN SELECT prod.*,o.groups FROM public.products prod LEFT JOIN public.product_options o ON o.product_id=prod.id
      WHERE prod.vendor_id='5792a8da-aa87-5a06-8421-657261c3800c' ORDER BY prod.menu_sort_order LOOP
      selections:='{}';
      FOR g IN SELECT * FROM jsonb_array_elements(coalesce(p.groups,'[]')) LOOP
        IF mode=0 THEN selections:=selections||jsonb_build_object(g->>'id',g->'defaults');
        ELSE
          SELECT x INTO c FROM jsonb_array_elements(g->'choices') WITH ORDINALITY AS t(x,n)
            ORDER BY (x->>'extra')::numeric DESC,n DESC LIMIT 1;
          selections:=selections||jsonb_build_object(g->>'id',jsonb_build_array(c->>'id'));
        END IF;
      END LOOP;
      expected:=CASE WHEN mode=0 THEN base_prices[p.menu_sort_order+1] ELSE max_prices[p.menu_sort_order+1] END;
      oid:=gen_random_uuid();
      items:=jsonb_build_array(jsonb_build_object('product_id',p.id,'quantity',2,'customizations',selections,'unit_price',1,'price',1));
      result:=public.create_customer_order_retry(oid,'Menu verification','+905330000000','Rollback test address','Cash on Delivery',NULL,items);
      IF (result->>'subtotal')::numeric<>expected*2 THEN RAISE EXCEPTION 'Incorrect subtotal for %, expected % got %',p.name,expected*2,result; END IF;
      IF NOT EXISTS(SELECT 1 FROM public.order_items WHERE order_id=oid AND unit_price=expected AND total_price=expected*2 AND customizations=public.megjet_canonical_choices(selections)) THEN RAISE EXCEPTION 'Incorrect stored choices/price for %',p.name; END IF;
      IF p.groups IS NOT NULL AND mode=1 AND NOT EXISTS(SELECT 1 FROM public.order_items WHERE order_id=oid AND product_name LIKE '%1.5 Portion%') THEN RAISE EXCEPTION 'Missing kitchen portion label'; END IF;
      PERFORM public.create_customer_order_retry(oid,'Menu verification','+905330000000','Rollback test address','Cash on Delivery',NULL,items);
      IF (SELECT count(*) FROM public.order_items WHERE order_id=oid)<>1 THEN RAISE EXCEPTION 'Retry duplicated item'; END IF;
      rejected:=false;
      BEGIN
        PERFORM public.create_customer_order_retry(oid,'Menu verification','+905330000000','Rollback test address','Cash on Delivery',NULL,jsonb_set(items,'{0,quantity}','3'));
      EXCEPTION WHEN OTHERS THEN rejected:=true; END;
      IF NOT rejected THEN RAISE EXCEPTION 'Changed cart retry accepted'; END IF;
      IF p.groups IS NOT NULL THEN
        rejected:=false;
        BEGIN
          PERFORM public.create_customer_order_retry(gen_random_uuid(),'Menu verification','+905330000000','Rollback test address','Cash on Delivery',NULL,jsonb_build_array(jsonb_build_object('product_id',p.id,'quantity',1,'customizations','{}'::jsonb)));
        EXCEPTION WHEN OTHERS THEN
          IF SQLERRM NOT LIKE 'Choose the required options for %' THEN RAISE; END IF;
          rejected:=true;
        END;
        IF NOT rejected THEN RAISE EXCEPTION 'Missing required options accepted'; END IF;
      END IF;
    END LOOP;
  END LOOP;
END $$;
SELECT 'PASS: 36 checkouts, server pricing, stored choices, matching retries, changed-cart rejection and required options' AS result;
ROLLBACK;
