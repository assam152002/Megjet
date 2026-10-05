const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
for(const file of ['assets/florist.js','assets/florist-portal.js']){
 const source=fs.readFileSync(file,'utf8');const context={};vm.runInNewContext(source.match(/function flowerRows\(rows\).*\n/)[0]+'this.normalize=flowerRows',context);
 const rows=context.normalize([{flower_quotes:null},{flower_quotes:[{flower_acceptances:null}]},{flower_quotes:[{flower_acceptances:{id:'accepted'}}]},{flower_quotes:[{flower_acceptances:[{id:'accepted'}]}]}]);
 assert.equal(rows[0].flower_quotes.length,0);assert.equal(rows[1].flower_quotes[0].flower_acceptances.length,0);assert.equal(rows[2].flower_quotes[0].flower_acceptances[0].id,'accepted');assert.equal(rows[3].flower_quotes[0].flower_acceptances.length,1);
 assert.equal(context.normalize(null).length,0);
}
console.log('Flower relations: null, single acceptance and array acceptance handled in all portals.');
