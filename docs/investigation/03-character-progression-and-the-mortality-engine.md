# Dossier 03: Character Progression & The Mortality Engine Investigation

**Focus:** Permadeath mechanics, the grace cascade, procedural skill trees, doctrine decay, and equipment fit.  
**Primary Source Modules:** `src/chronicle/fate.gd`, `src/chronicle/progression.gd`, `src/chronicle/character.gd`, `src/chronicle/gear.gd`, `src/battle/abilities/ability_grammar.gd`  
**Reference Docs:** [docs/02-design.md](docs/02-design.md), [docs/06-decisions.md](docs/06-decisions.md)

---

## 1. Mechanics of Growth and Mortality

In _Earth Kings_, progression is not a linear treadmill of stat bloat; it is a precarious negotiation with permanent loss.

### 1.1 The Mortality Engine & The Grace Cascade (`Fate.resolve`)

When a character’s hit points reach zero, death is the default state. Survival cannot be assumed; it must be bought through tangible prior preparation ([D11](docs/06-decisions.md#L18)). Survival is calculated via a strictly prioritized cascade of "Graces," where the first roll to succeed claims the outcome:

```
[Character Falls to 0 HP]
          │
          ▼
    1. Charm Grace (Relic Carried: Grave Token 50%, Knotted Cord 25%) ──▶ LIVES (Item Destroyed)
          │ (fail)
          ▼
    2. Rescue Grace (12% per standing ally, max 36%) ───────────────────▶ LIVES (Rescuer Named)
          │ (fail)
          ▼
    3. Lore Grace (Sum of read doctrine grace values, max 30%) ─────────▶ LIVES (Book Cited)
          │ (fail)
          ▼
    4. Ground Grace (15% if within 6 tiles of active Hearth) ───────────▶ LIVES (Crawls to Camp)
          │ (fail)
          ▼
    5. Luck Grace (Flat 7% unconditional roll) ─────────────────────────▶ LIVES (Pure Fortune)
          │ (fail)
          ▼
    6. Capture Grace (Raiders 40%, Soldiers 30%, Beasts 0%) ────────────▶ CAPTURED (Ransom Set)
          │ (fail)
          ▼
       PERMADEATH (Character Erased from Active Roster)
```

- **Telemetry Baseline:** Over 200 simulated unassisted falls against beasts, an unprepared adventurer dies **186 times** (93% mortality). Standing allies lift survival to 31%; read doctrine elevates it further.

### 1.2 The Power Grammar (`AbilityGrammar`)

- **Procedural Synthesis:** Skill trees are not authored lists; they are synthesized from 9 Themes (Edge, Ember, Storm, Hunt, Iron, Vigil, Hearth, Mourning, Wind) crossed with 7 Effect Archetypes (Blow, Reach, Loose, Burst, Sweep, Mend, Rally) across 3 intensity rungs.
- **Milestone Unlocks:**
  - Level 2: Player manually selects Class; companions assign based on template weighting ([D12](docs/06-decisions.md#L19)).
  - Level 5: First generated skill tree awakens.
  - Level 10: Second skill tree awakens, preferring an unheld thematic branch.
- **Rung Allocation:** Leveling grants unspent rungs (`Character.rungs`), which the player manually invests into unlocked tree nodes via the Party Screen.
- **The Codex:** Cataloguing distinct grammar permutations increases continental understanding, granting up to +20% global tree effectiveness and unlocking theme selection at 100% completion ([D17](docs/06-decisions.md#L24)).

### 1.3 Knowledge Decay & Doctrine Entropy

- **Per-Character Retention:** Reading at a Library instills doctrine directly into a specific character.
- **The Entropy Clock:** Unused or unpracticed knowledge decays every 900 steps ([D07](docs/06-decisions.md#L14)).
- **Party Pedagogy:** Characters can spend campfire time teaching read doctrine to companions, distributing life-saving lore before it fades.

### 1.4 Gear Affinity & Misfit Penalties (`Gear.suits`)

- **Suitability:** Equipment carries explicit calling affiliations. A heavy plate armor suits an Iron Knight or Sworn Blade; a longbow ranger wearing it receives only a fraction of its defensive value (`MISFIT_SHARE`) and incurs an agility penalty (`MISFIT_PENALTY`).

---

## 2. Identified Vulnerabilities & Stress Areas

### 2.1 The "Last-Hit" XP Friction

- **Mechanic:** Combat XP (`20 + level² × 6`) is awarded exclusively to the unit delivering the killing blow.
- **Critic's Concern:** This mechanic risks encouraging anti-tactical behavior: players intentionally withholding optimal attacks from heavy hitters to allow weak or under-leveled support units to scrape the final hit.

### 2.2 The Permadeath / Save-Scumming Paradox ([D21](docs/06-decisions.md#L28))

- **Mechanic:** Save/load is unrestricted; reloading after a tragic death is left to the player’s conscience.
- **Critic's Concern:** While pragmatic for avoiding player hostility, does unrestricted reloading completely dismantle the existential dread of the Grace Cascade? If a player can simply reload after failing the grace roll, the tension of the preparation thesis is compromised.

### 2.3 Doctrine Entropy Cognitive Load

- **Critic's Concern:** Does the 900-step knowledge decay mechanic create genuine temporal stakes, or does it trigger "maintenance anxiety," forcing repetitive backtracking to distant libraries just to keep grace and combat buffs active?

---

## 3. Investigation & Benchmark Procedures

### Test Protocol 3.1: Monte Carlo Grace Distribution Audit

- **Objective:** Empirically verify grace trigger distributions across 1,000 automated lethal fall simulations.
- **Test Matrix:**
  1. Naked / Unread Solo unit vs Beast (Target: ~93% death rate).
  2. Fully geared company with 3 allies standing (Target: ~36% rescue rate).
  3. Lore scholar carrying 2 charms near hearth (Target: >85% survival rate).
- **Harness:** Run custom batch in `tests/bench.tscn` evaluating `Fate.resolve`.

### Test Protocol 3.2: Grammar Balance & Outlier Detection

- **Objective:** Generate 500 distinct skill trees from `AbilityGrammar` and identify statistical outliers.
- **Evaluation Criteria:**
  - Flag any rung combinations where burst damage exceeds single-target cap by >150%.
  - Flag any theme combinations producing redundant or non-functional abilities.

### Test Protocol 3.3: Misfit Penalty Usability Check

- **Objective:** Test party screen gear equipping with mismatched class items.
- **Verification:** Confirm UI cleanly displays the negative swing `(-X)` without obscuring base stats.
