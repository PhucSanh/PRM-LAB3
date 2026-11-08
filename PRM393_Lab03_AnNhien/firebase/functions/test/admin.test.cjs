'use strict';
const {test,before,after,beforeEach}=require('node:test');
const assert=require('node:assert/strict');
const {initializeApp,deleteApp}=require('firebase-admin/app');
const {getFirestore,Timestamp}=require('firebase-admin/firestore');
const {createAdminService,requireAdmin,matchesSegment,dateKey,periodBuckets}=require('../admin.cjs');
const DAY=86400000,admin={uid:'admin-user',token:{admin:true}};
let app,db,service,time;
before(()=>{assert.ok(process.env.FIRESTORE_EMULATOR_HOST,'Run through Firebase emulator');app=initializeApp({projectId:'demo-admin-tests'},'admin-tests');db=getFirestore(app);});
after(async()=>{if(app)await deleteApp(app);});
beforeEach(async()=>{for(const c of ['users','adminPresence','adminDaily','adminCampaigns','adminCampaignRate'])await db.recursiveDelete(db.collection(c));time=Date.parse('2026-11-08T10:00:00+07:00');service=createAdminService(db,{now:()=>time});});
async function user(id,role='elder',created=time){await db.doc(`users/${id}`).set({role,displayName:id,createdAt:Timestamp.fromMillis(created)});}
test('admin endpoints reject missing auth and forged client roles',async()=>{
 assert.throws(()=>requireAdmin(null),e=>e.code==='unauthenticated');
 assert.throws(()=>requireAdmin({uid:'u',token:{admin:'true'}}),e=>e.code==='permission-denied');
 for(const auth of [null,{uid:'u',token:{}}]){await assert.rejects(service.dashboard(auth),e=>['unauthenticated','permission-denied'].includes(e.code));await assert.rejects(service.createCampaign(auth,{}));await assert.rejects(service.cancelCampaign(auth,{id:'anything'}));}
});
test('timezone midnight and nonoverlapping period ranges',()=>{
 assert.equal(dateKey(Date.parse('2026-11-07T18:00:00Z')),'2026-11-08');
 for(const period of ['hour','day','week','month','quarter']){const b=periodBuckets(period,time);assert.equal(b.end-b.start,b.step*b.n);}
 assert.throws(()=>periodBuckets('bad',time));
});
test('heartbeat is transactionally deduplicated and distinguishes first, returning users and sessions',async()=>{
 await user('elder');const auth={uid:'elder'};
 await Promise.all([service.recordActivity(auth),service.recordActivity(auth)]);
 let d=(await db.doc('adminDaily/2026-11-08').get()).data();assert.equal(d.activeUsers,1);assert.equal(d.firstSeenUsers,1);assert.equal(d.sessions,1);
 time+=31*60000;await service.recordActivity(auth);d=(await db.doc('adminDaily/2026-11-08').get()).data();assert.equal(d.activeUsers,1);assert.equal(d.sessions,2);
 time+=DAY;await service.recordActivity(auth);d=(await db.doc('adminDaily/2026-11-09').get()).data();assert.equal(d.returningUsers,1);assert.equal(d.activeUsers,1);assert.equal(d.firstSeenUsers,undefined);
 await assert.rejects(service.recordActivity(null),e=>e.code==='unauthenticated');await assert.rejects(service.recordActivity({uid:'missing'}),e=>e.code==='failed-precondition');
});
test('unknown activity is excluded from inactive segment; role and signup filtering use actual schema',()=>{
 const profile={role:'elder',createdAt:Timestamp.fromMillis(time-2*DAY)};
 assert.equal(matchesSegment(profile,null,'inactive',time),false);
 assert.equal(matchesSegment(profile,{lastSeen:Timestamp.fromMillis(time-8*DAY)},'inactive',time),true);
 assert.equal(matchesSegment(profile,null,'parents',time),true);assert.equal(matchesSegment(profile,null,'children',time),false);assert.equal(matchesSegment(profile,null,'new',time),true);
});
test('dashboard returns actual totals, completions, unique active users and growth',async()=>{
 await user('mom');await user('child','caregiver',time-10*DAY);await user('unset',null);
 await db.doc('users/mom/tasks/task').set({title:'walk'});await db.doc('users/mom/completions/task_2026-11-08').set({date:'2026-11-08',status:'done'});await db.doc('users/mom/caregivers/child').set({});
 await service.recordActivity({uid:'mom'});const d=await service.dashboard(admin,{period:'week'});
 assert.equal(d.metrics.totalUsers,3);assert.equal(d.metrics.parents,1);assert.equal(d.metrics.children,1);assert.equal(d.metrics.unassigned,1);assert.equal(d.metrics.dau,1);assert.equal(d.metrics.tasks,1);assert.equal(d.metrics.doneToday,1);assert.equal(d.metrics.familyLinks,1);assert.equal(d.metrics.downloads,null);assert.equal(d.growth.total,2);assert.equal(d.growth.previous.reduce((a,b)=>a+b,0),1);assert.equal(d.users.length,3);assert.equal(d.segments.inactive,0);
});
const campaign=(patch={})=>({title:'Chào buổi sáng',body:'Cùng vận động nhé!',segment:'parents',requestId:'test-request-00001',...patch});
test('campaign validates length, segment, request id, schedule and rate limit',async()=>{
 for(const patch of [{title:''},{body:'a'.repeat(241)},{segment:'admins'},{requestId:'bad/path'},{scheduledAt:time-DAY},{scheduledAt:time+91*DAY}])await assert.rejects(service.createCampaign(admin,campaign(patch)),e=>e.code==='invalid-argument');
 const first=await service.createCampaign(admin,campaign());const again=await service.createCampaign(admin,campaign());assert.equal(first.id,again.id);assert.equal((await db.collection('adminCampaigns').get()).size,1);
 await assert.rejects(service.createCampaign(admin,campaign({requestId:'test-request-00002'})),e=>e.code==='resource-exhausted');
});
test('worker targets role, persists real inbox content and is retry safe',async()=>{
 await user('mom');await user('child','caregiver');const {id}=await service.createCampaign(admin,campaign());
 await Promise.all([service.dispatchCampaign(id),service.dispatchCampaign(id)]);await service.dispatchCampaign(id);
 const inbox=await db.collection('users/mom/notifications').get();assert.equal(inbox.size,1);assert.equal(inbox.docs[0].data().body,'Cùng vận động nhé!');assert.equal(inbox.docs[0].data().event,'admin_campaign');assert.equal((await db.collection('users/child/notifications').get()).size,0);
 const c=(await db.doc(`adminCampaigns/${id}`).get()).data();assert.equal(c.status,'enqueued');assert.equal(c.enqueuedUsers,1);
 await assert.rejects(service.cancelCampaign(admin,{id}),e=>e.code==='failed-precondition');
});
test('scheduled campaign does not dispatch early and cancellation prevents delivery',async()=>{
 await user('mom');let {id}=await service.createCampaign(admin,campaign({scheduledAt:time+DAY}));await service.dispatchCampaign(id);assert.equal((await db.doc(`adminCampaigns/${id}`).get()).data().status,'queued');
 await service.cancelCampaign(admin,{id});time+=2*DAY;await service.dispatchCampaign(id);assert.equal((await db.collection('users/mom/notifications').get()).size,0);
 const next=await service.createCampaign(admin,campaign({requestId:'scheduled-request-0002',scheduledAt:time+DAY}));time+=DAY;await service.processQueue();assert.equal((await db.doc(`adminCampaigns/${next.id}`).get()).data().status,'enqueued');
});
test('campaign cursor processes batches without duplicate deliveries',async()=>{
 const batch=db.batch();for(let i=0;i<151;i++)batch.set(db.doc(`users/person-${String(i).padStart(3,'0')}`),{role:'elder'});await batch.commit();const {id}=await service.createCampaign(admin,campaign());await service.dispatchCampaign(id);let c=(await db.doc(`adminCampaigns/${id}`).get()).data();assert.equal(c.status,'sending');assert.equal(c.enqueuedUsers,150);await service.processQueue();c=(await db.doc(`adminCampaigns/${id}`).get()).data();assert.equal(c.status,'enqueued');assert.equal(c.enqueuedUsers,151);
});
test('heartbeat just after UTC+7 midnight counts the new day despite 30 minute throttle',async()=>{
 await user('mom');time=Date.parse('2026-11-08T23:55:00+07:00');await service.recordActivity({uid:'mom'});time+=10*60000;await service.recordActivity({uid:'mom'});assert.equal((await db.doc('adminDaily/2026-11-09').get()).data().activeUsers,1);
});
test('seed login accepts only server secret, issues dedicated admin token and throttles attempts',async()=>{
 const {createAdminLogin}=require('../admin-login.cjs');let issued;
 const login=createAdminLogin(db,{createCustomToken:async(uid,claims)=>{issued={uid,claims};return 'test-token';}},{getPassword:()=> 'fixture-password',now:()=>time});
 const request=(password)=>({data:{username:'admin',password},rawRequest:{ip:'192.0.2.1'}});
 await assert.rejects(login(request('wrong')),e=>e.code==='unauthenticated');
 assert.deepEqual(await login(request('fixture-password')),{token:'test-token'});assert.deepEqual(issued,{uid:'an-nhien-admin',claims:{admin:true}});
 for(let i=0;i<3;i++)await assert.rejects(login(request('wrong')),e=>e.code==='unauthenticated');
 await assert.rejects(login(request('fixture-password')),e=>e.code==='resource-exhausted');
 time+=16*60000;assert.equal((await login(request('fixture-password'))).token,'test-token');
});
