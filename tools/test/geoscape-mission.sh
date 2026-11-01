#!/usr/bin/env bash
# A Geoscape mission round trip on the test machine, by the control port (features/lw-geoscape.md):
# a new campaign to the Geoscape (new-campaign.sh), time run until the aliens' first abductions,
# the squad sent (the decision taken), the mission won (lw.sh win), the reports passed, the
# Geoscape opened again: its account of the mission and the money before and after printed.
# The build already done (sync-build.sh). The game is left running.
#   tools/test/geoscape-mission.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
lw() { tools/test/lw.sh "$@" | grep -v '^> '; }
money() { lw geo | grep -o 'money [0-9]*'; }
# Waits (3 s steps) until the top screen's name matches $1.
until_top() {
  for _ in $(seq 1 "${2:-60}"); do
    sleep 3
    lw ping 2>/dev/null | grep -qE "pong ($1)" && return 0
  done
  echo "timeout waiting for $1"; return 1
}

tools/test/new-campaign.sh | tail -1 | cut -c1-120
for _ in $(seq 1 15); do
  lw decisions | grep -q 'abductions in' && break
  lw 'run 720' | grep '^event' | cut -c1-150
done
d=$(lw decisions | grep 'abductions in' | head -1)
echo "$d"
before=$(money)
lw "act $(echo "$d" | awk '{print $2}')"
# The Skyranger's briefing waits for a key once the mission has loaded (minutes with the EW map).
for _ in $(seq 1 120); do
  sleep 5
  lw ping | grep -qE 'pong (UITacticalHUD|UIMissionIntro|UISpecialMissionHUD)' && break
  lw continue >/dev/null 2>&1 || true
done
sleep 10
lw win
# The reports, until the base.
for _ in $(seq 1 60); do
  sleep 4
  r=$(lw continue 2>/dev/null || true)
  case "$r" in *"nothing to continue"*|*"unknown screen"*) echo "$r"; break ;; esac
done
lw geoscape >/dev/null
lw geo | grep -E 'Geoscape|mission in|^event' | tail -3
echo "$before -> $(money)"
