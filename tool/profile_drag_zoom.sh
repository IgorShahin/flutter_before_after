#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-macos}"
APP_PATH="example/lib/main.dart"

echo "Profiling before_after_slider drag/zoom scenario on: ${TARGET}"

case "${TARGET}" in
  macos)
    flutter run --profile -d macos -t "${APP_PATH}" --trace-skia
    ;;
  chrome)
    flutter run --profile -d chrome -t "${APP_PATH}" --web-renderer canvaskit
    ;;
  ios)
    flutter run --profile -d ios -t "${APP_PATH}" --trace-skia
    ;;
  android)
    flutter run --profile -d android -t "${APP_PATH}" --trace-skia
    ;;
  *)
    echo "Unsupported target: ${TARGET}"
    echo "Usage: bash tool/profile_drag_zoom.sh [macos|chrome|ios|android]"
    exit 1
    ;;
esac
