const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const html = fs.readFileSync('index.html', 'utf8');
const definitions = [...html.matchAll(/function displayOrderId\([^)]*\)\{[\s\S]*?\n\}/g)];
const id = 'f762abb6-1234-4321-9876-0000b52b2bf4';
for (const [definition] of definitions) {
  const context = {}; vm.createContext(context); vm.runInContext(definition, context);
  assert.equal(context.displayOrderId(id), 'B52B2BF4');
}
const start = html.indexOf('function renderAdminOrders(){');
const end = html.indexOf('\nasync function ', start);
const code = html.slice(start, end);
const elements = {adminStatusFilter:{value:'all'},adminSearch:{value:'B52B2BF4'},adminOrders:{innerHTML:''}};
const order = {id, status:'confirmed',created_at:'2026-10-08T00:00:00Z',customer_name:'QA',subtotal:875,delivery_fee:130,total:1005};
const context = {window:{},adminOrdersCache:[order],adminOrderRiderMap:{},$:id=>elements[id],normalizedStatus:s=>s,escapeHtml:String,displayOrderId:uuid=>uuid.replace(/-/g,'').slice(-8).toUpperCase(),money:String,renderRiderAssignment:()=>'',renderAdminOrderItems:()=>'',escapeJsString:String};
vm.createContext(context);vm.runInContext(code,context);context.renderAdminOrders();
assert.ok(elements.adminOrders.innerHTML.includes('Order #B52B2BF4'));
assert.ok(!elements.adminOrders.innerHTML.includes('Order #F762ABB6'));
assert.ok(elements.adminOrders.innerHTML.includes(id), 'Actions must keep the full database ID');
assert.ok(!html.includes('String(o.id).slice(0,8).toUpperCase()'), 'Rider workload and admin cards must use the canonical number');
console.log('Order number regression passed: customer/admin format, search, rider workload and full action IDs.');
