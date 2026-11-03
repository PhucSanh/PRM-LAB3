#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
android_device="${1:-emulator-5556}"
if [[ ! "$android_device" =~ ^[a-zA-Z0-9_.:-]+$ ]]; then
  printf '%s\n' 'Device ID không hợp lệ.' >&2
  exit 2
fi
if [[ ! -x firebase/tests/node_modules/.bin/firebase ]]; then
  printf '%s\n' 'Chạy npm ci --prefix firebase/tests và npm ci --prefix firebase/functions trước.' >&2
  exit 2
fi
# Demo project only. The emulator suite starts/stops with this test process.
./firebase/tests/node_modules/.bin/firebase emulators:exec \
  --project demo-an-nhien --only auth,firestore,functions \
  "flutter test integration_test/firebase_emulator_test.dart -d '$android_device'"
