#!/usr/bin/env bash
# Commands to the running game on the test machine through the mod's control port (LWX2Control,
# development builds only), from here; prints the answers. Each argument is a command:
#   tools/test/lw.sh help
#   tools/test/lw.sh geoscape 'run 24' geo
#   tools/test/lw.sh 'go phase=tactical.*ready=1 900' units     (wait / go: tools/test/lw.ps1)
# The client is tools/test/lw.ps1 in the test machine's checkout (synced by sync-build.sh).
set -euo pipefail
host=${LWX2_HOST:-wingpu}
port=${LWX2_PORT:-7531}
cmds=$(printf '%s\n' "$@" | base64 -w0)
ssh "$host" "pwsh -NoProfile -File C:\\Users\\aekms\\projects\\long-war-x2\\tools\\test\\lw.ps1 -Commands $cmds -Port $port" 2>&1 | tr -d '\r'
