CREATE TABLE public.megjet_delivery_estimates (
 id integer PRIMARY KEY CHECK (id=1),
 travel_min integer NOT NULL DEFAULT 15 CHECK (travel_min BETWEEN 1 AND 180),
 travel_max integer NOT NULL DEFAULT 25 CHECK (travel_max BETWEEN travel_min AND 180)
);
ALTER TABLE public.megjet_delivery_estimates ENABLE ROW LEVEL SECURITY;
INSERT INTO public.megjet_delivery_estimates(id) VALUES(1);
REVOKE ALL ON public.megjet_delivery_estimates FROM anon,authenticated;
GRANT SELECT ON public.megjet_delivery_estimates TO anon,authenticated;
CREATE POLICY "Public delivery estimates" ON public.megjet_delivery_estimates FOR SELECT TO anon,authenticated USING (true);
CREATE FUNCTION public.admin_save_delivery_estimates(p_min integer,p_max integer) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.megjet_require_admin();
 IF p_min IS NULL OR p_max IS NULL OR p_min<1 OR p_max<p_min OR p_max>180 THEN RAISE EXCEPTION 'Use 1–180 minutes, maximum at least minimum'; END IF;
 UPDATE public.megjet_delivery_estimates SET travel_min=p_min,travel_max=p_max WHERE id=1;
END;
$$;
REVOKE ALL ON FUNCTION public.admin_save_delivery_estimates(integer,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_save_delivery_estimates(integer,integer) TO authenticated;
