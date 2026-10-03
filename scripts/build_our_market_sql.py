import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
m=json.loads((root/'data/our-market-import.json').read_text())
q=lambda s:"'"+s.replace("'","''")+"'"
vid=m['vendor']['id']
out=root/'database/our-market';out.mkdir(parents=True,exist_ok=True)
vendor="insert into public.vendors(id,name,bio,bio_en,bio_tr,bio_translation_source,active) values ("+q(vid)+"::uuid,'Our Market','Groceries, household essentials and everyday products.','Groceries, household essentials and everyday products.','Market ürünleri, ev ihtiyaçları ve günlük ürünler.','Groceries, household essentials and everyday products.',false) on conflict (id) do nothing;\n"
vendor="do $$ begin if exists(select 1 from public.vendors where lower(btrim(name))='our market' and id<>"+q(vid)+"::uuid) then raise exception 'Our Market already exists under another ID'; end if; end $$;\n"+vendor
cats='insert into public.vendor_menu_categories(vendor_id,name,name_en,sort_order) values\n'+',\n'.join('('+q(vid)+'::uuid,'+q(c)+','+q(c)+','+str(i)+')' for i,c in enumerate(m['categories']))+'\non conflict(vendor_id,name) do nothing;\n'
(out/'00-vendor-and-categories.sql').write_text('begin;\n'+vendor+cats+'commit;\n')
fields=['id','vendor_id','name','description','price','available','menu_sort_order']
batch_files=[]
for index,offset in enumerate(range(0,len(m['items']),200),1):
 rows=[{k:x[k] for k in fields} for x in m['items'][offset:offset+200]]
 sql='insert into public.products('+','.join(fields)+') select '+','.join(fields)+' from jsonb_to_recordset('+q(json.dumps(rows,ensure_ascii=False,separators=(',',':')))+'::jsonb) as x(id uuid,vendor_id uuid,name text,description text,price numeric,available boolean,menu_sort_order integer) on conflict(id) do nothing;\n'
 path=out/(str(index).zfill(2)+'-products.sql');path.write_text(sql);batch_files.append(path)
final="do $$ begin if (select count(*) from public.products where vendor_id="+q(vid)+"::uuid)<>"+str(len(m['items']))+" then raise exception 'Market import count mismatch'; end if; end $$;\nupdate public.vendors set active=true where id="+q(vid)+"::uuid;\n"
(out/'99-enable-market.sql').write_text(final)
(root/'database/our_market_import.sql').write_text('-- Source: 18 supplied market HTML files. Deterministic IDs make repeat imports safe.\n'+(out/'00-vendor-and-categories.sql').read_text()+''.join(p.read_text() for p in batch_files)+final)
print(json.dumps({'products':len(m['items']),'categories':len(m['categories']),'batches':len(batch_files)}))
