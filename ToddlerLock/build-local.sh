#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT="$SCRIPT_DIR/ToddlerLock.xcodeproj"
BUILD_ROOT="$SCRIPT_DIR/build"

if ! command -v xcodebuild >/dev/null 2>&1; then
  print -u2 "Для локальной сборки нужен Xcode. Без него используйте GitHub Actions: Build Tyk."
  exit 1
fi

python3 "$SCRIPT_DIR/generate_project.py"
xcodebuild \
  -project "$PROJECT" \
  -target ToddlerLock \
  -configuration Release \
  SYMROOT="$BUILD_ROOT/Products" \
  OBJROOT="$BUILD_ROOT/Intermediates" \
  CODE_SIGNING_ALLOWED=NO \
  build

APP_PATH=$(find "$BUILD_ROOT/Products/Release" -maxdepth 1 -name '*.app' -print -quit)
test -n "$APP_PATH"
codesign --force --deep --sign - \
  --entitlements "$SCRIPT_DIR/ToddlerLock/App/ToddlerLock.entitlements" \
  "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
print "$APP_PATH"
