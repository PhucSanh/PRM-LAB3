'use strict';
const fs=require('node:fs');const path=require('node:path');
const file=path.join(__dirname,'../firebase/functions/.env.real');
if(!fs.existsSync(file)){fs.writeFileSync(file,'FIREBASE_PROJECT_ID=prm393-145c9\nADMIN_LOGIN_PASSWORD=admin\nUSE_FIREBASE_CLI_CREDENTIAL=1\nHOST=0.0.0.0\nPORT=3000\n',{mode:0o600,flag:'wx'});console.log('Created ignored local server configuration (.env.real). Real Firebase, no emulator.');}
