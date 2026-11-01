#!/usr/bin/env bash
# The player's download (features/playable-build.md): the mod as built on the test machine,
# with the player's config (the development switches off) and nothing of either game (no
# converted content, no Long War words), plus the setup program and a short README.
#   tools/release/package.sh            → dist/LongWarX2-<date>-<commit>.zip
# Needs: the test machine's checkout at this commit (it is built there first), npm install here.
set -euo pipefail
cd "$(dirname "$0")/../.."
host=${LWX2_HOST:-wingpu}
game='C:/Program Files (x86)/Steam/steamapps/common/XCOM 2/XCom2-WarOfTheChosen/XComGame/Mods/LongWarX2'
commit=$(git rev-parse --short HEAD)
[ -z "$(git status --porcelain)" ] || { echo "the working tree has changes: commit first, the build is of a commit"; exit 1; }
name="LongWarX2-$(date -u +%Y%m%d)-$commit"
stage="dist/$name"

# The build, of this commit (the game stopped first: a running game keeps the mod's files).
tools/test/on.sh 'tools\test\stop-game.ps1' >/dev/null 2>&1 || true
ssh "$host" "cd C:\\Users\\aekms\\projects\\long-war-x2; git checkout -q -- .; git fetch -q origin main; git checkout -q $commit 2>&1; pwsh -File tools\\test\\build.ps1" | tr -d '\r' | grep -E ': Error|SUCCESS|FAIL' | tail -2
rm -rf "$stage" && mkdir -p "$stage"
scp -rq "$host:$game" "$stage/LongWarX2"
ssh "$host" "cd C:\\Users\\aekms\\projects\\long-war-x2; git checkout -q main" >/dev/null 2>&1 || true

# Nothing of the games, the player's config.
rm -rf "$stage/LongWarX2/Content" "$stage/LongWarX2/Localization/XComGame.int" "$stage/LongWarX2/Config/XComLWX2EWMap.ini"
node scripts/airwar-config.mjs ../xcom-ew-lw-tree/data/airwar.json --player > "$stage/LongWarX2/Config/XComLWAirWar.ini"
if find "$stage" -iname '*.upk' -o -iname '*.tfc' -o -iname '*.png' | grep -q .; then echo "game content in the download:"; find "$stage" -iname '*.upk' -o -iname '*.tfc' -o -iname '*.png'; exit 1; fi

npm run -s setup:bundle >/dev/null
cp dist/LongWarX2-setup.exe "$stage/"
cp tools/release/README.txt "$stage/README.txt"
sed -i "s/@BUILD@/$name/" "$stage/README.txt"
( cd dist && rm -f "$name.zip" && zip -qr "$name.zip" "$name" )
echo "dist/$name.zip: $(du -h "dist/$name.zip" | cut -f1)"
( cd dist && unzip -l "$name.zip" | tail -1 )
