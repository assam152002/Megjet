BEGIN;
WITH photos(id,image_url) AS (VALUES
('6022fe34-d951-5af8-abcf-9fb5dc620cf0'::uuid, './assets/menu-photos/alcohol-clean-v1/6022fe34-d951-5af8-abcf-9fb5dc620cf0.webp'),
('f6eb49a1-6df8-5f58-af1f-50f546ed16d3'::uuid, './assets/menu-photos/alcohol-clean-v1/f6eb49a1-6df8-5f58-af1f-50f546ed16d3.webp'),
('3abccabc-e1c7-54ec-a39b-864b68d1b6be'::uuid, './assets/menu-photos/alcohol-clean-v1/3abccabc-e1c7-54ec-a39b-864b68d1b6be.webp'),
('13072270-1f5c-5d19-b1ab-fa6eb0b02449'::uuid, './assets/menu-photos/alcohol-clean-v1/13072270-1f5c-5d19-b1ab-fa6eb0b02449.webp'),
('58c61fde-255f-5240-bf83-604fff387762'::uuid, './assets/menu-photos/alcohol-clean-v1/58c61fde-255f-5240-bf83-604fff387762.webp'),
('c3fd9e8e-2c14-5e58-8a8a-92308794d08b'::uuid, './assets/menu-photos/alcohol-clean-v1/c3fd9e8e-2c14-5e58-8a8a-92308794d08b.webp'),
('d33ab566-8fc9-5a4d-b447-327470933801'::uuid, './assets/menu-photos/alcohol-clean-v1/d33ab566-8fc9-5a4d-b447-327470933801.webp')
) UPDATE public.products p SET image_url=photos.image_url FROM photos WHERE p.id=photos.id AND p.vendor_id='0fda82be-7bde-5187-9a15-0d8f12bbcd73' AND p.image_url LIKE '%alcohol-photo-unavailable.svg' RETURNING p.id,p.name;
COMMIT;
