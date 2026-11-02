#!/usr/bin/env bash
# The newest Enemy Within save on the test machine (or a named one), fetched and read as JSON with xcomsave's
# xcom2json (built from ../xcomsave: cmake -S ../xcomsave -B /tmp/lwx2-xcomsave && make -C /tmp/lwx2-xcomsave).
#   tools/ew-test/save.sh [save name]   → /tmp/lwx2-ewsave/<save>.json (the path printed)
set -euo pipefail
host=${LWX2_HOST:-wingpu}
tool=${XCOM2JSON:-/tmp/lwx2-xcomsave/xcom2json}
name=${1:-$(ssh "$host" '(Get-ChildItem "$env:USERPROFILE\Documents\My Games\XCOM - Enemy Within\XComGame\SaveData" -Filter "save*" | Sort LastWriteTime -Desc | Select -First 1).Name' | tr -d '\r')}
mkdir -p /tmp/lwx2-ewsave
scp -q "$host:Documents/My Games/XCOM - Enemy Within/XComGame/SaveData/$name" "/tmp/lwx2-ewsave/$name"
(cd /tmp/lwx2-ewsave && "$tool" "$name" >/dev/null)
echo "/tmp/lwx2-ewsave/$name.json"
