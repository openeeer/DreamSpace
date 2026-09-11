#!/usr/bin/env bash
# Package a physical-device Flutter build for signing in ESign.
set -euo pipefail

APP_PATH="${1:-build/ios/iphoneos/Runner.app}"
OUTPUT_PATH="${2:-build/ios/DreamSpace-unsigned.ipa}"

test -d "$APP_PATH"
test -f "$APP_PATH/Info.plist"
test -f "$APP_PATH/Runner"
mkdir -p "$(dirname "$OUTPUT_PATH")"
OUTPUT_PATH="$(cd "$(dirname "$OUTPUT_PATH")" && pwd)/$(basename "$OUTPUT_PATH")"

STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
mkdir -p "$STAGING/Payload"
ditto "$APP_PATH" "$STAGING/Payload/Runner.app"
(
  cd "$STAGING"
  COPYFILE_DISABLE=1 zip -q -r -y DreamSpace-unsigned.ipa Payload
)
unzip -tq "$STAGING/DreamSpace-unsigned.ipa"
mv -f "$STAGING/DreamSpace-unsigned.ipa" "$OUTPUT_PATH"
printf 'Unsigned IPA ready: %s\n' "$OUTPUT_PATH"
