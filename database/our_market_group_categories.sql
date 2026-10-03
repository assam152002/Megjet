begin;
update public.products set description=regexp_replace(description,'^\[([^]]+) · ([^]]+)\]', '[\1] [\2]') where vendor_id='06d76aea-1c94-5950-b621-22130e57ef75' and description ~ '^\[[^]]+ · [^]]+\]';
insert into public.vendor_menu_categories(vendor_id,name,name_en,name_tr,sort_order) values
('06d76aea-1c94-5950-b621-22130e57ef75','Water & Ice','Water & Ice','Su ve Buz',0),
('06d76aea-1c94-5950-b621-22130e57ef75','Drinks','Drinks','İçecekler',1),
('06d76aea-1c94-5950-b621-22130e57ef75','Snacks','Snacks','Atıştırmalıklar',2),
('06d76aea-1c94-5950-b621-22130e57ef75','Food','Food','Gıda',3),
('06d76aea-1c94-5950-b621-22130e57ef75','Meat & Chicken','Meat & Chicken','Et ve Tavuk',4),
('06d76aea-1c94-5950-b621-22130e57ef75','Basic Foods','Basic Foods','Temel Gıda',5),
('06d76aea-1c94-5950-b621-22130e57ef75','Dairy & Breakfast','Dairy & Breakfast','Süt Ürünleri ve Kahvaltılık',6),
('06d76aea-1c94-5950-b621-22130e57ef75','Bakery','Bakery','Fırın Ürünleri',7),
('06d76aea-1c94-5950-b621-22130e57ef75','Fit & Form','Fit & Form','Fit ve Form',8),
('06d76aea-1c94-5950-b621-22130e57ef75','Home Care','Home Care','Ev Bakımı',9),
('06d76aea-1c94-5950-b621-22130e57ef75','Home Life','Home Life','Ev ve Yaşam',10),
('06d76aea-1c94-5950-b621-22130e57ef75','Personal Care','Personal Care','Kişisel Bakım',11),
('06d76aea-1c94-5950-b621-22130e57ef75','Technology','Technology','Teknoloji',12),
('06d76aea-1c94-5950-b621-22130e57ef75','Sexual Health','Sexual Health','Cinsel Sağlık',13),
('06d76aea-1c94-5950-b621-22130e57ef75','Baby','Baby','Bebek',14),
('06d76aea-1c94-5950-b621-22130e57ef75','Clothing','Clothing','Giyim',15),
('06d76aea-1c94-5950-b621-22130e57ef75','Stationery','Stationery','Kırtasiye',16),
('06d76aea-1c94-5950-b621-22130e57ef75','Pet','Pet','Evcil Hayvan',17)
on conflict(vendor_id,name) do update set sort_order=excluded.sort_order,name_en=excluded.name_en,name_tr=excluded.name_tr;
delete from public.vendor_menu_categories where vendor_id='06d76aea-1c94-5950-b621-22130e57ef75' and name like '% · %';
do $$ begin
if (select count(*) from public.vendor_menu_categories where vendor_id='06d76aea-1c94-5950-b621-22130e57ef75')<>18 then raise exception 'Expected 18 market categories'; end if;
if (select count(*) from public.products where vendor_id='06d76aea-1c94-5950-b621-22130e57ef75')<>1876 then raise exception 'Product count changed'; end if;
end $$;
commit;
