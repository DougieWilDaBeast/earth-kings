# Dossier 06: Forensic Test Matrix & Benchmark Protocols

**Focus:** Reproducible test harness commands, empirical telemetry hooks, stress scenarios, and critic evaluation scoring rubric.  
**Primary Execution Utilities:** `.\ek.ps1`, `tests/bench.tscn`, `src/game.gd`  
**Reference Docs:** [docs/05-roadmap.md](docs/05-roadmap.md), [docs/10-manual-tests.md](docs/10-manual-tests.md)

---

## 1. Test Harness Architecture (`.\ek.ps1` & `tests/bench.tscn`)

The critic does not rely on ad-hoc playthroughs or unverifiable impressions. Every scenario in this investigation can be booted deterministically into specific world states, party compositions, and geographical locations using the unified dev bench:

```powershell
# Core syntax:
.\ek.ps1 --scene=<key> --at=<site|coord> --level=<n> --gold=<n> --stores=<items> [--shot] [--play]
```

### Parameter Reference

- `--scene`: Target scene key (`title`, `world`, `battle`, `area`, `character_select`, `coliseum`, `museum`, `summary`).
- `--at`: Spawn location on the continental map (`camp`, `village`, `keep`, `library`, `tower`, `gate`, or explicit coordinate `x,y`).
- `--level`: Initial party level override (scales base stats, class choices, and unlocks).
- `--gold`: Starting purse balance in `GameState.gold`.
- `--stores`: Initial bag contents (`item_id:count,item_id:count`).
- `--shot`: Renders a single post-draw frame, exports a high-resolution PNG, and terminates immediately.
- `--play`: Bypasses headless mode and boots into an interactive runtime window.

---

## 2. Systematic Forensic Test Matrix

The following battery of 14 empirical tests covers all five investigation domains:

| ID      | Domain      | Objective                                    | Exact Execution Command                                              | Primary Evaluation Metric                                                           |
| ------- | ----------- | -------------------------------------------- | -------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| **T01** | Boot        | Opening cinematic glide & title handoff      | `.\ek.ps1 --scene=title --play`                                      | Zero frame drops; smooth haze shader; title parade monster loop cleanly strikes     |
| **T02** | Tactics     | Group phase initiative & alpha-strike check  | `.\ek.ps1 --scene=battle --level=5 --play`                           | Measure enemy action opportunities relative to player party turn volume             |
| **T03** | Tactics     | Consumable draught sustain loop              | `.\ek.ps1 --scene=battle --level=8 --stores=draught_amber:10 --play` | Verify whether bonus-action draught drinking trivializes high-tier boss pressure    |
| **T04** | Tactics     | Positional flanking & facing resolution      | `.\ek.ps1 --scene=battle --level=3 --play`                           | Confirm 1.2× side and 1.5× rear multipliers apply accurately in `AbilityResolver`   |
| **T05** | World       | 128×128 continental viewport rendering       | `.\ek.ps1 --scene=world --zoom=0.14 --shot`                          | Validate complete landmass noise carve without visual anomalies or white squares    |
| **T06** | World       | Prowler sight cone & cover verification      | `.\ek.ps1 --scene=world --at=30,45 --play`                           | Confirm rock crags block vision; brush dampens detection radius                     |
| **T07** | World       | Roadside encounter & escort route trigger    | `.\ek.ps1 --scene=world --at=50,50 --play`                           | Step 40 tiles; verify roadside wagon encounter ignites and refusal penalizes renown |
| **T08** | Progression | Class selection bifurcation at Level 2       | `.\ek.ps1 --scene=character_select --play`                           | Advance to Level 2; verify `pending_class_choice` waits exclusively for player      |
| **T09** | Progression | Second skill tree branching at Level 10      | `.\ek.ps1 --scene=world --level=10 --play`                           | Inspect Party Screen (**P**); verify second generated tree prefers unheld theme     |
| **T10** | Progression | Gear suitability & misfit penalty swings     | `.\ek.ps1 --scene=world --stores=sworn_blade_greatsword:1 --play`    | Equip greatsword on non-warrior; verify UI displays negative stat swing             |
| **T11** | Narrative   | Campfire rest ambiance & token interpolation | `.\ek.ps1 --scene=world --at=camp --play`                            | Trigger rest; verify flame lighting and token replacement `{place}`, `{gold}`       |
| **T12** | Narrative   | Memorial site reflection and bond check      | `.\ek.ps1 --scene=area --at=village --play`                          | Interact with memorial marker; verify solitary `Recollection` speech bubble         |
| **T13** | Sensory     | Sworn Blade run cycle vs companion sliding   | `.\ek.ps1 --scene=battle --play`                                     | Compare movement frames of Bram vs Sera/Toln; record aesthetic discrepancy          |
| **T14** | Coliseum    | Multi-team 3-way free-for-all brawl          | `.\ek.ps1 --scene=coliseum --play`                                   | Launch `the_grand_melee`; verify Team B and Team C attack each other evenly         |

---

## 3. Telemetry Extraction & Data Capture Protocols

During test execution, quantitative data will be harvested from engine state:

1. **Combat Telemetry:**
   - Hook into `EventBus.battle_log` to stream actions, damage dealt, damage taken, and facing multipliers.
2. **Ledger Audits:**
   - Read `GameState.ledger` counters upon scene termination:
     ```json
     {
       "kills": 0,
       "damage_dealt": 0,
       "damage_taken": 0,
       "battles_won": 0,
       "battles_lost": 0,
       "gold_earned": 0,
       "steps_walked": 0
     }
     ```
3. **Museum Journey Dossiers:**
   - Inspect `%APPDATA%\Godot\app_userdata\Earth Kings\earth-kings.museum.json` to verify historical accuracy of fallen party members, including fates, hearth vigour, and equipment loadouts.

---

## 4. Final Evaluation Scoring Rubric

The final critical evaluation will rate _Earth Kings_ across six weighted dimensions on a 10-point scale:

```
[Tactical Rigor & Combat Dynamics]      (25% Weight)
[World Chronometry & Overland Pacing]   (20% Weight)
[Progression, Grammar & Mortality]      (20% Weight)
[Narrative Resonance & Atmosphere]      (15% Weight)
[Audiovisual & Aesthetic Execution]     (10% Weight)
[Interface Ergonomics & Usability]      (10% Weight)
```

- **9.0 – 10.0:** Genre-defining benchmark; flawless systemic execution.
- **8.0 – 8.9:** Outstanding achievement with minor, easily addressable rough edges.
- **7.0 – 7.9:** Compelling, deeply ambitious work held back by specific mechanical or sensory flaws.
- **6.0 – 6.9:** Flawed diamond; brilliant conceptual core compromised by systemic friction.
- **< 6.0:** Systemic breakdown; fails to fulfill its core design promise.

---

## 5. Adjudication of the Third Judge: The Benchmark & Enforcement Decree

### The Deliberation

The Critic has constructed an uncompromising 14-scenario empirical battery (`T01`–`T14`), demanding that _Earth Kings_ prove its stability and balance through deterministic execution via `.\ek.ps1` and `tests/bench.tscn`. The Developer may argue that comprehensive automated testing on resource-constrained hardware risks stalling development.

The Third Judge inspects the enforcement apparatus:

1. **On Paused Smoke Suites ([Repo Memory L219](earth-kings.md#L219)):** The repo memory explicitly records that routine full-suite smoke testing was paused on 2026-09-02 due to stale expectations and compute starvation. The Critic's protocols must respect this reality: benchmarks must be targeted, modular, and boot directly into specific test states via `.\ek.ps1 --at= --level=` rather than grinding through the entire legacy test folder.
2. **On Metric Objectivity:** The scoring rubric is affirmed. Weighting Tactical Rigor (25%), World Chronometry (20%), and Progression/Mortality (20%) accurately reflects the game's core value proposition as an uncompromising tactical survival RPG.

### Judicial Rulings & Remedial Decrees

- **Ruling 6.1 (Modular Benchmark Execution):** Execution of the test battery shall be conducted individually using the fast boot harness (`.\ek.ps1 --scene=X --play`). Running monolithic multi-suite smoke tests headlessly is declared non-essential.
- **Ruling 6.2 (The Threshold of Release Certification):** _Earth Kings_ shall not receive final critical certification until it achieves a composite score of **8.0 or higher**, with no individual dimension falling below **7.0**.
- **Ruling 6.3 (Binding Action Plan):** All engineering remediations decreed in Dossiers 01 through 05 (the combat pouch, readiness tax, chokepoint clearance, shared XP split, campfire dialogue enforcement, and procedural sprite bobbing) are hereby adopted as the official stabilization agenda.

> _"A test that cannot run on the developer's desk is a useless monument to theory. Use the bench harness, test each seam one at a time, and measure what the player actually feels when their sword strikes and their companion falls."_  
> — **The Third Judge**
