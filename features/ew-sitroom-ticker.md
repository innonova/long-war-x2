---
title: The Situation Room's news ticker and objectives (EW's, by Long War's rules)
status: in-progress
priority: 3
dependsOn: [strategy-flow]
---

EW's Situation Room shows WORLD NEWS along the map's foot (five headlines, scrolling) and an OBJECTIVES panel under the
map; the port shows neither. The reviewer's rounds 4 and 5 list both.

**Long War's rules** (`XGFacility_SituationRoom`, `UISituationRoom`, read from the stock package):
- Five headlines, newest first (`m_arrTickerItems[5]`); a country's new headline replaces its old one.
- Pushed by: a country's panic changing (`XGCountry.AddPanic` → `PushPanicHeadline(panic / 20)`: lines for levels 1, 2
  (also 3), 4, 5 per council country); a mission's result (`XGFundingCouncil` → `PushMissionSpecificHeadline`: abduction,
  terror, crash site, landed UFO, covert operations, won or lost; a won abduction with gene-modded soldiers or MECs its own
  lines; the HQ assault and the raid on EXALT's base are narratives); a country leaving (`PushCountryWithdrawHeadline`);
  EXALT's operations (sabotage, propaganda, research hack); the council's requests and missions
  (`PushFundingCouncilHeadline`, with the council's own text); narratives once a campaign (UFO shot down, alien captured,
  code broken, base assaulted, psi soldier, EXALT raid); and after 120 hours without news an ambient headline of the act
  (of the first act two times in five).
- Each family's lines dealt without repeats until all are used, then again, those still shown kept out.
- The ticker's text: the headlines in their colours (plain, good, bad), "//" between (`UpdateTicker`); the movie's
  `SetTickerText(title, text)`.
- Objectives: EW's `m_strObj…` lines by the campaign's progress (`ShowObjectives`), in `theObjectivesPanel`.

## Report (2026-11-19, the ticker's rules)

- **Words** (`lw-words.mjs`, `makeTickerWords`): EW's 494 headline lines from the player's install, each with its family
  (`Panic:<country>:<level>`, `Ambient:<act>`, `AbductionWon` …, `Narrative:<name>`), and the title, into `[LWTicker]`.
- **Rules** (`LWTicker`; the state's `Ticker`, `TickerUsed`, `TickerNarratives`, `TickerQuiet`): all of the above but
  the council's headlines; hooked into `AddPanic`, `MissionBack`, the month's withdrawals, EXALT's operations, a UFO
  downed and the hour. Seen: five headlines at a campaign's start, in the log.
- **Not drawn yet:** the wall's movie takes `SetTickerText` and `ShowTicker`, but nothing shows. The ticker clip
  (`theTicker`, at x 1102 of the movie's stage, 4744 wide) builds its scrolling sliders by `Bind` and moves them with
  Tweener; its title field stayed empty. Next: whether the sliders are made (the renamed classes, `ew-ui.ts`) and where
  EW's wall meshes show that part of the movie (`UI_situationroom_center`'s UVs).
- **Not yet:** the council's headlines; the objectives panel.
- **Probed further:** the five sliders are made and carry the headlines (`txtField`), and Tweener moves them; the
  ticker clip is now above the map area (which had covered it), but nothing shows, even moved into the map's middle on the
  wall. Next: whether its text renders in the 3D movie at all (fonts, colour), by a test clip of ours beside it.

## Report (2026-11-19 morning, the ticker drawn)

- **Why nothing showed:** EW's ticker builds its scrolling lines from a library clip whose text fields stay 4 pixels
  high in XCOM 2 (its font does not draw), and its mask stood far off the lines' path. The headlines now scroll in XCOM 2's
  own scrolling text (`UIScrollingText`) along the map's foot, where EW's run, WORLD NEWS first, each in its colour, "//"
  between; EW's own ticker is hidden. Seen on wingpu in the Situation Room ("WORLD NEWS: Economist says future markets
  unpredictable if major tech…", scrolling); hidden where the wall is bare.
- **Still:** the council's headlines; the objectives panel.
