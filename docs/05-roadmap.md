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

**The First Hour comes first** ([D95](06-decisions.md), 2026-10-14). Until it plays end to end
(crater, the Tower's city, the Guild, the first rank-E gate, Tower floors 1 to 5, chapter one's
memory), nothing new is started, and the list below waits behind it. Order of work, one pull request
each, each ending playable:
1. The suites and the soak play one of the sixteen (Atlas) — built.
2. Quick fixes — built. While a box is open on the ground (the landing's words, a screen) the
   log, the hint line and tip cards wait for it to close; the walking hint goes once you have
   walked (the tutorial keeps it), and "red ground is being watched" is said once, by its tip;
   the crash site has no furniture; the apple sapling stands in the way like any young tree;
   loose stones are walked over; standing at the Tower's foot offers the climb instead of
   starting it (Auto still climbs); a region on water is not called grassland; the ground reads
   from mipmaps, so it no longer shimmers zoomed out.
3. M opens the map, a compass points at the objective, Auto walks there — built
   ([D96](06-decisions.md), confirmed).
3b. The cut list hidden in data, the opening's cast, and a compass that keeps to the lead's rank —
   built ([D97](06-decisions.md), design meeting 2). Coliseum, training ground, museum, trivia,
   grimoires, ferries, captivity, nemeses, dispatch and seasons are switched off in
   `data/world_rules.json` → `first_hour.hidden`; the wishlist keeps an "After the First Hour" list.
4. Fights where they are met, opening running — built ([D98](06-decisions.md)). A band met on the
   ground is fought on that ground with no change of screen; walking off the field's edge gets
   clear. Tuned since by [D113](06-decisions.md): about a level a fight.
5. The crater opening, the Tower's city and the Guild, to the first gate — built
   ([D101](06-decisions.md), design meeting 2's calls A to E). The first world's lead comes down 12
   to 16 tiles from Stormreach, which now stands at the Tower's foot (since [D247](06-decisions.md) a walled city
   on the land, two tiles by two, walked into by its south gate with no door, the Tower just past its north gate); Bram pulls them out, Sky is in
   Atlas's crater and carries him on the ground; the Guild keeps the Tower's door and nobody climbs
   until a gate is shut; the open rank E gate Greyhollow stands 8 tiles from the city in every world.
   The opening shows another lead's world ending. The Tower's foot is rock and flagstone and its shaft
   is drawn in house ([D158](06-decisions.md)) until its art is made (A9). Ewan walked the road by hand in about seven minutes (play-test 2).
6. Tower floors 1 to 5, walkable — built ([D102](06-decisions.md)). Each is its own ground
   (`data/areas/tower_floor_1` to `_5`) with bands watching it, fought where they are met and for
   real, and the stair up at the far end; standing on the stair wins the floor. Floor 5's stair is
   kept by a keeper (the Warden of the Fifth and two slimes, level 9, [D156](06-decisions.md), [D150](06-decisions.md)) who can kill an unready Atlas. Auto
   climbs them too ([D127](06-decisions.md), [D150](06-decisions.md)). Floors 6 up are still fought as one battle.
   Layouts and foes are **Inferred**, for `doug-md`'s play-test after this step.
7. Atlas's chapter-one memory — built ([D103](06-decisions.md)). A child's saddle buckle lies on
   floor 5 for Atlas alone; picking it up plays "Chapter one: The Weight" (meeting 2's working draft,
   **Inferred**) and writes it under _What has come back_ in the journal's Quests page and in the
   annals. Memories live in `data/memories.json`, one list per lead; the buckle is a stand-in prop
   until art request A10 is made. Cato, the quiz's most common second lead, has his own chapter one
   in the same alcove ([D135](06-decisions.md)): a bronze stylus, "Chapter one: The Last Line",
   **Inferred**, stand-in prop until art request A11. So do Janus, Bellona, Cassius, Saturn, Pluto,
   Ultor and Liber ([D138](06-decisions.md)), the leads with enough of the founders' material, and
   Ares, Caesar, Vesta, Iris, Ceres, Juno and Diana ([D151](06-decisions.md)), drafted from Will's
   inspiration volumes and rewritten by the creatives' meeting, so all sixteen have one. The opening's replay says what the fallen lead had just remembered, or
   that they never found out, and the other half of a tie hears one line for it
   ([D153](06-decisions.md)). The people on the route have their lines
   ([D154](06-decisions.md)): Old Halloran, the Guild's master, beside Sennet; Buri on blades falling
   from a clear sky; Bram's dead master in the crater; Barnaby at the gate's mouth. In Stormreach's
   streets Muck Muck, the builder everyone asks, and Sinner, a cleric who mends the company for gold
   ([D176](06-decisions.md), `doug-md`; their art is requests A26 and A27). **Planned**, after
   the First Hour (creatives' meeting C4): the training hall in Stormreach, Ultor's bandit company,
   the trap inn, Vane on the wall, and floor keepers given a why.
8. The gamers' week fixes — built ([D104](06-decisions.md) to [D110](06-decisions.md), Will's calls L
   to Q). A new player is Atlas (the quiz, four questions with sixteen ways through and one lead
   for each, waits for the next life) on the new **First Hour** setting,
   where a fall is for good; Gentle is now called Story. The death screen has Ascend selected and
   Reload one step along. Auto stops at the Guild at the Tower's door before the first gate, and the
   Guild's register opens there by itself; the Tower's door says how to climb; on a floor the compass
   points at a memory before the stair, and the buckle lies on the way to it. The Tower stands tall
   on its tile in wall stone, and is seen on the edge of the screen from the crater on, until art
   A9. Meeting 3 and Ewan's play-test 2 followed ([28](28-the-first-hour.md#how-it-was-tested)).
9. Meeting 4's fix batches ([D119](06-decisions.md), [D120](06-decisions.md)), one pull request
   each. Batch 1, the climb — built ([D115](06-decisions.md)): a floor's stair goes straight on to
   the next and only floor 5 sends the party out; a path to choose or a power to take no longer
   hides the Tower's door (Ewan's lock-out after floor 2); walking away from a gate between its
   floors walks out of it. `tests/climb_smoke_test` plays Atlas from the yard door up the floors,
   out to a gate and back, and through two packs fought one after the other. Batch 2 — built
   ([D116](06-decisions.md), [D121](06-decisions.md)): a gate is gone into with E beside it, never by
   walking onto it, and the cart, burnt wagon and toll rope are hidden in the First Hour. Batch 3 — built ([D122](06-decisions.md)): five boxes in the crater, a
   broken chest stays broken, a cache found on the land is a coin pile you walk to, companions are
   drawn following from the moment they join, Bellona and Iris head the library apart, a siege says
   where it is, the camp scene only at a hut, Sennet says what the register is and a shut gate says it
   counted, the far Tower sits on the horizon, and the soak names its longest frames. Next: Ewan plays
   to chapter one on batch 3's build. Auto now climbs a floor's stair instead of walking out
   ([D127](06-decisions.md)).
10. The in-house art studio ([D123](06-decisions.md)), one pull request each. The road — built
   ([D126](06-decisions.md)): a cobble road on the land from the crater through the great city and
   the first gate to the Tower. Biome edges — built ([D128](06-decisions.md)): two lands meet in a
   ragged band, not on the tile's straight edge. Tower floors — built ([D129](06-decisions.md)):
   flagstones, masonry walls and a runner instead of rock and grass. Scenery by rule — built
   ([D130](06-decisions.md)): trees in groves off the paths, bushes along them, flowers on the
   meadow. The wagon — built ([D131](06-decisions.md)): the roadside scenes are drawn and stand on
   the ground ahead when come upon, and are back in the First Hour. The Tower's stair and lit runes — built
   ([D132](06-decisions.md)): a flight of steps at the end of each floor and glowing glyphs on its walls. The Tower's yard —
   built ([D133](06-decisions.md)): plain sandstone paving and a kerb, the Tower on its own masonry. The crater — built
   ([D134](06-decisions.md)): a scorched floor in a ring of thrown-up earth, shards glinting in it. The city and
   the first gate — built ([D136](06-decisions.md)): paved in the yard's sandstone, the first gate's right up to its ring of stones ([D137](06-decisions.md)). The jungle and
   the barrow downs — built ([D140](06-decisions.md)): their own flat ground, pools and cover, drawn in house. The barrow gate — built
   ([D141](06-decisions.md)): a standing doorway of rune stones with the gate's light turning in it. The far Tower keeps out of
   the middle of the screen, where the way ahead is ([D142](06-decisions.md)).
   A gate's fight is fought where the party stands, at the gate, like a band's
   ([D162](06-decisions.md), five strangers' finding 7); since [D207](06-decisions.md) so is every
   fight in a run (Tower floors 6 up, roadside fights, towns defended or raided, captives taken back);
   only the training ground and the coliseum, both hidden, keep a screen of their own. A phone held upright is laid out tall, the ground
   filling it and text about 12 points ([D163](06-decisions.md), finding 6).
11. **Next** ([D124](06-decisions.md)): Ewan played the hour (play-test 3, 2026-10-15,
   [28](28-the-first-hour.md#how-it-was-tested)); its first fixes are built ([D178](06-decisions.md))
   and his bigger asks are listed, **planned**, waiting on his order
   ([28](28-the-first-hour.md#play-test-3s-asks)); the first he chose, life on the land, is built
   ([D179](06-decisions.md)). Play-test 4 (2026-10-17, a new game as Janus): its first fixes are built
   ([D189](06-decisions.md): a pin where you click, speeds 1×/2×/3×/5×, harder fought floors, the
   baker's bread, birds that fly about) and his new asks are listed, **planned**, waiting on his order
   ([28](28-the-first-hour.md#play-test-4s-asks)); the first he picked, the map over the ground, is
   built ([D232](06-decisions.md): a corner map, right-click Go here or Place a marker, the party
   walking on under it), and the party cards and the followers' facing are fixed ([D231](06-decisions.md),
   [D214](06-decisions.md)); of the roads and ways he picked footpaths and dirt
   tracks, built with signposts where three ways meet ([D233](06-decisions.md), art A32). Five real players, named by the
   founders, play a build from `e3ed512` on with the play log on (call AV, 2026-10-16); their logs and
   Ewan's notes are written up, then design meeting 5 with the newcomer's timed run. What only the
   founders can answer meanwhile, from when the hour is done to the music and Steam, is in
   [30](30-questions-for-the-founders.md) ([D164](06-decisions.md)). The First Hour as it plays, its
   play-tests and its builds: [28](28-the-first-hour.md).
12. The designers' fortnight's changes, one pull request each (`dougie`, 2026-10-15 23:04: "All
   recommended"). The Tower's bestiary and the names pass — built ([D143](06-decisions.md),
   [D144](06-decisions.md)): no copied slimes on floors 1 to 4, one new kind of foe a floor, no
   four-letter temper codes on screen, Barnaby off the road's bands. Life two — built
   ([D145](06-decisions.md)): the quiz deals only leads with a chapter one (since [D151](06-decisions.md) all sixteen have one,
   so it deals every lead), and a
   suite walks every way through it after Atlas's fall. Three wares at a market — built
   ([D146](06-decisions.md)). Two gates at the Guild — built ([D147](06-decisions.md)). A store-page draft and a
   devlog with each itch push — written ([D148](06-decisions.md), [29](29-the-store-page.md)). One of the other
   sixteen's lights going out at the hour's end — built ([D149](06-decisions.md)). Auto pausing for gates,
   the keeper and stronger bands, and picking up the keepsake before the stair — built ([D150](06-decisions.md)). After the city the compass points
   at Greyhollow, with Sennet's line — built ([D161](06-decisions.md), the five strangers' AU).
13. Gates as crossings between the worlds — built ([D152](06-decisions.md), `dougie`'s idea): as a gate
   shuts its light can open onto the same gate in another lead's world, with that lead in it, or
   their world burning if it has ended; the first gate of the first life always does. A word carried
   — built ([D183](06-decisions.md), from [D172](06-decisions.md)): what a lead says at a gate is heard
   by a later lead who shuts the same gate, and the first gate of a life carries the lead who fell
   last, or word of them. **Planned**: a hand in a gate fight, a lead met again in the contest past
   the top.
14. **The First Hour is done** (`dougie`, 2026-10-16, [D168](06-decisions.md)), answering the
   founders' questions ([30](30-questions-for-the-founders.md), D168 to D175, Ewan's D186; 25 to 32 Ewan's D217, Will's halves D212, D213, D228 to D230: 28 (50/50) and 32 (Early Access) agreed by both, 30 open until the team's price research, 31 asked again on 2026-10-31). The freeze lifts. Next,
   all **planned**: chapter twos and later arcs drafted from the material there is
   ([D173](06-decisions.md); all sixteen drafted, not in the game, [D182](06-decisions.md)); `doug-md`'s cues for the hour's music in place of the stand-ins
   ([D175](06-decisions.md)); the cut list back bit by bit where it fits the story; `doug-md`'s
   asks in his order ([D118](06-decisions.md)): first, the quest list — built ([D190](06-decisions.md)):
   the road, errands, captives and word of a weapon, L or a click on the compass to follow the next,
   Follow in the journal; next, coins in four metals. Further off: worlds sealed until their lead dies, then
   open to invasion, and the company entering other worlds from floor 30 ([D172](06-decisions.md));
   the word carried between the leads is built ([D183](06-decisions.md), item 13); the contest past floor 100 ([D171](06-decisions.md)). Steam, the
   store page and a native Android build wait ([D169](06-decisions.md)); call AV's five real players
   and meeting 5 wait for players. The Warden of the Fifth's voice — built ([D184](06-decisions.md),
   [D174](06-decisions.md)): as its fight begins it names the lead and counts which of the sixteen
   challengers they are, first to sixteenth and final (lines **Inferred**, agenda item 108). Its fight
   is left as it is until the Tower's bestiary rework ([D156](06-decisions.md)).
   The hour's music in the meantime — built ([D185](06-decisions.md)): five in-house themes made in
   code (`tools/make_music.py`) from the creatives' brief, played by place: the Tower floors, Stormreach,
   the crater, a chapter one's memory and the world's end; the road keeps Angelic and the fights Bday
   Project. Two more fight sounds (a fight opening, a ward) and the weak low ones given a mid-range
   knock, measured by `tools/audio_levels.py`. **Planned**: a layer added a floor up the Tower, and the
   opening's replay thinning as fewer are left (brief items 3 and 6).
   `doug-md` answered his half on 2026-10-16 ([D186](06-decisions.md)): the music order is in
   [31](31-music.md) (**planned**). The hour is a little harder on Ewan's word, `dougie`'s call AZ
   ([D188](06-decisions.md)). Still open: the falling weapon (agenda 101) and which lead will not climb (agenda 75).
15. **Atlas's last stand** — built ([D191](06-decisions.md), `doug-md`, 2026-10-17). A new player's
   first New Game is the tutorial, as Atlas, on the last day of his world: Hearthwick's lessons, then
   a band out of a broken gate he cannot beat. He falls for good, the quiz picks the first life of
   the player's own, and the opening plays whole with his world going dark. The first life is no
   longer Atlas ([D106](06-decisions.md) changed); the words, the band and the skip for someone who
   has played it before are **Inferred** (agenda 122), back to both founders.
16. **A move's effect is seen on whoever it lands on** — built ([D192](06-decisions.md), `dougie`,
   2026-10-17). Knockbacks slide the body back a tile or two, Undertow drags it in, slows frost the
   feet, burns and bleeds tick numbers, a knockdown lays the body flat, Sunder cracks the guard;
   a move shrugged off says so in silver (Pinned, Unmoved, Fireproof…), and a wind-up stepped out
   of says Dodged!. Which move carries what and every size are **Inferred** (agenda 123).
17. **Design meeting 5's order of work** ([D193](06-decisions.md) to [D200](06-decisions.md), 2026-10-17,
   chaired by the intern): the milestone picture redrawn (3 and 6 reached, 11 next); one game pull request
   at a time, in this order, all **planned**: (1) Auto walks on from the first gate to the Tower's yard
   door, one save per arrival at the city, a fall names its killer, and the soak plays a lead the quiz
   deals ([D197](06-decisions.md)); (2) stances on the fighter cards, Own way, Close in, Keep away, Guard,
   Hold ([D195](06-decisions.md), call BC; **built**, [D209](06-decisions.md)); (3) coins in four metals, `doug-md`'s next (**built**, [D253](06-decisions.md)); (4) **the Second
   Hour**: Tower floors 6 to 10 on their own floors, laid out from the chapter twos' rooms, each lead's
   chapter-two keepsake on its floor, a keeper on floor 10 ([D196](06-decisions.md); **built**,
   [D254](06-decisions.md)), then sixteen self-played runs to floor 10 (2 to 5 falls; **run**, 4 falls with random companions,
   [D258](06-decisions.md)); (5) `doug-md`'s play-test asks in his order (play-test 7, 2026-10-18, added fifteen, [28](28-the-first-hour.md#play-test-7s-asks); its
   first fixes built, [D259](06-decisions.md)). His play-test
   5 comes after (1) and (2), with a word on each in-house theme ([D198](06-decisions.md)); art on the
   credits' return in [D199](06-decisions.md)'s order; three new founders' questions in
   [30](30-questions-for-the-founders.md), 25 to 27 ([D200](06-decisions.md)). `dougie` took all four of the
   meeting's calls as recommended ([D201](06-decisions.md)): the itch push after (1) and (2), his
   play-tests standing in for the five players until the Second Hour, and he listens to the themes himself.

18. **How work moves** ([D202](06-decisions.md), 2026-10-17, `dougie`'s ask): the stages of making a game laid
   against this one, the loop every piece of work goes round, cost tiers, bug severities and the states
   of a milestone, in [32](32-the-pipeline.md). Milestones 12 to 17 are **planned**: the game at release on
   one page, the business basics ([30](30-questions-for-the-founders.md), questions 28 to 32), alpha, beta,
   launch and after launch. The inbox is built ([D205](06-decisions.md), call BH): GitHub issues, labels and
   milestones from `.github/plan.json`, a `plan` check on every PR, a daily sort and a status issue; `dougie`
   made the board and protected `main` from his checklist (2026-10-17). `dougie` then took the pipeline's three
   calls as recommended ([D208](06-decisions.md)): the Steam page after the Second Hour and A9 (BI), the
   business questions by voice note before it (BJ), the one-pager once the Second Hour is timed (BK). Every
   open item is now an issue on the board (#210 to #258); the Second Hour is #231 to #234, coins #235.
   `dougie` answered question 29 and his half of 28 on 2026-10-17 ([D212](06-decisions.md), [D213](06-decisions.md)):
   all profits 50/50 with `doug-md` (awaiting Ewan's word), PixelLab 22 euro a month paid by Will, credits
   back 27 October. Later that day ([D228](06-decisions.md) to [D230](06-decisions.md)): Early Access, aimed at
   January or February 2027; the split after Steam's cut and costs, the rest of the small print near payday;
   a one-off price with a free First Hour leaned to; on 2026-10-18 he took the price and platforms ([D255](06-decisions.md)):
   Steam Early Access at $15 to $20, the First Hour free on itch and as the demo, phones after 1.0 at $7 to $10.
19. **`doug-md`'s play-test 4 asks go first** ([D204](06-decisions.md), 2026-10-17): ahead of item 17's
   list, one pull request at a time. (a) **Fights in real time where they happen**: part one built, no
   stop before a fight on the ground (about a tenth of a second from being seen, was over a second)
   and no box round it; part two built ([D207](06-decisions.md), issue #205), no separate fight
   screens: Tower floors 6 up walked on a borrowed plan of floors 1 to 4 with their own foes (until
   the Second Hour's rooms), roadside fights where their scene stands, towns and captives just ahead.
   (b) **People on the land** — built ([D215](06-decisions.md), issue #206), all three together: the
   Watch beset on the roads round a town (join in and they fight beside you, then pay the Watch's
   bounty), six bands always camping near the First Hour's road (half of them brigands), and companies
   of climbers walking the road and resting on Tower floors ([28](28-the-first-hour.md#play-test-4s-asks), items 1 and 4).
   (c) **Three ways for Auto to walk** — built ([D216](06-decisions.md)): Aggressive, Mixed (the default)
   and Passive, picked in the menu; roadside scenes stand down the road, are told in the log and no
   longer stop Auto or open a box.
   Item 17's list follows.
20. **Auto reaches the Tower** — built ([D206](06-decisions.md), item 17's first, 2026-10-17). Auto walks on
   from the first gate to the Tower's door and stops there, goes in when switched on again, and after a
   chapter makes for the next gate; a town is saved once an arrival; a fall names its killer; the soak
   plays the lead the quiz deals from the seed. Found on the way: as a dealt lead, self-played runs fell
   before the Tower in 6 of 8, Atlas in none.
21. **Auto rests when hurt** — built ([D210](06-decisions.md), call BL, 2026-10-17). Under half its health a
   party walking itself goes to the nearest village, keep or hut to be patched up before fighting on. The
   early falls as dealt leads still happen, mostly at full health in the first road fights: issue #230.
22. **The road is fair to a lead walking alone** — built ([D211](06-decisions.md), call BM, 2026-10-17).
   Road bands stand two levels down and one smaller on the First Hour, the land's great beasts wait for
   level 3, Auto goes into a gate only when making for it, a lesser gate is kept by its floor's strongest,
   and walking wears a party down to half. Dealt leads no longer fall in their first fights; they still
   fall later, at levels 3 to 7, mostly fighting on at about half health: the rest of issue #230.
23. **Ewan's "what other games do well"** ([D223](06-decisions.md) to [D227](06-decisions.md), 2026-10-17,
   issue #270; questions 34 to 38 in [30](30-questions-for-the-founders.md)): twelve ideas kept, eleven cut,
   the list as he wrote it. **Planned**, big pieces first and always one being built, small ones alongside
   in other threads ([D226](06-decisions.md), loosening [D194](06-decisions.md)): the land journals (#284,
   **built**, [D239](06-decisions.md): a page for each land set foot in, up to five things to do there, and
   one of eighteen trinkets for finishing it, which walk faster, wade the shallows, slip past bands, keep
   a hazard off or fight harder), the world remembering (#286, **built**, [D249](06-decisions.md): the people you talk to bring up what you did once word of it has reached them, a place that has heard the worst turns you away until a coin or a word wins it round, a faction that keeps losing bands to you knows you on sight, and a later world's people have dreamt what an earlier lead did), companions whose arcs react
   (#283, **built** for all sixteen, [D250](06-decisions.md), [D256](06-decisions.md): a short arc of each one's own, told at the fire after their chapter one (after floor 5 for one walking with the lead), that ends by what the company did and who of the sixteen it met or lost; Bellona's first, the other fifteen in her shape on `dougie`'s word; bonds from before the descent learned as the game goes on, no romance played), a house in
   Stormreach (#285, **built**, [D252](06-decisions.md): Marta lets the Flagon's room two for good, then Steward Hobb sells a narrow house with a bed of your own and the strongbox) and the town at the crater (#258, **built**, [D251](06-decisions.md): once a gate is shut Muck Muck builds a smithy, an infirmary and then a wall there, each with its people, and settlers come), the second half harder as the Tower climbs and
   faster when the world is neglected (#287); with them the quick wins (#272 to #275: scars built,
   [D218](06-decisions.md); a gate keeper's prize built, [D219](06-decisions.md); treasure maps built, [D220](06-decisions.md); a band led to the Watch built, [D236](06-decisions.md)), stories inside gates (#288) and ground that changes the fight (#289).
24. **Sound in the browser, and New Game on a phone** — built ([D234](06-decisions.md), [D235](06-decisions.md), #292,
   2026-10-17, `dougie`'s report): the browser build was silent because its buses were made at runtime;
   they are in `default_bus_layout.tres` now. A player with a save is asked whether to play the last stand
   or skip it. Both went to itch in build `1daa322` (2026-10-17 17:39), the first build with sound;
   `dougie` listens to the five in-house themes on it and keeps or drops each (#218).
25. **`doug-md`'s later play-test fixes** — built (2026-10-17, his own PRs): the Tower's floors 6 up hit
   harder, 1.2 times from floor 6 and a little more each floor ([D222](06-decisions.md), #280); a question
   mark on each path at level 2 says what kind of fighter it makes ([D237](06-decisions.md), #254); a place
   on the ground comes into sight when it can be seen, not four tiles off ([D238](06-decisions.md), #253).
   The next itch push carries them, with the land journals (#284, PR #298) once they merge.
26. **Full screen on a phone** — built ([D240](06-decisions.md), #301, 2026-10-17, `dougie`'s report):
   itch's full-screen button turns a phone on its side, where the menu ran off both ends and a fight's
   buttons lay under the walking pad. The menu scrolls with Close always showing, and a fight's buttons
   take as many columns as fit above the pad. Reaches the phone with the next itch push. Held upright, the
   party screen and the journal now fit too: roster and list above, ribbons wrapping
   ([D241](06-decisions.md), #302).
27. **The play screen** (`doug-md`, 2026-10-17 and 2026-10-18): a small panel under the compass on the
   ground with the company's faces, levels and health bars and the purse — built ([D244](06-decisions.md));
   after RimWorld's play screen ([investigation/11](investigation/11-rimworld-play-screen.md)), what wants
   attention listed under it (someone badly hurt, nothing to mend with, one held, a town attacked, a path
   or power owed, an X on the map), each pressed to act on, and a mark on anyone owed a path or power —
   built ([D245](06-decisions.md)). **Planned** from the same look: letters for the world's big moments,
   an inspect card for anyone clicked on the ground, sums on hover for every number, speed keys on the
   ground.
28. **Play-test 6** (`doug-md`, 2026-10-17): the first fixes — built ([D246](06-decisions.md)): no black
   screen and no jumping at 5× (the camera smooths at its own pace), no fighters dancing side by side (a
   blow reaches the diagonals), one line of what can be done and a log that clears itself, a gate far
   above the company asks twice, climbers who join a fight and rest round a fire. **Planned**, waiting
   on his order: Stormreach walked outside (built, [D247](06-decisions.md)), fights inside a gate (built, item 29), Tower floors that grow, climbers with
   a part to play, hamlets and homesteads worth going to, paths and gates' ground that fit, carriages
   ([28](28-the-first-hour.md#play-test-6s-asks)).
29. **Fights inside gates** — built (`doug-md`, play-test 6, his first pick of its asks, [D248](06-decisions.md)):
   E at a gate opens its floor, chambers in rock from the doorway to the way down, a band in each, the
   keeper before the way down on the last floor; walked straight on down, walked back out of the
   doorway. Outside a gate, fights are a gate break's.
30. **Play-test 7** (`doug-md`, 2026-10-18): the first fixes — built ([D259](06-decisions.md)): the party no longer
   left behind after the wilds, a company on a Tower floor joins any fight there, the talk box and hint strip only as big as
   what they say, a cache drawn as what is in it (A37 for its own art), and the view shakes when a weapon lands. His
   fifteen bigger asks are in [28](28-the-first-hour.md#play-test-7s-asks), ordered by `dougie` ([D260](06-decisions.md)):
   **gates that grow** built ([D261](06-decisions.md): ground of their own, longer by rank, shut when all are down or
   the keeper falls, left broken with folk cheering; how long each rank takes in [28](28-the-first-hour.md#gates-that-grow)),
   then **five tiers of each monster**, the goblins', the wolves' and 24 more monsters' built ([D262](06-decisions.md), [D264](06-decisions.md)
   and [D267](06-decisions.md) to [D270](06-decisions.md): lesser, plain, high, hob, and a chieftain or a caster, dealt by the fight's level, each tier fighting its own way ([D275](06-decisions.md)) and each family with a trick of its own ([D276](06-decisions.md)); the named one-off monsters keep one kind); the climbers' stone (built, [D266](06-decisions.md)), Sennet seen from
   afar (built, [D265](06-decisions.md)), the journal at the side (built, [D271](06-decisions.md)) and Stormreach's frame rate as small pieces alongside (the frame rate
   built, [D263](06-decisions.md): ways on the land on one kept grid, a land's page opened without reading
   the map, and the play log says when the frame rate drops); and a writers' pass over every line
   (built, [D274](06-decisions.md), the rules in [13](13-heroes-and-tempers.md#the-lines)). After gates and tiers
   comes `dougie`'s list (BR9), one at a time: **recruiting anyone** built ([D277](06-decisions.md): a Charisma
   check, and a no won round by their favour or a few fights), sending your own people out built ([D278](06-decisions.md):
   a band to shut a gate on the odds, open once a gate is shut), moods built ([D279](06-decisions.md): thoughts that
   make a mood, which nudges a fight), crafting built ([D280](06-decisions.md): herbs mixed into draughts, a smith's
   edge on a weapon), caves built ([D282](06-decisions.md): a mouth on some hills, a gate-like floor behind it), then
   heights (**planned**).
31. **Fights on the ground are dangerous, and they turn** — built ([D272](06-decisions.md), call BQ, 2026-10-19,
   from the review "Is this game fun?"). A band of the land comes as many as the company and its blows get
   through armour; the first time one of the company is badly hurt, a fight played by hand asks stand, pull
   them back or break off for silver. The Tower and the gates are untouched. Next: Ewan plays it.
32. **Big gates pitched** — built ([D273](06-decisions.md), 2026-10-19): a B gate's bands stand 2 levels lower, an
   A or S gate's 4, climbing half a level a floor, and the gate clock's party carries gear for its level. The
   clock's party of four now shuts most B and S gates. Next: Ewan plays a B gate.
33. **The party keeps together** — built ([D281](06-decisions.md), 2026-10-19): companions come to a hurt
   lead, nobody falls back further than 3 tiles from the rest, and nobody hangs back from a foe already
   hitting them.
34. **Heals keep pace with health** — built ([D284](06-decisions.md), 2026-10-19): a mend heals 10% more
   for every level past 3 (2.4 times at level 17), as health grows; the first levels are as they were.
35. **Something on the road every few minutes** — built ([D286](06-decisions.md), 2026-10-19): the road keeps a
   clock, and every 6 to 9 steps there is a band ahead, a roadside scene, a traveller with a line or a find.
   Next: Ewan walks from the crater to the gate and says if it feels alive; then the First Hour's 14
   tutorial steps, as their own piece.
36. **The founders' meeting and design meeting six's work order** (2026-10-20, [D287](06-decisions.md) to
   [D299](06-decisions.md); questions 41 to 46 in [30](30-questions-for-the-founders.md)). **Planned**, one game
   pull request at a time, each ending playable:
   0. Push main to itch and `doug-md`'s play-test 8 on it, solo and as four, on `dougie`'s word.
      **Done**: `6f8fcf6` pushed 2026-10-21 10:06, played by `doug-md` the same morning; first fixes
      [D324](06-decisions.md), his eleven asks in [28](28-the-first-hour.md#play-test-8s-asks) in call BX's order ([D325](06-decisions.md)):
      disband, the quick wheel, the fallen reached first and a sent band's return time now, held until B is in
      (**built**, [D326](06-decisions.md));
      the 2× cap (**built**, [D329](06-decisions.md)), nemesis (**built**, [D330](06-decisions.md)) and hunger after B; the writers' pass, city doors, groves and the opening later.
      The opening's remake is settled in shape (call BZ, [D328](06-decisions.md)): 14 shots in three acts, the lead's
      chapter-one object falling with them, a demon king in a gate, Bram's "Give me your hand." at the end; built with the game's own sprites and a camera on every shot
      ([D340](06-decisions.md); art A58-A61 asked for after 27 October).
      The writers' pass on the Tower's people and the four stock lines is **built** ([D341](06-decisions.md)):
      the seven companies each in their own voice, more said on the shared and living floors.
      More of the city's doors are **built** ([D342](06-decisions.md)): six rooms in Stormreach with their own people.
   A. Ground fights running, with a first strike ([D288](06-decisions.md)); "Send away" from a button on each
      person, with a place to meet, a crow's word and the band seen on the land ([D294](06-decisions.md)); the
      story fixes (Liber's blurb, the foreman, one Wick, the fen's Iron Key); the tutorial cut to about 7 steps (#377).
      **Built** ([D300](06-decisions.md), 2026-10-20): Auto no longer stops for a band of the land, tips wait for
      a fight to end, G strikes first, a Send button on each card with a town to meet in and a crow, the band
      on the map, the four story fixes, and the last stand in 7 steps.
   B. Levelling in gates: levels only from new foes in a gate, experience in the Tower, a log of foes per
      character, and the numbers re-pitched by self-played runs ([D292](06-decisions.md), #378). **Built**
      ([D301](06-decisions.md), 2026-10-21): levels only from kinds first put down in a gate or cave, a log of foes
      with kinds to look out for, Auto hunting gates while the Tower outmatches it (floor 5's keeper and floors 6 up left as they were, to revisit),
      sixteen self-played runs in [28](28-the-first-hour.md). **Next**, and not
      yet started on main: C, D, E and F were built ahead of it on today's levelling (2026-10-20 and 21), so its
      sixteen runs also cover the demon kings, double gates, the Gate Key's gates, floors 11 to 20 with their
      shared floors, the living floor's rest, the sword in the yard and the toll for walking out of a fight.
      It goes in alone: nothing else merges into the game until its sixteen runs are green ([D323](06-decisions.md)).
   C. The land: caves (#371, [D282](06-decisions.md)), then heights, ledges, cliffs and ways up; places worth
      going to; creatures that match the land ([D287](06-decisions.md), #379). **Built in part**: caves ([D282](06-decisions.md));
      heights on the wind scarp, dropped off anywhere and climbed only at a slope, a drop of two hurting, the edges
      drawn ([D308](06-decisions.md), 2026-10-20); the wilds as places on the map, heard of at rest and marked, each
      with what it holds and a guard of the land's own creatures by its far chest ([D309](06-decisions.md), 2026-10-21). A board can post clearing a wild the party has heard of ([D310](06-decisions.md), 2026-10-21). Every way found on
      high ground (a click, Auto, a band, a person) goes round by a slope ([D312](06-decisions.md), 2026-10-21). A fight on
      high ground keeps to the slopes, and a body shoved off an edge falls, hurt and flat ([D313](06-decisions.md), 2026-10-21). Every wild
      tells a story in three pages stood on, written in the annals when the last is read ([D314](06-decisions.md), 2026-10-21). Walking
      into a wild whose guard stands takes its quest on the spot, for the nearest settlement known ([D316](06-decisions.md), 2026-10-21). A mountain with the
      clouds below: the cloud peak, three heights up, two on each world's crag; a body shoved into the clouds in a
      fight is gone ([D321](06-decisions.md), 2026-10-21). Rises on every tile of the land, a height up with a rock
      face, more on hills and crag, climbed only at a slope ([D332](06-decisions.md), 2026-10-21, held until B is in).
      Six hamlets on the map, three kinds (a sheepfold, a mill, salt pans), each with folk who sell, a job, a trouble
      and a story ([D333](06-decisions.md), 2026-10-21, held until B is in). Two caravans that go a round of four towns,
      one selling the makings of runes, one herbs and bread ([D334](06-decisions.md), 2026-10-21, held until B is in).
      Herbs on the land to pick, by what each land grows ([D335](06-decisions.md), 2026-10-21, held until B is in).
      Life on the land that matches it, no grasshopper in the ash ([D336](06-decisions.md), 2026-10-21, held until B is in;
      the lands' own creatures are art A56).
      Ladders that climb two heights, on the cloud peak and the scarp, and a Climbing Rope that scales any face a height up
      ([D337](06-decisions.md), 2026-10-21, held until B is in). Next: hills and mountains on the land more than a height
      up, town walls to scale.
      **The heights against the founders' ask** (2026-10-21, for [D323](06-decisions.md)): kept are the one-way
      ledge, the ways up, a drop that hurts, the clouds that kill, and a shove off an edge. Still short of it, and
      planned for C's rest: heights only stand in two kinds of wild place, so the land itself is still flat ("it's
      a 2D world at the minute") and every hill and crag land should get shelves on [D308](06-decisions.md)'s rules;
      a slope is the only way up, where `dougie` asked to "scale walls or scale these heights" (a ladder, a rope, a
      climb); an edge is a rim and a shadow, with no rock face to give it the 3D look (A49, A50); and being higher
      gives nothing in a fight (a blow or a shot from above).
   D. Gates alive: readings, double gates, demon kings of fallen worlds, instant gates from a key
      ([D293](06-decisions.md), #380). **Built**: readings and double gates ([D302](06-decisions.md), 2026-10-20);
      demon kings of fallen worlds and the Gate Key that tears a gate where it is turned ([D304](06-decisions.md),
      2026-10-20).
   E. Formations, a leader who rises, call-outs and a bonus for fights shared ([D289](06-decisions.md), #381).
      **Built** (2026-10-20): the five shapes, walked and fought in, picked on the party sheet, and the guard for
      holding one ([D305](06-decisions.md)); a leader who rises out of the fights won and calls for a shape, call-outs
      both sides hear, the bonus for fights shared, and a formation breaking on a low mood ([D306](06-decisions.md)).
      A band of foes falls in too, round its boss, in the shape its size picks, facing the party ([D315](06-decisions.md),
      2026-10-21), and on the ground a band of three or more walks in its shape too ([D320](06-decisions.md), 2026-10-21).
      Charisma in who leads, a tie-break that lifts someone up to two wins behind ([D323](06-decisions.md)): **built**
      ([D338](06-decisions.md), 2026-10-21, held until B is in). The leader's call-out is an order the company answers,
      and no trust in the leader breaks a formation ([D339](06-decisions.md), 2026-10-21, held until B is in). The wheel on
      a held key is play-test 8's quick wheel (#417). Not yet: plans made between fights, other orders (#411).
   F. The Tower past floor 10: bigger floors, shared floors, the first people living in it
      ([D290](06-decisions.md), #382). **Built** ([D307](06-decisions.md), 2026-10-20): from floor 11 every floor
      is laid out at the climb and grows with height, every third floor from 12 is shared with a company who
      fight beside the party, and from 25 every fifth floor has people living by the stair. A living floor rests the
      company for coin and sells bread, herbs and a draught, marked up ([D317](06-decisions.md), 2026-10-21). Not yet:
      the floors' 3D look, gear seen on the floor and on fighters (art). The grown floors stay; hand-laid floors
      with keepsakes and chapter threes come later as their own piece ([D323](06-decisions.md)).
   G. Your guild, companies of your own, the 32, a tavern and mercenaries, after the founders answer
      question 45 ([D294](06-decisions.md), [D295](06-decisions.md), #383; the questions #384). Built ahead of it
      ([D345](06-decisions.md), 2026-10-21): sellswords for coin off the Gilded Flagon's book, who go when the
      job is done, and the Flagon as where the roaming leads are met. The tavern on your own land and the
      four new people of the 32 wait on G and the writers.
   Also built, outside the order, from `doug-md`'s older asks: the sword in the Tower's yard, one pull a run
   ([D318](06-decisions.md), #249), and a fight you can walk out of, at a cost ([D319](06-decisions.md), #243), both
   2026-10-21. Crafting's next step, enchanting ([D299](06-decisions.md), item 3), after B and before C's rest
   ([D323](06-decisions.md)): **built** ([D327](06-decisions.md), 2026-10-21), four runes from charms and herbs laid on
   the weapon somebody carries, each a fight passive while they carry it. Not yet: runes on armour, an enchanter.
   Alongside: art from 27 October (road events that read, gear seen on the floor and on fighters, the Tower,
   heights: A49 to A54 in [24](24-art-requests.md)), the fallen weapon's cinematic ([D296](06-decisions.md); the fight for it is built: a band of the land
   may stand over the crater first, [D311](06-decisions.md), 2026-10-21), and a look at a small on-device model
   for fight plans ([D298](06-decisions.md), #385): **done** ([investigation 12](investigation/12-a-small-model-for-fight-plans.md));
   its plans fought no better than the rules in 200 party clashes, so no runtime goes in ([D322](06-decisions.md), 2026-10-21).

Updated 2026-10-13. Since 2026-10-12 the founders have settled the size, real-time fights and a
class per character ([D63](06-decisions.md), [D64](06-decisions.md)), the turn-based battle is gone
([D65](06-decisions.md)), and the early game's units play their moves in a fight. `dougie`'s
direction on 2026-10-13: get the early game playable before polishing art. Since 2026-09-26 every
pull request is checked by CI (the suites, a soak, and the ledger).

1. **The sixteen as the playable lineup — built.** `dougie`, 2026-10-13: the sixteen of
   [21](21-the-sixteen-first-draft.md) (Atlas to Liber) are the leads a run starts with, each in
   their own class ([D63](06-decisions.md)), and the original twelve (Bram, Sera, Toln and the rest)
   stop being leads and become significant NPCs in the main stories. Built 2026-10-13: the sixteen
   classes and starting moves ([M11](#m11--the-real-time-fight--in-progress), agenda item 68) and the
   sixteen as the leads, in their own bodies, the other fifteen settling where 21 puts them
   ([D78](06-decisions.md), agenda item 69), and the twelve placed in the world as story people,
   each where their backstory belongs with a conversation ([D79](06-decisions.md), agenda item 70).
   Each of the sixteen fights in their own way too: Atlas's bearer, Diana's wolf, Pluto's shades
   and the rest ([21](21-the-sixteen-first-draft.md#the-sixteen-signatures-as-built), agenda item 72).
   Still to write: their parts in the main stories, with the sixteen's quest lines.
2. **Walled towns and a great city — built** (2026-10-14, [D85](06-decisions.md), agenda item 74).
   `doug-md` asked for towns with walls, people at their jobs, a city big enough to walk round for a
   while, small quests and a tavern ([voice note](worldbuilding/voice-notes/2026-10-13-doug-md-cities.md)).
   Every village is walled on the land, its townsfolk walk rounds of work, and one village a world
   is a great city with the Gilded Flagon and five small quests. Planned: a second city (agenda 74
   asks which), and the lead who will not climb the Tower (agenda item 75, open).
3. **The early game's art, in the order a new player meets it.** Done (2026-10-13): the founders'
   bodies, the first foes and the rank-E gate bosses play walk, attack, skill, hit and death
   ([19](19-asset-list.md#tier-1--the-combat-prototype-after-the-reset), [W28](09-wishlist.md#w28--animations-wired-to-what-is-on-disk)).
   Next: the other level-1 faction foes, the twelve's bodies (now NPCs: idle and walk unless a story
   fight needs more), their companions and the village's walks; then the sixteen's fight sets. The
   fight effects and status icons are in the fight since 2026-10-13 ([D82](06-decisions.md)).
   Deferred by `dougie` (2026-10-13): redrawing the tide and flame lions' manes.
4. **The founders' agenda**: the [agenda](worldbuilding/answers.md#what-is-still-to-decide) holds
   what the build inferred while it went ahead, each with a recommended answer, and the
   [briefing sheet](worldbuilding/session-2-briefing.md) gives options and cost. Newest: the
   Amber Knight (65), the fight's sounds (66), the quieter level-up (67), the sixteen classes (68),
   the sixteen as leads (69), their signatures (72), the walls and the city (74), and the lead who
   will not climb (75). `doug-md` answered
   items 11, 12, 20 and 21 on 2026-10-12 ([D60](06-decisions.md)); item 15 (what a hearth is to
   someone who fell) still holds the writing for M13, and items 20 and 57 the end of the step clock (M18).
5. **First writing sitting for the sixteen** — names, seeds and fighting styles are drafted in
   [21](21-the-sixteen-first-draft.md) and built as the leads ([D78](06-decisions.md)); their
   memories, shared mark and own quest lines (M13) are not written.
6. **Tuning, whenever it annoys you:** `experience.first_kill_multiplier`, `assists_needed` and
   `healer_assists_needed`, the Tower's curve and cohorts (`world_rules.tower`), the
   `dispatch` odds, `data/sfx.json`, and `names.json` are all in `data/` and one number each.
7. **Before a public build**: the three fan-cover tracks swapped, the borrowed sprites redrawn, and
   PixelLab's terms checked ([Launch readiness](#launch-readiness--in-progress)).
8. **"Who wins?" clips — built** (2026-10-16, [D180](06-decisions.md), call AY). Two of the sixteen
   fight it out hands off, dressed as a show, and `tools/who_wins.py` records it wide and tall
   ([18](18-combat-direction.md#who-wins), [investigation 10](investigation/10-who-wins-shows.md)).
   Planned: the aim line and ground ring before a big move, words when a signature goes off, a cut to
   speed lines on the last blow, music under the clip once the in-house themes land, and a look at the
   leads who lose most one against one (Iris, Janus, Pluto; agenda item 112).
   **Party clashes and a guild war — built** (2026-10-18, [D257](06-decisions.md), #329): random
   parties of one to four, with gear, stances, draughts and words over their heads, and the Guild
   against the Heart Empire, as a table and as video (`tools/party_war.py`,
   [18](18-combat-direction.md#party-clashes)). Planned: a look at how much the company's side is worth
   (it decides two draws in five on its own), more wars under `wars`, and the clips tall for shorts.
9. **Fight tactics — built** (2026-10-17, [D187](06-decisions.md), call BB). Every fighter on every
   side fights to a doctrine: dodging wind-ups, keeping distance, flanking, guarding the hurt,
   hanging back to heal, breaking off when low, and choosing whom to hit
   ([18](18-combat-direction.md#tactics), [21](21-the-sixteen-first-draft.md#how-the-sixteen-fight-tactically)).
   Stances built 2026-10-17 ([D209](06-decisions.md)): each party card says how that fighter
   fights, Own way, Close in, Keep away, Guard or Hold, set by a click on the word or a key
   ([18](18-combat-direction.md#stances)). Planned next: the signatures' own moves (Janus swapping two units, Saturn pulling one in),
   and a look at Janus and Pluto, who still lose most one against one (agenda item 118).

Before any build goes to a playtest: `.\ek.ps1 test`, then one five-minute `tools/soak.tscn` run
([10](10-manual-tests.md#automated-tests)). Since 2026-09-26 CI runs every suite and a two-minute
soak on each pull request, so the five-minute soak is the only step left to do by hand. The seams audit on 2026-09-24 found six bugs no suite
was looking for, all now fixed and covered — see `tests/seams_smoke_test` and
[D42](06-decisions.md).

### M10 — Research and the size test — SHIPPED

- Deep dive into _Dungeon Settlers_' combat, written up in `docs/investigation/` against the
  questions in [18](18-combat-direction.md#what-the-research-has-to-answer) ✅:
  [investigation/07](investigation/07-dungeon-settlers-combat.md), from published sources, and
  `doug-md`'s answers to its ten questions after about twenty hours of play (2026-10-12)
- Sprite size test in PixelLab — 64, 32 and 16 side by side, four units on screen ([19](19-asset-list.md), Tier 0) ✅.
  **Prepared** 2026-09-25: instructions ([20](20-pixellab-size-test.md)), `tools/size_test.tscn`,
  the importer, `art/size_test/RESULTS.md`. **Generated** 2026-10-12 through the API
  (`tools/pixellab.py`), 34 generations; the base body dressed and animated for 30 more
- The size written into [06 — Decisions](06-decisions.md) ✅ — [D55](06-decisions.md): the 64 class
  on the base body, confirmed by `doug-md` ([D57](06-decisions.md)) and `dougie` ([D63](06-decisions.md))
- ✅ Done when: both founders have read the report, seen the sizes in the battle scene, and a
  D-entry says which size — **met** 2026-10-12 ([D63](06-decisions.md)). Still **Inferred**: the
  `body_scale` numbers for big units ([D57](06-decisions.md))

### M11 — The real-time fight — IN PROGRESS

Started 2026-09-24, on the first pass of M10, as a prototype beside the turn-based battle; since
2026-10-12 it is the only fight — see [18 — The fight](18-combat-direction.md#the-fight). What
is left is art: the moves of the units not yet drawn.

- A battle scene: real time, pause at any moment, speed up and slow down ✅ (`src/skirmish/`)
- Point-and-click movement on the existing grid; automatic basic attacks ✅
- Four active abilities per unit on Q W E R, with cooldowns ✅ and cast times ✅; a per-unit auto
  toggle ✅ and Wait for Orders ✅. Passives ✅ (2026-10-12, `data/skirmish.json`, **Inferred**
  per class — agenda item 45), shown on the cards and on hover
- Walk, attack, skill, hit and death played in the fight ✅ (2026-10-13, [W28](09-wishlist.md#w28--animations-wired-to-what-is-on-disk)):
  the founders' three bodies, the first foes, the early big units and the rank-E gate bosses, 28
  units in all, the Bog Jelly and the Amber Knight among them ([19](19-asset-list.md), Tier 1); the
  sixteen fight on their standing pose until their sets are drawn
- Fight effects and status icons ✅ (2026-10-13, [D82](06-decisions.md)): a slash, an arrow in
  flight, a burst, a heal and a shield block where a blow lands, a charge-up round a charged spell,
  and stun, charging, tired, draught and herb icons over the head (`effects` and `status_icons` in
  `data/skirmish.json`, **Inferred** — agenda item 71)
- Facing ✅ and generated battlefields ✅ carried over; falling becomes a near-death window a
  companion can reach ✅; when it runs out the fall is settled through `Fate.resolve`, as the
  turn-based battle settled it ✅ (a sandbox fight only rolls `Fate.roll` and writes nothing back;
  **Inferred** — agenda items 46 and 63)
- Enemy kinds that fight differently ✅ (2026-10-12): Charger, Skirmisher, Mender, by data
  (**Inferred**, item 45)
- Feel without art ✅ (2026-10-12): damage and critical numbers, hit flash, lunge, hit-stop, camera
  shake on deaths, cooldown sweeps on the skill tiles and touch buttons
- The fight is heard ✅ (2026-10-13, [D76](06-decisions.md)): fourteen sounds made in code, from the
  swing to the victory call, cued from `data/sfx.json`; how each sounds is **Inferred** (agenda item 66)
- A class of their own for each of the sixteen ✅ (2026-10-13, [D63](06-decisions.md)): four moves
  for level 1, a passive and growth each, in `data/classes.json` and `data/skirmish.json`
  ([21](21-the-sixteen-first-draft.md#the-sixteen-classes-as-built)); a lead starts in it and may
  switch at level 2. Every move and number is **Inferred** (agenda item 68)
- A signature each for the sixteen ✅ (2026-10-13, [21](21-the-sixteen-first-draft.md#the-sixteen-signatures-as-built)):
  Atlas carried by a bearer, Janus faster the worse the odds, Bellona's orders, Cassius learning
  who hits him, Saturn's heavy ground, Vesta's wards and her fire against the dead, Caesar taking
  the hit and getting back up once, Iris's marks, Pluto's shades, Ceres's planted ground, Cato set,
  Juno's doubled and thrown items, Ultor's one target, Diana's wolf, Ares's opener, Liber
  unstunnable (`signatures` in `data/skirmish.json`, `src/skirmish/skirmish_signatures.gd`), at no
  new art. Every rule and number is **Inferred** (agenda item 72), and Atlas's bearer is Sky
  ([D83](06-decisions.md)). Planned, not built: the parts no fight can do yet — moving people (Janus,
  Saturn's push and pull), a taunt, Bellona's orders as moves
- A headless smoke test that plays it out ✅ (`tests/skirmish_smoke_test.tscn`)
- Every fight the world starts ✅ (2026-10-12): bands on the road, gates and their objectives, the
  Tower, Guild musters and allies, the coliseum and training, all on scene key `skirmish`
- Touch controls ✅ (2026-09-25): tap to pick, tap to order, the keys as buttons down the right
- Auto-pause, off / on a fall / on a fall or a manual skill ready ✅; the J and P leans in real time ✅
- Drag a box to pick fighters ✅ (2026-10-12, [D58](06-decisions.md))
- From `doug-md`'s _Dungeon Settlers_ answers ✅ (2026-10-12, [D59](06-decisions.md), numbers
  **Inferred**): gentler facing, speeds 1×/1.5×/2×, stuns that break casts, charged spells, an
  energy bar, draughts and herbs mid-fight, shields that block
- Done when: both founders have played the prototype against the current battle and chosen.
  `doug-md` ✅ chose real time (2026-10-12, D58); `dougie` ✅ too (D63)
- Replace `TurnManager` ✅ (2026-10-12, [D64](06-decisions.md), [D65](06-decisions.md)): every
  fight the world starts is the real-time fight, with what the turn-based battle did on the way in
  and out carried over — the encounter, allies, ambush, confrontation, objectives, levelled foes,
  the journal, experience and assists, practice, wounds, the fallen through `Fate.resolve`,
  `battle_started` / `battle_finished` — and `battle.gd`, `turn_manager.gd`, the battle HUD,
  `EnemyBrain` and `battle_smoke_test` deleted. Training's choice between the two fights is gone

### M12 — Getting stronger the new way — SHIPPED

Built 2026-09-24, in the turn-based battle; since 2026-10-12 the real-time fight awards all of
it ([D65](06-decisions.md)). A sandbox fight awards nothing, unless it asks to (the coliseum's
waves do, for the copy of the company on the sand).

- Experience per character from the **first kill of each kind of enemy**; the last hit takes it ✅
  (`Progression.award_kill`)
- Assists counted per kind, and a kind's experience after ten, or five for a healer's ([D54](06-decisions.md),
  2026-10-01) ✅: a healer's assist is one where the helper healed the one who landed the blow in
  the same fight (`Skirmish._healed_by`), which is agenda item 23
- Bosses give everyone involved their experience ✅ — gate guardians and the Tower's apex fighter
  are flagged `"boss": true` in `encounter.gd`
- Proficiency per weapon kind (blade, bow, staff, bare hands) as well as per move, both rising by
  use and both adding to how hard a move hits ✅ (`Proficiency.arms_rank`)
- The party screen's Practice page shows weapon skill, the kinds each character has learned from,
  and the assists they are part-way through ✅
- Growth you can see ([D67](06-decisions.md), 2026-10-12) ✅: a level gained in play is a gold
  flicker on whoever gained it and a line at the top right that says so and what is owed (the
  banner it began as was in the way: [D77](06-decisions.md), 2026-10-13); a path chosen from cards in each
  class's colour; a tree of powers as a trail of stones, one click to take the next. Class colours
  are **Inferred** (agenda item 64)
- The journal is a book, found in the furrow at the landing, and its first page is a sheet for
  each companion: every number, what a level adds, what they carry and can do ✅ ([D67](06-decisions.md))
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
  area ✅ (2026-10-12, `src/chronicle/wanderers.gd`). Since 2026-10-13 they are the sixteen
  themselves, each settling where [21](21-the-sixteen-first-draft.md) puts them ([D78](06-decisions.md));
  the twelve stand-ins are story NPCs now (below). Heard of at inns and on
  rests, seen where they stand, met with **X** or inside the place, and joined if willing and there is room. Their own quest lines, not yet
- The original twelve as story people, not leads ([D79](06-decisions.md)): each standing in the place
  their backstory belongs to, with their companions and a conversation ✅ (2026-10-13,
  `data/story_npcs.json`; where and what is **Inferred**, agenda item 70). Their parts in the main
  stories (planned): written with the sixteen's quest lines
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
  comes back out onto the map at the Tower's foot. The walked floors 1 to 5 go straight on from one
  stair to the next floor, and only floor 5 sends the party out ([D115](06-decisions.md))
- A chapter every five floors ✅: winning its last floor moves the world on (three upkeeps pass, and
  the weakest gates that were only brewing open — or a new rift tears if none are left), then the
  stair above is **sealed** until the company answers the world. **The reading taken:** shutting a
  gate or saving a town counts (`chapter_keys`). Items and quests as keys wait on the Guild
- The census at the end of every chapter ✅ — since M15 a lead who died in an earlier world is
  counted out once this lead has climbed as high as they did
- Gates cannot be left until beaten ✅ (built 2026-09-24: once a floor is won, any step is the next
  floor, and it survives a save). Since [D115](06-decisions.md) a step away between floors walks
  out, the floors won kept, and E at it goes on with the next ([D116](06-decisions.md): a gate is
  entered with E, not by walking onto it); objectives inside ✅ (built 2026-10-01: rout, slay the keeper,
  reach the heart — [D45](06-decisions.md)); timed ones wait on playtest (agenda item 14)
- The Adventurers Guild in settlements ✅ (built 2026-10-01: a hall in every standing keep and
  village — the gate register and contracts that pay when a gate is shut, **Y** or the clerk), and
  S-rank gates that gather armies ✅ (a Guild muster that goes in beside the company, or alone —
  [D46](06-decisions.md))
- The Tower past floor 10 ✅ (2026-10-20, [D307](06-decisions.md)): from floor 11 every floor is laid out
  at the climb and grows with height, every third floor from 12 is shared with a company who fight beside
  the party, and from 25 every fifth has people living by the stair
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
  map short of spawns musters the rest on the nearest open ground (`BattleGrid.muster_cells`)
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
  continent is a look-only map opened from the journal. The party walking itself walks the ground
  too ✅ (2026-10-14, [D94](06-decisions.md))
- One world, the same every run ✅ (2026-10-14, [D91](06-decisions.md), [D92](06-decisions.md)):
  `doug-md`'s Map F frozen into `data/world_map.json` with the Tower in the middle; its lands and
  ground the same every run too; improved by hand from here ([27](27-the-world.md))
- Coins and prices (agenda item 60) ✅ (2026-10-18, [D253](06-decisions.md)): four coins, copper to
  platinum ([D177](06-decisions.md)), every price set again as [26](26-coins-and-prices.md) proposed
  ([D89](06-decisions.md), [D90](06-decisions.md)); `doug-md` still to check the numbers (agenda row 166)
- Planar areas that differ (agenda item 62) ✅ (2026-10-12, [D66](06-decisions.md)): eighteen lands
  ([investigation/09](investigation/09-lands-of-the-continent.md)), placed by the world's shape and
  reshaped round gates; every tile of open country its own ground, with ways out only where the land
  goes and landmarks now and then (`src/chronicle/biome.gd`, `src/area/ground_gen.gd`,
  `data/biomes.json`). Art for sixteen of the lands was a recoloured stand-in; since 2026-10-13 every
  land's trees, rocks and plants and the ground of eight (the blight, snow, dune, savanna, swamp,
  bog, taiga, badlands) are PixelLab's (`tools/pixellab_world.py`). The jungle's and the barrow downs'
  ground is drawn in house since 2026-10-15 ([D140](06-decisions.md)), and so is the ground of the other
  six (ash, blossom, slime, crystal, fungal, mist; [D157](06-decisions.md)): no land is a stand-in now
- Bands met on the ground ✅ (2026-10-12, [D66](06-decisions.md), [D68](06-decisions.md),
  [D72](06-decisions.md)): patrolling with the ground they watch painted red; step in (or be walked
  into view of) and they charge, the real-time fight opens on that same ground at the view it was
  seen in, and play comes back to the same spot. Sight and patrol numbers are **Inferred**
- One land ✅ (2026-10-13, [D84](06-decisions.md)): the continent walked as one stretch of ground,
  each tile's ground laid side by side with its neighbours and no edge or loading between them;
  villages, keeps, gates and the rest standing in their tiles and walked straight into; every band
  within two tiles on the land, patrolling its tile and walking across when it moves
  (`src/area/land.gd`). Where a place sits in its tile, how far bands are shown, how far they
  patrol and how fast they walk are **Inferred**. A straight line still shows where two lands meet
- Weather and hazards per land, enemies chosen by land, the Tower's element reshaping its country
  (planned; [investigation/09](investigation/09-lands-of-the-continent.md#not-built))
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
- The lands do something ✅ (2026-10-13, [D71](06-decisions.md)): their own enemies, slow ground,
  fog and shorter sight in mist and jungle, cold, heat and ooze worn off by the right gear; the
  strange lands rare. The numbers are **Inferred**
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
  the three fan covers (`peace_sign.mp3`, `crossing_field.mp3`, `unravel.mp3`) are out of every
  build since 2026-10-14 ([D100](06-decisions.md)), and `doug-md` makes the First Hour's missing cues;
  who made the two menu sounds (`angelic.wav` and `bday_project.wav` are by Ewan, who is `doug-md`,
  and cleared to ship, [D63](06-decisions.md), [D64](06-decisions.md), [D100](06-decisions.md)); where the items, props, buildings,
  holds, tilesets and menu frames came from; PixelLab's commercial terms for the plan used. These
  open items are the one part of this section that waits on the founders
- Saves survive updates and crashes ✅ (2026-10-12): an older save is upgraded step by step
  (`save_migrations.gd`) instead of wiped, a newer one is refused and left alone, and every save is
  written to a temporary file and renamed into place with the last one kept as a backup that a
  corrupt save falls back to (D56)
- New-player onboarding ✅ (2026-10-12): first-time tip cards (`data/tips.json`, once per player
  in `settings.cfg`, never during autoplay; _Tips: on/off_ and _Reset tips_ in the menu) and a
  _How to Play_ page from the title screen and the menu (`data/how_to_play.json`)
- A playable tutorial ✅ (2026-10-12, [D73](06-decisions.md)): offered the first time the game is
  opened and always on the title screen. A tour of Hearthwick, a training village, with a card that
  ticks off fifteen steps — walking, talking, asking, buying, a fox who will not talk, a favour, a
  chest, doors, the party screen, the journal and a sparring pair met on the village ground and
  fought there ([D75](06-decisions.md)) — then what a run holds
  and **Start a new run**. Nothing in it is ever saved (`GameState.rehearsing`). Offered once, as
  `doug-md` chose ([D74](06-decisions.md)); its words and order are **Inferred**. Since 2026-10-17 it
  is **Atlas's last stand** ([D191](06-decisions.md)): a new player's first New Game, ending in a
  fight Atlas cannot win and his fall, then the quiz and the opening
- Gamepad support ✅ (2026-10-12): Xbox and PlayStation pads play the whole game — menus by focus,
  a cursor for the fights, hint lines that name the pad's buttons, and pad rebinding in the
  system menu. The layout is in the README
- Code signing and notarization for Windows and macOS — planned; needs paid certificates
- An itch.io page for the browser build ✅ (2026-10-13, `dougie`'s, still a draft): pushed only on
  `dougie`'s word; every push and play-test build is listed in [28](28-the-first-hour.md#builds-on-itch-io)
- A Steam page with the First Hour as a free demo — planned, once the hour plays and the music is
  clean ([D100](06-decisions.md)); the founders come back to it later ([D169](06-decisions.md))

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
