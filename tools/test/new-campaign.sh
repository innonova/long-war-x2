#!/usr/bin/env bash
# A new campaign on the test machine, by the control port (development builds): the game started,
# the campaign made from the main menu (no tutorial, no intro), its reports passed, the LONG WAR
# GEOSCAPE opened. Without the first mission unless --first (then it stops in the mission: lw.sh win).
#   tools/test/new-campaign.sh [difficulty 0-3] [--first]
set -euo pipefail
cd "$(dirname "$0")/../.."
d=${1:-1}
first=''
[ "${2:-}" = --first ] && first=first
tools/test/on.sh 'tools\test\start-game.ps1' 2>&1 | tail -1
tools/test/lw.sh "campaign $d $first" | grep -v '^>'
[ -n "$first" ] && exit 0
# Until the base: each report passed as it comes.
for _ in $(seq 1 40); do
  sleep 4
  r=$(tools/test/lw.sh continue 2>/dev/null | grep -v '^>' || true)
  case "$r" in *"nothing to continue: UIFacilityGrid"*) break ;; esac
done
tools/test/lw.sh geoscape geo | grep -v '^>' | sed -n 2p
