'use strict';
// Explicitly local fixtures. Refuse to write production data.
const path=require('node:path');
const requireBackend=require('node:module').createRequire(path.join(__dirname,'../firebase/functions/package.json'));
const {initializeApp}=requireBackend('firebase-admin/app');
const {getFirestore,Timestamp}=requireBackend('firebase-admin/firestore');
if(!process.env.FIRESTORE_EMULATOR_HOST || process.env.GCLOUD_PROJECT!=='demo-an-nhien')throw new Error('Only FIRESTORE_EMULATOR_HOST + GCLOUD_PROJECT=demo-an-nhien are supported.');
initializeApp({projectId:'demo-an-nhien'});const db=getFirestore();
(async()=>{
 const now=Date.now(),day=86400000,batch=db.batch();
 for(let i=0;i<30;i++){
  const uid=`seed-${String(i).padStart(3,'0')}`,role=i%3===0?'caregiver':'elder';
  batch.set(db.doc(`users/${uid}`),{displayName:`Thành viên thử nghiệm ${i+1}`,role,createdAt:Timestamp.fromMillis(now-i*day/3),...(role==='caregiver'?{pairedMomUid:'seed-001'}:{})});
  batch.set(db.doc(`adminPresence/${uid}`),{firstSeen:Timestamp.fromMillis(now-15*day),lastSeen:Timestamp.fromMillis(now-i*day/6)});
  batch.set(db.doc(`users/${uid}/tasks/walk`),{title:'Đi bộ',habitKey:'move',status:'pending'});
  if(role==='caregiver')batch.set(db.doc(`users/seed-001/caregivers/${uid}`),{createdAt:Timestamp.fromMillis(now)});
 }
 await batch.commit();console.log('Seeded 30 emulator-only profiles, activity, tasks and family links. Login admin uses ADMIN_LOGIN_PASSWORD from .secret.local.');
})().catch(error=>{console.error(error.message);process.exitCode=1;});
