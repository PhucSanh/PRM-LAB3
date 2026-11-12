'use strict';
const {test,before,after} = require('node:test');
const assert = require('node:assert/strict');
const {initializeApp,deleteApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {createDomain,validateTask} = require('../domain.cjs');
let app,db;
before(()=>{
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST,'Run via Firebase Emulator: npm test --prefix firebase/tests');
  app=initializeApp({projectId:'demo-an-nhien'},'backend-tests');db=getFirestore(app);
});
after(async()=>{if(app)await deleteApp(app);});
let sequence=0;
async function setup(){
  const suffix=`${Date.now()}-${sequence++}`;const mom=`b-mom-${suffix}`,child=`b-child-${suffix}`;
  await db.doc(`users/${mom}`).set({role:'elder'});await db.doc(`users/${child}`).set({role:'caregiver'});
  let time=Date.UTC(2026,10,4);let code=100000+sequence*100;
  const domain=createDomain(db,{now:()=>time,generateCode:()=>String(code++)});
  return {mom,child,domain,advance:ms=>time+=ms};
}
const task={schemaVersion:2,revision:0,title:'Đi bộ',habitKey:'move',hour:8,minute:0,repeat:'weekly',status:'pending',remind:true,
  startDate:'2026-11-04',endDate:null,weekdays:[1,3,5],monthDays:[],lastDayOfMonth:false,excludedDates:[],durationMinutes:15,timezone:'Asia/Ho_Chi_Minh'};
test('backend validates actual calendar and recurrence, not only date format',()=>{
  assert.doesNotThrow(()=>validateTask(task));
  for(const patch of [{startDate:'2026-02-31'},{weekdays:[]},{hour:24},{durationMinutes:0},{revision:-1},{admin:true}]) {
    assert.throws(()=>validateTask({...task,...patch}),e=>e.code==='invalid-argument');
  }
});
test('pairing: role, wrong code, 10-minute expiry, new code invalidates old, single-use',async()=>{
  const {mom,child,domain,advance}=await setup();
  await assert.rejects(domain.createPairing(child),e=>e.code==='permission-denied');
  await assert.rejects(domain.createPairing(null),e=>e.code==='unauthenticated');
  const first=await domain.createPairing(mom);
  advance(600000);await assert.rejects(domain.redeemPairing(child,first.code),e=>e.code==='not-found');
  const second=await domain.createPairing(mom);advance(31000);const third=await domain.createPairing(mom);
  await assert.rejects(domain.redeemPairing(child,second.code),e=>e.code==='not-found');
  assert.deepEqual(await domain.redeemPairing(child,third.code),{momUid:mom});
  assert.equal((await db.doc(`users/${child}`).get()).data().pairedMomUid,mom);
  assert.equal((await db.doc(`users/${mom}/caregivers/${child}`).get()).exists,true);
  await assert.rejects(domain.redeemPairing(child,third.code),e=>e.code==='not-found');
});
test('invalid pairing attempts commit and sixth attempt is rate-limited',async()=>{
  const {child,domain,advance}=await setup();
  for(let i=0;i<5;i++)await assert.rejects(domain.redeemPairing(child,'999999'),e=>e.code==='not-found');
  assert.equal((await db.doc(`pairingAttempts/${child}`).get()).data().count,5);
  await assert.rejects(domain.redeemPairing(child,'999999'),e=>e.code==='resource-exhausted');
  advance(600001);await assert.rejects(domain.redeemPairing(child,'999999'),e=>e.code==='not-found');
  assert.equal((await db.doc(`pairingAttempts/${child}`).get()).data().count,1);
});
test('only one child can consume the same code concurrently',async()=>{
  const {mom,child,domain}=await setup();const other=child+'-other';await db.doc(`users/${other}`).set({role:'caregiver'});
  const {code}=await domain.createPairing(mom);
  const results=await Promise.allSettled([domain.redeemPairing(child,code),domain.redeemPairing(other,code)]);
  assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
  assert.equal((await db.collection(`users/${mom}/caregivers`).get()).size,1);
});
test('re-pair removes old grant; owner or child can revoke; stranger cannot',async()=>{
  const a=await setup(),b=await setup();const {domain,child,mom}=a;
  await domain.redeemPairing(child,(await domain.createPairing(mom)).code);
  await domain.redeemPairing(child,(await b.domain.createPairing(b.mom)).code);
  assert.equal((await db.doc(`users/${mom}/caregivers/${child}`).get()).exists,false);
  await assert.rejects(domain.revokePairing('stranger',b.mom,child),e=>e.code==='permission-denied');
  await domain.revokePairing(b.mom,b.mom,child);
  assert.equal((await db.doc(`users/${b.mom}/caregivers/${child}`).get()).exists,false);
  assert.equal((await db.doc(`users/${child}`).get()).data().pairedMomUid,undefined);
});
test('suggestion send retries persist one inbox; partial acceptance atomic and idempotent',async()=>{
  const {domain,mom,child}=await setup();
  await domain.redeemPairing(child,(await domain.createPairing(mom)).code);
  const send={momUid:mom,id:'req',tasks:[task,{...task,title:'Uống trà',hour:15}]};
  await domain.sendSuggestion(child,send);await domain.sendSuggestion(child,send);
  await assert.rejects(domain.sendSuggestion(child,{...send,message:'Different payload'}),e=>e.code==='already-exists');
  assert.equal((await db.collection(`users/${mom}/notifications`).get()).size,1);
  await assert.rejects(domain.resolveSuggestion(mom,{id:'req',selected:[2]}),e=>e.code==='invalid-argument');
  assert.equal((await db.collection(`users/${mom}/tasks`).get()).size,0);
  await domain.resolveSuggestion(mom,{id:'req',selected:[1],times:{1:{hour:16,minute:30}}});
  const tasks=await db.collection(`users/${mom}/tasks`).get();assert.equal(tasks.size,1);assert.equal(tasks.docs[0].data().hour,16);
  assert.equal((await db.doc(`users/${mom}/suggestions/req`).get()).data().status,'partial');
  const notices=db.collection(`users/${child}/notifications`);
  assert.equal((await notices.where('event','==','suggestion_partial').get()).size,1);
  await assert.rejects(domain.resolveSuggestion(mom,{id:'req',selected:[1]}),e=>e.code==='failed-precondition');
  assert.equal((await db.collection(`users/${mom}/tasks`).get()).size,1);
  await domain.resolveSuggestion(mom,{id:'req',selected:[0]});
  assert.equal((await notices.where('event','==','suggestion_accepted').get()).size,1);
  assert.equal((await notices.get()).size,2);
});
test('dismiss notifies the sender once without creating tasks; undo returns pending',async()=>{
  const {domain,mom,child}=await setup();await domain.redeemPairing(child,(await domain.createPairing(mom)).code);
  await domain.sendSuggestion(child,{momUid:mom,id:'dismiss',tasks:[task]});
  await domain.resolveSuggestion(mom,{id:'dismiss',selected:[]});
  assert.equal((await db.collection(`users/${mom}/tasks`).get()).size,0);
  await assert.rejects(domain.resolveSuggestion(mom,{id:'dismiss',selected:[]}),e=>e.code==='failed-precondition');
  const notices=await db.collection(`users/${child}/notifications`).get();
  assert.equal(notices.size,1);
  assert.equal(notices.docs[0].data().event,'suggestion_dismissed');
  await domain.undoDismiss(mom,{id:'dismiss'});assert.equal((await db.doc(`users/${mom}/suggestions/dismiss`).get()).data().status,'pending');
  await assert.rejects(domain.undoDismiss(child,{id:'dismiss'}),e=>e.code==='failed-precondition');
  await domain.revokePairing(mom,mom,child);
  await assert.rejects(domain.sendSuggestion(child,{momUid:mom,id:'no-grant',tasks:[task]}),e=>e.code==='permission-denied');
});

const {createNotificationEvents,eventKey}=require('../notification-events.cjs');
test('schedule push requires current grant and a different authenticated actor; retries preserve readAt',async()=>{
  const {domain,mom,child}=await setup();const events=createNotificationEvents(db);
  const input={eventId:'schedule-'+mom,ownerUid:mom,actorUid:child,taskId:'walk',after:task};
  await events.scheduleChanged(input);
  assert.equal((await db.collection(`users/${mom}/notifications`).get()).size,0);
  await domain.redeemPairing(child,(await domain.createPairing(mom)).code);
  await events.scheduleChanged({...input,actorUid:mom});
  await events.scheduleChanged({...input,actorUid:undefined});
  assert.equal((await db.collection(`users/${mom}/notifications`).get()).size,0);
  await events.scheduleChanged(input);await events.scheduleChanged(input);
  const id=eventKey('schedule',input.eventId),ref=db.doc(`users/${mom}/notifications/${id}`);
  assert.equal((await ref.get()).data().route,'/today');
  assert.equal((await ref.get()).data().kind,'family');
  await ref.update({readAt:'preserved'});await events.scheduleChanged(input);
  assert.equal((await ref.get()).data().readAt,'preserved');
  await events.scheduleChanged({...input,eventId:'revision-only',before:task,after:{...task,revision:1}});
  assert.equal((await db.collection(`users/${mom}/notifications`).get()).size,1);
});
test('completion notifies only linked child, once per occurrence; undo, skip, revoke do not notify',async()=>{
  const {domain,mom,child}=await setup();const events=createNotificationEvents(db);
  await domain.redeemPairing(child,(await domain.createPairing(mom)).code);
  const completionId='walk_2026-11-04';
  const after={taskId:'walk',date:'2026-11-04',status:'done'};
  await db.doc(`users/${mom}/completions/${completionId}`).set(after);
  await events.completed({ownerUid:mom,completionId,after});
  await events.completed({ownerUid:mom,completionId,after});
  let list=await db.collection(`users/${child}/notifications`).get();assert.equal(list.size,1);
  assert.equal(list.docs[0].data().route,'/caregiver/schedule?date=2026-11-04');
  await events.completed({ownerUid:mom,completionId,after:{...after,status:'skipped'}});
  await events.completed({ownerUid:mom,completionId,after:{...after,status:'pending'}});
  await domain.revokePairing(mom,mom,child);
  const later={...after,date:'2026-11-05'};
  await db.doc(`users/${mom}/completions/walk_2026-11-05`).set(later);
  await events.completed({ownerUid:mom,completionId:'walk_2026-11-05',after:later});
  list=await db.collection(`users/${child}/notifications`).get();assert.equal(list.size,1);
});
test('pairing lifecycle creates two system inbox entries atomically and idempotently',async()=>{
  const {mom,child}=await setup();const events=createNotificationEvents(db);
  const event={eventId:'pair-'+mom,ownerUid:mom,childUid:child,after:{displayName:'Con'}};
  await Promise.all([events.pairingChanged(event),events.pairingChanged(event)]);
  for(const uid of [mom,child]) {
    const list=await db.collection(`users/${uid}/notifications`).get();assert.equal(list.size,1);
    assert.equal(list.docs[0].data().kind,'system');assert.equal(list.docs[0].data().event,'pairing_linked');
  }
  await events.pairingChanged({...event,eventId:'unlink-'+mom,before:event.after,after:undefined});
  assert.equal((await db.collection(`users/${mom}/notifications`).get()).size,2);
});

test('partial can dismiss, undo and accept remaining without duplicating accepted tasks',async()=>{
  const {domain,mom,child}=await setup();
  await domain.redeemPairing(child,(await domain.createPairing(mom)).code);
  await domain.sendSuggestion(child,{momUid:mom,id:'resume',tasks:[task,{...task,title:'Trà',hour:15}]});
  await domain.resolveSuggestion(mom,{id:'resume',selected:[0]});
  await domain.resolveSuggestion(mom,{id:'resume',selected:[]});
  await domain.undoDismiss(mom,{id:'resume'});
  assert.equal((await db.doc(`users/${mom}/suggestions/resume`).get()).data().status,'partial');
  await domain.resolveSuggestion(mom,{id:'resume',selected:[1],times:{1:{hour:16,minute:30}}});
  const s=(await db.doc(`users/${mom}/suggestions/resume`).get()).data();
  assert.equal(s.status,'accepted');assert.equal(s.acceptedIds.length,2);
  assert.equal((await db.collection(`users/${mom}/tasks`).get()).size,2);
  await assert.rejects(domain.resolveSuggestion(mom,{id:'resume',selected:[0]}),e=>e.code==='failed-precondition');
});
