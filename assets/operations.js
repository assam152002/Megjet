/* Shared availability, private staff push, compact navigation, and bio locales. */
(()=>{
 'use strict';
 const $=id=>document.getElementById(id);
 window.MEGJET_BIO_LOCALE=(vendor,original)=>vendor.bio_translation_source===vendor.bio?(vendor['bio_'+(document.documentElement.lang==='tr'?'tr':'en')]||original):original;
 function updateBios(){document.querySelectorAll('[data-original-bio]').forEach(el=>{el.textContent=el.dataset[document.documentElement.lang==='tr'?'bioTr':'bioEn']||el.dataset.originalBio||'';});}
 window.addEventListener('megjet:languagechange',updateBios);
 const header=document.querySelector('body>header');
 if(header){
  const brand=header.querySelector('.brand'),account=$('customerAccountOpen'),bar=document.createElement('div'),details=document.createElement('div'),toggle=document.createElement('button');
  bar.className='megjet-header-bar';details.id='megjetHeaderDetails';details.hidden=true;
  toggle.id='megjetHeaderToggle';toggle.type='button';toggle.textContent='Menu';toggle.setAttribute('aria-controls',details.id);toggle.setAttribute('aria-expanded','false');
  if(brand)bar.append(brand);if(account)bar.append(account);bar.append(toggle);
  for(const child of [...header.children])details.append(child);
  header.append(bar,details);
  toggle.addEventListener('click',()=>{details.hidden=!details.hidden;toggle.setAttribute('aria-expanded',String(!details.hidden));});
  details.addEventListener('click',event=>{if(event.target.closest('a[href^="#"]')){details.hidden=true;toggle.setAttribute('aria-expanded','false');}});
 }
 const roleKeys={admin:'megjet_access_token',vendor:'megjet_vendor_access_token',rider:'megjet_rider_access_token'};
 async function rpc(name,body,token){
  if(typeof cfg==='undefined'||!cfg?.url||!cfg?.key)throw new Error('App connection unavailable.');
  const response=await fetch(cfg.url.replace(/\/+$/,'')+'/rest/v1/rpc/'+name,{method:'POST',headers:{apikey:cfg.key,Authorization:'Bearer '+(token||cfg.key),'Content-Type':'application/json'},body:JSON.stringify(body)});
  const result=await response.json();if(!response.ok)throw new Error(result.message||'Could not save notification settings.');return result;
 }
 const statusIds={admin:'notificationStatus',vendor:'vendorPhase1Message',rider:'riderPushMessage'};
 const buttonIds={admin:'enableNotifications',vendor:'vendorNotifyBtn',rider:'riderNotifyBtn'};
 const riderRefresh=$('riderRefresh');
 if(riderRefresh){
  const btn=document.createElement('button');btn.id='riderNotifyBtn';btn.type='button';btn.className='secondary';btn.textContent='🔔 Enable Notifications';btn.addEventListener('click',()=>window.MEGJET_ENABLE_PUSH('rider'));riderRefresh.parentElement.append(btn);
  const msg=document.createElement('div');msg.id='riderPushMessage';msg.className='megjet-push-message';msg.setAttribute('role','status');riderRefresh.parentElement.after(msg);
 }
 window.MEGJET_ENABLE_PUSH=async(role)=>{
  const message=$(statusIds[role]),button=$(buttonIds[role]);
  const show=text=>{if(message)message.textContent=text;};
  const token=localStorage.getItem(roleKeys[role]);
  if(!token){show('Sign in before enabling notifications.');return;}
  if(!('serviceWorker' in navigator)||!('PushManager' in window)||!('Notification' in window)){show('Install Megjet on your home screen, then enable notifications on a supported device.');return;}
  try{
   if(button)button.disabled=true;
   const permission=await Notification.requestPermission();
   if(permission!=='granted'){show('Allow notifications in your device settings. In-app alerts still work.');return;}
   const key=await rpc('megjet_push_public_key',{});
   if(!key)throw new Error('Background notifications are not configured.');
   const bytes=Uint8Array.from(atob(key.replace(/-/g,'+').replace(/_/g,'/')+'='.repeat((4-key.length%4)%4)),c=>c.charCodeAt(0));
   const registration=await navigator.serviceWorker.ready;
   let subscription=await registration.pushManager.getSubscription();
   if(subscription){const existing=subscription.options.applicationServerKey;if(existing&&Array.from(new Uint8Array(existing)).join(',')!==Array.from(bytes).join(',')){await subscription.unsubscribe();subscription=null;}}
   subscription ||= await registration.pushManager.subscribe({userVisibleOnly:true,applicationServerKey:bytes});
   await rpc('megjet_register_push',{p_subscription:subscription.toJSON(),p_locale:document.documentElement.lang==='tr'?'tr':'en'},token);
   localStorage.setItem('megjet_push_role',role);
   if(button)button.textContent='🔔 Notifications Enabled';
   show('Background notifications enabled on this device. Open Megjet to view order details.');
  }catch(error){show('Could not enable notifications: '+error.message);}finally{if(button)button.disabled=false;}
 };
 // Stop device delivery on sign-out even if the network is unavailable.
 document.addEventListener('click',event=>{
  const id=event.target.closest('button')?.id,role={adminLogout:'admin',vendorLogout:'vendor',riderLogout:'rider'}[id];
  if(!role||localStorage.getItem('megjet_push_role')!==role)return;
  const token=localStorage.getItem(roleKeys[role]);localStorage.removeItem('megjet_push_role');
  navigator.serviceWorker?.ready.then(async registration=>{const sub=await registration.pushManager.getSubscription();if(sub){await sub.unsubscribe();await rpc('megjet_remove_push',{p_endpoint:sub.endpoint},token);}}).catch(()=>{});
 },true);
 window.MEGJET_ADMIN_AVAILABILITY=async(id,accepting)=>{
  if(!confirm(accepting?'Open this restaurant for new orders?':'Pause new orders for this restaurant on all devices?'))return;
  try{await rpc('vendor_set_order_availability',{p_vendor_id:id,p_accepting:accepting},localStorage.getItem(roleKeys.admin));await loadAdminMenu();}catch(error){alert('Could not change restaurant availability: '+error.message);}
 };
 async function refreshAvailability(){
  const data=window.MEGJET_VENDOR_DATA;if(!data||document.hidden||typeof cfg==='undefined')return;
  try{
   const response=await fetch(cfg.url.replace(/\/+$/,'')+'/rest/v1/vendors?select=id,accepting_orders,active',{headers:{apikey:cfg.key,Authorization:'Bearer '+cfg.key}});
   if(!response.ok)return;const states=new Map((await response.json()).map(v=>[String(v.id),v]));
   data.vendors.forEach(v=>{const fresh=states.get(String(v.id));if(fresh)v.accepting_orders=fresh.active&&fresh.accepting_orders;});
   document.querySelectorAll('#vendors [data-vendor-id]').forEach(card=>{const v=data.vendors.find(v=>String(v.id)===card.dataset.vendorId);let badge=card.querySelector('.phase1-badge.closed');if(v?.accepting_orders===false&&!badge){badge=document.createElement('span');badge.className='phase1-badge closed';badge.textContent='Temporarily closed';card.querySelector('.vendor-card-body')?.append(badge);}else if(v?.accepting_orders!==false)badge?.remove();});
   const profile=$('vendorProfile'),current=data.vendors.find(v=>String(v.id)===profile?.dataset.vendorId);
   if(current?.accepting_orders===false&&!$('megjetClosedNotice')){const notice=document.createElement('div');notice.id='megjetClosedNotice';notice.className='coming-soon-notice';notice.textContent='Temporarily closed. You can browse the menu; new orders are paused.';profile?.querySelector('.vendor-profile-body')?.prepend(notice);}else if(current?.accepting_orders!==false)$('megjetClosedNotice')?.remove();
   const products=new Map(data.products.map(p=>[String(p.id),p]));
   document.querySelectorAll('#vendorProfile .megjet-add-button').forEach(button=>{const id=button.closest('.item')?.querySelector('[data-menu-product-id]')?.dataset.menuProductId;const p=products.get(id);const v=data.vendors.find(v=>String(v.id)===String(p?.vendor_id));if(v){button.disabled=v.accepting_orders===false;button.textContent=button.disabled?'Temporarily closed':'Add';}});
  }catch{}
 }
 setInterval(refreshAvailability,60000);
 document.addEventListener('visibilitychange',()=>{if(!document.hidden)refreshAvailability();});
})();
