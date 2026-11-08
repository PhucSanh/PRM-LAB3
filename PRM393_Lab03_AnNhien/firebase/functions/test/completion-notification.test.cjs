'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
const {createNotificationEvents}=require('../notification-events.cjs');
function fixture(){
 const state=new Map([
 ['users/parent/caregivers/child',{}],['users/parent/caregivers/unpaired',{}],
 ['users/child',{pairedMomUid:'parent'}],['users/unpaired',{pairedMomUid:'different'}],
 ['users/parent/completions/walk_2026-11-08',{status:'done'}],
 ]);
 const ref=path=>({path});const snapshot=r=>({exists:state.has(r.path),data:()=>state.get(r.path)});
 const db={doc:ref,collection:path=>({get:async()=>({docs:[...state.keys()].filter(k=>k.startsWith(path+'/')&&k.slice(path.length+1).indexOf('/')<0).map(k=>({id:k.split('/').at(-1),ref:ref(k)}))})}),
 runTransaction:async fn=>fn({get:async r=>snapshot(r),create:(r,data)=>{assert.ok(!state.has(r.path));state.set(r.path,data);}})};
 return {state,events:createNotificationEvents(db),notices:()=>[...state].filter(([k])=>k.includes('/notifications/'))};
}
const event={ownerUid:'parent',completionId:'walk_2026-11-08',after:{taskId:'walk',date:'2026-11-08',status:'done'}};
test('completion alerts only mutually linked caregiver, once, with dated calendar target',async()=>{
 const f=fixture();await f.events.completed(event);await f.events.completed(event);
 assert.equal(f.notices().length,1);const [path,item]=f.notices()[0];
 assert.ok(path.startsWith('users/child/notifications/'));assert.equal(item.event,'task_completed');
 assert.equal(item.parentUid,'parent');assert.equal(item.route,'/caregiver/schedule?date=2026-11-08');
});
test('skip, undo and revoked family link do not notify',async()=>{
 const f=fixture();for(const status of ['pending','skipped','postponed'])await f.events.completed({...event,after:{...event.after,status}});
 f.state.delete('users/parent/caregivers/child');await f.events.completed(event);assert.equal(f.notices().length,0);
});
