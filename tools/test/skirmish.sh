#!/usr/bin/env bash
# A War of the Chosen Skirmish Mode mission with Long War's classes, from here (features/lw-classes.md):
# starts the game (the build already done), opens Legacy Hub > Skirmish, makes the squad's four
# soldiers the given Long War classes (ranks and perks as Skirmish Mode rolls them), starts the
# mission and waits until the perk probe has logged the shot breakdowns; prints them.
#   tools/test/skirmish.sh [Sniper Gunner Assault Medic]
# Classes: Sniper Scout Rocketeer Gunner Medic Engineer Assault Infantry. The clicks are the
# screens' places in the 1600x900 window.
set -euo pipefail
cd "$(dirname "$0")/../.."
host=${LWX2_HOST:-wingpu}
log='C:\Users\aekms\Documents\My Games\XCOM2 War of the Chosen\XComGame\Logs\Launch.log'
classes=("${@:-Sniper Gunner Assault Medic}")
[ $# -eq 0 ] && classes=(Sniper Gunner Assault Medic)
declare -A row=([Sniper]=448 [Scout]=480 [Rocketeer]=512 [Gunner]=543 [Medic]=575 [Engineer]=607 [Assault]=639 [Infantry]=671)
units=(194 226 257 289)

steps=('tools\test\click-screen.ps1 699 900' 'Start-Sleep 5' 'tools\test\click-screen.ps1 810 500' 'Start-Sleep 2' 'tools\test\click-screen.ps1 810 780' 'Start-Sleep 6' 'tools\test\click-screen.ps1 550 162' 'Start-Sleep 2')
for i in "${!classes[@]}"; do
  [ "$i" -ge 4 ] && break
  y=${row[${classes[$i]}]:?unknown class ${classes[$i]}}
  # Edit Unit i, Choose New Class, the class, back to the squad.
  steps+=("tools\\test\\click-screen.ps1 550 ${units[$i]}" 'Start-Sleep 2' 'tools\test\click-screen.ps1 550 194' 'Start-Sleep 2' "tools\\test\\click-screen.ps1 550 $y" 'Start-Sleep 2' 'tools\test\click-screen.ps1 47 895' 'Start-Sleep 2')
done
steps+=('tools\test\click-screen.ps1 545 865')

tools/test/on.sh 'tools\test\stop-game.ps1' >/dev/null 2>&1 || true
tools/test/on.sh 'tools\test\start-game.ps1' "${steps[@]}" 2>&1 | tail -1
for _ in $(seq 1 60); do
  sleep 5
  r=$(ssh "$host" "Get-Content '$log' | Select-String 'perk probe|appError' | % Line; if (-not (Get-Process XCom2 -ErrorAction SilentlyContinue)) { 'GAME GONE' }" 2>&1 | tr -d '\r')
  [ -n "$r" ] && break
done
echo "$r" | grep -q 'appError\|GAME GONE' && { echo "$r"; exit 1; }
sleep 3
ssh "$host" "\$l = Get-Content '$log'; \$i = (\$l | Select-String 'perk probe' | Select -Last 1).LineNumber; \$l[\$i..(\$i+16)]" 2>&1 | tr -d '\r' | grep -v '^\[' | cut -c1-400
