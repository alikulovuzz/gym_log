#!/usr/bin/env bash
# Builds the .rpk variants that ticket #7 needs, so one trip to the band can tell
# a signature rejection apart from a package-id or manifest rejection.
#
#   A  gymlog-devkey    com.gymlog.band              aiot build    toolkit's bundled dev key
#   B  gymlog-ownkey    com.gymlog.band              aiot release  our own self-generated key
#   C  demo-devkey      com.application.watch.demo   aiot build    control: stock template id
#
# Each variant paints its own tag on screen, so the band tells us which one is running.
set -euo pipefail
cd "$(dirname "$0")/.."

OUT=../artifacts
mkdir -p "$OUT"
rm -f "$OUT"/*.rpk

MANIFEST=src/manifest.json
BUILDINFO=src/common/build-info.js
cp "$MANIFEST" "$MANIFEST.bak"
cp "$BUILDINFO" "$BUILDINFO.bak"
restore() { mv "$MANIFEST.bak" "$MANIFEST"; mv "$BUILDINFO.bak" "$BUILDINFO"; }
trap restore EXIT

variant() {
  local out_name=$1 pkg=$2 app_name=$3 tag=$4 mode=$5

  node -e "
    const fs=require('fs');
    const m=JSON.parse(fs.readFileSync('$MANIFEST','utf8'));
    m.package='$pkg'; m.name='$app_name';
    fs.writeFileSync('$MANIFEST', JSON.stringify(m,null,2));
  "
  printf "export default {\n  tag: '%s'\n}\n" "$tag" > "$BUILDINFO"

  rm -rf dist build
  npx aiot "$mode" >/dev/null 2>&1

  local built
  built=$(ls dist/*.rpk | head -1)
  cp "$built" "$OUT/$out_name.rpk"
  printf '%-16s %-28s %-8s %7s bytes   (%s)\n' \
    "$out_name" "$pkg" "$mode" "$(stat -c%s "$built")" "$(basename "$built")"
}

echo "variant          package                      mode        size"
echo "---------------------------------------------------------------------------"
variant gymlog-devkey "com.gymlog.band"            "GymLog"     "DEV-KEY"  build
variant gymlog-ownkey "com.gymlog.band"            "GymLog"     "OWN-KEY"  release
variant demo-devkey   "com.application.watch.demo" "GymLogDemo" "DEMO-ID"  build
echo
echo "artifacts in $(cd "$OUT" && pwd):"
ls -1 "$OUT"
