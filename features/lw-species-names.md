---
title: Long War's species by their own names on the field
status: planned
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
