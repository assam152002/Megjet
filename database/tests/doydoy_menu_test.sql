-- Rollback-only checkout checks: no test orders or activation persist. Includes all 59 items and all specified options.
BEGIN;
UPDATE public.vendors SET active=true WHERE id='a83e1b05-71fa-5b1f-ab35-1d8cca0c4ea9';
DO $$
DECLARE
  p record; g jsonb; c jsonb; selections jsonb; items jsonb; oid uuid;
  mode integer; expected numeric; result json; rejected boolean;
  base_prices numeric[]:=ARRAY[900.0,1050.0,800.0,800.0,1050.0,1150.0,950.0,1000.0,1000.0,1150.0,1050.0,1050.0,5250.0,1150.0,1150.0,500.0,725.0,650.0,450.0,550.0,300.0,800.0,220.0,440.0,500.0,600.0,600.0,550.0,550.0,500.0,550.0,300.0,450.0,220.0,220.0,220.0,220.0,220.0,220.0,220.0,250.0,500.0,300.0,350.0,400.0,400.0,50.0,90.0,90.0,90.0,90.0,90.0,90.0,70.0,70.0,50.0,90.0,200.0,70.0];
  max_prices numeric[]:=ARRAY[900.0,1050.0,800.0,800.0,1050.0,1150.0,950.0,1000.0,1000.0,1150.0,1050.0,1050.0,5250.0,1150.0,1150.0,610.0,835.0,760.0,560.0,660.0,410.0,910.0,220.0,440.0,500.0,600.0,600.0,550.0,550.0,500.0,550.0,300.0,450.0,220.0,220.0,220.0,220.0,220.0,220.0,220.0,250.0,500.0,300.0,400.0,450.0,450.0,100.0,90.0,90.0,90.0,90.0,90.0,90.0,70.0,70.0,50.0,90.0,200.0,70.0];
BEGIN
  FOR mode IN 0..1 LOOP
    FOR p IN SELECT prod.*,o.groups FROM public.products prod LEFT JOIN public.product_options o ON o.product_id=prod.id
      WHERE prod.vendor_id='a83e1b05-71fa-5b1f-ab35-1d8cca0c4ea9' AND prod.available=true ORDER BY prod.menu_sort_order LOOP
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
SELECT 'PASS: 118 checkouts, server pricing, stored choices, matching retries, changed-cart rejection and required options' AS result;
ROLLBACK;
