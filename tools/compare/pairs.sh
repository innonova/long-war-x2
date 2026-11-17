#!/usr/bin/env bash
# Every view captured on both sides put side by side with its difference hints (pair.py), and a gallery page of them:
# logs/compare/pairs/<view>.png and .txt, logs/compare/index.html. Local only: the captures are the games' art.
#   tools/compare/pairs.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
py=${LWX2_PY:-$HOME/.cache/lwx2-compare/bin/python}
mkdir -p logs/compare/pairs
{
  echo '<!doctype html><meta charset="utf-8"><title>EW and the port, view by view</title>'
  echo '<style>body{background:#111;color:#ddd;font:14px sans-serif;margin:20px}img{width:100%;max-width:1800px}pre{white-space:pre-wrap;color:#aaa}h2{color:#7cf}</style>'
  echo "<h1>Enemy Within (left) and the port (right)</h1><p>$(date -u '+%Y-%m-%d %H:%M UTC')</p>"
  for e in logs/compare/ew/*.png; do
    v=$(basename "$e" .png)
    x=logs/compare/x2/$v.png
    [ -f "$x" ] || continue
    "$py" tools/compare/pair.py "$e" "$x" "logs/compare/pairs/$v" >/dev/null
    echo "<h2 id=\"$v\">$v</h2><img src=\"pairs/$v.png\">"
    [ -f "logs/compare/review/$v.md" ] && echo "<pre>$(sed 's/&/\&amp;/g;s/</\&lt;/g' "logs/compare/review/$v.md")</pre>"
    echo "<details><summary>hints</summary><pre>$(cat "logs/compare/pairs/$v.txt")</pre></details>"
  done
} > logs/compare/index.html
ls logs/compare/pairs/*.png | wc -l
