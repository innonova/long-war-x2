#!/usr/bin/env bash
# Enemy Within's side of the named views (tools/compare/README.md), captured by clicks into logs/compare/ew/<view>.png.
# EW must be up (tools/ew-test/start-ew.ps1) with a strategy save loaded and its base in view; the clicks are in EW's
# client pixels at 1600 x 900 (tools/compare/win.ps1). Each view starts from the base's view and goes back to it.
#   tools/compare/capture-ew.sh [view …]     (all views without arguments)
set -euo pipefail
cd "$(dirname "$0")/../.."
host=${LWX2_HOST:-wingpu}
out=logs/compare/ew
mkdir -p "$out"
# The room tabs over the base's view; a room's own menu below its tab (EW's submenu; x, then each option's y).
R=624 E=770 B=922 H=1040 S=1194
click() { echo "tools\\compare\\win.ps1 click $1 $2"; }
# Each view: clicks, then how many times EW's back arrow (bottom left) leads back to the base.
declare -A V=(
  [base]='|0'
  [room-research]="$(click $R 28)|1"
  [room-engineering]="$(click $E 28)|1"
  [room-barracks]="$(click $B 28)|1"
  [room-hangar]="$(click $H 28)|1"
  [room-sitroom]="$(click $S 28)|1"
  [scr-research]="$(click $R 28);$(click 764 84)|2"
  [scr-genelab]="$(click $R 28);$(click 764 164)|2"
  [scr-builditems]="$(click $E 28);$(click 860 80)|2"
  [scr-facilities]="$(click $E 28);$(click 860 120)|2"
  [scr-foundry]="$(click $E 28);$(click 860 160)|2"
  [scr-repairbay]="$(click $E 28);$(click 860 200)|2"
  [scr-ots]="$(click $B 28);$(click 880 125)|2"
  [scr-psilabs]="$(click $B 28);$(click 880 165)|2"
  [scr-officers]="$(click $B 28);$(click 880 285)|2"
  [scr-aircraft]="$(click $H 28);$(click 1030 85)|2"
  [scr-satellite]="$(click $S 28);$(click 1192 83)|2"
  [scr-greymarket]="$(click $S 28);$(click 1192 205)|2"
  [scr-requests]="$(click $S 28);$(click 1192 245)|2"
  [mission-control]="$(click 796 806)|1"
)
order=(base room-research room-engineering room-barracks room-hangar room-sitroom scr-research scr-genelab scr-builditems
  scr-facilities scr-foundry scr-repairbay scr-ots scr-psilabs scr-officers scr-aircraft scr-satellite scr-greymarket
  scr-requests mission-control)
[ $# -gt 0 ] && order=("$@")
for v in "${order[@]}"; do
  [ -n "${V[$v]:-}" ] || { echo "no view $v"; continue; }
  clicks=${V[$v]%|*}
  backs=${V[$v]##*|}
  lines=()
  IFS=';' read -ra cs <<< "$clicks"
  for c in "${cs[@]}"; do [ -n "$c" ] && lines+=("$c" 'Start-Sleep 4'); done
  lines+=('Start-Sleep 1' 'tools\compare\win.ps1 shot C:\Users\aekms\cmp.png')
  for _ in $(seq 1 "$backs"); do lines+=("$(click 80 854)" 'Start-Sleep 3'); done
  tools/test/on.sh "${lines[@]}" >/dev/null
  scp -q "$host:cmp.png" "$out/$v.png"
  echo "$v"
done
