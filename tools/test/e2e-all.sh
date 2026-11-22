#!/usr/bin/env bash
# Every click journey, each from the start it needs (features/e2e-tests.md): the main menu for first-mission, a campaign at
# EW's base for the others (geoscape-mission on a campaign of its own: it runs time). One line per journey, then the total.
#   tools/test/e2e-all.sh
set -uo pipefail
cd "$(dirname "$0")/../.."
fails=0
run() { local r; r=$(tools/test/e2e.sh "tools/test/e2e/$1.txt" 2>&1 | tail -1); echo "$r"; [[ "$r" == *", 0 failed" ]] || fails=$((fails+1)); }
tools/test/on.sh 'tools\test\stop-game.ps1' 'tools\test\start-game.ps1' 2>&1 | tail -1
run first-mission
tools/test/new-campaign.sh 1 --begin 2>&1 | tail -1
for j in base-menus aek-repro soldier-and-rooms strategy-actions; do run "$j"; done
tools/test/new-campaign.sh 1 --begin 2>&1 | tail -1
run geoscape-mission
echo "e2e-all: $fails journeys with failures"
