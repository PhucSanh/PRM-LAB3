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
  await assertSucceeds(setDoc(doc(db('child'), 'users/child'), {role:'admin',momUid:'mom'}));
  await assertFails(getDoc(doc(db('child'), 'users/mom/tasks/a')));
  await assertFails(setDoc(doc(db('mom'), 'users/mom/caregivers/child'), {}));
  await assertFails(setDoc(doc(db('child'), 'users/mom/caregivers/child'), {}));
});
test('trusted caregiver can read tasks and suggest; owner only accepts/rejects', async () => {
  await env.withSecurityRulesDisabled(async ctx => {
    await setDoc(doc(ctx.firestore(),'users/mom/caregivers/child'), {});
    await setDoc(doc(ctx.firestore(),'users/mom/tasks/a'), task);
  });
  await assertSucceeds(getDoc(doc(db('child'), 'users/mom/tasks/a')));
  await assertFails(updateDoc(doc(db('child'), 'users/mom/tasks/a'), {title:'Changed'}));
  const suggestion = {senderUid:'child',status:'pending',title:'Đi bộ',createdAt:serverTimestamp()};
  await assertSucceeds(setDoc(doc(db('child'), 'users/mom/suggestions/a'), suggestion));
  await assertFails(setDoc(doc(db('stranger'), 'users/mom/suggestions/b'), {...suggestion,senderUid:'stranger'}));
  await assertFails(setDoc(doc(db('child'), 'users/mom/suggestions/b'), {...suggestion,senderUid:'mom'}));
  await assertFails(updateDoc(doc(db('child'), 'users/mom/suggestions/a'), {status:'accepted'}));
  await assertFails(updateDoc(doc(db('mom'), 'users/mom/suggestions/a'), {title:'Overwrite'}));
  await assertSucceeds(updateDoc(doc(db('mom'), 'users/mom/suggestions/a'), {status:'accepted'}));
  await assertFails(updateDoc(doc(db('mom'), 'users/mom/suggestions/a'), {status:'rejected'}));
  await env.withSecurityRulesDisabled(ctx => deleteDoc(doc(ctx.firestore(),'users/mom/caregivers/child')));
  await assertFails(getDoc(doc(db('child'), 'users/mom/tasks/a')));
  await assertFails(getDoc(doc(db('child'), 'users/mom/suggestions/a')));
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
