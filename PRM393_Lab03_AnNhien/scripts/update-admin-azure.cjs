'use strict';
// Update only the existing container image. Keep credentials, identity and scaling.
const {execFileSync}=require('node:child_process');const http=require('node:http');const fs=require('node:fs');const path=require('node:path');
const root=path.resolve(__dirname,'..');const metadataPath=path.join(root,'deploy/azure-admin.json');const metadata=JSON.parse(fs.readFileSync(metadataPath));const az=process.env.AZ_BIN||'az';
function cli(args){return JSON.parse(execFileSync(az,[...args,'--output','json'],{encoding:'utf8',stdio:['ignore','pipe','pipe']}));}
async function pushImage(server,token,image){
 const endpoint=execFileSync('docker',['context','inspect','--format','{{.Endpoints.docker.Host}}'],{encoding:'utf8'}).trim();if(!endpoint.startsWith('unix://'))throw new Error('Expected a local Unix Docker daemon.');
 const dockerAuth=Buffer.from(JSON.stringify({username:'00000000-0000-0000-0000-000000000000',password:token,serveraddress:server})).toString('base64');
 execFileSync('docker',['tag','an-nhien-admin:production',image],{stdio:'inherit'});
 await new Promise((resolve,reject)=>{const req=http.request({socketPath:endpoint.slice(7),method:'POST',path:'/images/'+encodeURIComponent(image)+'/push',headers:{'X-Registry-Auth':dockerAuth}},response=>{let buffer='',error=false;response.setEncoding('utf8');response.on('data',chunk=>{buffer+=chunk;let index;while((index=buffer.indexOf('\n'))>=0){const line=buffer.slice(0,index);buffer=buffer.slice(index+1);try{const entry=JSON.parse(line);if(entry.error){error=true;reject(new Error('Registry image push failed.'));}}catch{}}});response.on('end',()=>{if(!error&&response.statusCode<300)resolve();else reject(new Error('Docker push failed: '+response.statusCode));});});req.on('error',reject);req.end();});
}
(async()=>{
 if(cli(['account','show']).id!==metadata.subscription)throw new Error('Wrong Azure subscription.');
 const token=cli(['account','get-access-token','--resource','https://management.azure.com/']).accessToken;
 const url='https://management.azure.com'+metadata.appId+'?api-version=2025-01-01';
 async function arm(method='GET',body){const response=await fetch(url,{method,headers:{Authorization:'Bearer '+token,'Content-Type':'application/json'},...(body?{body:JSON.stringify(body)}:{})});const text=await response.text();const data=text?JSON.parse(text):{};if(!response.ok)throw new Error('Azure update failed: '+response.status+' '+(data.error?.code||''));return data;}
 const app=await arm();const template=app.properties.template;
 if(template.containers.length!==1||template.containers[0].name!=='an-nhien')throw new Error('Unexpected container configuration.');
 const login=cli(['acr','login','--name','pace638443565b84','--expose-token']);
 const image=login.loginServer+'/an-nhien/admin:'+new Date().toISOString().replace(/[-:.TZ]/g,'');
 await pushImage(login.loginServer,login.accessToken,image);console.log('Image pushed:',image);
 const previousImage=template.containers[0].image;template.containers[0].image=image;delete template.revisionSuffix;
 await arm('PATCH',{properties:{template}});
 metadata.previousImage=previousImage;metadata.image=image;metadata.updatedAt=new Date().toISOString();fs.writeFileSync(metadataPath,JSON.stringify(metadata,null,2)+'\n');
 console.log('Existing app revision update requested. No credential or access changes.');
})().catch(error=>{console.error(error.message);process.exitCode=1;});
