const assert=require('node:assert/strict'),{select}=require('../assets/discovery-core.js');
const vendors=[{id:'a',name:'Café Kitchen',rating:4.7,preparation_minutes:20},{id:'b',name:'Our Market',rating:4.2,preparation_minutes:40},{id:'c',name:'New Diner',rating:null,preparation_minutes:null}];
const products=[{vendor_id:'a',name:'Chicken Pizza'},{vendor_id:'b',name:'Milk'}];
const base={view:'all',query:'',category:'',rating:0,time:0,maxFee:0,sort:'name',offers:false,favorites:['a'],offerVendors:[],fee:75};
const ids=s=>select(vendors,products,{...base,...s}).map(v=>v.id);
assert.deepEqual(ids({query:'chicken pizza'}),['a']);assert.deepEqual(ids({query:'cafe'}),['a']);assert.deepEqual(ids({view:'market',query:'milk'}),['b']);assert.deepEqual(ids({view:'favorites',rating:4.5,time:30}),['a']);assert.deepEqual(ids({time:30}),['a']);assert.deepEqual(ids({offers:true}),[]);assert.deepEqual(ids({offers:true,offerVendors:['b']}),['b']);assert.deepEqual(ids({maxFee:50}),[]);assert.deepEqual(ids({maxFee:100,sort:'rating'}),['a','b','c']);assert.deepEqual(ids({sort:'time'}),['a','b','c']);assert.deepEqual(ids({category:'Pizza',query:'milk'}),[]);assert.deepEqual(select([{id:'d',name:'Alcohol And Cigerattes'}],[],{...base,view:'shops'}).map(v=>v.id),['d']);console.log('12 discovery behaviour checks passed');
const dessertVendors=[{id:'s',name:'Sweet Holes'},{id:'e',name:'Çikolata Evim Gazimağusa'},{id:'m',name:'Our Market'},{id:'t',name:'Turkish Kitchen'}];
const dessertProducts=[{vendor_id:'s',name:'Classic Ring'},{vendor_id:'e',name:'Belçika Çikolatalı Waffle'},{vendor_id:'m',name:'Chocolate Cake'},{vendor_id:'t',name:'Tavuk Şiş'}];
assert.deepEqual(select(dessertVendors,dessertProducts,{...base,category:'Dessert'}).map(v=>v.id).sort(),['e','s']);
assert.deepEqual(select(dessertVendors,dessertProducts,{...base,category:'Chicken'}).map(v=>v.id),['t']);
assert.deepEqual(select(dessertVendors,dessertProducts,{...base,category:'Dessert',view:'shops'}),[]);
assert.deepEqual(select(dessertVendors,dessertProducts,{...base,query:'cikolata'}).map(v=>v.id),['e']);
console.log('4 multilingual cuisine regressions passed');

assert.deepEqual(ids({view:'shops',query:'milk'}),[]);
const florist={id:'f',name:'Alya Çiçek Evi',quote_only:true};
assert.deepEqual(select([...vendors,florist],[],{...base,view:'shops'}).map(v=>v.id),['f']);
assert.deepEqual(select([...vendors,florist],[],{...base,view:'market'}).map(v=>v.id),['b']);
console.log('Separate Shops and Market regression checks passed');
