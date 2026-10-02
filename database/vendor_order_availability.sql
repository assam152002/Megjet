-- Restaurant closure is shared across devices and enforced for new order items.
ALTER TABLE public.vendors ADD COLUMN IF NOT EXISTS accepting_orders boolean NOT NULL DEFAULT true;

CREATE OR REPLACE FUNCTION public.vendor_set_order_availability(p_vendor_id uuid,p_accepting boolean)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
  IF auth.uid() IS NULL OR NOT (public.megjet_is_admin() OR EXISTS (
    SELECT 1 FROM public.vendor_users WHERE user_id=auth.uid() AND vendor_id=p_vendor_id
  )) THEN RAISE EXCEPTION 'Restaurant access required'; END IF;
  IF p_accepting IS NULL THEN RAISE EXCEPTION 'Choose open or closed'; END IF;
  UPDATE public.vendors SET accepting_orders=p_accepting WHERE id=p_vendor_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Restaurant not found'; END IF;
  RETURN p_accepting;
END $$;
REVOKE ALL ON FUNCTION public.vendor_set_order_availability(uuid,boolean) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.vendor_set_order_availability(uuid,boolean) TO authenticated;

CREATE OR REPLACE FUNCTION public.require_vendor_open_for_new_order()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v public.vendors;
BEGIN
  SELECT vendor.* INTO v FROM public.vendors vendor JOIN public.products product ON product.vendor_id=vendor.id WHERE product.id=NEW.product_id FOR SHARE OF vendor;
  IF NOT FOUND OR v.active IS NOT TRUE OR v.accepting_orders IS NOT TRUE THEN
    RAISE EXCEPTION 'Restaurant is temporarily closed. Please choose another restaurant.';
  END IF;
  RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION public.require_vendor_open_for_new_order() FROM PUBLIC,anon,authenticated;
DROP TRIGGER IF EXISTS require_vendor_open_for_new_order ON public.order_items;
CREATE TRIGGER require_vendor_open_for_new_order BEFORE INSERT ON public.order_items
FOR EACH ROW EXECUTE FUNCTION public.require_vendor_open_for_new_order();
