# 05 — Roadmap

Shipping-first ordering: every milestone ends with something runnable. Nothing starts until the
previous milestone demonstrably works.

## M0 — Tactics core — SHIPPED

- Square grid, Dijkstra movement with per-tile cost and jump, charge-time turn order
- Abilities with min range, max range, splash, healing; facing bonuses (side 1.1×, back 1.2× since [D59](06-decisions.md))
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

Updated 2026-10-01, after joint session 2 settled the Tower's floors, steps, reloading, the living
copy, memory and assists (D48–D54), and the hundred-floor Tower and the two assist numbers were
built. **Everything left on this list needs one or both founders**: the build has gone as far as it
can without an answer.
Since 2026-09-26 every pull request is checked by CI (the suites, a soak, and the ledger).

1. **`dougie` confirms the size: the 64 class, every unit dressed onto the base body** ([D55](06-decisions.md)).
   `dougie` handed the call to Claude on 2026-10-12 ([D55](06-decisions.md)) and has not given his own
   answer yet. `doug-md` confirmed it on 2026-10-12 ([D57](06-decisions.md)), with big units drawn taller by a
   `body_scale` (built) and the base's look blended with the heroic 64s. Still **Inferred** and
   waiting on both founders' eyes: the `body_scale` numbers, and whether the blend reads (the first
   dressed unit with `BLEND_STYLE` has not been generated yet). The size test, the base body dressed
   as Bram and what each cost are in [`art/size_test/RESULTS.md`](../art/size_test/RESULTS.md); the
   viewer is `.\ek.ps1 sizetest`. Tier 1's eight units are generated and staged in
   [`art/tier1/`](../art/tier1/README.md), and the sixteen have a first look on the base
   ([21](21-the-sixteen-first-draft.md#what-they-could-look-like)).
   `dougie`, 2026-10-12: they go into the game together with the full redo, not eight at a time.
2. **`dougie` plays the real-time skirmish against the turn-based fight** (Training → Fight in real
   time). `doug-md` played both on 2026-10-12 and chose real time ([D58](06-decisions.md)): it flows
   better and asks for smarter choices; facing reads; he paused once, never needed auto-pause, and
   found fights a little quick but expects levels and abilities to lengthen them. His one ask, drag
   a box to pick fighters, is built. `dougie`'s turn decides whether M11 replaces the turn loop
   ([D36](06-decisions.md)).
3. ~~**An hour of _Dungeon Settlers_ itself**~~ Done 2026-10-12: `doug-md` has played about twenty
   hours and answered the ten questions ([investigation/07](investigation/07-dungeon-settlers-combat.md#doug-mds-answers-2026-10-12)).
   What they change in our fight is being settled with him.
4. **The second half of session 2**: the [agenda](worldbuilding/answers.md#what-is-still-to-decide),
   items 9–12 and 15, the four the build inferred before (16–19), and the five session 2 raised
   (20–24). The [briefing sheet](worldbuilding/session-2-briefing.md) gives each one its options and
   cost. Items 20 and 21 (the milestones that replace steps, and how far a walk is in one view)
   unblock M18. Item 12 (built meanwhile as "easy to find") settles the last of M15, item 15 the
   writing for M13; item 11 (party growth) was built on an inference on 2026-10-12, by Tower
   chapter, and waits as item 35. Item 3 (the research and the prototype) has gone as far as it can
   without play (steps 2 and 3); 13 is built; 14 is deferred to playtest. Items 25 to 29 are what
   M13's fall inferred on 2026-10-12: where the sixteen land, the stand-ins and their tempers, where
   each temper goes, how one joins, and how "Ascend to heaven" is shown. Items 50 to 56 are what
   M15's sixteen worlds inferred the same day: how alike the siblings are, where the earlier lead
   waits, when the ghost and the weapon arrive, where the weapon lands, the ghost at the fire, the
   stand-ins' weapons, and how a world's end is shown.
   **`doug-md` answered items 11, 12, 20 and 21 on 2026-10-12** ([D60](06-decisions.md), [transcript](worldbuilding/voice-notes/2026-10-12-doug-md-chat.md)):
   six in the party, the weapon lands anywhere (built), a living world whose deadlines can be
   missed, one view with the world as a map, and carriages. They wait on `doug-md`; item 10 is
   still open, and items 57 to 62 are new.
5. **First writing sitting for the sixteen** — the four NT tempers ([13](13-heroes-and-tempers.md#writing-one)),
   starting from the seeds the session left, with god-style names ([D39](06-decisions.md)).
   **A draft of all sixteen is ready to react to** ([21](21-the-sixteen-first-draft.md)); confirm or
   replace the NT four and they get built.
6. **Tuning, whenever it annoys you:** `experience.first_kill_multiplier`, `assists_needed` and
   `healer_assists_needed`, the Tower's curve and cohorts (`world_rules.tower`), the
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
  the importer, `art/size_test/RESULTS.md`. **Generated** 2026-10-12 through the API
  (`tools/pixellab.py`), 34 generations; the base body dressed and animated for 30 more
- ~~The size written into [06 — Decisions](06-decisions.md)~~ — [D55](06-decisions.md), 2026-10-12: the 64 class
  on the base body, **Inferred** until both founders confirm
- ✅ Done when: both founders have read the report, seen the sizes in the battle scene, and a
  D-entry says which size

### M11 — The real-time fight, as a prototype — IN PROGRESS

Started 2026-09-24, on the first pass of M10. A playable prototype exists — see
[18 — The prototype](18-combat-direction.md#the-prototype) — and the items below are marked
against it.

- A separate battle scene: real time, pause at any moment, speed up and slow down ✅ (`src/skirmish/`)
- Point-and-click movement on the existing grid; automatic basic attacks ✅
- Four active abilities per unit on Q W E R, with cooldowns ✅ and cast times ✅; a per-unit auto
  toggle ✅ and Wait for Orders ✅. Passives ✅ (2026-10-12, `data/skirmish.json`, **Inferred**
  per class — agenda item 45), shown on the cards and on hover
- Attack, hit and death animations for one party of four and three enemy kinds ([19](19-asset-list.md), Tier 1) — waits on art
- Facing ✅ and generated battlefields ✅ carried over; falling becomes a near-death window a
  companion can reach ✅; when it runs out the turn-based graces are rolled through `Fate.roll` ✅
  (2026-10-12, nothing written back, **Inferred** — agenda item 46)
- Enemy kinds that fight differently ✅ (2026-10-12): Charger, Skirmisher, Mender, by data
  (**Inferred**, item 45)
- Feel without art ✅ (2026-10-12): damage and critical numbers, hit flash, lunge, hit-stop, camera
  shake on deaths, cooldown sweeps on the skill tiles and touch buttons
- A headless smoke test that plays it out ✅ (`tests/skirmish_smoke_test.tscn`)
- Reachable from the Training ground and the bench ✅. A training fight only — nothing written back
- Touch controls ✅ (2026-09-25): tap to pick, tap to order, the keys as buttons down the right
- Auto-pause, off / on a fall / on a fall or a manual skill ready ✅; the J and P leans in real time ✅
- Drag a box to pick fighters ✅ (2026-10-12, [D58](06-decisions.md))
- From `doug-md`'s _Dungeon Settlers_ answers ✅ (2026-10-12, [D59](06-decisions.md), numbers
  **Inferred**): gentler facing, speeds 1×/1.5×/2×, stuns that break casts, charged spells, an
  energy bar, draughts and herbs mid-fight, shields that block
- Done when: both founders have played the prototype against the current battle and chosen.
  `doug-md` ✅ chose real time (2026-10-12, D58); `dougie` to come.
  Only then does it replace `TurnManager` ([D36](06-decisions.md))

### M12 — Getting stronger the new way — SHIPPED

Built 2026-09-24, in the turn-based battle. The real-time skirmish is training-only and awards
nothing yet.

- Experience per character from the **first kill of each kind of enemy**; the last hit takes it ✅
  (`Progression.award_kill`)
- Assists counted per kind, and a kind's experience after ten, or five for a healer's ([D54](06-decisions.md),
  2026-10-01) ✅: a healer's assist is one where the helper healed the one who landed the blow in
  the same fight (`Battle._healed_by`), which is agenda item 23
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
- **To tune:** `experience.first_kill_multiplier` (2), `assists_needed` (10) and
  `healer_assists_needed` (5) in
  `data/world_rules.json`. At 4 the first fight of a run jumped the lead to level 5 on Gentle;
  at 2 it lands near where the old per-kill rule did

### M13 — The fall — IN PROGRESS

Started 2026-10-12, on the founders' direction to build from the docs and infer where a question is
open. What was inferred is agenda items 25 to 29. The writing still waits on the first writing
sitting, and the reading of a hearth on agenda item 15.

- An intro that shows the sixteen falling ([19](19-asset-list.md), Tier 4.1) — waits on art. A
  landing beat in words plays on the first frame of every new run ✅ (`data/fall.json` → `landing`)
- The first four of the sixteen written, with fixed god-style names and signature weapons
- The shared mark on every one of the sixteen — spoken of when two meet; its form is not chosen
- Memories returned by the chapter, written per lead, and the whole story as a cinematic once every
  fragment is found ([D53](06-decisions.md))
- The standing quest every lead carries from landing: "Ascend to heaven" ([D53](06-decisions.md)) ✅
  (2026-10-12): in the journal's _Quests & the Fallen_ page with the Tower's floor and chapter, and
  ASCEND on the Tower. It never completes; that is item 22 and M17
- Random crash sites per world, replacing fixed starting hearths ✅ (2026-10-12,
  `src/chronicle/fall.gd`): drawn from the world seed and the lead, and the crater becomes Home
- The fifteen living their own lives: moving between places by temper, instead of standing in one
  area ✅ (2026-10-12, `src/chronicle/wanderers.gd`), with the twelve existing heroes standing in
  until the sixteen are written. Heard of at inns and on rests, seen where they stand, met with
  **X** or inside the place, and joined if willing and there is room. Their own quest lines, not yet
- Regional name generation for everyone else, and earned titles from `Renown` ([D39](06-decisions.md)) ✅
  — built ahead of the rest of M13: `src/chronicle/names.gd`, `data/names.json`, `tests/names_smoke_test.tscn`
- ✅ Done when: a new game opens on the fall, lands the lead somewhere random, and one of the other
  fifteen can be met somewhere they walked to — **met in words** 2026-10-12
  (`walk_smoke_test --check=fall`); the falling itself waits on the intro's art

### M14 — The Tower in chapters, and gates you cannot leave — IN PROGRESS

Chapters built 2026-09-25 (`src/chronicle/chapters.gd`) with every number in `data/world_rules.json` →
`tower`. Since 2026-10-01 the Tower is **a hundred floors in twenty chapters** ([D48](06-decisions.md)):
enemies rise about a level every three floors, four faction cohorts (`tower.cohorts`) hold the
floors in turn, the apex fight is on the hundredth, gold is paid by the chapter, and a book comes
every chapter and a skill tree every two. That shape is agenda item 24. Steps still drive the small
clocks, and a chapter's close moves them on further, until M18 replaces them ([D49](06-decisions.md)).

- Every Tower floor cleared returns the party to the world ✅ — each floor is one fight, and the party
  comes back out onto the map at the Tower's foot
- A chapter every five floors ✅: winning its last floor moves the world on (three upkeeps pass, and
  the weakest gates that were only brewing open — or a new rift tears if none are left), then the
  stair above is **sealed** until the company answers the world. **The reading taken:** shutting a
  gate or saving a town counts (`chapter_keys`). Items and quests as keys wait on the Guild
- The census at the end of every chapter ✅ — since M15 a lead who died in an earlier world is
  counted out once this lead has climbed as high as they did
- Gates cannot be left until beaten ✅ (built 2026-09-24: once a floor is won, any step is the next
  floor, and it survives a save); objectives inside ✅ (built 2026-10-01: rout, slay the keeper,
  reach the heart — [D45](06-decisions.md)); timed ones wait on playtest (agenda item 14)
- The Adventurers Guild in settlements ✅ (built 2026-10-01: a hall in every standing keep and
  village — the gate register and contracts that pay when a gate is shut, **Y** or the clerk), and
  S-rank gates that gather armies ✅ (a Guild muster that goes in beside the company, or alone —
  [D46](06-decisions.md))
- ✅ Done when: a run cannot climb past floor five without having done something in the world, and
  the world is visibly different after it ([D34](06-decisions.md), [D35](06-decisions.md)) — **met**
  for chapters: `walk_smoke_test --check=chapters`, and a soak that tops the Tower answers each seal
  by shutting the gates the chapter woke

### M15 — Sixteen worlds — IN PROGRESS

Built 2026-10-12 on M13's fall, with agenda item 12 taken as "easy to find" until it is answered.
Everything below marked ✅ that day is **Inferred**, agenda items 50 to 56; see
[17](17-the-sixteen-worlds.md#sixteen-worlds-as-built).

- The lead's death ends the world: the overhead shot of it being destroyed, and the world marked
  gone for good ✅ (drawn on the existing map: the camera rises while it burns out from the Tower;
  `src/world/world_end.gd`). The art for it waits on the intro
- Choosing the next lead from the survivors, in their own sibling world, from level 1 — the quiz
  asked again with every dead lead's answers removed, and the picker showing only the living
  ([D43](06-decisions.md)). Both halves are built: the quiz closes the dead's answers (2026-09-26),
  and since 2026-10-01 a lead who dies is recorded outside the save, passed to the quiz, and
  hidden from the picker ([D47](06-decisions.md)) ✅. The sibling world ✅ (2026-10-12)
- Sibling worlds that tend to play out alike — same seed, perturbed ✅ (`siblings.perturbation`)
- The journal saved at death; the ghost met at a campfire, sharing it as temper and rapport allow ✅
  in a simple form: the ghost sits at any fire, rapport is nights at the fire, and finding the
  weapon opens it fully. Meditating as an action of its own, not yet
- The signature weapon crash-landing in the next world, and rumours that lead to it ✅
- Nothing arrives before the new lead has got as far as the old one did ✅ (the old lead's level and
  Tower floor, both reached; the census counts them out from the same floor)
- The earlier lead alive in the next world as an NPC, from their stats and starting personality
  ([D52](06-decisions.md)) ✅
- Classic and Iron Man ([D51](06-decisions.md)), replacing free save/load ([D21](06-decisions.md)):
  Classic offers reload or ascend when the lead dies, and Iron Man ascends straight back to choosing.
  Under Classic the record of the fallen is written on ascending, not on the fall ✅ (built
  2026-10-12: the mode is picked on the quiz and the picker and kept in the save; Classic saves by
  hand and on setting out, resting and closing a chapter; Iron Man has no Save or Load and also
  saves on every return to the map and on leaving; the fall screen in `run_summary` —
  [02](02-design.md#when-the-lead-falls-classic-and-iron-man)). The save points are **Inferred**,
  agenda item 40. Left: quitting mid-fight in Iron Man still drops the fight unsettled
- ✅ Done when: a lead can die, the next can start in another world, and the first lead's ghost
  can tell the second where their weapon went ([D32](06-decisions.md), [D33](06-decisions.md)) —
  **met in words** 2026-10-12 (`walk_smoke_test --check=sixteen`); the founders' answers to items 12
  and 50 to 56 are what is left

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
- The party cap growing from four to six ✅ (built 2026-10-12, on an inference — agenda item 35):
  four seats to start, a fifth when Tower chapter 1 (floor 5) is cleared and a sixth at chapter 2
  (floor 10), all in `world_rules.party` (`src/chronicle/seats.gd`, `roster.seats`). A seat opening
  gets a banner, lines at the fire and a hint to hire; a companion back from a job with no room
  takes it first. Generated battlefields muster six, the two set-piece maps have six spawns, and a
  map short of spawns musters the rest on the nearest open ground (`BattleGrid.muster_cells`), in
  the turn-based fight and the real-time skirmish alike
- Joining a gate raid ✅ (2026-10-01): a companion sent to stand with a Guild muster waits with it
  and comes back paid, or rolls for their life if it lost
- ✅ Done when: a companion sent to join a gate raid comes back with a story, or does not come
  back ([D38](06-decisions.md)) — met for errands: `tests/dispatch_smoke_test.tscn`. Two hundred
  trips to open gates on Even: 179 back, 2 taken, 19 dead. On Gentle, which has no permadeath, all
  come back. **Met for gate raids** 2026-10-01: the same suite sends a companion to a muster that
  wins and to one that loses
- **To tune:** the `dispatch` block in `data/world_rules.json` — pace, how far a hunt goes, the
  trouble odds, and the chance of winning alone

### M17 — Past the top — DESIGN FIRST

- How the contest between the surviving leads is fought
- Who, or what, decided only one world survives, and how the last fight asks you to stop it
- ✅ Done when: there is a design doc both founders have signed off. Nothing is built before that

### M18 — One view, and no step clock — IN PROGRESS

Settled in joint session 2 ([D49](06-decisions.md), [D50](06-decisions.md)). The explored map is
built; the one view and the end of the step clock wait on agenda items 20 and 21.

- The game played in the planar view alone; the Z switch and the walkable continental view retired
  ✅ (2026-10-12, [D61](06-decisions.md)): every run and every return lands on the ground; an edge
  is a step on the continent, done out of sight; a place's doings are offered on the ground; the
  continent is a look-only map opened from the journal. Only the party walking itself (Q) still
  walks it
- Planar areas that differ (agenda item 62, planned): more layouts, exits that follow the land, places
  worth remembering — today every area has the same four exits
- Places worth walking round ✅ (2026-10-12, [D62](06-decisions.md)): every prop and building at its
  proper size (`data/props.json`), houses drawn from their art, woods, flowers, birds and bugs laid
  by `tools/dress_areas.py`, the wilds' ground reshaped into patches and ponds, furnished rooms,
  portals at the gates and a rune tower at the Tower, and people with questions, shops, favours and
  moods (`talk`). Sizes, names and the new people's words are **Inferred**
- Carriages (item 60, planned): pay to ride part of the way, with ambushes and other events on the road
- The continent as a map: black until the party has been there, filled in as it travels ✅
  (2026-10-12, `src/chronicle/atlas.gd`): four tiles seen round the party at every step,
  continental or planar, fading in; a place drawn only once known; saved as two bitfields
- Guild maps that mark some places and the general lie of the land ✅ (2026-10-12): bought once
  per hall; other maps hidden in the world ✅ — in chests, caches and spoils; and places named by
  news, contracts and errands marked. The numbers and the reading of item 21's second half are
  **Inferred** (agenda items 30 to 33)
- The step clock retired. The world moves on at milestones: Tower chapters and the checkpoints item
  20 names. `doug-md` answered on 2026-10-12; the proposal from it — days spent by resting and
  travelling, conditions, deadlines whose misses are stories — is
  [investigation/08](investigation/08-quests-and-a-living-world.md), **Inferred** (item 57). Every system priced in steps re-priced or dropped: doctrine fading, gates breaking,
  captive and thread deadlines, seasons, companions' travel on jobs
- ✅ Done when: a run can be played from landing to a Tower chapter without the world view, nothing
  in the world changes because the party walked, and the map shows only where the party has been or
  been told of

## Launch readiness — IN PROGRESS

Work that gets the build into players' hands. Almost none of it waits on a founder answer.

- Playable builds for Windows, Linux, macOS and the browser ✅ (2026-10-12): `export_presets.cfg`
  and the `release` workflow — run by hand for a test build, or tag `v*` for a GitHub pre-release.
  The version on the title screen is `application/config/version`, set from the tag
- Fullscreen and a sound-effects volume in the system menu ✅ (2026-10-12): both kept in
  `settings.cfg`; `F11` switches fullscreen anywhere
- The browser build loads and plays ✅ (2026-10-12): `tools/web_smoke.py` exports it and plays it
  in headless Chromium — cinematic, New Game, quiz, a life, steps on the map, Save Game, reload,
  Continue — with no console errors. 56 MB to download (`index.wasm` 39.5 MB, about 10 MB
  gzipped; `index.pck` 16.7 MB, mostly the music); from a local server the cinematic is up in
  about 2.5 s and a new world in about 4.5 s. Saves and settings persist through IndexedDB,
  sound starts on the first click or key, fullscreen works from the menu and `F11`. Quit is left
  off the title and the run summary in the browser (it only froze the page). The symbols the
  built-in font lacked are swapped for ones it has, and the character list scrolls at 1280×720.
  Known issue: the host must serve gzip or the first load is the full 56 MB
- Credits screen ✅ (2026-10-12): off the title and the system menu, read from `data/credits.json` —
  the founders, Godot's MIT notice word for word, its third-party components, music, sound, art,
  fonts and tools
- Asset provenance audit — first pass done 2026-10-12 ([22](22-asset-provenance.md)); open items:
  **`peace_sign.mp3`, `crossing_field.mp3` and `unravel.mp3` are fan covers of commercial songs,
  dev only — they must be swapped for original or licensed tracks before any public release**; who
  made `angelic.wav`, `bday_project.wav` and the two menu sounds; where the items, props, buildings,
  holds, tilesets and menu frames came from; PixelLab's commercial terms for the plan used. These
  open items are the one part of this section that waits on the founders
- Saves survive updates and crashes ✅ (2026-10-12): an older save is upgraded step by step
  (`save_migrations.gd`) instead of wiped, a newer one is refused and left alone, and every save is
  written to a temporary file and renamed into place with the last one kept as a backup that a
  corrupt save falls back to (D56)
- New-player onboarding ✅ (2026-10-12): first-time tip cards (`data/tips.json`, once per player
  in `settings.cfg`, never during autoplay; _Tips: on/off_ and _Reset tips_ in the menu) and a
  _How to Play_ page from the title screen and the menu (`data/how_to_play.json`)
- A playable tutorial ✅ (2026-10-12, [D63](06-decisions.md)): offered the first time the game is
  opened and always on the title screen. A tour of Hearthwick, a training village, with a card that
  ticks off fifteen steps — walking, talking, asking, buying, a fox who will not talk, a favour, a
  chest, doors, the party screen, the journal and a real-time sparring fight — then what a run holds
  and **Start a new run**. Nothing in it is ever saved (`GameState.rehearsing`). Its words and order
  are **Inferred**
- Gamepad support ✅ (2026-10-12): Xbox and PlayStation pads play the whole game — menus by focus,
  a cursor for the fights, hint lines that name the pad's buttons, and pad rebinding in the
  system menu. The layout is in the README
- Code signing and notarization for Windows and macOS — planned; needs paid certificates
- A store page (itch.io or Steam) — planned; the founders' call

## Deferred

Designed for, seams in place, not built. See [Vision](01-vision.md).

- A guild you command, with its own adventuring party sent out on objectives (agenda item 59,
  `doug-md` 2026-10-12)
- Foes who survive you remember you, marked or hardened by what you did (item 61, `doug-md` 2026-10-12)
- The fallen weapon shown: a cinematic of its fall, the ground marked by what it is, and a monster
  that picks it up fighting at 30% of it (item 58, `doug-md` 2026-10-12)
- LLM character minds and an NPC society living off-screen
- The Masquerade
- A server as world-authority
- Generated tile art wired in from `art/map_kit`
- Lineage entries for the works named in joint session 1 ([16](16-lineage/00-index.md#named-in-joint-session-1--no-entry-yet))
