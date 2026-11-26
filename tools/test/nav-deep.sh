#!/usr/bin/env bash
# The navigation map's next level (features/nav-map.md): screens reached from a room's screens, walked by clicks the same
# way in either game (tools/test/nav-walk.sh's: the base's view, the room's tab, the entry), each step a click on a label
# (click <LABEL>, OCR) or at a place in the game's 1920x1080 UI (at <x> <y>), the screen then read (OCR, both passes) and
# photographed, and left by the corner arrow as many times as clicks were made (Esc where a step opened a dialog).
# Written to logs/nav/<tag>/deep/<name>.txt and .png, with deep/index.tsv; tools/test/nav-compare.mjs sets EW's and the
# port's side by side. Not committed: it holds the games' words.
#   tools/test/nav-deep.sh <port|ew> [name …]
set -uo pipefail
cd "$(dirname "$0")/../.."
tag=${1:?usage: nav-deep.sh <port|ew> [name …]}; shift
out=logs/nav/$tag/deep; mkdir -p "$out"; index="$out/index.tsv"
[ -f "$index" ] || printf 'name\troom\tentry\tsteps\tlines\n' > "$index"
# name | room | the room's entry | steps (;-separated)
spec=$(cat <<'EOF'
soldier-summary|BARRACKS|VIEW SOLDIERS|at 458 215
soldier-abilities|BARRACKS|VIEW SOLDIERS|at 458 215;click ABILITIES
craft-summary|HANGAR|VIEW AIRCRAFT LIST|click RAVEN-
craft-loadout|HANGAR|VIEW AIRCRAFT LIST|click RAVEN-;click EDIT LOADOUT
satellite-country|SITUATION ROOM|LAUNCH SAT|click CANADA
research-list|RESEARCH|RESEARCH PROJECT|
facility-tile|ENGINEERING|BUILD FACILITIES|at 254 407
EOF
)
if [ "$tag" = port ]; then declare -A X=([RESEARCH]=809 [ENGINEERING]=985 [BARRACKS]=1164 [HANGAR]=1313 ["SITUATION ROOM"]=1495)
else declare -A X=([RESEARCH]=750 [ENGINEERING]=928 [BARRACKS]=1105 [HANGAR]=1252 ["SITUATION ROOM"]=1437); fi
read_screen() {
  { tools/test/on.sh 'tools\test\ocr.ps1' 2>/dev/null; tools/test/on.sh 'tools\test\ocr.ps1 -Invert' 2>/dev/null; } | tr -d '\r' | grep -E '^[0-9]+ [0-9]+ [0-9]+ [0-9]+ ' | sort -u -k5 > "$1"
}
click() { case "$1" in at\ *) tools/test/on.sh "tools\\test\\click.ps1 ${1#at }" 2>&1 | tail -1;; click\ *) tools/test/on.sh "tools\\test\\click-label.ps1 \"${1#click }\"" 2>&1 | tail -1;; esac; }
while IFS='|' read -r name room entry steps; do
  [ -n "$name" ] || continue
  if [ $# -gt 0 ] && ! printf '%s\n' "$@" | grep -qx "$name"; then continue; fi
  grep -v -P "^\Q$name\E\t" "$index" > "$index.tmp"; mv "$index.tmp" "$index"
  # (From the base's view: a right click leaves a room and does nothing on the base's view.)
  tools/test/on.sh 'tools\test\click.ps1 960 540 -Right' 'Start-Sleep 2' 'tools\test\click.ps1 960 540 -Right' 'Start-Sleep 2' >/dev/null 2>&1
  tools/test/on.sh "tools\\test\\click.ps1 ${X[$room]} 33" >/dev/null 2>&1; sleep 3
  r=$(click "click $entry"); sleep 3; n=1; err=""
  [[ "$r" == ERR* ]] && err="entry: $r"
  IFS=';' read -ra st <<< "$steps"
  for s in "${st[@]}"; do
    [ -n "$s" ] || continue
    [ -n "$err" ] && break
    r=$(click "$s"); sleep 3; n=$((n + 1))
    [[ "$r" == ERR* ]] && err="$s: $r"
  done
  read_screen "$out/$name.txt"; tools/test/shot.sh "$out/$name.png" >/dev/null 2>&1
  lines=$(grep -c . "$out/$name.txt")
  echo "$name: $lines lines${err:+ ($err)}" | tee -a "$out/run.log"
  printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$room" "$entry" "$steps" "$lines" >> "$index"
  # (Back out: Esc for a dialog, else the corner arrow, once a click; then right clicks to the base's view.)
  for _ in $(seq 1 $n); do
    if grep -qE ' (CANCEL|Cancel|CONTINUE|Continue|OK)$' "$out/$name.txt"; then tools/test/on.sh 'tools\test\esc.ps1' >/dev/null 2>&1
    else tools/test/on.sh 'tools\test\click.ps1 96 1027' >/dev/null 2>&1; fi
    sleep 2
  done
done <<< "$spec"
echo "nav-deep $tag: done, $out"
