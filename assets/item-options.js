(function(){
  'use strict';
  const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const tr=()=>document.documentElement.lang==='tr';
  const text=(en,turkish)=>tr()?turkish:en;
  const label=o=>tr()?(o.label_tr||o.label_en):o.label_en;
  let configs,loading,current,dialog,previousFocus;
  async function load(){
    if(configs)return configs;
    if(!loading)loading=fetchJson(cfg.url.replace(/\/+$/,'')+'/rest/v1/product_options?select=product_id,groups,products(price,available)',{headers:{apikey:cfg.key,Authorization:'Bearer '+cfg.key}}).then(rows=>configs=new Map(rows.map(row=>[String(row.product_id),row]))).catch(e=>{loading=null;throw e;});
    return loading;
  }
  function summary(item){
    return (item.customization_labels||[]).map(group=>label(group)+': '+(group.choices.length?group.choices.map(label).join(', '):text('None','Yok'))).join(' · ');
  }
  window.megjetCartOptionsHtml=item=>item.customizations?'<div class="cart-options" data-no-translate>'+esc(summary(item))+'</div>':'';
  function mount(){
    if(dialog)return;
    dialog=document.createElement('dialog');dialog.id='megjetItemOptions';dialog.setAttribute('aria-labelledby','megjetOptionsTitle');dialog.setAttribute('data-no-translate','');
    dialog.innerHTML='<form id="megjetOptionsForm"><header><h2 id="megjetOptionsTitle"></h2><button id="megjetOptionsClose" type="button" aria-label="Close">×</button></header><div id="megjetOptionsGroups"></div><div id="megjetOptionsError" role="alert"></div><footer><strong id="megjetOptionsTotal"></strong><button id="megjetOptionsAdd" type="submit"></button></footer></form>';
    document.body.appendChild(dialog);
    dialog.querySelector('#megjetOptionsClose').onclick=()=>dialog.close();
    dialog.addEventListener('close',()=>previousFocus?.focus());
    dialog.addEventListener('click',e=>{if(e.target===dialog){const r=dialog.getBoundingClientRect();if(e.clientX<r.left||e.clientX>r.right||e.clientY<r.top||e.clientY>r.bottom)dialog.close();}});
    dialog.addEventListener('change',updateTotal);
    dialog.querySelector('form').addEventListener('submit',e=>{
      e.preventDefault();const {product,config}=current;const selections={},labels=[];let extra=0;
      for(const group of config.groups){
        const selected=[...dialog.querySelectorAll('input[data-group="'+group.id+'"]:checked')].map(input=>input.value);
        if(selected.length<group.min||selected.length>group.max){dialog.querySelector('#megjetOptionsError').textContent=text('Please choose the required options for ','Lütfen gerekli seçenekleri seçin: ')+label(group);return;}
        selections[group.id]=selected.sort();
        const choices=group.choices.filter(choice=>selected.includes(choice.id));extra+=choices.reduce((a,c)=>a+Number(c.extra||0),0);
        labels.push({...group,choices});
      }
      const base=Number(config.products?.price??product.price);
      const item={...product,price:base+extra,base_price:base,customizations:selections,customization_labels:labels};
      const token=registerMegjetCartProduct(item);current.add(token);window.dispatchEvent(new Event('megjet:itemadded'));dialog.close();
    });
  }
  function updateTotal(){
    let extra=0;for(const group of current.config.groups)for(const choice of group.choices){const input=dialog.querySelector('input[data-group="'+group.id+'"][value="'+choice.id+'"]');if(input?.checked)extra+=Number(choice.extra||0);}
    dialog.querySelector('#megjetOptionsTotal').textContent=money(Number(current.config.products?.price??current.product.price)+extra);
    dialog.querySelector('#megjetOptionsError').textContent='';
  }
  function open(product,config,add){
    mount();current={product,config,add};previousFocus=document.activeElement;
    dialog.querySelector('#megjetOptionsTitle').textContent=window.MEGJET_MENU_LOCALE?.name(product)||product.name;
    dialog.querySelector('#megjetOptionsAdd').textContent=text('Add to cart','Sepete ekle');
    dialog.querySelector('#megjetOptionsClose').setAttribute('aria-label',text('Close','Kapat'));
    dialog.querySelector('#megjetOptionsGroups').innerHTML=config.groups.map(group=>'<fieldset><legend>'+esc(label(group))+(group.min?' <span>'+text('Required','Zorunlu')+'</span>':'')+'</legend>'+(group.id==='ingredients'?'<p>'+text("Uncheck anything you do not want.","İstemediğiniz malzemelerin işaretini kaldırın.")+'</p>':'')+group.choices.map(choice=>'<label class="megjet-option-choice"><input data-group="'+esc(group.id)+'" name="'+esc(group.id)+'" value="'+esc(choice.id)+'" type="'+(group.max===1?'radio':'checkbox')+'" '+(group.defaults?.includes(choice.id)?'checked':'')+'><span>'+esc(label(choice))+'</span><small>'+(Number(choice.extra)?'+'+money(choice.extra):'')+'</small></label>').join('')+'</fieldset>').join('');
    updateTotal();dialog.showModal();
  }
  const originalAdd=window.megjetAddDirect;
  window.megjetAddDirect=async function(token){
    const product=window.MEGJET_CART_PRODUCTS?.[token];if(!product)return false;
    try{
      const config=(await load()).get(String(product.id));
      if(!config){const result=originalAdd(token);window.dispatchEvent(new Event('megjet:itemadded'));return result;}
      if(dialog?.open)return false;
      if(config.products?.available===false)throw new Error(text('This item is unavailable.','Bu ürün mevcut değil.'));
      open(product,config,originalAdd);
    }catch(e){alert(text('Could not load item choices: ','Ürün seçenekleri yüklenemedi: ')+e.message);}
    return false;
  };
  window.MEGJET_ITEM_OPTIONS={load,summary};
  window.addEventListener('megjet:languagechange',()=>{if(dialog?.open)dialog.close();});
  load().catch(()=>{});
})();
