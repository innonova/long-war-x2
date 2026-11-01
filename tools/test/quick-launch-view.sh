#!/usr/bin/env bash
# The EW map on the Tactical Quick Launch screen, from here (experiment 2): builds the mod on
# the test machine, starts the game, opens the screen (main menu's TEST TACTICAL), generates
# a map (the screen draws the world only then; it turns the debug camera on, which the mod
# holds at the configured view) and takes a screenshot to the given local path. The game is left
# running; the log lines of ours are printed.
#   tools/test/quick-launch-view.sh /tmp/lwtree-x2-1.png [--no-build]
set -euo pipefail
cd "$(dirname "$0")/../.."
out=${1:?usage: quick-launch-view.sh <local png> [--no-build]}
host=${LWX2_HOST:-wingpu}
log='C:\Users\aekms\Documents\My Games\XCOM2 War of the Chosen\XComGame\Logs\Launch.log'
tools/test/on.sh 'tools\test\stop-game.ps1' >/dev/null 2>&1 || true
if [ "${2:-}" != --no-build ]; then
  ssh "$host" 'cd C:\Users\aekms\projects\long-war-x2; pwsh -File tools\test\build.ps1' 2>&1 | tr -d '\r' | grep -E ': Error|SUCCESS|FAIL' | tail -3
fi
tools/test/on.sh 'tools\test\start-game.ps1' 'tools\test\click.ps1 200 152' 2>&1 | tail -1
for _ in $(seq 1 25); do
  sleep 4
  r=$(ssh "$host" "Get-Content '$log' | Select-String 'camera hold spawned|appError' | % Line; if (-not (Get-Process XCom2 -ErrorAction SilentlyContinue)) { 'GAME GONE' }" 2>&1 | tr -d '\r')
  [ -n "$r" ] && break
done
echo "$r" | grep -q 'appError\|GAME GONE' && { echo "$r"; exit 1; }
# Generate Map (screen pixels of the 1600x900 window); generating turns the debug camera on.
tools/test/on.sh 'tools\test\click-screen.ps1 240 84' 'Start-Sleep 50' 'tools\test\shot.ps1 C:\Users\aekms\lwx2-view.png' >/dev/null 2>&1
scp -q "$host:lwx2-view.png" "$out"
ssh "$host" "Get-Content '$log' | Select-String 'LongWarX2: LongWarX2|appError' | % Line | Select-Object -Last 16" 2>&1 | tr -d '\r' | cut -c1-240
