CREATE FUNCTION public.vendor_save_preparation(p_vendor_id uuid,p_minutes integer)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.vendor_users WHERE user_id=auth.uid() AND vendor_id=p_vendor_id) AND NOT EXISTS(SELECT 1 FROM public.admin_users WHERE user_id=auth.uid()) THEN RAISE EXCEPTION 'Vendor access required';END IF;
 IF p_minutes IS NULL OR p_minutes NOT BETWEEN 1 AND 180 THEN RAISE EXCEPTION 'Preparation time must be 1–180 minutes';END IF;
 UPDATE public.vendors SET preparation_minutes=p_minutes WHERE id=p_vendor_id;
END $$;
REVOKE ALL ON FUNCTION public.vendor_save_preparation(uuid,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.vendor_save_preparation(uuid,integer) TO authenticated;
ALTER TABLE public.order_service_requests ALTER COLUMN customer_user_id DROP NOT NULL;
CREATE FUNCTION public.megjet_queue_cancelled_refund() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NEW.status='cancelled' AND OLD.status<>'cancelled' AND NEW.payment_status='paid' THEN
  INSERT INTO public.order_service_requests(order_id,customer_user_id,kind,reason,amount,status)
  VALUES(NEW.id,NEW.auth_user_id,'refund','Paid order cancelled. Admin must return the payment.',NEW.total,'approved') ON CONFLICT(order_id,kind) DO NOTHING;
 END IF;RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION public.megjet_queue_cancelled_refund() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER megjet_queue_cancelled_refund AFTER UPDATE OF status ON public.orders FOR EACH ROW EXECUTE FUNCTION public.megjet_queue_cancelled_refund();
