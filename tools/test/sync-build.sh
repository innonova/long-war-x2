#!/usr/bin/env bash
# This working tree (committed or not) onto the test machine's checkout and built there: the game
# stopped first (a running game keeps the old build's files), the checkout reset to its commit,
# the difference applied as a patch, the mod built. Prints the build's errors and its result (not its warnings:
# twenty of them used to push a compile error out of view).
#   tools/test/sync-build.sh
# Long War's words are written again after the build (tools/test/words.mjs, from that machine's Long War), as the setup
# writes them for a player: the build puts the repository's stand-in words in their place.
# LWX2_EWMAP=1: the whole EW map placed in missions afterwards (PlaceEWMapWhole in the installed config;
# needs the converted map in the checkout's Content and Config, tools/convert/README.md).
set -euo pipefail
cd "$(dirname "$0")/../.."
host=${LWX2_HOST:-wingpu}
commit=$(git rev-parse HEAD)
git push -q origin HEAD 2>/dev/null || true
# Untracked files go in the patch too (intent-to-add, undone after).
new=$(git ls-files --others --exclude-standard)
[ -n "$new" ] && git add -N $new
git diff HEAD --binary > /tmp/lwtree-sync.patch
[ -n "$new" ] && git reset -q $new
scp -q /tmp/lwtree-sync.patch "$host:lwx2-sync.patch"
rm -f /tmp/lwtree-sync.patch
LWX2_TIMEOUT=${LWX2_TIMEOUT:-600} tools/test/on.sh 'tools\test\stop-game.ps1' 'git fetch -q origin 2>&1' "git reset -q --hard $commit 2>&1" 'git clean -qfd -e BuildCache 2>&1' \
  'if ((Get-Item C:\Users\aekms\lwx2-sync.patch).Length -gt 0) { git apply C:\Users\aekms\lwx2-sync.patch 2>&1 }' 'tools\test\build.ps1' \
  'node tools\test\words.mjs 2>&1 | ForEach-Object { if ($_ -match "^words written") { "words: SUCCESS" } else { $_ } }' \
  ${LWX2_EWMAP:+'$f = "C:\Program Files (x86)\Steam\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\Mods\LongWarX2\Config\XComLWAirWar.ini"; (Get-Content $f) -replace "PlaceEWMapWhole=false","PlaceEWMapWhole=true" | Set-Content $f; "EW map: SUCCESS placed whole"'} 2>&1 |
  tr -d '\r' | grep -E 'error|Error|SUCCESS|FAIL|Fail|Crash detected' | grep -v 'Unknown property in defaults' | head -20
