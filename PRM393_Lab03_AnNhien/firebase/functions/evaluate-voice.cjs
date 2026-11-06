'use strict';
// Optional live semantic evaluation. No Firebase writes; run only after a key is configured.
const {callGroq,validateInput} = require('./voice-task.cjs');
const cases = [
  {id:'tomorrow-daily',now:Date.UTC(2026,10,6,4,30),utterances:['Mai lúc 8 giờ sáng nhắc bác tưới cây, mỗi ngày nhé.'],check:r=>r.ready&&r.draft.date==='2026-11-07'&&r.draft.hour===8&&r.draft.repeat==='daily'},
  {id:'ambiguous-eight',now:Date.UTC(2026,10,6,4,30),utterances:['Mai 8 giờ nhắc bác tưới cây.'],check:r=>!r.ready&&r.draft.hour===null},
  {id:'clarify-morning',now:Date.UTC(2026,10,6,4,30),utterances:['Mai 8 giờ nhắc bác tưới cây.','8 giờ sáng'],check:r=>r.ready&&r.draft.date==='2026-11-07'&&r.draft.hour===8},
  {id:'missing-date',now:Date.UTC(2026,10,6,4,30),utterances:['8 giờ sáng nhắc bác đi bộ.'],check:r=>!r.ready&&r.draft.date===null},
  {id:'tonight',now:Date.UTC(2026,10,6,4,30),utterances:['Tối nay lúc 8 giờ nhắc bác gọi con.'],check:r=>r.ready&&r.draft.date==='2026-11-06'&&r.draft.hour===20},
  {id:'year-boundary',now:Date.UTC(2026,11,31,4,30),utterances:['Mai 9 giờ sáng nhắc bác đi bộ.'],check:r=>r.ready&&r.draft.date==='2027-01-01'&&r.draft.hour===9},
  {id:'unsupported-delete',now:Date.UTC(2026,10,6,4,30),utterances:['Xoá hết lịch của bác.'],check:r=>!r.ready},
  {id:'multiple-tasks',now:Date.UTC(2026,10,6,4,30),utterances:['Mai 8 giờ sáng tưới cây, 9 giờ sáng đi bộ.'],check:r=>!r.ready},
];
async function main() {
  const apiKey=process.env.GROQ_API_KEY;
  if(!apiKey || apiKey==='replace_with_your_groq_key') throw new Error('Configure GROQ_API_KEY on this machine before running live evaluation.');
  let failures=0;
  for(const [index,c] of cases.entries()) {
    // Pace the live suite so provider TPM/RPM limits are not semantic failures.
    if(index) await new Promise(resolve=>setTimeout(resolve,12000));
    try {
      let result;
      for(let attempt=0;attempt<3;attempt++) {
        try {
          result=await callGroq(validateInput({utterances:c.utterances}),{
            apiKey,model:process.env.GROQ_VOICE_MODEL||'openai/gpt-oss-20b',now:c.now});
          break;
        } catch(error) {
          if(error.code!=='resource-exhausted' || attempt===2) throw error;
          console.log(`WAIT ${c.id} (provider rate limit)`);
          await new Promise(resolve=>setTimeout(resolve,30000));
        }
      }
      const passed=c.check(result);if(!passed)failures++;
      console.log(`${passed?'PASS':'FAIL'} ${c.id}`);
    } catch (error) {
      failures++;
      // Only expose an allowlisted code; provider responses and keys stay private.
      const code=['unavailable','resource-exhausted','data-loss','invalid-argument','failed-precondition'].includes(error.code) ? error.code : 'unknown';
      console.log(`FAIL ${c.id} (${code})`);
    }
  }
  console.log(`${cases.length-failures}/${cases.length} live cases passed; no tasks written.`);
  process.exitCode=failures?1:0;
}
main().catch(()=>{console.error('Live evaluation requires a configured Groq key and network. No task was written.');process.exitCode=1;});
