(function(root){
 const normalize=s=>String(s||'').normalize('NFKD').replace(/[\u0300-\u036f]/g,'').toLowerCase();
 function select(vendors,products,state){
  const terms=normalize(state.query).trim().split(/\s+/).filter(Boolean), byVendor=new Map();
  products.forEach(p=>{const key=String(p.vendor_id);byVendor.set(key,(byVendor.get(key)||'')+' '+p.name+' '+(p.description||''));});
  return vendors.filter(v=>{
   const shop=/market/i.test(v.name),text=normalize(v.name+' '+(v.area||'')+' '+(byVendor.get(String(v.id))||''));
   return (state.view!=='shops'||shop)&&(state.view!=='favorites'||state.favorites.includes(String(v.id)))&&terms.every(t=>text.includes(t))&&(!state.category||text.includes(normalize(state.category)))&&(!state.rating||Number(v.rating)>=state.rating)&&(!state.time||(Number(v.preparation_minutes)>0&&Number(v.preparation_minutes)<=state.time))&&(!state.offers||state.offerVendors.includes(String(v.id)))&&(!state.maxFee||(Number.isFinite(state.fee)&&state.fee<=state.maxFee));
  }).sort((a,b)=>state.sort==='rating'?(Number(b.rating)||0)-(Number(a.rating)||0)||a.name.localeCompare(b.name):state.sort==='time'?(Number(a.preparation_minutes)||Infinity)-(Number(b.preparation_minutes)||Infinity)||a.name.localeCompare(b.name):a.name.localeCompare(b.name));
 }
 const api={normalize,select};root.MegjetDiscoveryCore=api;if(typeof module!=='undefined')module.exports=api;
})(typeof window==='undefined'?globalThis:window);
