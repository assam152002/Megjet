CREATE INDEX IF NOT EXISTS megjet_push_outbox_order ON public.megjet_push_outbox(order_id);
CREATE OR REPLACE FUNCTION public.megjet_claim_push() RETURNS SETOF public.megjet_push_outbox
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 UPDATE public.megjet_push_outbox SET state='failed' WHERE state IN ('pending','processing') AND attempts>=5 AND next_attempt<=now();
 DELETE FROM public.megjet_push_outbox WHERE created_at<now()-interval '30 days' AND state IN ('sent','failed');
 -- A single five-minute reminder; excludes old abandoned/testing orders.
 INSERT INTO public.megjet_push_outbox(user_id,order_id,kind,portal)
 SELECT a.user_id,o.id,'unanswered','admin' FROM public.orders o CROSS JOIN public.admin_users a
 WHERE lower(o.status)='pending' AND o.created_at BETWEEN now()-interval '15 minutes' AND now()-interval '5 minutes' ON CONFLICT DO NOTHING;
 INSERT INTO public.megjet_push_outbox(user_id,order_id,kind,portal)
 SELECT DISTINCT v.user_id,o.id,'unanswered','vendor' FROM public.orders o JOIN public.order_items i ON i.order_id=o.id JOIN public.vendor_users v ON v.vendor_id=i.vendor_id
 WHERE lower(o.status)='pending' AND o.created_at BETWEEN now()-interval '15 minutes' AND now()-interval '5 minutes' ON CONFLICT DO NOTHING;
 RETURN QUERY UPDATE public.megjet_push_outbox q SET state='processing',attempts=q.attempts+1,next_attempt=now()+interval '2 minutes'
 WHERE q.id IN (SELECT c.id FROM public.megjet_push_outbox c WHERE c.state IN ('pending','processing') AND c.next_attempt<=now() AND c.attempts<5 ORDER BY c.id LIMIT 30 FOR UPDATE SKIP LOCKED)
 RETURNING q.*;
END $$;
