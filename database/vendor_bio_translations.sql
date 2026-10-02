ALTER TABLE public.vendors ADD COLUMN IF NOT EXISTS bio_en text CHECK(char_length(bio_en)<=600), ADD COLUMN IF NOT EXISTS bio_tr text CHECK(char_length(bio_tr)<=600), ADD COLUMN IF NOT EXISTS bio_translation_source text;
CREATE OR REPLACE FUNCTION public.admin_set_vendor_bio_translations(p_vendor_id uuid,p_bio text,p_bio_en text,p_bio_tr text) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.megjet_require_admin();
 IF p_bio IS NULL OR greatest(char_length(btrim(p_bio)),char_length(btrim(coalesce(p_bio_en,''))),char_length(btrim(coalesce(p_bio_tr,''))))>600 THEN RAISE EXCEPTION 'Each restaurant bio must be at most 600 characters'; END IF;
 UPDATE public.vendors SET bio=btrim(p_bio),bio_en=nullif(btrim(p_bio_en),''),bio_tr=nullif(btrim(p_bio_tr),''),bio_translation_source=btrim(p_bio) WHERE id=p_vendor_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Vendor not found'; END IF;
END $$;
REVOKE ALL ON FUNCTION public.admin_set_vendor_bio_translations(uuid,text,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_set_vendor_bio_translations(uuid,text,text,text) TO authenticated;
-- Translations of the verified current public bios. Restaurant names stay unchanged.
UPDATE public.vendors v SET bio_en=t.en,bio_tr=t.tr,bio_translation_source=v.bio FROM (VALUES
('Armağan Döner (Salamis Yolu)','Döner, İskender and oven-baked specialities.','Döner, İskender ve fırın lezzetleri.'),
('Cafe 5','Best Homemade Burgers in town; Vegetarian & Vegan choices; Fresh desserts everyday; Coffee, wine, beers.','Şehrin en iyi ev yapımı burgerleri; vejetaryen ve vegan seçenekler; her gün taze tatlılar; kahve, şarap ve bira.'),
('Çikolata Evim Gazimağusa',E'Chocolate Shop\nA World of Happiness 🍫☕️\n🕙 10:00–00:30',E'Çikolata Dükkanı\nBir Dünya Mutluluk 🍫☕️\n🕙 10:00–00:30'),
('Crispy House (Sakarya)','Burgers, crispy chicken, pizza and pasta.','Burgerler, çıtır tavuk, pizza ve makarna.'),
('Çukurova Restorant (Gülseren)','Wraps, kebabs and grilled specialities.','Dürümler, kebaplar ve ızgaralar.'),
('Doy Doy Kebap - Künefe (Baykal)','Kebabs, wraps, oven-baked specialities and künefe.','Kebap, dürüm, fırın lezzetleri ve künefe.'),
('Helvacı Ali',E'🇹🇷 The world’s halva maker\n🗓️ Since 1900\n⏰ 10:00–01:00\n✒️ @helvaciali.kibris',E'🇹🇷 Dünyanın helvacısı\n🗓️ 1900’den Günümüze\n⏰ 10:00–01:00\n✒️ @helvaciali.kibris'),
('La Dolce-Bella',E'Whatever we did,\nWe did it with LOVE..',E'Her ne yaptıysak\nAŞK ile yaptık..'),
('NO.33 Limon Tantuni',E'🕰️ 11:30–21:30\n📍 CityMall, 2nd Floor\n📞 0539 102 43 33\n📣 A Globalland Property Ltd. establishment.',E'🕰️ 11:30–21:30\n📍 CityMall 2. Kat\n📞 0539 102 43 33\n📣 Globalland Property Ltd. kuruluşudur.'),
('Sparklin Kitchen',E'🥣 Daily healthy bowls | 🗓️ Subscription plans\n🛵 Delivery | Weekdays 08:00–17:00\n📍Mağusa, Cyprus',E'🥣 Günlük Sağlıklı Kaseler | 🗓️Abonelik sistemi\n🛵 Paket Servis | Hafta içi 08.00–17.00\n📍Mağusa, Kıbrıs'),
('Sweet Holes',E'Best Donuts in Cyprus! 🍩\nLefkoşa: 05338583232\nMağusa: 05338333233\nGirne: 05391053232',E'Kıbrıs’ın en iyi donutları! 🍩\nLefkoşa: 05338583232\nMağusa: 05338333233\nGirne: 05391053232')
) AS t(name,en,tr) WHERE v.name=t.name;
