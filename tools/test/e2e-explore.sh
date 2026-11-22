#!/usr/bin/env bash
# A systematic walk through the base (features/e2e-tests.md): for each room tab, its menu read off the screen (OCR, the
# menu column under the tabs), each entry clicked as a player would, the screen that opens recorded and photographed,
# then left by the corner arrow; a screen that does not open, or a way out that does not return to the room, reported.
# The game must be up in a campaign (tools/test/new-campaign.sh 1 --begin).
#   tools/test/e2e-explore.sh [room …]
set -uo pipefail
cd "$(dirname "$0")/../.."
out=logs/e2e/explore; mkdir -p "$out"; rm -f "$out"/*.png
log="$out/run.log"; : > "$log"
say() { echo "$*" | tee -a "$log"; }
screen() { tools/test/lw.sh state 2>/dev/null | sed -n 's/.*screen=\([^ ]*\).*/\1/p' | tail -1; }
declare -A X=([RESEARCH]=809 [ENGINEERING]=985 [BARRACKS]=1164 [HANGAR]=1313 ["SITUATION ROOM"]=1495)
rooms=("$@"); [ ${#rooms[@]} -eq 0 ] && rooms=(RESEARCH ENGINEERING BARRACKS HANGAR "SITUATION ROOM")
fails=0
for room in "${rooms[@]}"; do
  tools/test/on.sh "tools\\test\\click.ps1 ${X[$room]} 33" >/dev/null 2>&1; sleep 2.5
  # (The room's menu: OCR lines in the menu column, x 900-1350, y 70-330 of the 1920x1080 UI, upper-case labels.)
  mapfile -t items < <(tools/test/on.sh 'tools\test\ocr.ps1 -Invert' 2>/dev/null | tr -d '\r' | awk '$1>=880 && $1<=1350 && $2>=70 && $2<=330 {$1=$2=$3=$4=""; sub(/^ +/,""); print}' | grep -E '^[A-Z0-9 /:-]+$' | awk 'length($0)>3')
  say "== $room: ${#items[@]} entries: ${items[*]}"
  for it in "${items[@]}"; do
    slug=$(echo "$room-$it" | tr ' /:' '___' | tr -cd 'A-Za-z0-9_-')
    r=$(tools/test/on.sh "tools\\test\\click-label.ps1 \"$it\"" 2>&1 | tail -1 | tr -d '\r'); sleep 3
    s=$(screen); tools/test/shot.sh "$out/$slug.png" >/dev/null 2>&1
    if [[ "$r" == ERR* ]]; then say "  $it: FAIL click ($r)"; fails=$((fails+1)); continue; fi
    if [ "$s" = UILWEWHub ]; then say "  $it: opened nothing (still the hub)"; continue; fi
    # (A dialog (EW's own: the bonuses' list, hiring) has its own buttons, no corner arrow: Esc, as its Cancel.)
    if [[ "$s" == UIDialogueBox || "$s" == UILWEWHiring ]]; then
      tools/test/on.sh 'tools\test\esc.ps1' >/dev/null 2>&1; sleep 2.5; b=$(screen)
      if [ "$b" = UILWEWHub ]; then say "  $it: $s (a dialog), Esc ok"; else say "  $it: $s (a dialog), Esc left $b on top: FAIL"; fails=$((fails+1)); fi
      continue
    fi
    tools/test/on.sh 'tools\test\click.ps1 96 1027' >/dev/null 2>&1; sleep 2.5
    b=$(screen)
    if [ "$b" = UILWEWHub ]; then say "  $it: $s, back ok"
    else
      say "  $it: $s, back left $b on top: FAIL"; fails=$((fails+1))
      # (Out by Esc, else by the control port; the room's tab not clicked again: clicked in its own room, it leaves it.)
      tools/test/on.sh 'tools\test\esc.ps1' >/dev/null 2>&1; sleep 2
      [ "$(screen)" != UILWEWHub ] && { tools/test/lw.sh 'open hub' >/dev/null 2>&1; sleep 3; tools/test/on.sh "tools\\test\\click.ps1 ${X[$room]} 33" >/dev/null 2>&1; sleep 2.5; }
    fi
  done
done
say "explore: $fails failed"
