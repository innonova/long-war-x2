#!/usr/bin/env bash
# A new campaign taken into its first abduction mission, by the control port: the given control commands
# first (setup: items, techs, facilities), then time run until abductions, the squad sent, the briefing
# passed, until the soldiers can move. The build already done (sync-build.sh). The game is left in the mission.
#   tools/test/to-mission.sh ['give-to 0 LWSmall_73' 'exec GiveTech LWTech_ArcThrower' …]
set -euo pipefail
cd "$(dirname "$0")/../.."
lw() { tools/test/lw.sh "$@" | grep -v '^> '; }
tools/test/new-campaign.sh | tail -1 | cut -c1-60
lw 'arm now' >/dev/null
for c in "$@"; do lw "$c"; done
for _ in $(seq 1 10); do lw decisions | grep -q 'abductions in' && break; lw 'run 720' >/dev/null; done
d=$(lw decisions | grep 'abductions in' | head -1 | awk '{print $2}')
lw "act $d"
for _ in $(seq 1 80); do
  sleep 5
  lw ping | grep -qE 'pong (UITacticalHUD|UISpecialMissionHUD)' && break
  lw continue >/dev/null 2>&1 || true
done
sleep 8
lw ping
