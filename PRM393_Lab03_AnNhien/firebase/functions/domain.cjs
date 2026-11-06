'use strict';
const {randomInt} = require('node:crypto');
const {isDeepStrictEqual}=require('node:util');
const {Timestamp, FieldValue} = require('firebase-admin/firestore');
class DomainError extends Error { constructor(code, message) {super(message); this.code = code;} }
const fail = (code, message) => {throw new DomainError(code, message);};
const requireUid = uid => {if (!uid) fail('unauthenticated', 'Cần đăng nhập trước.');};
const validId = value => typeof value === 'string' && /^[a-zA-Z0-9_-]{1,128}$/.test(value);
const validDate = s => typeof s === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(s) &&
  Number.isFinite(Date.parse(s)) && new Date(s).toISOString().slice(0,10) === s;
function validateTask(t) {
  const allowed = ['completionSourceId','revision','schemaVersion','title','habitKey','hour','minute','repeat','status','remind','startDate',
    'endDate','weekdays','monthDays','lastDayOfMonth','excludedDates','durationMinutes','timezone'];
  if (!t || Object.keys(t).some(k=>!allowed.includes(k)) || t.schemaVersion!==2 ||
      t.completionSourceId!=null && (typeof t.completionSourceId!=='string'||t.completionSourceId.length>128) || !Number.isInteger(t.revision) || t.revision<0 || typeof t.title!=='string' || !t.title.trim() || t.title.length>80 ||
      !['move','purpose','downshift','eighty','plant','tea','belong','family','tribe'].includes(t.habitKey) ||
      !Number.isInteger(t.hour) || t.hour<0 || t.hour>23 || !Number.isInteger(t.minute) || t.minute<0 || t.minute>59 ||
      !['once','daily','someDays','weekly','monthly'].includes(t.repeat) || t.status!=='pending' ||
      typeof t.remind!=='boolean' || !validDate(t.startDate) ||
      t.endDate!==null && (!validDate(t.endDate)||t.endDate<t.startDate) ||
      !Array.isArray(t.weekdays) || t.weekdays.length>7 || t.weekdays.some(n=>!Number.isInteger(n)||n<1||n>7) ||
      ['someDays','weekly'].includes(t.repeat)&&!t.weekdays.length ||
      !Array.isArray(t.monthDays) || t.monthDays.length>31 || t.monthDays.some(n=>!Number.isInteger(n)||n<1||n>31) ||
      typeof t.lastDayOfMonth!=='boolean' || t.repeat==='monthly'&&!t.monthDays.length&&!t.lastDayOfMonth ||
      !Array.isArray(t.excludedDates) || t.excludedDates.length>366 || t.excludedDates.some(s=>!validDate(s)) ||
      !Number.isInteger(t.durationMinutes) || t.durationMinutes<1 || t.durationMinutes>1440 || t.timezone!=='Asia/Ho_Chi_Minh') {
    fail('invalid-argument','Thông tin lịch chưa hợp lệ. Kiểm tra tên, ngày và giờ.');
  }
  return {...t,title:t.title.trim()};
}

function createDomain(db, {now = () => Date.now(), generateCode = () => String(randomInt(100000,1000000))} = {}) {
  const user = uid => db.doc(`users/${uid}`);
  async function createPairing(uid) {
    requireUid(uid);
    for(let attempt=0;attempt<8;attempt++) {
      const code=generateCode();
      const result=await db.runTransaction(async tx=>{
        const profile=await tx.get(user(uid));
        if(profile.data()?.role!=='elder') fail('permission-denied','Chỉ máy của Bác tạo mã ghép nối.');
        const pointer=db.doc(`pairingOwners/${uid}`);
        const previous=await tx.get(pointer);
        const target=db.doc(`pairings/${code}`);
        const existing=await tx.get(target);
        if(existing.exists && existing.data().expiresAt.toMillis()>now()) return null;
        if(previous.exists && previous.data().createdAt.toMillis()>now()-30000) {
          fail('resource-exhausted','Chờ 30 giây rồi tạo mã mới nhé.');
        }
        if(previous.exists) tx.delete(db.doc(`pairings/${previous.data().code}`));
        const expiresAt=Timestamp.fromMillis(now()+600000);
        tx.set(target,{momUid:uid,expiresAt,createdAt:Timestamp.fromMillis(now())});
        tx.set(pointer,{code,createdAt:Timestamp.fromMillis(now())});
        return {code,expiresAt:expiresAt.toMillis()};
      });
      if(result) return result;
    }
    fail('resource-exhausted','Chưa tạo được mã mới. Bác thử lại nhé.');
  }
  async function redeemPairing(uid, code) {
    requireUid(uid);
    if(typeof code!=='string'||!/^\d{6}$/.test(code)) fail('invalid-argument','Mã gồm 6 số. Ví dụ: 123456.');
    const result=await db.runTransaction(async tx=>{
      const profile=await tx.get(user(uid));
      if(profile.data()?.role!=='caregiver') fail('permission-denied','Chọn vai trò Con cháu trước.');
      const rateRef=db.doc(`pairingAttempts/${uid}`);
      const rate=await tx.get(rateRef);
      const active=rate.exists && rate.data().since.toMillis()>now()-600000;
      const count=active?rate.data().count:0;
      if(count>=5) fail('resource-exhausted','Đã thử 5 lần. Chờ 10 phút rồi thử lại.');
      const ref=db.doc(`pairings/${code}`);
      const pair=await tx.get(ref);
      const data=pair.data();
      const mom=data ? await tx.get(user(data.momUid)) : null;
      const pointer=data ? await tx.get(db.doc(`pairingOwners/${data.momUid}`)) : null;
      tx.set(rateRef,{since:active?rate.data().since:Timestamp.fromMillis(now()),count:count+1});
      if(!data||data.expiresAt.toMillis()<=now()||data.momUid===uid||mom.data()?.role!=='elder'||pointer.data()?.code!==code) {
        return {error:true}; // Commit failed attempts; throwing here would roll the counter back.
      }
      const oldMom=profile.data()?.pairedMomUid;
      if(oldMom && oldMom!==data.momUid) tx.delete(db.doc(`users/${oldMom}/caregivers/${uid}`));
      tx.set(db.doc(`users/${data.momUid}/caregivers/${uid}`),{displayName:profile.data()?.displayName||'Người thân',createdAt:FieldValue.serverTimestamp()});
      tx.update(user(uid),{pairedMomUid:data.momUid});
      tx.delete(ref); tx.delete(db.doc(`pairingOwners/${data.momUid}`));
      return {momUid:data.momUid};
    });
    if(result.error) fail('not-found','Mã chưa đúng hoặc đã hết hạn. Nhờ mẹ tạo mã mới rồi thử lại.');
    return result;
  }
  async function revokePairing(uid, momUid, childUid) {
    requireUid(uid);
    if(!validId(momUid)||!validId(childUid)||uid!==momUid&&uid!==childUid) fail('permission-denied','Không có quyền ngưng ghép nối.');
    await db.runTransaction(async tx=>{
      const child=await tx.get(user(childUid));
      tx.delete(db.doc(`users/${momUid}/caregivers/${childUid}`));
      if(child.data()?.pairedMomUid===momUid) tx.update(user(childUid),{pairedMomUid:FieldValue.delete()});
    });
    return {ok:true};
  }
  async function sendSuggestion(uid, {momUid,id,tasks,message=''}) {
    requireUid(uid);
    if(!validId(momUid)||!validId(id)||!Array.isArray(tasks)||tasks.length<1||tasks.length>10||typeof message!=='string'||message.length>500) fail('invalid-argument','Kiểm tra lại lịch gợi ý.');
    tasks=tasks.map(validateTask);
    await db.runTransaction(async tx=>{
      const grant=await tx.get(db.doc(`users/${momUid}/caregivers/${uid}`));
      if(!grant.exists) fail('permission-denied','Cần ghép nối lại với máy của mẹ.');
      const ref=db.doc(`users/${momUid}/suggestions/${id}`);
      const existing=await tx.get(ref);
      if(existing.exists) {
        if(existing.data().senderUid!==uid || !isDeepStrictEqual(existing.data().tasks,tasks) || existing.data().message!==message) fail('already-exists','Mã yêu cầu đã dùng cho lịch khác. Tạo lịch mới rồi gửi lại.');
        return; // Same request id: do not create a second notification or schedule.
      }
      const sender=await tx.get(db.doc(`users/${uid}`));
      tx.create(ref,{senderName:sender.data()?.displayName||'Người thân',senderUid:uid,status:'pending',tasks,message,createdAt:FieldValue.serverTimestamp(),acceptedIds:[]});
      tx.set(db.doc(`users/${momUid}/notifications/suggestion-${id}`),{
        kind:'family',event:'suggestion_received',title:'Có lịch gợi ý mới',body:'Người thân gửi lịch. Bác tự chọn nhận hoặc bỏ qua.',
        route:`/inbox/suggestions/${id}`,recipientUid:momUid,receivedAt:FieldValue.serverTimestamp()});
    });
    return {id};
  }
  async function resolveSuggestion(uid, {id,selected=[],times={}}) {
    requireUid(uid);
    if(!validId(id)||!Array.isArray(selected)||!selected.every(Number.isInteger)||new Set(selected).size!==selected.length ||
        !times || typeof times!=='object'||Array.isArray(times)) fail('invalid-argument','Lựa chọn chưa hợp lệ.');
    await db.runTransaction(async tx=>{
      const ref=db.doc(`users/${uid}/suggestions/${id}`);const snap=await tx.get(ref);const s=snap.data();
      if(!s) fail('not-found','Không tìm thấy lịch gợi ý.');
      if(!['pending','partial'].includes(s.status)) fail('failed-precondition','Gợi ý này đã được xử lý.');
      if(!Array.isArray(s.tasks)||selected.some(n=>n<0||n>=s.tasks.length)||Object.keys(times).some(k=>!selected.includes(Number(k)))) fail('invalid-argument','Lựa chọn chưa hợp lệ.');
      const previous=s.acceptedIds||[];
      if(selected.some(n=>previous.includes(`suggestion-${id}-${n}`))) fail('failed-precondition','Việc này đã được nhận.');
      const tasks=selected.map(n=>validateTask({...s.tasks[n],...(times[n]||{})}));
      const ids=selected.map(n=>`suggestion-${id}-${n}`);
      ids.forEach((taskId,i)=>tx.create(db.doc(`users/${uid}/tasks/${taskId}`),tasks[i]));
      const acceptedIds=[...previous,...ids];
      tx.update(ref,{status:!selected.length?'dismissed':acceptedIds.length===s.tasks.length?'accepted':'partial',acceptedIds,
        resolvedAt:FieldValue.serverTimestamp()});
    });
    return {ok:true};
  }
  async function undoDismiss(uid,{id}) {
    requireUid(uid);if(!validId(id)) fail('invalid-argument','Mã gợi ý không hợp lệ.');
    await db.runTransaction(async tx=>{
      const ref=db.doc(`users/${uid}/suggestions/${id}`);const snap=await tx.get(ref);
      if(snap.data()?.status!=='dismissed') fail('failed-precondition','Chỉ hoàn tác gợi ý vừa bỏ qua.');
      tx.update(ref,{status:(snap.data().acceptedIds||[]).length?'partial':'pending',resolvedAt:FieldValue.delete()});
    });return {ok:true};
  }
  return {createPairing,redeemPairing,revokePairing,sendSuggestion,resolveSuggestion,undoDismiss};
}
module.exports={createDomain,DomainError,validateTask};
