#!/usr/bin/env bash
# The port's campaign brought to an EW save's state, as far as the base's menus depend on it (features/nav-map.md: EW's
# navigation and the port's compared at the same state): the save's facilities on the same tiles (XGBase.m_arrFacilities,
# rows below the top one; Long War's facility numbers are EW's) and its research done (XGFacility_Labs.m_arrResearched,
# Long War's tech numbers). Through the control port's test aids (base set, techdone); the game up in a campaign at EW's
# base (tools/test/new-campaign.sh 1 --begin).
#   tools/test/mirror-ew-save.sh <save name on wingpu, e.g. save1753>
set -euo pipefail
cd "$(dirname "$0")/../.."
json=$(tools/ew-test/save.sh "${1:?usage: mirror-ew-save.sh <save>}")
python3 - "$json" <<'EOF' > /tmp/lwx2-mirror.txt
import json, sys
d = json.load(open(sys.argv[1]))
facilities, researched = [], []
for chunk in d['checkpoints']:
    for c in chunk['checkpoint_table']:
        for p in c['properties']:
            if c['class_name'] == 'XComStrategyGame.XGBase' and p['name'] == 'm_arrFacilities':
                facilities = [{q['name']: q.get('value') for q in s} for s in p['structs']]
            if c['class_name'] == 'XComStrategyGame.XGFacility_Labs' and p['name'] == 'm_arrResearched':
                researched = p['elements']
for f in facilities:
    # (The top row is the fixed rooms.)
    if f.get('iFacility', 0) > 0 and f.get('Y', 0) > 0:
        print(f"base set {f.get('X', 0) + 1} {f.get('Y', 0) + 1} {f['iFacility']}")
for t, done in enumerate(researched):
    if done and t > 0:
        print(f"techdone {t}")
EOF
n=0
while read -r cmd; do
  r=$(tools/test/lw.sh "$cmd" < /dev/null 2>&1 | grep -v "^> " | tail -1)
  case "$r" in ERR*) echo "$cmd: $r";; esac
  n=$((n + 1))
done < /tmp/lwx2-mirror.txt
echo "mirrored: $n commands"
tools/test/lw.sh base | grep -v '^> ' | head -6
