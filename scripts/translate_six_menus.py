"""Reviewed customer text translations. Canonical restaurant/product names are untouched."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
menus=json.loads((ROOT/'data/six-restaurant-menus.json').read_text())
# Positional lists are checked against the import manifest before any SQL is emitted.
translations=[
'''Tavuk Döner Dürüm + Ayran
Soslu Tavuk Döner Dürüm + Ayran
Patatesli Tavuk Döner Dürüm + Ayran
Soslu Döner Servis + Ayran
Döner Adana + Ayran
Döner Ciğer + Ayran
Döner Et + Ayran
Tavuk Döner İskender + Ayran
Ekonomik Tavuk Menü + Ayran
Ekonomik Adana Menü + Ayran
Ekonomik Ciğer Menü + Ayran
Ekonomik Et Menü + Ayran
Ekonomik Kanat Menü + Ayran
Lahmacun
Kaşarlı Lahmacun
Kuşbaşı Kaşarlı Pide
Kıymalı Kaşarlı Pide
Kaşarlı Pide
Sucuklu Kaşarlı Pide
Karışık Pide
Kuşbaşı Kaşarlı Yumurtalı Pide
Kıymalı Kaşarlı Yumurtalı Pide
Sucuklu Yumurtalı Pide
Sucuklu Kaşarlı Yumurtalı Pide
Tam Karışık Pide
Mini Lahmacun
Sarımsaklı Lahmacun
Adana Dürüm
Tavuk Şiş Dürüm
Ciğer Dürüm
Et Şiş Dürüm
Karışık Dürüm
Çiğ Köfte Dürüm
Çiğ Köfte (10 Adet)
Çiğ Köfte (15 Adet)
Çiğ Köfte (1 Porsiyon)
Adana Kebap
Tavuk Şiş Servis
Ciğer Servis
Et Şiş Servis
Beyti Sarma
Izgara Kanat
Patlıcan Kebap
Adana - Tavuk Karışık
Adana - Et Şiş Karışık
Adana - Ciğer Şiş Karışık
Adana - Izgara Kanat Karışık
Tavuk Şiş - Et Şiş Karışık
Et Şiş - Ciğer Şiş Karışık
Et Şiş - Kanat Karışık
Et Şiş - Adana - Tavuk Şiş Karışık
Tam Karışık
Et Kavurma
Tavuk Kavurma
Ciğer Kavurma
Çıtır Tavuk
Kelle Paça Çorbası
Mercimek Çorbası
Domates Çorbası
Ezogelin Çorbası
Kaşarlı Salata
Tavuklu Salata
Mevsim Salata
Çoban Salata
Dip Salata
Patates Kızartması
Duble Porsiyon Patates Kızartması
Ayran
Coca-Cola (25 cl.)
Sprite (25 cl.)
7UP (25 cl.)
Fanta (25 cl.)
Yedigün (25 cl.)
Pepsi Max (25 cl.)
Coca-Cola Diet (25 cl.)
Şalgam Suyu
Meyveli Soda
Su''',
'''Ada Sandviç Menü
Ada Lavaş Dürüm
Bütün Tavuk Menü
Spor Menü (Yarım Tavuk)
Yarım Ekmek Kokoreç
Adana Porsiyon
Kasap Köfte Porsiyon
Kuzu Pirzola Porsiyon
Adana (1 Kg.)
Kuzu Pirzola (1 Kg.)
Çeyrek Ekmek Kokoreç
Kokoreç Servis
Atom Kokoreç
Bardak Ayran / Ev Yapımı Ayran
Meşrubat ve Meyve Suları (33 cl.)
Soda
Su''',
'''Ciğer Dürüm + Ayran
Tavuk Şiş Dürüm + Ayran
Adana Dürüm + Ayran
Kuzu Şiş Dürüm + Ayran
Köri Soslu Tavuk + İçecek
Ciğer Servis + Ayran
Izgara Köfte + Ayran
Et Kavurma + Ayran
Tavuk Kavurma + Ayran
Beyti Sarma + İçecek
Karışık Kebap + Ayran
Garson XXL Kebap + Ayran
Adana Servis + Ayran
Kuzu Şiş Servis + Ayran
Tavuk Şiş Servis + Ayran
Tavuk Kanat Servis + Ayran
Lahmacun
Kuşbaşı Kaşarlı Pide
Kıymalı Pide
Sosisli Peynirli Pide
Kıymalı Kaşarlı Pide
Kaşarlı Pide
Çıtır Tavuk Menü
Tavuk Dolma
Patates Kızartması
Çıtır Tavuk Salata
Kelle Çorbası
Mercimek Çorbası
Tavuk Çorbası
Çiğ Köfte Dürüm
Çiğ Köfte Servis
Coca-Cola (33 cl.)
Coca-Cola Zero (33 cl.)
Fanta (33 cl.)
Sprite (33 cl.)
Su (50 cl.)
Ayran (30 cl.)
Soda
Şalgam Suyu''',
'''Double King Burger
Duble Cheeseburger
Füme Dana Burger
Peynirli Burger
Klasik Burger
Çıtır Tavuk Burger
Izgara Tavuk Burger
Izgara Tavuk Dürüm
Ala Chickie Dürüm ve Cajun Patates
Tavuk Fajita Dürüm
Ayvalık Tost
Karışık Tost
Üç Peynirli Tost
Kaşarlı Tost
Meksika Usulü Dana Tost
Meksika Usulü Tavuk Tost
Döner Tost
Club Sandviç ve Cajun Patates
Dil Sandviç ve Cajun Patates
Meksika Usulü Dana Sandviç ve Cajun Patates
Meksika Usulü Tavuk Sandviç ve Cajun Patates
Kumru Sandviç ve Cajun Patates
Sosisli Sandviç ve Cajun Patates
Füme Sosisli Sandviç ve Cajun Patates
Peynirli Tavuk ve Mantar Sandviç ve Cajun Patates
Kasap Köfte Salata
Çıtır Tavuk Sezar Salata
Izgara Tavuk Sezar Salata
Izgara Hellim Sezar Salata
À La Etli Salata
À La Tavuklu Salata
Izgara Tavuk Salata
Izgara Hellim Salata
Kahvaltı Burrito + Patates
Füme Kahvaltı Burrito + Patates
Füme Yumurta ve Peynirli Burger
Sade Omlet
Peynirli Omlet
Menemen
Meksika Usulü Tavuk Quesadilla + Patates
Meksika Usulü Kıymalı Quesadilla + Patates
Meksika Usulü Tavuk Taquito + Patates
Meksika Usulü Kıymalı Taquito + Patates
Tavuk Fajita
Tavuk Fajita Dürüm + Cajun Patates
Meksika Usulü Tavuk Nachos
Meksika Usulü Kıymalı Nachos
Peynirli Nachos
Tavuk Tenders
Tavuk Kanat
Kanat ve Tenders
Tavuk Döner Dürüm + Cajun Patates
Tavuk Döner Sandviç + Cajun Patates
Tavuk Döner Burger + Cajun Patates
Tavuk Döner Servis
Tavuk Quesadilla + Cajun Patates
Arap Usulü Shawarma
Zereshk polo ba morgh
Chelo Kebab Kubide
Chelo Jooje Kebab
Karışık Kebap / Jooje Menü
Gheyneh / Jooje Menü
Kubje Menü / Gheymen bademjoon
Gherneh Menü / Karafs
Ghormeh sabzi
Sbzi polo mahi
Özel Dana Pizza
Şarküteri Pizza
Dil Pizza
Et ve Mantar Pizza
BBQ Füme Pizza
Karışık Pizza
Tavuk ve Mantar Pizza
Tavuk Döner Pizza
Dört Peynirli Pizza
Pepperoni Pizza
Vejetaryen Pizza
Margherita Pizza
Cola / Cola Zero / Sprite / Fanta (Kutu)
Fuse Tea
Ayran
Soda
Su
Yumurta
Hellim (2 Adet)
Kaşar Peyniri
Cheddar Peyniri
Mantar
Füme Dana (1 Dilim)
Salam
Sosis
Pepperoni
Lavaş''',
'''Espresso
Americano
Latte
Cappuccino
Mocha
Karamelli Latte
Vanilyalı Latte
Cortado
Türk Kahvesi
Soğuk Americano
Soğuk Latte
Soğuk Mocha
Soğuk Karamelli Latte
Soğuk Vanilyalı Latte
Poşet Çay
Sıcak Çikolata
Su
Soda
Cappy Meyve Suyu
Fuse Tea
Cola-Cola
Fanta
Sprite
Tiramisu
Lotus Cheesecake
Yanık Cheesecake
New York Cheesecake
Devil's Pasta
Brownie
Makaron (3 Adet)
Donut
Latte Pasta''',
'''English Breakfast
Cypriot Breakfast
Coffeeholic Breakfast
Plain Menemen
Mixed Menemen
Kasseri Cheese Menemen
Fried Egg Menemen
Plain Omelette
Kasseri Cheese Omelette
Mixed Omelette
Fried Egg Omelette
Cheese Gözleme
Halloumi Gözleme
Potato Gözleme
Kasseri Cheese Gözleme
Kasseri Cheese Toast
Mixed Toast
Pastırma Toast
Cheese Sandwich
Chicken Sandwich
Boly Beef Sandwich
Mixed Sandwich
Tuna Sandwich
Cheese Salad
Caesar Salad
Chicken Salad
Tuna Salad
Beef Fajita
Stuffed Chicken
Chicken Fajita
Chicken with Curry Sauce
Chicken with Mustard Sauce
Chicken with Mushroom Sauce
Grilled Wings
Chicken Tenders
Chicken Diana
Chicken Princess
Golden Chicken
BBQ Chicken
Grilled Chicken
Kentucy Wings
Sliced Doner over Rice
Sliced Doner Iskender
Sliced Doner Service
Lamb Skewer Kebab Service
Adana Kebab Service
Chicken Skewer Service
Sliced Doner Wrap
Lamb Skewer Wrap
Adana Wrap
Kentucy Chicken Wrap
Meatball Wrap
Steak Wrap
Chicken Skewer Wrap
Meat Pita
Cubed Meat Pita
Kasseri Cheese Pita
Lahmacun
Original Maraş Paça Soup
Beyran Soup
Lentil Soup
Chicken Soup
Fettucini Alfredo
Pesto Sauce Pasta
Spaghetti Bolognose
Spaghetti Napolitan
Cyprus Style
Pasta Eco 1 Menu
Pasta Eco 2 Menu
Italian Mix
BBQ Chicken
Margherita
Veggie Pizza
Chilli Chicken
Coffeholic Special
Pizza Eco 1 Menu (32 cm)
Pizza Eco 2 Menu (32 cm)
Chicken Burger
Beef Burger
Cheeseburger
Double Cheeseburger
Triple Cheeseburger
Cousin Menu
Twins Menu
I'm Hungry Menu
GYM Menu
Hot Snack Basket
Cheese Rolls (6 Pieces)
Onion Rings (6 Pieces)
Fries Plate
Mixed Baked Potato
Chicken Baked Potato
Tuna Baked Potato
Vegetarian Baked Potato
Macchiato
Americano
Latte
Cappuccino
Flat White
Mocha
White Mocha
Spanish Latte
Iced Americano
Iced Latte
Iced Mocha
Iced White Mocha
Iced Spanish Latte
Voltage / Frozen / Milkshake
Italian Soda / Lemonade
Smoothies / Freshly Squeezed Orange Juice
Coca Cola / Fanta / Sprite / Fuse Tea
Water
Soda
Ayran'''
]
categories='''Doners|Doners|Dönerler
Back To City Menu|Back To City Menu|Şehre Dönüş Menüsü
Pita & Lahmacun|Pita & Lahmacun|Pide ve Lahmacun
Wraps|Wraps|Dürümler
Çiğ Köfte|Çiğ Köfte|Çiğ Köfte
Services|Services|Servisler
Soups|Soups|Çorbalar
Salads|Salads|Salatalar
Side Dishes|Side Dishes|Yan Ürünler
Drinks|Drinks|İçecekler
Most Preferred|Most Preferred|En Çok Tercih Edilenler
Grilled Meats|Grilled Meats|Izgaralar
Kokoreç|Kokoreç|Kokoreç
Sandwich & Toast & Wrap|Sandwiches, Toasts & Wraps|Sandviç, Tost ve Dürüm
Service Menu|Service Menu|Servis Menüsü
Pitas|Pitas|Pideler
Other Dishes|Other Dishes|Diğer Yemekler
Handmade Burgers|Handmade Burgers|El Yapımı Burgerler
Toasts|Toasts|Tostlar
Sandwiches|Sandwiches|Sandviçler
Breakfasts|Breakfasts|Kahvaltılar
À La Mexicana|À La Mexicana|Meksika Lezzetleri
Tenders, Wings & Wingers|Tenders, Wings & Wingers|Tenders, Kanat ve Karışık Tavuk
Doners Menu|Doner Menu|Döner Menüsü
À La Persia|À La Persia|İran Lezzetleri
American Pizza (28 cm)|American Pizza (28 cm)|Amerikan Pizza (28 cm)
Drinks, Extras & Sauces|Drinks, Extras & Sauces|İçecekler, Ekstralar ve Soslar
Hot Coffees|Hot Coffees|Sıcak Kahveler
Cold Coffees|Cold Coffees|Soğuk Kahveler
Hot Drinks|Hot Drinks|Sıcak İçecekler
Cold Drinks|Cold Drinks|Soğuk İçecekler
Pastry|Pastry|Pastane Ürünleri
Kahvaltılık|Breakfast|Kahvaltılık
Menemen & Omlet|Menemen & Omelettes|Menemen ve Omlet
Gözleme, Tost & Sandviç|Gözleme, Toasts & Sandwiches|Gözleme, Tost ve Sandviç
Salatalar|Salads|Salatalar
Ana Yemekler|Main Courses|Ana Yemekler
Dürüm & Kebap Çeşitleri|Wraps & Kebabs|Dürüm ve Kebap Çeşitleri
Pideler & Çorbalar|Pitas & Soups|Pideler ve Çorbalar
Makarnalar|Pasta|Makarnalar
Pizzalar (32 cm / 42 cm)|Pizzas (32 cm / 42 cm)|Pizzalar (32 cm / 42 cm)
Hamburgerler & Fırsat Menüler|Burgers & Meal Deals|Hamburgerler ve Fırsat Menüler
Atıştırmalıklar & Kumpir|Snacks & Baked Potatoes|Atıştırmalıklar ve Kumpir
İçecekler & Kahveler|Drinks & Coffees|İçecekler ve Kahveler'''
cats={x.split('|')[0]:x.split('|')[1:] for x in categories.splitlines()}
descriptions='''1 Tavuk Burger + 1 Et Burger + 2 Coca Cola + 6 Soğan Halkası + 2 Porsiyon Patates Kızartması|1 chicken burger + 1 beef burger + 2 Coca Cola + 6 onion rings + 2 portions of fries
Ana Yemek + Salata + Pilav + Patates Kızartması + Coca Cola + Tatlı|Main course + salad + rice + fries + Coca Cola + dessert
Dana Kıyma|Minced beef
Domates Soslu|With tomato sauce
Domates, salatalık ve maydanoz ile servis edilir.|Served with tomatoes, cucumbers and parsley.
Domates, salatalık ve siyah zeytin ile servis edilir.|Served with tomatoes, cucumbers and black olives.
Domates, salatalık, siyah zeytin ve ekmek ile servis edilir. 2 adet yumurta kullanılır.|Made with 2 eggs; served with tomatoes, cucumbers, black olives and bread.
Domates, salatalık, siyah zeytin ve kızarmış patates ile servis edilir.|Served with tomatoes, cucumbers, black olives and fries.
Dürümler soğan, maydanoz, domates söğüşü ve 2 adet lavaş ile servis edilir.|Wraps are served with onions, parsley, sliced tomatoes and 2 lavash breads.
Et Jambon, Mısır, Mantar, Zeytin, Kırmızı Biber|Beef ham, corn, mushrooms, olives, red pepper
Herhangi 3 Makarna Al 2 Öde|Choose any 3 pastas, pay for 2
Herhangi 4 Makarna Al 3 Öde|Choose any 4 pastas, pay for 3
Herhangi 4 Pizza Al 3 Öde|Choose any 4 pizzas, pay for 3
Herhangi 6 Pizza Al 4 Öde|Choose any 6 pizzas, pay for 4
Izgara Tavuk + 2 Pilav + Salata + Soda|Grilled chicken + 2 servings of rice + salad + soda
Kentucy Tavuk Parçacıkları, Mısır, Mantar, Jalapeno Biber|Kentucy chicken pieces, corn, mushrooms, jalapeño pepper
Kentucy Tavuk Parçacıkları, Mısır, Mantar, Kırmızı Biber|Kentucy chicken pieces, corn, mushrooms, red pepper
Kıbrıs Patatesi, Mısır, Mantar, Zeytin, Rus Salatası|Cypriot potato, corn, mushrooms, olives, Russian salad
Kıbrıs Patatesi, Salam, Sucuk, Sosis, Mısır, Mantar, Zeytin, Rus Salatası|Cypriot potato, salami, sucuk, sausage, corn, mushrooms, olives, Russian salad
Kıbrıs Patatesi, Tavuk, Mısır, Mantar, Zeytin, Rus Salatası|Cypriot potato, chicken, corn, mushrooms, olives, Russian salad
Kıbrıs Patatesi, Ton Balığı, Mısır, Mantar, Zeytin, Rus Salatası|Cypriot potato, tuna, corn, mushrooms, olives, Russian salad
Kızartılmış Sosis (6 Adet), Salam (6 Adet), Hellim (6 Adet), Sigara Böreği (6 Adet), Patates (6 Adet)|Fried sausage (6 pieces), salami (6 pieces), halloumi (6 pieces), cheese rolls (6 pieces), potatoes (6 pieces)
Kızartılmış hellim, özel salata sosu, beyaz peynir, mevsim yeşillikleri|Fried halloumi, special salad dressing, white cheese, seasonal greens
Kızartılmış tavuk, sezar sos, mevsim yeşillikleri|Fried chicken, Caesar dressing, seasonal greens
Kızartılmış tavuk, özel salata sosu, mevsim yeşillikleri|Fried chicken, special salad dressing, seasonal greens
Mozarella Peyniri, Domates Parçacıkları|Mozzarella cheese, tomato pieces
Mısır, Mantar, Yeşil ve Kırmızı Biber, Zeytin|Corn, mushrooms, green and red peppers, olives
Patates Kızartması ile servis edilir.|Served with fries.
Pilav, patates kızartması ve salata ile servis edilir.|Served with rice, fries and salad.
Salam, Sucuk, Sosis, Yeşil ve Kırmızı Biber, Mısır, Zeytin, Mantar|Salami, sucuk, sausage, green and red peppers, corn, olives, mushrooms
Süzme yoğurt, soğan-maydanoz söğüşü, patates kızartması, kızartılmış domates-biber ve lavaş ile|With strained yoghurt, sliced onions and parsley, fries, fried tomatoes and peppers, and lavash
Tavuk - Mantar|Chicken - mushrooms
Tavuk Grill - Rendelenmiş Hellim|Grilled chicken - grated halloumi
Ton balığı, özel salata sosu, mevsim yeşillikleri|Tuna, special salad dressing, seasonal greens
Yeşillik, zeytin, tereyağ, limon ve ekmek ile servis edilir.|Served with greens, olives, butter, lemon and bread.
İtalyan Pizza 32cm + Vejeteryan Pizza 32cm + 2 Coca Cola + 6 Soğan Halkası + 2 Porsiyon Patates Kızartması|Italian pizza (32 cm) + vegetarian pizza (32 cm) + 2 Coca Cola + 6 onion rings + 2 portions of fries'''
desc_en=dict(x.split('|',1) for x in descriptions.splitlines())
english_desc='''150 g chicken, grilled vegetables|150 g tavuk, ızgara sebzeler
150 g crispy chicken|150 g çıtır tavuk
150 g grilled chicken, cajun fries|150 g ızgara tavuk, Cajun patates kızartması
Adana kebab, chicken skewer, lamb skewer + Salad, pita + Ayran|Adana kebap, tavuk şiş, kuzu şiş + salata, pide + ayran
Adana kebab, chicken skewer, lamb skewer, chicken wing, grilled meatball, liver skewer + Salad, pita + Ayran|Adana kebap, tavuk şiş, kuzu şiş, tavuk kanat, ızgara köfte, ciğer şiş + salata, pide + ayran
All sandwiches are served with Cajun fries|Tüm sandviçler Cajun patates kızartması ile servis edilir
Beef, corn, sweet pepper, kaşar|Dana eti, mısır, tatlı biber, kaşar
Chicken doner, kaşar cheese, sauce|Tavuk döner, kaşar peyniri, sos
Chicken, corn, sweet pepper, kaşar|Tavuk, mısır, tatlı biber, kaşar
Choice of Rice or Bulgur Pilaf, Mixed Pickles with Turnips, Bread|Pilav veya bulgur pilavı seçimi, şalgamlı karışık turşu, ekmek
Coca-Cola, Fanta, Sprite, Fuse Tea, Turnip Juice|Coca-Cola, Fanta, Sprite, Fuse Tea, şalgam suyu
Coleslaw, Roasted Mohair Chicken, Mixed Pickles with Turnips|Coleslaw, fırında tiftik tavuk, şalgamlı karışık turşu
Egg (2), sausage, sweet green & red pepper, kasseri cheese, optional sauce|Yumurta (2 adet), sosis, tatlı yeşil ve kırmızı biber, kaşar peyniri, isteğe bağlı sos
Egg, burger bread, smoky beef, kassericher, cheddar cheese|Yumurta, burger ekmeği, füme dana eti, kaşar ve cheddar peyniri
Egg, smoked beef slices, sausage, sweet green & red pepper, tomatoes, kasseri cheese-flavored chips|Yumurta, füme dana dilimleri, sosis, tatlı yeşil ve kırmızı biber, domates, kaşar peyniri aromalı patates
Eggs, tomatoes, tomato paste, sweet green and red pepper|Yumurta, domates, domates salçası, tatlı yeşil ve kırmızı biber
Fried egg (2), bread (2 piece), fresh tomatoes, cucumbers|Yumurta (2 adet), ekmek (2 dilim), taze domates, salatalık
Fried egg (2), kasseri cheese, sweet green an red pepper|Yumurta (2 adet), kaşar peyniri, tatlı yeşil ve kırmızı biber
Fries, ketchup, mayonnaise + Drink|Patates kızartması, ketçap, mayonez + içecek
Fries, rice, salad, bread|Patates kızartması, pilav, salata, ekmek
Grilled halloumi, kaşar, cheddar|Izgara hellim, kaşar, cheddar
Kaşar cheese only|Sadece kaşar peyniri
Ketchup, mayonnaise|Ketçap, mayonez
Olive, pickles, lemon, bread|Zeytin, turşu, limon, ekmek
Onion, Parsley, Tomato|Soğan, maydanoz, domates
Pickles + Ayran|Turşu + ayran
Pita, olive, lemon, greens|Pide, zeytin, limon, yeşillik
Salad + Ayran|Salata + ayran
Salad + Drink|Salata + içecek
Salad, fries, rice, pita + Ayran|Salata, patates kızartması, pilav, pide + ayran
Salad, pita + Ayran|Salata, pide + ayran
Salad, pita + Drink|Salata, pide + içecek
Salad, rice, fries, roasted pepper + Ayran|Salata, pilav, patates kızartması, köz biber + ayran
Salad, rice, fries, roasted pepper, bread + Ayran|Salata, pilav, patates kızartması, köz biber, ekmek + ayran
Salad, yoghurt, pickles + Ayran|Salata, yoğurt, turşu + ayran
Salami, sucuk, kaşar cheese|Salam, sucuk, kaşar peyniri
Salami, sucuk, sausage, kaşar cheese, sauce|Salam, sucuk, sosis, kaşar peyniri, sos
Served with Fries, Rice and Bread|Patates kızartması, pilav ve ekmek ile servis edilir
Served with Rice, Fries, Salad|Pilav, patates kızartması ve salata ile servis edilir
Served with Rice, Roasted Tomato, Roasted Pepper, Tablacı Salad, and Lavash|Pilav, köz domates, köz biber, tablacı salatası ve lavaş ile servis edilir
Served with Rice, Salad, Yoghurt and Bread|Pilav, salata, yoğurt ve ekmek ile servis edilir
Served with sauce & Cajun fries|Sos ve Cajun patates kızartması ile servis edilir
Tomato, parsley|Domates, maydanoz
Tomato, parsley, pickles, lemon|Domates, maydanoz, turşu, limon
Wings + Salad, pita + Ayran|Kanat + salata, pide + ayran'''
desc_tr=dict(x.split('|',1) for x in english_desc.splitlines())
def q(x):return "'"+x.replace("'","''")+"'"
sql=['BEGIN;'];rows=[]
for i,r in enumerate(menus):
 names=translations[i].splitlines();assert len(names)==len(r['products']),(r['name'],len(names),len(r['products']))
 for c in r['categories']:
  en,tr=cats[c];sql.append('UPDATE public.vendor_menu_categories SET name_en=%s,name_tr=%s WHERE vendor_id=%s AND name=%s;'%(q(en),q(tr),q(r['id']),q(c)))
 for p,t in zip(r['products'],names):
  d=p['description'];en,tr=(t,p['name']) if i==5 else (p['name'],t)
  if i==5: de,dt=desc_en[d] if d else '',d
  else:de,dt=d,desc_tr[d] if d else ''
  if i==4:
   if p['name']=='Poşet Çay / Bag Tea':en='Bag Tea'
   if p['name']=='Su / Water':en='Water'
   if p['name']=='Türk Kahvesi':en='Turkish Coffee'
   if p['name']=='Yanık Cheesecake':en='Burnt Cheesecake'
   if p['name']=='Macaron (3 Adet)':en='Macaron (3 Pieces)'
  row=dict(product_id=p['id'],name_en=en,name_tr=tr,description_en=de,description_tr=dt);rows.append(row)
  sql.append('INSERT INTO public.product_translations(product_id,name_en,name_tr,description_en,description_tr) VALUES (%s,%s,%s,%s,%s) ON CONFLICT(product_id) DO NOTHING;'%(q(p['id']),q(en),q(tr),q(de),q(dt)))
sql.append('COMMIT;')
(ROOT/'database/six_restaurant_translations.sql').write_text('\n'.join(sql)+'\n')
(ROOT/'data/six-restaurant-locales.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
print('Validated',len(rows),'bilingual product records and all category translations')
