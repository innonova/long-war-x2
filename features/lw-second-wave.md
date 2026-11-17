---
title: Long War's second-wave options
status: planned
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

## Open

- Where the choice is made: EW's own second-wave screen is in its shell movies, which the port does not convert yet; the
  start screen (EW's ContinentSelect movie) or XCOM 2's own new-campaign options are the alternatives.
