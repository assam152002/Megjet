(()=>{
'use strict';
const $=id=>document.getElementById(id);
const profile=$('vendorProfile');
function profileState(){document.body.classList.toggle('mj-browsing-menu',!profile.classList.contains('hidden'));}
new MutationObserver(profileState).observe(profile,{attributes:true,attributeFilter:['class']});profileState();
document.addEventListener('click',e=>{const b=e.target.closest('[data-jump-category]');if(!b)return;const category=profile.querySelectorAll('details.menu-category')[Number(b.dataset.jumpCategory)];if(category){category.open=true;category.scrollIntoView({behavior:'smooth',block:'start'});profile.querySelectorAll('[data-jump-category]').forEach(x=>x.setAttribute('aria-current',String(x===b)));}});
function summary(){const source=$('cartItems'),target=$('mjCheckoutItems');if(!source||!target)return;target.replaceChildren();source.querySelectorAll(':scope > .row').forEach(row=>{const copy=row.cloneNode(true);copy.querySelectorAll('button,input,select,[id]').forEach(el=>{if(el.matches('button,input,select'))el.remove();else el.removeAttribute('id');});target.append(copy);});$('mjCheckoutSubtotal').textContent=$('subtotal')?.textContent||'₺ 0';}
const summaryObserver=new MutationObserver(summary);summaryObserver.observe($('cartItems'),{childList:true,subtree:true,characterData:true});summaryObserver.observe($('subtotal'),{childList:true,subtree:true,characterData:true});summary();
})();
