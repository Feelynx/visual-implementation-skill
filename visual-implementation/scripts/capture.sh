#!/usr/bin/env bash
set -euo pipefail

# Read-only screen capture for the verification gate (references/verification.md).
# Captures pixels only — never taps, types, or navigates (NN-30).

usage() {
  cat >&2 <<'EOF'
Usage: capture.sh [android|ios|auto] [output.png]

  android   capture from the first connected adb device/emulator
  ios       capture from the booted iOS simulator (xcrun simctl)
  auto      try android, then ios (default)
  output    output file (default: capture.png)
EOF
  exit 1
}

TARGET="${1:-auto}"
OUT="${2:-capture.png}"
case "$TARGET" in android|ios|auto) ;; -h|--help|*) usage ;; esac

capture_android() {
  command -v adb >/dev/null 2>&1 || return 1
  adb get-state >/dev/null 2>&1 || return 1
  adb exec-out screencap -p > "$OUT"
}

capture_ios() {
  command -v xcrun >/dev/null 2>&1 || return 1
  xcrun simctl io booted screenshot "$OUT" >/dev/null 2>&1
}

ok=0
case "$TARGET" in
  android) capture_android && ok=1 ;;
  ios)     capture_ios && ok=1 ;;
  auto)    { capture_android || capture_ios; } && ok=1 ;;
esac

if [ "$ok" -ne 1 ] || [ ! -s "$OUT" ]; then
  rm -f "$OUT"
  echo "Error: no capturable device found (android: adb device connected; ios: simulator booted)." >&2
  echo "If the device is the user's shared session, ask before doing anything beyond this read-only capture." >&2
  exit 1
fi

echo "Captured: $OUT"
