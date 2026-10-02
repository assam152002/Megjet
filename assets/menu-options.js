/* Database-backed choices for every restaurant. Price validation stays on the server. */
(()=>{
 'use strict';
 const originalAdd=window.add;
 const dialog=document.createElement('dialog');dialog.className='megjet-photo-preview';dialog.id='megjetMenuOptions';dialog.setAttribute('aria-labelledby','megjetOptionsTitle');dialog.setAttribute('data-no-translate','');
 document.body.append(dialog);
 let current=null,busy=false;
 const isTr=()=>document.documentElement.lang==='tr';
 const label=x=>x[isTr()?'label_tr':'label_en']||x.label_en||x.label_tr||'';
 const esc=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
 function selected(){const result={};for(const g of current.groups)result[g.id]=Array.from(dialog.querySelectorAll('input:checked')).filter(x=>x.dataset.group===g.id).map(x=>x.value);return result;}
 function total(selection){let price=Number(current.product.price);for(const g of current.groups)for(const id of selection[g.id])price+=Number(g.choices.find(c=>c.id===id)?.extra||0);return price;}
 function renderChoiceSummary(){document.querySelectorAll('#cartItems .row').forEach((row,i)=>{const item=(window.cart||[])[i];if(!item?.customizations)return;let summary=row.querySelector('.megjet-choice-summary');if(!summary){summary=document.createElement('div');summary.className='muted megjet-choice-summary';row.querySelector('span')?.append(summary);}summary.textContent=item.choice_summary||'';});}
 const renderOriginal=window.renderCart;
 window.renderCart=function(){renderOriginal();renderChoiceSummary();};
 function open(product,groups){
  current={product,groups};
  const name=window.MEGJET_MENU_LOCALE?.name(product)||product.name;
  dialog.innerHTML='<form><div class="megjet-photo-heading"><h2 id="megjetOptionsTitle">'+esc(name)+'</h2><button type="button" data-close aria-label="'+(isTr()?'Kapat':'Close')+'">✕</button></div>'+groups.map(g=>'<fieldset style="margin:12px 0;border:1px solid #9bb6c8;border-radius:12px;padding:12px"><legend>'+esc(label(g))+'</legend>'+g.choices.map(c=>'<label style="display:flex;gap:10px;align-items:center;padding:9px 0"><input style="width:auto" type="'+(g.max===1?'radio':'checkbox')+'" name="group-'+esc(g.id)+'" data-group="'+esc(g.id)+'" value="'+esc(c.id)+'" '+((g.defaults||[]).includes(c.id)?'checked':'')+'><span>'+esc(label(c))+(Number(c.extra)?' (+'+money(c.extra)+')':'')+'</span></label>').join('')+'</fieldset>').join('')+'<p role="alert" id="megjetOptionsError"></p><button type="submit" style="width:100%;min-height:48px" id="megjetOptionsSubmit"></button></form>';
  const update=()=>{dialog.querySelector('#megjetOptionsSubmit').textContent=(isTr()?'Sepete ekle — ':'Add to cart — ')+money(total(selected()));};
  dialog.querySelector('[data-close]').onclick=()=>dialog.close();
  dialog.querySelector('form').addEventListener('change',update);
  dialog.querySelector('form').addEventListener('submit',e=>{
   e.preventDefault();const customizations=selected();
   for(const g of groups){const n=customizations[g.id].length;if(n<g.min||n>g.max){dialog.querySelector('#megjetOptionsError').textContent=isTr()?'Lütfen seçenekleri kontrol edin: '+label(g):'Please check your choices for '+label(g);return;}}
   const choice_summary=groups.map(g=>label(g)+': '+g.choices.filter(c=>customizations[g.id].includes(c.id)).map(label).join(', ')).filter(x=>!x.endsWith(': ')).join(' · ');
   originalAdd({...product,price:total(customizations),customizations,choice_summary,quantity:1});renderChoiceSummary();dialog.close();
   setStatus(isTr()?'Sepete eklendi ✓':'Added to cart ✓','ok');
  });
  update();dialog.showModal();
 }
 async function route(product){
  if(!product||busy||dialog.open)return false;
  busy=true;setStatus(isTr()?'Seçenekler yükleniyor…':'Loading item options…');
  try{
   const rows=await fetchJson(cfg.url.replace(/\/+$/,'')+'/rest/v1/product_options?select=groups&product_id=eq.'+encodeURIComponent(product.id),{headers:{apikey:cfg.key,Authorization:'Bearer '+cfg.key}});
   const groups=rows?.[0]?.groups||[];
   if(groups.length)open(product,groups);
   else {originalAdd(product);setStatus(isTr()?'Sepete eklendi ✓':'Added to cart ✓','ok');}
  }catch(error){setStatus((isTr()?'Seçenekler yüklenemedi: ':'Could not load item options: ')+error.message,'bad');}
  finally{busy=false;}
  return false;
 }
 window.add=product=>{void route(product);return false;};
 window.megjetAddDirect=token=>{const product=window.MEGJET_CART_PRODUCTS?.[token];if(product)void route({...product,quantity:1});return false;};
 const observer=new MutationObserver(renderChoiceSummary);observer.observe(document.getElementById('cartItems'),{childList:true});renderChoiceSummary();
})();
