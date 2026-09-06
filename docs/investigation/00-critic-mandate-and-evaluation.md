# Forensic Evaluation & Investigation Mandate: _Earth Kings_

**Evaluator:** Lead Ludological Critic & Systems Examiner  
**Scope of Assessment:** Complete engine, mechanics, narrative systems, progression telemetry, audiovisual staging, and runtime stability.  
**Subject:** _Earth Kings_ (Godot 4 SRPG / Local-Native GDScript Architecture)  
**Status:** Pre-Release Forensic Investigation Ordered

---

## 1. Executive Critique: The State of _Earth Kings_

_Earth Kings_ is an anomaly in modern independent game design. Where contemporary tactical role-playing games routinely drift toward frictionless power fantasy, infinite undo trees, and mechanical bloat, _Earth Kings_ stands as an unyielding, melancholic, and mechanically severe monument to consequence.

Its foundational premise is daring: a turn-based tactical RPG constructed upon a living, step-driven clock where travel is never free, death is the default consequence of defeat, power is discovered through an arcane procedural grammar rather than chosen from an authored buffet, and quiet companionship is treated with as much mechanical gravitas as martial slaughter. The influence of _Sousou no Frieren_—manifest in its memorial sites, forgotten grimoires, and campfire reflections—infuses what could have been a cold simulation with a profound sense of temporal weight.

Yet, this exact severity creates tremendous fragility. When a game demands that the player accept irreversible permadeath and the slow decay of hard-won knowledge, the underlying systems must operate with mathematical perfection and aesthetic absolute truth. Any systemic leak—a clunky turn transition, an erratic camera snap, a visual artifact that betrays the world’s diegetic reality, or a dead zone in overworld travel—does not merely cause minor irritation; it breaks the sacred contract of consequence.

### The Critic’s Verdict in Brief

_Earth Kings_ possesses the intellectual and mechanical architecture of a masterpiece in waiting, but it currently hovers in a critical phase space where brilliant high-concept design collides with systemic strain. The game must not be reviewed casually. It demands a rigorous, multi-vector forensic investigation across five primary domains of play before a final critical judgment can be pronounced.

---

## 2. The Third Judge: Judicial Concurrence & Adjudication Framework

To ensure that this inquiry neither succumbs to uncritical auteur sycophancy nor dismisses deliberate friction as developer oversight, an independent **Third Judge** (Tribunal Arbitrator & Systems Jurisprudent) has been impaneled alongside the Chief Ludological Critic and Systems Examiner.

### The Judicial Philosophy

The Third Judge does not evaluate _Earth Kings_ against the standard consumer expectations of mass-market, frictionless power-fantasy RPGs. Instead, the Third Judge evaluates against **internal ludic jurisprudence**:

1. **The Contract of Severity:** If a game promises that death is real and knowledge decays, does it keep that promise without cheating the player, and does it reward the exact behaviors it demands?
2. **The Defense of Intentional Friction:** Friction is not inherently a defect. A slow walk across a bleak country or the agony of losing a scholar can be the artistic core. The Judge distinguishes _vital friction_ (which generates meaning) from _accidental friction_ (which generates irritation).
3. **The Final Adjudication:** In each investigative dossier, the Third Judge issues a formal, binding ruling—weighing the Critic's indictment against the Architecture's intent—and prescribes non-negotiable remedial rulings.

The evaluation team is equipped with exhaustive analytical, diagnostic, and empirical apparatus to probe every seam of _Earth Kings_:

1. **Deterministic Benchmarking & State Synthesis:**
   - Full command of `ek.ps1` and `tests/bench.tscn`, enabling instantaneous booting into targeted world coordinates, specific danger levels, custom party rosters, calibrated gold reserves, and automated screenshot captures (`--scene=`, `--at=`, `--level=`, `--gold=`, `--stores=`, `--shot`, `--play`).
2. **Telemetry & Ledger Analytics:**
   - Real-time hooks into `GameState.ledger`, extracting kill counts, total damage throughput, floor clearances, step counts, and gold accumulation curves across hundreds of virtual journeys.
3. **Mathematical Monte Carlo Simulators:**
   - Independent verification scripts auditing the six-tier `Fate` grace cascade (`Charm`, `Rescue`, `Lore`, `Ground`, `Luck`, `Capture`), measuring survival rates across thousands of simulated lethal falls.
4. **Ludonarrative & Grammar Parsing Engines:**
   - Structural decoders that parse `data/abilities.json`, `data/banter.json`, `data/threads.json`, and `AbilityGrammar` output to evaluate semantic variety, emotional resonance, and thematic coherence.
5. **Aesthetic & Sensory Scanners:**
   - Pixel-level frame inspection, Wang tile transition boundary probes, audio bus dynamic range logging, and animation frame completeness profiling across all 69 unit templates.

---

## 3. The Investigation Plan: Suite of Dossiers

To conduct this investigation systematically, the inquiry is partitioned into six forensic dossiers:

| Dossier | File Link                                                                                                                                          | Focus Area & Primary Inquiries                                                                                                                |
| ------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **00**  | [docs/investigation/00-critic-mandate-and-evaluation.md](docs/investigation/00-critic-mandate-and-evaluation.md)                                   | **The Mandate:** Core critique, thesis, diagnostic capabilities, and investigation charter.                                                   |
| **01**  | [docs/investigation/01-tactical-grid-and-combat-systems.md](docs/investigation/01-tactical-grid-and-combat-systems.md)                             | **Tactics & Combat:** The unified party phase, action economy, directional flanking, AI lethality, and consumable pacing.                     |
| **02**  | [docs/investigation/02-world-topology-and-the-step-clock.md](docs/investigation/02-world-topology-and-the-step-clock.md)                           | **Topology & Step Chronometry:** The 128×128 continental map, the step-clock upkeep engine, prowler sight cones, and roadside economics.      |
| **03**  | [docs/investigation/03-character-progression-and-the-mortality-engine.md](docs/investigation/03-character-progression-and-the-mortality-engine.md) | **Progression & Mortality:** Permadeath graces, the Training Yoke, procedural skill tree agency, and doctrine entropy.                        |
| **04**  | [docs/investigation/04-narrative-resonance-and-the-frieren-layer.md](docs/investigation/04-narrative-resonance-and-the-frieren-layer.md)           | **Narrative & The Frieren Layer:** Dynamic campfire banter, memorial visits, town sieges, and emergent story threads (`Skein`).               |
| **05**  | [docs/investigation/05-sensory-presentation-and-ergonomics.md](docs/investigation/05-sensory-presentation-and-ergonomics.md)                       | **Aesthetics & Ergonomics:** The 68-unit animation deficit, Wang tile seams, dual-bus audio staging, camera rig dynamics, and modal friction. |
| **06**  | [docs/investigation/06-forensic-test-matrix-and-benchmarks.md](docs/investigation/06-forensic-test-matrix-and-benchmarks.md)                       | **Empirical Protocols:** Reproducible CLI test invocations, stress harnesses, and telemetry extraction criteria.                              |

---

## 4. Primary Hypotheses to Investigate

Before executing the test matrix, the critic poses five core hypotheses that will determine whether _Earth Kings_ succeeds as an enduring classic or falters under its own conceptual weight:

1. **The Tactical Agency Hypothesis:** Does the unified player phase (`TurnManager.advance_group`) empower squad synergy, or does it trivialize enemy counter-play by enabling alpha-strike burst combinations that circumvent the CT system?
2. **The Continental Fatigue Hypothesis:** Does the expansion from 44×44 to 128×128 tiles enrich exploration with meaningful geographic isolation, or does the step-clock turn overland navigation into an unrewarding, high-friction attrition march?
3. **The Mortality Contract Hypothesis:** Does the six-tier grace cascade genuinely communicate "survival is earned through preparation," or does the 7% flat Luck grace and RNG variance create perceived arbitrariness when an investment of ten hours ends in a ditch?
4. **The Procedural Poetics Hypothesis:** Do generated skill trees from the hidden grammar feel like genuine discoveries of lost ancient arts, or do they degenerate into mathematical soup lacking distinct tactical identity?
5. **The Atmospheric Unity Hypothesis:** Can the somber, contemplative storytelling survive the jarring visual dissonance between the fully animated `sworn_blade` and the sliding, static sprites of the remaining 68 units?

The following dossiers lay out the exhaustive investigative procedure to answer each question definitively.

---

## 5. Third Judge Verdict on the Mandate

> _"The court accepts the forensic charter with one paramount caveat: do not sterilize the game's tragedy in the pursuit of mechanical neatness. Many reviewers mistake cruelty for poor balance, and many developers mistake inconvenience for profundity. Our investigation will not reward the game for merely being harsh; it will examine whether every ounce of player suffering yields an equivalent ounce of tellable history."_  
> — **The Third Judge**
