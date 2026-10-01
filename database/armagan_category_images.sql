-- Category thumbnails reuse matching generated Armagan menu photographs.
BEGIN;
ALTER TABLE public.vendor_menu_categories DROP CONSTRAINT vendor_menu_categories_image_url_check;
ALTER TABLE public.vendor_menu_categories ADD CONSTRAINT vendor_menu_categories_image_url_check CHECK (image_url IS NULL OR (length(image_url)<=2048 AND (image_url ~ '^https://manuspenfcahagcstedd[.]supabase[.]co/storage/v1/object/public/category-images/' OR image_url ~ '^https://assam152002[.]github[.]io/Megjet/assets/(sparklin|armagan)/')));
UPDATE public.vendor_menu_categories c SET image_url=v.image_url FROM (VALUES
('Wraps', 'https://assam152002.github.io/Megjet/assets/armagan/01-meat-doner-wrap.webp'),
('Services', 'https://assam152002.github.io/Megjet/assets/armagan/08-meat-iskender.webp'),
('Oven Products', 'https://assam152002.github.io/Megjet/assets/armagan/19-mix-pita.webp'),
('Side Dishes', 'https://assam152002.github.io/Megjet/assets/armagan/25-fries.webp'),
('Drinks', 'https://assam152002.github.io/Megjet/assets/armagan/29-coca-cola-33-cl.webp')
) v(name,image_url) WHERE c.vendor_id='c6f0e4cc-e5cc-58cd-8232-541e400bf6ea' AND c.name=v.name;
COMMIT;
