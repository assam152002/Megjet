import webpush from 'npm:web-push@3.6.7';
import { createClient } from 'npm:@supabase/supabase-js@2.57.4';
const db=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false}});
const json=(data:unknown,status=200)=>new Response(JSON.stringify(data),{status,headers:{'Content-Type':'application/json'}});
async function sameSecret(a:string,b:string){
 const hash=async(s:string)=>new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(s)));
 const [x,y]=await Promise.all([hash(a),hash(b)]);let diff=0;for(let i=0;i<x.length;i++)diff|=x[i]^y[i];return diff===0;
}
Deno.serve(async(req)=>{
 if(req.method!=='POST')return json({error:'Method not allowed'},405);
 const bearer=req.headers.get('Authorization')?.replace(/^Bearer /,'')||'';
 if(!bearer)return json({error:'Unauthorized'},401);
 const {data:cfg,error:configError}=await db.rpc('megjet_push_server_config');
 if(configError||!cfg?.megjet_push_dispatch_token)return json({error:'Push configuration unavailable'},503);
 if(!await sameSecret(bearer,cfg.megjet_push_dispatch_token))return json({error:'Unauthorized'},401);
 try{
  webpush.setVapidDetails('https://assam152002.github.io/Megjet/',cfg.megjet_vapid_public,cfg.megjet_vapid_private);
  const {data:jobs,error}=await db.rpc('megjet_claim_push');if(error)throw error;
  let sent=0,failed=0;
  for(const job of jobs||[]){
   const {data:subs,error:subError}=await db.from('megjet_push_subscriptions').select('endpoint,keys,locale').eq('user_id',job.user_id);
   let retry=!!subError;
   for(const sub of subs||[]){
    const tr=sub.locale==='tr';
    const body=tr?'Güncellemeleri görmek için Megjet uygulamasını açın.':'Open Megjet to view updates.';
    try{
     // Use the library's encryption/VAPID implementation with native fetch in Edge Runtime.
     const details=webpush.generateRequestDetails(sub,JSON.stringify({title:'Megjet',body,tag:'megjet-update',url:'./'}),{TTL:300,urgency:'high'});
     const response=await fetch(details.endpoint,{method:'POST',headers:details.headers,body:new Uint8Array(details.body),signal:AbortSignal.timeout(10000)});
     if(response.status===404||response.status===410)await db.from('megjet_push_subscriptions').delete().eq('endpoint',sub.endpoint);
     else if(!response.ok){retry=true;failed++;}else sent++;
    }catch{retry=true;failed++;}
   }
   const {error:doneError}=await db.from('megjet_push_outbox').update({state:retry?(job.attempts>=5?'failed':'pending'):'sent',next_attempt:new Date(Date.now()+Math.min(300,30*2**job.attempts)*1000).toISOString()}).eq('id',job.id);
   if(doneError)throw doneError;
  }
  return json({processed:jobs?.length||0,sent,failed});
 }catch{return json({error:'Push dispatch failed'},500);}
});
