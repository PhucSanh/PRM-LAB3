#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! rg -q '^ADMIN_LOGIN_PASSWORD=' firebase/functions/.secret.local 2>/dev/null; then
  (umask 077; printf '\nADMIN_LOGIN_PASSWORD=admin\n' >> firebase/functions/.secret.local)
fi
printf '%s\n' 'Open http://127.0.0.1:5000/?emulator=1 — local admin / admin.' 'Seed test data in a second terminal with the command in admin-web/README.md.'
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 GCLOUD_PROJECT=demo-an-nhien node scripts/tick-admin-queue.cjs --watch &
admin_queue_pid=$!
trap 'kill "$admin_queue_pid" 2>/dev/null || true' EXIT INT TERM
firebase/tests/node_modules/.bin/firebase emulators:start --project demo-an-nhien --only auth,firestore,functions,hosting
