# Dossier 04: Narrative Architecture & The "Frieren Layer" Investigation

**Focus:** Ambient storytelling, campfire melancholy, character bonding, memorial visits, and emergent narrative threads.  
**Primary Source Modules:** `src/chronicle/banter.gd`, `src/chronicle/recollection.gd`, `src/chronicle/skein.gd`, `src/chronicle/annals.gd`, `src/dialogue/dialogue_script.gd`, `data/banter.json`, `data/threads.json`  
**Reference Docs:** [docs/01-vision.md](docs/01-vision.md), [docs/08-threads.md](docs/08-threads.md), [docs/09-wishlist.md](docs/09-wishlist.md)

---

## 1. Dramaturgical Design: The Philosophy of the Quiet Road

_Earth Kings_ rejects the bombast of the standard fantasy epic. In its place, it constructs what the design documents term the **"Frieren Layer"**—a narrative texture inspired by the melancholic, post-quest atmosphere of _Sousou no Frieren_. Heroes are not demigods; they are mortal wanderers who share warm broth at a fire, remember fallen friends at roadside graves, collect quaint and mechanically useless spells (trivia grimoires), and slowly build interpersonal bonds across thousands of road steps.

### 1.1 The Campfire & Banter Engine (`Banter` & `Recollection`)

- **Rest Transitions:** Stepping into camp transfers the party from the harsh tactical overland to an intimate sanctuary (`data/areas/camp.json`). Companions sit around an animated fire lit by dynamic lighting (`AreaFire`, `PointLight2D`).
- **Occasion & Mood Weighting:** Exchanges trigger based on context (`road`, `rest`, `after_battle`, `grave`) and interpersonal mood (`warm`, `cold`, `neutral`), driven by `Character.bonds`.
- **Dynamic Token Interpolation:** Dialogue strings are not static; they dynamically ingest the company's real telemetry:
  - `{a}`, `{b}`: Interlocutors.
  - `{deed}`: Most recent continental feat.
  - `{fallen}`: Name of a permanently deceased comrade.
  - `{place}`: Last visited province or settlement.
  - `{battles}`, `{floors}`, `{miles}`, `{gold}`: Concrete historical counters.
- **Recollections (`Recollection`):** When scripted banter exhausts, party members deliver personal reflections on the journey. Each line is spoken exactly once across the lifespan of the universe (tracked via `recalled:<hash>`).

### 1.2 The Skein: Quests Without Quest Logs (`class_name Skein`)

- **The Philosophy of No Quests:** In adherence to [Vision](docs/01-vision.md) and [Decision Q14](docs/06-decisions.md#L45), the player is never handed a conventional quest log with checklist waypoints.
- **The Thread Engine:** The world tracks invisible narrative states (`world.threads`) loaded from `data/threads.json`. Threads ignite upon world conditions (e.g., notoriety exceeding threshold, clearing three gates, reaching the Tower).
- **The Deadline & "Instead" Mechanism ([D23](docs/06-decisions.md#L30)):** A thread never simply vanishes if ignored. Stages carry explicit step deadlines. If the party fails to arrive or intervene before the deadline expires, the thread executes its `instead` block—worsening the situation, destroying a settlement, or unleashing a vengeful hunter.

### 1.3 The Living World: Townsfolk & The Annals

- **Ambient Life:** Town NPCs are not static vending machines. They wander standable paths (`AreaActor.roam`) and mutter contextual chatter into auto-fading speech bubbles (`SpeechBubble`) without demanding player clicks.
- **The Annals (`Annals`):** Telemetry from the entire run is compiled into an in-game historical chronicle viewable in the Journal, transforming gameplay actions into written historiography.

---

## 2. Identified Vulnerabilities & Stress Areas

### 2.1 The Token Exhaustion & Repetition Cliff

- **Risk:** While banter contains 70 authored exchanges and 41 reflections, an extended 30-hour playthrough encompassing thousands of steps across a 128×128 map will inevitably deplete the authored pool. Does the campfire atmosphere collapse into awkward silence or jarring repetition once reflections run dry?

### 2.2 The "Quiet Banter" Delivery Dilemma ([Wishlist W10c](docs/09-wishlist.md#L156))

- **Mechanic:** In response to player feedback that dialogue boxes were "too loud" and obstructed the map, `Pace.quiet_banter` routes banter to speech bubbles and the bottom-corner log.
- **Critic's Concern:** Does demoting campfire dialogue to ambient bubbles cause players to completely overlook poignant character interactions, degrading the emotional heart of the game into background noise?

### 2.3 The Invisible Thread Blindspot

- **Critic's Concern:** Without any quest tracker, do players experience unfair frustration when a town they were planning to visit is suddenly burned down because a thread deadline expired 400 steps ago on the other side of the continent?

---

## 3. Investigation & Benchmark Procedures

### Test Protocol 4.1: Banter Token Parsing & Syntactic Sanity

- **Objective:** Ingest `data/banter.json` and programmatically test every exchange against dummy character states (empty party, 4-person party, single survivor of dead company).
- **Verification:** Ensure zero unreplaced tokens (e.g., raw `{fallen}` strings appearing when no character has died yet).

### Test Protocol 4.2: Thread Expiration & Continental State Transitions

- **Objective:** Simulate a rapid 2,000-step overworld traverse without intervening in ignited threads (`the_vengeful_oath`, `the_deep_breach`).
- **Verification Criteria:**
  - Verify that `instead` triggers execute cleanly and log meaningful news in the world log.
  - Confirm that ruined towns correctly alter their area state to disabled trading.

### Test Protocol 4.3: Campfire Atmosphere Audit

- **Objective:** Manual qualitative evaluation of camp transitions:
  ```powershell
  .\ek.ps1 --scene=world --at=camp --play
  ```
- **Focus:** Lighting warmth, flame particle timing, companion placement, and audio transition from overworld wind to intimate hearth quiet.
