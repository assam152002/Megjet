-- Web Push subscriptions and an idempotent private outbox. Secrets are seeded in Vault separately.
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;
CREATE TABLE IF NOT EXISTS public.megjet_push_subscriptions (
 endpoint text PRIMARY KEY, user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 keys jsonb NOT NULL, locale text NOT NULL DEFAULT 'en' CHECK(locale IN ('en','tr')),
 updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS megjet_push_subscriptions_user ON public.megjet_push_subscriptions(user_id);
ALTER TABLE public.megjet_push_subscriptions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.megjet_push_subscriptions FROM anon,authenticated;
GRANT ALL ON public.megjet_push_subscriptions TO service_role;
CREATE TABLE IF NOT EXISTS public.megjet_push_outbox (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE, kind text NOT NULL,
 portal text NOT NULL CHECK(portal IN ('admin','vendor','rider')),
 created_at timestamptz NOT NULL DEFAULT now(), next_attempt timestamptz NOT NULL DEFAULT now(),
 attempts integer NOT NULL DEFAULT 0, state text NOT NULL DEFAULT 'pending' CHECK(state IN ('pending','processing','sent','failed')),
 UNIQUE(user_id,order_id,kind)
);
CREATE INDEX IF NOT EXISTS megjet_push_outbox_order ON public.megjet_push_outbox(order_id);
CREATE INDEX IF NOT EXISTS megjet_push_outbox_pending ON public.megjet_push_outbox(next_attempt) WHERE state IN ('pending','processing');
ALTER TABLE public.megjet_push_outbox ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.megjet_push_outbox FROM anon,authenticated;
GRANT ALL ON public.megjet_push_outbox TO service_role;
GRANT USAGE,SELECT ON SEQUENCE public.megjet_push_outbox_id_seq TO service_role;

CREATE OR REPLACE FUNCTION public.megjet_push_public_key() RETURNS text
LANGUAGE sql SECURITY DEFINER SET search_path='' AS $$
 SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name='megjet_vapid_public' LIMIT 1
$$;
REVOKE ALL ON FUNCTION public.megjet_push_public_key() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.megjet_push_public_key() TO anon,authenticated,service_role;

CREATE OR REPLACE FUNCTION public.megjet_register_push(p_subscription jsonb,p_locale text DEFAULT 'en') RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE endpoint text:=p_subscription->>'endpoint';
BEGIN
 IF auth.uid() IS NULL OR NOT(public.megjet_is_admin() OR EXISTS(SELECT 1 FROM public.vendor_users WHERE user_id=auth.uid()) OR EXISTS(SELECT 1 FROM public.rider_users WHERE user_id=auth.uid())) THEN RAISE EXCEPTION 'Staff sign-in required'; END IF;
 -- Only browser push providers; prevents arbitrary outbound network targets.
 IF endpoint IS NULL OR length(endpoint)>4096 OR endpoint !~ '^https://(fcm\.googleapis\.com|updates\.push\.services\.mozilla\.com|[a-z0-9-]+\.push\.apple\.com|[a-z0-9.-]+\.notify\.windows\.com)/' THEN RAISE EXCEPTION 'Unsupported push service'; END IF;
 IF coalesce(p_subscription->'keys'->>'p256dh','') !~ '^[A-Za-z0-9_-]{87,88}=?$' OR coalesce(p_subscription->'keys'->>'auth','') !~ '^[A-Za-z0-9_-]{22,24}={0,2}$' THEN RAISE EXCEPTION 'Invalid push subscription'; END IF;
 INSERT INTO public.megjet_push_subscriptions(endpoint,user_id,keys,locale) VALUES(endpoint,auth.uid(),p_subscription->'keys',CASE WHEN p_locale='tr' THEN 'tr' ELSE 'en' END)
 ON CONFLICT ON CONSTRAINT megjet_push_subscriptions_pkey DO UPDATE SET user_id=EXCLUDED.user_id,keys=EXCLUDED.keys,locale=EXCLUDED.locale,updated_at=now();
 RETURN true;
END $$;
CREATE OR REPLACE FUNCTION public.megjet_remove_push(p_endpoint text) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN DELETE FROM public.megjet_push_subscriptions WHERE endpoint=p_endpoint AND user_id=auth.uid(); RETURN true; END $$;
REVOKE ALL ON FUNCTION public.megjet_register_push(jsonb,text),public.megjet_remove_push(text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.megjet_register_push(jsonb,text),public.megjet_remove_push(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.megjet_queue_order_push() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF TG_TABLE_NAME='order_items' THEN
  INSERT INTO public.megjet_push_outbox(user_id,order_id,kind,portal) SELECT user_id,NEW.order_id,'new','vendor' FROM public.vendor_users WHERE vendor_id=NEW.vendor_id ON CONFLICT DO NOTHING;
  INSERT INTO public.megjet_push_outbox(user_id,order_id,kind,portal) SELECT user_id,NEW.order_id,'new','admin' FROM public.admin_users ON CONFLICT DO NOTHING;
 ELSIF TG_TABLE_NAME='order_riders' THEN
  INSERT INTO public.megjet_push_outbox(user_id,order_id,kind,portal) SELECT user_id,NEW.order_id,'assigned','rider' FROM public.rider_users WHERE rider_id=NEW.rider_id ON CONFLICT DO NOTHING;
 ELSIF NEW.status IS DISTINCT FROM OLD.status THEN
  INSERT INTO public.megjet_push_outbox(user_id,order_id,kind,portal) SELECT a.user_id,NEW.id,'status:'||NEW.status,'admin' FROM public.admin_users a ON CONFLICT DO NOTHING;
  INSERT INTO public.megjet_push_outbox(user_id,order_id,kind,portal) SELECT DISTINCT v.user_id,NEW.id,'status:'||NEW.status,'vendor' FROM public.vendor_users v JOIN public.order_items i ON i.vendor_id=v.vendor_id WHERE i.order_id=NEW.id ON CONFLICT DO NOTHING;
  INSERT INTO public.megjet_push_outbox(user_id,order_id,kind,portal) SELECT r.user_id,NEW.id,'status:'||NEW.status,'rider' FROM public.rider_users r JOIN public.order_riders a ON a.rider_id=r.rider_id WHERE a.order_id=NEW.id ON CONFLICT DO NOTHING;
 END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION public.megjet_queue_order_push() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER megjet_order_item_push AFTER INSERT ON public.order_items FOR EACH ROW EXECUTE FUNCTION public.megjet_queue_order_push();
CREATE TRIGGER megjet_rider_assignment_push AFTER INSERT ON public.order_riders FOR EACH ROW EXECUTE FUNCTION public.megjet_queue_order_push();
CREATE TRIGGER megjet_order_status_push AFTER UPDATE OF status ON public.orders FOR EACH ROW EXECUTE FUNCTION public.megjet_queue_order_push();

CREATE OR REPLACE FUNCTION public.megjet_push_server_config() RETURNS jsonb
LANGUAGE sql SECURITY DEFINER SET search_path='' AS $$
 SELECT jsonb_object_agg(name,decrypted_secret) FROM vault.decrypted_secrets WHERE name IN ('megjet_vapid_public','megjet_vapid_private','megjet_push_dispatch_token')
$$;
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
REVOKE ALL ON FUNCTION public.megjet_push_server_config(),public.megjet_claim_push() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.megjet_push_server_config(),public.megjet_claim_push() TO service_role;

CREATE OR REPLACE FUNCTION public.megjet_dispatch_push() RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE token text;
BEGIN
 SELECT decrypted_secret INTO token FROM vault.decrypted_secrets WHERE name='megjet_push_dispatch_token' LIMIT 1;
 IF token IS NOT NULL THEN
  PERFORM net.http_post(url:='https://manuspenfcahagcstedd.supabase.co/functions/v1/megjet-push',headers:=jsonb_build_object('Authorization','Bearer '||token,'Content-Type','application/json'),body:='{}'::jsonb,timeout_milliseconds:=15000);
 END IF;
END $$;
REVOKE ALL ON FUNCTION public.megjet_dispatch_push() FROM PUBLIC,anon,authenticated;
SELECT cron.schedule('megjet-push-dispatch','* * * * *','select public.megjet_dispatch_push()');
