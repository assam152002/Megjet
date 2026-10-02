const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const html=fs.readFileSync('index.html','utf8');
for(const m of html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g))new vm.Script(m[1]);
new vm.Script(fs.readFileSync('sw.js','utf8'));
const helper=html.slice(html.indexOf('async function fetchJson('),html.indexOf('\nasync function testConnection'));
async function run(fetch,body){
 const timers=new Set();
 const ctx=vm.createContext({fetch,AbortController,TypeError,setTimeout:(fn,ms)=>{const t=setTimeout(fn,ms/1000);timers.add(t);return t;},clearTimeout:t=>{clearTimeout(t);timers.delete(t);}});
 vm.runInContext(helper,ctx);try{await body(ctx.fetchJson);}finally{assert.equal(timers.size,0);}
}
(async()=>{
 let calls=0;
 await run(async()=>{calls++;await new Promise(r=>setTimeout(r,10));return {ok:true,text:async()=>'{"ok":true}'};},async f=>assert.equal((await f('/menu')).ok,true));assert.equal(calls,1);
 calls=0;
 await run(async(_,o)=>{calls++;if(calls===1)return new Promise((_,reject)=>o.signal.addEventListener('abort',()=>reject(Object.assign(new Error('timeout'),{name:'AbortError'}))));return {ok:true,text:async()=>'[]'};},async f=>assert.equal((await f('/menu')).length,0));assert.equal(calls,2);
 calls=0;await run(async()=>{calls++;throw new TypeError('Network failed');},async f=>assert.rejects(f('/menu')));assert.equal(calls,2);
 calls=0;await run(async()=>{calls++;return {ok:false,status:401,text:async()=>'{"message":"Unauthorized"}'};},async f=>assert.rejects(f('/menu'),/Unauthorized/));assert.equal(calls,1);
 calls=0;await run(async()=>{calls++;return {ok:false,status:503,text:async()=>'{}'};},async f=>assert.rejects(f('/menu')));assert.equal(calls,2);
 calls=0;await run(async()=>{calls++;throw new TypeError('Network failed');},async f=>assert.rejects(f('/checkout',{method:'POST'})));assert.equal(calls,1);
 const loadCode=html.slice(html.indexOf('let restaurantLoadPromise='),html.indexOf('/* NO.33 Limon Tantuni — imported'));
 const elements={vendors:{innerHTML:''}};let setupShown=0,hidden=0,renders=0,reads=0,listener;
 const ctx=vm.createContext({escapeHtml:s=>String(s),$:id=>elements[id]||{},cfg:{url:'https://test.invalid',key:'publishable'},window:{addEventListener:(name,fn)=>{if(name==='online')listener=fn;}},setStatus:()=>{},showSetup:()=>setupShown++,hideSetup:()=>hidden++,loadDeliveryFee:async()=>100,fetchJson:async()=>{reads++;await new Promise(r=>setTimeout(r,5));return [];},megjetFetchPages:async()=>[],renderVendors:()=>renders++,loadGrowthHome:async()=>{},MEGJET_COMING_SOON_ALCOHOL_VENDOR:{},MEGJET_COMING_SOON_ALCOHOL_PRODUCTS:[],console:{warn:()=>{}}});
 vm.runInContext(loadCode,ctx);const a=ctx.load(),b=ctx.load();assert.equal(a,b);await a;assert.equal(reads,2);assert.equal(renders,1);assert.equal(setupShown,0);
 ctx.fetchJson=async()=>{throw new TypeError('Offline');};await ctx.load();assert.match(elements.vendors.innerHTML,/Retry/);assert.match(elements.vendors.innerHTML,/Support reference: DISPLAY-ERROR/);assert.equal(setupShown,0);assert.ok(hidden);
 ctx.fetchJson=async()=>[];listener();await ctx.load();assert.equal(renders,2);
 console.log('Passed: script syntax, slow reads, bounded read retries, no auth/write retries, timer cleanup, load deduplication, customer error screen and reconnection recovery.');
})().catch(e=>{console.error(e);process.exitCode=1;});
