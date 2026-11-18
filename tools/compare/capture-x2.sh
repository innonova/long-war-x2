#!/usr/bin/env bash
# The port's side of the named views (tools/compare/README.md), captured through the control port into
# logs/compare/x2/<view>.png. The game must be up in a campaign begun (tools/test/new-campaign.sh 1 --begin: EW's hub is
# the strategy layer's root). Each view from the hub's base view, after the facilities are placed (below).
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
  [mission-control]='hub mc|sleep 5'
  [room-research]='hub 0|sleep 3'
  [room-engineering]='hub 1|sleep 3'
  [room-barracks]='hub 2|sleep 3'
  [room-barracks-menu]='hub 2|sleep 3'
  [room-hangar]='hub 3|sleep 3'
  [room-sitroom]='hub 4|sleep 3'
  [scr-research]='hub 0|sleep 2|hub option 0|sleep 4'
  [scr-genelab]='hub 0|sleep 2|hub option 2|sleep 5'
  [scr-builditems]='hub 1|sleep 2|hub option 0|sleep 4'
  [scr-facilities]='hub 1|sleep 2|hub option 1|sleep 5'
  [scr-foundry]='hub 1|sleep 2|hub option 2|sleep 4'
  [scr-repairbay]='hub 1|sleep 2|hub option 3|sleep 4'
  [scr-soldiers]='hub 2|sleep 2|hub option 0|sleep 4'
  [scr-ots]='hub 2|sleep 2|hub option 1|sleep 4'
  [scr-psilabs]='hub 2|sleep 2|hub option 2|sleep 4'
  [scr-memorial]='hub 2|sleep 2|hub option 3|sleep 4'
  [scr-hire]='hub 2|sleep 2|hub option 4|sleep 4'
  [scr-officers]='hub 2|sleep 2|hub option 5|sleep 4'
  [scr-aircraft]='hub 3|sleep 2|hub option 0|sleep 4'
  [scr-satellite]='hub 4|sleep 2|hub option 0|sleep 5'
  [scr-finances]='hub 4|sleep 2|hub option 2|sleep 5'
  [scr-greymarket]='hub 4|sleep 2|hub option 3|sleep 5'
  [scr-requests]='request now|request now|hub 4|sleep 2|hub option 4|sleep 5'
  [scr-shiploadout]='hub 3|sleep 2|hub option 0|sleep 4|click 592 234|sleep 4'
  [dlg-orderjets]='hub 3|sleep 2|hub option 0|sleep 4|click 1234 318|sleep 3'
  [dlg-transfer]='hub 3|sleep 2|hub option 0|sleep 4|click 1234 234|sleep 3'
  [soldier-summary]='open summary|sleep 5'
  [soldier-promotion]='open abilities|sleep 5'
  [soldier-loadout]='open summary|sleep 4|open loadout|sleep 5'
)
order=(base mission-control room-research room-engineering room-barracks room-hangar room-sitroom scr-research scr-genelab scr-builditems
  scr-facilities scr-foundry scr-repairbay scr-soldiers scr-ots scr-psilabs scr-memorial scr-hire scr-officers scr-aircraft scr-satellite
  scr-finances scr-greymarket scr-requests scr-shiploadout dlg-orderjets dlg-transfer soldier-summary soldier-promotion soldier-loadout)
# Once, before the views: every room's menu as full as EW's in the reference save (the facilities placed and an officer
# project bought, test aids; column 4 is the shaft) and a soldier with ranks to show (the first one).
for p in 'base set 1 2 11' 'base set 2 2 22' 'base set 3 2 12' 'base set 6 2 17' 'base set 5 2 23' 'officers buy 0' 'rankup 0 4'; do lw "$p" >/dev/null; done
[ $# -gt 0 ] && order=("$@")
lw 'open hub' >/dev/null
sleep 3
for v in "${order[@]}"; do
  [ -n "${V[$v]:-}" ] || { echo "no view $v"; continue; }
  IFS='|' read -ra steps <<< "${V[$v]}"
  for s in "${steps[@]}"; do
    # ('click x y': a click at a client point, for what only the mouse opens.)
    case "$s" in
      sleep*) sleep "${s#sleep }" ;;
      click*) tools/test/on.sh "tools\\compare\\win.ps1 $s" >/dev/null ;;
      *) lw "$s" >/dev/null ;;
    esac
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
