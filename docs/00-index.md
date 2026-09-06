# Earth Kings — Design Package

The working documentation for the game. Read in order; each doc is short on purpose.

| #   | Doc                                                  | What it answers                                                 |
| --- | ---------------------------------------------------- | --------------------------------------------------------------- |
| 01  | [Vision](01-vision.md)                               | What this is, what it is deliberately not, what is deferred     |
| 02  | [Design](02-design.md)                               | The loop and every system in it                                 |
| 03  | [Architecture](03-architecture.md)                   | Where code lives, how it talks, where the seams are             |
| 04  | [Data formats](04-data-formats.md)                   | Every JSON schema, so content can be added without reading code |
| 05  | [Roadmap](05-roadmap.md)                             | Milestones and honest status                                    |
| 06  | [Decisions](06-decisions.md)                         | What was decided, when, and why — append-only                   |
| 07  | [Lineage](07-lineage.md)                             | Where this came from, so the trail is not lost                  |
| 08  | [Threads](08-threads.md)                             | Long-running story in a game with no quest log                  |
| 09  | [Wishlist](09-wishlist.md)                           | Spoken notes, transcribed, and what was done about each         |
| 10  | [Manual tests](10-manual-tests.md)                   | Human verification checklist across all screens and systems     |
| 11  | [Character Backstories](11-character-backstories.md) | Lineage, ethos, companions, and lore for all 12 playable heroes |

## Forensic Investigation Package

A critical evaluation and comprehensive investigation plan conducted from the perspective of an expert ludological critic:

- [00 — Critic Mandate & Evaluation](investigation/00-critic-mandate-and-evaluation.md)
- [01 — Tactical Grid & Combat Systems](investigation/01-tactical-grid-and-combat-systems.md)
- [02 — World Topology & Step Chronometry](investigation/02-world-topology-and-the-step-clock.md)
- [03 — Character Progression & The Mortality Engine](investigation/03-character-progression-and-the-mortality-engine.md)
- [04 — Narrative Architecture & The Frieren Layer](investigation/04-narrative-resonance-and-the-frieren-layer.md)
- [05 — Sensory Presentation & Ergonomics](investigation/05-sensory-presentation-and-ergonomics.md)
- [06 — Forensic Test Matrix & Benchmarks](investigation/06-forensic-test-matrix-and-benchmarks.md)

## Working rules

1. **Content lives in `data/`, never in code.** A new gate, class, doctrine or unit is a JSON edit.
2. **Systems talk through `EventBus`.** No system holds a reference to another.
3. **Every milestone ends playable.** Nothing starts until the previous thing runs.
4. **Update `06-decisions.md` when a design question is settled.** Future-you will not remember why.
5. **Docs describe what exists.** Planned work belongs in the roadmap, marked as planned.
