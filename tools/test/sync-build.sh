#!/usr/bin/env bash
# This working tree (committed or not) onto the test machine's checkout and built there: the game
# stopped first (a running game keeps the old build's files), the checkout reset to its commit,
# the difference applied as a patch, the mod built. Prints the build's errors and its result.
#   tools/test/sync-build.sh
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
LWX2_TIMEOUT=600 tools/test/on.sh 'tools\test\stop-game.ps1' 'git fetch -q origin 2>&1' "git reset -q --hard $commit 2>&1" 'git clean -qfd -e BuildCache 2>&1' \
  'if ((Get-Item C:\Users\aekms\lwx2-sync.patch).Length -gt 0) { git apply C:\Users\aekms\lwx2-sync.patch 2>&1 }' 'tools\test\build.ps1' 2>&1 |
  tr -d '\r' | grep -E 'error|: Error|: Warning|SUCCESS|FAIL' | grep -v 'Unknown property in defaults' | head -20
