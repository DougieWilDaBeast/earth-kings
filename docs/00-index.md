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
| 12  | [World Charter Interview](12-world-charter-interview.md) | Absorbed into 15 — kept as a pointer |
| 13  | [Heroes & Tempers](13-heroes-and-tempers.md)         | The sixteen starting characters and the four questions that pick one |
| 14  | [Lore Pools & Casting](14-lore-pools.md)             | History authored with no character in mind, and how it gets attached |
| 15  | [The Question Book](15-the-question-book.md)         | **Every open question in one place** — 366 of them, 79 answered so far |
| 16  | [Lineage entries](16-lineage/00-index.md)            | Sixteen sources that shaped this, with 143 candidate answers tagged to question ids |
| 17  | [The Fall and the Sixteen Worlds](17-the-sixteen-worlds.md) | **The shape of the whole game** — the fall, the Tower's chapters, a world ending, what carries, the contest past the top. Direction, agreed 2026-09-24 |
| 18  | [Combat direction](18-combat-direction.md)           | The move to a real-time-with-pause fight, what the research has to answer, and what it costs |

## Deciding the world

The systems are specified; the world they run on mostly is not. Every open question lives in one
book, answered by voice note and reconciled into canon:

- [15 — The Question Book](15-the-question-book.md) — every question, in one file
- [Answers](worldbuilding/answers.md) — what has been settled, and by whom
- [**What is still to decide**](worldbuilding/answers.md#what-is-still-to-decide) — the agenda: the open follow-ups, the contradictions, and the drafts waiting on a yes
- [Respondents](worldbuilding/respondents.md) — who may answer, and with what standing
- [Voice notes](worldbuilding/voice-notes/) — raw transcripts, kept as spoken, including
  [joint session 1](worldbuilding/voice-notes/2026-09-24-joint-session-1.md) — both founders, 2026-09-24
- [Lineage entries](16-lineage/00-index.md) — 143 drafted answers from the sixteen works that shaped this
- [Process](worldbuilding/00-process.md) — how the sittings and merge sessions run
- [Divergence ledger](worldbuilding/divergence-ledger.md) — forks, resolutions, and what the
  losing answers become
- [Casting ledger](worldbuilding/casting-ledger.md) — which authored history could belong to
  which of the sixteen, why, and what was decided

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
