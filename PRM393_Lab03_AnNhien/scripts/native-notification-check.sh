#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
android_device="${1:-emulator-5556}"
adb_tool="${ADB:-adb}"
if [[ ! "$android_device" =~ ^[a-zA-Z0-9_.:-]+$ ]]; then exit 2; fi
native_log="$(mktemp /tmp/an-nhien-notifications.XXXXXX)"
flutter test integration_test/local_reminder_test.dart -d "$android_device" > "$native_log" 2>&1 &
native_pid=$!
cleanup() {
  if kill -0 "$native_pid" 2>/dev/null; then kill "$native_pid" 2>/dev/null || true; fi
  rm -f "$native_log"
}
trap cleanup EXIT INT TERM
# Flutter integration runner uninstalls the test app at exit. Grant only after
# this run's package appears, rather than relying on the previous installation.
for ((attempt=0;attempt<180;attempt++)); do
  if ! kill -0 "$native_pid" 2>/dev/null; then break; fi
  if "$adb_tool" -s "$android_device" shell pm grant com.annhien.an_nhien android.permission.POST_NOTIFICATIONS >/dev/null 2>&1; then break; fi
  sleep 1
done
status=0
wait "$native_pid" || status=$?
cat "$native_log"
exit "$status"
