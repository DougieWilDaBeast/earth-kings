# 05 — Roadmap

Shipping-first ordering: every milestone ends with something runnable. Nothing starts until the
previous milestone demonstrably works.

## M0 — Tactics core — SHIPPED

- Square grid, Dijkstra movement with per-tile cost and jump, charge-time turn order
- Abilities with min range, max range, splash, healing; facing bonuses (side 1.2×, back 1.5×)
- Enemy AI that plans a move and a target
- Directional unit art, equipment with per-facing offsets
- Wounds persisting between battles; title screen, system menu, save/load
- Headless smoke test that plays a whole battle

## M1 — Characters and progression — SHIPPED

- `Character` as the persistent person, distinct from the battle `Unit` ✅
- XP curve, level-ups, class choice at level 2, Training Yoke stance ✅
- Doctrine bonuses feeding derived stats ✅
- `Roster` holding the party; battles spawning from Characters and writing results back ✅
- Permadeath wired through battle resolution via [`Fate`](02-design.md) ✅
- XP awarded to whoever landed the killing blow ✅ — superseded by M12: first kill of each kind only

## M2 — The generated power system — SHIPPED

- Hidden ability grammar: themes × archetypes × rungs ✅
- Tree generation, registration into `Database`, restore-on-load ✅
- Codex understanding readout ✅
- Trees unlocking at levels 5 and 10, feeding the battle command menu ✅
- Archetypes weighted per theme, so a knight's trees come out sharp ✅
- Throwaway foes scale with `raise_quietly` and never pollute the world's tree registry ✅

## M3 — The world and walk mode — SHIPPED

- `World` — ground, places, the step clock, serialisation ✅
- `WorldGen` — noise ground, scattered sites, gates ranked E–S, seeded doctrine ✅
- Walk scene: tile-by-tile movement with hold-to-repeat, camera follow, map rendering ✅
- Site interactions: rest, read, delve, climb ✅
- Live readout of where you are and how dangerous it is ✅

## M4 — Encounters and procedural battlefields — SHIPPED

- Encounter roll driven by distance to the nearest open gate and nearest hearth ✅
  (measured: 37% in a gate's mouth, 1% at the starting village)
- Battlefield generation from the world terrain you were standing on ✅
- Enemy composition and levels scaled to party level and local danger ✅

## M5 — Gates and delves — SHIPPED

- Stepping on an open gate fights its garrison and its guardian ✅
- Clearing shuts the gate and pays out; the world reopens gates over time ✅
- Multi-floor delves: a gate's rank sets how many fights deep it goes, retreating keeps the floors
  you took and losing gives them back ✅ — retreat removed by D35: there is no walking out
- Floor delve rewards: charm finds, generated skill tree discoveries on deep delves (rank C+), and written doctrine ✅

## M6 — The Tower — SHIPPED

- One battle per floor, escalating and never scaling down to meet you ✅
  (measured: floor 1 fields level 5, floor 6 fields level 15)
- Permanent floor log on the world ✅
- Floor rewards: gold every floor, doctrine every third, a new tree every fourth ✅
- A reason to stop: a floor's gold goes into `world.tower_hoard`, not the purse. It is banked by
  walking off the Tower and lost by losing a floor, so every extra climb is a decision about what
  you are already carrying ✅
- The Spire Apex: Floor 10 climax battle, hoard claiming, ascension vigour, and conclusion in the Museum ([D25](06-decisions.md)) ✅

## M7 — The Library and doctrine — SHIPPED

- Reading at a library; per-character knowledge ✅
- Entropy pass folded into walking ✅
- Teaching between party members, on the party screen ✅
- Each character's shelf shown, with anything close to fading marked ✅

## M8 — Fit to play — SHIPPED

- World in the save file, verified by a round-trip test ✅
- A real class picker on the party screen ✅
- Party screen: class choice, teaching, the Training Yoke, the Codex readout ✅
- The run ends when the party is gone ([D13](06-decisions.md)) ✅
- Every run generates its own world, with the seed readable from the menu ✅
- A seed can be typed in on the character select, so a country can be gone back to ✅
- Balance pass across levels 1–10: verified XP pacing, class stat growth curves, faction encounter scaling, and equipment misfit penalties ✅
- Dual progression pathways: branching generated trees at level 10, campfire strongbox stash, and journal trade ledger ✅
- ✅ Done when: two people can play a session without hitting a wall

## M9 — Living World & Geographic Breadth — SHIPPED

- 128×128 continental expansion with noise shoreline, lakes, snow, desert, and named regions ✅
- 33 hand-built top-down explorable areas with A\* pathfinding and obstacle avoidance ✅
- Planar and Continental view switching (`Z`) with seamless cardinal edge navigation ✅
- Four seasonal clovers advancing on the 120-step continental calendar (`Season`) ✅
- Persistent Nemesis system: surviving foes take epithets, remember past clashes, and rally ✅
- Continental news and tavern tidings (`News`) surveying sieges, broken gates, and trade ✅
- Coastal ferry network connecting seaside havens across oceans (`Ferry`) ✅
- Coliseum gladiator bouts, stakes wagering, and 3-way free-for-all cohorts (`Arena`) ✅
- The Annals: historical chronicle compiled from live telemetry (`Annals`) ✅
- Tactical ambush mechanics: cover stalks grant opening CT initiative and surprise damage ✅

## From here — the sixteen worlds

Joint session 1 (2026-09-24) set the direction: [17 — The Fall and the Sixteen Worlds](17-the-sixteen-worlds.md),
[18 — Combat direction](18-combat-direction.md), [D31–D40](06-decisions.md). What follows is
**planned, not built**. The rule does not change: every milestone ends playable, and nothing starts
until the one before it demonstrably works. Where a milestone waits on a founder answer, it names
the [agenda item](worldbuilding/answers.md#what-is-still-to-decide).

### Next steps, in order

Updated 2026-09-24, after M11's prototype, M12, M16, D35 and D39 were built. **Everything left on
this list needs one or both founders** — the build has gone as far as it can without an answer.
Since 2026-09-26 every pull request is checked by CI (the suites, a soak, and the ledger), and the
repo is wired to `dougie`'s LLM gateway for tooling only — see [AGENTS.md](../AGENTS.md).

1. **By 2026-09-27 — spend the last 15% of PixelLab credits on the size test.** Everything is
   ready: step-by-step instructions in [20](20-pixellab-size-test.md), the viewer
   (`.\ek.ps1 sizetest`) and the importer.
   [19 — Asset list](19-asset-list.md), Tier 0. The model game measures in the 32 class
   ([investigation/07](investigation/07-dungeon-settlers-combat.md#13-sprite-size-and-frame-counts)),
   so 32 against the 64 on disk is the real choice.
2. **Play the real-time skirmish against the turn-based fight** (Training → Fight in real time).
   Judge facing, `HEALTH_SCALE`, how often you pause, and whether auto-pause helps. That decides
   whether M11 replaces the turn loop ([D36](06-decisions.md)).
3. **An hour of _Dungeon Settlers_ itself** — the ten questions at the end of
   [investigation/07](investigation/07-dungeon-settlers-combat.md#what-only-playing-it-can-answer).
4. **Next founders' session** — the [agenda](worldbuilding/answers.md#what-is-still-to-decide),
   items 1–2 and 4–12 and 15. Items 1 and 2 (the Tower's floor count, and steps against Tower
   chapters) unblock M14; items 4 and 5 unblock M15; 6, 7 and 15 unblock M13; 11 unblocks party
   growth. Item 3 — the research and the prototype — has gone as far as it can without play (steps
   2 and 3); 13 is built; 14 is deferred to playtest.
5. **First writing sitting for the sixteen** — the four NT tempers ([13](13-heroes-and-tempers.md#writing-one)),
   starting from the seeds the session left, with god-style names ([D39](06-decisions.md)).
6. **Optional, `dougie` — try the voice-note mapper on the real gateway.** With the
   [LLM gateway](https://github.com/DougieWilDaBeast/llm-gateway) up and `LLM_GATEWAY_KEY` set,
   `python3 tools/map_voice_note.py docs/worldbuilding/voice-notes/2026-09-14-doug-md-part-1-b-land-scale-and-edges.md`
   and compare its draft against the `LN` entries in [answers.md](worldbuilding/answers.md). If it
   finds what the hand ingest found, and the verbatim check rejects little, use it as the first
   pass for the next session's transcript ([voice notes](worldbuilding/voice-notes/README.md#a-first-pass-by-model)).
7. **Tuning, whenever it annoys you:** `experience.first_kill_multiplier` and `assists_needed`, the
   `dispatch` odds, and `names.json` are all in `data/` and one number each.

Before any build goes to a playtest: `.\ek.ps1 test`, then one five-minute `tools/soak.tscn` run
([10](10-manual-tests.md#automated-tests)). Since 2026-09-26 CI runs every suite and a two-minute
soak on each pull request, so the five-minute soak is the only step left to do by hand. The seams audit on 2026-09-24 found six bugs no suite
was looking for, all now fixed and covered — see `tests/seams_smoke_test` and
[D42](06-decisions.md).

### M10 — Research and the size test — IN PROGRESS

- Deep dive into _Dungeon Settlers_' combat, written up in `docs/investigation/` against the
  questions in [18](18-combat-direction.md#what-the-research-has-to-answer) — **first pass done**:
  [investigation/07](investigation/07-dungeon-settlers-combat.md), from published sources. Still to
  do: an hour of hands-on play to answer the ten questions it lists at the end
- Sprite size test in PixelLab — 64, 32 and 16 side by side, four units on screen ([19](19-asset-list.md), Tier 0).
  **Prepared** 2026-09-25: instructions ([20](20-pixellab-size-test.md)), `tools/size_test.tscn`,
  the importer, `art/size_test/RESULTS.md` — waiting on the generating
- The size written into [06 — Decisions](06-decisions.md)
- ✅ Done when: both founders have read the report, seen the sizes in the battle scene, and a
  D-entry says which size

### M11 — The real-time fight, as a prototype — IN PROGRESS

Started 2026-09-24, on the first pass of M10. A playable prototype exists — see
[18 — The prototype](18-combat-direction.md#the-prototype) — and the items below are marked
against it.

- A separate battle scene: real time, pause at any moment, speed up and slow down ✅ (`src/skirmish/`)
- Point-and-click movement on the existing grid; automatic basic attacks ✅
- Four active abilities per unit on Q W E R, with cooldowns ✅ and cast times ✅; a per-unit auto
  toggle ✅ and Wait for Orders ✅. Passives — not yet
- Attack, hit and death animations for one party of four and three enemy kinds ([19](19-asset-list.md), Tier 1) — waits on art
- Facing ✅ and generated battlefields ✅ carried over; falling becomes a near-death window a
  companion can reach ✅ — the graces are not rolled yet
- A headless smoke test that plays it out ✅ (`tests/skirmish_smoke_test.tscn`)
- Reachable from the Training ground and the bench ✅. A training fight only — nothing written back
- Touch controls ✅ (2026-09-25): tap to pick, tap to order, the keys as buttons down the right
- Auto-pause, off / on a fall / on a fall or a manual skill ready ✅; the J and P leans in real time ✅
- ✅ Done when: both founders have played the prototype against the current battle and chosen.
  Only then does it replace `TurnManager` ([D36](06-decisions.md))

### M12 — Getting stronger the new way — SHIPPED

Built 2026-09-24, in the turn-based battle. The real-time skirmish is training-only and awards
nothing yet.

- Experience per character from the **first kill of each kind of enemy**; the last hit takes it ✅
  (`Progression.award_kill`)
- Assists counted per kind, and a kind's experience after five ✅ — one number for now; agenda
  item 8 asks whether grunts should take ten
- Bosses give everyone involved their experience ✅ — gate guardians and the Tower's apex fighter
  are flagged `"boss": true` in `encounter.gd`
- Proficiency per weapon kind (blade, bow, staff, bare hands) as well as per move, both rising by
  use and both adding to how hard a move hits ✅ (`Proficiency.arms_rank`)
- The party screen's Practice page shows weapon skill, the kinds each character has learned from,
  and the assists they are part-way through ✅
- ✅ Done when: killing the same enemy twice gives experience once, and a soak run shows levels
  rising only as the party meets new things ([D37](06-decisions.md)) — `tests/experience_smoke_test.tscn`:
  one goblin takes a fresh character from level 1 to 4 on Gentle, thirty-nine more change nothing,
  and forty new kinds take them to 17
- **To tune:** `experience.first_kill_multiplier` (2) and `assists_needed` (5) in
  `data/world_rules.json`. At 4 the first fight of a run jumped the lead to level 5 on Gentle;
  at 2 it lands near where the old per-kill rule did

### M13 — The fall — PLANNED

Waits on the first writing sitting, and on agenda items 6, 7 and 15.

- An intro that shows the sixteen falling ([19](19-asset-list.md), Tier 4.1)
- The first four of the sixteen written, with fixed god-style names and signature weapons
- The shared mark on every one of the sixteen
- Random crash sites per world, replacing fixed starting hearths
- The fifteen living their own lives: moving between places by temper, instead of standing in one area
- Regional name generation for everyone else, and earned titles from `Renown` ([D39](06-decisions.md)) ✅
  — built ahead of the rest of M13: `src/chronicle/names.gd`, `data/names.json`, `tests/names_smoke_test.tscn`
- ✅ Done when: a new game opens on the fall, lands the lead somewhere random, and one of the other
  fifteen can be met somewhere they walked to

### M14 — The Tower in chapters, and gates you cannot leave — IN PROGRESS

Chapters built 2026-09-25 (`src/chronicle/chapters.gd`) with every number in `data/world_rules.json` →
`tower`, so agenda item 1 (how many floors, how many to a chapter) changes a number, not the code.
Agenda item 2 (steps against chapters) is still open: steps drive the small clocks as before, and a
chapter's close moves them on further.

- Every Tower floor cleared returns the party to the world ✅ — each floor is one fight, and the party
  comes back out onto the map at the Tower's foot
- A chapter every five floors ✅: winning its last floor moves the world on (three upkeeps pass, and
  the weakest gates that were only brewing open — or a new rift tears if none are left), then the
  stair above is **sealed** until the company answers the world. **The reading taken:** shutting a
  gate or saving a town counts (`chapter_keys`). Items and quests as keys wait on the Guild
- The census at the end of every chapter ✅ — it always reads sixteen until there is more than one
  world (M15)
- Gates cannot be left until beaten ✅ (built 2026-09-24: once a floor is won, any step is the next
  floor, and it survives a save); objectives inside, some timed (agenda item 14)
- The Adventurers Guild in settlements, and S-rank gates that gather armies
- ✅ Done when: a run cannot climb past floor five without having done something in the world, and
  the world is visibly different after it ([D34](06-decisions.md), [D35](06-decisions.md)) — **met**
  for chapters: `walk_smoke_test --check=chapters`, and a soak that tops the Tower answers each seal
  by shutting the gates the chapter woke

### M15 — Sixteen worlds — PLANNED

Waits on M13, and on agenda items 4, 5 and 12.

- The lead's death ends the world: the overhead shot of it being destroyed, and the world marked
  gone for good
- Choosing the next lead from the survivors, in their own sibling world, from level 1
- Sibling worlds that tend to play out alike — same seed, perturbed
- The journal saved at death; the ghost met at a campfire, sharing it as temper and rapport allow
- The signature weapon crash-landing in the next world, and rumours that lead to it
- Nothing arrives before the new lead has got as far as the old one did
- A ruling on save/load against a world-ending death ([D21](06-decisions.md), `CO7`)
- ✅ Done when: a lead can die, the next can start in another world, and the first lead's ghost
  can tell the second where their weapon went ([D32](06-decisions.md), [D33](06-decisions.md))

### M16 — Companions on jobs — MOSTLY SHIPPED

Built 2026-09-24 on the errands the game already had (`src/chronicle/dispatch.gd`).

- A job log, filled from quests and rumours ✅ — the errand list is the job log. Rumours post jobs
  since 2026-09-25: when the host passes on the news, one that points at real trouble puts work on
  the board — a bounty on a survivor who got away, a look at a gate whose wards broke, arrows for a
  town under siege (`src/chronicle/rumour_jobs.gd`, wording in `data/errands.json` → `rumours`)
- Party members sent on jobs, travelling the map on the step clock, reporting back, sometimes
  dying ✅ — from the party screen's Practice page, one button per accepted errand. They leave the
  marching order, cover a tile a step out and back, may meet something on the road (more likely the
  closer it runs to an open gate), and a fight lost alone goes to `Fate` with nobody standing to
  pull them out. Look and deliver errands pay when they get there; fetches and hunts when they are
  back. A hunt teaches them the kind they hunted, under M12's rules
- The party cap growing from four to six — waits on agenda item 11
- Joining a gate raid — waits on M14's gates-with-armies
- ✅ Done when: a companion sent to join a gate raid comes back with a story, or does not come
  back ([D38](06-decisions.md)) — met for errands: `tests/dispatch_smoke_test.tscn`. Two hundred
  trips to open gates on Even: 179 back, 2 taken, 19 dead. On Gentle, which has no permadeath, all
  come back
- **To tune:** the `dispatch` block in `data/world_rules.json` — pace, how far a hunt goes, the
  trouble odds, and the chance of winning alone

### M17 — Past the top — DESIGN FIRST

- How the contest between the surviving leads is fought
- Who, or what, decided only one world survives, and how the last fight asks you to stop it
- ✅ Done when: there is a design doc both founders have signed off. Nothing is built before that

## Deferred

Designed for, seams in place, not built. See [Vision](01-vision.md).

- LLM character minds and an NPC society living off-screen
- The Masquerade
- A server as world-authority
- Generated tile art wired in from `art/map_kit`
- Lineage entries for the works named in joint session 1 ([16](16-lineage/00-index.md#named-in-joint-session-1--no-entry-yet))
