import json, re, unicodedata, uuid
from pathlib import Path
from decimal import Decimal
from bs4 import BeautifulSoup

ROOT = Path(__file__).resolve().parents[2]
DEPARTMENTS = {
 'waters':'Water & Ice','drinks':'Drinks','snacks':'Snacks','food':'Food',
 'meat and chicken':'Meat & Chicken','basic foods':'Basic Foods',
 'dairy and breakfast':'Dairy & Breakfast','bakery':'Bakery','fit and form':'Fit & Form',
 'home care':'Home Care','home life':'Home Life','personal care':'Personal Care',
 'technology':'Technology','sexual health':'Sexual Health','baby':'Baby',
 'clothing':'Clothing','stationery':'Stationery','pet':'Pet'
}
VENDOR_ID = str(uuid.uuid5(uuid.NAMESPACE_URL,'https://assam152002.github.io/Megjet/vendor/our-market'))
def clean(s): return re.sub(r'\s+',' ',unicodedata.normalize('NFC',s)).strip()
def text(e): return clean(e.get_text(' ',strip=True)) if e else ''
def heading(s): return re.sub(r'^[^A-Za-zÀ-ž0-9]+','',clean(s)).strip()
items=[]; categories=[]; sources=[]; duplicates=[]; conflicts=[]; seen={}
item_selector='li,.menu-item,.menu-card,.item-card,.product-item,.item,tr'
for file_key,department in DEPARTMENTS.items():
 path=ROOT/'upload'/('market '+file_key+'.html')
 soup=BeautifulSoup(path.read_text(),'html.parser')
 price_nodes=soup.body.select('.item-price,.product-price,.price')
 if file_key=='sexual health':price_nodes=[tr.find_all('td')[2] for tr in soup.select('tbody tr')]
 source_count=0; h2='';h3=''; price_set={id(p) for p in price_nodes}
 for node in soup.body.descendants:
  if not getattr(node,'name',None):continue
  if node.name in ('h2','h3') and not node.find_parent(class_=lambda c:c and c in ['menu-card','item-card','menu-item','product-item']):
   if node.name=='h2':h2=heading(text(node));h3=''
   else:h3=heading(text(node))
  if node.get('class') and ('category-title' in node['class'] or 'section-title' in node['class']):h2=heading(text(node));h3=''
  if id(node) not in price_set:continue
  source_count+=1
  container=node
  while container and not (container.name in ('li','tr') or any(c in container.get('class',[]) for c in ['menu-item','menu-card','item-card','product-item','item'])):container=container.parent
  if container is None:raise ValueError('No product container: '+path.name+' '+text(node))
  name_node=container.select_one('.item-name,.product-name') or container.find('h3') or container.find('a')
  details=[]
  if container.name=='tr':
   cells=container.find_all('td');name_node=cells[0];details=[text(cells[1])]
  else:
   for d in container.select('.item-size,.product-size,.product-details,.item-weight,.item-details,.item-info p'):
    if d.select_one('.item-name,.product-name,.item-price,.product-price,.price'):continue
    if d==name_node:continue
    value=text(d)
    if value and value not in details:details.append(value)
  name=text(name_node)
  if not name:raise ValueError('Missing name '+path.name)
  size=clean(' '.join(details)).strip('() ')
  full_name=name if not size or size.casefold() in name.casefold() else name+' ('+size+')'
  raw_price=text(node);m=re.fullmatch(r'([\d,]+(?:\.\d{1,2})?)\s*TL',raw_price)
  variants=[]
  if m:
   variants=[(size,str(Decimal(m[1].replace(',','')).quantize(Decimal('.01'))),True)]
  elif ' / ' in raw_price:
   sizes=size.split(' / ');prices=re.findall(r'([\d,]+\.\d{2})\s*TL',raw_price)
   if len(sizes)!=len(prices):raise ValueError('Unmapped sizes/prices '+name)
   variants=[(s,str(Decimal(p.replace(',','')).quantize(Decimal('.01'))),True) for s,p in zip(sizes,prices)]
  elif re.fullmatch(r'[\d,]+\.\d{2}\s*-\s*[\d,]+\.\d{2}\s*TL',raw_price):
   variants=[(size,str(Decimal(raw_price.split(' - ')[0].replace(',','')).quantize(Decimal('.01'))),False)]
  else:raise ValueError('Invalid price '+path.name+' '+raw_price)
  sub=h3 or h2
  category=department+(' · '+sub if sub and sub!=department else '')
  if len(category)>80:raise ValueError('Long category '+category)
  if category not in categories:categories.append(category)
  for size,price,available in variants:
   full_name=name if not size or size.casefold() in name.casefold() else name+' ('+size+')'
   key=full_name.casefold()
   row={'id':str(uuid.uuid5(uuid.UUID(VENDOR_ID),key)), 'vendor_id':VENDOR_ID,'department':department,'category':category,'name':full_name,'description':'['+category+']'+(' '+size if size else '')+(' — Source price range: '+raw_price+'. Exact variant prices need confirmation.' if not available else ''),'price':price,'available':available,'image_url':None,'source_file':path.name,'source_name':name,'pack_size':size,'source_index':source_count,'source_price':raw_price}
   if key in seen:
    prev=seen[key]
    if prev['price']!=price:conflicts.append({'first':prev,'second':row})
    else:duplicates.append({'name':full_name,'price':price,'kept_source':prev['source_file'],'removed_source':path.name})
    continue
   seen[key]=row;row['menu_sort_order']=len(items);items.append(row)
 sources.append({'file':path.name,'department':department,'source_products':source_count})
 if source_count!=len(price_nodes):raise ValueError('Missed prices '+path.name)
for row in items:
 matches=[c for c in conflicts if c['first']['id']==row['id']]
 if matches:
  prices=[row['price']]+[c['second']['price'] for c in matches]
  row['available']=False
  row['description']+=' — Source lists conflicting prices: '+', '.join(p+' TL' for p in prices)+'. Confirm the correct price before enabling.'
report={'vendor':{'id':VENDOR_ID,'name':'Our Market'},'sources':sources,'source_product_count':sum(s['source_products'] for s in sources),'unique_product_count':len(items),'categories':categories,'duplicates':duplicates,'conflicts':conflicts,'pending_price_review':[{'id':i['id'],'name':i['name'],'source_file':i['source_file'],'reason':i['description']} for i in items if not i['available']],'items':items}
out=ROOT/'megjet'/'data'/'our-market-import.json';out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'vendor':report['vendor'],'source_product_count':report['source_product_count'],'unique_product_count':len(items),'available':sum(i['available'] for i in items),'pending_price_review':len(report['pending_price_review']),'conflicting_names':len(set(c['first']['id'] for c in conflicts))},ensure_ascii=False))
print(json.dumps({'categories':len(categories),'sources':sources},ensure_ascii=False))
