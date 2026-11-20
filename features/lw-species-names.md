---
title: Long War's species by their own names on the field
status: review
priority: 6
dependsOn: [lw-aliens, lw-exalt]
---

## The problem

Long War's species fight as XCOM 2 templates (`XComLWStrategy.ini`, `FightAs`): the Floater as an Archon, the
Thin Man as a Viper, the Sectoid Commander as a Sectoid, EXALT's eight as ADVENT's troopers, captains, shield
bearers and stun lancers. On the field every message, target and tooltip names them by that template ("ADVENT
Trooper was killed!" for an EXALT Operative). XCOM 2 names an alien by its template only:
`XComGameState_Unit.GetName` returns `GetMyTemplate().strCharacterName` for anyone not a soldier or a civilian, so a
unit cannot be given its own name the way the SHIVs are (`SetCharacterName` is read for soldiers only).

## The way

A character template per Long War species, made when the templates are created as a copy of the XCOM 2 template it
fights as (every property, its abilities, AI, loot, pawn), named after the species and given EW's name for it (EW's
`XLocalizedData.m_aCharacterName[eChar_*]`, read from the player's EW install by the words writer, never committed).
`FightAs` then names the species' own template. Everything keyed on the XCOM 2 template's name has to follow:
the EW bodies (`XComLWX2EWUnits.ini` `Template=`, which already tells species apart), the encounter lists and pod
spawning (`LWMissionSquads`), the autopsies and corpses, the Shen's Last Gift and other per-template checks, the
control port's aids.

Templates two species share today (the Sectoid and the Sectoid Commander; the Muton and the Muton Elite …) become two,
so their stats and leaders can also be told apart by template rather than by the `LWX2Species` unit value.

Found while giving EXALT its own bodies (lw-exalt, report of 2026-11-20).

## Report (2026-11-20, first cut)

- **The copies** (`X2Character_LWSpecies`): for each `FightAs` entry, XCOM 2's own creation function for the template
  it fights as (`X2Character_DefaultCharacters.CreateTemplate_*`, so its config stats, abilities, pawn, loot and AI are
  that template's), renamed `LWX2Char_<species>` and given EW's name. Made as XCOM 2 makes its own, per difficulty.
- **The names** (`LWX2Species.Names`): EW's `m_aCharacterName[eChar_…]` by `ECharacter` number, written into the mod's
  `LongWarX2.int` by the setup (`makeSpeciesWords`); Long War's text stays on the player's machine.
- **Following the copies:** the missions spawn each species as its copy (`LWMissionSquads.TemplateFor`); the aliens'
  passives go on the copies too (`LWAlienStats.AddAbilities`); the EW bodies find their template through the copy
  (`LWX2EWBodies.PickFor`, `AddAnimSets`: a species' body on its copy only, which also keeps EXALT's animations off
  XCOM 2's own ADVENT).
- `Codex` in `FightAs` is not one of XCOM 2's template names (the Codex is `Cyberus`); the Outsider's copy is made
  from `Cyberus`.

**Fixed on the way:** XCOM 2's creation functions make each template under the template's own object name, so calling
one again remade XCOM 2's own object; renamed, it renamed XCOM 2's template (its own ADVENT troopers came out as EXALT),
and two species of one template (the Sectoid and its Commander) were one object. Each copy is now a new object of its
own name made from the remade one. The names: a localized array read with gaps (indices from 4) came out empty; every
index is written now (`Names[0]=""` …), and the copies are named in `OnPostTemplatesCreated` (and again at the battle's
start).

**Checked on wingpu** (a campaign's first mission; the control port's `enemies` now shows each unit's name as the game
shows it): the pods spawn as `LWX2Char_4` "Sectoid"; spawned copies "EXALT Operative" (in its EW body), "EXALT Elite
Medic", a Drone "Drone", the Sectoid Commander in its EW body; XCOM 2's own `AdvTrooperM1` stays "ADVENT Trooper" in
ADVENT's body. 130 templates named (every difficulty's copy).

### Left open

- Loot and corpses are still the XCOM 2 template's ("ADVENT Trooper Corpse dropped" for an EXALT soldier), as before.
- Not checked: a captured alien's and the Chryssalid hive's and Progeny's spawns through the copies (they use
  `LWMissionSquads.TemplateFor` too).

