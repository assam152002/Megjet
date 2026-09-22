const fs = require('fs');
const path = 'index.html';
let s = fs.readFileSync(path, 'utf8');
const anchor = 'function renderVendors(vendors,products){';
if (!s.includes(anchor)) throw new Error('Vendor renderer anchor not found');

const imageSetup = `/* Generic Alcohol Market artwork — inline SVGs keep the preview fast and reliable. */
function megjetAlcoholArtwork(emoji,label,colorA,colorB){
  const svg=\`<svg xmlns="http://www.w3.org/2000/svg" width="640" height="420" viewBox="0 0 640 420"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop stop-color="\${colorA}"/><stop offset="1" stop-color="\${colorB}"/></linearGradient></defs><rect width="640" height="420" rx="34" fill="url(#g)"/><circle cx="320" cy="176" r="102" fill="rgba(255,255,255,.16)"/><text x="320" y="215" text-anchor="middle" font-size="112">\${emoji}</text><text x="320" y="340" text-anchor="middle" fill="white" font-family="Arial,sans-serif" font-size="38" font-weight="700">\${label}</text></svg>\`;
  return 'data:image/svg+xml;charset=UTF-8,'+encodeURIComponent(svg);
}
const MEGJET_ALCOHOL_IMAGES={
  beer:megjetAlcoholArtwork('🍺','Beer','#e6a51d','#7b3f00'),
  wine:megjetAlcoholArtwork('🍷','Wine','#9d174d','#3f0a2a'),
  spirits:megjetAlcoholArtwork('🥃','Whisky & Spirits','#b66a22','#2f1a10'),
  extras:megjetAlcoholArtwork('🥤','Drinks & Snacks','#1686a7','#123b65'),
  market:megjetAlcoholArtwork('🍾','Alcohol Market','#18243f','#7d2748')
};
Object.assign(MEGJET_CATEGORY_IMAGES,{'Beer':MEGJET_ALCOHOL_IMAGES.beer,'Wine':MEGJET_ALCOHOL_IMAGES.wine,'Whisky & Spirits':MEGJET_ALCOHOL_IMAGES.spirits,'Soft Drinks & Snacks':MEGJET_ALCOHOL_IMAGES.extras});
Object.assign(window.MEGJET_PRODUCT_PHOTOS=window.MEGJET_PRODUCT_PHOTOS||{}, {'Beer':MEGJET_ALCOHOL_IMAGES.beer,'Red Wine':MEGJET_ALCOHOL_IMAGES.wine,'White Wine':MEGJET_ALCOHOL_IMAGES.wine,'Whisky':MEGJET_ALCOHOL_IMAGES.spirits,'Vodka, Gin & Spirits':MEGJET_ALCOHOL_IMAGES.spirits,'Soft Drinks':MEGJET_ALCOHOL_IMAGES.extras,'Snacks':MEGJET_ALCOHOL_IMAGES.extras});
(window.MEGJET_VENDOR_LOGOS=window.MEGJET_VENDOR_LOGOS||{})['Alcohol Market']=MEGJET_ALCOHOL_IMAGES.market;
(window.MEGJET_VENDOR_HEROES=window.MEGJET_VENDOR_HEROES||{})['Alcohol Market']=MEGJET_ALCOHOL_IMAGES.market;

`;
s = s.replace(anchor, imageSetup + anchor);
fs.writeFileSync(path, s);
console.log('Generic Alcohol Market images applied');
