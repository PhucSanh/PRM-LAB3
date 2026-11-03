import { before, after, beforeEach, test } from 'node:test';
import { readFile } from 'node:fs/promises';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, updateDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { ref, uploadBytes, getBytes, deleteObject } from 'firebase/storage';

let env;
const task = { title: 'Đi bộ', habitKey: 'move', hour: 9, minute: 0, repeat: 'daily', status: 'pending', remind: true };
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-an-nhien',
    firestore: {rules: await readFile(new URL('../firestore.rules', import.meta.url), 'utf8')},
    storage: {rules: await readFile(new URL('../storage.rules', import.meta.url), 'utf8')},
  });
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });
const db = uid => env.authenticatedContext(uid).firestore();
test('private task: owner allowed; stranger and anonymous denied', async () => {
  await assertSucceeds(setDoc(doc(db('mom'), 'users/mom/tasks/a'), task));
  await assertSucceeds(getDoc(doc(db('mom'), 'users/mom/tasks/a')));
  await assertFails(getDoc(doc(db('stranger'), 'users/mom/tasks/a')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'users/mom/tasks/a')));
  await assertFails(setDoc(doc(db('stranger'), 'users/mom/tasks/a'), task));
});
test('task validates every field, enums, types and unknown fields', async () => {
  for (const patch of [{title:''},{title:'x'.repeat(81)},{hour:24},{minute:-1},{minute:60},{minute:1.5},{remind:'yes'},{status:'invalid'},{repeat:'weekly'},{habitKey:'invalid'},{admin:true}]) {
    await assertFails(setDoc(doc(db('mom'), 'users/mom/tasks/a'), {...task,...patch}));
  }
  const { minute, ...missing } = task;
  await assertFails(setDoc(doc(db('mom'), 'users/mom/tasks/a'), missing));
});
test('contacts do not grant cross-account access or allow grant forgery', async () => {
  await assertSucceeds(setDoc(doc(db('mom'), 'users/mom/family/child'), {name:'Child',relation:'Con',phone:'123'}));
  await assertFails(setDoc(doc(db('child'), 'users/child'), {role:'admin',pairedMomUid:'mom'}));
  await assertFails(getDoc(doc(db('child'), 'users/mom/tasks/a')));
  await assertFails(setDoc(doc(db('mom'), 'users/mom/caregivers/child'), {}));
  await assertFails(setDoc(doc(db('child'), 'users/mom/caregivers/child'), {}));
});
test('trusted caregiver can manage v2 tasks; grants are server-only; suggestions private', async () => {
  await env.withSecurityRulesDisabled(async ctx => {
    await setDoc(doc(ctx.firestore(),'users/mom/caregivers/child'), {});
    await setDoc(doc(ctx.firestore(),'users/mom/tasks/a'), task);
    await setDoc(doc(ctx.firestore(),'users/mom/suggestions/a'), {senderUid:'child',status:'dismissed'});
  });
  await assertSucceeds(getDoc(doc(db('child'), 'users/mom/tasks/a')));
  await assertSucceeds(updateDoc(doc(db('child'), 'users/mom/tasks/a'), {title:'Changed',revision:1}));
  await assertFails(getDoc(doc(db('child'), 'users/mom/suggestions/a')));
  await assertFails(setDoc(doc(db('child'), 'users/mom/suggestions/b'), {senderUid:'child',status:'pending'}));
  await assertFails(updateDoc(doc(db('mom'), 'users/mom/suggestions/a'), {status:'accepted'}));
  await env.withSecurityRulesDisabled(ctx => deleteDoc(doc(ctx.firestore(),'users/mom/caregivers/child')));
  await assertFails(getDoc(doc(db('child'), 'users/mom/tasks/a')));
  await assertFails(updateDoc(doc(db('child'), 'users/mom/tasks/a'), {title:'Again',revision:2}));
});
test('catalog read-only, notifications server-written, default deny', async () => {
  await assertSucceeds(getDoc(doc(db('mom'), 'habits/move')));
  await assertFails(setDoc(doc(db('mom'), 'habits/move'), {}));
  await assertFails(setDoc(doc(db('mom'), 'users/mom/notifications/a'), {}));
  await assertFails(setDoc(doc(db('mom'), 'unknown/a'), {}));
});
test('Storage: owner PDF upload/read/delete; reject stranger, type, size, extension', async () => {
  const own = env.authenticatedContext('mom').storage();
  const file = ref(own, 'reports/mom/week.pdf');
  await assertSucceeds(uploadBytes(file, new Uint8Array([37,80,68,70]), {contentType:'application/pdf'}));
  await assertSucceeds(getBytes(file));
  await assertFails(getBytes(ref(env.authenticatedContext('child').storage(), 'reports/mom/week.pdf')));
  await assertFails(uploadBytes(ref(own,'reports/child/week.pdf'), new Uint8Array([1]), {contentType:'application/pdf'}));
  await assertFails(uploadBytes(ref(own,'reports/mom/week.txt'), new Uint8Array([1]), {contentType:'application/pdf'}));
  await assertFails(uploadBytes(ref(own,'reports/mom/bad.pdf'), new Uint8Array([1]), {contentType:'text/plain'}));
  await assertFails(uploadBytes(ref(own,'reports/mom/big.pdf'), new Uint8Array(5*1024*1024), {contentType:'application/pdf'}));
  await assertFails(getBytes(ref(env.unauthenticatedContext().storage(),'reports/mom/week.pdf')));
  await assertSucceeds(deleteObject(file));
});
test('F1 profile: owner creates and selects role; other users and anonymous denied', async () => {
  const profile = doc(db('mom'), 'users/mom');
  await assertSucceeds(setDoc(profile, {displayName:'Bác', photoUrl:null, role:null, onboarded:false, createdAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(profile, {role:'elder'}));
  await assertSucceeds(getDoc(profile));
  await assertFails(getDoc(doc(db('child'), 'users/mom')));
  await assertFails(updateDoc(doc(db('child'), 'users/mom'), {role:'caregiver'}));
  await assertFails(setDoc(doc(db('child'), 'users/mom'), {role:'elder'}));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'users/mom')));
});

test('F10: inbox is owner-readable but only trusted backend can write', async () => {
  await env.withSecurityRulesDisabled(ctx => setDoc(doc(ctx.firestore(), 'users/mom/notifications/n'), {
    title: 'Đến giờ đi bộ', body: '9:30 sáng', route: '/reminder/a', receivedAt: serverTimestamp(),
  }));
  await assertSucceeds(getDoc(doc(db('mom'), 'users/mom/notifications/n')));
  await assertFails(getDoc(doc(db('child'), 'users/mom/notifications/n')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'users/mom/notifications/n')));
  await assertFails(updateDoc(doc(db('mom'), 'users/mom/notifications/n'), {route:'/inbox'}));
  await assertSucceeds(deleteDoc(doc(db('mom'), 'users/mom/notifications/n')));
});
test('F10: device registration owner-only and validates token/time/payload', async () => {
  const registration = {token:'device-token', updatedAt:serverTimestamp(), platform:'android'};
  const own = doc(db('mom'), 'users/mom/devices/device-token');
  await assertSucceeds(setDoc(own, registration));
  await assertSucceeds(getDoc(own));
  await assertFails(getDoc(doc(db('child'), 'users/mom/devices/device-token')));
  await assertFails(setDoc(doc(db('child'), 'users/mom/devices/device-token'), registration));
  await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), 'users/mom/devices/device-token'), registration));
  for (const patch of [{token:'other'}, {platform:'admin'}, {updatedAt:new Date(0)}, {admin:true}]) {
    await assertFails(setDoc(own, {...registration,...patch}));
  }
  await assertSucceeds(deleteDoc(own));
});

const v2 = {...task,schemaVersion:2,revision:0,startDate:'2026-11-04',endDate:null,weekdays:[1,3,5],monthDays:[],
  lastDayOfMonth:false,excludedDates:[],durationMinutes:15,timezone:'Asia/Ho_Chi_Minh',repeat:'weekly'};
test('v2 schedule validates recurrence and rejects stale revisions, schema injection', async () => {
  const own=doc(db('mom'),'users/mom/tasks/v2');
  await assertSucceeds(setDoc(own,v2));
  for(const patch of [{weekdays:[]},{weekdays:[0,8]},{weekdays:[1,1]}, {monthDays:[32]}, {timezone:'UTC'},
      {revision:-1},{durationMinutes:0},{startDate:'bad'},{admin:true},{status:'done'}]) {
    await assertFails(setDoc(doc(db('mom'),'users/mom/tasks/bad'),{...v2,...patch}));
  }
  await assertFails(updateDoc(own,{title:'Stale',revision:0}));
  await assertSucceeds(updateDoc(own,{title:'New',revision:1}));
});
test('completion status is per day; owner only; deterministic identity and server time',async()=>{
  await assertSucceeds(setDoc(doc(db('mom'),'users/mom/tasks/t'),v2));
  const completion={taskId:'t',date:'2026-11-04',status:'done',updatedAt:serverTimestamp()};
  await assertSucceeds(setDoc(doc(db('mom'),'users/mom/completions/t_2026-11-04'),completion));
  await assertFails(setDoc(doc(db('child'),'users/mom/completions/t_2026-11-04'),completion));
  await assertFails(setDoc(doc(db('mom'),'users/mom/completions/wrong'),completion));
  await assertFails(setDoc(doc(db('mom'),'users/mom/completions/missing_2026-11-04'),{...completion,taskId:'missing'}));
});
test('profile cannot forge pairing or change established role; settings merge is valid',async()=>{
  const own=doc(db('mom'),'users/mom');
  await assertFails(setDoc(own,{role:'elder',pairedMomUid:'victim'}));
  await assertSucceeds(setDoc(own,{role:null,onboarded:false}));
  await assertSucceeds(updateDoc(own,{role:'elder',fontScale:1.3,honorific:'ba',wakeTime:'06:30'}));
  await assertFails(updateDoc(own,{pairedMomUid:'victim'}));
  await assertFails(updateDoc(own,{role:'caregiver'}));
  await assertFails(updateDoc(own,{fontScale:10}));
  await assertFails(getDoc(doc(db('mom'),'pairings/123456')));
  await assertFails(setDoc(doc(db('mom'),'pairingOwners/mom'),{code:'123456'}));
});
