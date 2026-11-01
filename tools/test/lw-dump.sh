#!/usr/bin/env bash
# The whole game state of the running game on the test machine (development builds), as a text file
# here to read and grep: the screens up, then every XCOM 2 game state object with all its fields
# (LWX2Control's "dump"). With a filter, only the classes whose name holds it.
#   tools/test/lw-dump.sh /tmp/lwtree-state.txt [Unit]
set -euo pipefail
cd "$(dirname "$0")/../.."
out=${1:?usage: lw-dump.sh <local file> [class name part]}
tools/test/lw.sh "dump ${2:-}" | grep -v '^> ' > "$out"
echo "$(grep -c '^== ' "$out") objects, $(wc -l < "$out") lines: $out"
