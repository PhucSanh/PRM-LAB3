'use strict';
const path=require('node:path');
const {initializeApp,applicationDefault,cert}=require('firebase-admin/app');
const {getAuth}=require('firebase-admin/auth');
const {getMessaging}=require('firebase-admin/messaging');
function initializeRealFirebase(){
 if(['FIRESTORE_EMULATOR_HOST','FIREBASE_AUTH_EMULATOR_HOST','FIREBASE_EMULATOR_HUB'].some(k=>process.env[k]))throw new Error('Real server refuses emulator environment variables.');
 const projectId=process.env.FIREBASE_PROJECT_ID||'prm393-145c9';
 if(projectId.startsWith('demo-'))throw new Error('Real server requires a real project.');
 let app,db;
 if(process.env.FIREBASE_SERVICE_ACCOUNT_JSON){
  let account;try{account=JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);}catch{throw new Error('Invalid service-account secret JSON.');}
  if(account.project_id!==projectId)throw new Error('Service account must belong to the configured Firebase project.');
  app=initializeApp({projectId,credential:cert(account)});db=require('firebase-admin/firestore').getFirestore(app);
 }else if(process.env.USE_FIREBASE_CLI_CREDENTIAL==='1'){
  // Development only: reuse the account already authorized by `firebase login`.
  // Refresh tokens remain in memory and in the CLI's existing credential store.
  const auth=require('../tests/node_modules/firebase-tools/lib/auth');
  const api=require('../tests/node_modules/firebase-tools/lib/api');
  const account=auth.getGlobalDefaultAccount();
  if(!account?.tokens?.refresh_token)throw new Error('Run firebase login first, or configure GOOGLE_APPLICATION_CREDENTIALS.');
  const {GoogleAuth}=require('google-auth-library');
  const {Firestore}=require('@google-cloud/firestore');
  const googleAuth=new GoogleAuth({projectId,scopes:['https://www.googleapis.com/auth/cloud-platform'],credentials:{type:'authorized_user',client_id:api.clientId(),client_secret:api.clientSecret(),refresh_token:account.tokens.refresh_token}});
  const credential={getAccessToken:async()=>{const client=await googleAuth.getClient();const {token}=await client.getAccessToken();return {access_token:token,expires_in:Math.max(1,Math.floor(((client.credentials.expiry_date||Date.now()+3600000)-Date.now())/1000))};}};
  app=initializeApp({projectId,credential});db=new Firestore({projectId,authClient:googleAuth});
 }else{
  app=initializeApp({projectId,credential:applicationDefault()});db=require('firebase-admin/firestore').getFirestore(app);
 }
 return {projectId,db,auth:getAuth(app),messaging:getMessaging(app)};
}
module.exports={initializeRealFirebase};
