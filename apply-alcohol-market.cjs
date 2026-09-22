const fs = require('fs');
const path = 'index.html';
let s = fs.readFileSync(path, 'utf8');

function replaceOnce(oldText, newText, label) {
  if (!s.includes(oldText)) throw new Error('Missing anchor: ' + label);
  s = s.replace(oldText, newText);
}

replaceOnce('</head>', `<style id="megjet-coming-soon-store-css">
.coming-soon-badge{display:inline-flex;align-items:center;gap:5px;margin-top:7px;padding:5px 9px;border-radius:999px;background:#fff3cd;color:#7a5200;border:1px solid #f3d98a;font-size:11px;font-weight:900}
.coming-soon-notice{margin-bottom:12px;padding:13px 14px;border-radius:15px;background:#fff8e7;border:1px solid #f3d98a;color:#694900;font-size:13px;line-height:1.45}
.coming-soon-button{background:#dfe8ed!important;color:#607480!important;box-shadow:none!important;cursor:not-allowed!important}
.coming-soon-price{color:#7a5200;font-size:12px;font-weight:800}
</style>
</head>`, 'head');

replaceOnce('  <div class="quick-chip">🍟 Snacks</div>', '  <div class="quick-chip">🍟 Snacks</div>\n  <div class="quick-chip">🍺 Alcohol Market</div>', 'category chip');

replaceOnce(
  'renderVendors([...vendors, MEGJET_LOCAL_DOLCE_VENDOR, MEGJET_LOCAL_HELVACI_VENDOR, MEGJET_LOCAL_NO33_VENDOR],[...products, ...MEGJET_LOCAL_DOLCE_PRODUCTS, ...MEGJET_LOCAL_HELVACI_PRODUCTS, ...MEGJET_LOCAL_NO33_PRODUCTS]);',
  'renderVendors([...vendors, MEGJET_COMING_SOON_ALCOHOL_VENDOR, MEGJET_LOCAL_DOLCE_VENDOR, MEGJET_LOCAL_HELVACI_VENDOR, MEGJET_LOCAL_NO33_VENDOR],[...products, ...MEGJET_COMING_SOON_ALCOHOL_PRODUCTS, ...MEGJET_LOCAL_DOLCE_PRODUCTS, ...MEGJET_LOCAL_HELVACI_PRODUCTS, ...MEGJET_LOCAL_NO33_PRODUCTS]);',
  'live vendors'
);

const alcoholData = `/* Alcohol Market — visible preview only. Ordering stays disabled until a licensed partner is connected. */
const MEGJET_COMING_SOON_ALCOHOL_VENDOR={id:"megjet-alcohol-coming-soon",name:"Alcohol Market",area:"Gazimagusa",rating:"Coming Soon",coming_soon:true};
const MEGJET_COMING_SOON_ALCOHOL_PRODUCTS=[
  {id:"alcohol-preview-beer",vendor_id:"megjet-alcohol-coming-soon",name:"Beer",description:"[Beer] Local and international beer selection coming soon",price:0},
  {id:"alcohol-preview-red-wine",vendor_id:"megjet-alcohol-coming-soon",name:"Red Wine",description:"[Wine] Red wine selection coming soon",price:0},
  {id:"alcohol-preview-white-wine",vendor_id:"megjet-alcohol-coming-soon",name:"White Wine",description:"[Wine] White wine selection coming soon",price:0},
  {id:"alcohol-preview-whisky",vendor_id:"megjet-alcohol-coming-soon",name:"Whisky",description:"[Whisky & Spirits] Whisky selection coming soon",price:0},
  {id:"alcohol-preview-spirits",vendor_id:"megjet-alcohol-coming-soon",name:"Vodka, Gin & Spirits",description:"[Whisky & Spirits] Spirits selection coming soon",price:0},
  {id:"alcohol-preview-soft-drinks",vendor_id:"megjet-alcohol-coming-soon",name:"Soft Drinks",description:"[Soft Drinks & Snacks] Mixers and soft drinks coming soon",price:0},
  {id:"alcohol-preview-snacks",vendor_id:"megjet-alcohol-coming-soon",name:"Snacks",description:"[Soft Drinks & Snacks] Crisps, nuts and snacks coming soon",price:0}
];
(window.MEGJET_VENDOR_DESCRIPTIONS=window.MEGJET_VENDOR_DESCRIPTIONS||{})[MEGJET_COMING_SOON_ALCOHOL_VENDOR.name]="Beer, wine, whisky, spirits, soft drinks and snacks. Browsing preview only — ordering is not available yet.";

`;
replaceOnce('function renderDemoMenu(){', alcoholData + 'function renderDemoMenu(){', 'alcohol data');

replaceOnce(
  'renderVendors([...demoVendors,MEGJET_LOCAL_DOLCE_VENDOR,MEGJET_LOCAL_HELVACI_VENDOR,MEGJET_LOCAL_NO33_VENDOR],[...demoProducts,...MEGJET_LOCAL_DOLCE_PRODUCTS,...MEGJET_LOCAL_HELVACI_PRODUCTS,...MEGJET_LOCAL_NO33_PRODUCTS]);',
  'renderVendors([...demoVendors,MEGJET_COMING_SOON_ALCOHOL_VENDOR,MEGJET_LOCAL_DOLCE_VENDOR,MEGJET_LOCAL_HELVACI_VENDOR,MEGJET_LOCAL_NO33_VENDOR],[...demoProducts,...MEGJET_COMING_SOON_ALCOHOL_PRODUCTS,...MEGJET_LOCAL_DOLCE_PRODUCTS,...MEGJET_LOCAL_HELVACI_PRODUCTS,...MEGJET_LOCAL_NO33_PRODUCTS]);',
  'demo vendors'
);

replaceOnce(
  "    const infoClass=isSweetHoles?'item-info sweetholes-product-info':'item-info';\n    return `<div class=\"item\">",
  "    const infoClass=isSweetHoles?'item-info sweetholes-product-info':'item-info';\n    if(v.coming_soon)return `<div class=\"item\"><div class=\"${infoClass}\" style=\"display:flex;gap:10px;align-items:center;min-width:0\"><img class=\"${photoClass}\" src=\"${escapeHtml(productImage)}\" alt=\"${escapeHtml(p.name||'Product')}\"><div><b>${escapeHtml(p.name)}</b><div class=\"muted\">${escapeHtml(cleanDesc(p))}</div><div class=\"coming-soon-price\">Products and prices coming soon</div></div></div><button type=\"button\" class=\"coming-soon-button\" disabled>Coming Soon</button></div>`;\n    return `<div class=\"item\">",
  'disabled products'
);

const cardLine = /    return `<div class="card vendor vendor-profile-list-card" onclick="openVendorProfile[^\n]+\n/;
if (!cardLine.test(s)) throw new Error('Missing anchor: vendor card');
s = s.replace(cardLine, `    return \`<div class="card vendor vendor-profile-list-card" onclick="openVendorProfile('\${escapeHtml(v.id)}')"><div class="vendor-head"><div class="vendor-logo-wrap">\${logo?\`<img class="vendor-logo" src="\${logo}" alt="\${escapeHtml(v.name)} logo">\`:\`<div class="vendor-logo" style="display:flex;align-items:center;justify-content:center;font-size:34px;font-weight:900;color:#0878bd">\${v.coming_soon?'🍺':escapeHtml(String(v.name||'M').slice(0,1))}</div>\`}</div><div class="vendor-card-body"><div class="vendor-card-title">\${escapeHtml(v.name)}</div><div class="vendor-card-meta"><span class="vendor-rating"><span class="star">★</span> \${escapeHtml(rating)}</span> • \${escapeHtml(area)}<br>\${v.coming_soon?'🔒 Browsing preview only':\`🕐 \${prep?escapeHtml(prep)+' min preparation':'Prep time not provided'}\`}</div>\${v.coming_soon?'<span class="coming-soon-badge">● COMING SOON</span>':''}<button class="vendor-view" type="button" onclick="event.stopPropagation();openVendorProfile('\${escapeHtml(v.id)}')">\${v.coming_soon?'Browse Preview':'View Menu'}&nbsp; →</button></div></div></div>\`;\n`);

replaceOnce(
  "    list.classList.add('hidden'); profile.classList.remove('hidden'); profile.scrollIntoView({behavior:'smooth',block:'start'});",
  "    if(v.coming_soon){const body=profile.querySelector('.vendor-profile-body');if(body)body.insertAdjacentHTML('afterbegin','<div class=\"coming-soon-notice\"><b>🍺 Alcohol Market is coming soon</b><br>You can browse the planned categories, but ordering and checkout are disabled until Megjet connects a licensed Gazimagusa market. Age and ID verification will be required when ordering is activated.</div>');}\n    list.classList.add('hidden'); profile.classList.remove('hidden'); profile.scrollIntoView({behavior:'smooth',block:'start'});",
  'profile notice'
);

fs.writeFileSync(path, s);
console.log('Alcohol Market update applied');
