(()=>{'use strict';
const $=id=>document.getElementById(id),t=(en,tr)=>document.documentElement.lang==='tr'?tr:en;
let key='',quoted=null,requestId=0,timer;
const items=()=>Array.from(new Set((window.cart||[]).map(p=>String(p.id)))).sort().map(id=>({product_id:id}));
function address(){return window.MEGJET_DELIVERY_PIN?.serialized('address')||$('address')?.value||'';}
function quoteKey(){return JSON.stringify([items(),address()]);}
function message(){const box=$('nearbyDeliveryMessage');if(!box)return;const q=quoted;if(!items().length){box.hidden=true;return;}box.hidden=false;box.textContent=q?.tier?t('Delivery fee: ','Teslimat ücreti: ')+money(q.fee)+' · '+(q.nearby?t('Nearby discount applied','Yakın teslimat indirimi uygulandı'):t('Based on the farthest pickup from your address pin','Adres konumunuza en uzak teslim alma noktasına göre')):q?.reason==='vendor_pin'?t('First-tier fee applies. A pickup location is not yet verified.','İlk kademe ücreti geçerli. Teslim alma konumu henüz doğrulanmadı.'):t('Pin your delivery address to calculate its delivery fee.','Teslimat ücretini hesaplamak için adresinizi işaretleyin.');}
function redraw(){renderCart();renderCheckoutTotals();message();}
async function refresh(force=false){const next=quoteKey();if(!force&&next===key)return quoted;key=next;const run=++requestId;quoted=null;redraw();if(!items().length||!window.MegjetDeliveryPinCore.parse(address()))return null;try{const q=await fetchJson(cfg.url.replace(/\/$/,'')+'/rest/v1/rpc/quote_nearby_delivery',{method:'POST',headers:{apikey:cfg.key,Authorization:'Bearer '+cfg.key,'Content-Type':'application/json'},body:JSON.stringify({p_items:items(),p_delivery_address:address()})});if(run!==requestId||next!==quoteKey()){if(force)return refresh(true);return null;}if(!Number.isFinite(Number(q.fee))||Number(q.fee)<0)throw Error('Invalid delivery quote');quoted=q;redraw();return q;}catch(error){if(run===requestId){quoted=null;redraw();}if(force)throw error;return null;}}
window.MEGJET_NEARBY={fee(){return key===quoteKey()&&quoted?Number(quoted.fee):Number(DELIVERY);},refresh};
const note=document.createElement('p');note.id='nearbyDeliveryMessage';note.className='service-eta';note.dataset.noTranslate='';$('serviceCheckoutFormEstimate')?.after(note);

const changed=()=>{clearTimeout(timer);timer=setTimeout(()=>void refresh(),250);};
$('address')?.addEventListener('input',changed);const cartItems=$('cartItems');if(cartItems)new MutationObserver(()=>{if(quoteKey()!==key)changed();}).observe(cartItems,{childList:true});
setInterval(()=>{if(!document.hidden&&quoteKey()!==key)changed();},700);window.addEventListener('megjet:languagechange',message);void refresh();
})();
