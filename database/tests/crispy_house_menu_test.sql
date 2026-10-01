-- Rollback-only checkout checks: no test orders or activation persist. Includes all 54 items with confirmed base prices.
BEGIN;
UPDATE public.vendors SET active=true WHERE id='6d7aeeee-0826-5888-ba1d-f46dcc7548c5';
DO $$
DECLARE
  p record; g jsonb; c jsonb; selections jsonb; items jsonb; oid uuid;
  mode integer; expected numeric; result json; rejected boolean;
  base_prices numeric[]:=ARRAY[500.0,450.0,550.0,360.0,250.0,360.0,340.0,280.0,420.0,380.0,450.0,400.0,480.0,560.0,640.0,540.0,630.0,670.0,600.0,450.0,700.0,690.0,640.0,780.0,760.0,400.0,470.0,470.0,550.0,440.0,390.0,390.0,420.0,500.0,470.0,390.0,550.0,370.0,240.0,240.0,450.0,60.0,350.0,30.0,30.0,30.0,60.0,80.0,117.0,130.5,90.0,162.0,180.0,207.0,216.0];
  max_prices numeric[]:=ARRAY[640.0,450.0,550.0,360.0,250.0,360.0,340.0,280.0,420.0,380.0,910.0,860.0,480.0,560.0,640.0,540.0,630.0,670.0,600.0,450.0,700.0,690.0,640.0,780.0,760.0,400.0,470.0,470.0,550.0,740.0,650.0,650.0,700.0,970.0,470.0,390.0,550.0,370.0,240.0,240.0,450.0,60.0,350.0,30.0,30.0,30.0,60.0,80.0,117.0,130.5,90.0,166.5,180.0,207.0,216.0];
BEGIN
  FOR mode IN 0..1 LOOP
    FOR p IN SELECT prod.*,o.groups FROM public.products prod LEFT JOIN public.product_options o ON o.product_id=prod.id
      WHERE prod.vendor_id='6d7aeeee-0826-5888-ba1d-f46dcc7548c5' AND prod.available=true ORDER BY prod.menu_sort_order LOOP
      selections:='{}';
      FOR g IN SELECT * FROM jsonb_array_elements(coalesce(p.groups,'[]')) LOOP
        SELECT coalesce(jsonb_agg(x->>'id'),'[]') INTO c FROM (
          SELECT x FROM jsonb_array_elements(g->'choices') WITH ORDINALITY AS t(x,n)
          ORDER BY (x->>'extra')::numeric * CASE WHEN mode=0 THEN 1 ELSE -1 END,n
          LIMIT CASE WHEN mode=0 THEN (g->>'min')::integer ELSE (g->>'max')::integer END
        ) picked;
        selections:=selections||jsonb_build_object(g->>'id',c);
      END LOOP;
      expected:=CASE WHEN mode=0 THEN base_prices[p.menu_sort_order+1] ELSE max_prices[p.menu_sort_order+1] END;
      oid:=gen_random_uuid();
      items:=jsonb_build_array(jsonb_build_object('product_id',p.id,'quantity',2,'customizations',selections,'unit_price',1,'price',1));
      result:=public.create_customer_order_retry(oid,'Menu verification','+905330000000','Rollback test address','Cash on Delivery',NULL,items);
      IF (result->>'subtotal')::numeric<>expected*2 THEN RAISE EXCEPTION 'Incorrect subtotal for %, expected % got %',p.name,expected*2,result; END IF;
      IF NOT EXISTS(SELECT 1 FROM public.order_items WHERE order_id=oid AND unit_price=expected AND total_price=expected*2 AND customizations=public.megjet_canonical_choices(selections)) THEN RAISE EXCEPTION 'Incorrect stored choices/price for %',p.name; END IF;

      PERFORM public.create_customer_order_retry(oid,'Menu verification','+905330000000','Rollback test address','Cash on Delivery',NULL,items);
      IF (SELECT count(*) FROM public.order_items WHERE order_id=oid)<>1 THEN RAISE EXCEPTION 'Retry duplicated item'; END IF;
      rejected:=false;
      BEGIN
        PERFORM public.create_customer_order_retry(oid,'Menu verification','+905330000000','Rollback test address','Cash on Delivery',NULL,jsonb_set(items,'{0,quantity}','3'));
      EXCEPTION WHEN OTHERS THEN rejected:=true; END;
      IF NOT rejected THEN RAISE EXCEPTION 'Changed cart retry accepted'; END IF;
      IF EXISTS(SELECT 1 FROM jsonb_array_elements(coalesce(p.groups,'[]')) gg WHERE (gg->>'min')::integer>0) THEN
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
SELECT 'PASS: 108 checkouts, server pricing, stored choices, matching retries, changed-cart rejection and required options' AS result;
ROLLBACK;
