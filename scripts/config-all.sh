#!/usr/bin/env bash
# Every committed config regenerated from one Long War folder (its XComGame/: Config/, CookedPCConsole/, Localization/INT/).
# The port follows stock Long War 1.0 (the default: the installer's files in the Tree's samples), never one player's
# changes (the Tree's samples/Config and samples/CookedPCConsole are the person's modified Long War;
# samples/additional_mods/manual.changes.txt lists what was changed).
#   scripts/config-all.sh [<Long War's XComGame folder>]
set -euo pipefail
cd "$(dirname "$0")/.."
tree=../xcom-ew-lw-tree
lw=${1:-"$tree/samples/Long War Mod Manager 1.0d-620-1-0d/LongWarFiles/_Long War EW 1.0 for PC-88-1-0.exe/{app}/XComGame"}
# upkit reads the game's own packages (Core.upk …) beside Long War's: a folder of the full game's packages
# (the samples'), with this Long War's packages over them.
cooked=$(mktemp -d /tmp/lwx2-cooked-XXXX)
trap 'rm -rf "$cooked"' EXIT
for f in "$tree/samples/CookedPCConsole"/* "$lw/CookedPCConsole"/*; do ln -sfn "$(realpath "$f")" "$cooked/$(basename "$f")"; done
core="$lw/Config/DefaultGameCore.ini"
words="$lw/Localization/INT/XComGame.int"
[ -f "$words" ] || words="$lw/INT2/XComGame.int"
cfg=LongWarX2/Config
node scripts/base-config.mjs "$core" > $cfg/XComLWBase.ini
node scripts/gear-config.mjs "$core" > $cfg/XComLWGear.ini
node scripts/strategy-config.mjs "$core" "$cooked/XComStrategyGame.upk" > $cfg/XComLWStrategy.ini
node scripts/research-config.mjs "$core" "$tree/data/techtree.json" > $cfg/XComLWResearch.ini
node scripts/aliens-config.mjs "$core" > $cfg/XComLWAliens.ini
node scripts/maps-config.mjs "$lw/Config/DefaultMaps.ini" > $cfg/XComLWEWMaps.ini
node scripts/airwar-config.mjs "$tree/data/airwar.json" > $cfg/XComLWAirWar.ini
# Writes XComLWClasses.ini, XComClassData.ini, XComGameData.ini, XComGameCore.ini, XComGameData_XpData.ini and the words (gitignored) itself.
node scripts/classes-config.mjs "$core" "$words" "$cooked/XComGame.upk" > /dev/null
git status --short -- $cfg
