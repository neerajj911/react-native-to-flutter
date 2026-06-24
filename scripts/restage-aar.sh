#!/usr/bin/env bash
# Restage Flutter's AAR repo under semver coordinates.
# `flutter build aar` always emits version 1.0; this script copies the layout
# under <version>/ and renames+patches all references so gradle can resolve it
# as com.example.flutter_sdk:flutter_release:<version>.
#
# Usage: restage-aar.sh <src-1.0-dir> <dst-version-dir> <version>
set -euo pipefail

SRC="$1"
DST="$2"
VERSION="$3"

mkdir -p "$DST"
cp -r "$SRC"/. "$DST/"
cd "$DST"

# Rename every flutter_release-1.0.* → flutter_release-<VERSION>.*
for f in flutter_release-1.0.*; do
  [ -e "$f" ] || continue
  mv "$f" "${f/-1.0./-${VERSION}.}"
done

POM="flutter_release-${VERSION}.pom"
MOD="flutter_release-${VERSION}.module"

# POM: patch the <version> tag (leave dependency versions alone — those are
# Flutter engine versions, not ours).
if [ -f "$POM" ]; then
  sed -i "s|<version>1.0</version>|<version>${VERSION}</version>|g" "$POM"
fi

# Gradle Module metadata (JSON): patch component version + file refs.
if [ -f "$MOD" ]; then
  sed -i 's|"version"[[:space:]]*:[[:space:]]*"1.0"|"version": "'"${VERSION}"'"|g' "$MOD"
  sed -i 's|flutter_release-1\.0\.|flutter_release-'"${VERSION}"'.|g' "$MOD"
fi

# Recompute checksums for the files we just modified.
for f in "$POM" "$MOD"; do
  [ -f "$f" ] || continue
  md5sum    "$f" | awk '{print $1}' > "${f}.md5"
  sha1sum   "$f" | awk '{print $1}' > "${f}.sha1"
  sha256sum "$f" | awk '{print $1}' > "${f}.sha256"
  sha512sum "$f" | awk '{print $1}' > "${f}.sha512"
done

echo "Restaged AAR at version ${VERSION} in ${DST}"
