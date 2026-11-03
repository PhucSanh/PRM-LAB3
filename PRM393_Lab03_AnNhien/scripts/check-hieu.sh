#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
flutter analyze
flutter test
npm ci --prefix firebase/functions
npm ci --prefix firebase/tests
npm run check --prefix firebase/functions
npm test --prefix firebase/tests
