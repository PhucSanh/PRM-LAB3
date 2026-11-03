'use strict';
// Refuse to run against production, even if ambient credentials are available.
if(!process.env.FIRESTORE_EMULATOR_HOST)throw new Error('Set FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 first');
const localRequire=require('node:module').createRequire(require('node:path').resolve(__dirname,'../functions/package.json'));
const {initializeApp}=localRequire('firebase-admin/app');
const {getFirestore}=localRequire('firebase-admin/firestore');
const habits=require('../habits.json');
initializeApp({projectId:'demo-an-nhien'});
(async()=>{const db=getFirestore();const batch=db.batch();
  for(const {key,...data} of habits)batch.set(db.doc(`habits/${key}`),data);
  await batch.commit();console.log(`Seeded ${habits.length} habits into local emulator only.`);
})().catch(e=>{console.error(e.message);process.exitCode=1;});
