/* Restaurant names and canonical product data stay untouched; only customer-facing menu text changes. */
(function(){
  "use strict";
  const categories={
    "İçecek Menüsü":["Beverages","İçecek Menüsü"],"Specials":["Specials","Özel Lezzetler"],
    "Kase Çeşitleri":["Bowl Varieties","Kase Çeşitleri"],"Günün Kaseleri":["Bowls of the Day","Günün Kaseleri"],
    "Salata Çeşitleri":["Salads","Salata Çeşitleri"],"Burger Çeşitleri":["Burgers","Burger Çeşitleri"],
    "Wrap Çeşitleri":["Wraps","Wrap Çeşitleri"],
    "SOSLAR":["Sauces","SOSLAR"],"SICAK İÇECEKLER":["Hot Drinks","SICAK İÇECEKLER"],
    "SOĞUK İÇECEKLER":["Cold Drinks","SOĞUK İÇECEKLER"],
    "EV YAPIMI BURGER DURAĞI":["Homemade Burgers","EV YAPIMI BURGER DURAĞI"],
    "BURGER STATION EKSTRALARI":["Burger Extras","BURGER STATION EKSTRALARI"],
    "PATATES DURAĞI":["Potato Sides","PATATES DURAĞI"],"ATIŞTIRMALIKLAR":["Snacks","ATIŞTIRMALIKLAR"],
    "BİRALAR":["Beers","BİRALAR"],"ŞARAPLAR":["Wines","ŞARAPLAR"],"KOKTEYLLER":["Cocktails","KOKTEYLLER"],
    "BOWL":["Bowls","Kaseler"],"MEAL DEAL":["Meal Deals","Menü Fırsatları"],
    "Klasikler / Classics":["Classics","Klasikler"],"Özel Lezzetler":["Specialties","Özel Lezzetler"],
    "İstantuni & Servis":["İstantuni & Service","İstantuni & Servis"],"Peynir Severlere":["For Cheese Lovers","Peynir Severlere"],
    "Yan Ürünler / Sides":["Sides","Yan Ürünler"],"İçecekler / Beverages":["Beverages","İçecekler"],
    "İrmik Helvaları":["Semolina Halva","İrmik Helvaları"],
    "Belçika Çikolatalı Kovada Waffle":["Belgian Chocolate Waffle Bucket","Belçika Çikolatalı Kovada Waffle"],
    "Belçika Çikolatalı Bubble Tabakta Waffle":["Belgian Chocolate Bubble Waffle Plate","Belçika Çikolatalı Bubble Tabakta Waffle"],
    "Krep Sarma":["Rolled Crepes","Krep Sarma"],"Bardak Waffle":["Waffle Cups","Bardak Waffle"],
    "Belçika Çikolatalı Kruvasan":["Belgian Chocolate Croissants","Belçika Çikolatalı Kruvasan"],
    "Pastalar":["Cakes","Pastalar"],"Sıcak İçecekler":["Hot Drinks","Sıcak İçecekler"],
    "Soğuk İçecekler":["Cold Drinks","Soğuk İçecekler"],
    "Dünya Kahveleri (Sıcak)":["World Coffees (Hot)","Dünya Kahveleri (Sıcak)"],
    "Dünya Kahveleri (Soğuk)":["World Coffees (Cold)","Dünya Kahveleri (Soğuk)"],
    "Başlangıçlar / Starters":["Starters","Başlangıçlar"],"Çorbalar / Soups":["Soups","Çorbalar"],
    "Salatalar / Salads":["Salads","Salatalar"],"Makarnalar / Pasta":["Pasta","Makarnalar"],
    "Pizzalar / Pizzas":["Pizzas","Pizzalar"],"Burgerler / Burgers":["Burgers","Burgerler"],
    "Desserts / Tatlılar":["Desserts","Tatlılar"],
    "Şefin Özel Izgara Lezzetleri / Chef's Special Grilled Flavors":["Chef's Grilled Specials","Şefin Özel Izgara Lezzetleri"],
    "İçecekler / Drinks • Meşrubatlar / Soft Drinks":["Soft Drinks","Meşrubatlar"],
    "İçecekler / Drinks • Kahveler / Coffees":["Coffees","Kahveler"],
    "Alkollü İçecekler / Alcoholic Beverages • Biralar / Beers":["Beers","Biralar"],
    "Alkollü İçecekler / Alcoholic Beverages • Şaraplar / Wines":["Wines","Şaraplar"],
    "Alkollü İçecekler / Alcoholic Beverages • Alkollü Kokteyler / Cocktails":["Cocktails","Kokteyller"],
    "Sweets Menu":["Sweets","Tatlılar"],"Hot Drinks Menu":["Hot Drinks","Sıcak İçecekler"],
    "Hot Chocolates Menu":["Hot Chocolates","Sıcak Çikolatalar"],"Cold Drinks Menu":["Cold Drinks","Soğuk İçecekler"],
    "Hot Coffees Menu":["Hot Coffees","Sıcak Kahveler"],"Iced Coffees Menu":["Iced Coffees","Soğuk Kahveler"],
    "Turkish Coffees Menu":["Turkish Coffees","Türk Kahveleri"],
    "Milkshake-Frozen-Lemonade Menu":["Milkshakes, Frozen Drinks & Lemonade","Milkshake, Frozen ve Limonata"],
    "Myra Special Menu":["Myra Specials","Myra Özel Lezzetleri"],"Ice Creams Menu":["Ice Creams","Dondurmalar"],
    "Extra Products Menu":["Extras","Ek Ürünler"],"Classic Donuts":["Classic Donuts","Klasik Donutlar"],
    "Filled Donuts":["Filled Donuts","Dolgulu Donutlar"],"Donut Cakes":["Donut Cakes","Donut Pastaları"],
    "Cheesecakes & Cups":["Cheesecakes & Cups","Cheesecake ve Bardak Tatlıları"],
    "Croissants":["Croissants","Kruvasanlar"],"Packs & Snacks":["Packs & Snacks","Paketler ve Atıştırmalıklar"],
    "Milkshake":["Milkshakes","Milkshake'ler"],"Frozen":["Frozen Drinks","Frozen İçecekler"],
    "Beverages":["Beverages","İçecekler"],"Drink":["Drinks","İçecekler"],"Other Items":["Other Items","Diğer Ürünler"]
  };
  const names={
    "Acı Sos":["Hot Sauce","Acı Sos"],"Burger Sos":["Burger Sauce","Burger Sos"],"Ranch Sos":["Ranch Sauce","Ranch Sos"],
    "Su":["Water","Su"],"Ayran":["Ayran","Ayran"],"Türk Kahvesi":["Turkish Coffee","Türk Kahvesi"],
    "Sade Soda":["Plain Soda","Sade Soda"],"Meyveli Soda":["Fruit Soda","Meyveli Soda"],
    "Çay":["Tea","Çay"],"Bitki Çayı":["Herbal Tea","Bitki Çayı"],
    "Sıcak Çikolata":["Hot Chocolate","Sıcak Çikolata"],"Beyaz Çikolatalı Latte":["White Chocolate Latte","Beyaz Çikolatalı Latte"]
    ,"Bardak Meyve Suyu (Vişne / Ananas / Greyfurt / Portakal)":["Fruit Juice (Cherry / Pineapple / Grapefruit / Orange)","Bardak Meyve Suyu (Vişne / Ananas / Greyfurt / Portakal)"],
    "Ev Yapımı Limonata":["Homemade Lemonade","Ev Yapımı Limonata"],"Füme Dana Jambon":["Smoked Beef Ham","Füme Dana Jambon"],
    "Fıstık Ezmesi":["Peanut Butter","Fıstık Ezmesi"],"Eritilmiş Peynir":["Melted Cheese","Eritilmiş Peynir"],
    "Hellim":["Halloumi","Hellim"],"Jalapeno Biber":["Jalapeño Pepper","Jalapeno Biber"],
    "KIRMIZI ŞARAP":["Red Wine","KIRMIZI ŞARAP"],"BEYAZ ŞARAP":["White Wine","BEYAZ ŞARAP"],
    "ROSE ŞARAP":["Rosé Wine","ROSE ŞARAP"],"Mantar":["Mushrooms","Mantar"],
    "PATATES KIZARTMASI":["French Fries","PATATES KIZARTMASI"],"Patates Kızartması":["French Fries","Patates Kızartması"],
    "Peynir":["Cheese","Peynir"],"Patlıcan Sos":["Eggplant Sauce","Patlıcan Sos"],
    "Siyah Çay":["Black Tea","Siyah Çay"],"Soğuk Americano":["Iced Americano","Soğuk Americano"],
    "Soğuk Latte":["Iced Latte","Soğuk Latte"],"Soğuk Nescafe":["Iced Nescafe","Soğuk Nescafe"],
    "Yumurta":["Egg","Yumurta"],"Avokado":["Avocado","Avokado"],
    "Blue Cheese":["Blue Cheese","Mavi Küflü Peynir"],"Mac & Cheese":["Mac & Cheese","Peynirli Makarna"],
    "CHICKEN BOWL":["Chicken Bowl","Tavuk Kasesi"],"MEATBALL BOWL":["Meatball Bowl","Köfte Kasesi"],
    "SALMON BOWL":["Salmon Bowl","Somon Kasesi"],"KLASİK BURGER":["Classic Burger","Klasik Burger"],
    "BURGER BAYILDI":["Burger Bayıldı","Burger Bayıldı"],
    "Hot Coffee":["Hot Coffee","Sıcak Kahve"],"Chocolate Donut":["Chocolate Donut","Çikolatalı Donut"]
  };
  const words=[
    ["Tavuklu","Chicken"],["Tavuk","Chicken"],["Köfteli","Meatball"],["Köfte","Meatball"],
    ["Dana","Beef"],["Somon","Salmon"],["Peynirli","Cheese"],["Peynir","Cheese"],
    ["Çikolatalı","Chocolate"],["Çikolata","Chocolate"],["Fıstıklı","Pistachio"],
    ["Fındıklı","Hazelnut"],["Muzlu","Banana"],["Çilekli","Strawberry"],
    ["Limonlu","Lemon"],["Portakallı","Orange"],["Ballı","Honey"],
    ["Karamelli","Caramel"],["Soslu","Sauce"],["Sos","Sauce"],
    ["Salatası","Salad"],["Salata","Salad"],["Kızartması","Fries"],
    ["Patates","Potato"],["Soğan","Onion"],["Halkası","Rings"],
    ["Kasesi","Bowl"],["Kase","Bowl"],["İçecek","Drink"],
    ["Sıcak","Hot"],["Soğuk","Iced"],["Beyaz","White"],["Kırmızı","Red"],
    ["Büyük","Large"],["Küçük","Small"],["Tek","Single"],["Adet","Pieces"],
    ["Burger","Burger"],["Wrap","Wrap"],["Donuts","Donutlar"],["Donut","Donut"],
    ["Filled","Dolgulu"],["Glazed","Sırlı"],["Classic","Klasik"],
    ["Chocolate","Çikolatalı"],["Strawberry","Çilekli"],["Banana","Muzlu"],
    ["Chicken","Tavuklu"],["Beef","Dana"],["Salmon","Somon"],
    ["Salad","Salata"],["Bowl","Kase"],["Sauce","Sos"],
    ["Fries","Patates Kızartması"],["Cheese","Peynirli"],
    ["Hot","Sıcak"],["Iced","Soğuk"],["Cold","Soğuk"],
    ["Large","Büyük"],["Small","Küçük"],["Pack","Paket"]
  ];
  function wordSwap(text,target){
    const split=words.findIndex(([from])=>from==="Donuts");
    const pairs=target==="en"?words.slice(0,split):words.slice(split);
    let changed=false,result=String(text||"");
    for(const [from,to] of pairs){
      const safe=from.replace(/[.*+?^${}()|[\]\\]/g,"\\$&");
      const re=new RegExp("(^|[^\\p{L}])("+safe+")(?=$|[^\\p{L}])","giu");
      result=result.replace(re,(_,prefix)=>{changed=true;return prefix+to;});
    }
    return changed?result:text;
  }
  function lang(){return document.documentElement.lang==="tr"?"tr":"en";}
  function locale(product){return (window.MEGJET_PRODUCT_TRANSLATIONS||{})[String(product.id)]||{};}
  function name(product){
    const translated=locale(product)["name_"+lang()];
    return translated||names[product.name]?.[lang()==="tr"?1:0]||wordSwap(product.name,lang())||product.name||"";
  }
  function description(product){
    const translated=locale(product)["description_"+lang()];
    if(translated!==undefined&&translated!==null)return translated;
    let text=String(product.description||"").replace(/^\[[^\]]+\]\s*/,"");
    if(lang()==="en")return text.replaceAll("Allergens: İnek Sütü","Allergens: Cow's milk").replaceAll("İnek Sütü","Cow's milk").replaceAll("Soya","Soy");
    return text.replaceAll("Allergens:","Alerjenler:").replaceAll("Cow's milk","İnek sütü").replaceAll("Gluten","Gluten").replaceAll("Soya","Soya");
  }
  function category(original,vendorId){
    const specific=(window.MEGJET_VENDOR_CATEGORY_META||[]).find(c=>String(c.vendor_id)===String(vendorId)&&c.name===original);
    return specific?.["name_"+lang()]||categories[original]?.[lang()==="tr"?1:0]||original;
  }
  function refresh(){
    const data=window.MEGJET_VENDOR_DATA;
    if(!data)return;
    const products=new Map((data.products||[]).map(p=>[String(p.id),p]));
    document.querySelectorAll("#vendorProfile [data-menu-product-id]").forEach(el=>{
      const p=products.get(el.dataset.menuProductId);if(!p)return;
      const title=el.querySelector("b"),detail=el.querySelector(".muted"),photo=el.querySelector("img");
      if(title)title.textContent=name(p);
      if(detail)detail.textContent=description(p);
      if(photo)photo.alt=name(p);
    });
    document.querySelectorAll("#vendorProfile [data-menu-category]").forEach(el=>{
      const localized=category(el.dataset.menuCategory,el.dataset.menuVendor);
      el.textContent=localized;
      const photo=el.closest("summary")?.querySelector("img.category-photo");
      if(photo)photo.alt=localized;
    });
  }
  window.MEGJET_MENU_LOCALE={name,description,category,refresh};
})();
