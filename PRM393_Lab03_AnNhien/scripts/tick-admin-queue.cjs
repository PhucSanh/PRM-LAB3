'use strict';
const path=require('node:path');
const req=require('node:module').createRequire(path.join(__dirname,'../firebase/functions/package.json'));
if(!process.env.FIRESTORE_EMULATOR_HOST||process.env.GCLOUD_PROJECT!=='demo-an-nhien')throw new Error('This script only runs against demo-an-nhien Firestore Emulator.');
const {initializeApp,deleteApp}=req('firebase-admin/app');const {getFirestore}=req('firebase-admin/firestore');
const {createAdminService}=require('../firebase/functions/admin.cjs');
const app=initializeApp({projectId:'demo-an-nhien'});
const service=createAdminService(getFirestore());
async function tick(){await service.processQueue();}
if(process.argv.includes('--watch')){
 let busy=false;
 const run=async()=>{if(busy)return;busy=true;try{await tick();}catch{console.error('Local queue waiting for emulator; will retry.');}finally{busy=false;}};
 run();setInterval(run,10000);
}else tick().then(()=>console.log('Processed one emulator queue tick.')).catch(e=>{console.error(e.message);process.exitCode=1;}).finally(()=>deleteApp(app));
