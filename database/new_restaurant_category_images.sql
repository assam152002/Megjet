-- Use matching menu photos for the 22 categories of the three new restaurants.
BEGIN;
ALTER TABLE public.vendor_menu_categories DROP CONSTRAINT vendor_menu_categories_image_url_check;
ALTER TABLE public.vendor_menu_categories ADD CONSTRAINT vendor_menu_categories_image_url_check CHECK (image_url IS NULL OR (length(image_url)<=2048 AND (image_url ~ '^https://manuspenfcahagcstedd[.]supabase[.]co/storage/v1/object/public/category-images/' OR image_url ~ '^https://assam152002[.]github[.]io/Megjet/assets/(sparklin|armagan|menu-photos)/')));
UPDATE public.vendor_menu_categories c SET image_url=v.image_url FROM (VALUES
('5792a8da-aa87-5a06-8421-657261c3800c'::uuid,'Wraps','https://assam152002.github.io/Megjet/assets/menu-photos/cukurova-01.webp'),
('5792a8da-aa87-5a06-8421-657261c3800c'::uuid,'Kebabs & Grills','https://assam152002.github.io/Megjet/assets/menu-photos/cukurova-05.webp'),
('5792a8da-aa87-5a06-8421-657261c3800c'::uuid,'Salads','https://assam152002.github.io/Megjet/assets/menu-photos/cukurova-11.webp'),
('5792a8da-aa87-5a06-8421-657261c3800c'::uuid,'Side Dishes','https://assam152002.github.io/Megjet/assets/menu-photos/cukurova-13.webp'),
('5792a8da-aa87-5a06-8421-657261c3800c'::uuid,'Drinks','https://assam152002.github.io/Megjet/assets/armagan/29-coca-cola-33-cl.webp'),
('6d7aeeee-0826-5888-ba1d-f46dcc7548c5'::uuid,'Appetizer','https://assam152002.github.io/Megjet/assets/menu-photos/crispy-house-05.webp'),
('6d7aeeee-0826-5888-ba1d-f46dcc7548c5'::uuid,'Healthy Menu','https://assam152002.github.io/Megjet/assets/menu-photos/crispy-house-12.webp'),
('6d7aeeee-0826-5888-ba1d-f46dcc7548c5'::uuid,'Crispy','https://assam152002.github.io/Megjet/assets/menu-photos/crispy-house-15.webp'),
('6d7aeeee-0826-5888-ba1d-f46dcc7548c5'::uuid,'Burgers','https://assam152002.github.io/Megjet/assets/menu-photos/crispy-house-03.webp'),
('6d7aeeee-0826-5888-ba1d-f46dcc7548c5'::uuid,'Meatballs','https://assam152002.github.io/Megjet/assets/menu-photos/crispy-house-11.webp'),
('6d7aeeee-0826-5888-ba1d-f46dcc7548c5'::uuid,'Pizzas','https://assam152002.github.io/Megjet/assets/menu-photos/crispy-house-30.webp'),
('6d7aeeee-0826-5888-ba1d-f46dcc7548c5'::uuid,'Pastas','https://assam152002.github.io/Megjet/assets/menu-photos/crispy-house-35.webp'),
('6d7aeeee-0826-5888-ba1d-f46dcc7548c5'::uuid,'Soups & Salads','https://assam152002.github.io/Megjet/assets/menu-photos/crispy-house-41.webp'),
('6d7aeeee-0826-5888-ba1d-f46dcc7548c5'::uuid,'Drinks','https://assam152002.github.io/Megjet/assets/menu-photos/crispy-house-47.webp'),
('6d7aeeee-0826-5888-ba1d-f46dcc7548c5'::uuid,'Coffees','https://assam152002.github.io/Megjet/assets/menu-photos/crispy-house-53.webp'),
('a83e1b05-71fa-5b1f-ab35-1d8cca0c4ea9'::uuid,'Kebabs','https://assam152002.github.io/Megjet/assets/menu-photos/doydoy-01.webp'),
('a83e1b05-71fa-5b1f-ab35-1d8cca0c4ea9'::uuid,'Wraps','https://assam152002.github.io/Megjet/assets/menu-photos/doydoy-16.webp'),
('a83e1b05-71fa-5b1f-ab35-1d8cca0c4ea9'::uuid,'Oven Meals','https://assam152002.github.io/Megjet/assets/menu-photos/doydoy-26.webp'),
('a83e1b05-71fa-5b1f-ab35-1d8cca0c4ea9'::uuid,'Salads & Mezes','https://assam152002.github.io/Megjet/assets/menu-photos/doydoy-37.webp'),
('a83e1b05-71fa-5b1f-ab35-1d8cca0c4ea9'::uuid,'Soups','https://assam152002.github.io/Megjet/assets/menu-photos/doydoy-43.webp'),
('a83e1b05-71fa-5b1f-ab35-1d8cca0c4ea9'::uuid,'Desserts','https://assam152002.github.io/Megjet/assets/menu-photos/doydoy-44.webp'),
('a83e1b05-71fa-5b1f-ab35-1d8cca0c4ea9'::uuid,'Drinks','https://assam152002.github.io/Megjet/assets/armagan/29-coca-cola-33-cl.webp')
) v(vendor_id,name,image_url) WHERE c.vendor_id=v.vendor_id AND c.name=v.name AND c.image_url IS NULL;
COMMIT;
