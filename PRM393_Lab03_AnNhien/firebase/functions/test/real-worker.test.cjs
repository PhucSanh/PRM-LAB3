'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
const {Timestamp}=require('firebase-admin/firestore');const {createRealWorker}=require('../real-worker.cjs');
function fixture({missingIndex=false,failFirst=false}={}){
 const state=new Map(),now=1000,stats={sent:0,userReads:0};
 const notice={id:'notice',ref:{path:'users/user/notifications/notice',parent:{parent:{id:'user',parent:{id:'users'}}}},get:()=>Timestamp.fromMillis(2000),data:()=>({kind:'system',recipientUid:'user'})};
 const snapshot=docs=>({docs,size:docs.length});
 const ref=path=>({path,get:async()=>({exists:state.has(path),data:()=>state.get(path)}),set:async value=>state.set(path,value),update:async value=>state.set(path,{...state.get(path),...value})});
 const query=docs=>({orderBy(){return this;},limit(){return this;},where(){return this;},startAfter(){return this;},get:async()=>snapshot(docs)});
 const db={doc:ref,runTransaction:async fn=>fn({get:r=>r.get(),create:(r,value)=>state.set(r.path,value),set:(r,value)=>state.set(r.path,value)}),
 collectionGroup:name=>{const q=query(name==='notifications'?[notice]:[]);if(missingIndex)q.get=async()=>{throw Object.assign(new Error('index building'),{code:9});};return q;},
 collection:path=>{if(path==='users'){stats.userReads++;return query([{id:'user'}]);}if(path==='users/user/devices')return query([{data:()=>({token:'fixture-token',updatedAt:Timestamp.fromMillis(now)}),ref:{delete:async()=>{}}}]);return query(path==='users/user/notifications'?[notice]:[]);}
 };
 const messaging={sendEachForMulticast:async()=>{stats.sent++;if(failFirst&&stats.sent===1)return {responses:[{error:{code:'messaging/server-unavailable'}}]};return {responses:[{success:true}]};}};
 const admin={processQueue:async()=>{assert.ok(state.has('serverRuntime/notifications'),'checkpoint must exist before campaign dispatch');}};
 const worker=createRealWorker(db,messaging,admin,{now:()=>now,log:{error(){}}});return {worker,state,stats};
}
test('real worker checkpoints before dispatch and does not resend processed inboxes',async()=>{
 const f=fixture();await f.worker.tick();assert.equal(f.stats.sent,1);assert.equal(f.state.get('serverRuntime/notifications').path,'users/user/notifications/notice');await f.worker.tick();assert.equal(f.stats.sent,1);assert.equal(f.worker.status().lastSuccess,1000);
});
test('FCM transient failure keeps cursor and retries rather than dropping the inbox',async()=>{
 const f=fixture({failFirst:true});await f.worker.tick();assert.equal(f.state.get('serverRuntime/notifications').path,null);assert.ok(f.worker.status().lastError);await f.worker.tick();assert.equal(f.stats.sent,2);assert.equal(f.worker.status().lastError,null);assert.equal(f.state.get('serverRuntime/notifications').path,'users/user/notifications/notice');
});
test('index-building fallback processes per-user outbox with durable cursors and no duplicate push',async()=>{
 const f=fixture({missingIndex:true});await f.worker.tick();assert.equal(f.stats.sent,1);assert.equal(f.stats.userReads,1);await f.worker.tick();assert.equal(f.stats.sent,1);assert.equal(f.stats.userReads,1);assert.equal(f.worker.status().lastError,null);assert.ok([...f.state.keys()].some(k=>k.startsWith('serverRuntime/notifications-')));
});
