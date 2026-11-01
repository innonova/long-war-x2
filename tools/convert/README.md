# Converting Enemy Within's content for XCOM 2

Everything here runs on the player's machine, from their own Enemy Within
install; nothing it writes is committed (`features/hard-parts.md`,
experiments 1 and 2). The scripts use upkit and the Long War Tech Tree's
readers, so they run from a checkout of `innonova/xcom-ew-lw-tree` beside
this one:

    cd ../xcom-ew-lw-tree
    npx vite-node ../long-war-x2/tools/convert/<script>.ts -- <arguments>

## An EW package as it is (aliens, effects): `ew-package.ts`

    ew-package.ts -- <EW>/CookedPCConsole/GameUnit_XComFloater_SF.upk <out>.upk

Decompressed, the header fixed, the texture cache names renamed to names of
the same length (`CharTextures` → `EWCharTextrs`, `Textures` → `EWTextrs`,
`Lighting` → `EWLightg`, `Textures_startup` → `EWTextrs_startup`). XCOM 2
loads its skeletal meshes, AnimSets and particle systems as they are. The
package goes into the mod's `Content`, and the player's EW caches are linked
into the built mod's `Content` under the new names (`tools/test/build.ps1`
does it after each build: hard links, no copies). Its materials do not
render in XCOM 2: the unit display uses a material made in the editor.

## An EW map: `ew-map.ts`

    ew-map.ts -- <EW>/CookedPCConsole/CSmallScout_Badlands.upk <out>.upk <out>.ini

- the package: every object of its world made an empty object XCOM 2 can
  read, the packages it carries copies of renamed (first letter `Q`), every
  texture rewritten with its mips uncompressed in the package
  (`inline-textures.ts`), so it needs no texture cache; it goes into the
  mod's `Content`;
- the `.ini` (`XComLWX2EWMap.ini`, into the mod's `Config`): every placed
  static mesh with its place, its materials and whether it is backdrop; each
  material's diffuse and normal maps; EW's play area and drop zones. The mod
  (`LWX2EWMapPieces`, `LWX2PartPlacer`) places them in a mission.

## For the editor: `ew-to-gltf.ts`, `gltf-to-fbx.py`

An EW unit as glTF (mesh, skeleton, textures, animations), then FBX through
Blender, for XCOM 2's editor. The editor's animation import crashes on every
FBX tried, so this route is kept only for materials and meshes; EW's own
packages (above) are the route for units.
