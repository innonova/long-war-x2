#!/usr/bin/env bash
# The E2E click tests (features/e2e-tests.md): a journey through the game driven as a player drives it, by real clicks
# on labels the screen shows (OCR), keys and the corner back button, each step checked against the screen expected
# (the control port's state) and photographed. The game must be up (e.g. tools/test/new-campaign.sh 1 --begin).
#   tools/test/e2e.sh tools/test/e2e/<journey>.txt
# A journey, one step a line (# comments):
#   click <label>     a label on screen, clicked (rclick <label>: right-clicked)
#   tab <room>        one of EW's room tabs clicked at its place (Windows' OCR misses that row in some states; the tabs
#                     do not move): RESEARCH ENGINEERING BARRACKS HANGAR SITUATION ROOM
#   back              the corner back arrow clicked     esc        Esc pressed     rmb        a right click mid-screen
#   see <text>        the text on screen (OCR, spaces ignored; FAIL otherwise): a result the screen shows
#   unseen <text>     the text not on screen (OCR; FAIL if it is): a placeholder or an error that should not show
#   waitsee <text> <s> the text on screen within s seconds (OCR again and again): a notice that comes and goes
#   maybe <label>     a label clicked if it is on screen (a page that comes only sometimes); no FAIL otherwise
#   escto <screen> <n> Esc pressed until the screen holds text, at most n times (an alert that may come or not)
#   key <key>         a key pressed (key.ps1's names: Space, Enter, W ...)
#   at <x> <y>        a click at a place in the 1920x1080 UI (a list's row, whose label is a random name)
#   expect <text>     the top screen's class holds text (FAIL otherwise)
#   lw <command>      a control-port command (setup only, never the thing tested)
#   until <cmd>|<text>|<setup cmd>|<n> setup: the setup command run (at most n times) until the state command holds text
#   lwsave <name> <cmd>|<regex> / lwdiff <name> <cmd>|<regex>|<change>: a number in the game's state kept, then its
#                     change checked (the corpses sold: -2)
#   lwsee <cmd>|<text> the game's state (a control-port command's answer) holds text (~regex): what the clicks did, where the
#                     screen shows it too faintly to read
#   wait <s>          shot <name>
#   waitfor <text> <s> wait until the game's state line (phase, map, screen) holds text, at most s seconds (FAIL after)
#   rec <name> <s>    a video of the next s seconds (in the background; fetched at the end with a frame strip per
#                     quarter second, logs/e2e/<journey>/<name>.mp4 and <name>-strip.png)
set -uo pipefail
cd "$(dirname "$0")/../.."
journey=$1; name=$(basename "$journey" .txt); out=logs/e2e/$name; mkdir -p "$out"; rm -f "$out"/*.png
n=0; fails=0; clips=""; log="$out/run.log"; : > "$log"
screen() { tools/test/lw.sh state 2>/dev/null | sed -n 's/.*screen=\([^ ]*\).*/\1/p' | tail -1; }
say() { echo "$*" | tee -a "$log"; }
exec 3< "$journey"
while IFS= read -r line <&3 || [ -n "$line" ]; do
  line=${line%%#*}; line=$(echo "$line" | sed 's/[[:space:]]*$//'); [ -z "$line" ] && continue
  n=$((n+1)); op=${line%% *}; arg=${line#* }; [ "$arg" = "$line" ] && arg=""
  exec </dev/null
  case "$op" in
    click)  r=$(tools/test/on.sh "tools\\test\\click-label.ps1 \"$arg\"" 2>&1 | tail -1); sleep 1.5 ;;
    see)    t=$(tools/test/on.sh 'tools\test\ocr.ps1 -Invert' 'tools\test\ocr.ps1' 2>&1 | cut -d' ' -f5- | tr '\n' '|'); if printf '%s' "$t" | tr -d ' ' | grep -qiF -- "${arg// /}"; then r="ok (seen: $arg)"; else r="FAIL: '$arg' not on screen; read: ${t:0:300}"; fails=$((fails+1)); fi ;;
    unseen) t=$(tools/test/on.sh 'tools\\test\\ocr.ps1 -Invert' 'tools\\test\\ocr.ps1' 2>&1 | cut -d' ' -f5- | tr '\n' '|'); if printf '%s' "$t" | tr -d ' ' | grep -qiF -- "${arg// /}"; then r="FAIL: '$arg' on screen"; fails=$((fails+1)); else r="ok (not seen: $arg)"; fi ;;
    waitsee) txt="${arg% *}"; lim="${arg##* }"; t0=$SECONDS; r="FAIL: '$txt' not seen within ${lim}s"
            while (( SECONDS - t0 < lim )); do t=$(tools/test/on.sh 'tools\test\ocr.ps1 -Invert' 2>&1 | cut -d' ' -f5- | tr '\n' '|'); if printf '%s' "$t" | tr -d ' ' | grep -qiF -- "${txt// /}"; then r="ok after $((SECONDS - t0))s (seen: $txt)"; break; fi; done
            [[ "$r" == FAIL* ]] && fails=$((fails+1)) ;;
    maybe)  r=$(tools/test/on.sh "tools\\test\\click-label.ps1 \"$arg\"" 2>&1 | tail -1); case "$r" in ERR*) r="(none: $arg)";; esac; sleep 1.5 ;;
    rclick) r=$(tools/test/on.sh "tools\\test\\click-label.ps1 \"$arg\" -Right" 2>&1 | tail -1); sleep 1.5 ;;
    tab)    case "$arg" in RESEARCH) x=809;; ENGINEERING) x=985;; BARRACKS) x=1164;; HANGAR) x=1313;; "SITUATION ROOM") x=1495;; *) x=0;; esac
            if [ "$x" = 0 ]; then r="ERR no tab $arg"; else r=$(tools/test/on.sh "tools\\test\\click.ps1 $x 33" 2>&1 | tail -1); r="tab $arg at $x 33 $r"; fi; sleep 1.5 ;;
    back)   r=$(tools/test/on.sh 'tools\test\click.ps1 96 1027' 2>&1 | tail -1); sleep 1.5 ;;
    esc)    r=$(tools/test/on.sh 'tools\test\esc.ps1' 2>&1 | tail -1); sleep 1.5 ;;
    at)     r=$(tools/test/on.sh "tools\\test\\click.ps1 $arg" 2>&1 | tail -1); r="clicked at $arg${r:+ $r}"; sleep 1.5 ;;
    key)    r=$(tools/test/on.sh 'tools\test\focus.ps1' "tools\\test\\key.ps1 $arg 150" 2>&1 | tail -1); sleep 1.5 ;;
    escto)  want="${arg% *}"; max="${arg##* }"; r="FAIL: not back to $want after $max Esc"
            for ((k = 0; k < max; k++)); do [[ "$(screen)" == *"$want"* ]] && { r="ok after $k Esc"; break; }; tools/test/on.sh 'tools\test\esc.ps1' >/dev/null 2>&1; sleep 1.5; done
            [[ "$r" == FAIL* && "$(screen)" == *"$want"* ]] && r="ok after $max Esc"
            [[ "$r" == FAIL* ]] && fails=$((fails+1)) ;;
    rmb)    r=$(tools/test/on.sh 'tools\test\click.ps1 960 540 -Right' 2>&1 | tail -1); sleep 1.5 ;;
    until)  IFS='|' read -r c txt act max <<< "$arg"; r="FAIL: '$txt' not in '$c' after $max x '$act'"
            for ((k = 0; k < max; k++)); do o=$(tools/test/lw.sh "$c" 2>&1 | grep -v '^>'); if printf '%s' "$o" | grep -qiF -- "$txt"; then r="ok after $k x '$act'"; break; fi; if [[ "$act" == key:* ]]; then tools/test/on.sh 'tools\test\focus.ps1' "tools\\test\\key.ps1 ${act#key:} 150" >/dev/null 2>&1; sleep 1.5; else tools/test/lw.sh "$act" >/dev/null 2>&1; fi; done
            [[ "$r" == FAIL* ]] && fails=$((fails+1)) ;;
    lwsave) nm="${arg%% *}"; rest="${arg#* }"; c="${rest%%|*}"; rx="${rest#*|}"; v=$(tools/test/lw.sh "$c" 2>&1 | grep -v '^>' | grep -oE -- "$rx" | grep -oE '[0-9]+' | head -1)
            if [ -n "$v" ]; then declare -g "saved_$nm=$v"; r="ok ($nm = $v)"; else r="FAIL: no number for '$rx' in '$c'"; fails=$((fails+1)); fi ;;
    lwdiff) nm="${arg%% *}"; rest="${arg#* }"; c="${rest%%|*}"; rest2="${rest#*|}"; rx="${rest2%|*}"; want="${rest2##*|}"; v=$(tools/test/lw.sh "$c" 2>&1 | grep -v '^>' | grep -oE -- "$rx" | grep -oE '[0-9]+' | head -1)
            old="saved_$nm"; d=$(( ${v:-0} - ${!old:-0} )); if [ -n "$v" ] && [ "$d" = "$want" ]; then r="ok ($nm ${!old} -> $v)"; else r="FAIL: $nm ${!old:-?} -> ${v:-?}, not $want"; fails=$((fails+1)); fi ;;
    lwsee)  c="${arg%%|*}"; txt="${arg#*|}"; o=$(tools/test/lw.sh "$c" 2>&1 | grep -v '^>'); if { [[ "$txt" == "~"* ]] && printf '%s' "$o" | grep -qiE -- "${txt#\~}"; } || { [[ "$txt" != "~"* ]] && printf '%s' "$o" | grep -qiF -- "$txt"; }; then r="ok (the game's state: $txt)"; else r="FAIL: '$txt' not in '$c': ${o:0:200}"; fails=$((fails+1)); fi ;;
    lw)     r=$(tools/test/lw.sh "$arg" 2>&1 | tail -1); sleep 1 ;;
    wait)   sleep "$arg"; r="" ;;
    waitfor) wt=${arg% *}; ws=${arg##* }; t0=$(date +%s); r="FAIL: no '$wt' within ${ws}s"
            while [ $(( $(date +%s) - t0 )) -lt "$ws" ]; do st=$(tools/test/lw.sh state 2>/dev/null | tail -1); if [[ "$st" == *"$wt"* ]]; then r="ok after $(( $(date +%s) - t0 ))s ($st)"; break; fi; sleep 5; done
            [[ "$r" == FAIL* ]] && fails=$((fails+1)) ;;
    rec)    rn=${arg%% *}; rs=${arg#* }; r=$(tools/test/on.sh "tools\\test\\record.ps1 C:\\Users\\aekms\\e2e-$rn.mp4 $rs" 2>&1 | tail -1); clips="$clips $rn" ;;
    shot)   tools/test/shot.sh "$out/$arg.png" >/dev/null 2>&1; r="shot $arg" ;;
    expect) s=$(screen); if [[ "$s" == *"$arg"* ]]; then r="ok ($s)"; else r="FAIL: expected $arg, got $s"; fails=$((fails+1)); fi ;;
    *)      r="ERR unknown step"; fails=$((fails+1)) ;;
  esac
  [[ "$r" == ERR* ]] && fails=$((fails+1))
  [ "$op" != shot ] && [ "$op" != expect ] && [ "$op" != wait ] && tools/test/shot.sh "$out/$(printf %02d $n).png" >/dev/null 2>&1
  say "$(printf %02d $n) $line -> ${r}"
done
# The clips fetched, each with a strip of frames every quarter second (what a still misses: transitions, flicker).
sleep 2
for c in $clips; do
  scp -q "wingpu:e2e-$c.mp4" "$out/$c.mp4" 2>/dev/null || { say "clip $c: not fetched"; continue; }
  rm -rf "$out/.f-$c"; mkdir -p "$out/.f-$c"
  ffmpeg -loglevel error -i "$out/$c.mp4" -vf "fps=4,scale=400:-1" "$out/.f-$c/%03d.png" 2>/dev/null
  montage "$out/.f-$c/"*.png -tile 6x -geometry +2+2 -background black "$out/$c-strip.png" 2>/dev/null
  rm -rf "$out/.f-$c"
  say "clip $c: $out/$c.mp4, strip $out/$c-strip.png"
done
say "$name: $n steps, $fails failed"
[ "$fails" -eq 0 ]
