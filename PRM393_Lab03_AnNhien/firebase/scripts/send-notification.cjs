// Trusted operator only. Client apps cannot create inbox documents.
// node firebase/scripts/send-notification.cjs <project-id> <payload.json> --send
// payload: {id, recipientUid, title, body}. One new inbox entry -> notifyInbox.
// Never send a second push here: the deployed trigger owns delivery.
const path = require('node:path');
const fs = require('node:fs');
const cli = path.resolve(__dirname, '../tests/node_modules/firebase-tools/lib');
const auth = require(path.join(cli, 'auth.js'));
const {requireAuth} = require(path.join(cli, 'requireAuth.js'));
const {Client} = require(path.join(cli, 'apiv2.js'));
const [project, payloadFile, confirmation] = process.argv.slice(2);
if (!project || !payloadFile || confirmation !== '--send') {
  throw new Error('Usage: node send-notification.cjs <project> <payload.json> --send');
}
const {id, recipientUid, title, body, route = '/inbox'} = JSON.parse(fs.readFileSync(payloadFile, 'utf8'));
if (![id, recipientUid].every(v => typeof v === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(v)) ||
    typeof title !== 'string' || !title.trim() || title.length > 160 ||
    typeof body !== 'string' || body.length > 1000 || route !== '/inbox') {
  throw new Error('Invalid system announcement payload');
}
const options = {project, nonInteractive: true};
const account = auth.getGlobalDefaultAccount();
if (!account) throw new Error('Run firebase login first');
auth.setActiveAccount(options, account);
(async () => {
  await requireAuth(options);
  const db = new Client({urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1'});
  const base = `projects/${project}/databases/(default)/documents/users/${recipientUid}`;
  await db.get(base); // Never create announcements under a nonexistent user.
  await db.post(`${base}/notifications`, {fields: {
    title: {stringValue: title.trim()}, body: {stringValue: body}, route: {stringValue: route},
    kind: {stringValue: 'system'}, event: {stringValue: 'system_announcement'},
    recipientUid: {stringValue: recipientUid},
    receivedAt: {timestampValue: new Date().toISOString()},
  }}, {queryParams: {documentId: id}});
  console.log('System inbox entry created. The deployed notifyInbox trigger handles push delivery.');
})().catch(() => {
  console.error('Not created: check permissions, configuration, recipient and unique id. No push sent by CLI.');
  process.exitCode = 1;
});
