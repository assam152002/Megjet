(function(root){
 const normalize=s=>String(s||'').normalize('NFKD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/ı/g,'i');
 const cuisines={Pizza:/\bpizza|pizzalar/,Burger:/burger|hamburger/,Kebab:/kebab|kebap|doner|tantuni|kofte|shawarma/,Chicken:/chicken|tavuk|pilic/,Dessert:/dessert|tatli|waffle|donut|doughnut|cheesecake|magnolia|kruvasan|croissant|baklava|kunefe|helva|ice cream|dondurma/,Drinks:/drink|icecek|coffee|kahve|cay|tea|milkshake|lemonade|limonata|juice|meyve suyu|water|\bsu\b|ayran/};
 function matchesCuisine(v,p,category){
  if(/market|alcohol|cigerattes|cigarettes|çiçek|cicek|florist/i.test(v.name))return false;
  const pattern=cuisines[category];if(!pattern)return false;
  if(category==='Dessert'&&/cikolata evim|sweet\s*holes|helvaci ali/.test(normalize(v.name)))return true;
  return pattern.test(normalize((p?.name||'')+' '+(p?.description||'')));
 }
 function select(vendors,products,state){
  const terms=normalize(state.query).trim().split(/\s+/).filter(Boolean), byVendor=new Map();
  products.forEach(p=>{const key=String(p.vendor_id);byVendor.set(key,(byVendor.get(key)||'')+' '+p.name+' '+(p.description||''));});
  return vendors.filter(v=>{
   const market=/market/i.test(v.name)&&!/alcohol|cigerattes|cigarettes/i.test(v.name),shop=!market&&(/alcohol|cigerattes|cigarettes|çiçek|cicek|florist/i.test(v.name)||v.quote_only),text=normalize(v.name+' '+(v.area||'')+' '+(byVendor.get(String(v.id))||''));
   return (state.view!=='shops'||shop)&&(state.view!=='market'||market)&&(state.view!=='favorites'||state.favorites.includes(String(v.id)))&&terms.every(t=>text.includes(t))&&(!state.category||products.some(p=>String(p.vendor_id)===String(v.id)&&matchesCuisine(v,p,state.category)))&&(!state.rating||Number(v.rating)>=state.rating)&&(!state.time||(Number(v.preparation_minutes)>0&&Number(v.preparation_minutes)<=state.time))&&(!state.offers||state.offerVendors.includes(String(v.id)))&&(!state.maxFee||(Number.isFinite(state.fee)&&state.fee<=state.maxFee));
  }).sort((a,b)=>state.sort==='rating'?(Number(b.rating)||0)-(Number(a.rating)||0)||a.name.localeCompare(b.name):state.sort==='time'?(Number(a.preparation_minutes)||Infinity)-(Number(b.preparation_minutes)||Infinity)||a.name.localeCompare(b.name):a.name.localeCompare(b.name));
 }
 const api={normalize,select,matchesCuisine};root.MegjetDiscoveryCore=api;if(typeof module!=='undefined')module.exports=api;
})(typeof window==='undefined'?globalThis:window);
