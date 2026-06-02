#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PROJECT_PATH="${PROJECT_PATH:-Quiltwright.xcodeproj}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-.build/XcodeDerivedData}"
CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/ModuleCache}"
MAC_SCHEME="${MAC_SCHEME:-QuiltwrightMac}"
IOS_SCHEME="${IOS_SCHEME:-QuiltwrightiOS}"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

export DEVELOPER_DIR
export CLANG_MODULE_CACHE_PATH

ensure_xcode() {
  if [[ ! -x "$DEVELOPER_DIR/usr/bin/xcodebuild" ]]; then
    echo "xcodebuild was not found at $DEVELOPER_DIR/usr/bin/xcodebuild" >&2
    echo "Set DEVELOPER_DIR to the Xcode installation on this Buildkite agent." >&2
    exit 1
  fi

  xcodebuild -version
}

run_package_checks() {
  swift run QuiltwrightChecks
}

build_macos() {
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$MAC_SCHEME" \
    -destination "platform=macOS" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -quiet \
    build \
    CODE_SIGNING_ALLOWED=NO
}

build_ios_simulator() {
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$IOS_SCHEME" \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -quiet \
    build \
    CODE_SIGNING_ALLOWED=NO
}

case "${1:-all}" in
  package)
    ensure_xcode
    run_package_checks
    ;;
  macos)
    ensure_xcode
    build_macos
    ;;
  ios)
    ensure_xcode
    build_ios_simulator
    ;;
  all)
    ensure_xcode
    run_package_checks
    build_macos
    build_ios_simulator
    ;;
  *)
    echo "Usage: $0 [package|macos|ios|all]" >&2
    exit 2
    ;;
esac
