# Dossier 01: Tactical Grid & Combat Systems Investigation

**Focus:** Battlefield simulation, action economy, initiative architecture, AI behavior, and combat resolution.  
**Primary Source Modules:** `src/battle/battle.gd`, `src/battle/turn_manager.gd`, `src/battle/unit.gd`, `src/battle/abilities/ability_resolver.gd`, `src/battle/ai/enemy_brain.gd`  
**Reference Docs:** [docs/02-design.md](docs/02-design.md), [docs/06-decisions.md](docs/06-decisions.md)

---

## 1. Ludological Audit of Current Combat Mechanics

The tactical grid of _Earth Kings_ represents a fascinating hybrid of _Final Fantasy Tactics_ charge-time (CT) initiative and modern squad-based action economies. Rather than strictly interleaving individual character turns, _Earth Kings_ implements an asymmetric turn cadence:

### 1.1 The Unified Player Phase (`TurnManager.advance_group`)

- **Mechanic:** Time advances continuously until any unit reaches 100 CT. When an enemy unit triggers, it acts alone. However, when **any** living player unit reaches ready status, the **entire living party** is granted a unified action phase.
- **Cycling:** The player can cycle through all ready party members using `Tab`, executing moves and abilities in any chosen sequence.
- **CT Debt Prevention:** When a unit concludes its turn in a group phase, CT is clamped at `0` rather than allowing early actors to plunge into negative initiative debt.
- **Critic's Observation:** This mechanic fundamentally alters the traditional SRPG paradigm. It encourages complex cooperative maneuvers (e.g., a Sworn Blade moving to flank, a Mage breaking guard with an area spell, followed by a Ranger landing a lethal kill). However, it introduces an extreme risk of "Alpha-Strike Hegemony," where a single hyper-fast scout (high speed / Agility) continually pulls heavy, slow comrades into frequent group phases.

### 1.2 Action Economy (`Unit.pay` / `Unit.can_pay`)

- **Resource Split:** Every unit possesses an `action_spent` and `bonus_spent` state.
- **Cost Allocation:**
  - Standard Movement: Costs `Cost.EITHER` (consumes the bonus action first; falls back to main action if bonus is spent).
  - Flash Step (Blink Range): Always costs `Cost.BONUS`.
  - Abilities: Cost `Cost.ACTION` by default, unless flagged `"bonus": true` (e.g., Riposte, Spark, Shield Bash, Second Wind).
  - Consumables (Draughts): Costs `Cost.BONUS` from `GameState.stores`.
- **Critic's Observation:** The `Cost.EITHER` mechanic for movement is an elegant solution to the perennial grid-tactics dilemma of "move vs. act." By letting units reposition without sacrificing their primary attack—provided their bonus slot is open—combat remains mobile. However, the introduction of in-combat healing draughts as a bonus action creates potential degenerate sustain loops if gold reserves are high.

### 1.3 Flanking & Positional Mathematics (`AbilityResolver`)

- **Multipliers:** Attacks delivered to a target's side flank deal **1.2×** damage; attacks delivered to the back deal **1.5×** damage.
- **Facing Resolution:** Determined by `Unit.dominant_direction()`, derived from the orientation vector at turn termination.
- **Insight Bonus:** Attacking an enemy whose Guard has been unlocked in the Bestiary grants an additional **+5% insight bonus**.

---

## 2. Identified Vulnerabilities & Stress Areas

The investigation must rigorously test three primary points of systemic stress:

```
[Fast Scout triggers 100 CT] ──▶ [Whole Party Ready] ──▶ [Alpha Strike on Priority Foe]
              │                                                     │
              ▼                                                     ▼
     [CT Clamped at 0] ◀────────── [Tab Cycle All] ◀────── [Draught as Bonus Action]
```

1. **Initiative Exploitation (The "Scout Battery"):**
   - If a party composition stacks initiative-boosting gear on a single unit, does the group turn trigger so frequently that slower enemy cohorts never receive a combat window?
2. **Consumable Trivialization:**
   - Because draughts are drawn directly from `GameState.stores` without equipping them to individual belt slots beforehand, a party carrying 15 draughts effectively possesses an infinite health buffer during boss encounters.
3. **AI Positional Naivety:**
   - `EnemyBrain` plans moves and targets in discrete steps. Does the AI actively protect its rear arc against high-mobility flanking units, or does it leave its back exposed after attacking?
4. **Coliseum Multi-Team Dynamics:**
   - In 3-way brawls (`ENEMY_B`, `ENEMY_C`), does the threat assessment logic cause factions to realistically wage war on each other, or do both AI cohorts unconsciously converge upon the player?

---

## 3. Investigation & Benchmark Procedures

The evaluation team will execute the following automated and interactive diagnostic scenarios via `tests/bench.tscn`:

### Test Protocol 1.1: Alpha Strike and Initiative Saturation

- **Objective:** Measure whether player party alpha-strikes can eliminate high-danger foes before enemy turn 1.
- **Invocation:**
  ```powershell
  .\ek.ps1 --scene=battle --level=5 --play
  ```
- **Metrics Collected:**
  - Ratio of player actions to enemy actions over 50 combat rounds.
  - Frequency of back-flank hits landed by player vs. AI.
  - Number of enemy units killed before their first turn.

### Test Protocol 1.2: Consumable Attrition Stress

- **Objective:** Determine if high-tier gates and Spire bosses can be brute-forced using deep draught stocks.
- **Invocation:**
  ```powershell
  .\ek.ps1 --scene=battle --level=8 --stores=draught_amber:10,draught_red:10 --play
  ```
- **Threshold of Concern:** If party victory rate in an S-Rank gate exceeds 90% solely due to bonus-action healing without tactical positioning, the economy requires immediate rebalancing (e.g., introducing a consumable cooldown or limited pouch capacity).

### Test Protocol 1.3: Coliseum Free-For-All Target Distribution

- **Objective:** Profile AI cohort targeting in 3-way arena brawls.
- **Verification:** Inspect `the_grand_melee` card execution; record whether Enemy B attacks Enemy C with equal probability as attacking Player units.

---

## 4. Adjudication of the Third Judge: Combat & Tactical Grid

### The Deliberation

The Critic raises valid alarm regarding the "Scout Battery" exploit in `TurnManager.advance_group` and the bottomless draught pouch. The Developer's defense rests on player agency: group turns prevent the agonizing wait of 10-unit initiative queues, and bonus-action draughts prevent early-game attrition deaths.

The Third Judge inspects the tension between tactical discipline and action abuse:

1. **On Group Turns (`TurnManager.advance_group`):** Group activation is not inherently an exploit—it is the engine of tactical choreography. What makes _Earth Kings_ distinct from chess is that a team acts as a cohesive martial squad. However, clamping CT at `0` for all actors when a fast scout breaks 100 CT without taxing the slow actors creates an unearned speed subsidy.
2. **On In-Combat Draughts:** Drinking from `GameState.stores` without a belt limit violates the core design pillar: _Power is scarce; preparation is what buys lives_ ([01-vision.md](docs/01-vision.md)). A party walking into battle with twenty draughts in their infinite backpack turns mortality into a simple gold calculation.
3. **On AI Positional Naivety:** If the player gains 1.5× back-stab damage while the AI blindly marches forward without turning its back to a wall or ally, the tactical contract is one-sided.

### Judicial Rulings & Remedial Decrees

- **Ruling 1.1 (The Initiative Tax):** When `TurnManager.advance_group()` triggers, any ally whose personal CT was below 60 CT must pay a "Readiness Tax" on their next cycle (starting at `-25 CT`), preventing hyper-fast scouts from perpetually pulling heavy knights into free actions.
- **Ruling 1.2 (The Pouch Mandate):** Strike direct access to `GameState.stores` during combat. Implement a dedicated combat pouch (2 draught slots per character, pre-allocated at camp or world screen). Once consumed, the bag is inaccessible until the battle concludes.
- **Ruling 1.3 (AI Facing Priority):** In `EnemyBrain`, mandate that the final step of turn resolution evaluates threats in a 3-tile radius and re-orients the unit's dominant facing toward the highest calculated threat vector rather than defaulting to the movement direction.

> _"A victory won because Bram drank eight amber draughts out of an unequipped pack is not a hero's survival—it is an accounting trick. Enforce the combat pouch; make every draught carried into a gate a conscious sacrifice of space."_  
> — **The Third Judge**
