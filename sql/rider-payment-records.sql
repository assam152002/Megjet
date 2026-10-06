ALTER TABLE public.rider_earnings ADD COLUMN paid_at timestamptz,ADD COLUMN paid_reference text,ADD COLUMN paid_by uuid REFERENCES auth.users(id);
CREATE FUNCTION public.admin_unpaid_rider_earnings() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.megjet_require_admin();
 SELECT coalesce(jsonb_agg(x),'[]'::jsonb) INTO result FROM(SELECT e.id,e.order_id,e.rider_id,e.amount,e.created_at,r.name FROM public.rider_earnings e LEFT JOIN public.riders r ON r.id::text=e.rider_id WHERE e.status='earned' ORDER BY e.created_at LIMIT 200)x;
 RETURN result;
END $$;
CREATE FUNCTION public.admin_record_rider_payment(p_earning_id uuid,p_reference text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.megjet_require_admin();
 IF length(trim(coalesce(p_reference,''))) NOT BETWEEN 3 AND 200 THEN RAISE EXCEPTION 'Enter a payment reference (3–200 characters)';END IF;
 UPDATE public.rider_earnings SET status='paid',paid_at=now(),paid_reference=trim(p_reference),paid_by=auth.uid() WHERE id=p_earning_id AND status='earned';
 IF NOT FOUND THEN RAISE EXCEPTION 'This earning is already paid or unavailable';END IF;
END $$;
REVOKE ALL ON FUNCTION public.admin_unpaid_rider_earnings(),public.admin_record_rider_payment(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_unpaid_rider_earnings(),public.admin_record_rider_payment(uuid,text) TO authenticated;
