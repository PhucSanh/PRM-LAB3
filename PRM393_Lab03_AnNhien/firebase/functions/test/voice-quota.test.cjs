'use strict';
const {test,before,after} = require('node:test');
const assert = require('node:assert/strict');
const {initializeApp,deleteApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {reserveQuota} = require('../voice-task.cjs');
let app,db;
before(()=>{
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST,'Run via npm test --prefix firebase/tests');
  app=initializeApp({projectId:'demo-an-nhien'},'voice-quota-tests');db=getFirestore(app);
});
after(async()=>{if(app)await deleteApp(app);});
test('voice quota serializes calls, isolates users, resets minute and day counters',async()=>{
  const uid=`voice-${Date.now()}`,now=Date.UTC(2026,10,6,4,30);
  // Small concurrent batches keep emulator transaction retries within SDK limits.
  for(let i=0;i<4;i++) await Promise.all([reserveQuota(db,uid,now),reserveQuota(db,uid,now)]);
  await assert.rejects(reserveQuota(db,uid,now),e=>e.code==='resource-exhausted');
  await reserveQuota(db,uid+'-other',now);
  await reserveQuota(db,uid,now+60000);
  const data=(await db.doc(`voiceUsage/${uid}`).get()).data();
  assert.equal(data.minuteCount,1);assert.equal(data.dayCount,9);
  assert.deepEqual(Object.keys(data).sort(),['day','dayCount','expiresAt','minute','minuteCount']);
  await db.doc(`voiceUsage/${uid}`).update({dayCount:60});
  await assert.rejects(reserveQuota(db,uid,now+120000),e=>e.code==='resource-exhausted');
  await reserveQuota(db,uid,now+86400000);
  assert.equal((await db.doc(`voiceUsage/${uid}`).get()).data().dayCount,1);
});
