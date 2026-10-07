const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const html=fs.readFileSync('index.html','utf8');
for(const m of html.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/gi)){if(!/\bsrc\s*=|application\/ld\+json/.test(m[1]))new vm.Script(m[2]);}
const extract=name=>html.match(new RegExp('function '+name+'\\([^)]*\\)\\{[\\s\\S]*?\\n\\}'))[0];
const nodes={previousOrderText:{textContent:''},previousOrder:{classList:{remove:()=>{}}},openPreviousOrder:{}};
let saved='f762abb6-1234-4321-9876-0000b52b2bf4';
const ctx={localStorage:{getItem:()=>saved},$:id=>nodes[id],trackedOrderId:'old',showTracking:()=>{ctx.opened=ctx.trackedOrderId}};vm.createContext(ctx);
vm.runInContext(extract('displayOrderId')+'\n'+extract('showPreviousOrder')+'\n'+extract('phoneForWhatsApp')+'\n'+extract('phoneForCall'),ctx);
ctx.showPreviousOrder();assert.ok(nodes.previousOrderText.textContent.includes('#B52B2BF4'));
const click=html.slice(html.indexOf('$("openPreviousOrder").onclick=()=>{'),html.indexOf('$("openPreviousOrder").onclick=()=>{')+250).match(/^[\s\S]*?\n\};/)[0];vm.runInContext(click,ctx);nodes.openPreviousOrder.onclick();assert.equal(ctx.opened,saved);
assert.equal(ctx.phoneForWhatsApp('05338412009'),'905338412009');assert.equal(ctx.phoneForWhatsApp('03152921945'),'923152921945');assert.equal(ctx.phoneForWhatsApp('+923152921945'),'923152921945');
vm.runInContext('let MEGJET_SUPPORT_PHONE="",MEGJET_SUPPORT_WHATSAPP="";\n'+extract('megjetSupportHTML'),ctx);assert.ok(!ctx.megjetSupportHTML().includes('href="tel:'));assert.ok(!ctx.megjetSupportHTML().includes('href="https://wa.me/'));assert.ok(ctx.megjetSupportHTML().includes('Chat with Megjet'));
vm.runInContext('MEGJET_SUPPORT_PHONE="+905338412009";MEGJET_SUPPORT_WHATSAPP="905338412009";',ctx);assert.ok(ctx.megjetSupportHTML().includes('href="tel:+905338412009"'));assert.ok(ctx.megjetSupportHTML().includes('https://wa.me/905338412009?'));
assert.ok(html.includes('window.MEGJET_DELIVERY_PIN?.set("address","")'));assert.ok(html.includes('data-mj-minus="\'+i+\'" aria-label="Decrease quantity"'));assert.ok(html.includes('data-mj-plus="\'+i+\'" aria-label="Increase quantity"'));
console.log('Customer UI: latest-order navigation, phone prefixes, configured support links, pin reset, labels and script syntax passed.');
