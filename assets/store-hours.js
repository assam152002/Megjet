/* Published hours only; all comparisons use the Gazimagusa clock. */
(function(root){
'use strict';
const zone='Asia/Famagusta',week=['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
const normalize=s=>String(s||'').normalize('NFKD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/ı/g,'i');
function parse(text){
 text=normalize(text);if(/24\s*(?:saat|hours?)|24\/7/.test(text))return {always:true};
 const m=text.match(/(\d{1,2})[:.](\d{2})\s*(am|pm)?\s*[–—-]\s*(\d{1,2})[:.](\d{2})\s*(am|pm)?/i);if(!m)return null;
 const minutes=(h,m,ampm)=>{h=Number(h);m=Number(m);if(m>59||h>(ampm?12:23)||h<0||(ampm&&h<1))return NaN;return (ampm?(h%12+(ampm==='pm'?12:0)):h)*60+m;};
 const start=minutes(m[1],m[2],m[3]),end=minutes(m[4],m[5],m[6]);if(!Number.isFinite(start)||!Number.isFinite(end)||start===end)return null;
 let days=[0,1,2,3,4,5,6];if(/mon\s*[–—-]\s*sat/.test(text))days=[1,2,3,4,5,6];else if(/mon\s*[–—-]\s*fri|hafta ici|weekdays/.test(text))days=[1,2,3,4,5];else if(/sun(?:day)?\s*closed/.test(text))days=[1,2,3,4,5,6];
 return {start,end,days};
}
function clock(now){const values=Object.fromEntries(new Intl.DateTimeFormat('en-GB',{timeZone:zone,weekday:'short',hour:'2-digit',minute:'2-digit',hourCycle:'h23'}).formatToParts(now).map(p=>[p.type,p.value]));return {day:week.indexOf(values.weekday),minute:Number(values.hour)*60+Number(values.minute)};}
function evaluate(schedule,now=new Date()){
 if(!schedule)return {known:false,open:null};if(schedule.always)return {known:true,open:true,always:true};
 const {day,minute}=clock(now),overnight=schedule.end<schedule.start,previous=(day+6)%7;
 if(schedule.days.includes(day)&&minute>=schedule.start&&(overnight||minute<schedule.end))return {known:true,open:true,closes:schedule.end};
 if(overnight&&schedule.days.includes(previous)&&minute<schedule.end)return {known:true,open:true,closes:schedule.end};
 for(let ahead=0;ahead<8;ahead++)if(schedule.days.includes((day+ahead)%7)&&(ahead>0||minute<schedule.start))return {known:true,open:false,opens:schedule.start,daysAhead:ahead,day:(day+ahead)%7};
 return {known:false,open:null};
}
function source(v){const maps=root.MEGJET_VENDOR_HOURS||{},key=Object.keys(maps).find(k=>normalize(k)===normalize(v.name));const candidate=maps[key];return candidate&&parse(candidate)?candidate:(v.bio||'');}
const time=n=>String(Math.floor(n/60)).padStart(2,'0')+':'+String(n%60).padStart(2,'0');
function status(v,now=new Date(),lang='en'){
 const tr=lang==='tr',hours=evaluate(parse(source(v)),now);let label,detail;
 if(v.coming_soon)return {label:tr?'Yakında':'Coming soon',detail:'',closed:true,known:hours.known};
 if(v.accepting_orders===false)return {label:tr?'Siparişler duraklatıldı':'Orders paused',detail:tr?'Yeni sipariş alınmıyor':'New orders are paused',closed:true,known:hours.known};
 if(!hours.known)return {label:tr?'Sipariş alıyor':'Accepting orders',detail:tr?'Çalışma saatleri belirtilmedi':'Hours unavailable',closed:false,known:false};
 if(hours.open){label=tr?'Şimdi açık':'Open now';detail=hours.always?(tr?'24 saat açık':'Open 24 hours'):(tr?'Kapanış ':'Closes at ')+time(hours.closes);}
 else {label=tr?'Kapalı':'Closed';const days=tr?['Paz','Pzt','Sal','Çar','Per','Cum','Cmt']:week;detail=(tr?'Açılış ':'Opens ')+(hours.daysAhead===0?(tr?'bugün ':'today '):hours.daysAhead===1?(tr?'yarın ':'tomorrow '):days[hours.day]+' ')+time(hours.opens);}
 return {label,detail,closed:!hours.open,known:true};
}
const api={parse,clock,evaluate,status,source,zone};root.MEGJET_HOURS=api;if(typeof module!=='undefined')module.exports=api;
})(typeof window==='undefined'?globalThis:window);
