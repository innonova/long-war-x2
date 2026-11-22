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
#   key <key>         a key pressed (key.ps1's names: Space, Enter, W ...)
#   expect <text>     the top screen's class holds text (FAIL otherwise)
#   lw <command>      a control-port command (setup only, never the thing tested)
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
    rclick) r=$(tools/test/on.sh "tools\\test\\click-label.ps1 \"$arg\" -Right" 2>&1 | tail -1); sleep 1.5 ;;
    tab)    case "$arg" in RESEARCH) x=809;; ENGINEERING) x=985;; BARRACKS) x=1164;; HANGAR) x=1313;; "SITUATION ROOM") x=1495;; *) x=0;; esac
            if [ "$x" = 0 ]; then r="ERR no tab $arg"; else r=$(tools/test/on.sh "tools\\test\\click.ps1 $x 33" 2>&1 | tail -1); r="tab $arg at $x 33 $r"; fi; sleep 1.5 ;;
    back)   r=$(tools/test/on.sh 'tools\test\click.ps1 96 1027' 2>&1 | tail -1); sleep 1.5 ;;
    esc)    r=$(tools/test/on.sh 'tools\test\esc.ps1' 2>&1 | tail -1); sleep 1.5 ;;
    key)    r=$(tools/test/on.sh 'tools\test\focus.ps1' "tools\\test\\key.ps1 $arg 150" 2>&1 | tail -1); sleep 1.5 ;;
    rmb)    r=$(tools/test/on.sh 'tools\test\click.ps1 960 540 -Right' 2>&1 | tail -1); sleep 1.5 ;;
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
