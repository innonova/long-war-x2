---
title: "Long War's council requests"
status: review
priority: 31
dependsOn: [lw-council-missions, lw-geoscape]
---

# Long War's council requests

Besides its missions, Long War's council asks for things: corpses, artifacts, weapons, a satellite over a country, an
interceptor on a continent, each for rewards (cash, staff, a soldier, less panic). The port had none of it; Quai
d'Orsay, a starting bonus, hangs on it. Taken on 2026-11-17 while working through STATUS under the person's "in whichever
order works for you".

## How Long War does it (XGFundingCouncil)

- **The clock** (`Update`, `SetupMonthlyRequests`): every 36 + rand(36) hours a new request (Quai d'Orsay: sooner by
  its share).
- **Which** (`DetermineNewFCRequest`, `DetermineFCRequestCountry`, `ChooseNextRequest`, `passesRequestRequirements`): a
  council country still in, at random; a request whose techs are all researched and that is not already open for that
  country (its cooldowns, as the code stands, leave every passing request possible); a satellite request only for a
  country without one, a jet request only with two jets or more, fewer than four on that continent and a satellite off
  the home continent (`CanTransferSatellite`, `CanTransferJet`).
- **What** (`BuildRequest`, 41 kinds): the item and how many (fixed, rand(n) + k, or by the month: corpses (1 + rand 4) x
  month within 6..20, fragments (2 + rand 4) x month within 12..50), its hours (FCREQUEST_DAYS x a factor, or its own,
  less 2 per panic block of the country), and its rewards, one branch of a roll, followed through the hand-patched jumps.
- **Rewards** (`CreateReward`, `GrantFCRewards`): cash is the item's quest price (`XGItemTree.GetItemQuestPrice`, + the
  reward's minimum when it is not 1) x the amount x PROFIT_MARGIN; scientists and engineers a double roll between the
  reward's quantities, a soldier or cash instead when XCOM has more than 120 of them; a soldier of level 3 (4 from the
  year's end in a country of science above 50); "a soldier or scientists" at even odds; panic -20.
- **Pending or waiting** (`OnValidRequestAdded`): XCOM holds enough already, it asks at once (accept or ignore); else it
  waits its hours, to be handed over once XCOM has the items (`AttemptTurnInRequest`), or met by the satellite or jet
  arriving. Met (`OnRequestCompleted`): the country's science +10 (Quai d'Orsay: more by its share).
- **A country leaving** takes its requests (`OnCountryLeft`).

## Report (2026-11-17)

- **The Tree:** `scripts/upk_requests.py` reads `BuildRequest` into `data/requests.json` (numbers only), following each
  branch of its rolls through the bytecode's jumps (e.g. the Cyberdisc corpses' request: a soldier or engineers, and
  cash in both branches). Committed there (5a69025).
- **The config:** `scripts/requests-config.mjs` writes `XComLWRequests.ini` from it and the player's Long War
  `DefaultGameCore.ini` (each item's quest price). 41 requests.
- **The rules:** `LWCouncilRequests` (the clock, the choice, the amount, the rewards, giving, refusing, expiring, the
  satellite and jet transfers met on arrival, a country's science up), state on `XComGameState_LWStrategy`
  (`Requests`, `RequestCountdown`, `CountryScience`, which the hunts' science roll now adds). `LWCouncil.GrantRewards`
  pays a request's rewards as a mission's.
- **Where the player sees it:** the Long War Geoscape lists the open requests above its events; one XCOM can meet is a
  decision, "COUNCIL REQUEST: give Mexico 12 Alien Alloys for 2 scientists", and a pending one also "refuse". A pending
  request stops the clock, as EW's alert does; a waiting one is a notice and time goes on. Test aid: `request`,
  `request now [id]`.
- **Checked on wingpu:** a request for 12 alloys came for §120 and 160 hours (Long War's price 6, +2, x12, x1.25); with
  alloys held, a pending one was given from the decisions (alloys 61 → 49, scientists 10 → 12); a satellite request for
  the United Kingdom was met by launching one there (engineers 10 → 12). Screenshot: `logs/wingpu_council_requests.png`.
- **Choices:** the requests sit on the Long War Geoscape panel (EW shows them on its Situation Room and as Mission
  Control alerts; its own screens for them can come later). Transfer requests are never "pending" here: a satellite or
  jet is met only on arrival (in Long War one held in storage made the request ask at once, then the same).
- **What it looks like in play:** early in a campaign only the transfer requests pass (the others need autopsies and
  research), so satellite requests come every few days for the countries without one; seven were open by day 26. That
  is what Long War's code gives.
- **Not done:** EW's own screens for requests; the jet request was not seen (it needs two jets and a satellite abroad).

## Report (2026-11-17, EW's request screen)

- **`UILWEWCouncilRequest`** on EW's `FundingCouncilRequests` movie, filled as `XGPendingRequestsUI.UpdateRequest` fills
  `UIFundingCouncilRequest`: REQUEST FROM <country>, the item, REQUESTED and IN STORAGE (red while too few), TIME LIMIT (DAYS),
  the country's own words (Long War's `m_strRequestIntro` for the request, its `<XGCountry:…/>` tags in EW's forms of the
  country's name: with the article, the adjective, the possessive), REWARDS in EW's words (cash, scientists, engineers, panic
  reduction, a recruit); DISPATCH ITEMS (greyed while too few are held) gives them (`LWCouncilRequests.Answer`), NOT NOW
  leaves the request (a pending one is then ignored, as the Geoscape's refusal does). Opened from Mission Control's list,
  where each item request XCOM can answer is one entry, REQUEST FROM <country> with its hours (EW opens the screen from its
  Situation Room).
- **Words** (written on the player's machine, `makeRequestWords`): `[XGPendingRequestsUI]`'s labels, the 41 request intros,
  and the 16 council countries' name forms from EW's `[XGLocalizedData]`, by the mod's country order: 118 words.
- **Clicks:** this movie raises its buttons as `button_0` and `button_1` (EW's script names them `mouseBtn1` and 2); both
  are taken.
- **Not shown:** EW's item picture (EW's pictures are not ported); a recruit's class and rank (EW names them; Long War's
  reward picks the class when the soldier comes). A pending request shows TIME LIMIT 0 days: it must be answered now.
- **Checked on wingpu:** Argentina's pending request for 12 alien alloys (the intro in Long War's words, 201 in storage,
  REWARDS: §120; `logs/wingpu_ew_council_request.png`); Nigeria's waiting one (177 hours left in the list) opened from
  Mission Control and DISPATCH ITEMS clicked: "Nigeria's request met (12 Alien Alloys): 2 engineers", back on Mission
  Control.
- **Open:** EW's Situation Room's pending-request list, and the "Incoming Council Communication" alert as a request comes;
  satellite and jet requests on this screen (EW's Transfer Satellite sends the player to the Situation Room).
