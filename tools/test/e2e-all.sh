#!/usr/bin/env bash
# Every click journey, each from the start it needs (features/e2e-tests.md): the main menu for first-mission, a campaign at
# EW's base for the others (geoscape-mission on a campaign of its own: it runs time). One line per journey, then the total.
#   tools/test/e2e-all.sh
set -uo pipefail
cd "$(dirname "$0")/../.."
fails=0
# (Each journey from the base's view: a journey can end inside a room, and clicking that room's tab again leaves it. A
# right click leaves a room and does nothing on the base's view.)
run() { local r; tools/test/on.sh 'tools\test\click.ps1 960 540 -Right' 'Start-Sleep 2' 'tools\test\click.ps1 960 540 -Right' 'Start-Sleep 2' >/dev/null 2>&1; r=$(tools/test/e2e.sh "tools/test/e2e/$1.txt" 2>&1 | tail -1); echo "$r"; [[ "$r" == *", 0 failed" ]] || fails=$((fails+1)); }
tools/test/on.sh 'tools\test\stop-game.ps1' 'tools\test\start-game.ps1' 2>&1 | tail -1
run first-mission
tools/test/new-campaign.sh 1 --begin 2>&1 | tail -1
for j in base-menus aek-repro soldier-and-rooms strategy-actions base-building hangar satellite psi-labs gray-market foundry officers gene-mods; do run "$j"; done
tools/test/new-campaign.sh 1 --begin 2>&1 | tail -1
run geoscape-mission
# (A shot, from a mission's first turn: to-mission.sh's own campaign.)
tools/test/to-mission.sh 2>&1 | tail -1
run ability-bar
run shot
# (The Motion Tracker, from a mission of its own with the item on the first ten soldiers: whoever the squad takes has one.)
gives=(); for i in 0 1 2 3 4 5 6 7 8 9; do gives+=("give-to $i LWSmall_222"); done
tools/test/to-mission.sh "${gives[@]}" 2>&1 | tail -1
run motion-tracker
echo "e2e-all: $fails journeys with failures"
