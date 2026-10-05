(function(root){
 'use strict';
 const pattern=/\nMap pin: https:\/\/www\.google\.com\/maps\?q=(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)\s*$/;
 const valid=p=>!!p&&Number.isFinite(p.lat)&&Number.isFinite(p.lng)&&p.lat>=-90&&p.lat<=90&&p.lng>=-180&&p.lng<=180;
 function parse(value){const m=String(value||'').match(pattern);if(!m)return null;const pin={lat:Number(m[1]),lng:Number(m[2])};return valid(pin)?pin:null;}
 function clean(value){return String(value||'').replace(pattern,'').trim();}
 function serialize(address,pin){if(!clean(address)||!valid(pin))throw new Error('Choose a valid delivery pin.');return clean(address)+'\nMap pin: https://www.google.com/maps?q='+pin.lat.toFixed(6)+','+pin.lng.toFixed(6);}
 function destination(value){const p=parse(value);return p?p.lat.toFixed(6)+','+p.lng.toFixed(6):String(value||'');}
 const api={parse,clean,serialize,valid,destination};root.MegjetDeliveryPinCore=api;if(typeof module!=='undefined')module.exports=api;
})(typeof window==='undefined'?globalThis:window);
