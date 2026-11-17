---
title: Long War's second-wave options
status: in-progress
priority: 40
dependsOn: [lw-startbonus]
---

# Long War's second-wave options

Long War's campaign options (EW's "second wave", the shell's gameplay toggles: `m_arrGameplayToggleTitle`, `eGO_…`)
are not in the port: a campaign plays as with all of them off. Long War 1.0 has 31, numbered as its text numbers them:

0 Damage Roulette, 1 New Economy, 2 Strict Screening, 3 Hidden Potential, 4 Training Roulette, 5 Save Scum, 6 Red Fog,
7 Absolutely Critical, 8 Liberators, 9 Dynamic War, 10 Results Driven, 11 Cinematic Mode, 12 Diminishing Returns,
13 Wear and Tear, 14 Itchy Trigger Tentacle, 15 War Weariness, 16 Bronzeman Mode, 17 Total Loss, 18 Commander's Choice,
19 Aiming Angles, 20 Mind Hates Matter, 21 Hidden Trees, 22 Durability, 23 United Humanity, 24 The Friendly Skies,
25 We Are Legion, 26 Miracle Workers, 27 Quick and Dirty, 28 Perfect Information, 29 Recon, 30 Green Fog.

(Long War's enum names do not all match the titles: Long War reused EW's slots, e.g. `eGO_Marathon` is Dynamic War,
`eGO_UltraRarePsionics` Wear and Tear.)

## Plan

1. **The choice:** the options chosen as a campaign starts (EW asks for them in its shell, before the start screen), kept
   in the campaign's Long War state, each with Long War's own title and text from the player's install.
2. **Each option's rule,** read from Long War's code where it checks the option (`IsOptionEnabled`, `m_arrSecondWave…`),
   one at a time, starting with those another part of the port already waits on: The Friendly Skies (the Firestorm's
   refits, `lw-air-war`), then the tactical ones that are one rule each (Absolutely Critical, Damage Roulette, Red Fog,
   Aiming Angles), then the strategy ones (New Economy, Results Driven, Diminishing Returns, War Weariness, …), Dynamic War
   last (it rescales the whole campaign).
3. Each option checked on wingpu with it on and off.

## Decisions

- **Where the choice is made: XCOM 2's own new-campaign screen** (its second-wave list, `UIShellDifficulty`). EW's own
  second-wave screen is in its shell movies, which the port does not convert; XCOM 2's list takes options from config, and
  a campaign's choice is kept in its settings (`XComGameState_CampaignSettings`). XCOM 2's own eight options are taken out
  of the list: a Long War campaign has Long War's.

## Report (2026-11-17, the choice; The Friendly Skies)

- **The choice:** `XComUI.ini` removes XCOM 2's eight second-wave options from its new-campaign screen and lists Long War's
  31 in Long War's order (`LWSW_<nn>_<name>`); their lines and tooltips are Long War's own titles and texts ("Damage
  Roulette (#0): Weapons have a much wider range of damage…"), written from the player's install into the mod's
  `XComGame.int` (`makeSecondWaveWords`: 31). `LWX2SecondWave.On(n)` answers with Long War's number, as Long War's
  `IsOptionEnabled`.
- **Test aid:** `secondwave` lists the options on; `secondwave <n> on|off` sets one in a running campaign.
- **#24 The Friendly Skies:** XCOM's aircraft weapons aim 15 better (Long War's `ABDUCTION_REWARD_SCI`, "Friendly Skies bonus
  for XCOM aircraft", added to each weapon's to-hit in `XGItemTree.BuildShipWeapons`, the Foundry's versions too):
  `LWAirWar.WeaponFor`, weapons 1 to 7.
- **Checked on wingpu:** the same Raven-1 against the same small UFO at Balanced: 39% of 1,000 simulated fights downed it with
  the option off, 60% with it on (`logs/wingpu_friendly_skies_off.png`, `…_on.png`). **Not seen:** the options on XCOM 2's
  new-campaign screen (the test campaigns are made by the control port, without it).
- **Corrected:** STATUS's "the Firestorm's refits" waited on this option by a misreading; Firestorms are refitted as
  interceptors are.
