#!/usr/bin/env bash
set -euo pipefail
SDK_VERSION="$(xcrun --sdk iphoneos --show-sdk-version)"
if (( ${SDK_VERSION%%.*} < 26 )); then
  echo "DreamSpace native Liquid Glass requires Xcode 26+ (iOS 26 SDK). Selected SDK: $SDK_VERSION" >&2
  exit 1
fi
xcodebuild -version
