BEGIN;
WITH photos(id,image_url) AS (VALUES
('c56bb586-99e8-52b6-8cab-7cd5a9750934'::uuid,'./assets/menu-photos/alcohol-clean-v1/c56bb586-99e8-52b6-8cab-7cd5a9750934.webp'),
('2447922e-2bed-550d-af6c-979fe4610469'::uuid,'./assets/menu-photos/alcohol-clean-v1/2447922e-2bed-550d-af6c-979fe4610469.webp')
) UPDATE public.products p SET image_url=photos.image_url FROM photos WHERE p.id=photos.id AND p.vendor_id='0fda82be-7bde-5187-9a15-0d8f12bbcd73' AND p.image_url LIKE '%alcohol-photo-unavailable.svg' RETURNING p.id,p.name;
COMMIT;
