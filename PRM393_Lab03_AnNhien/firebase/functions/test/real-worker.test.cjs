'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
const {Timestamp}=require('firebase-admin/firestore');const {createRealWorker}=require('../real-worker.cjs');
const flush=async()=>{for(let i=0;i<8;i++)await new Promise(resolve=>setImmediate(resolve));};
function fixture({failPush=false,failInitialize=false}={}){
 let time=1000,serial=0;const state=new Map(),listeners=new Map(),timers=new Map();
 const stats={reads:0,subscriptions:0,sent:0,dispatches:[],cursors:[],queryGets:0};
 const ref=path=>({path,async get(){stats.reads++;return {exists:state.has(path),data:()=>state.get(path)};},async set(value){state.set(path,value);},async update(value){state.set(path,{...state.get(path),...value});}});
 const query=name=>({orderBy(){return this;},limit(){return this;},where(){return this;},startAfter(...args){stats.cursors.push(args.at(-1).path);return this;},async get(){stats.queryGets++;throw new Error('Polling is forbidden');},onSnapshot(next,error){stats.subscriptions++;const item={next,error};listeners.set(name,item);return ()=>{if(listeners.get(name)===item)listeners.delete(name);};}});
 const db={doc:ref,runTransaction:async fn=>{if(failInitialize)throw Object.assign(new Error('quota'),{code:8});return fn({get:r=>r.get(),create:(r,value)=>state.set(r.path,value),set:(r,value)=>state.set(r.path,value)});},collectionGroup:query,collection:path=>path==='users/user/devices'?{get:async()=>({docs:[{data:()=>({token:'fixture-token',updatedAt:Timestamp.fromMillis(time)}),ref:{delete:async()=>{}}}]})}:query(path)};
 const messaging={sendEachForMulticast:async()=>{stats.sent++;if(failPush&&stats.sent===1)return {responses:[{error:{code:'messaging/server-unavailable'}}]};return {responses:[{success:true}]};}};
 const options={now:()=>time,log:{error(){}},setTimer:(fn,ms)=>{const id=++serial;timers.set(id,{fn,due:time+ms});return id;},clearTimer:id=>timers.delete(id)};
 const admin={dispatchCampaign:async id=>{assert.ok(state.has('serverRuntime/notifications'));stats.dispatches.push(id);}};
 const makeWorker=()=>createRealWorker(db,messaging,admin,options),worker=makeWorker();
 const emit=(name,docs)=>{assert.ok(listeners.has(name),'listener exists: '+name);listeners.get(name).next({docs,docChanges:()=>docs.map(doc=>({type:doc.removed?'removed':'added',doc}))});};
 const advance=async ms=>{time+=ms;for(let i=0;i<100;i++){const due=[...timers].find(([,v])=>v.due<=time);if(!due)break;timers.delete(due[0]);due[1].fn();await flush();}};
 const notice=(id='notice',at=2000)=>({id,ref:{path:`users/user/notifications/${id}`,parent:{parent:{id:'user',parent:{id:'users'}}}},get:()=>Timestamp.fromMillis(at),data:()=>({kind:'system',recipientUid:'user'})});
 const campaign=(id,at,removed=false)=>({id,removed,data:()=>({status:'queued',scheduledAt:Timestamp.fromMillis(at)})});
 return {worker,makeWorker,state,listeners,timers,stats,emit,advance,notice,campaign,admin};
}
test('24 idle hours keep five listeners without polling or rereading checkpoints',async()=>{
 const f=fixture();await f.worker.start();for(const name of ['caregivers','completions','scheduleEvents','notifications','adminCampaigns'])f.emit(name,[]);
 await f.advance(86400000);assert.equal(f.stats.reads,4);assert.equal(f.stats.queryGets,0);assert.equal(f.stats.subscriptions,5);assert.equal(f.timers.size,0);assert.equal(f.worker.status().listeners,5);f.worker.stop();
});
test('notification event is pushed immediately and cursor advances before next page',async()=>{
 const f=fixture();await f.worker.start();f.emit('notifications',[f.notice()]);await flush();
 assert.equal(f.stats.sent,1);assert.equal(f.state.get('serverRuntime/notifications').path,'users/user/notifications/notice');assert.ok(f.stats.cursors.includes('users/user/notifications/notice'));
 f.emit('notifications',[f.notice('next',3000)]);await flush();assert.equal(f.stats.sent,2);f.worker.stop();
});
test('transient push failure retries from the same cursor without dropping an event',async()=>{
 const f=fixture({failPush:true});await f.worker.start();f.emit('notifications',[f.notice()]);await flush();assert.equal(f.state.get('serverRuntime/notifications').path,null);assert.equal(f.listeners.has('notifications'),false);
 await f.advance(29999);assert.equal(f.listeners.has('notifications'),false);await f.advance(1);f.emit('notifications',[f.notice()]);await flush();assert.equal(f.stats.sent,2);assert.equal(f.worker.status().lastError,null);assert.equal(f.state.get('serverRuntime/notifications').path,'users/user/notifications/notice');f.worker.stop();
});
test('restart resumes persisted cursor and push receipts suppress duplicate sends',async()=>{
 const f=fixture();await f.worker.start();f.emit('notifications',[f.notice()]);await flush();f.worker.stop();f.stats.cursors.length=0;const restarted=f.makeWorker();await restarted.start();assert.ok(f.stats.cursors.includes('users/user/notifications/notice'));f.emit('notifications',[f.notice()]);await flush();assert.equal(f.stats.sent,1);restarted.stop();
});
test('quota during initialization backs off fifteen minutes and shutdown cancels retries',async()=>{
 const f=fixture({failInitialize:true});await f.worker.start();assert.equal(f.worker.status().lastError,8);assert.equal(f.timers.size,1);assert.equal(f.stats.subscriptions,0);await f.advance(899999);assert.equal(f.timers.size,1);f.worker.stop();await f.advance(1);assert.equal(f.timers.size,0);assert.equal(f.stats.subscriptions,0);
});
test('listener errors reconnect from saved cursor without fallback scans',async()=>{
 const f=fixture();await f.worker.start();f.listeners.get('notifications').error({code:9});assert.equal(f.listeners.has('notifications'),false);assert.equal(f.stats.queryGets,0);await f.advance(900000);assert.equal(f.listeners.has('notifications'),true);assert.equal(f.stats.subscriptions,6);f.worker.stop();
});
test('future campaigns use a timer, cancellation removes it, new campaigns run immediately',async()=>{
 const f=fixture();await f.worker.start();f.emit('adminCampaigns',[f.campaign('later',61000)]);await f.advance(59999);assert.deepEqual(f.stats.dispatches,[]);await f.advance(1);assert.deepEqual(f.stats.dispatches,['later']);
 f.emit('adminCampaigns',[f.campaign('cancelled',121000)]);f.emit('adminCampaigns',[f.campaign('cancelled',121000,true)]);await f.advance(60000);assert.deepEqual(f.stats.dispatches,['later']);
 f.emit('adminCampaigns',[f.campaign('immediate',0)]);await f.advance(0);assert.deepEqual(f.stats.dispatches,['later','immediate']);f.worker.stop();
});
test('campaign cursor updates schedule the next batch and listener removal stops work',async()=>{
 const f=fixture();await f.worker.start();f.emit('adminCampaigns',[f.campaign('batch',0)]);await f.advance(0);f.emit('adminCampaigns',[f.campaign('batch',0)]);await f.advance(0);assert.deepEqual(f.stats.dispatches,['batch','batch']);f.emit('adminCampaigns',[f.campaign('batch',0,true)]);await f.advance(86400000);assert.equal(f.stats.dispatches.length,2);f.worker.stop();assert.equal(f.listeners.size,0);
});
test('late callbacks after shutdown cannot dispatch notifications',async()=>{
 const f=fixture();await f.worker.start();const listener=f.listeners.get('notifications');f.worker.stop();listener.next({docs:[f.notice()]});await flush();assert.equal(f.stats.sent,0);assert.equal(f.listeners.size,0);
});

test('campaign snapshot updates cannot bypass the retry delay after failure',async()=>{
 const f=fixture();let attempts=0;f.admin.dispatchCampaign=async()=>{attempts++;throw new Error('temporary failure');};
 await f.worker.start();f.emit('adminCampaigns',[f.campaign('retry',0)]);await f.advance(0);assert.equal(attempts,1);
 f.emit('adminCampaigns',[f.campaign('retry',0)]);await f.advance(0);assert.equal(attempts,1);
 await f.advance(30000);assert.equal(attempts,2);f.worker.stop();
});
