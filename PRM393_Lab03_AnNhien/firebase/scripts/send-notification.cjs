// Trusted operator tool. Never ship this CLI authentication code in the app.
// node firebase/scripts/send-notification.cjs <project-id> <payload.json> --send
// payload: {id, recipientUid, title, body, route}. Reusing id updates the inbox
// entry; push itself is at-least-once and may be delivered more than once.
const path = require('node:path');
const fs = require('node:fs');
const cli = path.resolve(__dirname, '../tests/node_modules/firebase-tools/lib');
const auth = require(path.join(cli, 'auth.js'));
const { requireAuth } = require(path.join(cli, 'requireAuth.js'));
const { Client } = require(path.join(cli, 'apiv2.js'));
const [project, payloadFile, confirmation] = process.argv.slice(2);
if (!project || !payloadFile || confirmation !== '--send') {
  throw new Error('Usage: node send-notification.cjs <project> <payload.json> --send');
}
const payload = JSON.parse(fs.readFileSync(payloadFile, 'utf8'));
const { id, recipientUid, title, body, route = '/inbox' } = payload;
if (![id, recipientUid].every(v => typeof v === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(v)) ||
    typeof title !== 'string' || title.length < 1 || title.length > 160 ||
    typeof body !== 'string' || body.length > 1000 ||
    !(route === '/inbox' || /^\/(reminder\/[A-Za-z0-9_-]+|today\/suggestions\/[A-Za-z0-9_-]+)$/.test(route))) {
  throw new Error('Invalid notification payload');
}
const options = { project, nonInteractive: true };
const account = auth.getGlobalDefaultAccount();
if (!account) throw new Error('Run firebase login first');
auth.setActiveAccount(options, account);
(async () => {
  await requireAuth(options);
  const db = new Client({ urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1' });
  const fcm = new Client({ urlPrefix: 'https://fcm.googleapis.com', apiVersion: 'v1' });
  const base = `projects/${project}/databases/(default)/documents/users/${recipientUid}`;
  await db.patch(`${base}/notifications/${id}`, { fields: {
    title: {stringValue: title}, body: {stringValue: body}, route: {stringValue: route},
    receivedAt: {timestampValue: new Date().toISOString()},
  }});
  let pageToken;
  let sent = 0;
  let failed = 0;
  do {
    const response = await db.get(`${base}/devices`, {queryParams: {pageSize: 100, ...(pageToken ? {pageToken} : {})}});
    for (const device of response.body.documents ?? []) {
      const token = device.fields?.token?.stringValue;
      const updated = Date.parse(device.fields?.updatedAt?.timestampValue ?? '');
      // Registration must be refreshed by app use within 30 days.
      if (!token || !Number.isFinite(updated) || Date.now() - updated > 30 * 86400000) continue;
      try {
        await fcm.post(`projects/${project}/messages:send`, {message: {
          token,
          // Generic system-tray text protects privacy if a stale registration remains.
          notification: {title: 'An Nhiên', body: 'Bác có thông báo mới. Mở An Nhiên để xem nhé.'},
          data: {notification_id: id, recipient_uid: recipientUid, route},
        }});
        sent++;
      } catch (error) {
        failed++;
        // Only a definite UNREGISTERED result authorizes deleting registration.
        const details = error.context?.body?.error?.details ?? [];
        if (details.some(d => d.errorCode === 'UNREGISTERED')) {
          await db.delete(device.name);
        }
      }
    }
    pageToken = response.body.nextPageToken;
  } while (pageToken);
  console.log(`Inbox saved; pushes accepted=${sent}, failed=${failed}. No tokens logged.`);
  if (failed) process.exitCode = 1;
})().catch(() => { console.error('Notification operation failed. Check operator permissions and service configuration.'); process.exitCode = 1; });
