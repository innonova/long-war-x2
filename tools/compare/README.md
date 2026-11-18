# Comparing the port with Enemy Within, view by view

`features/ew-compare.md`. The same named view captured in both games on the test machine, side by side, with
hints of where they differ, for a reviewer and for the fixes. Everything lands in `logs/compare/` (not committed:
the captures are the games' art).

## Capturing

Both games run windowed at 1600 x 900 on wingpu, never at once.

- **Enemy Within:** `tools/ew-test/start-ew.ps1` (through `tools/test/on.sh`), a Long War 1.0 strategy save loaded
  by clicks (LOAD GAME, the save, NEXT, LOAD GAME), the base in view. Then `tools/compare/capture-ew.sh [view …]`
  → `logs/compare/ew/<view>.png`. EW lists every save in its folder; the person's Game 55 (December 2016, a built
  base) is the reference. EW reads its save list once at start, so arranging the folder needs a restart. Hold the
  other saves aside in `SaveData-held` while comparing, and move them back afterwards. Loading a save makes EW write
  its autosave slot (an existing save1754 was overwritten once): keep a copy of that slot too.
- **The port:** a development build (control port), `tools/test/new-campaign.sh`, then
  `tools/compare/capture-x2.sh [view …]` → `logs/compare/x2/<view>.png`.
- `tools/compare/win.ps1` takes the game window's client area (shot) and clicks in its pixels. It does not
  bring the window forward: Enemy Within drew its world black after that.

## Pairs, hints, gallery

`tools/compare/pairs.sh` runs `pair.py` on every view captured on both sides (`~/.cache/lwx2-compare`, a Python
venv with numpy, Pillow and scikit-image) and writes:

- `logs/compare/pairs/<view>.png`: EW on the left, the port on the right, the twelve most different cells outlined
  and numbered on both;
- `logs/compare/pairs/<view>.txt`: those cells ranked. Two games never match pixel for pixel, so each 100 px cell
  is compared by its statistics: brightness, colour, detail (edges) and structure (SSIM). A cell grey in the port
  where EW's is coloured, or lit where EW's is black, ranks high;
- `logs/compare/index.html`: the gallery, with the reviewer's notes where there are any.

## The reviewer

A Codex agent (gpt-6-astra), for an eye that isn't anchored on what was changed. It reads the pairs and hints and
writes `logs/compare/review/<view>.md`. Its brief:

> You compare screenshots of the same view in two games: Enemy Within with Long War (the original, left) and
> Long War X2, its port to XCOM 2 (right). The port reuses EW's own content where it can (the base's rooms, EW's
> Flash screens), so the goal is that the right looks like the left. For each view, list the differences that
> matter, most important first:
> - what is missing or extra (rooms, props, characters, panels, a whole 3D scene);
> - lighting and colour (washed out, too dark, lamps or light strips not glowing, a colour cast);
> - materials (flat grey, wrong texture, see-through, black);
> - camera (framing, angle, distance);
> - the interface: size, position, panels missing or extra, a 2D screen where EW draws it in 3D.
>
> Ignore what only differs because the campaigns differ: dates, money, names, which facilities are built, list
> contents, the number of items. Fonts render slightly differently in the two games; ignore that too.
>
> Each finding: a short title; where (part of the screen, or the hint's cell numbers); what EW shows; what the port
> shows; the kind (missing, lighting, material, camera, interface, other); how much it matters (1 most); how sure
> you are. Write it to `logs/compare/review/<view>.md`. No changes to anything else.
