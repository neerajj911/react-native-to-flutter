#!/usr/bin/env bash
# Verifies tag, package.json, and pubspec.yaml all carry the same version.
# Usage: scripts/check-versions.sh v1.0.0
set -euo pipefail

TAG="${1:-${GITHUB_REF_NAME:-}}"
if [[ -z "$TAG" ]]; then
  echo "Usage: $0 <tag>  (or set GITHUB_REF_NAME)"
  exit 2
fi

VERSION="${TAG#v}"

PKG_VERSION=$(node -p "require('./packages/react_native_sdk/package.json').version")
PUBSPEC_VERSION=$(grep -E '^version:' packages/flutter_sdk/pubspec.yaml | awk '{print $2}')

fail=0
[[ "$PKG_VERSION"     == "$VERSION" ]] || { echo "package.json ($PKG_VERSION) != tag ($VERSION)"; fail=1; }
[[ "$PUBSPEC_VERSION" == "$VERSION" ]] || { echo "pubspec.yaml ($PUBSPEC_VERSION) != tag ($VERSION)"; fail=1; }

if [[ $fail -ne 0 ]]; then exit 1; fi
echo "All versions aligned at $VERSION"
