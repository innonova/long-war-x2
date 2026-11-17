---
title: Long War's damaged gear and its repair
status: review
priority: 30
dependsOn: [lw-gear, lw-shivs-mecs]
---

# Long War's damaged gear and its repair

Long War damages the gear of soldiers who come back hurt, and repairs it in the Cybernetics Lab, which it renames the
Repair Bay. EW only damaged MEC suits. Three second-wave options change this system (features/lw-second-wave.md):
#13 Wear and Tear, #22 Durability and #26 Miracle Workers. The port had none of it.

## Long War's rules (its code)

- **After a mission** (`XGFacility_Barracks` calls `XGStrategySoldier`'s repurposed `DEMOUltimateSoldier` for each soldier
  of the squad and for a covert operative): each item a soldier carries that is not infinite can be damaged. That covers
  the pistol, each large and small item, and the armour, though not a SHIV's.
  - **The chance:** (1 − HP / max HP) × the item's damage chance, %. Long War keeps the chance in `BalanceMods_Classic`'s
    `iWill` ("Max%DamagedChance": armours mostly 95, weapons 20–50, MEC suits 95, MEC weapons 75).
  - **Wear and Tear (#13):** a second roll as well, `SW_RARE_PSI` (20)% whatever the soldier's health.
  - **Durability (#22):** never damaged.
  - **A damaged item** is taken off the soldier. The soldier gets the infinite primary, secondary or armour in its place
    (a MEC: the first suit). In storage it counts as damaged, not available (`XGStorage.DamageItem`).
  - **A soldier dead or missing** whose gear is lost (Total Loss's roll, which never succeeds in 1.0) loses it outright.
    Otherwise the gear is damaged at the full chance (HP 0).
- **Repair** (`XGFacility_CyberneticsLab.AddMecForRepair`, from the Cybernetics Lab's MEC inventory, which lists every
  damaged item: `GetDamagedItemsInCategory(0)`):
  - **The cost:** half the item's build cost in cash, meld, elerium and alloys (`m_fMecRepairCostMod` 0.5). Paid when the
    repair begins.
  - **Miracle Workers (#26):** no cost.
  - **The time:** the item's build hours × `CB_EXPERT_BONUS` (80)%, × 0.67 once Foundry project 5 is done, ÷ the work all
    of XCOM's engineers do in an hour (`GetWorkPerHour`). At least 72 hours. The item is back in storage then.

## Plan

1. **The rules:** each item's damage chance (generated from Long War's config) and the damage after a mission, with #13 and
   #22. The campaign keeps the damaged items and the repairs under way (`XComGameState_LWStrategy`). Repair runs on Long
   War's clock, with #26. Test aids for each.
2. **The screens:** EW's own Cybernetics Lab screen (`UICyberneticsLab`) and its MEC inventory (`UIMECInventory`), which
   list the damaged items with their repair cost and time, as Long War's do.

## Decisions

- A damaged item leaves XCOM 2's inventory, and the campaign keeps its template, one entry per item. Repaired, a new item
  of that template goes back into the inventory. Long War's items carry nothing of their own (no upgrades) that this
  would lose.

## Report (2026-11-17, the rules)

- **The numbers** (`XComLWGear.ini`'s `[LongWarX2.LWGearRepair]`, from `scripts/gear-config.mjs`): 113 items' damage chances
  (`BalanceMods_Classic`'s `iWill`), Wear and Tear's 20%, a repair's 80% of the build time, half the cost, at least 72
  hours, and Foundry project 5's 0.67.
- **After a mission** (`LWGearRepair.Apply`, as the strategy layer opens, beside the wounds and fatigue): each soldier back
  from a mission not yet counted (the mark `LWExperience` leaves, as fatigue reads it) has the gear rolled once.
  - **What is rolled:** each worn item that is not infinite (weapons, armour, small items; not what a soldier picked up; not
    a SHIV's armour), at (1 − HP / max HP) × its chance, and with Wear and Tear a second roll at 20%. Durability skips it.
  - **A damaged item** leaves the soldier and the inventory, and its template is kept in the campaign's `DamagedItems`. The
    soldier gets the infinite gear in its place: the class's kit and basic armour, a MEC its first suit and weapon, a SHIV
    its first weapon. Noted in the campaign's events.
- **Repair** (`LWGearRepair.StartRepair`; `Repairs`, counted down each hour of Long War's clock):
  - **The cost:** half the item's build cost in cash, alloys, elerium and meld, paid when it begins; nothing with Miracle
    Workers.
  - **The time:** 80% of its build work, 0.67 of that with Foundry project 5, at the work all of XCOM's engineers do in an
    hour; at least 72 hours.
  - **Then** the item is back in storage.
- **Checked on wingpu** (new test aid `repair`, with `repair <template>` and `repair wear <soldier> <hp>`):
  - **Carapace (95%):** at 1 of 4 HP, damaged, the soldier in basic armour; at full health, not; at 0 HP, damaged.
  - **Durability:** nothing at 0 HP.
  - **Wear and Tear:** 4 of 20 unhurt soldiers' Carapace damaged (20%).
  - **The repair:** refused short of 9 alloys; begun free under Miracle Workers; 480 hours with 10 engineers; the Carapace
    back in storage on the hour.
  - **A mission won and the squad back** (Wear and Tear on, each of the squad carrying Carapace and Combat Stims): 5 items
    damaged, noted, the soldiers re-armed. Opening the Geoscape again added none.
- **Not done yet:** the screens (phase 2: EW's Cybernetics Lab and its inventory). A dead soldier's gear is not rolled
  (Long War rolls it at full chance as it goes back to storage).

## Report (2026-11-17, the Repair Bay's screen)

- **Engineering's REPAIR BAY** (EW's engineering menu option, once the Cybernetics Lab is built; Long War renamed EW's
  "MEC armor" option to it) opens EW's own MEC inventory movie, as Long War rewrote it (`UILWEWRepairBay`):
  - **The list:** "DAMAGED ITEM INVENTORY". Above it REPAIR ALL with what all the repairs cost together; below it each
    damaged item ("DAMAGED: …", greyed when XCOM cannot pay) and each repair under way ("REPAIRING: … Days: n").
  - **A selected item:** the info panel shows its name, Long War's description and "REPAIRS NEEDED", with the repair cost
    below the list.
  - **A damaged item chosen:** EW's question ("REPAIR ITEM: …", the cost, Long War's warning; REPAIR / NOT NOW), then EW's
    word that the repair has begun.
  - **REPAIR ALL:** repairs every damaged item XCOM can pay for, as Long War's rewritten button does.
  - **The words** are Long War's own (its `UIMECInventory` and `XGCyberneticsUI` text), written on the player's machine
    (`scripts/lw-words.mjs` `makeRepairWords`; the hub's "Repair Bay" and its help in `makeHubWords`).
- **Driven as EW drives it:** the movie's `widgetHelper` (`SetListOptions`, `SetListSelection`, `SetSelected`, the
  button's enable), `UpdateInfo`, `SetSoldier`, `SetBuildButtonHelp`. Clicks come as 391/392/398 on `option0` (the button)
  or `option1` (the list, with the row).
- **XCOM 2's font runs wider than EW's:** a row holds about 27 characters at the movie's size. Longer labels ("REPAIRING:
  CARAPACE ARMOR Days:20") are set smaller in proportion.
- **Checked on wingpu:**
  - Engineering's menu with REPAIR BAY (`logs/wingpu_hub_engineering_repairbay.png`).
  - The list with four Carapaces and Combat Stims (`logs/wingpu_repairbay.png`).
  - The question for Combat Stims (`logs/wingpu_repairbay_confirm.png`) and the info panel (`logs/wingpu_repairbay_selected.png`).
  - REPAIR ALL with 31 alloys: three Carapaces and the Stims under repair, the fourth Carapace and the button greyed
    (`logs/wingpu_repairbay_repairall.png`, `logs/wingpu_repairbay_repairing.png`).
- **Left as it is:**
  - The info panel's title for a repair under way is cut before "Days" (the list shows it).
  - The item's icon is the movie's "?" (EW had icons only for MEC gear).
  - Pointing at a row does not select it; a click does.

## Report (2026-11-17, a dead soldier's gear)

- **A soldier who died** (Long War's `DEMOUltimateSoldier` at HP 0: each item rolled at its full chance as it goes back to
  storage). XCOM 2 has already put a recovered body's items into storage, and keeps none from a body left behind.
  `LWGearRepair.DeadGear` (with the Geoscape's damaged-gear pass) finds each dead soldier not yet counted
  (`LWX2GearDead`). It takes the items of the soldier's last version that carried more than the dead does now (XCOM 2 leaves
  what cannot be taken off, the XPad), each item as it was then. Each non-infinite item that is in storage is rolled at its
  full chance (and Wear and Tear's, without Durability). A damaged one is taken out of storage into the damaged items and
  noted ("… came back damaged and waits for repair").
- **Checked on wingpu** (test aid `repair dead <soldier>`: the soldier's items put into storage, as a recovered body's are,
  the soldier dead, the pass run): three dead soldiers in Carapace (95%), each Carapace damaged and out of storage (held 0),
  noted. Found on the way: in strategy a soldier has no team, and the item taken off has no slot; both now handled.
