'use strict';
const http=require('node:http');const path=require('node:path');const fs=require('node:fs');
const {createHmac,randomBytes,scryptSync,timingSafeEqual}=require('node:crypto');
const {HttpsError}=require('firebase-functions/v2/https');
const {createDomain,DomainError}=require('./domain.cjs');
const {createAdminService}=require('./admin.cjs');
const {createNotificationEvents}=require('./notification-events.cjs');
const {createRealWorker}=require('./real-worker.cjs');
const {initializeRealFirebase}=require('./real-runtime.cjs');
const hash=(password,salt)=>scryptSync(password,salt,32);
function createSessionAuth(password,{now=Date.now}={}){
 if(!password)throw new Error('Set ADMIN_LOGIN_PASSWORD in the server environment.');
 const secret=randomBytes(32),salt=randomBytes(16),expected=hash(password,salt),attempts=new Map();
 function sign(){const payload=Buffer.from(JSON.stringify({uid:'local-admin',admin:true,exp:now()+8*3600000})).toString('base64url');return payload+'.'+createHmac('sha256',secret).update(payload).digest('base64url');}
 return {
  login(username,password,ip){const record=attempts.get(ip);if(record&&now()-record.since<900000&&record.count>=5)throw new HttpsError('resource-exhausted','Thử quá nhiều lần. Chờ 15 phút.');if(attempts.size>1000)for(const [k,v]of attempts)if(now()-v.since>=900000)attempts.delete(k);if(attempts.size>2000)throw new HttpsError('resource-exhausted','Vui lòng thử lại sau.');attempts.set(ip,record&&now()-record.since<900000?{...record,count:record.count+1}:{since:now(),count:1});if(username!=='admin'||typeof password!=='string'||password.length>256||!timingSafeEqual(hash(password,salt),expected))throw new HttpsError('unauthenticated','Tài khoản hoặc mật khẩu không đúng.');return {token:sign()};},
  verify(token){try{const [payload,signature,...rest]=token.split('.');if(rest.length||!payload||!signature)return null;const expected=createHmac('sha256',secret).update(payload).digest(),actual=Buffer.from(signature,'base64url');if(actual.length!==expected.length||!timingSafeEqual(actual,expected))return null;const data=JSON.parse(Buffer.from(payload,'base64url'));return data.admin===true&&data.exp>now()?{uid:data.uid,token:{admin:true}}:null;}catch{return null;}}
 };
}
function createHandler({db,auth,admin,worker,password,webRoot,extraRoutes={},allowedOrigins=[]}){
 const sessions=createSessionAuth(password),domain=createDomain(db),events=createNotificationEvents(db);
 const routes={
  adminDashboard:(a,d)=>admin.dashboard(a,d),adminCreateCampaign:(a,d)=>admin.createCampaign(a,d),adminCancelCampaign:(a,d)=>admin.cancelCampaign(a,d),recordAppActivity:(a)=>admin.recordActivity(a),
  createPairing:a=>domain.createPairing(a?.uid),
  redeemPairing:(a,d)=>domain.redeemPairing(a?.uid,d.code),
  revokePairing:async(a,d)=>{const grant=typeof d.momUid==='string'&&typeof d.childUid==='string'&&!d.momUid.includes('/')&&!d.childUid.includes('/')?await db.doc(`users/${d.momUid}/caregivers/${d.childUid}`).get():null;const result=await domain.revokePairing(a?.uid,d.momUid,d.childUid);if(grant?.exists)await events.pairingChanged({eventId:grant.ref.path+':revoke:'+grant.data().createdAt?.toMillis(),ownerUid:d.momUid,childUid:d.childUid,before:grant.data(),after:null});return result;},
  sendSuggestion:(a,d)=>domain.sendSuggestion(a?.uid,d),resolveSuggestion:(a,d)=>domain.resolveSuggestion(a?.uid,d),undoDismiss:(a,d)=>domain.undoDismiss(a?.uid,d),...extraRoutes
 };
 return async(req,res)=>{
  res.setHeader('X-Content-Type-Options','nosniff');res.setHeader('Cache-Control','no-store');
  const origin=req.headers.origin;if(origin&&allowedOrigins.includes(origin)){res.setHeader('Access-Control-Allow-Origin',origin);res.setHeader('Vary','Origin');res.setHeader('Access-Control-Allow-Headers','Content-Type, Authorization, X-Firebase-AppCheck, Firebase-Instance-ID-Token');res.setHeader('Access-Control-Allow-Methods','GET, POST, OPTIONS');}
  const json=(status,value)=>{res.writeHead(status,{'Content-Type':'application/json; charset=utf-8'});res.end(JSON.stringify(value));};
  if(req.method==='OPTIONS'){res.writeHead(origin&&allowedOrigins.includes(origin)?204:403);res.end();return;}
  const url=new URL(req.url,'http://localhost');
  if(url.pathname==='/health'){json(200,{ok:true,projectId:db.projectId,environment:'firebase-real'});return;}
  if(url.pathname.startsWith('/api/')){
   if(req.method!=='POST'){json(405,{error:{status:'INVALID_ARGUMENT',message:'POST required'}});return;}
   if(origin&&!allowedOrigins.includes(origin)){json(403,{error:{status:'PERMISSION_DENIED',message:'Origin is not allowed.'}});return;}
   try{
    let raw='';for await(const chunk of req){raw+=chunk;if(Buffer.byteLength(raw)>65536)throw new HttpsError('invalid-argument','Nội dung quá lớn.');}
    let data;try{data=JSON.parse(raw).data;}catch{throw new HttpsError('invalid-argument','JSON không hợp lệ.');}
    if(!data||typeof data!=='object'||Array.isArray(data))throw new HttpsError('invalid-argument','Dữ liệu không hợp lệ.');
    const name=url.pathname.slice(5);
    if(name==='adminSignIn'){json(200,{result:sessions.login(data.username,data.password,req.socket.remoteAddress)});return;}
    if(!Object.hasOwn(routes,name))throw new HttpsError('not-found','API không tồn tại.');
    const bearer=/^Bearer (\S+)$/.exec(req.headers.authorization||'')?.[1];if(!bearer)throw new HttpsError('unauthenticated','Vui lòng đăng nhập.');
    let actor=sessions.verify(bearer);if(!actor){try{const decoded=await auth.verifyIdToken(bearer,true);actor={uid:decoded.uid,token:decoded};}catch{throw new HttpsError('unauthenticated','Phiên đăng nhập hết hạn.');}}
    if(actor.uid==='local-admin'&&!name.startsWith('admin'))throw new HttpsError('permission-denied','Admin session cannot impersonate an app user.');
    const result=await routes[name](actor,data);json(200,{result});
   }catch(error){const known=error instanceof HttpsError||error instanceof DomainError,code=known?error.code:'internal';const httpCode={unauthenticated:401,'permission-denied':403,'not-found':404,'invalid-argument':400,'resource-exhausted':429,'failed-precondition':400,'already-exists':409}[code]||500;json(httpCode,{error:{status:code.toUpperCase().replaceAll('-','_'),message:known?error.message:'Chưa thực hiện được. Vui lòng thử lại.'}});if(!known)console.error('API failure',{code:error.code||'internal'});}
   return;
  }
  if(!['GET','HEAD'].includes(req.method)){res.writeHead(405);res.end();return;}
  const publicFiles={'/':'index.html','/index.html':'index.html','/app.js':'app.js','/styles.css':'styles.css','/firebase-config.js':'firebase-config.js','/firebase-client.js':'firebase-client.js','/real-client.js':'real-client.js'};
  if(url.pathname==='/runtime-config.js'){res.writeHead(200,{'Content-Type':'text/javascript'});res.end('window.ADMIN_REST_API=true;window.ADMIN_USE_EMULATORS=false;window.ADMIN_API_BASE=location.origin;');return;}
  const file=publicFiles[url.pathname];if(!file){res.writeHead(404);res.end();return;}
  let content=fs.readFileSync(path.join(webRoot,file));if(file==='index.html')content=content.toString().replace('<script src="app.js">','<script src="runtime-config.js"></script><script src="app.js">');res.writeHead(200,{'Content-Type':file.endsWith('.css')?'text/css':file.endsWith('.js')?'text/javascript':'text/html; charset=utf-8'});res.end(req.method==='HEAD'?undefined:content);
 };
}
async function start(){
 const envFile=path.join(__dirname,'.env.real');if(fs.existsSync(envFile))process.loadEnvFile(envFile);
 const runtime=initializeRealFirebase(),admin=createAdminService(runtime.db);
 // Fail before opening the admin screen if real DB authorization is missing.
 await runtime.db.collection('users').limit(1).get();
 const worker=createRealWorker(runtime.db,runtime.messaging,admin);
 const {createAssistantService}=require('./assistant.cjs');const {createVoiceTaskService}=require('./voice-task.cjs');
 const ai={getKey:()=>process.env.GROQ_API_KEY||'',getModel:()=>process.env.GROQ_VOICE_MODEL||'openai/gpt-oss-20b'};
 const assistant=createAssistantService(runtime.db,ai),voice=createVoiceTaskService(runtime.db,ai);
 const host=process.env.HOST||'127.0.0.1',port=Number(process.env.PORT||3000);
 const localOrigins=[`http://localhost:${port}`,`http://127.0.0.1:${port}`,...Object.values(require('node:os').networkInterfaces()).flat().filter(x=>x.family==='IPv4'&&!x.internal).map(x=>`http://${x.address}:${port}`)];
 const origins=[...localOrigins,...(process.env.ALLOWED_ORIGINS||'').split(',').map(s=>s.trim()).filter(Boolean)];
 const server=http.createServer(createHandler({...runtime,admin,worker,password:process.env.ADMIN_LOGIN_PASSWORD,webRoot:path.resolve(__dirname,'../../admin-web'),allowedOrigins:origins,extraRoutes:{talkToAssistant:(a,d)=>assistant(a.uid,d),interpretVoiceTask:(a,d)=>voice(a.uid,d)}}));
 await worker.tick();const timer=setInterval(()=>worker.tick(),10000);
 server.listen(port,host,()=>console.log(`An Nhien REAL Firebase (${runtime.projectId}) — http://${host}:${port}`));
 const stop=()=>{clearInterval(timer);server.close(()=>process.exit(0));};process.once('SIGINT',stop);process.once('SIGTERM',stop);
}
if(require.main===module)start().catch(error=>{console.error('Real backend startup failed',{code:error.code||'startup',message:error.message?.slice(0,300)});process.exitCode=1;});
module.exports={createHandler,createSessionAuth};
