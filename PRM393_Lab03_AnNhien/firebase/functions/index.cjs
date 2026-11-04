'use strict';
const {initializeApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');
const {onCall,HttpsError} = require('firebase-functions/v2/https');
const {onDocumentCreated} = require('firebase-functions/v2/firestore');
const {createDomain,DomainError} = require('./domain.cjs');
initializeApp();
const db=getFirestore(); const domain=createDomain(db);
const options={region:'asia-southeast1',maxInstances:3};
function callable(fn) {return onCall(options,async request=>{
  try { return await fn(request.auth?.uid,request.data||{}); }
  catch(e) {if(e instanceof DomainError) throw new HttpsError(e.code,e.message); throw new HttpsError('internal','Chưa thực hiện được. Vui lòng thử lại.');}
});}
exports.createPairing=callable(uid=>domain.createPairing(uid));
exports.redeemPairing=callable((uid,d)=>domain.redeemPairing(uid,d.code));
exports.revokePairing=callable((uid,d)=>domain.revokePairing(uid,d.momUid,d.childUid));
exports.sendSuggestion=callable((uid,d)=>domain.sendSuggestion(uid,d));
exports.resolveSuggestion=callable((uid,d)=>domain.resolveSuggestion(uid,d));
exports.undoDismiss=callable((uid,d)=>domain.undoDismiss(uid,d));
// Inbox is already persisted by the transaction before this trigger sends push.
// Delivery is at least once. Stable notification id lets the client deduplicate.
exports.notifyInbox=onDocumentCreated({...options,document:'users/{uid}/notifications/{id}',retry:true},async event=>{
  const data=event.data?.data(); if(!data) return;
  const devices=await db.collection(`users/${event.params.uid}/devices`).get();
  const fresh=devices.docs.filter(d=>d.data().updatedAt?.toMillis()>Date.now()-30*86400000);
  for(let offset=0;offset<fresh.length;offset+=500) {
    const chunk=fresh.slice(offset,offset+500);
    const result=await getMessaging().sendEachForMulticast({tokens:chunk.map(d=>d.data().token),
      notification:{title:'An Nhiên',body:'Bác có thông báo mới.'},
      data:{notification_id:event.params.id,recipient_uid:event.params.uid,route:data.route||'/inbox'},
      android:{collapseKey:event.params.id}});
    await Promise.all(result.responses.map((r,i)=>r.error?.code==='messaging/registration-token-not-registered'?chunk[i].ref.delete():null));
    if(result.responses.some(r=>r.error && ['messaging/internal-error','messaging/server-unavailable'].includes(r.error.code))) {
      throw new Error('Transient FCM error');
    }
  }
});
