#!/usr/bin/env bash
# The port's side of the named views (tools/compare/README.md), captured through the control port into
# logs/compare/x2/<view>.png. The game must be up in a campaign begun (tools/test/new-campaign.sh 1 --begin: EW's hub is
# the strategy layer's root). Mission Control is captured first if it is on top, then each view from the hub's base view.
#   tools/compare/capture-x2.sh [view …]     (all views without arguments)
set -euo pipefail
cd "$(dirname "$0")/../.."
host=${LWX2_HOST:-wingpu}
out=logs/compare/x2
mkdir -p "$out"
lw() { tools/test/lw.sh "$@" | grep -v '^>' || true; }
esc() { lw 'key 510' >/dev/null; sleep 2; }
# Each view: control-port commands from the hub's base view ('sleep n' waits), then the capture, then back to the base.
declare -A V=(
  [base]='sleep 1'
  [room-research]='hub 0|sleep 3'
  [room-engineering]='hub 1|sleep 3'
  [room-barracks]='hub 2|sleep 3'
  [room-hangar]='hub 3|sleep 3'
  [room-sitroom]='hub 4|sleep 3'
  [scr-research]='hub 0|sleep 2|hub option 0|sleep 4'
  [scr-builditems]='hub 1|sleep 2|hub option 0|sleep 4'
  [scr-facilities]='hub 1|sleep 2|hub option 1|sleep 5'
  [scr-aircraft]='hub 3|sleep 2|hub option 0|sleep 4'
  [scr-satellite]='hub 4|sleep 2|hub option 0|sleep 5'
  [scr-sitroom]='hub 4|sleep 2|hub option 1|sleep 5'
  [scr-greymarket]='hub 4|sleep 2|hub option 2|sleep 5'
  [scr-soldiers]='hub 2|sleep 2|hub option 0|sleep 4'
  [soldier-summary]='open armory|sleep 5'
  [soldier-loadout]='open loadout|sleep 5'
  [soldier-promotion]='open promotion|sleep 5'
)
order=(base room-research room-engineering room-barracks room-hangar room-sitroom scr-research scr-builditems scr-facilities
  scr-aircraft scr-satellite scr-sitroom scr-greymarket scr-soldiers soldier-summary soldier-loadout soldier-promotion)
[ $# -gt 0 ] && order=("$@")
if [[ " ${order[*]} " == *" mission-control "* ]] || [ $# -eq 0 ]; then
  case "$(lw state)" in
    *screen=UILWEWMissionControl*)
      tools/test/on.sh 'tools\compare\win.ps1 shot C:\Users\aekms\cmp.png' >/dev/null
      scp -q "$host:cmp.png" "$out/mission-control.png"; echo "mission-control: UILWEWMissionControl" ;;
    *) echo "mission-control: not on top (a campaign just made has it), skipped" ;;
  esac
fi
lw 'open hub' >/dev/null
sleep 3
for v in "${order[@]}"; do
  [ -n "${V[$v]:-}" ] || { echo "no view $v"; continue; }
  IFS='|' read -ra steps <<< "${V[$v]}"
  for s in "${steps[@]}"; do
    case "$s" in sleep*) sleep "${s#sleep }" ;; *) lw "$s" >/dev/null ;; esac
  done
  tools/test/on.sh 'tools\compare\win.ps1 shot C:\Users\aekms\cmp.png' >/dev/null
  scp -q "$host:cmp.png" "$out/$v.png"
  echo "$v: $(lw state | sed -n 's/.*screen=\([^ ]*\).*/\1/p')"
  # Back to the hub's base view: screens closed, the room left.
  for _ in 1 2 3; do
    case "$(lw state)" in *screen=UILWEWHub*) break ;; esac
    esc
  done
  lw 'hub back' >/dev/null
  sleep 2
done
