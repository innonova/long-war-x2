#!/usr/bin/env bash
# Commands to the running game on the test machine through the mod's control port (LWX2Control,
# development builds only), from here; prints the answers. Each argument is a command:
#   tools/test/lw.sh help
#   tools/test/lw.sh geoscape 'run 24' geo
set -euo pipefail
host=${LWX2_HOST:-wingpu}
port=${LWX2_PORT:-7531}
cmds=$(printf '%s\n' "$@" | base64 -w0)
ssh "$host" "\$c = New-Object Net.Sockets.TcpClient; try { \$c.Connect('127.0.0.1', $port) } catch { 'ERR the game is not listening on $port'; exit 1 };
\$s = \$c.GetStream(); \$s.ReadTimeout = 120000; \$r = New-Object IO.StreamReader(\$s); \$w = New-Object IO.StreamWriter(\$s); \$w.NewLine = \"\`r\`n\";
foreach (\$cmd in [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$cmds')).Split([char]10)) {
  if (-not \$cmd) { continue }
  '> ' + \$cmd; \$w.WriteLine(\$cmd); \$w.Flush()
  while ((\$l = \$r.ReadLine()) -ne '.') { if (\$l -eq \$null) { 'ERR connection closed'; break }; \$l }
}
\$c.Close()" 2>&1 | tr -d '\r'
