# Earth Kings — Design Package

The working documentation for the game. Read in order; each doc is short on purpose.

| #   | Doc                                                  | What it answers                                                 |
| --- | ---------------------------------------------------- | --------------------------------------------------------------- |
| 01  | [Vision](01-vision.md)                               | What this is, what it is deliberately not, what is deferred     |
| 02  | [Design](02-design.md)                               | The loop and every system in it                                 |
| 03  | [Architecture](03-architecture.md)                   | Where code lives, how it talks, where the seams are             |
| 04  | [Data formats](04-data-formats.md)                   | Every JSON schema, so content can be added without reading code |
| 05  | [Roadmap](05-roadmap.md)                             | Milestones and honest status — and the next steps, in order     |
| 06  | [Decisions](06-decisions.md)                         | What was decided, when, and why — append-only                   |
| 07  | [Lineage](07-lineage.md)                             | Where this came from, so the trail is not lost                  |
| 08  | [Threads](08-threads.md)                             | Long-running story in a game with no quest log                  |
| 09  | [Wishlist](09-wishlist.md)                           | Spoken notes, transcribed, and what was done about each         |
| 10  | [Manual tests](10-manual-tests.md)                   | Human verification checklist across all screens and systems     |
| 11  | [Character Backstories](11-character-backstories.md) | Lineage, ethos, companions, and lore for all 12 playable heroes |
| 12  | [World Charter Interview](12-world-charter-interview.md) | Absorbed into 15 — kept as a pointer |
| 13  | [Heroes & Tempers](13-heroes-and-tempers.md)         | The sixteen starting characters and the four questions that pick one |
| 14  | [Lore Pools & Casting](14-lore-pools.md)             | History authored with no character in mind, and how it gets attached |
| 15  | [The Question Book](15-the-question-book.md)         | **Every open question in one place** — 366 of them, 85 answered so far (2026-10-13) |
| 16  | [Lineage entries](16-lineage/00-index.md)            | Sixteen sources that shaped this, with 143 candidate answers tagged to question ids |
| 17  | [The Fall and the Sixteen Worlds](17-the-sixteen-worlds.md) | **The shape of the whole game** — the fall, the Tower's chapters, a world ending, what carries, the contest past the top. Direction, agreed 2026-09-24 |
| 18  | [Combat direction](18-combat-direction.md)           | The move to a real-time-with-pause fight, what the research has to answer, and what it costs |
| 19  | [Asset list](19-asset-list.md)                       | Everything to generate in PixelLab, in order — starting with the size test before the credits reset on 2026-09-27 |
| 20  | [The PixelLab size test](20-pixellab-size-test.md)   | Step-by-step instructions for the size test: settings, prompts, order, importing, the viewer, and recording the call |
| 21  | [The Sixteen: a first draft](21-the-sixteen-first-draft.md) | **Draft, not settled** — all sixteen proposed from joint session 1: names, seeds, sixteen ways to fight, where each one is. For the founders to keep or replace |
| 22  | [Asset provenance](22-asset-provenance.md)           | Where every file in `art/` and `audio/` and every font came from, its licence, and what must be cleared before a public release |
| 23  | [Originality pass](23-originality-pass.md)           | Which characters copied someone else's, what they are called now, and the PixelLab prompts to redraw them |
| 24  | [Art requests](24-art-requests.md)                   | **The art waiting to be made** — written here, then `dougie` generates it in PixelLab |
| 25  | [The opening](25-the-opening.md)                     | The cinematic after New Game: what each shot shows, where its words live, and how to change it |
| 26  | [Coins and prices](26-coins-and-prices.md)           | **Proposed, not built** — every price and earning in copper, silver, gold and platinum, for `doug-md` to check |
| 27  | [The world](27-the-world.md)                         | The one world every run is played on: the map, what stays the same and what the seed deals, and how to change it |
| 28  | [The First Hour](28-the-first-hour.md)               | **What a new player plays today**: the route from the crater to chapter one, the sixteen chapter ones, the play-tests and every build on itch |
| 29  | [The store page](29-the-store-page.md)               | **A draft, not published**: the name, five lines and five shots for the Steam page, each promising only what the First Hour shows |
| 30  | [Questions for the founders](30-questions-for-the-founders.md) | **What only Will and Ewan can answer**, read aloud and answered by voice note: who, why it matters, and the default |
| 31  | [What needs music](31-music.md)                  | **Planned**: which scenes need music and in what order, the memory theme first, for when the music is made |
| 32  | [How work moves](32-the-pipeline.md)                 | **The stages and the pipeline**: where the game stands in the stages of making a game, what is still expensive to change, and the loop every piece of work goes round, with the milestones from here |

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
- [07 — Dungeon Settlers: the combat deep dive](investigation/07-dungeon-settlers-combat.md) — the research [D36](06-decisions.md) asked for, first pass 2026-09-24
- [08 — Quests and a living world](investigation/08-quests-and-a-living-world.md) — _Baldur's Gate 3_, _The Witcher 3_ and _Skyrim_, and a proposal for what replaces the step clock (2026-10-12, **Inferred**)
- [09 — The lands of the continent](investigation/09-lands-of-the-continent.md) — _Necesse_, _Terraria_, _Valheim_ and _Don't Starve_, and the eighteen lands built from them ([D66](06-decisions.md), 2026-10-12)
- [10 — Who wins? shows](investigation/10-who-wins-shows.md) — a channel of simulated "who wins?" fights, read off its frames, and the show built from it ([D180](06-decisions.md), 2026-10-16)
- [11 — RimWorld's Play Screen, for Earth Kings](investigation/11-rimworld-play-screen.md)
- [12 — A small on-device model for fight plans](investigation/12-a-small-model-for-fight-plans.md) — EmbeddingGemma 2, what would run it in Godot, what a native runtime costs the stack, and an offline table to try first ([D298](06-decisions.md), #385, 2026-10-20, **Inferred**)
- [13 — How other mobile games do touch](investigation/13-mobile-controls.md) — seventeen phone games (_Into the Breach_, _FTL_, _Bad North_, _Divinity: Original Sin 2_, _Stardew Valley_ and more), what works on a thumb, and a ranked list of what Earth Kings could build now and after 1.0 ([D379](06-decisions.md), 2026-10-22, **Inferred**)
- [14 — What we can take from outside](investigation/14-outside-assets-and-services.md) — art, sound, Godot addons, Steam and other services, community tools, and what multiplayer would mean, with named sources and licences and a do-first list ([D426](06-decisions.md), 2026-10-23, **Inferred**, waits on Will)

## Working rules

1. **Content lives in `data/`, never in code.** A new gate, class, doctrine or unit is a JSON edit.
2. **Systems talk through `EventBus`.** No system holds a reference to another.
3. **Every milestone ends playable.** Nothing starts until the previous thing runs.
4. **Update `06-decisions.md` when a design question is settled.** Future-you will not remember why.
5. **Docs describe what exists.** Planned work belongs in the roadmap, marked as planned.

Coding agents get the same rules, and the commands, in [AGENTS.md](../AGENTS.md). CI runs every
smoke suite, a two-minute soak and the ledger check on each pull request
([10 — Manual tests](10-manual-tests.md#automated-tests)).
