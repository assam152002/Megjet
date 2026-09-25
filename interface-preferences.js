/* Interface labels only. Restaurant names, product names and customer content stay as entered. */
(function(){
  "use strict";
  const tr={
    "Cargo & Delivery • Yeni Nesil Kurye":"Kargo ve Teslimat • Yeni Nesil Kurye",
    "Megjet — Gazimagusa • Food Delivery":"Megjet — Gazimağusa • Yemek Teslimatı",
    "App preferences":"Uygulama tercihleri","Search":"Ara","🍽️ Megjet":"🍽️ Megjet",
    "Credit: ₺ 0":"Kredi: ₺ 0","Lifetime: 0":"Toplam: 0",
    "Redeem 100 or more points in multiples of 100. The reward credit is automatically applied to your next account order.":"En az 100 puanı, 100'ün katları halinde kullanın. Ödül kredisi hesabınızdan vereceğiniz bir sonraki siparişe otomatik uygulanır.",
    "📱 WhatsApp support uses secure click-to-chat links. 🔔 Browser/in-app order alerts are enabled for Admin. 💳 Online payments remain OFF until you request them.":"📱 WhatsApp desteği güvenli bağlantılarla çalışır. 🔔 Yönetici için tarayıcı ve uygulama içi sipariş bildirimleri açıktır. 💳 Talep edene kadar çevrim içi ödeme kapalıdır.",
    "My Account":"Hesabım","Admin":"Yönetici","Vendor Login":"İşletme Girişi","Rider Login":"Kurye Girişi",
    "Language":"Dil","Appearance":"Görünüm","Light":"Açık","Dark":"Koyu",
    "delivery":"teslimat","Megjet is ready • Checking live connection…":"Megjet hazır • Canlı bağlantı kontrol ediliyor…",
    "Fresh food. Great taste. Delivered to you. 🍽️":"Taze yemek. Harika lezzet. Kapınıza gelsin. 🍽️",
    "Fresh food from local restaurants and vendors — delivered across your Megjet service area.":"Yerel restoranlardan taze yemekler Megjet hizmet bölgenizde kapınıza gelsin.",
    "🍽️ Food":"🍽️ Yemek","🍔 Meals":"🍔 Öğünler","🍕 Pizza":"🍕 Pizza","🍟 Snacks":"🍟 Atıştırmalıklar","🍺 Alcohol Market":"🍺 Alkol Marketi","🎉 Events":"🎉 Etkinlikler","Popular near you":"Yakınınızdaki popüler yerler",
    "👤 My Megjet Account":"👤 Megjet Hesabım","Your account, orders and quick reorders.":"Hesabınız, siparişleriniz ve hızlı yeniden sipariş.",
    "Create Account":"Hesap Oluştur","Sign In":"Giriş Yap","Sign in":"Giriş Yap","Sign out":"Çıkış Yap","Sign Out":"Çıkış Yap",
    "Welcome to Megjet 👋":"Megjet'e hoş geldiniz 👋","👤 Profile":"👤 Profil","Profile":"Profil",
    "Keep your contact details and delivery addresses ready for checkout.":"İletişim bilgilerinizi ve teslimat adreslerinizi sipariş için hazır tutun.",
    "Save Profile":"Profili Kaydet","📍 Saved Addresses":"📍 Kayıtlı Adresler",
    "Save home, office or event locations and choose one at checkout.":"Ev, iş veya etkinlik adreslerinizi kaydedip ödeme sırasında seçin.",
    "Set as default address":"Varsayılan adres yap","Add Address":"Adres Ekle","⭐ Megjet Rewards":"⭐ Megjet Ödülleri",
    "Earn 1 point for every ₺ 10 of delivered order value. 100 points = ₺0 reward value.":"Teslim edilen siparişlerin her ₺10 tutarı için 1 puan kazanın. 100 puanın ödül değeri ₺0.",
    "Available points":"Kullanılabilir puanlar","Refresh Rewards":"Ödülleri Yenile","🎁 Your Referral Code":"🎁 Davet Kodunuz",
    "Share this code with a friend. You earn 100 bonus points after their first delivered order.":"Bu kodu arkadaşınızla paylaşın. İlk siparişi teslim edildiğinde 100 bonus puan kazanın.",
    "Copy":"Kopyala","Have a referral code?":"Davet kodunuz var mı?","Redeem Rewards":"Ödül Kullan","Redeem":"Kullan",
    "📦 My Orders":"📦 Siparişlerim","Your orders are securely linked to your Megjet account. Account actions are protected.":"Siparişleriniz Megjet hesabınıza güvenli biçimde bağlıdır.",
    "Refresh Orders":"Siparişleri Yenile","Connect Megjet":"Megjet'e Bağlan",
    "Enter your Supabase Project URL and Publishable Key. They are stored only in this browser.":"Supabase proje adresinizi ve yayınlanabilir anahtarınızı girin. Bilgiler yalnızca bu tarayıcıda saklanır.",
    "Connect":"Bağlan","Your Cart":"Sepetiniz","View Cart":"Sepeti Gör","Hide Cart":"Sepeti Gizle","Checkout":"Siparişi Tamamla",
    "Delivery details":"Teslimat bilgileri","Use a saved address…":"Kayıtlı adres seçin…",
    "Choose a saved address or enter a new one below.":"Kayıtlı adres seçin veya aşağıya yeni bir adres girin.",
    "💳 Payment":"💳 Ödeme","Cash on Delivery":"Kapıda Ödeme","Credit / Debit Card — coming soon":"Kredi / Banka Kartı — yakında",
    "Cash on Delivery is available. Card payment will be added when a payment gateway is connected.":"Kapıda ödeme kullanılabilir. Ödeme altyapısı bağlandığında kartla ödeme eklenecek.",
    "🎟️ Coupon":"🎟️ Kupon","Coupon":"Kupon","Discount":"İndirim","Subtotal":"Ara Toplam","Delivery":"Teslimat","Total":"Toplam","Payable Total":"Ödenecek Tutar",
    "Place order":"Sipariş Ver","🎉 Order placed successfully!":"🎉 Siparişiniz başarıyla alındı!",
    "Thank you for ordering from Megjet. We'll contact you shortly to confirm your order.":"Megjet'ten sipariş verdiğiniz için teşekkürler. Onay için kısa süre içinde sizinle iletişime geçeceğiz.",
    "Order Status:":"Sipariş Durumu:","Track My Order":"Siparişimi Takip Et","Continue Shopping":"Alışverişe Devam Et",
    "📦 Track Your Order":"📦 Siparişinizi Takip Edin","Your order status updates from the Megjet admin dashboard.":"Sipariş durumunuz Megjet yönetim panelinden güncellenir.",
    "🛵 Live Rider Location":"🛵 Canlı Kurye Konumu","LIVE":"CANLI","Waiting for rider location…":"Kurye konumu bekleniyor…",
    "🗺️ Open location in Maps":"🗺️ Konumu Haritada Aç","⭐ Rate Your Delivered Order":"⭐ Teslim Edilen Siparişi Değerlendirin",
    "Thank you! Rate each vendor and your rider.":"Teşekkürler! İşletmeleri ve kuryenizi değerlendirin.",
    "🛵 Rider Rating":"🛵 Kurye Puanı","Submit Reviews":"Değerlendirmeleri Gönder",
    "📦 Your Recent Order":"📦 Son Siparişiniz","View Order":"Siparişi Gör","🔎 Track an Existing Order":"🔎 Mevcut Siparişi Takip Edin",
    "Enter the order number and the phone number used when placing the order.":"Sipariş numarasını ve siparişte kullanılan telefon numarasını girin.",
    "Track Order":"Siparişi Takip Et","Pending":"Beklemede","Confirmed":"Onaylandı","Preparing":"Hazırlanıyor",
    "Ready for Pickup":"Teslim Almaya Hazır","Out for Delivery":"Dağıtımda","Delivered":"Teslim Edildi","Cancelled":"İptal Edildi",
    "Add":"Ekle","Available":"Mevcut","Unavailable":"Mevcut Değil","Sold Out":"Tükendi","Remove":"Kaldır","Apply":"Uygula","Clear":"Temizle",
    "Refresh":"Yenile","Cancel":"İptal","Save Changes":"Değişiklikleri Kaydet","Delete":"Sil","Edit":"Düzenle","Close":"Kapat",
    "No photo yet":"Henüz fotoğraf yok","Sample photo":"Örnek fotoğraf","Photo added":"Fotoğraf eklendi","Upload Photo":"Fotoğraf Yükle","Change Photo":"Fotoğrafı Değiştir",
    "🏪 Vendor Portal":"🏪 İşletme Paneli","Sign in with your vendor account.":"İşletme hesabınızla giriş yapın.",
    "Vendor Dashboard":"İşletme Paneli","Your orders and sales overview":"Siparişleriniz ve satış özetiniz",
    "⚡ Quick Operations":"⚡ Hızlı İşlemler","Fast controls for daily vendor work.":"Günlük işletme işleri için hızlı kontroller.",
    "🏪 Store Status":"🏪 İşletme Durumu","📋 Open Active Orders":"📋 Aktif Siparişleri Aç","🍵 My Menu":"🍵 Menüm",
    "Search any of your menu items, then upload or change its photo.":"Menü ürünlerini arayın, ardından fotoğraf yükleyin veya değiştirin.",
    "📋 View Orders by Status":"📋 Duruma Göre Siparişler",
    "Choose a status to see only your vendor's orders in that stage, including cancelled orders.":"İptal edilenler dahil yalnızca seçilen durumdaki işletme siparişlerini görün.",
    "All Orders":"Tüm Siparişler","All orders":"Tüm siparişler","🛵 Rider Portal":"🛵 Kurye Paneli",
    "Sign in with your rider phone number and password/PIN.":"Kurye telefon numaranız ve şifreniz/PIN'inizle giriş yapın.",
    "🛵 Rider Dashboard":"🛵 Kurye Paneli","Your assigned deliveries":"Size atanan teslimatlar",
    "🟢 Rider Availability":"🟢 Kurye Müsaitliği","Go available when you are ready to receive deliveries.":"Teslimat almaya hazır olduğunuzda müsait durumuna geçin.",
    "Set Availability":"Müsaitliği Ayarla","📦 Active Delivery":"📦 Aktif Teslimat",
    "📍 Live location sharing is off until you have an Out for Delivery order.":"Dağıtımda bir siparişiniz olana kadar canlı konum paylaşımı kapalıdır.",
    "Admin Orders":"Yönetici Siparişleri","Sign in with the Megjet admin account.":"Megjet yönetici hesabıyla giriş yapın.",
    "Dashboard":"Panel","Manage Megjet orders":"Megjet siparişlerini yönetin",
    "Admin access is restricted to the configured Megjet admin account.":"Yönetici erişimi yalnızca tanımlı Megjet yönetici hesabına açıktır.",
    "📊 Overview":"📊 Genel Bakış","🧾 Orders":"🧾 Siparişler","🏪 Vendors":"🏪 İşletmeler","🛵 Riders":"🛵 Kuryeler",
    "🍵 Menu":"🍵 Menü","💰 Sales":"💰 Satışlar","🎟️ Coupons":"🎟️ Kuponlar","🤝 Vendors":"🤝 İşletmeler",
    "⭐ Reviews":"⭐ Değerlendirmeler","🚀 Growth":"🚀 Büyüme","⚙️ Settings":"⚙️ Ayarlar",
    "⚡ Operations Snapshot":"⚡ İşlem Özeti","Quick view of what needs attention right now.":"Şu anda ilgilenmeniz gerekenleri hızlıca görün.",
    "📦 Orders Today":"📦 Bugünkü Siparişler","💰 Revenue Today":"💰 Bugünkü Gelir","🔄 Active Orders":"🔄 Aktif Siparişler",
    "🛵 Out for Delivery":"🛵 Dağıtımda","🛵 Riders Available":"🛵 Müsait Kuryeler","🏪 Active Vendors":"🏪 Aktif İşletmeler",
    "⏳ Pending":"⏳ Beklemede","📦 Ready for Pickup":"📦 Teslim Almaya Hazır","🚚 Delivery in Progress":"🚚 Devam Eden Teslimatlar",
    "🚨 Attention Needed":"🚨 İlgi Gerekenler","🔔 Enable Notifications":"🔔 Bildirimleri Aç",
    "New order received.":"Yeni sipariş alındı.","View New Orders":"Yeni Siparişleri Gör",
    "⚡ Loading Admin data in parallel…":"⚡ Yönetici verileri yükleniyor…","🔎 Global Search":"🔎 Genel Arama",
    "Search customers, orders, vendors, riders and menu items from one place.":"Müşterileri, siparişleri, işletmeleri, kuryeleri ve menüleri tek yerden arayın.",
    "Type something to search.":"Aramak için bir şey yazın.","New orders will be checked automatically.":"Yeni siparişler otomatik kontrol edilecek.",
    "🤖 Auto-Assign Ready Orders":"🤖 Hazır Siparişleri Otomatik Ata","Assigns ready orders to active available riders.":"Hazır siparişleri aktif ve müsait kuryelere atar.",
    "Vendor Management":"İşletme Yönetimi","Add, edit, activate or deactivate vendors.":"İşletmeleri ekleyin, düzenleyin, etkinleştirin veya devre dışı bırakın.",
    "+ Add Vendor":"+ İşletme Ekle","Add Vendor":"İşletme Ekle","Edit Vendor":"İşletmeyi Düzenle",
    "Restaurant bio":"Restoran tanıtımı","Shown below the restaurant banner. Up to 600 characters.":"Restoran görselinin altında gösterilir. En fazla 600 karakter.",
    "Vendor logo":"İşletme logosu","Choose a JPG, PNG or WebP logo.":"JPG, PNG veya WebP logo seçin.",
    "Remove uploaded logo":"Yüklenen logoyu kaldır","Vendor banner":"İşletme kapak görseli",
    "Choose a wide JPG, PNG or WebP banner.":"Yatay bir JPG, PNG veya WebP kapak görseli seçin.",
    "Remove uploaded banner":"Yüklenen kapak görselini kaldır","Active for customers":"Müşterilere açık",
    "Save Vendor":"İşletmeyi Kaydet","Save Photos":"Fotoğrafları Kaydet","Loading vendors…":"İşletmeler yükleniyor…",
    "🛵 Rider Management":"🛵 Kurye Yönetimi","Add, edit, activate/deactivate riders and manage their login password.":"Kuryeleri ekleyin ve düzenleyin; durumlarını ve şifrelerini yönetin.",
    "+ Add Rider":"+ Kurye Ekle","Refresh Riders":"Kuryeleri Yenile","Add Rider":"Kurye Ekle","Save Rider":"Kuryeyi Kaydet",
    "Active rider":"Aktif kurye","Available for assignments":"Atamalara müsait","Loading riders…":"Kuryeler yükleniyor…",
    "Menu Management":"Menü Yönetimi",
    "Add, edit, enable or disable customer menu items. Duplicate item names are allowed when they belong to different vendors.":"Menü ürünlerini ekleyin, düzenleyin veya kapatın. Farklı işletmelerde aynı ürün adı kullanılabilir.",
    "All vendors":"Tüm işletmeler","Add Menu Item":"Menü Ürünü Ekle","+ Add Menu Item":"+ Menü Ürünü Ekle",
    "Product Picture":"Ürün Fotoğrafı","Available to customers":"Müşterilere sunuluyor","Save Item":"Ürünü Kaydet","+ Add Item":"+ Ürün Ekle",
    "Each menu item has its own internal Product ID. Items with the same name from different vendors remain separate.":"Her menü ürününün ayrı bir ürün kimliği vardır. Farklı işletmelerdeki aynı adlı ürünler ayrı tutulur.",
    "💰 Sales & Finance":"💰 Satış ve Finans","Only Delivered orders count as completed sales.":"Yalnızca teslim edilen siparişler tamamlanan satış sayılır.",
    "Product sales and delivery revenue are tracked separately.":"Ürün satışları ve teslimat gelirleri ayrı izlenir.",
    "Refresh Sales":"Satışları Yenile","🏪 Sales by Vendor":"🏪 İşletmeye Göre Satışlar",
    "Vendor product sales from Delivered orders only.":"Yalnızca teslim edilen siparişlerdeki işletme ürün satışları.",
    "🥇 Best-Selling Items":"🥇 En Çok Satan Ürünler","Ranked by quantity sold from Delivered orders.":"Teslim edilen siparişlerde satılan adede göre sıralanır.",
    "📅 Sales by Day":"📅 Günlük Satışlar","Last 7 days, based on Delivered orders.":"Teslim edilen siparişlere göre son 7 gün.",
    "🎟️ Coupon Manager":"🎟️ Kupon Yönetimi","Create simple percentage or fixed-amount discounts.":"Yüzde veya sabit tutarlı indirimler oluşturun.",
    "Percent":"Yüzde","Fixed ₺":"Sabit ₺","Create Coupon":"Kupon Oluştur","Loading coupons…":"Kuponlar yükleniyor…",
    "🤝 Vendor Applications":"🤝 İşletme Başvuruları",
    "Review new vendor applications. Approved vendors can then be connected to a vendor account.":"Yeni işletme başvurularını inceleyin. Onaylanan işletmeler hesaba bağlanabilir.",
    "Loading applications…":"Başvurular yükleniyor…","⭐ Customer Reviews":"⭐ Müşteri Değerlendirmeleri",
    "Ratings submitted after completed deliveries.":"Tamamlanan teslimatlardan sonra gönderilen puanlar.","Loading reviews…":"Değerlendirmeler yükleniyor…",
    "🚀 Growth & Revenue":"🚀 Büyüme ve Gelir","Loyalty, referrals, promotions, featured listings and vendor commission.":"Sadakat, davetler, kampanyalar, öne çıkanlar ve işletme komisyonu.",
    "📢 Promotions":"📢 Kampanyalar","No link":"Bağlantı yok","Product ID":"Ürün Kimliği","Vendor ID":"İşletme Kimliği",
    "Coupon code":"Kupon kodu","Active now":"Şu anda aktif","Create Promotion":"Kampanya Oluştur",
    "⭐ Featured Products":"⭐ Öne Çıkan Ürünler","🏪 Featured Vendors & Commission":"🏪 Öne Çıkan İşletmeler ve Komisyon",
    "Refresh Growth Dashboard":"Büyüme Panelini Yenile","⚙️ Megjet Settings":"⚙️ Megjet Ayarları",
    "Control delivery fee, service area, opening hours and customer support from one place.":"Teslimat ücretini, hizmet alanını, çalışma saatlerini ve desteği tek yerden yönetin.",
    "Save Delivery Fee":"Teslimat Ücretini Kaydet","Store is accepting new orders":"İşletme yeni sipariş alıyor","Save Launch Settings":"Açılış Ayarlarını Kaydet",
    "🤝 Become a Megjet Vendor":"🤝 Megjet İşletmesi Olun",
    "Own a food business in Gazimagusa? Send your details and our admin team can review your application.":"Gazimağusa'da bir yiyecek işletmeniz mi var? Bilgilerinizi gönderin, ekibimiz başvurunuzu incelesin.",
    "Submit Vendor Application":"İşletme Başvurusu Gönder","0 items":"0 ürün","Thank you for ordering from Megjet!":"Megjet'ten sipariş verdiğiniz için teşekkürler!",
    "Search food, restaurants, meals or snacks…":"Yemek, restoran veya atıştırmalık arayın…",
    "Your name":"Adınız","Phone number":"Telefon numarası","Email address":"E-posta adresi","Password":"Şifre",
    "Password (minimum 6 characters)":"Şifre (en az 6 karakter)","Full name":"Ad soyad",
    "Label (e.g. Home, Office)":"Etiket (örn. Ev, İş)","Full delivery address":"Açık teslimat adresi",
    "Area (e.g. Gazimagusa)":"Bölge (örn. Gazimağusa)","Delivery phone":"Teslimat telefonu",
    "Points to redeem":"Kullanılacak puan","Megjet categories":"Megjet kategorileri",
    "Supabase Project URL":"Supabase proje adresi","Supabase Publishable Key":"Supabase yayınlanabilir anahtarı",
    "Delivery address in Gazimagusa":"Gazimağusa teslimat adresi","Optional comment (applies to your vendor reviews)":"İsteğe bağlı yorum (işletme değerlendirmeleri için)",
    "Order number (e.g. BE424888)":"Sipariş numarası (örn. BE424888)","Vendor phone number":"İşletme telefon numarası",
    "🔎 Search your menu item…":"🔎 Menü ürününüzü arayın…","View vendor orders by status":"İşletme siparişlerini duruma göre göster",
    "Rider phone number":"Kurye telefon numarası","Password / PIN":"Şifre / PIN","Admin email":"Yönetici e-postası",
    "Admin sections":"Yönetici bölümleri","Search name, phone, order #, vendor, rider or menu item…":"Ad, telefon, sipariş, işletme, kurye veya ürün arayın…",
    "Search name, phone, address or order #":"Ad, telefon, adres veya sipariş no arayın",
    "Vendor name":"İşletme adı","Area":"Bölge","Vendor phone":"İşletme telefonu","Full vendor address":"İşletmenin açık adresi",
    "Tell customers about this restaurant…":"Müşterilere bu restoranı anlatın…","Rating (e.g. 4.8)":"Puan (örn. 4,8)",
    "Preparation time (minutes)":"Hazırlık süresi (dakika)","Portal password (6+ characters)":"Panel şifresi (6+ karakter)",
    "Rider name":"Kurye adı","Login password (minimum 6 characters)":"Giriş şifresi (en az 6 karakter)",
    "Search existing menu items…":"Menüdeki ürünleri arayın…","Search menu items":"Menü ürünlerini arayın","Filter menu by vendor":"Menüyü işletmeye göre filtrele",
    "Item name":"Ürün adı","Category (e.g. Burgers, Desserts)":"Kategori (örn. Burgerler, Tatlılar)",
    "Short description":"Kısa açıklama","Price (₺)":"Fiyat (₺)","Code e.g. CHAI10":"Kod, örn. CHAI10",
    "Minimum order":"Minimum sipariş","Max discount (optional)":"Maksimum indirim (isteğe bağlı)",
    "Promotion title":"Kampanya başlığı","Short subtitle":"Kısa alt başlık","Image URL (optional)":"Görsel adresi (isteğe bağlı)",
    "Link value (optional)":"Bağlantı değeri (isteğe bağlı)","Sort order":"Sıralama",
    "Delivery fee (₺)":"Teslimat ücreti (₺)","Minimum order (₺)":"Minimum sipariş (₺)","e.g. CHAI-AB12CD34":"örn. CHAI-AB12CD34",
    "Service area e.g. Gazimagusa":"Hizmet bölgesi, örn. Gazimağusa","Support phone":"Destek telefonu",
    "WhatsApp number (digits only)":"WhatsApp numarası (yalnızca rakam)","Business name":"İşletme adı",
    "Contact person":"İlgili kişi","Email (optional)":"E-posta (isteğe bağlı)",
    "Menu, timings or anything else":"Menü, çalışma saatleri veya diğer bilgiler",
    "Loading…":"Yükleniyor…","Loading menu…":"Menü yükleniyor…","Checking…":"Kontrol ediliyor…",
    "Add to cart":"Sepete ekle","Make Available":"Satışa Aç","Deactivate":"Devre Dışı Bırak","Activate":"Etkinleştir",
    "Active":"Aktif","Inactive":"Pasif","Online":"Çevrim içi","Offline":"Çevrim dışı",
    "Accept":"Kabul Et","Reject":"Reddet","Approve":"Onayla","Assign Rider":"Kurye Ata",
    "Mark Ready":"Hazır Olarak İşaretle","Change Password":"Şifre Değiştir","View Menu":"Menüyü Gör","Open Menu":"Menüyü Aç",
    "Ready for pickup":"Teslim Almaya Hazır","Out for delivery":"Dağıtımda","Delivered ✓":"Teslim Edildi ✓"
  };

  const attrs=["placeholder","title","aria-label"];
  const textHistory=new WeakMap();
  const attrHistory=new WeakMap();
  let language="en",scheduled=false;

  function phrase(source){
    if(Object.prototype.hasOwnProperty.call(tr,source))return tr[source];
    let m=source.match(/^(\d+) items?$/i);
    if(m)return m[1]+" ürün";
    m=source.match(/^(\d+) menu items?$/i);
    if(m)return m[1]+" menü ürünü";
    m=source.match(/^(\d+) of (\d+) items?$/i);
    if(m)return m[1]+" / "+m[2]+" ürün";
    m=source.match(/^([₺\d., ]+) delivery$/);
    if(m)return m[1]+" teslimat";
    m=source.match(/^🍵 Open (.+) Menu$/);
    if(m)return "🍵 "+m[1]+" Menüsünü Aç";
    m=source.match(/^Welcome, (.+) 👋$/);
    if(m)return "Hoş geldiniz, "+m[1]+" 👋";
    m=source.match(/^Your order number is #(.+)$/);
    if(m)return "Sipariş numaranız #"+m[1];
    m=source.match(/^([+-]?\d+) matching items?$/);
    if(m)return m[1]+" eşleşen ürün";
    return source;
  }
  function translateWithSpacing(source){
    const m=source.match(/^(\s*)([\s\S]*?)(\s*)$/);
    return m[1]+phrase(m[2])+m[3];
  }
  function excluded(node){
    const el=node.nodeType===Node.ELEMENT_NODE?node:node.parentElement;
    return !el||!!el.closest('script,style,template,[data-no-translate],.item-info,.category-title strong,.vendor-profile-info h1,.vendor-brand-row b,.menu-item-admin .row b,.vendor-menu-main > b');
  }
  function translateText(node){
    if(!node.nodeValue||!node.nodeValue.trim()||excluded(node))return;
    let state=textHistory.get(node);
    if(!state||node.nodeValue!==state.applied)state={source:node.nodeValue,applied:node.nodeValue};
    const next=language==="tr"?translateWithSpacing(state.source):state.source;
    state.applied=next;textHistory.set(node,state);
    if(node.nodeValue!==next)node.nodeValue=next;
  }
  function translateAttributes(el){
    if(excluded(el))return;
    let history=attrHistory.get(el);
    if(!history){history={};attrHistory.set(el,history);}
    for(const attr of attrs){
      if(!el.hasAttribute(attr))continue;
      const now=el.getAttribute(attr);
      let state=history[attr];
      if(!state||state.applied!==now)state={source:now,applied:now};
      const next=language==="tr"?translateWithSpacing(state.source):state.source;
      state.applied=next;history[attr]=state;
      if(now!==next)el.setAttribute(attr,next);
    }
  }
  function translateTree(root){
    if(!root||excluded(root))return;
    if(root.nodeType===Node.TEXT_NODE){translateText(root);return;}
    if(root.nodeType!==Node.ELEMENT_NODE)return;
    translateAttributes(root);
    const walk=document.createTreeWalker(root,NodeFilter.SHOW_ELEMENT|NodeFilter.SHOW_TEXT);
    while(walk.nextNode()){
      const node=walk.currentNode;
      if(node.nodeType===Node.TEXT_NODE)translateText(node);
      else translateAttributes(node);
    }
  }
  function savePreference(key,value){try{localStorage.setItem(key,value)}catch(_){}}
  function setLanguage(next){
    language=next==="tr"?"tr":"en";
    document.documentElement.lang=language;
    document.title=language==="tr"?tr["Megjet — Gazimagusa • Food Delivery"]:"Megjet — Gazimagusa • Food Delivery";
    savePreference("megjet_language",language);
    translateTree(document.body);
  }
  function setTheme(next){
    const theme=next==="dark"?"dark":"light";
    document.documentElement.dataset.theme=theme;
    const browserBar=document.querySelector('meta[name="theme-color"]');
    if(browserBar)browserBar.content=theme==="dark"?"#0b1624":"#168fd0";
    savePreference("megjet_theme",theme);
  }
  function start(){
    const lang=document.getElementById("megjetLanguage"),theme=document.getElementById("megjetTheme");
    language=document.documentElement.lang==="tr"?"tr":"en";
    document.title=language==="tr"?tr["Megjet — Gazimagusa • Food Delivery"]:"Megjet — Gazimagusa • Food Delivery";
    const browserBar=document.querySelector('meta[name="theme-color"]');
    if(browserBar)browserBar.content=document.documentElement.dataset.theme==="dark"?"#0b1624":"#168fd0";
    if(lang){lang.value=language;lang.addEventListener("change",()=>setLanguage(lang.value));}
    if(theme){theme.value=document.documentElement.dataset.theme==="dark"?"dark":"light";theme.addEventListener("change",()=>setTheme(theme.value));}
    translateTree(document.body);
    const pending=new Set();
    const observer=new MutationObserver(records=>{
      for(const record of records){
        if(record.type==="childList")record.addedNodes.forEach(node=>pending.add(node));
        else pending.add(record.target);
      }
      if(scheduled)return;
      scheduled=true;
      requestAnimationFrame(()=>{
        scheduled=false;
        for(const node of pending)translateTree(node);
        pending.clear();
      });
    });
    observer.observe(document.body,{subtree:true,childList:true,characterData:true,attributes:true,attributeFilter:attrs});
  }
  if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",start,{once:true});
  else start();
  window.MEGJET_INTERFACE={setLanguage,setTheme,translate:phrase};
})();
