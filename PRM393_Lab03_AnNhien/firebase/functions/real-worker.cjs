'use strict';
const {createHash,randomUUID}=require('node:crypto');
const {Timestamp}=require('firebase-admin/firestore');
const {createNotificationEvents}=require('./notification-events.cjs');
const {sendInboxPush}=require('./push-delivery.cjs');
const STREAMS={caregivers:'createdAt',completions:'updatedAt',scheduleEvents:'createdAt',notifications:'receivedAt'};
function createRealWorker(db,messaging,admin,{now=Date.now,log=console,setTimer=setTimeout,clearTimer=clearTimeout}={}){
 const events=createNotificationEvents(db),checkpoints=new Map(),subscriptions=new Map(),timers=new Map(),campaigns=new Map();
 let stopped=true,generation=0,starting=null,initializing=false,lastSuccess=null,lastError=null;
 const delay=error=>error.code===8||error.code===9?900000:30000;
 function cancel(key){if(timers.has(key)){clearTimer(timers.get(key));timers.delete(key);}}
 function later(key,ms,fn){cancel(key);if(stopped)return;timers.set(key,setTimer(()=>{timers.delete(key);if(!stopped)fn();},Math.min(2147483647,Math.max(0,ms))));}
 function detach(key){const unsubscribe=subscriptions.get(key);subscriptions.delete(key);unsubscribe?.();}
 function failure(error,source){lastError=error.code||'worker-error';log.error('Realtime worker retry pending',{source,code:lastError});}
 async function push(doc){
  const uid=doc.ref.parent.parent?.id;if(!uid||doc.ref.parent.parent.parent.id!=='users')return;
  const receipt=db.doc(`serverPushReceipts/${createHash('sha256').update(doc.ref.path).digest('hex')}`),lease=randomUUID();
  const acquired=await db.runTransaction(async tx=>{const existing=(await tx.get(receipt)).data();if(existing?.status==='sent'||existing?.leaseUntil?.toMillis()>now())return false;tx.set(receipt,{status:'sending',lease,leaseUntil:Timestamp.fromMillis(now()+120000)});return true;});
  if(!acquired){const current=(await receipt.get()).data();if(current?.status==='sent')return;throw new Error('Push is leased by another worker.');}
  try{await sendInboxPush(db,messaging,{uid,id:doc.id,data:doc.data()},now());await receipt.update({status:'sent',finishedAt:Timestamp.fromMillis(now())});}
  catch(error){await receipt.update({status:'retry',leaseUntil:Timestamp.fromMillis(0)});throw error;}
 }
 async function handle(name,doc){
  const owner=doc.ref.parent.parent;if(owner?.parent.id!=='users')return;
  if(name==='notifications')return push(doc);
  if(name==='caregivers')return events.pairingChanged({eventId:doc.ref.path+':'+doc.get('createdAt').toMillis(),ownerUid:owner.id,childUid:doc.id,before:null,after:doc.data()});
  if(name==='completions')return events.completed({ownerUid:owner.id,completionId:doc.id,before:null,after:doc.data()});
  const data=doc.data();return events.scheduleChanged({eventId:doc.ref.path,ownerUid:owner.id,actorUid:data.actorUid,taskId:data.taskId,before:data.action==='created'?null:{change:'before'},after:{change:'after'}});
 }
 function watchStream(name,run){
  if(stopped||run!==generation)return;
  const field=STREAMS[name],state=checkpoints.get(name);let active=true;
  let query=db.collectionGroup(name).orderBy(field).orderBy('__name__').limit(100);
  query=state.path?query.startAfter(state.since,db.doc(state.path)):query.where(field,'>=',state.since);
  const retry=error=>{if(!active||stopped||run!==generation)return;active=false;detach(name);failure(error,name);later(name,delay(error),()=>watchStream(name,run));};
  try{subscriptions.set(name,query.onSnapshot(snapshot=>{
   if(!active||stopped||run!==generation||!snapshot.docs.length)return;
   // Freeze this page before processing. Re-open at the durable cursor only
   // after success, so limit(100) cannot hide later events or replay old pages.
   active=false;detach(name);
   void(async()=>{
    try{for(const doc of snapshot.docs){if(stopped||run!==generation)return;await handle(name,doc);if(stopped||run!==generation)return;const cursor={since:doc.get(field),path:doc.ref.path};await db.doc(`serverRuntime/${name}`).update(cursor);checkpoints.set(name,cursor);}
     lastSuccess=now();lastError=null;watchStream(name,run);
    }catch(error){if(stopped||run!==generation)return;failure(error,name);later(name,delay(error),()=>watchStream(name,run));}
   })();
  },retry));}catch(error){retry(error);}
 }
 function scheduleCampaign(id,entry,run){
  if(stopped||run!==generation||campaigns.get(id)!==entry)return;
  const due=Math.max(entry.data.scheduledAt?.toMillis()||0,entry.data.leaseUntil?.toMillis()||0,entry.retryAt||0);
  later('campaign:'+id,due-now(),()=>{
   if(campaigns.get(id)!==entry)return;
   if(due>now()){scheduleCampaign(id,entry,run);return;}
   if(entry.running){entry.changed=true;return;}
   entry.running=true;
   void admin.dispatchCampaign(id).then(()=>{entry.retryAt=0;lastSuccess=now();lastError=null;}).catch(error=>{
    if(stopped||run!==generation)return;failure(error,'campaign');entry.retryAt=now()+delay(error);
   }).finally(()=>{
    entry.running=false;if(stopped||run!==generation||campaigns.get(id)!==entry)return;
    if(entry.retryAt||entry.changed){entry.changed=false;scheduleCampaign(id,entry,run);}
   });
  });
 }
 function watchCampaigns(run){
  if(stopped||run!==generation)return;
  let active=true;
  const retry=error=>{if(!active||stopped||run!==generation)return;active=false;detach('campaigns');for(const id of campaigns.keys())cancel('campaign:'+id);campaigns.clear();failure(error,'campaigns');later('campaigns',delay(error),()=>watchCampaigns(run));};
  try{subscriptions.set('campaigns',db.collection('adminCampaigns').where('status','in',['queued','sending']).onSnapshot(snapshot=>{
   if(!active||stopped||run!==generation)return;
   for(const change of snapshot.docChanges()){
    const id=change.doc.id;if(change.type==='removed'){cancel('campaign:'+id);campaigns.delete(id);continue;}
    const entry=campaigns.get(id)||{running:false,changed:false};entry.data=change.doc.data();campaigns.set(id,entry);scheduleCampaign(id,entry,run);
   }
  },retry));}catch(error){retry(error);}
 }
 async function initialize(run){
  initializing=true;try{
   // All cutoffs exist before campaigns can create their first notifications.
   const cutoff=Timestamp.fromMillis(now());
   for(const name of Object.keys(STREAMS)){
    const ref=db.doc(`serverRuntime/${name}`),state=await db.runTransaction(async tx=>{const doc=await tx.get(ref);if(doc.exists)return doc.data();const value={since:cutoff,path:null};tx.create(ref,value);return value;},{maxAttempts:1});
    if(stopped||run!==generation)return;checkpoints.set(name,state);
   }
   for(const name of Object.keys(STREAMS))watchStream(name,run);watchCampaigns(run);log.info?.('Realtime worker listeners attached',{listeners:subscriptions.size});
  }catch(error){if(stopped||run!==generation)return;failure(error,'initialize');later('initialize',delay(error),()=>{void initialize(run);});}finally{if(run===generation)initializing=false;}
 }
 function start(){if(!stopped)return starting;stopped=false;const run=++generation;starting=initialize(run);return starting;}
 function stop(){stopped=true;generation++;for(const key of [...subscriptions.keys()])detach(key);for(const key of [...timers.keys()])cancel(key);campaigns.clear();}
 return {start,stop,status:()=>({mode:'realtime',initializing,lastSuccess,lastError,listeners:subscriptions.size,retryTimers:timers.size,stopped})};
}
module.exports={createRealWorker};
