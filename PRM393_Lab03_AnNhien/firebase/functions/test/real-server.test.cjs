'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');const http=require('node:http');const path=require('node:path');
const {createSessionAuth,createHandler}=require('../real-server.cjs');const {requireAdmin}=require('../admin.cjs');
test('admin session rejects forgery, expires, and rate limits wrong passwords',()=>{
 let time=1000000;const session=createSessionAuth('fixture-pass',{now:()=>time});
 assert.throws(()=>session.login('admin','wrong','ip'),e=>e.code==='unauthenticated');
 const {token}=session.login('admin','fixture-pass','ip');assert.equal(session.verify(token).token.admin,true);assert.equal(session.verify(token+'bad'),null);assert.equal(session.verify('garbage'),null);
 time+=9*3600000;assert.equal(session.verify(token),null);
 for(let i=0;i<5;i++)assert.throws(()=>session.login('admin','wrong','other'),e=>e.code==='unauthenticated');
 assert.throws(()=>session.login('admin','fixture-pass','other'),e=>e.code==='resource-exhausted');
});
async function fixture(t){
 const calls=[];const handler=createHandler({db:{projectId:'test-real'},auth:{verifyIdToken:async token=>{assert.equal(token,'firebase-user-token');return {uid:'app-user'};}},admin:{dashboard:async(a,d)=>{requireAdmin(a);return {source:'firestore',period:d.period};},createCampaign:async(a,d)=>{requireAdmin(a);calls.push(d);return {id:'real-campaign'};},recordActivity:async a=>{calls.push(a.uid);return {ok:true};}},worker:{},password:'fixture-pass',webRoot:path.resolve(__dirname,'../../../admin-web'),allowedOrigins:['http://allowed.test']});
 const server=http.createServer(handler);await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));t.after(()=>new Promise(resolve=>server.close(resolve)));const base=`http://127.0.0.1:${server.address().port}`;
 const call=async(name,data={},token,origin)=>{const response=await fetch(base+'/api/'+name,{method:'POST',headers:{'Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{}),...(origin?{Origin:origin}:{})},body:JSON.stringify({data})});return {status:response.status,body:await response.json()};};return {base,call,calls};
}
test('real HTTP admin login and dashboard use server session without Firebase custom token',async t=>{
 const f=await fixture(t),login=await f.call('adminSignIn',{username:'admin',password:'fixture-pass'});assert.equal(login.status,200);const token=login.body.result.token;
 assert.equal((await f.call('adminDashboard',{},null)).status,401);
 const dashboard=await f.call('adminDashboard',{period:'month'},token);assert.equal(dashboard.status,200);assert.equal(dashboard.body.result.source,'firestore');assert.equal(dashboard.body.result.period,'month');
 const campaign=await f.call('adminCreateCampaign',{title:'real request'},token);assert.equal(campaign.body.result.id,'real-campaign');assert.equal(f.calls[0].title,'real request');
 assert.equal((await f.call('recordAppActivity',{},token)).status,403);
});
test('APK Firebase ID token is verified and cannot access admin endpoints',async t=>{
 const f=await fixture(t);assert.equal((await f.call('recordAppActivity',{},'firebase-user-token')).status,200);assert.deepEqual(f.calls,['app-user']);assert.equal((await f.call('adminDashboard',{},'firebase-user-token')).status,403);assert.equal((await f.call('adminDashboard',{},'forged')).status,401);
});
test('HTTP server rejects foreign origins, invalid JSON, oversized payload and file traversal',async t=>{
 const f=await fixture(t);assert.equal((await f.call('adminSignIn',{},null,'https://evil.test')).status,403);
 let response=await fetch(f.base+'/api/adminSignIn',{method:'POST',body:'{'});assert.equal(response.status,400);
 response=await fetch(f.base+'/api/adminSignIn',{method:'POST',body:'x'.repeat(70000)});assert.equal(response.status,400);
 assert.equal((await fetch(f.base+'/real-server.cjs')).status,404);assert.equal((await fetch(f.base+'/.env.real')).status,404);
 const html=await (await fetch(f.base)).text();assert.ok(html.includes('runtime-config.js'));assert.ok(!(await(await fetch(f.base+'/runtime-config.js')).text()).includes('ADMIN_LOGIN_PASSWORD'));
});
test('real runtime refuses emulator configuration',()=>{
 const {initializeRealFirebase}=require('../real-runtime.cjs');const old=process.env.FIRESTORE_EMULATOR_HOST;process.env.FIRESTORE_EMULATOR_HOST='localhost:8080';try{assert.throws(()=>initializeRealFirebase(),/refuses emulator/);}finally{if(old===undefined)delete process.env.FIRESTORE_EMULATOR_HOST;else process.env.FIRESTORE_EMULATOR_HOST=old;}
});
