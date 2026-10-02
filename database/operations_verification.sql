-- Rollback-only verification; creates no live orders or notifications.
BEGIN;
DO $$
DECLARE p uuid;v uuid;uid uuid;oid uuid:=gen_random_uuid();items jsonb;result json;blocked boolean:=false;count_before integer;
BEGIN
 SELECT x.id,x.vendor_id INTO p,v FROM public.products x JOIN public.vendors y ON y.id=x.vendor_id WHERE x.available AND y.active AND NOT EXISTS(SELECT 1 FROM public.product_options opt WHERE opt.product_id=x.id) LIMIT 1;
 IF p IS NULL THEN RAISE EXCEPTION 'No simple product available for test';END IF;
 items:=jsonb_build_array(jsonb_build_object('product_id',p,'quantity',1));
 PERFORM set_config('request.jwt.claim.sub','',true);PERFORM set_config('request.jwt.claims','{}',true);
 BEGIN PERFORM public.vendor_set_order_availability(v,false);EXCEPTION WHEN OTHERS THEN IF SQLERRM='Restaurant access required' THEN blocked:=true;ELSE RAISE;END IF;END;
 IF NOT blocked THEN RAISE EXCEPTION 'Anonymous availability change allowed';END IF;
 SELECT user_id INTO uid FROM public.vendor_users WHERE vendor_id=v LIMIT 1;
 IF uid IS NOT NULL THEN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM public.vendor_set_order_availability(v,false);
  IF(SELECT accepting_orders FROM public.vendors WHERE id=v) THEN RAISE EXCEPTION 'Closure not saved';END IF;
 END IF;
 PERFORM set_config('request.jwt.claim.sub','',true);
 UPDATE public.vendors SET accepting_orders=true WHERE id=v;
 result:=public.create_customer_order_retry(oid,'Rollback verification','0000000000','Rollback test address','Card at Doorstep (POS)',NULL,items);
 IF coalesce((result->>'success')::boolean,false) IS NOT TRUE THEN RAISE EXCEPTION 'Open checkout failed';END IF;
 SELECT count(*) INTO count_before FROM public.megjet_push_outbox WHERE order_id=oid;
 IF count_before<1 THEN RAISE EXCEPTION 'New order push not queued';END IF;
 UPDATE public.vendors SET accepting_orders=false WHERE id=v;
 result:=public.create_customer_order_retry(oid,'Rollback verification','0000000000','Rollback test address','Card at Doorstep (POS)',NULL,items);
 IF (result->>'replayed')::boolean IS NOT TRUE THEN RAISE EXCEPTION 'Matching retry failed after closure';END IF;
 IF (SELECT count(*) FROM public.megjet_push_outbox WHERE order_id=oid)<>count_before THEN RAISE EXCEPTION 'Retry duplicated push';END IF;
 blocked:=false;
 BEGIN PERFORM public.create_customer_order_retry(gen_random_uuid(),'Rollback verification','0000000000','Rollback test address','Card at Doorstep (POS)',NULL,items);EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'Restaurant is temporarily closed%' THEN blocked:=true;ELSE RAISE;END IF;END;
 IF NOT blocked THEN RAISE EXCEPTION 'Closed restaurant accepted new order';END IF;
 blocked:=false;
 BEGIN PERFORM public.megjet_register_push('{"endpoint":"https://localhost/private","keys":{}}'::jsonb,'en');EXCEPTION WHEN OTHERS THEN IF SQLERRM='Staff sign-in required' THEN blocked:=true;ELSE RAISE;END IF;END;
 IF NOT blocked THEN RAISE EXCEPTION 'Anonymous push subscription accepted';END IF;
 UPDATE public.orders SET created_at=now()-interval '6 minutes' WHERE id=oid;
 PERFORM public.megjet_claim_push();
 IF NOT EXISTS(SELECT 1 FROM public.megjet_push_outbox WHERE order_id=oid AND kind='unanswered') THEN RAISE EXCEPTION 'Unanswered reminder was not queued';END IF;
 SELECT count(*) INTO count_before FROM public.megjet_push_outbox WHERE order_id=oid AND kind='unanswered';
 PERFORM public.megjet_claim_push();
 IF (SELECT count(*) FROM public.megjet_push_outbox WHERE order_id=oid AND kind='unanswered')<>count_before THEN RAISE EXCEPTION 'Duplicate unanswered reminder';END IF;
 IF uid IS NOT NULL THEN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);blocked:=false;
  BEGIN PERFORM public.megjet_register_push('{"endpoint":"https://localhost/private","keys":{}}'::jsonb,'en');EXCEPTION WHEN OTHERS THEN IF SQLERRM='Unsupported push service' THEN blocked:=true;ELSE RAISE;END IF;END;
  IF NOT blocked THEN RAISE EXCEPTION 'Arbitrary push endpoint accepted';END IF;
 END IF;
END $$;
ROLLBACK;
SELECT 'passed: shared closure, open POS checkout, closed new checkout rejection, matching retry, push deduplication, five-minute reminder deduplication, anonymous guards, push endpoint restrictions' AS verification;
