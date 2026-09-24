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
  you took and losing gives them back ✅
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

1. **By 2026-09-27 — spend the last 15% of PixelLab credits on the size test.** [19 — Asset list](19-asset-list.md), Tier 0.
   Nothing else is worth generating until the size is chosen.
2. **Next founders' session** — answer agenda items 1–4 and 9: the Tower's floor count, steps
   against Tower chapters, whether a world-ending death can be reloaded, and the sprite size. Each
   is a sentence, and each unblocks a milestone below.
3. **The Dungeon Settlers deep dive** (M10). It gates the whole of M11.
4. **First writing sitting for the sixteen** — the four NT tempers ([13](13-heroes-and-tempers.md#writing-one)),
   starting from the seeds the session left, with god-style names ([D39](06-decisions.md)).
5. **M12 can start straight away.** First-kill experience and proficiency by use sit in
   `chronicle/`, not `battle/`, and work under either fight.

### M10 — Research and the size test — NEXT

- Deep dive into _Dungeon Settlers_' combat, written up in `docs/investigation/` against the
  questions in [18](18-combat-direction.md#what-the-research-has-to-answer) — **first pass done**:
  [investigation/07](investigation/07-dungeon-settlers-combat.md), from published sources. Still to
  do: an hour of hands-on play to answer the ten questions it lists at the end
- Sprite size test in PixelLab — 64, 32 and 16 side by side, four units on screen ([19](19-asset-list.md), Tier 0)
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
- Regional name generation for everyone else, and earned titles from `Renown` ([D39](06-decisions.md))
- ✅ Done when: a new game opens on the fall, lands the lead somewhere random, and one of the other
  fifteen can be met somewhere they walked to

### M14 — The Tower in chapters, and gates you cannot leave — PLANNED

Waits on agenda items 1 and 2.

- Every Tower floor cleared returns the party to the world
- A chapter every five floors: the world's story advances, and the next chapter needs a key from
  the world (a gate cleared, an item, a quest)
- The census every five floors — how many of the sixteen are alive
- Gates cannot be left until beaten; objectives inside, some timed (agenda item 14)
- The Adventurers Guild in settlements, and S-rank gates that gather armies
- ✅ Done when: a run cannot climb past floor five without having done something in the world, and
  the world is visibly different after it ([D34](06-decisions.md), [D35](06-decisions.md))

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

### M16 — Companions on jobs — PLANNED

- A job log, filled from quests and rumours
- Party members sent on jobs, travelling the map in real time, reporting back, sometimes dying
- The party cap growing from four to six (agenda item 11)
- ✅ Done when: a companion sent to join a gate raid comes back with a story, or does not come
  back ([D38](06-decisions.md))

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
