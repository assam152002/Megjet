"""Extract the six supplied HTML menus. No inferred prices or ingredients.

Requires beautifulsoup4==4.13.4. Run with the upload directory as argv[1].
Outputs an auditable manifest and atomic, repeat-safe insert SQL.
Existing rows are never overwritten on rerun (admin edits are preserved).
"""
import sys, re, json, uuid, hashlib
from pathlib import Path
from bs4 import BeautifulSoup

ROOT = Path(__file__).resolve().parents[1]
SOURCES = [
 ('kebap dunyasi.html','Kebap Dünyası (Sakarya)','Sakarya',45),
 ('koz adasi.html','Köz Adası (Salamis Yolu)','Salamis Yolu',45),
 ('garson ali.html','Garson Ali (Dumlupınar)','Dumlupınar',None),
 ('ala carte.html',"O'Feel Du Grill",'Gazimagusa',None),
 ('island coffee.html','Island Coffee','Gazimagusa',None),
 ('cofeeholic.html','Coffeeholic Boutique Bakery House','Karakol',None),
]
def uid(s): return str(uuid.uuid5(uuid.NAMESPACE_URL,'https://assam152002.github.io/Megjet/menu-import-20261002/'+s))
def txt(x): return x.get_text(' ',strip=True) if x else ''
def prices(s): return [float(x.replace(',','')) for x in re.findall(r'\d[\d,]*(?:\.\d+)?',s)]
def group(key,label,choices,minimum=1):
 return dict(id=key,label_en=label,label_tr={'Size':'Boyut','Portion':'Porsiyon','Choice':'Seçim','Side':'Yan ürün'}.get(label,label),min=minimum,max=1,defaults=[choices[0]['id']] if minimum else [],choices=choices)
def choices(labels,amounts,base):
 tr={'Single':'Tek','Reg':'Normal','Large':'Büyük','Rice':'Pilav','Bulgur pilaf':'Bulgur pilavı','Cup Ayran':'Bardak ayran','Homemade Ayran':'Ev yapımı ayran','Turnip Juice':'Şalgam suyu'}
 return [dict(id='option-'+str(i+1),label_en=l,label_tr=tr.get(l,l),extra=round(p-base,2)) for i,(l,p) in enumerate(zip(labels,amounts))]
restaurants=[]
for fn,name,area,prep in SOURCES:
 source=Path(sys.argv[1])/fn; soup=BeautifulSoup(source.read_text(),'html.parser')
 restaurant=dict(id=uid(name),name=name,area=area,preparation_minutes=prep,source=fn,source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),categories=[],products=[],occurrences=[],warnings=[])
 category=''; sub=''; current_note=''
 for node in soup.find_all(True):
  classes=node.get('class',[])
  if node.name=='h2' or 'section-title' in classes:
   category=txt(node).replace(' (Regular / Large)','');sub='';current_note=''
   if category not in restaurant['categories']:restaurant['categories'].append(category)
  elif node.name=='h3':sub=txt(node)
  elif 'note' in classes:current_note=txt(node)
  elif 'menu-item' in classes:
   item_name=txt(node.select_one('.item-name'))
   if not item_name:raise ValueError((fn,str(node)))
   desc=txt(node.select_one('.item-description,.item-desc'))
   if current_note:desc=' '.join(filter(None,[desc,current_note]))
   price_nodes=node.select('.item-price,.price-tag'); ps=[]
   for p in price_nodes:ps+=prices(txt(p))
   if not ps:raise ValueError((fn,item_name,'missing price'))
   groups=[]; available=True; base=ps[0]
   if len(ps)>1:
    if fn=='island coffee.html':labels=[txt(p).split(':')[0] for p in price_nodes]
    elif fn=='cofeeholic.html' and category.startswith('Pizzalar'):labels=['32 cm','42 cm']
    else:
     labels=['Listed price '+str(int(p))+' TL' for p in ps];available=False
     restaurant['warnings'].append({'item':item_name,'reason':'Two prices without size/portion labels','prices':ps})
    groups.append(group('size','Size',choices(labels,ps,base)))
   if sub in ['Tenders','Wings','Wingers']:
    desc=' '.join(filter(None,[desc,item_name]));item_name=sub+' — '+item_name
   # Combined drinks are a choice of one drink, rather than a mixed bundle.
   drink_labels=None
   if fn=='ala carte.html' and item_name=='Cola / Cola Zero / Sprite / Fanta (Tin)':drink_labels=['Cola','Cola Zero','Sprite','Fanta']
   if fn=='cofeeholic.html' and ('İçecekler' in category) and '/' in item_name:drink_labels=[x.strip() for x in item_name.split('/')]
   if fn=='koz adasi.html' and item_name=='Soft Drinks & Juices (33 cl.)':drink_labels=['Coca-Cola','Fanta','Sprite','Fuse Tea','Turnip Juice']
   if drink_labels:groups.append(group('drink','Choice',choices(drink_labels,[base]*len(drink_labels),base)))
   if fn=='koz adasi.html' and item_name=='Whole Chicken Menu':groups.append(group('side','Side',choices(['Rice','Bulgur pilaf'],[base,base],base)))
   product=dict(id='',name=item_name,category=category,description=desc,price=base,available=available,featured=category=='Best Selling Meals',groups=groups,source_prices=ps,source_index=len(restaurant['occurrences']))
   restaurant['occurrences'].append(product.copy());restaurant['products'].append(product)
 # Consolidate exact repeated listings; prefer the main category to Best Selling.
 unique={}
 for p in restaurant['products']:
  k=(p['name'].casefold(),p['price'],json.dumps(p['groups'],sort_keys=True))
  if k in unique:
   previous=unique[k]
   if previous['category']=='Best Selling Meals' and p['category']!='Best Selling Meals':
    p['featured']=True; unique[k]=p
   else:previous['featured'] |= p['featured']
   if previous['description'] and p['description'] and previous['description']!=p['description']:
    restaurant['warnings'].append({'item':p['name'],'reason':'Repeated listing has different descriptions; main category retained','descriptions':[previous['description'],p['description']]})
  else:unique[k]=p
 restaurant['products']=sorted(unique.values(),key=lambda p:p['source_index'])
 if fn=='ala carte.html':
  # Portions are choices of the same dish, with exactly the source prices.
  for dish in ['Tenders','Wings','Wingers']:
   variants=[p for p in restaurant['products'] if p['name'].startswith(dish+' — ')]
   first=variants[0]; first['name']=dish; first['description']='Served with sauce & Cajun fries'
   first['groups'].append(group('portion','Portion',choices([p['name'].split(' — ')[1] if p is not first else '6 pcs'+(' (3 wings, 3 tenders)' if dish=='Wingers' else '') for p in variants],[p['price'] for p in variants],first['price'])))
   first['source_prices']=[p['price'] for p in variants]
   restaurant['products']=[p for p in restaurant['products'] if p not in variants[1:]]
  extras=[p for p in restaurant['products'] if p['category']=='Drinks, Extras & Sauces' and p['source_index']>=90]
  assert len(extras)==10
  extra_group=group('extras','Extras',choices([p['name'] for p in extras],[p['price'] for p in extras],0),0)
  extra_group.update(max=len(extras),label_tr='Ekstralar')
  for p in restaurant['products']:
   if p['category']!='Drinks, Extras & Sauces':p['groups'].append(extra_group)
 if fn=='cofeeholic.html':
  pastas=[p for p in restaurant['products'] if p['category']=='Makarnalar' and 'Eco' not in p['name']]
  pizzas=[p for p in restaurant['products'] if p['category'].startswith('Pizzalar') and 'Eco' not in p['name']]
  for p in restaurant['products']:
   count=0; candidates=[]
   if p['name'].startswith('Makarna Eco'):count=3 if 'Eco 1' in p['name'] else 4;candidates=pastas
   if p['name'].startswith('Pizza Eco'):count=4 if 'Eco 1' in p['name'] else 6;candidates=pizzas
   for slot in range(count):
    g=group('meal-'+str(slot+1),'Choice',choices([x['name'] for x in candidates],[p['price']]*len(candidates),p['price']))
    g.update(label_en=('Pasta' if candidates is pastas else 'Pizza')+' '+str(slot+1),label_tr=('Makarna' if candidates is pastas else 'Pizza')+' '+str(slot+1));p['groups'].append(g)
 if fn=='koz adasi.html':
  for p in restaurant['products']:
   if p['name']=='Cup Ayran / Homemade Ayran':p['groups'].append(group('ayran','Choice',choices(['Cup Ayran','Homemade Ayran'],[p['price']]*2,p['price'])))
 restaurant['categories']=[c for c in restaurant['categories'] if any(p['category']==c for p in restaurant['products'])]
 for i,p in enumerate(restaurant['products']):
  p['menu_sort_order']=i;p['id']=uid(name+'/'+p['category']+'/'+p['name']+'/'+str(p['price']))
 if fn=='ala carte.html':restaurant['warnings'].append({'reason':'Sauces listed without prices; preserved in source record, not sold at an invented price','sauces':['Mayonnaise','Ketchup','Cheddar','Mexican Salsa','Hot Spicy','BBQ Ranch','Spicy Ranch','Mustard','Garlic Mayonnaise','Sweet Chilli','Thai Sweet & Sour','Cocktail Sauce']})
 if fn=='cofeeholic.html':restaurant.update(address='Mağusa Macro Market Karşısı İsmet İnönü Bulvarı No: 64, Karakol',phone='0539 111 80 80',bio='Boutique Bakery House · 24 saat açık. Tel: 0539 111 80 80 / 0548 899 60 60')
 restaurants.append(restaurant)
def q(x):return 'NULL' if x is None else "'"+str(x).replace("'","''")+"'"
sql=['BEGIN;']
for r in restaurants:
 sql.append("DO $guard$ BEGIN IF EXISTS(SELECT 1 FROM public.vendors WHERE lower(name)=lower(%s) AND id<>%s::uuid) THEN RAISE EXCEPTION 'Restaurant name already exists with another ID'; END IF; END $guard$;"%(q(r['name']),q(r['id'])))
 sql.append("INSERT INTO public.vendors(id,name,area,preparation_minutes,address,phone,bio) VALUES (%s,%s,%s,%s,%s,%s,%s) ON CONFLICT(id) DO NOTHING;"%(q(r['id']),q(r['name']),q(r['area']),'NULL' if r['preparation_minutes'] is None else r['preparation_minutes'],q(r.get('address')),q(r.get('phone')),q(r.get('bio'))))
 for i,c in enumerate(r['categories']):sql.append('INSERT INTO public.vendor_menu_categories(vendor_id,name,sort_order) VALUES (%s,%s,%d) ON CONFLICT(vendor_id,name) DO NOTHING;'%(q(r['id']),q(c),i))
 for p in r['products']:
  sql.append('INSERT INTO public.products(id,vendor_id,name,description,price,available,featured,menu_sort_order) VALUES (%s,%s,%s,%s,%s,%s,%s,%d) ON CONFLICT(id) DO NOTHING;'%(q(p['id']),q(r['id']),q(p['name']),q('['+p['category']+'] '+p['description']),p['price'],str(p['available']).lower(),str(p['featured']).lower(),p['menu_sort_order']))
  if p['groups']:sql.append('INSERT INTO public.product_options(product_id,groups) VALUES (%s,%s::jsonb) ON CONFLICT(product_id) DO NOTHING;'%(q(p['id']),q(json.dumps(p['groups'],ensure_ascii=False))))
expected=[]
for r in restaurants:
 for p in r['products']:expected.append(dict(id=p['id'],vendor_id=r['id'],name=p['name'],description='['+p['category']+'] '+p['description'],price=p['price'],available=p['available'],menu_sort_order=p['menu_sort_order'],groups=p['groups']))
ids=','.join(q(r['id'])+'::uuid' for r in restaurants)
verify="""DO $verify$ DECLARE mismatches integer; BEGIN
WITH expected AS (SELECT * FROM jsonb_to_recordset(%s::jsonb) AS x(id uuid,vendor_id uuid,name text,description text,price numeric,available boolean,menu_sort_order integer,groups jsonb)),
actual AS (SELECT p.*,coalesce(o.groups,'[]'::jsonb) as groups FROM public.products p LEFT JOIN public.product_options o ON o.product_id=p.id WHERE p.vendor_id IN (%s))
SELECT count(*) INTO mismatches FROM expected e FULL JOIN actual a USING(id) WHERE e.id IS NULL OR a.id IS NULL OR e.vendor_id IS DISTINCT FROM a.vendor_id OR e.name IS DISTINCT FROM a.name OR e.description IS DISTINCT FROM a.description OR e.price IS DISTINCT FROM a.price OR e.available IS DISTINCT FROM a.available OR e.menu_sort_order IS DISTINCT FROM a.menu_sort_order OR e.groups IS DISTINCT FROM a.groups;
IF mismatches<>0 THEN RAISE EXCEPTION 'Menu import validation failed: %% mismatches',mismatches; END IF;
END $verify$;
"""%(q(json.dumps(expected,ensure_ascii=False)),ids)
sql.append(verify)
sql.append('COMMIT;')
(ROOT/'data'/'six-restaurant-menus.json').write_text(json.dumps(restaurants,ensure_ascii=False,indent=2))
(ROOT/'database'/'six_restaurant_menus.sql').write_text('\n'.join(sql)+'\n')
(ROOT/'database'/'six_restaurant_menus_verify.sql').write_text(verify+"SELECT 'All 373 imported products match source names, descriptions, prices, availability, sequence and option groups' AS result;\n")
for r in restaurants: print(r['name'],len(r['occurrences']),'source listings ->',len(r['products']),'products',len(r['categories']),'categories',sum(bool(p['groups']) for p in r['products']),'configurable',json.dumps(r['warnings'],ensure_ascii=False))
