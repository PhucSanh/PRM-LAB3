'use strict';
const {initializeApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');
const {defineSecret,defineString} = require('firebase-functions/params');
const {createVoiceTaskService} = require('./voice-task.cjs');
const {onCall,HttpsError} = require('firebase-functions/v2/https');
const {onDocumentCreated,onDocumentWritten,onDocumentWrittenWithAuthContext} = require('firebase-functions/v2/firestore');
const {createNotificationEvents} = require('./notification-events.cjs');
const {sendInboxPush} = require('./push-delivery.cjs');
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
const notifications = createNotificationEvents(db);
exports.notifyScheduleChanged = onDocumentWrittenWithAuthContext({...options,
  document:'users/{uid}/tasks/{taskId}',retry:true}, event => notifications.scheduleChanged({
    eventId:event.id, ownerUid:event.params.uid, actorUid:event.authId, taskId:event.params.taskId,
    before:event.data?.before.data(), after:event.data?.after.data(),
  }));
exports.notifyTaskCompleted = onDocumentWritten({...options,
  document:'users/{uid}/completions/{id}',retry:true}, event => notifications.completed({
    ownerUid:event.params.uid, completionId:event.params.id,
    before:event.data?.before.data(), after:event.data?.after.data(),
  }));
exports.notifyPairingChanged = onDocumentWritten({...options,
  document:'users/{uid}/caregivers/{childUid}',retry:true}, event => notifications.pairingChanged({
    eventId:event.id, ownerUid:event.params.uid, childUid:event.params.childUid,
    before:event.data?.before.data(), after:event.data?.after.data(),
  }));
// Inbox is already persisted by the transaction before this trigger sends push.
// Delivery is at least once. Stable notification id lets the client deduplicate.
exports.notifyInbox=onDocumentCreated({...options,document:'users/{uid}/notifications/{id}',retry:true},event=>
  sendInboxPush(db,getMessaging(),{uid:event.params.uid,id:event.params.id,data:event.data?.data()}));

// Secret is bound to this endpoint only; never returned to Flutter or logged.
const groqKey = defineSecret('GROQ_API_KEY');
const groqModel = defineString('GROQ_VOICE_MODEL',{default:'openai/gpt-oss-20b'});
const interpretVoiceTask = createVoiceTaskService(db,{getKey:()=>groqKey.value(),getModel:()=>groqModel.value()});
exports.interpretVoiceTask = onCall({...options,secrets:[groqKey],timeoutSeconds:30,concurrency:8},async request=>{
  try { return await interpretVoiceTask(request.auth?.uid,request.data); }
  catch(e) {
    if(e instanceof DomainError) throw new HttpsError(e.code,e.message);
    throw new HttpsError('internal','Chưa hiểu được lời nói lúc này. Bác thử lại hoặc nhập tay nhé.');
  }
});
