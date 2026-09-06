# Dossier 02: World Topology & Step Chronometry Investigation

**Focus:** Continental geography, step-clock pacing, prowler hunting mechanics, macro-economic trade routes, and regional dynamics.  
**Primary Source Modules:** `src/world/world_scene.gd`, `src/chronicle/world.gd`, `src/chronicle/world_gen.gd`, `src/chronicle/prowler.gd`, `src/chronicle/roadside.gd`, `src/chronicle/town.gd`  
**Reference Docs:** [docs/01-vision.md](docs/01-vision.md), [docs/02-design.md](docs/02-design.md), [docs/09-wishlist.md](docs/09-wishlist.md)

---

## 1. Spatial & Chronological Architecture

The transition of _Earth Kings_ from an austere 44×44 paddock to a 128×128 noise-carved continent marks its most ambitious systemic expansion. The world is governed not by an abstract real-time tick, but strictly by the player’s footsteps.

### 1.1 The Step-Clock Engine (`World._upkeep`)

- **Step Cadence:** Every step taken by the party advances the continental clock by `1`.
- **The Upkeep Interval (30 Steps):**
  - Prowler bands (`Prowler`) shift positions across regional paths.
  - Active trade routes (`world.routes`) pay dividends into `GameState.gold`.
  - Doctrine entropy decrements unpracticed lore across character shelves.
  - Open gates tick toward instability (`break_after_steps`).
  - Active story threads (`Skein`) evaluate deadline conditions.
- **Tower Temporal Dilation:** Scaling a single floor in the Tower advances world time by 30 steps ([D27](docs/06-decisions.md#L278)), ensuring that dungeon crawling does not freeze external continental pressure.

### 1.2 Deterministic Continental Topography

- **Dimensions:** 128×128 grid (16,384 discrete cells).
- **Landmass Synthesis:** Radial noise falloff generates an organic coastline surrounded by untraversable open ocean.
- **Biomes & Provinces:** Latitude warping dictates climatic bands (northern snowfields like The Frostpeak Waste transitioning southward to arid tracts like The Sunscorched Expanse), with intermediate wetlands (The Drowned Fens) and mountain elevations (The Dragonspine Ridge).
- **Dynamic Culling:** `world_scene._cells_in_view()` dynamically restricts tile draw calls to the active viewport, recalculating only when the `CameraRig` shifts.

### 1.3 Threat Density & Prowler Detection (Anti-Ambush Design)

- **Zero Random Encounters:** Ambush mechanics are replaced by visible prowler bands roaming with distinct crimson sight cones.
- **Topographical Cover:** Prowler vision is obstructed by rock crags, reduced by dense brush, and elevated on ridges.
- **Encounter Ignition:** Crossing into a watched red tile immediately triggers `Encounter.for_band`, transitioning seamlessly to a generated battlefield reflecting the local terrain.

```
       [Player Moves 1 Tile] ──▶ [Continental Clock +1]
                 │
                 ├── (Every 30 Steps: Upkeep Tick)
                 │         ├── Prowlers Roam / Restock
                 │         ├── Trade Routes Pay Gold
                 │         ├── Doctrine Decays (-1 Step)
                 │         └── Story Threads & Sieges Advance
                 │
                 └── [Steps into Prowler Red Cone] ──▶ [Grid Battle Triggered]
```

---

## 2. Identified Vulnerabilities & Stress Areas

### 2.1 Traversal Attrition vs. Player Boredom

- **The 128×128 Scale Dilemma:** At 1 step per keypress (or held input), navigating from the northern tundra to the southern sands requires hundreds of discrete steps. While auto-pace (`Q`) and speed cycling (`T`) mitigate physical strain, does long-distance transit degenerate into an unengaging waiting game punctuated by frequent prowler interruptions?
- **Prowler Funneling:** In narrow mountain passes or marshland isthmuses, do prowler bands cluster so tightly that avoidance is mathematically impossible, forcing unwanted battles that break exploration rhythm?

### 2.2 Macro-Economic Inflation via Trade Routes

- **Mechanic:** Rescuing roadside merchants unlocks up to five concurrent trade routes paying gold every 30 steps for a duration of 900 steps.
- **Risk:** A player running five active trade routes receives compounding payouts every 30 tiles. Over a 500-step trek across the continent, this yields thousands of gold pieces, potentially dismantling the scarcity of equipment, town hirelings, and captive ransoms.

### 2.3 Town Siege Catastrophe Cascades

- **Mechanic:** Neglected open gates break after repeated failed stability rolls, causing roving raiding parties to besiege the nearest settlement. If unaddressed, settlements fall into ruin and cease trading.
- **Risk:** If a player is exploring distant wilderness, can multiple settlements fall into ruins without adequate advance warning, leaving the map barren of merchants and safe hearths?

---

## 3. Investigation & Benchmark Procedures

### Test Protocol 2.1: Continental Transit & Frame-Time Profiling

- **Objective:** Measure rendering performance and input latency during sustained high-speed overworld traversal.
- **Invocation:**
  ```powershell
  .\ek.ps1 --scene=world --zoom=0.14 --play
  ```
- **Verification Criteria:**
  - Verify zero frame drops or stuttering during viewport redraws at maximum zoom.
  - Confirm zero texture loading anomalies (white squares) during rapid travel across biome transitions.

### Test Protocol 2.2: Economic Yield over Continental Traverse

- **Objective:** Track gold accumulation rate across a standardized 1,000-step continental circuit with 3 active trade routes.
- **Data Hook:** Record delta in `GameState.gold` and audit against shop inventory pricing in keeps and villages.
- **Acceptance Boundary:** Gold income must not outpace high-tier equipment costs (`Tier 3 Gear >= 1200 gold`).

### Test Protocol 2.3: Prowler Pathing & Chokepoint Density

- **Objective:** Audit prowler distribution across seeded worlds (`12345`, `88888`, `99999`) to ensure mountain passes maintain at least a 1-tile stealth bypass corridor.
