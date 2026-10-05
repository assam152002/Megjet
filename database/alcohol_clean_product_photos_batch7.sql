BEGIN;
WITH photos(id,image_url) AS (VALUES
('b37ea3cd-34a0-513e-9445-1e61694edad4'::uuid,'./assets/menu-photos/alcohol-clean-v1/b37ea3cd-34a0-513e-9445-1e61694edad4.webp'),
('e27b8312-8985-5128-b500-4336b9214e43'::uuid,'./assets/menu-photos/alcohol-clean-v1/e27b8312-8985-5128-b500-4336b9214e43.webp'),
('6d46a162-a915-5424-b96e-517ca2905bb2'::uuid,'./assets/menu-photos/alcohol-clean-v1/6d46a162-a915-5424-b96e-517ca2905bb2.webp'),
('1fff4626-ab27-5f78-bc62-33e8d991a9e6'::uuid,'./assets/menu-photos/alcohol-clean-v1/1fff4626-ab27-5f78-bc62-33e8d991a9e6.webp'),
('9d29a6b8-2e1f-5444-b96a-1fb626ba8916'::uuid,'./assets/menu-photos/alcohol-clean-v1/9d29a6b8-2e1f-5444-b96a-1fb626ba8916.webp'),
('2fbee7ba-4053-5da5-bc0a-6b3c3a1b734f'::uuid,'./assets/menu-photos/alcohol-clean-v1/2fbee7ba-4053-5da5-bc0a-6b3c3a1b734f.webp'),
('7ee42838-7900-53f8-a491-32b91e88a782'::uuid,'./assets/menu-photos/alcohol-clean-v1/7ee42838-7900-53f8-a491-32b91e88a782.webp'),
('be715dcb-2893-50bc-b16c-787b00b8d9b5'::uuid,'./assets/menu-photos/alcohol-clean-v1/be715dcb-2893-50bc-b16c-787b00b8d9b5.webp'),
('1f47423b-5d40-5aaf-ba8e-5b51bbea0971'::uuid,'./assets/menu-photos/alcohol-clean-v1/1f47423b-5d40-5aaf-ba8e-5b51bbea0971.webp'),
('56e426d6-0bb6-52fb-9cab-d6d88d6119d8'::uuid,'./assets/menu-photos/alcohol-clean-v1/56e426d6-0bb6-52fb-9cab-d6d88d6119d8.webp'),
('f7f2a67c-7dbe-5f4a-bed7-52e216a41c9d'::uuid,'./assets/menu-photos/alcohol-clean-v1/f7f2a67c-7dbe-5f4a-bed7-52e216a41c9d.webp'),
('9aef511d-c607-5577-935b-0d002cca0fcf'::uuid,'./assets/menu-photos/alcohol-clean-v1/9aef511d-c607-5577-935b-0d002cca0fcf.webp'),
('b4d1c216-e82c-563a-a640-2073ce6b774c'::uuid,'./assets/menu-photos/alcohol-clean-v1/b4d1c216-e82c-563a-a640-2073ce6b774c.webp'),
('599ef3b8-3783-553e-a063-ee970bf3e6eb'::uuid,'./assets/menu-photos/alcohol-clean-v1/599ef3b8-3783-553e-a063-ee970bf3e6eb.webp'),
('2774b3d9-552e-5bf5-b62c-23759ce24034'::uuid,'./assets/menu-photos/alcohol-clean-v1/2774b3d9-552e-5bf5-b62c-23759ce24034.webp'),
('a3151913-0338-5a3b-b6b4-71cad27163c1'::uuid,'./assets/menu-photos/alcohol-clean-v1/a3151913-0338-5a3b-b6b4-71cad27163c1.webp'),
('d22620a6-d9a4-59bb-83ad-7a692dfddcbe'::uuid,'./assets/menu-photos/alcohol-clean-v1/d22620a6-d9a4-59bb-83ad-7a692dfddcbe.webp')
) UPDATE public.products p SET image_url=photos.image_url FROM photos WHERE p.id=photos.id AND p.vendor_id='0fda82be-7bde-5187-9a15-0d8f12bbcd73' AND p.image_url LIKE '%alcohol-photo-unavailable.svg' RETURNING p.id,p.name;
COMMIT;
