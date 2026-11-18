#!/usr/bin/env bash
# A new campaign on the test machine, by the control port (development builds): the game started,
# the campaign made from the main menu (no tutorial, no intro), its reports passed, up to Long War's
# start screen (XCOM 2's base view is replaced by it: features/strategy-flow.md); --begin: its first
# option taken, on to EW's base. Without the first mission unless --first (then it stops in the
# mission: lw.sh win).
#   tools/test/new-campaign.sh [difficulty 0-3] [--first|--begin]
set -euo pipefail
cd "$(dirname "$0")/../.."
d=${1:-1}
first=''
[ "${2:-}" = --first ] && first=first
tools/test/on.sh 'tools\test\start-game.ps1' 2>&1 | tail -1
tools/test/lw.sh "campaign $d $first" | grep -v '^>'
[ -n "$first" ] && exit 0
begin=''
[ "${2:-}" = --begin ] && begin=1
# Until Long War's start screen (or, with --begin, the base): each report passed as it comes.
for _ in $(seq 1 40); do
  sleep 4
  top=$(tools/test/lw.sh screens 2>/dev/null | grep -v '^>' | head -1 || true)
  if [ "$top" = UILWStartSelect ] && [ -z "$begin" ]; then echo "start screen up"; break; fi
  case "$top" in UILWEWHub|UILWGeoscape|UILWEWMissionControl) echo "base: $top"; break ;; esac
  r=$(tools/test/lw.sh continue 2>/dev/null | grep -v '^>' || true)
  case "$r" in *"nothing to continue"*|*"unknown screen"*) echo "$r"; break ;; esac
done
