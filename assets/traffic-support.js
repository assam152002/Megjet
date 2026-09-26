(function(){
  'use strict';
  const $=id=>document.getElementById(id);
  const tr=()=>document.documentElement.lang==='tr';
  const phrase=(en,tk)=>tr()?tk:en;
  const escape=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const base='https://manuspenfcahagcstedd.supabase.co/rest/v1/rpc/';
  const apiKey='sb_publishable_fPcx_4VPIW7UeDRUpEm4nA_uhVHOwD1';
  let customerOpen=false, customerThread=null,selectedThread=null,adminInbox=[],customerBusy=false,adminBusy=false;

  async function rpc(method,args={},admin=false){
    const token=admin?localStorage.getItem('megjet_access_token'):null;
    if(admin&&!token)throw new Error(phrase('Admin sign-in required.','Yönetici girişi gerekli.'));
    const response=await fetch(base+method,{method:'POST',headers:{apikey:apiKey,Authorization:'Bearer '+(token||apiKey),'Content-Type':'application/json'},body:JSON.stringify(args)});
    const raw=await response.text();let data;
    try{data=raw?JSON.parse(raw):null;}catch{data=null;}
    if(!response.ok)throw new Error(data?.message||phrase('Could not connect to support.','Destek bağlantısı kurulamadı.'));
    return data;
  }

  function trackVisit(){
    if(['#admin','#vendor','#rider'].some(hash=>location.hash.startsWith(hash)))return;
    if(['megjet_access_token','megjet_vendor_access_token','megjet_rider_access_token'].some(key=>localStorage.getItem(key)))return;
    if(!window.crypto?.randomUUID)return;
    const visitor=localStorage.getItem('megjet_visitor_id')||crypto.randomUUID();
    const session=sessionStorage.getItem('megjet_visit_session')||crypto.randomUUID();
    localStorage.setItem('megjet_visitor_id',visitor);
    sessionStorage.setItem('megjet_visit_session',session);
    let referrer='';
    try{const u=new URL(document.referrer);if(u.origin!==location.origin)referrer=u.hostname;}catch{}
    const ping=()=>{if(document.visibilityState==='visible')rpc('record_app_visit',{p_visitor_id:visitor,p_session_id:session,p_referrer_host:referrer}).catch(()=>{});};
    ping();setInterval(ping,60000);
  }

  function getChatToken(){
    let token=localStorage.getItem('megjet_support_token');
    if(!/^[0-9a-f]{64}$/.test(token||'')){
      const bytes=crypto.getRandomValues(new Uint8Array(32));
      token=Array.from(bytes,b=>b.toString(16).padStart(2,'0')).join('');
      localStorage.setItem('megjet_support_token',token);
    }
    return token;
  }
  function messagesHTML(messages){
    if(!messages?.length)return `<div class="muted">${phrase('No messages yet.','Henüz mesaj yok.')}</div>`;
    return messages.map(m=>`<div class="support-bubble ${m.sender==='admin'?'admin':'customer'}"><small>${m.sender==='admin'?phrase('Megjet Support','Megjet Destek'):phrase('Customer','Müşteri')} · ${escape(new Date(m.created_at).toLocaleString())}</small><div data-no-translate>${escape(m.body)}</div></div>`).join('');
  }
  function renderCustomer(){
    $('supportStart').hidden=!!customerThread;
    $('supportConversation').hidden=!customerThread;
    $('supportCustomerMessages').innerHTML=messagesHTML(customerThread?.messages);
    $('supportCustomerStatus').textContent=customerThread?.status==='closed'
      ?phrase('Conversation closed. Sending a message will reopen it.','Görüşme kapandı. Mesaj göndererek yeniden açabilirsiniz.')
      :phrase('Messages update automatically. Admin replies when available.','Mesajlar otomatik yenilenir. Yönetici müsait olduğunda yanıtlar.');
  }
  async function loadCustomer(){
    if(!customerOpen||customerBusy)return;
    customerBusy=true;
    try{customerThread=await rpc('support_customer_state',{p_token:getChatToken()});renderCustomer();$('supportCustomerError').textContent='';}
    catch(e){$('supportCustomerError').textContent=e.message;}
    finally{customerBusy=false;}
  }
  function openChat(){
    customerOpen=true;$('supportPanel').hidden=false;
    $('supportFloatButton').hidden=true;
    loadCustomer();
    $('supportPanelClose').focus();
  }
  function closeChat(){customerOpen=false;$('supportPanel').hidden=true;$('supportFloatButton').hidden=false;}
  async function sendCustomer(e){
    e.preventDefault();if(customerBusy)return;
    const message=$('supportCustomerText').value.trim();if(!message)return;
    const button=$('supportCustomerSend');button.disabled=true;
    try{
      const token=getChatToken();
      if(customerThread)await rpc('support_customer_send',{p_token:token,p_body:message});
      else await rpc('support_customer_open',{p_token:token,p_name:$('supportCustomerName').value.trim(),p_order_reference:$('supportOrderRef').value.trim(),p_body:message});
      $('supportCustomerText').value='';await loadCustomer();
    }catch(err){$('supportCustomerError').textContent=err.message;}
    finally{button.disabled=false;}
  }

  async function loadTraffic(){
    if(!$('adminPanel')||$('adminPanel').classList.contains('hidden'))return;
    try{
      const d=await rpc('admin_traffic_summary',{},true);
      const metrics=[
        [phrase('Visits today','Bugünkü ziyaretler'),d.today_visits],
        [phrase('Unique visitors today','Bugünkü tekil ziyaretçiler'),d.today_visitors],
        [phrase('Active now (5 min)','Şu an aktif (5 dk)'),d.active_now],
        [phrase('Visits in 7 days','7 günlük ziyaretler'),d.last_7_days],
        [phrase('Visits in 30 days','30 günlük ziyaretler'),d.last_30_days]
      ];
      $('trafficSummary').innerHTML=metrics.map(([name,value])=>`<div class="support-stat"><span>${escape(name)}</span><strong>${Number(value)||0}</strong></div>`).join('');
      $('trafficDaily').innerHTML=`<div class="support-traffic-days">${(d.daily||[]).map(day=>`<div><span>${escape(String(day.day).slice(0,10))}</span><strong>${Number(day.visits)||0}</strong><small>${Number(day.visitors)||0} ${phrase('visitors','ziyaretçi')}</small></div>`).join('')}</div>`;
    }catch(e){$('trafficSummary').textContent=phrase('Traffic could not load: ','Trafik yüklenemedi: ')+e.message;}
  }

  function renderInbox(){
    const box=$('supportInbox');if(!box)return;
    if($('adminSectionSupport').classList.contains('active')){
      const html=adminInbox.length?adminInbox.map(t=>`<button type="button" class="support-thread-choice ${t.id===selectedThread?'selected':''}" data-support-thread="${escape(t.id)}"><strong data-no-translate>${escape(t.name)}</strong>${t.unread?`<b class="support-unread">${Number(t.unread)}</b>`:''}<small>${escape(t.order_reference?`#${t.order_reference} · `:'')}${escape(t.status)} · ${escape(new Date(t.last_message_at).toLocaleString())}</small></button>`).join(''):`<div class="muted">${phrase('No customer chats yet.','Henüz müşteri sohbeti yok.')}</div>`;
      if(box.innerHTML!==html)box.innerHTML=html;
    }
    const unread=adminInbox.reduce((n,t)=>n+Number(t.unread||0),0),badge=$('supportUnreadBadge');
    if(badge){if(badge.hidden===!!unread)badge.hidden=!unread;const label=unread>99?'99':String(unread);if(badge.textContent!==label)badge.textContent=label;}
  }
  async function loadInbox(){
    if(!localStorage.getItem('megjet_access_token')||!$('adminPanel')||$('adminPanel').classList.contains('hidden')||adminBusy)return;
    adminBusy=true;
    try{adminInbox=await rpc('admin_support_inbox',{},true)||[];renderInbox();
      if(selectedThread&&$('adminSectionSupport').classList.contains('active'))await loadAdminThread(selectedThread);
      $('supportAdminError').textContent='';}
    catch(e){$('supportAdminError').textContent=e.message;}
    finally{adminBusy=false;}
  }
  async function loadAdminThread(id){
    const t=await rpc('admin_support_thread',{p_thread_id:id},true);if(!t)return;
    selectedThread=t.id;
    $('supportAdminHeader').textContent=`${t.name}${t.order_reference?' · #'+t.order_reference:''} · ${t.status}`;
    const html=messagesHTML(t.messages);
    if($('supportAdminMessages').innerHTML!==html)$('supportAdminMessages').innerHTML=html;
    $('supportAdminForm').hidden=false;$('supportCloseThread').hidden=t.status==='closed';
    $('supportAdminMessages').scrollTop=$('supportAdminMessages').scrollHeight;
    renderInbox();
  }
  async function sendAdmin(e){
    e.preventDefault();if(!selectedThread)return;
    const text=$('supportAdminText').value.trim();if(!text)return;
    const btn=$('supportAdminForm').querySelector('button');btn.disabled=true;
    try{await rpc('admin_support_reply',{p_thread_id:selectedThread,p_body:text},true);$('supportAdminText').value='';await loadAdminThread(selectedThread);await loadInbox();}
    catch(err){$('supportAdminError').textContent=err.message;}
    finally{btn.disabled=false;}
  }

  function updateLanguage(){
    $('supportFloatButton').textContent='💬 '+phrase('Help','Yardım');
    $('supportPanel').querySelector('header strong').textContent='💬 '+phrase('Megjet Support','Megjet Destek');
    $('supportCustomerName').placeholder=phrase('Your name (optional)','Adınız (isteğe bağlı)');
    $('supportOrderRef').placeholder=phrase('Order number (optional)','Sipariş numarası (isteğe bağlı)');
    $('supportCustomerText').placeholder=phrase('How can we help?','Size nasıl yardımcı olabiliriz?');
    $('supportCustomerSend').textContent=phrase('Send','Gönder');
    renderCustomer();
    if(adminInbox.length)renderInbox();
  }

  function init(){
    const host=document.createElement('div');host.innerHTML=`
      <button id="supportFloatButton" type="button" aria-label="Chat with Megjet">💬 ${phrase('Help','Yardım')}</button>
      <section id="supportPanel" class="support-panel" aria-label="Megjet customer support" hidden>
        <header><strong>💬 ${phrase('Megjet Support','Megjet Destek')}</strong><button id="supportPanelClose" type="button" aria-label="Close">×</button></header>
        <div class="support-panel-body">
          <p id="supportCustomerStatus" class="muted">${phrase('Messages update automatically. Admin replies when available.','Mesajlar otomatik yenilenir. Yönetici müsait olduğunda yanıtlar.')}</p>
          <div id="supportStart"><input id="supportCustomerName" maxlength="80" placeholder="${phrase('Your name (optional)','Adınız (isteğe bağlı)')}"><input id="supportOrderRef" maxlength="40" placeholder="${phrase('Order number (optional)','Sipariş numarası (isteğe bağlı)')}"></div>
          <div id="supportConversation" hidden><div id="supportCustomerMessages" class="support-messages" role="log" aria-live="polite"></div></div>
          <form id="supportCustomerForm" class="support-compose"><textarea id="supportCustomerText" maxlength="1000" rows="2" placeholder="${phrase('How can we help?','Size nasıl yardımcı olabiliriz?')}" required></textarea><button id="supportCustomerSend" type="submit">${phrase('Send','Gönder')}</button></form>
          <div id="supportCustomerError" class="small" role="status"></div>
        </div>
      </section>`;
    document.body.append(...host.children);
    document.addEventListener('click',e=>{
      if(e.target.closest('#megjetChatOpen,#supportFloatButton'))openChat();
      const choice=e.target.closest('[data-support-thread]');if(choice)loadAdminThread(choice.dataset.supportThread).catch(err=>$('supportAdminError').textContent=err.message);
    });
    $('supportPanelClose').addEventListener('click',closeChat);
    $('supportCustomerForm').addEventListener('submit',sendCustomer);
    $('supportAdminForm').addEventListener('submit',sendAdmin);
    $('supportCloseThread').addEventListener('click',async()=>{if(!selectedThread)return;try{await rpc('admin_support_close',{p_thread_id:selectedThread},true);await loadAdminThread(selectedThread);await loadInbox();}catch(e){$('supportAdminError').textContent=e.message;}});
    $('supportAdminRefresh').addEventListener('click',loadInbox);
    $('trafficRefresh').addEventListener('click',loadTraffic);
    document.querySelector('[data-admin-tab="traffic"]')?.addEventListener('click',loadTraffic);
    document.querySelector('[data-admin-tab="support"]')?.addEventListener('click',loadInbox);
    document.addEventListener('keydown',e=>{if(e.key==='Escape'&&customerOpen)closeChat();});
    window.addEventListener('megjet:languagechange',updateLanguage);
    trackVisit();
    setInterval(()=>{if(customerOpen&&document.visibilityState==='visible')loadCustomer();},6000);
    setInterval(()=>{if(document.visibilityState==='visible')loadInbox();},12000);
    setInterval(()=>{if(document.visibilityState==='visible'&&$('adminSectionTraffic')?.classList.contains('active'))loadTraffic();},30000);
  }
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init,{once:true});else init();
})();
