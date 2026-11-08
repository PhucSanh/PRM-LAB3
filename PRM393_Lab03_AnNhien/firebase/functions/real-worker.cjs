'use strict';
const {createHash,randomUUID}=require('node:crypto');
const {Timestamp}=require('firebase-admin/firestore');
const {createNotificationEvents}=require('./notification-events.cjs');
const {sendInboxPush}=require('./push-delivery.cjs');
function createRealWorker(db,messaging,admin,{now=Date.now,log=console}={}){
 const notifications=createNotificationEvents(db);let busy=false,lastSuccess=null,lastError=null;let initialized=false;let userCache=[],usersCachedAt=0;const perUserCursor=new Map();
 // Persistent cursor: restarts catch up from the last successful page. First
 // activation starts at now, so historical inboxes aren't broadcast unexpectedly.
 async function poll(name,field,handle){
  const checkpoint=db.doc(`serverRuntime/${name}`);
  await db.runTransaction(async tx=>{const doc=await tx.get(checkpoint);if(!doc.exists)tx.create(checkpoint,{since:Timestamp.fromMillis(now()),path:null});});
  const state=(await checkpoint.get()).data();let q=db.collectionGroup(name).orderBy(field).orderBy('__name__').limit(100);
  q=state.path?q.startAfter(state.since,db.doc(state.path)):q.where(field,'>=',state.since);
  let docs;try{docs=await q.get();}catch(error){
   if(error.code!==9)throw error;
   // Single-collection indexes are available immediately. Temporary fallback
   // while new collection-group indexes build; idempotent handlers allow the
   // group cursor to catch up safely once its index becomes ready.
   if(!usersCachedAt||now()-usersCachedAt>60000){const users=await db.collection('users').limit(10001).get();if(users.size>10000)throw new Error('Worker requires aggregate routing above 10000 users');userCache=users.docs;usersCachedAt=now();}
   for(const user of userCache){
    const key=name+'-'+createHash('sha256').update(user.id).digest('hex'),ref=db.doc(`serverRuntime/${key}`);
    let cursor=perUserCursor.get(key);if(!cursor){const saved=await ref.get();cursor=saved.exists?saved.data():{since:state.since,path:null};if(!saved.exists)await ref.set(cursor);perUserCursor.set(key,cursor);}
    let query=db.collection(`users/${user.id}/${name}`).orderBy(field).orderBy('__name__').limit(100);
    query=cursor.path?query.startAfter(cursor.since,db.doc(cursor.path)):query.where(field,'>=',cursor.since);
    const page=await query.get();for(const item of page.docs){await handle(item);cursor={since:item.get(field),path:item.ref.path};await ref.set(cursor);perUserCursor.set(key,cursor);}
   }return;
  }for(const doc of docs.docs){await handle(doc);await checkpoint.update({since:doc.get(field),path:doc.ref.path});}
 }
 async function push(doc){
  const uid=doc.ref.parent.parent?.id;if(!uid||doc.ref.parent.parent.parent.id!=='users')return;
  const receipt=db.doc(`serverPushReceipts/${createHash('sha256').update(doc.ref.path).digest('hex')}`),lease=randomUUID();
  const acquired=await db.runTransaction(async tx=>{const existing=(await tx.get(receipt)).data();if(existing?.status==='sent'||existing?.leaseUntil?.toMillis()>now())return false;tx.set(receipt,{status:'sending',lease,leaseUntil:Timestamp.fromMillis(now()+120000)});return true;});
  if(!acquired){const current=(await receipt.get()).data();if(current?.status==='sent')return;throw new Error('Push is leased by another worker.');}
  try{await sendInboxPush(db,messaging,{uid,id:doc.id,data:doc.data()},now());await receipt.update({status:'sent',finishedAt:Timestamp.fromMillis(now())});}
  catch(error){await receipt.update({status:'retry',leaseUntil:Timestamp.fromMillis(0)});throw error;}
 }
 async function tick(){
  if(busy)return;busy=true;
  try{
   if(!initialized){const cutoff=Timestamp.fromMillis(now());for(const name of ['caregivers','completions','scheduleEvents','notifications'])await db.runTransaction(async tx=>{const ref=db.doc(`serverRuntime/${name}`);if(!(await tx.get(ref)).exists)tx.create(ref,{since:cutoff,path:null});});initialized=true;}
   await admin.processQueue();
   await poll('caregivers','createdAt',async doc=>{const parent=doc.ref.parent.parent;if(parent?.parent.id!=='users')return;await notifications.pairingChanged({eventId:doc.ref.path+':'+doc.get('createdAt').toMillis(),ownerUid:parent.id,childUid:doc.id,before:null,after:doc.data()});});
   await poll('completions','updatedAt',async doc=>{const parent=doc.ref.parent.parent;if(parent?.parent.id!=='users')return;await notifications.completed({ownerUid:parent.id,completionId:doc.id,before:null,after:doc.data()});});
   await poll('scheduleEvents','createdAt',async doc=>{const parent=doc.ref.parent.parent;if(parent?.parent.id!=='users')return;const d=doc.data();await notifications.scheduleChanged({eventId:doc.ref.path,ownerUid:parent.id,actorUid:d.actorUid,taskId:d.taskId,before:d.action==='created'?null:{change:'before'},after:{change:'after'}});});
   await poll('notifications','receivedAt',push);lastSuccess=now();lastError=null;
  }catch(error){lastError=error.code||'worker-error';log.error('Real worker retry pending',{code:lastError});}
  finally{busy=false;}
 }
 return {tick,status:()=>({lastSuccess,lastError,busy})};
}
module.exports={createRealWorker};
