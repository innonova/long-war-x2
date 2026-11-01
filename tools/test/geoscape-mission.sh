#!/usr/bin/env bash
# A Geoscape mission round trip, from here (features/lw-geoscape.md): a new test campaign to the
# LONG WAR GEOSCAPE (tools/test/campaign-mission.sh), time run until the aliens' first abductions,
# the squad sent (RESPOND), the mission entered and ended as won (ShowTestEndMission), the
# reports passed, the Geoscape opened again: its account of the mission printed. Screenshots of
# the Geoscape before and after to <local prefix>-before.png and -after.png. The game is left
# running. The build already done (tools/test/build.ps1).
#   tools/test/geoscape-mission.sh /tmp/lwtree-geo
# The clicks are the screens' places: if a screen moves, they do too.
set -euo pipefail
cd "$(dirname "$0")/../.."
out=${1:?usage: geoscape-mission.sh <local png prefix>}
host=${LWX2_HOST:-wingpu}
log='C:\Users\aekms\Documents\My Games\XCOM2 War of the Chosen\XComGame\Logs\Launch.log'
on() { tools/test/on.sh "$@" >/dev/null 2>&1; }
lines() { ssh "$host" "Get-Content '$log' | Select-String '$1' | % Line" 2>&1 | tr -d '\r'; }
# Waits (5 s steps) for a log line matching $1, the game's failure, or its end; prints it.
waitfor() {
  local r=''
  for _ in $(seq 1 "${2:-60}"); do
    sleep 5
    r=$(ssh "$host" "Get-Content '$log' | Select-String '$1|appError' | % Line; if (-not (Get-Process XCom2 -ErrorAction SilentlyContinue)) { 'GAME GONE' }" 2>&1 | tr -d '\r')
    [ -n "$r" ] && break
  done
  echo "$r" | tail -1 | cut -c1-200
  ! echo "$r" | grep -q 'appError\|GAME GONE'
}
shot() { on 'tools\test\shot.ps1 C:\Users\aekms\lwx2-shot.png'; scp -q "$host:lwx2-shot.png" "$1"; }

tools/test/campaign-mission.sh "$out-start.png" | tail -1
# RUN TIME until abductions are on the map (each press runs to the next event).
for _ in $(seq 1 15); do
  on 'tools\test\click.ps1 1290 975' 'Start-Sleep 2'
  [ -n "$(lines 'Geoscape: Abductions in')" ] && break
done
lines 'Geoscape: Abductions in' | tail -1 | cut -c1-200
shot "$out-before.png"
# The first action button: RESPOND. The briefing's launch if it asks; then the mission.
on 'tools\test\click.ps1 1080 237'
waitfor 'tactical HUD' 90
# First-time tips (CONFIRM) can come late and cover the button: both clicked until the mission ends.
sleep 20
for _ in $(seq 1 12); do
  on 'tools\test\focus.ps1' 'tools\test\click-screen.ps1 991 619' 'Start-Sleep 2' 'tools\test\click-screen.ps1 172 209' # LONG WAR TEST: END MISSION AS WON
  sleep 5
  [ -n "$(lines 'test: mission ended as won')" ] && break
done
waitfor 'test: mission ended as won' 2
# The mission report's Continue, the Skyranger's "any key", the after-action report's Continue.
sleep 20; on 'tools\test\focus.ps1' 'tools\test\click-screen.ps1 808 899'
sleep 30; on 'tools\test\focus.ps1' 'tools\test\click-screen.ps1 750 479'
sleep 40; on 'tools\test\focus.ps1' 'tools\test\click-screen.ps1 808 899'
sleep 10
for _ in $(seq 1 10); do
  on 'tools\test\focus.ps1' 'tools\test\click.ps1 100 135'
  sleep 4
  [ "$(lines 'Long War Geoscape shown' | wc -l)" -ge 2 ] && break
done
shot "$out-after.png"
lines 'Geoscape: The mission in|Geoscape: The abductions' | tail -2 | cut -c1-200
