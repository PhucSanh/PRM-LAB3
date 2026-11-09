'use strict';
// Permanent Firebase Auth identity; never creates an elder/caregiver profile.
const path=require('node:path');
const {initializeRealFirebase}=require('../firebase/functions/real-runtime.cjs');
async function seed(){
 if(!process.env.ADMIN_SEED_PASSWORD)throw new Error('Set ADMIN_SEED_PASSWORD.');
 const {auth,db}=initializeRealFirebase();
 const uid='an-nhien-admin',email='annhien.admin@prm393-145c9.firebaseapp.com';
 const values={email,password:process.env.ADMIN_SEED_PASSWORD,displayName:'An Nhiên Admin',disabled:false,emailVerified:true};
 let user;try{user=await auth.getUser(uid);}catch(error){if(error.code!=='auth/user-not-found')throw error;}
 if(user)await auth.updateUser(uid,values);else await auth.createUser({uid,...values});
 await auth.setCustomUserClaims(uid,{...user?.customClaims,admin:true});
 await auth.revokeRefreshTokens(uid);
 console.log('Permanent admin account annhien seeded; admin claim has no activation expiry.');
 await db.terminate();
}
seed().catch(error=>{console.error(error.code||'seed-failed',error.message?.slice(0,600));process.exitCode=1;});
