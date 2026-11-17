---
title: Comparing the port's look with Enemy Within's, view by view
status: in-progress
priority: 12
dependsOn: [ew-harness]
---

# Comparing the port's look with Enemy Within's

## Purpose

The person's (2026-11-17): a better way to compare the visuals of the two games than eyeballing the port against memories
of EW. The same view captured in both games, put side by side, with the differences found by tools and by a second model,
so the fixes are driven by evidence and the person is not needed on every round.

## Plan

1. **Views:** a catalog of named views. Each says how to reach it in the port (the control port) and in EW (the harness:
   a save loaded, clicks). It starts with the base overview, each room, and EW's strategy screens (research,
   engineering, build facilities, the hangar, the Situation Room, Mission Control and its alerts). Tactical spots on EW's
   maps come once the harness has the keyboard. The base rooms align almost for free: the port looks through EW's own room
   cameras.
2. **Pairs:** one script drives both games to a view and writes a side-by-side image (`logs/compare/<view>.png`), both at
   1600 × 900.
3. **Hints:** per-region differences (both images downscaled, cell by cell: brightness, saturation, edge density, SSIM),
   ranked, with crops. Plus a non-visual inventory: EW materials that fell back to grey or were skipped by the converter.
4. **A reviewer:** a Codex helper (gpt-6-astra) gets each pair, its hints and a short description of the view. It returns a
   ranked list of differences that matter (not fonts or the UI's own differences), which the fixes are worked from.
5. **A gallery** of the pairs (local, never published: game art) for the person to look at when they like.

## Decisions

- **EW's state comes from the person's own saves on wingpu,** synced by Steam:
  - Game 55: 94 saves, 26 October to 1 November 2025, stock Long War 1.0, 29 of them in missions.
  - Game 56: 24 saves, stock Long War 1.0.
  - Game 58: 3 saves, Long War Rebalance, which writes "[LWR v2.06.00]" into a save's description.
- **The image tools** are a Python venv on this machine (`~/.cache/lwx2-compare`: numpy, Pillow, scikit-image) and
  ImageMagick. Nothing is installed on wingpu.
- **Screenshots to OpenAI** through the person's Codex account: fine by the person (2026-11-17). Nothing goes into a
  repository.
