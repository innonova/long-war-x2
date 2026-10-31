#!/usr/bin/env bash
# Runs PowerShell lines on the test machine in its logged-in desktop session, through
# agent-manager's daemon there (am exec), from the repository's checkout:
#   tools/test/on.sh 'tools\test\click-screen.ps1 783 545' 'Start-Sleep 3' 'tools\test\shot.ps1 C:\Users\aekms\lwx2-1.png'
# Each argument is a line; tools\test\*.ps1 lines are called with &.
set -euo pipefail
host=${LWX2_HOST:-wingpu}
script=$(mktemp)
{
  echo "\$ErrorActionPreference = 'Continue'"
  echo "Set-Location C:\\Users\\aekms\\projects\\long-war-x2"
  for line in "$@"; do
    case "$line" in tools\\*) echo "& .\\$line" ;; *) echo "$line" ;; esac
  done
} > "$script"
scp -q "$script" "$host:lwx2-on.ps1"
rm -f "$script"
am exec "$host" --timeout "${LWX2_TIMEOUT:-300}" -- powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\aekms\lwx2-on.ps1'
