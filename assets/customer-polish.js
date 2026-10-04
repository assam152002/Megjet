(()=>{
'use strict';
const $=id=>document.getElementById(id);
const profile=$('vendorProfile');
function profileState(){document.body.classList.toggle('mj-browsing-menu',!profile.classList.contains('hidden'));}
new MutationObserver(profileState).observe(profile,{attributes:true,attributeFilter:['class']});profileState();
document.addEventListener('click',e=>{const b=e.target.closest('[data-jump-category]');if(!b)return;const category=profile.querySelectorAll('details.menu-category')[Number(b.dataset.jumpCategory)];if(category){category.open=true;category.scrollIntoView({behavior:'smooth',block:'start'});profile.querySelectorAll('[data-jump-category]').forEach(x=>x.setAttribute('aria-current',String(x===b)));}});
function summary(){const source=$('cartItems'),target=$('mjCheckoutItems');if(!source||!target)return;target.replaceChildren();source.querySelectorAll(':scope > .row').forEach(row=>{const copy=row.cloneNode(true);copy.querySelectorAll('button,input,select,[id]').forEach(el=>{if(el.matches('button,input,select'))el.remove();else el.removeAttribute('id');});target.append(copy);});$('mjCheckoutSubtotal').textContent=$('subtotal')?.textContent||'₺ 0';}
const summaryObserver=new MutationObserver(summary);summaryObserver.observe($('cartItems'),{childList:true,subtree:true,characterData:true});summaryObserver.observe($('subtotal'),{childList:true,subtree:true,characterData:true});summary();
const searchDialog=document.createElement('dialog');searchDialog.id='mjSearchDialog';searchDialog.setAttribute('aria-labelledby','mjSearchTitle');
searchDialog.innerHTML='<div class="mj-search-controls"><div class="mj-search-head"><h2 id="mjSearchTitle"></h2><button type="button" id="mjSearchClose" aria-label="Close search">×</button></div><div class="mj-search-input-row"><span aria-hidden="true">⌕</span><input id="mjGlobalSearch" type="search" autocomplete="off" autocapitalize="none"><button type="button" id="mjSearchClear"></button></div></div><p id="mjSearchStatus" role="status" aria-live="polite"></p><div id="mjSearchResults"></div>';
document.body.append(searchDialog);
const searchInput=$('mjGlobalSearch'),trigger=$('customerSearch');let closingSearch=false;
const tr=()=>document.documentElement.lang==='tr';
const normalize=s=>String(s||'').normalize('NFKD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/ı/g,'i');
const escape=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function searchResults(){
 $('mjSearchTitle').textContent=tr()?'Megjet’te ara':'Search Megjet';searchInput.placeholder=tr()?'Restoran, yemek veya market ürünü ara':'Search restaurants, food or groceries';$('mjSearchClear').textContent=tr()?'Temizle':'Clear';$('mjSearchClose').setAttribute('aria-label',tr()?'Aramayı kapat':'Close search');
 const data=window.MEGJET_VENDOR_DATA,terms=normalize(searchInput.value.trim()).split(/\s+/).filter(Boolean),results=$('mjSearchResults');
 if(!terms.length){$('mjSearchStatus').textContent=tr()?'Aramaya başlamak için bir isim yazın.':'Type a name to find restaurants and products.';results.replaceChildren();return;}
 if(!data){$('mjSearchStatus').textContent=tr()?'Menüler yükleniyor…':'Loading menus…';return;}
 const vendors=new Map(data.vendors.map(v=>[String(v.id),v]));const match=s=>terms.every(t=>normalize(s).includes(t));
 const shops=data.vendors.filter(v=>match(v.name));const products=data.products.filter(p=>p.available!==false&&vendors.has(String(p.vendor_id))&&match([p.name,window.MEGJET_MENU_LOCALE?.name(p),p.description,vendors.get(String(p.vendor_id)).name].join(' ')));
 $('mjSearchStatus').textContent=tr()?`${shops.length} işletme · ${products.length} ürün`:`${shops.length} places · ${products.length} products`;
 const row=(id,title,detail,photo,product)=>`<button type="button" class="mj-search-result" data-search-vendor="${escape(id)}"${product?` data-search-product="${escape(product)}"`:''}>${photo?`<img src="${escape(photo)}" alt="" loading="lazy">`:'<span class="mj-search-icon" aria-hidden="true">⌕</span>'}<span><strong>${escape(title)}</strong><small>${escape(detail)}</small></span><span aria-hidden="true">›</span></button>`;
 results.innerHTML=(shops.length?`<h3>${tr()?'Restoranlar ve mağazalar':'Restaurants & shops'}</h3>`+shops.map(v=>row(v.id,v.name,tr()?'Menüyü aç':'Open menu',v.logo_url)).join(''):'')+(products.length?`<h3>${tr()?'Ürünler':'Products'}</h3>`+products.slice(0,40).map(p=>row(p.vendor_id,window.MEGJET_MENU_LOCALE?.name(p)||p.name,`${vendors.get(String(p.vendor_id)).name} · ${Number(p.price).toLocaleString(tr()?'tr-TR':'en-US',{style:'currency',currency:'TRY'})}`,p.image_url,p.id)).join(''):'');
 if(!shops.length&&!products.length)results.innerHTML=`<div class="mj-search-empty">${tr()?'Sonuç bulunamadı. Başka bir isim deneyin.':'No matches. Try another name or product.'}</div>`;
 if(products.length>40)results.insertAdjacentHTML('beforeend',`<p>${tr()?'Daha fazla sonuç için aramanızı daraltın.':'Refine your search to see more results.'}</p>`);
}
function openSearch(){if(closingSearch||searchDialog.open)return;searchInput.value=trigger.value;searchResults();searchDialog.showModal();document.body.classList.add('mj-search-open');searchInput.focus();}
function closeSearch(){closingSearch=true;searchDialog.close();document.body.classList.remove('mj-search-open');trigger.blur();requestAnimationFrame(()=>{closingSearch=false;});}
trigger.readOnly=true;trigger.setAttribute('aria-haspopup','dialog');trigger.addEventListener('focus',openSearch);trigger.addEventListener('click',openSearch);
document.addEventListener('click',e=>{if(e.target.closest('[data-mj-nav="search"]'))openSearch();});
$('mjSearchClose').onclick=closeSearch;searchDialog.addEventListener('cancel',e=>{e.preventDefault();closeSearch();});searchDialog.addEventListener('click',e=>{if(e.target===searchDialog)closeSearch();});
searchInput.addEventListener('input',searchResults);$('mjSearchClear').onclick=()=>{searchInput.value='';searchResults();searchInput.focus();};
$('mjSearchResults').onclick=e=>{const b=e.target.closest('[data-search-vendor]');if(!b)return;const p=window.MEGJET_VENDOR_DATA?.products.find(p=>String(p.id)===b.dataset.searchProduct);closeSearch();window.openVendorProfile?.(b.dataset.searchVendor);if(p){const input=$('vendorProfileSearch');input.value=p.name;input.dispatchEvent(new Event('input',{bubbles:true}));}};
window.addEventListener('megjet:languagechange',()=>{if(searchDialog.open)searchResults();});window.addEventListener('megjet-vendors-ready',()=>{if(searchDialog.open)searchResults();});
function viewportHeight(){document.documentElement.style.setProperty('--mj-visible-height',(window.visualViewport?.height||window.innerHeight)+'px');}window.visualViewport?.addEventListener('resize',viewportHeight);viewportHeight();
})();
