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
