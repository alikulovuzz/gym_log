#!/usr/bin/env bash
# Drive a sideload from the PC, so the band's verdict on our own .rpk is captured
# rather than eyeballed. Requires the Android phone on adb (USB debugging on).
#
#   bash scripts/sideload.sh ../artifacts/gymlog-devkey.rpk
#
# Pushes the .rpk somewhere Mi Fitness's file picker can see it, then tails the
# logs that carry an install rejection. Leave it running while the install is
# driven (by hand, or by `adb shell input tap` from the agent).
set -euo pipefail
cd "$(dirname "$0")/.."

RPK=${1:?usage: sideload.sh <path-to-rpk>}
[ -f "$RPK" ] || { echo "no such .rpk: $RPK" >&2; exit 1; }

ADB=$(find node_modules/@miwt -name adb.exe 2>/dev/null | head -1)
ADB=${ADB:-adb}

"$ADB" wait-for-device
echo "device: $("$ADB" shell getprop ro.product.model | tr -d '\r') (android $("$ADB" shell getprop ro.build.version.release | tr -d '\r'))"

DEST=/sdcard/Download/$(basename "$RPK")
"$ADB" push "$RPK" "$DEST"
"$ADB" shell "ls -l $DEST"

# Make the file visible to media-scanner-backed pickers straight away.
"$ADB" shell "am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file://$DEST" >/dev/null 2>&1 || true

echo
echo "pushed. tailing logs for the install verdict — ctrl-c to stop."
echo "watching: Mi Fitness (com.xiaomi.wearable), rpk/quickapp/sign/install chatter"
echo "---------------------------------------------------------------------------"
"$ADB" logcat -c
"$ADB" logcat -v time \
  | grep --line-buffered -iE "rpk|quickapp|quick_app|vela|wearable|signature|sign|verify|install|reject|denied" \
  | grep --line-buffered -viE "InputMethod|WindowManager|ActivityTaskManager: Displayed"
