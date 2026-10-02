"""Apply the owner's confirmed O'Feel portion, extras, sauce and cutlery prices.

Uses an observed database snapshot and keeps existing product/choice IDs.
Unrelated restaurants and existing portion/drink groups stay unchanged.
"""
import json,uuid,copy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
rows=json.loads((ROOT/'data/ofeel-before-confirmed-options.json').read_text())
vendor_id=rows[0]['vendor_id']
# Existing choice identifiers are retained for carts and previous order records.
extras=[
 ('option-1','Egg','Yumurta',50),
 ('option-2','Halloumi (2 pcs)','Hellim (2 Adet)',50),
 ('option-3','Kasseri Cheese','Kaşar Peyniri',50),
 ('option-4','Cheddar Cheese','Cheddar Peyniri',35),
 ('option-5','Mushrooms','Mantar',60),
 ('option-11','Jalapeno','Jalapeno',40),
 ('option-12','Caramelized Onion','Karamelize Soğan',30),
 ('option-6','Smokey Beef (1 slice)','Füme Dana (1 Dilim)',60),
 ('option-7','Salami','Salam',50),
 ('option-8','Sausage','Sosis',50),
 ('option-9','Pepperoni','Pepperoni',50),
 ('option-10','Lavash','Lavaş',25),
 ('option-13','Extra Chicken Doner (50 gr.)','Ekstra Tavuk Döner (50 gr.)',70),
 ('option-14','Fries (100 gr.)','Patates Kızartması (100 gr.)',120),
]
extra_group=dict(id='extras',label_en='Extras',label_tr='Ekstralar',min=0,max=14,defaults=[],choices=[dict(id=k,label_en=en,label_tr=tr,extra=price) for k,en,tr,price in extras])
sauces=[('mayonnaise','Mayonnaise','Mayonez'),('ketchup','Ketchup','Ketçap'),('cheddar','Cheddar Sauce','Cheddar Sos'),('mexican-salsa','Mexican Salsa','Meksika Salsa'),('hot-spicy','Hot Spicy','Acı Sos'),('bbq-ranch','BBQ Ranch','BBQ Ranch'),('spicy-ranch','Spicy Ranch','Acı Ranch'),('mustard','Mustard','Hardal'),('garlic-mayonnaise','Garlic Mayonnaise','Sarımsaklı Mayonez'),('sweet-chilli','Sweet Chilli','Tatlı Acı Sos'),('thai-sweet-sour','Thai Sweet & Sour','Tay Tatlı Ekşi Sos'),('cocktail','Cocktail Sauce','Kokteyl Sos')]
sauce_group=dict(id='optional-sauce',label_en='Optional Sauce',label_tr='İsteğe Bağlı Sos',min=1,max=1,defaults=['none'],choices=[dict(id='none',label_en='No optional sauce',label_tr='Ek sos istemiyorum',extra=0)]+[dict(id=k,label_en=en,label_tr=tr,extra=20) for k,en,tr in sauces])
cutlery_group=dict(id='cutlery',label_en='Cutlery Service',label_tr='Çatal Bıçak Servisi',min=1,max=1,defaults=['no'],choices=[dict(id='no',label_en="I Don't Want Cutlery Service",label_tr='Çatal bıçak istemiyorum',extra=0),dict(id='yes',label_en='I Want Cutlery Service',label_tr='Çatal bıçak istiyorum',extra=20)])
def q(x):return "'"+str(x).replace("'","''")+"'"
sql=['BEGIN;'];new=[];changed=[];locale_updates=[]
for p in rows:
 original=copy.deepcopy(p)
 if any(g['id']=='extras' for g in p['groups']):
  p['groups']=[copy.deepcopy(extra_group) if g['id']=='extras' else g for g in p['groups'] if g['id'] not in ['optional-sauce','cutlery']]
  p['groups'] += [copy.deepcopy(sauce_group),copy.deepcopy(cutlery_group)]
 if p['name']=='Zereshk polo ba morgh':
  p.update(price=415,available=True)
  for g in p['groups']:
   if g['id']=='size':g.update(label_en='Portion',label_tr='Porsiyon',choices=[dict(id='option-1',label_en='Normal',label_tr='Normal',extra=0),dict(id='option-2',label_en='1.5×',label_tr='1,5×',extra=90)])
  sql.append('UPDATE public.products SET price=415,available=true WHERE id=%s AND vendor_id=%s;'%(q(p['id']),q(vendor_id)))
 for k,en,tr,price in extras:
  if p['name']==en:
   p['price']=price
   sql.append('UPDATE public.products SET price=%s WHERE id=%s AND vendor_id=%s;'%(price,q(p['id']),q(vendor_id)))
   locale_updates.append(dict(product_id=p['id'],name_en=en,name_tr=tr,description_en='',description_tr=''))
 if p['groups']!=original['groups']:
  changed.append(p['id'])
  # Guard against overwriting an unrelated concurrent edit to a choice group.
  sql.append("DO $guard$ BEGIN IF NOT EXISTS(SELECT 1 FROM public.product_options WHERE product_id=%s AND (groups=%s::jsonb OR groups=%s::jsonb)) THEN RAISE EXCEPTION 'Choice groups changed since snapshot'; END IF; END $guard$;"%(q(p['id']),q(json.dumps(original['groups'],ensure_ascii=False)),q(json.dumps(p['groups'],ensure_ascii=False))))
  sql.append('UPDATE public.product_options SET groups=%s::jsonb WHERE product_id=%s;'%(q(json.dumps(p['groups'],ensure_ascii=False)),q(p['id'])))
for k,en,tr,price in extras:
 if any(p['name']==en for p in rows):continue
 pid=str(uuid.uuid5(uuid.NAMESPACE_URL,'https://assam152002.github.io/Megjet/ofeel-confirmed-extra/'+en))
 p=dict(id=pid,vendor_id=vendor_id,name=en,description='[Drinks, Extras & Sauces] ',price=price,available=True,menu_sort_order=max(p['menu_sort_order'] for p in rows)+1,groups=[])
 rows.append(p);new.append(pid)
 sql.append('INSERT INTO public.products(id,vendor_id,name,description,price,available,menu_sort_order) VALUES (%s,%s,%s,%s,%s,true,%s) ON CONFLICT(id) DO NOTHING;'%(q(pid),q(vendor_id),q(en),q(p['description']),price,p['menu_sort_order']))
 locale_updates.append(dict(product_id=pid,name_en=en,name_tr=tr,description_en='',description_tr=''))
for t in locale_updates:
 sql.append('INSERT INTO public.product_translations(product_id,name_en,name_tr,description_en,description_tr) VALUES (%s,%s,%s,%s,%s) ON CONFLICT(product_id) DO UPDATE SET name_en=excluded.name_en,name_tr=excluded.name_tr;'%(q(t['product_id']),q(t['name_en']),q(t['name_tr']),q(t['description_en']),q(t['description_tr'])))
expected=[{k:p[k] for k in ['id','price','available','groups']} for p in rows]
verify="""DO $verify$ DECLARE n integer; BEGIN
WITH expected AS (SELECT * FROM jsonb_to_recordset(%s::jsonb) AS x(id uuid,price numeric,available boolean,groups jsonb))
SELECT count(*) INTO n FROM expected e LEFT JOIN public.products p USING(id) LEFT JOIN public.product_options o ON o.product_id=p.id WHERE p.id IS NULL OR p.price IS DISTINCT FROM e.price OR p.available IS DISTINCT FROM e.available OR coalesce(o.groups,'[]'::jsonb) IS DISTINCT FROM e.groups;
IF n<>0 THEN RAISE EXCEPTION 'OFeel confirmation verification failed';END IF;
END $verify$;"""%q(json.dumps(expected,ensure_ascii=False))
sql += [verify,'COMMIT;']
(ROOT/'database/ofeel_confirmed_options.sql').write_text('\n'.join(sql)+'\n')
(ROOT/'database/ofeel_confirmed_options_verify.sql').write_text(verify+"\nSELECT '97 products match confirmed OFeel prices and choices' AS result;\n")
(ROOT/'data/ofeel-confirmed-options.json').write_text(json.dumps(dict(normal_price=415,one_and_half_price=505,extra_group=extra_group,optional_sauce_group=sauce_group,cutlery_group=cutlery_group,changed_products=changed,new_products=new,products=rows),ensure_ascii=False,indent=2))
# Update current menu records while retaining their original HTML occurrences as evidence.
manifest=json.loads((ROOT/'data/six-restaurant-menus.json').read_text());restaurant=next(r for r in manifest if r['id']==vendor_id)
existing={p['id']:p for p in restaurant['products']}
for p in rows:
 target=existing.get(p['id'])
 if target:target.update(price=p['price'],available=p['available'],groups=p['groups'])
 else:restaurant['products'].append(dict(id=p['id'],name=p['name'],category='Drinks, Extras & Sauces',description='',price=p['price'],available=True,featured=False,groups=[],source_prices=[],menu_sort_order=p['menu_sort_order'],source_index=None))
restaurant['warnings']=[];restaurant['owner_confirmation']='2026-10-02: Normal 415 TL; 1.5x 505 TL; 14 extras, optional sauce +20 TL, optional cutlery +20 TL.'
(ROOT/'data/six-restaurant-menus.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
locales=json.loads((ROOT/'data/six-restaurant-locales.json').read_text());byid={t['product_id']:t for t in locales}
for t in locale_updates:
 if t['product_id'] in byid:byid[t['product_id']].update(t)
 else:locales.append(t)
(ROOT/'data/six-restaurant-locales.json').write_text(json.dumps(locales,ensure_ascii=False,indent=2))
print('Prepared',len(rows),'products;',len(changed),'meal choice groups updated;',len(new),'new extras')
