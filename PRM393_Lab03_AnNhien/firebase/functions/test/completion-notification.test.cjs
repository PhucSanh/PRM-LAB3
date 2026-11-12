'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
const {createNotificationEvents}=require('../notification-events.cjs');
function fixture(){
 const state=new Map([
 ['users/parent/caregivers/child',{}],['users/parent/caregivers/unpaired',{}],
 ['users/parent',{displayName:'Bà Lan'}],['users/child',{pairedMomUid:'parent'}],['users/unpaired',{pairedMomUid:'different'}],
 ['users/parent/tasks/walk',{creatorUid:'child',title:'Đi bộ buổi sáng'}],
 ['users/parent/completions/walk_2026-11-08',{status:'done'}],
 ]);
 const ref=path=>({path});const snapshot=r=>({exists:state.has(r.path),data:()=>state.get(r.path)});
 const db={doc:ref,collection:path=>({get:async()=>({docs:[...state.keys()].filter(k=>k.startsWith(path+'/')&&k.slice(path.length+1).indexOf('/')<0).map(k=>({id:k.split('/').at(-1),ref:ref(k)}))})}),
 runTransaction:async fn=>fn({get:async r=>snapshot(r),create:(r,data)=>{assert.ok(!state.has(r.path));state.set(r.path,data);}})};
 return {state,events:createNotificationEvents(db),notices:()=>[...state].filter(([k])=>k.includes('/notifications/'))};
}
const event={ownerUid:'parent',completionId:'walk_2026-11-08',after:{taskId:'walk',date:'2026-11-08',status:'done'}};
test('completion alerts only the activity creator, once, with detail target',async()=>{
 const f=fixture();await f.events.completed(event);await f.events.completed(event);
 assert.equal(f.notices().length,1);const [path,item]=f.notices()[0];
 assert.ok(path.startsWith('users/child/notifications/'));assert.equal(item.event,'task_completed');
 assert.equal(item.parentUid,'parent');assert.equal(item.route,'/caregiver/task/walk?date=2026-11-08');
 assert.match(item.title,/Bà Lan đã hoàn thành: Đi bộ buổi sáng/);
});
test('skip, undo and revoked family link do not notify',async()=>{
 const f=fixture();for(const status of ['pending','skipped','postponed'])await f.events.completed({...event,after:{...event.after,status}});
 f.state.delete('users/parent/caregivers/child');await f.events.completed(event);assert.equal(f.notices().length,0);
});
test('does not notify another linked caregiver or legacy activity without a creator',async()=>{
 const f=fixture();f.state.set('users/parent/caregivers/other',{});f.state.set('users/other',{pairedMomUid:'parent'});
 await f.events.completed(event);assert.equal(f.notices().length,1);
 const legacy=fixture();legacy.state.set('users/parent/tasks/walk',{title:'Đi bộ'});await legacy.events.completed(event);assert.equal(legacy.notices().length,0);
});
