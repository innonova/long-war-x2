#!/usr/bin/env bash
# A screenshot of the test machine's screen (the game's window in it), copied here.
#   tools/test/shot.sh /tmp/lwtree-shot.png
set -euo pipefail
cd "$(dirname "$0")/../.."
host=${LWX2_HOST:-wingpu}
tools/test/on.sh 'tools\test\shot.ps1 C:\Users\aekms\lwx2-shot.png' >/dev/null 2>&1
scp -q "$host:lwx2-shot.png" "${1:?usage: shot.sh <local png>}"
