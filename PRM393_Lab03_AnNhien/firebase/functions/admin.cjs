'use strict';
const {FieldValue, Timestamp} = require('firebase-admin/firestore');
const {HttpsError} = require('firebase-functions/v2/https');
const DAY=86400000, ZONE=7*3600000;
const SEGMENTS=['all','parents','children','inactive','new'];
const ms=value=>value?.toMillis?.() || 0;
const dateKey=value=>new Date(value+ZONE).toISOString().slice(0,10);
const startDay=now=>Date.parse(dateKey(now)+'T00:00:00+07:00');
function requireAdmin(auth){
  if(!auth?.uid) throw new HttpsError('unauthenticated','Vui lòng đăng nhập.');
  if(auth.token?.admin!==true) throw new HttpsError('permission-denied','Tài khoản chưa có quyền admin.');
}
function matchesSegment(profile,presence,segment,now){
  if(segment==='parents')return profile.role==='elder';
  if(segment==='children')return profile.role==='caregiver';
  if(segment==='new')return ms(profile.createdAt)>=now-7*DAY;
  // Unknown activity is not silently classified as inactive.
  if(segment==='inactive')return ms(presence?.lastSeen)>0&&ms(presence.lastSeen)<now-7*DAY;
  return segment==='all';
}
function periodBuckets(period,now){
  const end=startDay(now)+DAY;
  const configs={hour:{step:3600000,n:24,end:Math.floor(now/3600000)*3600000+3600000},day:{step:3600000,n:24,end},week:{step:DAY,n:7,end},month:{step:DAY,n:30,end},quarter:{step:DAY,n:90,end}};
  const c=configs[period];if(!c)throw new HttpsError('invalid-argument','Khoảng thời gian không hợp lệ.');
  return {...c,start:c.end-c.step*c.n};
}
async function count(query){return (await query.count().get()).data().count;}
async function bounded(query,max=10000){const result=await query.limit(max+1).get();if(result.size>max)throw new HttpsError('resource-exhausted','Dữ liệu vượt giới hạn báo cáo trực tiếp. Cần chuyển sang bảng aggregate.');return result.docs;}
function createAdminService(db,{now=Date.now}={}){
  async function profilesAndPresence(){const [profiles,presence]=await Promise.all([bounded(db.collection('users')),bounded(db.collection('adminPresence'))]);return {profiles,presence:new Map(presence.map(d=>[d.id,d.data()]))};}
  async function dashboard(auth,data={}){
    requireAdmin(auth);const time=now(),today=startDay(time),b=periodBuckets(data.period||'week',time);const warnings=[];let fallbackProfiles;
    const optionalCount=async(query,label,group,field,cutoff)=>{try{return await count(query);}catch(error){if(error.code!==9)throw error;fallbackProfiles||=bounded(db.collection('users'));const users=await fallbackProfiles;const values=await Promise.all(users.map(u=>count(db.collection(`users/${u.id}/${group}`).where(field,'>=',cutoff))));warnings.push(label+': đang dùng truy vấn theo người dùng trong lúc xây index');return values.reduce((a,b)=>a+b,0);}};
    const [{profiles,presence},tasks,doneToday,skippedToday,postponedToday,links,campaigns,daily,registeredDevices,notificationsToday,notificationsReadToday]=await Promise.all([
      profilesAndPresence(),count(db.collectionGroup('tasks')),count(db.collectionGroup('completions').where('date','==',dateKey(time)).where('status','==','done')),
      count(db.collectionGroup('completions').where('date','==',dateKey(time)).where('status','==','skipped')),
      count(db.collectionGroup('completions').where('date','==',dateKey(time)).where('status','==','postponed')),
      count(db.collectionGroup('caregivers')),db.collection('adminCampaigns').orderBy('createdAt','desc').limit(20).get(),
      db.collection('adminDaily').doc(dateKey(time)).get(),
      optionalCount(db.collectionGroup('devices').where('updatedAt','>=',Timestamp.fromMillis(time-30*DAY)),'Thiết bị','devices','updatedAt',Timestamp.fromMillis(time-30*DAY)),
      optionalCount(db.collectionGroup('notifications').where('receivedAt','>=',Timestamp.fromMillis(today)),'Thông báo mới','notifications','receivedAt',Timestamp.fromMillis(today)),
      optionalCount(db.collectionGroup('notifications').where('readAt','>=',Timestamp.fromMillis(today)),'Thông báo đã đọc','notifications','readAt',Timestamp.fromMillis(today))
    ]);
    const segmentCounts=Object.fromEntries(SEGMENTS.map(s=>[s,profiles.filter(d=>matchesSegment(d.data(),presence.get(d.id),s,time)).length]));
    const current=Array(b.n).fill(0),previous=Array(b.n).fill(0),labels=[];
    for(let i=0;i<b.n;i++)labels.push(new Intl.DateTimeFormat('vi-VN',{timeZone:'Asia/Bangkok',...(b.step===DAY?{day:'2-digit',month:'2-digit'}:{hour:'2-digit',minute:'2-digit'})}).format(b.start+i*b.step));
    profiles.forEach(d=>{const at=ms(d.data().createdAt);if(!at)return;let i=Math.floor((at-b.start)/b.step);if(i>=0&&i<b.n)current[i]++;i=Math.floor((at-(b.start-b.n*b.step))/b.step);if(i>=0&&i<b.n)previous[i]++;});
    const p=profiles.map(d=>presence.get(d.id)).filter(Boolean);const dau=p.filter(x=>ms(x.lastSeen)>=today).length,wau=p.filter(x=>ms(x.lastSeen)>=time-7*DAY).length,mau=p.filter(x=>ms(x.lastSeen)>=time-30*DAY).length;
    const newToday=profiles.filter(d=>ms(d.data().createdAt)>=today).length;
    const linkedParents=new Set(profiles.map(d=>d.data().pairedMomUid).filter(Boolean));
    const recent=[...profiles].sort((a,b)=>ms(b.data().createdAt)-ms(a.data().createdAt)).slice(0,100).map(d=>({id:d.id,name:d.data().displayName||'Chưa đặt tên',role:d.data().role||null,createdAt:ms(d.data().createdAt)||null,paired:Boolean(d.data().pairedMomUid)||linkedParents.has(d.id),lastSeen:ms(presence.get(d.id)?.lastSeen)||null}));
    const campaignRows=campaigns.docs.map(d=>({id:d.id,...d.data(),createdAt:ms(d.data().createdAt),scheduledAt:ms(d.data().scheduledAt)}));
    return {source:'firestore',warnings,generatedAt:time,timezone:'Asia/Bangkok',period:data.period||'week',metrics:{totalUsers:profiles.length,parents:segmentCounts.parents,children:segmentCounts.children,unassigned:profiles.length-segmentCounts.parents-segmentCounts.children,newToday,dau,wau,mau,returningToday:daily.data()?.returningUsers||0,firstSeenToday:daily.data()?.firstSeenUsers||0,sessionsToday:daily.data()?.sessions||0,downloads:null,registeredDevices,notificationsToday,notificationsReadToday,tasks,doneToday,skippedToday,postponedToday,familyLinks:links,trackedUsers:p.length,activityCoverage:profiles.length?Math.round(p.length/profiles.length*1000)/10:0},growth:{current,previous,labels,total:current.reduce((a,b)=>a+b,0)},segments:segmentCounts,users:recent,campaigns:campaignRows};
  }
  async function recordActivity(auth){
    if(!auth?.uid)throw new HttpsError('unauthenticated','Vui lòng đăng nhập.');
    const time=now(),key=dateKey(time),uid=auth.uid;
    await db.runTransaction(async tx=>{
      const presenceRef=db.doc(`adminPresence/${uid}`),dailyRef=db.doc(`adminDaily/${key}`),memberRef=db.doc(`adminDaily/${key}/members/${uid}`);
      const [profile,presence,member]=await Promise.all([tx.get(db.doc(`users/${uid}`)),tx.get(presenceRef),tx.get(memberRef)]);
      if(!profile.exists)throw new HttpsError('failed-precondition','Hồ sơ chưa sẵn sàng.');
      if(presence.exists && dateKey(ms(presence.data()?.lastSeen))===key && time-ms(presence.data()?.lastSeen)<30*60000)return;
      tx.set(presenceRef,{lastSeen:Timestamp.fromMillis(time),...(!presence.exists?{firstSeen:Timestamp.fromMillis(time)}:{})},{merge:true});
      tx.set(dailyRef,{sessions:FieldValue.increment(1),...(!member.exists?{activeUsers:FieldValue.increment(1),[presence.exists?'returningUsers':'firstSeenUsers']:FieldValue.increment(1)}:{})},{merge:true});
      if(!member.exists)tx.create(memberRef,{firstOpenAt:Timestamp.fromMillis(time)});
    });
    return {ok:true};
  }
  async function createCampaign(auth,data){
    requireAdmin(auth);const title=typeof data.title==='string'?data.title.trim():'',body=typeof data.body==='string'?data.body.trim():'';
    if(!title||title.length>65||!body||body.length>240||!SEGMENTS.includes(data.segment)||typeof data.requestId!=='string'||!/^[\w-]{16,100}$/.test(data.requestId))throw new HttpsError('invalid-argument','Thông báo hoặc nhóm người nhận không hợp lệ.');
    const scheduled=data.scheduledAt==null?now():Number(data.scheduledAt);
    if(!Number.isFinite(scheduled)||scheduled<now()-60000||scheduled>now()+90*DAY)throw new HttpsError('invalid-argument','Chọn lịch trong vòng 90 ngày tới.');
    const ref=db.doc(`adminCampaigns/${auth.uid}_${data.requestId}`);
    await db.runTransaction(async tx=>{
      const [existing,rate]=await Promise.all([tx.get(ref),tx.get(db.doc(`adminCampaignRate/${auth.uid}`))]);
      if(existing.exists)return;
      if(now()-ms(rate.data()?.lastCreated)<10000)throw new HttpsError('resource-exhausted','Vui lòng chờ 10 giây trước chiến dịch tiếp theo.');
      tx.create(ref,{title,body,segment:data.segment,scheduledAt:Timestamp.fromMillis(scheduled),createdAt:Timestamp.fromMillis(now()),createdBy:auth.uid,status:'queued',enqueuedUsers:0});
      tx.set(db.doc(`adminCampaignRate/${auth.uid}`),{lastCreated:Timestamp.fromMillis(now())});
    });return {id:ref.id};
  }
  async function cancelCampaign(auth,{id}){
    requireAdmin(auth);if(typeof id!=='string'||!id||id.includes('/')||id.length>240)throw new HttpsError('invalid-argument','Mã chiến dịch không hợp lệ.');
    await db.runTransaction(async tx=>{const ref=db.doc(`adminCampaigns/${id}`),doc=await tx.get(ref);if(!doc.exists)throw new HttpsError('not-found','Không tìm thấy chiến dịch.');if(doc.data().status!=='queued')throw new HttpsError('failed-precondition','Chỉ hủy được chiến dịch đang chờ.');tx.update(ref,{status:'cancelled',cancelledBy:auth.uid,cancelledAt:Timestamp.fromMillis(now())});});return {ok:true};
  }
  // One batch per campaign per invocation. Cursor and outbox writes commit together.
  // Retrying a batch never creates duplicate inbox documents.
  async function dispatchCampaign(id){
    const ref=db.doc(`adminCampaigns/${id}`),token=db.collection('adminWorkerIds').doc().id;
    const leased=await db.runTransaction(async tx=>{const doc=await tx.get(ref);const c=doc.data();if(!c||!['queued','sending'].includes(c.status)||ms(c.scheduledAt)>now()||ms(c.leaseUntil)>now())return false;tx.update(ref,{status:'sending',leaseToken:token,leaseUntil:Timestamp.fromMillis(now()+120000)});return true;});
    if(!leased)return;
    try{
      const c=(await ref.get()).data();let query=db.collection('users').orderBy('__name__').limit(150);if(c.cursor)query=query.startAfter(c.cursor);
      const users=await query.get();const selected=[];
      for(const u of users.docs){const presence=c.segment==='inactive'?(await db.doc(`adminPresence/${u.id}`).get()).data():null;if(matchesSegment(u.data(),presence,c.segment,now()))selected.push(u.id);}
      await db.runTransaction(async tx=>{const current=(await tx.get(ref)).data();if(current?.leaseToken!==token)return;
        for(const uid of selected)tx.set(db.doc(`users/${uid}/notifications/campaign-${id}`),{recipientUid:uid,kind:'system',event:'admin_campaign',campaignId:id,title:c.title,body:c.body,route:'/inbox',receivedAt:FieldValue.serverTimestamp()});
        tx.update(ref,{status:users.size<150?'enqueued':'sending',cursor:users.docs.at(-1)?.id||c.cursor||null,enqueuedUsers:FieldValue.increment(selected.length),leaseUntil:Timestamp.fromMillis(0),...(users.size<150?{enqueuedAt:Timestamp.fromMillis(now())}:{})});
      });
    }catch(error){await db.runTransaction(async tx=>{const c=(await tx.get(ref)).data();if(c?.leaseToken===token)tx.update(ref,{leaseUntil:Timestamp.fromMillis(0),lastError:'Không thể xếp hàng. Worker sẽ thử lại.'});});throw error;}
  }
  async function processQueue(){const docs=await db.collection('adminCampaigns').where('status','in',['queued','sending']).where('scheduledAt','<=',Timestamp.fromMillis(now())).orderBy('scheduledAt').limit(20).get();await Promise.all(docs.docs.map(d=>dispatchCampaign(d.id)));}
  return {dashboard,recordActivity,createCampaign,cancelCampaign,dispatchCampaign,processQueue};
}
module.exports={createAdminService,requireAdmin,matchesSegment,periodBuckets,dateKey,startDay};
