BEGIN;
WITH photos(id,image_url) AS (VALUES
('05db6628-a6cf-5e4e-bad5-bb3f73aa507d'::uuid, './assets/menu-photos/alcohol-clean-v1/05db6628-a6cf-5e4e-bad5-bb3f73aa507d.webp'),
('91266191-3c49-569b-ac64-ce0b277e6daf'::uuid, './assets/menu-photos/alcohol-clean-v1/91266191-3c49-569b-ac64-ce0b277e6daf.webp')
) UPDATE public.products p SET image_url=photos.image_url FROM photos WHERE p.id=photos.id AND p.vendor_id='0fda82be-7bde-5187-9a15-0d8f12bbcd73' AND p.image_url LIKE '%alcohol-photo-unavailable.svg' RETURNING p.id,p.name;
COMMIT;
