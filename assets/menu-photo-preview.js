/* Customer menu photo preview. Native dialog keeps focus inside the preview. */
(()=>{
 'use strict';
 const photoSelector='#vendorProfile .item img.product-image-admin, #vendors .item img.product-image-admin';
 const dialog=document.createElement('dialog');
 dialog.id='megjetMenuPhotoPreview';dialog.className='megjet-photo-preview';dialog.setAttribute('data-no-translate','');dialog.setAttribute('aria-labelledby','megjetPhotoName');
 dialog.innerHTML='<div class="megjet-photo-heading"><h2 id="megjetPhotoName"></h2><button type="button" id="megjetPhotoClose" aria-label="Close photo">✕</button></div><img id="megjetPhotoLarge" alt=""><p id="megjetPhotoError" role="status" hidden></p><p id="megjetPhotoPrice" class="price"></p><p id="megjetPhotoDescription"></p>';
 document.body.append(dialog);
 const large=dialog.querySelector('#megjetPhotoLarge'),name=dialog.querySelector('h2'),close=dialog.querySelector('button'),error=dialog.querySelector('#megjetPhotoError');
 let trigger=null;
 function dismiss(){if(dialog.open)dialog.close();}
 function open(photo){
  if(dialog.open)return;
  trigger=photo;const info=photo.closest('.item-info')||photo.parentElement;
  const title=info.querySelector('b')?.textContent?.trim()||photo.alt||'Menu photo';
  name.textContent=title;large.alt=title;large.hidden=false;error.hidden=true;
  dialog.querySelector('#megjetPhotoPrice').textContent=info.querySelector('.price')?.textContent||'';
  dialog.querySelector('#megjetPhotoDescription').textContent=info.querySelector('.muted')?.textContent||'';
  close.setAttribute('aria-label',document.documentElement.lang==='tr'?'Fotoğrafı kapat':'Close photo');
  large.src=photo.currentSrc||photo.src;
  dialog.showModal();document.documentElement.classList.add('megjet-photo-open');close.focus();
 }
 close.addEventListener('click',dismiss);
 dialog.addEventListener('click',event=>{if(event.target===dialog){const r=dialog.getBoundingClientRect();if(event.clientX<r.left||event.clientX>r.right||event.clientY<r.top||event.clientY>r.bottom)dismiss();}});
 dialog.addEventListener('close',()=>{document.documentElement.classList.remove('megjet-photo-open');large.removeAttribute('src');if(trigger?.isConnected)trigger.focus({preventScroll:true});trigger=null;});
 large.addEventListener('error',()=>{if(!dialog.open)return;large.hidden=true;error.textContent=document.documentElement.lang==='tr'?'Fotoğraf yüklenemedi. Lütfen tekrar deneyin.':'Photo could not load. Please try again.';error.hidden=false;});
 document.addEventListener('click',event=>{const photo=event.target.closest(photoSelector);if(photo){event.preventDefault();event.stopPropagation();open(photo);}},true);
 document.addEventListener('keydown',event=>{if((event.key==='Enter'||event.key===' ')&&event.target.matches(photoSelector)){event.preventDefault();open(event.target);}});
 function preparePhotos(){document.querySelectorAll(photoSelector).forEach(photo=>{if(photo.getAttribute('role')==='button')return;photo.setAttribute('role','button');photo.tabIndex=0;photo.setAttribute('aria-haspopup','dialog');});}
 let pending=false;
 const observer=new MutationObserver(()=>{if(pending)return;pending=true;requestAnimationFrame(()=>{pending=false;preparePhotos();});});
 observer.observe(document.getElementById('vendorProfile'),{childList:true,subtree:true});
 observer.observe(document.getElementById('vendors'),{childList:true,subtree:true});
 preparePhotos();
})();
