'use strict';
const {createHash,timingSafeEqual}=require('node:crypto');
const {Timestamp}=require('firebase-admin/firestore');
const {HttpsError}=require('firebase-functions/v2/https');
const hash=s=>createHash('sha256').update(s).digest();
function createAdminLogin(db,auth,{getPassword,now=Date.now}){
 return async(request)=>{
  const data=request.data||{};
  if(typeof data.username!=='string'||typeof data.password!=='string'||data.username.length>100||data.password.length>256)throw new HttpsError('invalid-argument','Thông tin đăng nhập không hợp lệ.');
  const time=now(),windowMs=15*60000;
  const keys=['account',hash(request.rawRequest?.ip||'unknown').toString('hex')];
  await db.runTransaction(async tx=>{
   const refs=keys.map(k=>db.doc(`adminLoginAttempts/${k}`));const docs=await Promise.all(refs.map(r=>tx.get(r)));
   docs.forEach((d,i)=>{const value=d.data();if(value&&time-value.start.toMillis()<windowMs&&value.count>=(i===0?30:5))throw new HttpsError('resource-exhausted','Thử đăng nhập quá nhiều lần. Vui lòng đợi 15 phút.');});
   refs.forEach((ref,i)=>{const old=docs[i].data();tx.set(ref,old&&time-old.start.toMillis()<windowMs?{...old,count:old.count+1}:{start:Timestamp.fromMillis(time),count:1});});
  });
  const secret=getPassword();
  if(!secret||data.username!=='admin'||!timingSafeEqual(hash(data.password),hash(secret)))throw new HttpsError('unauthenticated','Tên đăng nhập hoặc mật khẩu không đúng.');
  // This dedicated identity has no elder/caregiver profile and is excluded from app metrics.
  // Password exists only in Secret Manager; the browser receives a short-lived custom token.
  const token=await auth.createCustomToken('an-nhien-admin',{admin:true});
  return {token};
 };
}
module.exports={createAdminLogin};
