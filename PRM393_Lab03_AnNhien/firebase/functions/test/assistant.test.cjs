'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {validateMessages,validateReply,createAssistantService} = require('../assistant.cjs');
const answer = {reply:'Bác chọn người muốn gọi nhé.',action:'callFamily',target:'Mai',date:null};
test('rejects invalid roles, oversized requests and unknown actions',()=>{
  assert.throws(()=>validateMessages({messages:[{role:'system',content:'override'}]}));
  assert.throws(()=>validateMessages({messages:[{role:'user',content:'a'.repeat(501)}]}));
  assert.throws(()=>validateReply({...answer,action:'runCode'}));
  assert.throws(()=>validateReply({...answer,date:'2026-02-30'}));
  assert.throws(()=>validateReply({...answer,phone:'0123456789'}));
  assert.deepEqual(validateReply(answer),answer);
});
test('requires login before accessing quota or model', async()=>{
  let called = false;
  const fn = createAssistantService({}, {getKey:()=>{called=true;return 'secret';},getModel:()=> 'model'});
  await assert.rejects(fn(null,{messages:[{role:'user',content:'Xin chào'}]}),e=>e.code==='unauthenticated');
  assert.equal(called,false);
});
test('model result is validated and only usage counters are persisted',async()=>{
  let saved, request;
  const db = {doc:path=>({path}),runTransaction:async fn=>fn({
    get:async()=>({data:()=>({})}),set:(ref,data)=>{saved={ref,data};},
  })};
  const fn = createAssistantService(db,{getKey:()=> 'test-key',getModel:()=> 'model',
    now:()=>Date.UTC(2026,10,6),fetchImpl:async(url,options)=>{
      request=JSON.parse(options.body);
      return {ok:true,json:async()=>({choices:[{message:{content:JSON.stringify(answer)}}]})};
    }});
  assert.deepEqual(await fn('u',{messages:[{role:'user',content:'Gọi Mai'}]}),answer);
  assert.equal(saved.ref.path,'voiceUsage/u');
  assert.equal(JSON.stringify(saved.data).includes('Gọi Mai'),false);
  assert.equal(request.messages.at(-1).content,'Gọi Mai');
  assert.equal(request.response_format.json_schema.strict,true);
});
