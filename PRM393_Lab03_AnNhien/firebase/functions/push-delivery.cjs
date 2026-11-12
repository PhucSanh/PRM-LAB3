'use strict';
const TRANSIENT = new Set(['messaging/internal-error','messaging/server-unavailable',
  'messaging/quota-exceeded','messaging/unknown-error']);

const familyPush = new Map([
  ['suggestion_accepted', {title:'Ba mẹ đã đồng ý với gợi ý',body:'Việc bạn gửi đã được thêm vào lịch.'}],
  ['suggestion_partial', {title:'Ba mẹ đã nhận một phần gợi ý',body:'Một số việc bạn gửi đã được thêm vào lịch.'}],
  ['suggestion_dismissed', {title:'Ba mẹ đã bỏ qua gợi ý',body:'Ba mẹ đã từ chối các việc chưa nhận.'}],
  ['task_completed', {title:'Bác đã hoàn thành một việc',body:'Mở lịch để xem cập nhật từ người thân.'}],
]);

async function sendInboxPush(db, messaging, {uid,id,data}, now=Date.now()) {
  if (!data || data.recipientUid && data.recipientUid !== uid) return;
  const devices=await db.collection(`users/${uid}/devices`).get();
  const fresh=devices.docs.filter(doc=>{
    const device=doc.data();
    return typeof device.token==='string' && device.token.length>0 &&
      device.updatedAt?.toMillis()>now-30*86400000;
  });
  for(let offset=0;offset<fresh.length;offset+=500) {
    const chunk=fresh.slice(offset,offset+500);
    const result=await messaging.sendEachForMulticast({
      tokens:chunk.map(doc=>doc.data().token),
      notification: data.event==='admin_campaign' && data.campaignId
        ? {title:data.title,body:data.body}
        : familyPush.get(data.event) ??
          {title:'An Nhiên',body:'Bạn có thông báo mới. Mở An Nhiên để xem nhé.'},
      data:{notification_id:id,recipient_uid:uid,
        parent_uid:typeof data.parentUid==='string'?data.parentUid:'',
        kind:['family','reminder'].includes(data.kind)?data.kind:'system',
        route:typeof data.route==='string'?data.route:'/inbox'},
      android:{priority:'high',notification:{tag:id,channelId:'an_nhien_updates',icon:'ic_notification',sound:'default',defaultVibrateTimings:true}},
    });
    await Promise.all(result.responses.map((response,i)=>
      response.error?.code==='messaging/registration-token-not-registered'?chunk[i].ref.delete():null));
    if(result.responses.some(response=>TRANSIENT.has(response.error?.code))) {
      throw new Error('Transient FCM error; inbox remains available');
    }
  }
}
module.exports={sendInboxPush};
