'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {validateInput,normalizeResult,callGroq,createVoiceTaskService,systemPrompt} = require('../voice-task.cjs');
const now = Date.UTC(2026,10,6,4,30); // 11:30 Vietnam
const proposal = {title:'Tưới cây',date:'2026-11-07',hour:8,minute:0,repeat:'daily',weekdays:[],habitKey:'move',issue:'none'};
const response = value => ({ok:true,json:async()=>({choices:[{finish_reason:'stop',message:{content:JSON.stringify(value)}}]})});

test('voice input bounds conversation and rejects invalid real dates',()=>{
  assert.deepEqual(validateInput({utterances:[' mai tưới cây ']}),{utterances:['mai tưới cây'],contextDate:null});
  for(const data of [{utterances:[]},{utterances:['x'.repeat(501)]},{utterances:['a','b','c','d','e']},
    {utterances:[42]},{utterances:['a'],contextDate:'2026-02-31'}]) assert.throws(()=>validateInput(data),e=>e.code==='invalid-argument');
});
test('voice draft is ready only with complete future data and recurrence',()=>{
  assert.equal(normalizeResult(proposal,now).ready,true);
  for(const patch of [{title:null},{date:null},{hour:null},{minute:null},{date:'2026-11-06',hour:8},
    {repeat:'weekly',weekdays:[]},{issue:'ambiguous'},{issue:'multiple'},{issue:'unsupported'}]) {
    const result=normalizeResult({...proposal,...patch},now);
    assert.equal(result.ready,false);assert.ok(result.question);
  }
  const weekly=normalizeResult({...proposal,repeat:'someDays',weekdays:[5,1,1]},now);
  assert.deepEqual(weekly.draft.weekdays,[1,5]);
});
test('voice response validation rejects schema or calendar errors',()=>{
  for(const patch of [{date:'2026-02-31'},{date:'tomorrow'},{hour:24},{minute:60},{hour:8.5},{title:'x'.repeat(81)},
    {repeat:'forever'},{habitKey:'admin'},{weekdays:[0]},{execute:true},{issue:'delete'}])
    assert.throws(()=>normalizeResult({...proposal,...patch},now),e=>e.code==='data-loss');
});
test('Vietnam time is used at midnight and past timestamps never become ready',()=>{
  const late = Date.UTC(2026,11,31,17,1); // Jan 1, 2027 in Vietnam
  assert.match(systemPrompt(late),/2027-01-01T00:01/);
  assert.equal(normalizeResult({...proposal,date:'2026-12-31',hour:23},late).ready,false);
  assert.equal(normalizeResult({...proposal,date:'2027-01-01',hour:8},late).ready,true);
});
test('Groq request contains strict schema, bounded output and only text context',async()=>{
  let calls=0;
  const input=validateInput({utterances:['Mai 8 giờ tưới cây','Buổi sáng'],contextDate:'2026-11-07'});
  const result=await callGroq(input,{apiKey:'test-key',now,fetchImpl:async(url,options)=>{
    calls++;assert.equal(url,'https://api.groq.com/openai/v1/chat/completions');
    const body=JSON.parse(options.body);
    assert.equal(body.response_format.json_schema.strict,true);
    assert.equal(body.response_format.json_schema.schema.additionalProperties,false);
    assert.equal(body.max_completion_tokens,2048);
    assert.deepEqual(JSON.parse(body.messages[1].content),input);
    assert.match(body.messages[0].content,/hour=null/);
    assert.equal(options.headers.Authorization,'Bearer test-key');
    return response(proposal);
  }});
  assert.equal(calls,1);assert.equal(result.ready,true);
});
test('provider failures redact body, auth headers and transcripts',async()=>{
  for(const status of [400,401,429,500]) {
    await assert.rejects(callGroq({utterances:['private transcript']},{apiKey:'secret',now,
      fetchImpl:async()=>({ok:false,status,json:()=>{throw new Error('secret provider body');}})}),e=>{
      assert.ok(!e.message.includes('secret'));assert.ok(!e.message.includes('private'));return true;
    });
  }
  await assert.rejects(callGroq({}, {apiKey:'secret',now,fetchImpl:async()=>{throw new Error('secret');}}),e=>e.code==='unavailable');
  await assert.rejects(callGroq({}, {apiKey:'secret',now,fetchImpl:async()=>({ok:true,json:async()=>({choices:[{finish_reason:'length',message:{content:JSON.stringify(proposal)}}]})})}),e=>e.code==='data-loss');
  await assert.rejects(callGroq({}, {apiKey:'secret',now,fetchImpl:async()=>response({bad:true})}),e=>e.code==='data-loss');
});
test('unauthenticated, malformed and missing-key requests never access quota or Groq',async()=>{
  const db={doc:()=>{throw new Error('must not access database');}};
  const service=createVoiceTaskService(db,{getKey:()=>'',fetchImpl:()=>{throw new Error('must not call Groq');}});
  await assert.rejects(service(null,{utterances:['a']}),e=>e.code==='unauthenticated');
  await assert.rejects(service('user',{utterances:[]}),e=>e.code==='invalid-argument');
  await assert.rejects(service('user',{utterances:['a']}),e=>e.code==='failed-precondition');
});
test('voice userContext carries only honorific, wake time and untitled busy slots',()=>{
  const ctx={honorific:'ba',wakeTime:'05:30',busy:[{time:'09:30',durationMinutes:30,habitKey:'move'}]};
  assert.deepEqual(validateInput({utterances:['mai tập'],userContext:ctx}).userContext,ctx);
  assert.deepEqual(validateInput({utterances:['mai tập'],userContext:{}}).userContext,{honorific:null,wakeTime:null,busy:[]});
  for(const bad of [{title:'x'},{honorific:'admin'},{wakeTime:'25:00'},{wakeTime:'5:30'},
    {busy:[{time:'09:30',durationMinutes:30,habitKey:'move',title:'Đi bộ'}]},
    {busy:[{time:'09:30',durationMinutes:0,habitKey:'move'}]},
    {busy:Array.from({length:21},()=>({time:'09:30',durationMinutes:30,habitKey:'move'}))},'text',[]])
    assert.throws(()=>validateInput({utterances:['mai tập'],userContext:bad}),e=>e.code==='invalid-argument');
  assert.match(systemPrompt(now),/wakeTime \+ 60/);
});
