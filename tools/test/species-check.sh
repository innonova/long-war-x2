#!/usr/bin/env bash
# Each Long War species on the field animates (features/e2e-tests.md, after the Sectoids' bind-pose regression): in a
# mission, each species spawned beside the squad, its pawn checked: its mesh finds its idle in a set whose tracks fit the
# mesh's bones (the control port's anims), and its joints move off the bind pose. The game must be in a mission
# (tools/test/to-mission.sh).
#   tools/test/species-check.sh [species …]
set -uo pipefail
cd "$(dirname "$0")/../.."
species=("$@"); [ ${#species[@]} -eq 0 ] && species=(4 5 6 7 8 9 10 11 13 14 15 17 18 21 23 24 25 26 27 28 29 30 31)
tools/test/lw.sh "exec ToggleFOW" >/dev/null 2>&1
fails=0
for c in "${species[@]}"; do
  s=$(tools/test/lw.sh "spawn LWX2Char_$c 3 $c" 2>&1 | tail -1); sleep 4
  id=$(echo "$s" | grep -o "#[0-9]*" | head -1)
  a=$(tools/test/lw.sh "anims $id" 2>&1)
  head=$(echo "$a" | sed -n 2p | cut -c1-90)
  fit=$(echo "$a" | grep -o 'the first [0-9]* on the mesh' | awk '{print $3}' | sort -n | tail -1)
  finds=$(echo "$a" | grep -c 'the mesh finds .*: ')
  j1=$(echo "$a" | grep -o 'joints: .*' | head -1); sleep 1
  j2=$(tools/test/lw.sh "anims $id" 2>&1 | grep -o 'joints: .*' | head -1)
  if [ "${fit:-0}" -gt 0 ] && [ "$finds" -gt 0 ]; then v=ok; else v=FAIL; fails=$((fails+1)); fi
  [ "$j1" != "$j2" ] && moving=moving || moving=still
  echo "species $c: $v (tracks on mesh ${fit:-0}, idle found $finds, $moving) $head"
  [ -n "$id" ] && tools/test/lw.sh "remove $id" >/dev/null 2>&1
done
echo "species-check: ${#species[@]} species, $fails failed"
