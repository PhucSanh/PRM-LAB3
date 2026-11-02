// Uses the locally installed Firebase CLI login, never a service-account key.
// Run from any directory: node firebase/scripts/seed-habits.cjs <project-id>
const path = require('node:path');
const fs = require('node:fs');
const cli = path.resolve(__dirname, '../tests/node_modules/firebase-tools/lib');
const auth = require(path.join(cli, 'auth.js'));
const { requireAuth } = require(path.join(cli, 'requireAuth.js'));
const { Client } = require(path.join(cli, 'apiv2.js'));
const project = process.argv[2];
if (!project) throw new Error('An explicit Firebase project ID is required');
const options = { project, nonInteractive: true };
const account = auth.getGlobalDefaultAccount();
if (!account) throw new Error('Run firebase login first');
auth.setActiveAccount(options, account);
(async () => {
  await requireAuth(options);
  const api = new Client({ urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1' });
  const base = `projects/${project}/databases/(default)/documents`;
  const habits = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../habits.json'), 'utf8'));
  let created = 0;
  for (const habit of habits) {
    try {
      await api.post(`${base}/habits`, {
        fields: { name: { stringValue: habit.name }, description: { stringValue: habit.description } },
      }, { queryParams: { documentId: habit.key } });
      created++;
    } catch (error) {
      if (error.status !== 409 && error.context?.response?.statusCode !== 409) throw error;
      // Existing catalog entries are never overwritten by this bootstrap.
    }
  }
  const result = await api.get(`${base}/habits`, { queryParams: { pageSize: 100 } });
  const count = result.body.documents?.length ?? 0;
  if (count < 9) throw new Error('Habit catalog verification failed');
  console.log(`PASS: ${created} catalog entries created; ${count} entries verified in ${project}.`);
})().catch(error => { console.error(error.message); process.exitCode = 1; });
