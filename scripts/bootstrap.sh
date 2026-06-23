#!/usr/bin/env bash
# Generates the platform skeletons that flutter create / RN init produce,
# preserves our hand-written source, and wires the wrapper into the example app.
# Safe to re-run.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> 1/4  Flutter module platform folders"
if [[ ! -d packages/flutter_sdk/.android ]]; then
  # flutter create on an existing dir will overwrite lib/main.dart and pubspec.yaml.
  # Stash + restore the files we authored.
  TMP="$(mktemp -d)"
  cp packages/flutter_sdk/pubspec.yaml      "$TMP/pubspec.yaml"
  cp -R packages/flutter_sdk/lib            "$TMP/lib"

  (cd packages && flutter create \
      --template module \
      --org com.example \
      --project-name flutter_sdk \
      flutter_sdk)

  cp "$TMP/pubspec.yaml"       packages/flutter_sdk/pubspec.yaml
  rm -rf packages/flutter_sdk/lib
  cp -R "$TMP/lib"             packages/flutter_sdk/lib
  rm -rf "$TMP"
else
  echo "    (already initialized — skipping)"
fi

echo "==> 2/4  React Native example app skeleton"
if [[ ! -d example/android ]]; then
  TMP="$(mktemp -d)"
  cp example/App.tsx       "$TMP/App.tsx"
  cp example/package.json  "$TMP/package.json"

  # Generate into a side dir, then merge in.
  npx --yes @react-native-community/cli init Example \
      --version 0.74.0 \
      --skip-install \
      --directory _example_tmp

  for item in android ios index.js metro.config.js babel.config.js \
              tsconfig.json .eslintrc.js .prettierrc.js Gemfile; do
    if [[ -e _example_tmp/$item ]]; then
      mv "_example_tmp/$item" "example/$item"
    fi
  done
  rm -rf _example_tmp

  # Restore our App.tsx. Keep the generated package.json (it has the right
  # @react-native-community/cli, babel, metro deps) and add our SDK dep to it.
  cp "$TMP/App.tsx" example/App.tsx
  mv _example_tmp/package.json example/package.json 2>/dev/null || true
  node -e "
    const fs = require('fs');
    const p = JSON.parse(fs.readFileSync('example/package.json','utf8'));
    p.dependencies = p.dependencies || {};
    p.dependencies['rn-flutter-sdk'] = 'file:../packages/react_native_sdk';
    fs.writeFileSync('example/package.json', JSON.stringify(p, null, 2) + '\n');
  "
  rm -rf "$TMP"
else
  echo "    (already initialized — skipping)"
fi

echo "==> 3/4  Wire wrapper into example/android"

SETTINGS="example/android/settings.gradle"
if ! grep -q "rn-flutter-sdk" "$SETTINGS"; then
  cat >> "$SETTINGS" <<'EOF'

include ':rn-flutter-sdk'
project(':rn-flutter-sdk').projectDir = new File(rootProject.projectDir, '../../packages/react_native_sdk/android')
EOF
  echo "    settings.gradle patched"
fi

APP_GRADLE="example/android/app/build.gradle"
if ! grep -q "rn-flutter-sdk" "$APP_GRADLE"; then
  # Insert the dependency after the line opening the dependencies { block
  awk '
    /^dependencies *\{/ && !done {
      print
      print "    implementation project('"'"':rn-flutter-sdk'"'"')"
      done = 1
      next
    }
    { print }
  ' "$APP_GRADLE" > "$APP_GRADLE.tmp" && mv "$APP_GRADLE.tmp" "$APP_GRADLE"
  echo "    app/build.gradle patched"
fi

# MainApplication.kt — find it dynamically since the package path depends on RN init output.
MAIN_APP=$(find example/android/app/src/main/java -name 'MainApplication.kt' -o -name 'MainApplication.java' | head -1)
if [[ -n "$MAIN_APP" ]] && ! grep -q "MySDKPackage" "$MAIN_APP"; then
  if [[ "$MAIN_APP" == *.kt ]]; then
    # Add import after the package declaration
    sed -i.bak '1,/^package /{
      /^package /a\
import com.mysdk.MySDKPackage
    }' "$MAIN_APP"
    # Inject add(MySDKPackage()) inside the apply { ... } block of getPackages
    sed -i.bak 's|// add(MyReactNativePackage())|add(MySDKPackage())|' "$MAIN_APP" || true
    # Fallback: also inject before the closing brace of `.apply {` if the placeholder wasn't found
    if ! grep -q "MySDKPackage()" "$MAIN_APP"; then
      awk '
        /\.apply *\{/ { in_apply = 1; print; next }
        in_apply && /^[[:space:]]*\}/ { print "      add(MySDKPackage())"; in_apply = 0 }
        { print }
      ' "$MAIN_APP" > "$MAIN_APP.tmp" && mv "$MAIN_APP.tmp" "$MAIN_APP"
    fi
  else
    sed -i.bak '/^package /a\
import com.mysdk.MySDKPackage;
' "$MAIN_APP"
    sed -i.bak 's|// packages.add(new MyReactNativePackage());|packages.add(new MySDKPackage());|' "$MAIN_APP" || true
  fi
  rm -f "$MAIN_APP.bak"
  echo "    $MAIN_APP patched"
fi

echo "==> 4/4  Install JS deps + build SDK"
(cd packages/react_native_sdk && npm install)
"$ROOT/scripts/build-local.sh"

(cd example && npm install)

cat <<'EOF'

==========================================================
Bootstrap complete.

Next:
  cd example
  npx react-native start          # Metro, in one terminal
  npx react-native run-android    # builds + installs, in another

Tap "Open Flutter Screen" → you should see:
  Hello Nanu
  User ID: 123
==========================================================
EOF
