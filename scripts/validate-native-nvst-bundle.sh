#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 /path/to/PixelNOW.app" >&2
  exit 64
fi

APP_PATH="$1"
FRAMEWORKS_PATH="$APP_PATH/Contents/Frameworks"

if [[ ! -d "$APP_PATH/Contents" ]]; then
  echo "Native NVST bundle validation failed: app bundle not found at $APP_PATH" >&2
  exit 65
fi

if [[ ! -d "$FRAMEWORKS_PATH" ]]; then
  echo "Native NVST bundle validation failed: Contents/Frameworks is missing." >&2
  exit 66
fi

required_files=(
  "libBifrost2.dylib"
  "libGeronimo.dylib"
  "libGsAudioWebRTC.dylib"
  "SDL2.framework/Versions/A/SDL2"
)

for relative_path in "${required_files[@]}"; do
  path="$FRAMEWORKS_PATH/$relative_path"
  if [[ ! -f "$path" ]]; then
    echo "Native NVST bundle validation failed: missing $relative_path" >&2
    exit 67
  fi

  archs="$(lipo -archs "$path")"
  if [[ "$archs" != *"arm64"* ]]; then
    echo "Native NVST bundle validation failed: $relative_path has no arm64 slice ($archs)." >&2
    exit 68
  fi

  if ! codesign --verify --strict "$path" >/dev/null 2>&1; then
    echo "Native NVST bundle validation failed: invalid code signature for $relative_path" >&2
    exit 69
  fi
done

if ! otool -D "$FRAMEWORKS_PATH/libGeronimo.dylib" | grep -q '@executable_path/../Frameworks/libGeronimo.dylib'; then
  echo "Native NVST bundle validation failed: libGeronimo install name is not app-relative." >&2
  exit 70
fi

if ! otool -L "$FRAMEWORKS_PATH/libGeronimo.dylib" | grep -q '@executable_path/../Frameworks/libBifrost2.dylib'; then
  echo "Native NVST bundle validation failed: libGeronimo is not linked to app-relative libBifrost2." >&2
  exit 71
fi

echo "Native NVST bundle validation passed: $APP_PATH"
