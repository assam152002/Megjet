with photos(name,image_url) as (values
('Beer','./assets/menu-photos/alcohol-clean-v1/54bd1d69-3388-5c91-91a3-baa368a11e9f.webp'),
('Wine','./assets/menu-photos/alcohol-clean-v1/392e28ff-26fa-524e-b0d0-8b6901dc40de.webp'),
('Whiskey','./assets/menu-photos/alcohol-clean-v1/f9bee8b2-a173-52a5-9350-dccb145cedc7.webp'),
('Vodka','./assets/menu-photos/alcohol-clean-v1/0c0dac95-73f9-580c-bbde-e791831dbb80.webp'),
('Gin','./assets/menu-photos/alcohol-clean-v1/c3f6bd26-d585-5e71-8803-26711f32f35a.webp'),
('Tequila','./assets/menu-photos/alcohol-clean-v1/6b7b6322-52fb-5b67-8975-f9774e0360f1.webp'),
('Liqueur','./assets/menu-photos/alcohol-clean-v1/6acc7f46-577c-5629-b210-e0afe5b7d048.webp'),
('Rakı','./assets/menu-photos/alcohol-clean-v1/5be433ac-1542-588c-974f-30f5198f81a0.webp')
), updated as (update public.vendor_menu_categories c set image_url=photos.image_url from photos where c.name=photos.name and c.vendor_id='0fda82be-7bde-5187-9a15-0d8f12bbcd73'::uuid returning c.name) select count(*) as updated_categories from updated;