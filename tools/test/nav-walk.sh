#!/usr/bin/env bash
# The base's navigation walked by clicks and read off the screen (features/nav-map.md), the same way in either game: for
# each room tab, the room's own screen read (OCR), then its menu's entries clicked one by one, each screen that opens read
# and photographed, and left by the corner arrow (Esc for a dialog). Written to logs/nav/<tag>/: index.tsv (room, entry,
# screen class where the control port answers, the way back's result, lines read) and per screen its OCR lines
# ("x y w h text", the game's 1920x1080 UI coordinates) and a screenshot. Not committed: it holds the games' words.
# XCOM 2 with the port in a campaign at EW's base (tools/test/new-campaign.sh 1 --begin), tag "port"; or Enemy Within in
# its harness at the base (tools/ew-test/start-ew.ps1 and a save loaded), tag "ew": the scripts take EW's window when
# XCOM 2 is not running (game.ps1), and EW's HUD puts its room tabs where the port's (EW's own movie) does.
# tools/test/nav-compare.mjs then sets the two side by side.
#   tools/test/nav-walk.sh <port|ew> [room …]
set -uo pipefail
cd "$(dirname "$0")/../.."
tag=${1:?usage: nav-walk.sh <port|ew> [room …]}; shift
out=logs/nav/$tag; mkdir -p "$out"; index="$out/index.tsv"
# (All rooms: the walk read afresh; some: those rooms read again, the others kept.)
if [ $# -eq 0 ] || [ ! -f "$index" ]; then rm -rf "${out:?}"/*; printf 'room\tentry\tscreen\tback\tlines\n' > "$index"
else for room in "$@"; do grep -v -P "^\Q$room\E\t" "$index" > "$index.tmp"; mv "$index.tmp" "$index"; rm -rf "$out/$(echo "$room" | tr ' /:' '___' | tr -cd 'A-Za-z0-9_-')"; done; fi
say() { echo "$*" | tee -a "$out/run.log"; }
screen() { [ "$tag" = port ] && tools/test/lw.sh state 2>/dev/null | sed -n 's/.*screen=\([^ ]*\).*/\1/p' | tail -1; }
# (What is on the screen: both OCR passes, the plain and the inverted (each misses rows the other reads), merged.)
read_screen() {
  { tools/test/on.sh 'tools\test\ocr.ps1' 2>/dev/null; tools/test/on.sh 'tools\test\ocr.ps1 -Invert' 2>/dev/null; } | tr -d '\r' | grep -E '^[0-9]+ [0-9]+ [0-9]+ [0-9]+ ' | sort -u -k5 > "$1"
}
slugify() { echo "$*" | tr ' /:' '___' | tr -cd 'A-Za-z0-9_-'; }
# (The room tabs' places in the UI: the port's HUD stands them a little right of EW's own.)
if [ "$tag" = port ]; then declare -A X=([RESEARCH]=809 [ENGINEERING]=985 [BARRACKS]=1164 [HANGAR]=1313 ["SITUATION ROOM"]=1495)
else declare -A X=([RESEARCH]=750 [ENGINEERING]=928 [BARRACKS]=1105 [HANGAR]=1252 ["SITUATION ROOM"]=1437); fi
rooms=("$@"); [ ${#rooms[@]} -eq 0 ] && rooms=(RESEARCH ENGINEERING BARRACKS HANGAR "SITUATION ROOM")
for room in "${rooms[@]}"; do
  rs=$(slugify "$room"); mkdir -p "$out/$rs"
  tools/test/on.sh "tools\\test\\click.ps1 ${X[$room]} 33" >/dev/null 2>&1; sleep 3
  read_screen "$out/$rs/_room.txt"; tools/test/shot.sh "$out/$rs/_room.png" >/dev/null 2>&1
  # (The room's menu: upper-case lines in the menu column, x 700-1350, y 70-330 of the UI; where each was read, to click
  # there when OCR does not find the label again.)
  declare -A AT=()
  while read -r x y w h t; do AT["$t"]="$((x + w / 2)) $((y + h / 2))"; done < <(awk '$1>=700 && $1<=1350 && $2>=70 && $2<=330' "$out/$rs/_room.txt" | awk '{t=$0; sub(/^[0-9]+ [0-9]+ [0-9]+ [0-9]+ /,"",t); u=t; l=t; nu=gsub(/[A-Z]/,"",u); nl=gsub(/[a-z]/,"",l); if (nu >= 4 && nl * 5 <= nu) print}')
  mapfile -t items < <(printf '%s\n' "${!AT[@]}" | grep . | sort)
  say "== $room: ${#items[@]} entries: ${items[*]}"
  printf '%s\t\t%s\t\t%s\n' "$room" "$(screen)" "$(grep -c . "$out/$rs/_room.txt")" >> "$index"
  for it in "${items[@]}"; do
    es=$(slugify "$it")
    r=$(tools/test/on.sh "tools\\test\\click-label.ps1 \"$it\"" 2>&1 | tail -1 | tr -d '\r'); sleep 3
    [[ "$r" == ERR* && -n "${AT[$it]:-}" ]] && { r=$(tools/test/on.sh "tools\\test\\click.ps1 ${AT[$it]}" 2>&1 | tail -1 | tr -d '\r'); sleep 3; }
    s=$(screen)
    read_screen "$out/$rs/$es.txt"; tools/test/shot.sh "$out/$rs/$es.png" >/dev/null 2>&1
    n=$(grep -c . "$out/$rs/$es.txt")
    if [[ "$r" == ERR* ]]; then say "  $it: click failed ($r)"; printf '%s\t%s\t%s\t%s\t%s\n' "$room" "$it" "$s" "click failed" "$n" >> "$index"; continue; fi
    # (The way back: the corner arrow; a dialog's Cancel by Esc. In EW, whether it went back is judged by the room's
    # menu being read again.)
    # (EW names no screen: a dialog is told by its own CANCEL, which the corner arrow does not close.)
    if [[ "$s" == UIDialogueBox || "$s" == UILWEWHiring || "$s" == UILWEWPendingRequests ]] || { [ "$tag" = ew ] && grep -qE ' (CANCEL|Cancel|CONTINUE|Continue|OK)$' "$out/$rs/$es.txt"; }; then tools/test/on.sh 'tools\test\esc.ps1' >/dev/null 2>&1
    else tools/test/on.sh 'tools\test\click.ps1 96 1027' >/dev/null 2>&1; fi
    sleep 3
    b=back
    if [ "$tag" = port ]; then [ "$(screen)" = UILWEWHub ] || b="left $(screen) on top"
    else
      # (EW's menu comes back with its slide-in: read twice before calling it lost.)
      tools/test/on.sh 'tools\test\ocr.ps1 -Invert' 2>/dev/null | tr -d '\r' | grep -qF "$it" \
        || { sleep 2; tools/test/on.sh 'tools\test\ocr.ps1 -Invert' 2>/dev/null | tr -d '\r' | grep -qF "$it"; } || b="room menu not seen again"
    fi
    say "  $it: ${s:-?}, $n lines, $b"
    printf '%s\t%s\t%s\t%s\t%s\n' "$room" "$it" "$s" "$b" "$n" >> "$index"
    if [ "$b" != back ]; then
      # (The port: Esc, as its screens take it. EW: Esc at the room opens its pause menu, which then swallowed the next
      # entry's click; the corner arrow once more instead.)
      if [ "$tag" = port ]; then tools/test/on.sh 'tools\test\esc.ps1' >/dev/null 2>&1
      else tools/test/on.sh 'tools\test\click.ps1 96 1027' >/dev/null 2>&1; fi
      sleep 2
      tools/test/on.sh "tools\\test\\click.ps1 ${X[$room]} 33" >/dev/null 2>&1; sleep 3
    fi
  done
  unset AT
done
say "nav-walk $tag: $(($(wc -l < "$index") - 1)) screens read into $out"
