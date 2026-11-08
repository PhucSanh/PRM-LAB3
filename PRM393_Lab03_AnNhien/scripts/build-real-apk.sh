#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
backend_url="${1:-}"
mode="${2:-debug}"
if [[ -z "$backend_url" || ! "$mode" =~ ^(debug|release)$ ]]; then
  printf '%s\n' 'Usage: bash scripts/build-real-apk.sh http://YOUR_LAN_IP:3000 debug' '       bash scripts/build-real-apk.sh https://YOUR_BACKEND_HOST release' >&2
  exit 1
fi
if [[ "$mode" == release && "$backend_url" != https://* ]]; then
  printf '%s\n' 'Release APK requires an HTTPS backend URL.' >&2
  exit 1
fi
flutter build apk --"$mode" --dart-define="BACKEND_URL=$backend_url"
