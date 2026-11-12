'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {sendInboxPush}=require('../push-delivery.cjs');
function fixture(count) {
  const now=Date.now(), deleted=[];
  const docs=Array.from({length:count},(_,i)=>({data:()=>({token:`token-${i}`,updatedAt:{toMillis:()=>now}}),ref:{delete:async()=>deleted.push(i)}}));
  return {now,docs,deleted,db:{collection:path=>{assert.equal(path,'users/user/devices');return {get:async()=>({docs})};}}};
}
test('FCM chunks at 500, keeps private content out of tray and sets stable tag',async()=>{
  const f=fixture(501),batches=[];
  await sendInboxPush(f.db,{sendEachForMulticast:async message=>{
    batches.push(message);return {responses:message.tokens.map(()=>({success:true}))};
  }},{uid:'user',id:'notice',data:{kind:'family',title:'Private title',body:'Private health detail',route:'/today'}},f.now);
  assert.deepEqual(batches.map(b=>b.tokens.length),[500,1]);
  assert.equal(batches[0].android.notification.tag,'notice');
  assert.equal(batches[0].android.notification.channelId,'an_nhien_updates');
  assert.equal(batches[0].android.notification.sound,'default');
  assert.equal(batches[0].android.notification.defaultVibrateTimings,true);
  assert.equal(batches[0].data.recipient_uid,'user');
  assert.equal(batches[0].data.kind,'family');
  assert.equal(JSON.stringify(batches).includes('Private'),false);
});
test('stale registrations excluded, definite invalid token removed, transient failures retry',async()=>{
  const f=fixture(3);
  f.docs[2].data=()=>({token:'old',updatedAt:{toMillis:()=>0}});
  await assert.rejects(sendInboxPush(f.db,{sendEachForMulticast:async message=>{
    assert.equal(message.tokens.length,2);
    return {responses:[{error:{code:'messaging/registration-token-not-registered'}},{error:{code:'messaging/server-unavailable'}}]};
  }},{uid:'user',id:'n',data:{}},f.now),/Transient/);
  assert.deepEqual(f.deleted,[0]);
});
test('recipient mismatch is rejected before reading registrations',async()=>{
  await sendInboxPush({}, {}, {uid:'user',id:'n',data:{recipientUid:'other'}});
});
test('trusted admin campaign content reaches FCM notification',async()=>{
 const f=fixture(1);let notification;
 await sendInboxPush(f.db,{sendEachForMulticast:async message=>{notification=message.notification;return {responses:[{success:true}]};}},{uid:'user',id:'campaign',data:{event:'admin_campaign',campaignId:'trusted',title:'Vận động',body:'Đi bộ nhẹ nhé'}},f.now);
 assert.deepEqual(notification,{title:'Vận động',body:'Đi bộ nhẹ nhé'});
});
test('completion push signals progress without exposing task details on lock screen',async()=>{
 const f=fixture(1);let message;
 await sendInboxPush(f.db,{sendEachForMulticast:async m=>{message=m;return {responses:[{success:true}]};}},
 {uid:'user',id:'completed',data:{event:'task_completed',kind:'family',title:'Private task',body:'Private health detail',parentUid:'parent',route:'/caregiver/schedule?date=2026-11-08'}},f.now);
 assert.equal(message.notification.title,'Bác đã hoàn thành một việc');
 assert.equal(message.data.route,'/caregiver/schedule?date=2026-11-08');
 assert.equal(JSON.stringify(message).includes('Private'),false);
});
test('suggestion responses send visible FCM alerts to the original sender',async()=>{
  const f=fixture(1);
  for (const [event,title] of [
    ['suggestion_accepted','Ba mẹ đã đồng ý với gợi ý'],
    ['suggestion_partial','Ba mẹ đã nhận một phần gợi ý'],
    ['suggestion_dismissed','Ba mẹ đã bỏ qua gợi ý'],
  ]) {
    const messages=[];
    await sendInboxPush(f.db,{sendEachForMulticast:async message=>{
      messages.push(message);
      return {responses:[{success:true}]};
    }},{uid:'user',id:'response',data:{
      event,recipientUid:'user',parentUid:'parent',kind:'family',
      title:'Private task title',route:'/inbox',
    }},f.now);
    assert.equal(messages.length,1);
    assert.deepEqual(messages[0].tokens,['token-0']);
    assert.equal(messages[0].notification.title,title);
    assert.ok(messages[0].notification.body);
    assert.equal(JSON.stringify(messages[0]).includes('Private'),false);
  }
});
