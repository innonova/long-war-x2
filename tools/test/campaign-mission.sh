#!/usr/bin/env bash
# A campaign mission from the Long War headquarters, from here (experiments 2 and 4, the classes):
# starts the game (the build already done: tools/test/build.ps1), a new test campaign (TEST
# CAMPAIGN; the rookies become Long War Corporals, PromoteRookies), skips the intro, opens the
# LONG WAR HQ, and with --launch sends the squad on a mission and waits until the soldiers can
# move (the EW map placed when PlaceEWMapWhole is on). Screenshots to the given local path; our
# log lines printed. The game is left running.
#   tools/test/campaign-mission.sh /tmp/lwtree-shot.png [--launch]
# The clicks are the screens' places in the 1600x900 window: if a screen moves, they do too.
set -euo pipefail
cd "$(dirname "$0")/../.."
out=${1:?usage: campaign-mission.sh <local png> [--launch]}
host=${LWX2_HOST:-wingpu}
log='C:\Users\aekms\Documents\My Games\XCOM2 War of the Chosen\XComGame\Logs\Launch.log'
on() { tools/test/on.sh "$@" >/dev/null 2>&1; }
# Waits (5 s steps) for a log line matching $1, the game's failure, or its end; prints it.
waitfor() {
  local r=''
  for _ in $(seq 1 "${2:-60}"); do
    sleep 5
    r=$(ssh "$host" "Get-Content '$log' | Select-String '$1|appError' | % Line; if (-not (Get-Process XCom2 -ErrorAction SilentlyContinue)) { 'GAME GONE' }" 2>&1 | tr -d '\r')
    [ -n "$r" ] && break
  done
  echo "$r" | tail -1 | cut -c1-220
  ! echo "$r" | grep -q 'appError\|GAME GONE'
}
shot() { on 'tools\test\shot.ps1 C:\Users\aekms\lwx2-shot.png'; scp -q "$host:lwx2-shot.png" "$out"; }

on 'tools\test\stop-game.ps1' || true
tools/test/on.sh 'tools\test\start-game.ps1' 'tools\test\click.ps1 200 102' 2>&1 | tail -1
# Difficulty: Next; no Ironman: Start; the tutorial question: No.
sleep 6; on 'tools\test\click-screen.ps1 784 625'; sleep 4; on 'tools\test\click-screen.ps1 645 511'; sleep 6; on 'tools\test\click-screen.ps1 688 563'
waitfor 'test barracks'
# The intro: skipped; the after-action report: Continue; then the LONG WAR HQ button.
sleep 4; on 'tools\test\focus.ps1' 'tools\test\esc.ps1'; sleep 6; on 'tools\test\click-screen.ps1 808 899'
sleep 8
for _ in $(seq 1 20); do
  on 'tools\test\focus.ps1' 'tools\test\click.ps1 100 135'
  sleep 3
  ssh "$host" "Get-Content '$log' | Select-String 'Long War HQ shown' -Quiet" 2>&1 | grep -q True && break
done
waitfor 'Long War HQ shown' 2
if [ "${2:-}" = --launch ]; then
  on 'tools\test\click-screen.ps1 399 778' # LAUNCH MISSION
  waitfor 'Long War HQ: launching' 6
  waitfor 'Waiting for player confirmation' 60
  sleep 3; on 'tools\test\focus.ps1' 'tools\test\click-screen.ps1 745 522' # the briefing's launch
  waitfor 'tactical HUD'
  sleep 25; on 'tools\test\focus.ps1' 'tools\test\click-screen.ps1 991 619' # a first-time tip, if any
fi
sleep 2; shot
ssh "$host" "Get-Content '$log' | Select-String 'LongWarX2: LongWarX2' | % Line | Select-Object -Last 8" 2>&1 | tr -d '\r' | cut -c1-240
