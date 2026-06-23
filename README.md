# React Native → Flutter SDK

Minimal SDK that lets a React Native app open an embedded Flutter screen and pass it static data over a `MethodChannel`. Engine is cached, so the first `open()` warms it up and every subsequent one is instant.

## Folder structure

```
project-root/
├── packages/
│   ├── flutter_sdk/                  # Flutter module (the embedded UI)
│   │   ├── pubspec.yaml
│   │   └── lib/
│   │       ├── main.dart
│   │       └── dashboard_screen.dart
│   └── react_native_sdk/             # What the client installs
│       ├── package.json
│       ├── tsconfig.json
│       ├── src/index.ts              # MySDK.open(data)
│       └── android/
│           ├── build.gradle
│           └── src/main/
│               ├── AndroidManifest.xml
│               └── java/com/mysdk/
│                   ├── MySDKModule.kt        # caches engine + starts activity
│                   ├── FlutterScreenActivity.kt
│                   └── MySDKPackage.kt
├── example/                          # Host RN app for local testing
│   ├── App.tsx
│   └── package.json
├── scripts/
│   ├── build-local.sh                # one-shot local build
│   └── check-versions.sh             # tag ↔ package.json ↔ pubspec.yaml
└── .github/workflows/
    ├── flutter-build.yml             # builds AAR, uploads artifact
    ├── sdk-package.yml               # builds JS wrapper, uploads artifact
    └── release.yml                   # validates versions, calls the two above, releases
```

## Architecture flow

```
React Native app
        │  MySDK.open({ userName, userId })
        ▼
packages/react_native_sdk/src/index.ts
        ▼
MySDKModule.kt
        │  ensureEngine() — create + cache FlutterEngine on first call
        │  startActivity(Intent → FlutterScreenActivity, extras=data)
        ▼
FlutterScreenActivity
        │  provideFlutterEngine() returns the cached engine
        │  MethodChannel('sdk_channel')
        │  on 'ready' from Flutter → invokeMethod('setUser', extras)
        ▼
DashboardScreen (Dart)
        Hello Nanu
        User ID: 123
```

## Components

- **Flutter module (`packages/flutter_sdk/`)** — the UI. One screen, one channel.
- **RN wrapper (`packages/react_native_sdk/src/index.ts`)** — the JS surface, a single `open(data)` method.
- **Android bridge (`packages/react_native_sdk/android/`)** — Kotlin module that warms/caches the engine and launches the Flutter activity.
- **MethodChannel `sdk_channel`** — the only path data takes into Dart. No `initialRoute`, no intent reads from Dart.

## Why the ready-handshake

1. `DashboardScreen` registers its handler on `sdk_channel`, then calls `ready`.
2. `FlutterScreenActivity` receives `ready`, replies with `invokeMethod('setUser', extras)`.
3. Dart receives `setUser`, updates state.

This kills the race where Android could push data before Dart was listening.

## Why a cached engine

Without caching, every `open()` starts a fresh `FlutterEngine` (~300–800ms cold start). We cache it once in `FlutterEngineCache` under the id `"sdk_engine"`. The first `open()` pays the cost; every later `open()` is instant.

## Local build

```bash
./scripts/build-local.sh
```

Runs `flutter build aar`, copies the repo into `packages/react_native_sdk/android/flutter_aar/`, then `npm install && npm run build` on the wrapper. After that, `example/` resolves the wrapper via `file:../packages/react_native_sdk` and you can `cd example && npm install && npm run android`.

## GitHub Actions

Three workflows, all triggered on `v*` tag push (only `release.yml` runs end-to-end; the other two are reusable via `workflow_call`):

- `flutter-build.yml` — `flutter build aar` → uploads the Maven repo as an artifact.
- `sdk-package.yml` — builds the JS wrapper → uploads `lib/` and Android sources.
- `release.yml` — validates versions, calls both builds, downloads artifacts, packs a tarball, creates a GitHub Release.

No npm publish yet. The tarball is attached to the release; promote to npm manually once you trust the pipeline.

If a build fails, re-run only the failed job — artifacts from the other are reused.

## Versioning

Semantic. Three places must agree before a release ships:

- git tag (e.g. `v1.0.1`)
- `packages/react_native_sdk/package.json` `version`
- `packages/flutter_sdk/pubspec.yaml` `version`

`scripts/check-versions.sh` enforces this locally and in CI (the `validate` job in `release.yml`).

```bash
# bump both files to 1.0.1, commit, then:
git tag v1.0.1
git push origin main --tags
```

## Client integration

```javascript
import MySDK from "rn-flutter-sdk";

MySDK.open({
  userName: "Nanu",
  userId: "123"
});
```

The `open()` payload is an object, so extra keys (`theme`, `language`, …) can be added later without breaking existing callers.

### One-time Android host setup

Add `MySDKPackage()` to your `ReactNativeHost.getPackages()` and make sure `minSdkVersion >= 21`.
