'use strict';
// Deploy one standalone admin/API/worker. Credential material stays in memory:
// Google key -> Azure Container App secret; never written into source or image.
const {execFileSync}=require('node:child_process');const http=require('node:http');const fs=require('node:fs');const path=require('node:path');const {createHash,randomUUID}=require('node:crypto');
const root=path.resolve(__dirname,'..');const az=process.env.AZ_BIN||'az';
if(fs.existsSync(path.join(root,'deploy/azure-admin.json')))throw new Error('Deployment metadata already exists. This bootstrap must not rotate production keys; update the existing Azure revision instead.');
const subscription=process.env.AZURE_SUBSCRIPTION_ID||'6b48ddca-53c7-4bb3-89d2-f49764599722';
const resourceGroup=process.env.AZURE_RESOURCE_GROUP||'an-nhien-rg';
const appName=process.env.AZURE_APP_NAME||'an-nhien-admin';
const environmentId=process.env.AZURE_ENVIRONMENT_ID||`/subscriptions/${subscription}/resourceGroups/pace-demo-rg/providers/Microsoft.App/managedEnvironments/pace-environment-jp`;
const registryName=process.env.AZURE_REGISTRY_NAME||'pace638443565b84';
const project='prm393-145c9',accountId='an-nhien-azure-backend';
const envFile=path.join(root,'firebase/functions/.env.real');if(fs.existsSync(envFile))process.loadEnvFile(envFile);
// Azure CLI is a .cmd shim on Windows. `execFileSync` cannot launch that
// shim directly, so use the platform shell only for this fixed local command.
function cli(args){return JSON.parse(execFileSync(az,[...args,'--output','json'],{encoding:'utf8',maxBuffer:8*1024*1024,stdio:['ignore','pipe','pipe'],shell:process.platform==='win32'}));}
const delay=ms=>new Promise(resolve=>setTimeout(resolve,ms));
let azureToken,googleToken;
async function request(url,method='GET',body,kind='azure'){
 const token=kind==='azure'?azureToken:googleToken;const response=await fetch(url,{method,headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},...(body?{body:JSON.stringify(body)}:{})});const data=await response.json().catch(()=>({}));
 if(!response.ok)throw Object.assign(new Error(`${kind} ${method} ${new URL(url).pathname} failed: ${response.status} ${data.error?.code||''}${kind==='google'?' '+(data.error?.message||'').slice(0,600):''}`),{status:response.status});return data;
}
const azure=(id,version,method='GET',body)=>request('https://management.azure.com'+id+'?api-version='+version,method,body);
const google=(url,method='GET',body)=>request(url,method,body,'google');
function roleId(principal){const h=createHash('sha256').update(subscription+principal+'AcrPull').digest('hex').slice(0,32);return [h.slice(0,8),h.slice(8,12),h.slice(12,16),h.slice(16,20),h.slice(20)].join('-');}
async function pushImage(server,token,image){
 const endpoint=execFileSync('docker',['context','inspect','--format','{{.Endpoints.docker.Host}}'],{encoding:'utf8'}).trim();if(!endpoint.startsWith('unix://'))throw new Error('Expected a local Unix Docker daemon.');
 const dockerAuth=Buffer.from(JSON.stringify({username:'00000000-0000-0000-0000-000000000000',password:token,serveraddress:server})).toString('base64');
 execFileSync('docker',['tag','an-nhien-admin:production',image],{stdio:'inherit'});
 await new Promise((resolve,reject)=>{const req=http.request({socketPath:endpoint.slice(7),method:'POST',path:'/images/'+encodeURIComponent(image)+'/push',headers:{'X-Registry-Auth':dockerAuth}},response=>{let buffer='',error=false;response.setEncoding('utf8');response.on('data',chunk=>{buffer+=chunk;let index;while((index=buffer.indexOf('\n'))>=0){const line=buffer.slice(0,index);buffer=buffer.slice(index+1);try{const entry=JSON.parse(line);if(entry.error){error=true;reject(new Error('Registry image push failed.'));}}catch{}}});response.on('end',()=>{if(!error&&response.statusCode<300)resolve();else reject(new Error('Docker push failed: '+response.statusCode));});});req.on('error',reject);req.end();});
}
(async()=>{
 azureToken=cli(['account','get-access-token','--resource','https://management.azure.com/']).accessToken;
 const account=cli(['account','show']);if(account.id!==subscription)throw new Error('Select the intended Azure subscription first.');
 const environment=await azure(environmentId,'2025-01-01');const location=environment.location;
 const registry=cli(['acr','show','--name',registryName]);const login=cli(['acr','login','--name',registryName,'--expose-token']);
 const image=process.env.AZURE_DEPLOY_IMAGE||(registry.loginServer+'/an-nhien/admin:'+new Date().toISOString().replace(/[-:.TZ]/g,''));
 if(!process.env.AZURE_DEPLOY_IMAGE){console.log('Pushing production image to dedicated an-nhien/admin repository…');await pushImage(registry.loginServer,login.accessToken,image);console.log('Image pushed.');}else console.log('Reusing production image.');
 const groupId=`/subscriptions/${subscription}/resourceGroups/${resourceGroup}`;
 await azure(groupId,'2021-04-01','PUT',{location,tags:{application:'an-nhien',managedBy:'codex'}});
 const identityId=groupId+'/providers/Microsoft.ManagedIdentity/userAssignedIdentities/an-nhien-pull';
 const identity=await azure(identityId,'2023-01-31','PUT',{location});
 const assignmentId=registry.id+'/providers/Microsoft.Authorization/roleAssignments/'+roleId(identity.properties.principalId);
 await azure(assignmentId,'2022-04-01','PUT',{properties:{roleDefinitionId:`/subscriptions/${subscription}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d`,principalId:identity.properties.principalId,principalType:'ServicePrincipal'}});
 console.log('Dedicated resource group and image-pull identity prepared.');
 // Use existing authorized Google CLI account only to provision a scoped server identity.
 const {initializeRealFirebase}=require('../firebase/functions/real-runtime.cjs');const runtime=initializeRealFirebase();
 googleToken=(await runtime.auth.app.options.credential.getAccessToken()).access_token;
 const email=accountId+'@'+project+'.iam.gserviceaccount.com';const serviceAccountPath='projects/'+project+'/serviceAccounts/'+email;
 try{await google('https://iam.googleapis.com/v1/'+serviceAccountPath);}catch(error){if(error.status!==404)throw error;await google('https://iam.googleapis.com/v1/projects/'+project+'/serviceAccounts','POST',{accountId,serviceAccount:{displayName:'An Nhien Azure backend'}});}
 const policyUrl='https://cloudresourcemanager.googleapis.com/v1/projects/'+project;
 const policy=await google(policyUrl+':getIamPolicy','POST',{options:{requestedPolicyVersion:3}});policy.bindings||=[];
 for(const role of ['roles/datastore.user','roles/firebaseauth.viewer','roles/firebasecloudmessaging.admin']){let binding=policy.bindings.find(b=>b.role===role&&!b.condition);if(!binding){binding={role,members:[]};policy.bindings.push(binding);}if(!binding.members.includes('serviceAccount:'+email))binding.members.push('serviceAccount:'+email);}
 await google(policyUrl+':setIamPolicy','POST',{policy});
 const key=await google('https://iam.googleapis.com/v1/'+serviceAccountPath+'/keys','POST',{privateKeyType:'TYPE_GOOGLE_CREDENTIALS_FILE',keyAlgorithm:'KEY_ALG_RSA_2048'});
 let accepted=false;
 try{
  const privateCredential=Buffer.from(key.privateKeyData,'base64').toString('utf8');
  const origin='https://'+appName+'.'+environment.properties.defaultDomain;
  const appId=groupId+'/providers/Microsoft.App/containerApps/'+appName;
  const env=[{name:'NODE_ENV',value:'production'},{name:'HOST',value:'0.0.0.0'},{name:'PORT',value:'3000'},{name:'FIREBASE_PROJECT_ID',value:project},{name:'USE_FIREBASE_CLI_CREDENTIAL',value:'0'},{name:'FIREBASE_SERVICE_ACCOUNT_JSON',secretRef:'firebase-service-account'},{name:'ADMIN_LOGIN_PASSWORD',secretRef:'admin-password'},{name:'ALLOWED_ORIGINS',value:origin}];
  const body={location,identity:{type:'UserAssigned',userAssignedIdentities:{[identityId]:{}}},tags:{application:'an-nhien'},properties:{managedEnvironmentId:environmentId,workloadProfileName:'Consumption',configuration:{activeRevisionsMode:'Single',ingress:{external:true,targetPort:3000,transport:'http',allowInsecure:false},registries:[{server:registry.loginServer,identity:identityId}],secrets:[{name:'firebase-service-account',value:privateCredential},{name:'admin-password',value:process.env.ADMIN_LOGIN_PASSWORD}]},template:{containers:[{name:'an-nhien',image,env,resources:{cpu:0.25,memory:'0.5Gi'},probes:[{type:'Readiness',httpGet:{path:'/health',port:3000},initialDelaySeconds:30,periodSeconds:10},{type:'Liveness',httpGet:{path:'/health',port:3000},initialDelaySeconds:60,periodSeconds:30}]}],scale:{minReplicas:1,maxReplicas:1}}}};
  if(!process.env.ADMIN_LOGIN_PASSWORD)throw new Error('Set the admin password before deployment.');
  console.log('Creating HTTPS container app; credential is stored as an Azure secret.');await azure(appId,'2025-01-01','PUT',body);accepted=true;
  const metadata={subscription,resourceGroup,appName,appId,origin,image,environmentId,firebaseProject:project,serviceAccount:email,serviceAccountKeyName:key.name,createdAt:new Date().toISOString()};fs.writeFileSync(path.join(root,'deploy/azure-admin.json'),JSON.stringify(metadata,null,2)+'\n');
  for(let i=0;i<60;i++){const app=await azure(appId,'2025-01-01');const state=app.properties.provisioningState;console.log('Container app:',state,app.properties.runningStatus||'');if(state==='Succeeded'){console.log('Deployment URL: '+origin);await runtime.db.terminate();return;}if(state==='Failed')throw new Error('Azure container app provisioning failed.');await delay(10000);}
  throw new Error('Azure provisioning is still pending; resume using deploy/azure-admin.json.');
 }catch(error){if(!accepted){try{await google('https://iam.googleapis.com/v1/'+key.name,'DELETE');console.log('Unused service-account key removed.');}catch{console.error('Cleanup needed for unused key: '+key.name);}}await runtime.db.terminate();throw error;}
})().catch(error=>{console.error(error.message);process.exitCode=1;});
