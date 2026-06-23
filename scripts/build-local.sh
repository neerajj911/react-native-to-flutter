#!/usr/bin/env bash
# Local build: Flutter AAR + RN wrapper, staged so the example/ app can consume it.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Flutter AAR"
cd "$ROOT/packages/flutter_sdk"
flutter pub get
flutter build aar --no-profile --no-debug

echo "==> Stage AAR into RN wrapper"
rm -rf "$ROOT/packages/react_native_sdk/android/flutter_aar"
mkdir -p "$ROOT/packages/react_native_sdk/android/flutter_aar"
cp -R "$ROOT/packages/flutter_sdk/build/host/outputs/repo/." \
      "$ROOT/packages/react_native_sdk/android/flutter_aar/"

echo "==> RN wrapper"
cd "$ROOT/packages/react_native_sdk"
npm install
npm run build

echo "==> Done. The example app can now resolve the wrapper at packages/react_native_sdk."
