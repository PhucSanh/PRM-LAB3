const version='12.5.0';
const base=`https://www.gstatic.com/firebasejs/${version}`;
const bridge={ready:false,user:null,snapshot:null,requestId:null};
window.adminBackend=bridge;
const panel=document.querySelector('#auth-panel'),message=document.querySelector('#auth-message');
const status=text=>{message.textContent=text;};
function lock(text){panel.hidden=false;document.querySelector('.shell').hidden=true;status(text);}
try{
 const [{initializeApp},{getAuth,onAuthStateChanged,GoogleAuthProvider,signInWithPopup,signInWithCustomToken,signOut,connectAuthEmulator},{getFunctions,httpsCallable,connectFunctionsEmulator}]=await Promise.all([import(`${base}/firebase-app.js`),import(`${base}/firebase-auth.js`),import(`${base}/firebase-functions.js`)]);
 const app=initializeApp(window.ADMIN_FIREBASE_CONFIG),auth=getAuth(app),functions=getFunctions(app,window.ADMIN_FUNCTIONS_REGION);
 if(window.ADMIN_USE_EMULATORS){document.querySelector('.demo-badge').textContent='● Firebase Emulator';document.querySelector('.auth-panel>small').textContent='Môi trường local · Dữ liệu emulator, không phải production';connectAuthEmulator(auth,'http://127.0.0.1:9099');connectFunctionsEmulator(functions,'127.0.0.1',5001);}
 const call=async(name,data)=>(await httpsCallable(functions,name)(data)).data;
 let requestVersion=0;
 bridge.refresh=async(period='week')=>{
  const v=++requestVersion;document.querySelector('#data-status').textContent='Đang tải từ Firestore…';
  try{const snapshot=await call('adminDashboard',{period});if(v!==requestVersion)return;bridge.snapshot=snapshot;window.dispatchEvent(new CustomEvent('admin-data',{detail:snapshot}));document.querySelector('#data-status').textContent=`${window.ADMIN_USE_EMULATORS?'Firestore Emulator':'Firestore'} · Cập nhật ${new Date(snapshot.generatedAt).toLocaleTimeString('vi-VN')}`;}
  catch(error){if(v!==requestVersion)return;document.querySelector('#data-status').textContent='Tải dữ liệu thất bại';window.dispatchEvent(new CustomEvent('admin-error',{detail:error.message}));throw error;}
 };
 bridge.createCampaign=async(data)=>{
  bridge.requestId ||= crypto.randomUUID();
  const result=await call('adminCreateCampaign',{...data,requestId:bridge.requestId});bridge.requestId=null;return result;
 };
 bridge.cancelCampaign=id=>call('adminCancelCampaign',{id});
 document.querySelector('#google-login').addEventListener('click',async()=>{try{status('Đang đăng nhập…');await signInWithPopup(auth,new GoogleAuthProvider());}catch{status('Không đăng nhập được. Kiểm tra Google provider và Authorized domains trong Firebase Auth.');}});
 document.querySelector('#login-form').addEventListener('submit',async e=>{e.preventDefault();try{status('Đang đăng nhập…');const {token}=await call('adminSignIn',{username:document.querySelector('#login-username').value,password:document.querySelector('#login-password').value});await signInWithCustomToken(auth,token);document.querySelector('#login-password').value='';}catch(error){status(error.code==='functions/resource-exhausted'?'Thử quá nhiều lần. Vui lòng đợi 15 phút.':'Không đăng nhập được. Kiểm tra tài khoản; backend production hiện còn chờ triển khai do project Spark (cần Blaze).');}});
 document.querySelector('#logout').addEventListener('click',()=>signOut(auth));
 document.querySelector('#refresh-data').addEventListener('click',()=>bridge.refresh(window.adminSelectedPeriod||'week').catch(()=>{}));
 onAuthStateChanged(auth,async user=>{
  bridge.ready=false;bridge.user=null;bridge.snapshot=null;requestVersion++;
  if(!user){lock('Đăng nhập bằng tài khoản đã được cấp quyền admin.');return;}
  try{const token=await user.getIdTokenResult(true);if(token.claims.admin!==true){lock('Tài khoản chưa có custom claim admin. Liên hệ chủ dự án để cấp quyền bằng Admin SDK.');const out=document.createElement('button');out.textContent='Đăng xuất để đổi tài khoản';out.type='button';out.onclick=()=>signOut(auth);message.append(document.createElement('br'),out);return;}
   bridge.user=user;bridge.ready=true;panel.hidden=true;document.querySelector('.shell').hidden=false;await bridge.refresh(window.adminSelectedPeriod||'week');
  }catch{lock('Chưa kết nối được backend. Kiểm tra đã deploy Functions và cấu hình Firebase.');}
 });
}catch{lock('Không tải được Firebase SDK. Kiểm tra kết nối mạng rồi tải lại trang.');}
