# 28 — The First Hour

**What a new player plays today, start to finish, and how it got that way.** The First Hour was the
only milestone until it was done ([D95](06-decisions.md)); `dougie` called it done on 2026-10-16
([D168](06-decisions.md)). What else is built stays hidden behind `data/world_rules.json` →
`first_hour.hidden` ([D97](06-decisions.md)) until each system fits back into the world and the story. The order of work and what
is next is in the [roadmap](05-roadmap.md#next-steps-in-order); this doc describes what exists.

## The route

1. **New Game.** No quiz on the first life: the lead is Atlas (`first_hour.first_life`), on the
   **First Hour** setting, where a fall is for good ([D104](06-decisions.md), [D106](06-decisions.md)).
   The opening plays ([25](25-the-opening.md)).
2. **The crater.** Atlas comes down with Sky in a scorched crater ([D134](06-decisions.md)) 12 to 16
   tiles from Stormreach ([D101](06-decisions.md)). Bram pulls him out. Five boxes, then he walks
   ([D122](06-decisions.md)).
3. **The road.** A cobble road runs from the crater to the great city, on to the first gate and back
   to the Tower ([D126](06-decisions.md)). The compass and Auto point the way: town, then the first gate,
   then the Tower ([D96](06-decisions.md), [D161](06-decisions.md)); walking into the city, Sennet says the
   Guild's mark is earned at a gate and names it.
   Bands met on the land are fought on that ground with no change of screen ([D98](06-decisions.md));
   on the road itself they are brigands, poachers, cabin hands and cutpurses ([D144](06-decisions.md)).
   Lands blend where they meet ([D128](06-decisions.md)); the jungle and the barrow downs on the way
   have their own ground, drawn in house ([D140](06-decisions.md)), as do the six other lands
   ([D157](06-decisions.md)); scenery stands by rule
   ([D130](06-decisions.md)), and the roadside scenes stand on the road ([D131](06-decisions.md)).
4. **Stormreach and the Guild.** The great city stands at the Tower's foot, paved in sandstone
   ([D136](06-decisions.md)). The first time the party stands at the Tower's door the Guild's register
   opens by itself; Sennet keeps it ([D107](06-decisions.md), [D112](06-decisions.md)), and Old Halloran,
   the Guild's master, stands beside him and can mark a lead too ([D154](06-decisions.md)). Nobody climbs
   until a gate is shut ([D101](06-decisions.md)). A market lays out three wares: Z turns to the next,
   B buys the one in hand ([D146](06-decisions.md)). In the streets, Muck Muck the builder stands by
   the ruined bathhouse, and Sinner, a cleric, mends the whole company for 40 gold at the old shrine
   ([D176](06-decisions.md)).
5. **The first gate.** Two are offered, both rank E and open in every world: Greyhollow, eight tiles
   south of the city at the road's end, and Elderford, nine tiles north ([D147](06-decisions.md)). E
   beside one goes in; walking onto it does not ([D116](06-decisions.md)). Its fight is fought there on
   the plaza, its keepers coming out of the doorway, with no fight screen ([D162](06-decisions.md)). Its plaza runs up to its gate, a
   standing doorway of rune stones with the gate's light turning in it ([D137](06-decisions.md),
   [D141](06-decisions.md)). Shutting it gives the Guild's mark. As it shuts, its light opens onto the
   same gate in another lead's world, and that lead, the original, is standing in it shutting their
   side: one line from them, and the light closes ([D152](06-decisions.md), [below](#the-crossing)).
6. **The Tower.** A door drawn in house with lit rune stones up the yard ([D111](06-decisions.md)), a
   the huge Tower's round, rune-banded shaft over it, drawn in house
   until art A9 ([D158](06-decisions.md)), seen from far off beside the way ahead
   rather than over it ([D142](06-decisions.md)), the yard paved plainly
   ([D133](06-decisions.md)). "E to climb" at the door.
7. **Floors 1 to 5**, each walked ([D102](06-decisions.md)) and each its own shape: a pillared hall,
   a ring round a core, a split floor, zigzag terraces, the keeper's room ([D114](06-decisions.md)),
   dressed as a tower with a stair and lit runes ([D129](06-decisions.md), [D132](06-decisions.md)). Each floor brings a kind of foe not met on the one before, and floors 1 to 4 carry none of the
   sprites docs/22 marks dev only ([D143](06-decisions.md)).
   E at the stair goes straight to the next floor; only floor 5, its keeper beaten, brings the party
   back out to the yard ([D115](06-decisions.md)). Auto climbs too ([D127](06-decisions.md)), picking up the
   lead's keepsake before the stair, and hands over paused any fight that matters: a gate's, the
   keeper's, or a band more than a level over the lead ([D150](06-decisions.md)). Floor 5
   is kept by the Warden of the Fifth, an armoured figure with a glaive whose big swing shows before
   it lands, drawn in house ([D156](06-decisions.md)). As its fight begins it speaks once, in the
   conversation box, naming the lead and counting the challengers across the run of worlds: the
   first life hears "The first challenger arrives", the next after a death "The second challenger
   approaches", up to "the sixteenth and final challenger" ([D184](06-decisions.md), lines in
   `first_hour.warden`, **Inferred**, agenda 108).
8. **Chapter one.** In floor 5's west alcove, before the keeper, lies the lead's own keepsake
   ([below](#the-chapter-ones)). Picking it up plays their chapter one and writes it in the journal
   ([D103](06-decisions.md)). Beating the keeper costs somebody: one of the other sixteen's lights in
   the Tower goes out, by name, and the census reads fifteen ([D149](06-decisions.md)).
9. **A death.** The world remembers which gate its lead shut, and in the next crater Bram has
   dreamt of them ([D147](06-decisions.md)). The death screen has Ascend selected ([D105](06-decisions.md)); the world ends, the
   quiz picks the next of the sixteen ([D110](06-decisions.md), naming tempers, not their letters, [D144](06-decisions.md)); while some leads have no
   chapter one yet, it deals only those who do ([D145](06-decisions.md)), and the opening plays again for who is
   left, story shots only ([D135](06-decisions.md)).

**How hard.** The First Hour setting sits just easier than Even, a little harder since
[D188](06-decisions.md) (foes hit for 0.85 with 0.9 of their health; the party at 1.3 health and 1.2
attack): foes two levels down, half healed
after a fight, about a level a fight, the bands on the Tower's floors at the level written for them (the setting's
two levels off is not applied there), so the floor 5 keeper stands at level 9 ([D113](06-decisions.md), kept
by [D117](06-decisions.md), corrected by [D150](06-decisions.md)). **Saves**: on walking into a town or the city, opening the register,
shutting a gate, as well as setting out and resting ([D112](06-decisions.md)). **The play log**:
Copy or Save play log in the system menu hands a tester's run over ([D125](06-decisions.md)).

## The chapter ones

All sixteen lie at [2, 11] on `tower_floor_5` (`data/memories.json`); only the lead finds their own.
Each answers Bram in the crater in their own words (`unless` in `data/fall.json`). Every word is
**Inferred**, a working draft for the founders (agenda item 82, [D151](06-decisions.md)). The keepsakes are drawn as the coin
pile until their art requests are made ([24](24-art-requests.md)).

| Lead | Chapter one | Keepsake | Art | Decision |
| --- | --- | --- | --- | --- |
| Atlas | The Weight | a child's saddle buckle | A10 | [D103](06-decisions.md) |
| Cato | The Last Line | a bronze stylus | A11 | [D135](06-decisions.md) |
| Janus | The Shut Door | an iron hinge pin | A12 | [D138](06-decisions.md) |
| Bellona | The Order | a dented bronze whistle | A13 | [D138](06-decisions.md) |
| Cassius | The Mask | a cracked festival mask | A14 | [D138](06-decisions.md) |
| Saturn | The Mended Bowl | a mended clay bowl | A15 | [D138](06-decisions.md) |
| Pluto | The Tally | a notched tally stick | A16 | [D138](06-decisions.md) |
| Ultor | The Wrong Side | a knife hilt with no blade | A17 | [D138](06-decisions.md) |
| Liber | The Cut Rope | a cut length of rope | A18 | [D138](06-decisions.md) |
| Ares | The One He Let Go | a child's wooden sword | A19 | [D151](06-decisions.md) |
| Caesar | The Hero's Part | a child's tin crown | A20 | [D151](06-decisions.md) |
| Vesta | The One Who Stayed | a small clay lamp | A21 | [D151](06-decisions.md) |
| Iris | The Pass | a stitched leather ball | A22 | [D151](06-decisions.md) |
| Ceres | The Last Sheaf | a corn dolly | A23 | [D151](06-decisions.md) |
| Juno | The Last Plate | a burnt wooden spoon | A24 | [D151](06-decisions.md) |
| Diana | The Collar | a wolf's leather collar | A25 | [D151](06-decisions.md) |

### How a chapter one is written

The rule the creatives' meeting set (C1, [D151](06-decisions.md)), for any rewrite or chapter two:

- Ten boxes including the journal page (Atlas keeps nine): the keepsake found, the floor going out
  from under the world, a scene before the fall, a voice, "White.", and one thing the lead did not
  know before.
- Exactly three shared lines: box 2 ends "and the floor goes out from under the world"; one box ends
  "The face will not come"; "White." stands alone on its own box. Everything else is the lead's own.
- No two chapters share box 3's first words, and at most eight of the sixteen turn on a door or gate.
- Ties between leads are never named in chapter one. Each pair shares one thing a player who lived both
  lives will catch: the whistle (Bellona, Ultor), the cracked mask (Cassius, Caesar), the cut rope and
  the wooden sword (Ares, Liber). Chapter two names them (**planned**).
- Each voice behind a blank face is that lead's own person, not one hidden hand (call AI).

A new chapter one is a `memories.json` entry, a line in `fall.json` (and its name added to the shared
last line's `unless`), and an art request. The quiz deals only leads who have a chapter one ([D145](06-decisions.md)); with all
sixteen written, it deals every lead again.

## The crossing

A gate is a seam between the sixteen worlds ([D152](06-decisions.md), `dougie`, 2026-10-15). As any
gate shuts, `data/crossings.json` rolls once, fixed by the world's seed and the gate:

- **Who.** One of the sixteen who is not the lead and not walking with them, Janus and Pluto (who go
  to gates by temper) three times as likely. Alive, they are the original in their own world, not the
  copy who walks this one, and say one line in their own voice. If their world has ended, the gate
  shows it burning with nobody in it.
- **How often.** The first gate of the player's first life always opens (in the First Hour, Greyhollow
  for Atlas; `dougie` confirmed it, [D165](06-decisions.md)); after that a rank E gate about one time in four, more for higher ranks.
- **What it leaves.** A line in the journal and the annals, and `crossed:<lead>` in the run's flags.
- **A word carries** ([D183](06-decisions.md), from [D172](06-decisions.md)). Every gate a lead shuts,
  they say one line into it (`carried.left`, one for each of the sixteen), written down beside the
  fallen, outside the save (`user://earth-kings.sixteen.json`, [D47](06-decisions.md)). A later life,
  in a world of the same sixteen, that shuts the same gate hears the latest word another lead left
  there: "Through the last of the light, faint, comes a voice from another world: Atlas's." and then
  the line itself, in their voice. Failing that, the first gate a life shuts carries the lead who fell
  last: their last word, or, if they never shut a gate, word of them (a name, the mark, and a world
  that has ended). It plays after the crossing if there is one, with a line in the journal and the
  annals. No answer, no meeting; nothing else passes through. A world built from a seed asked for
  hears nothing. The crossing's odds and the first gate rule do not change.

Four boxes for a meeting, three for a burning world, three for a word carried and two for word of a
lead. Every word and number of the crossing is **Inferred** (agenda item 92); the word carried's
wording and which gate it is heard at are **Inferred** (agenda items 106 and 107).

## How it was tested

The play-tests and design meetings that shaped the hour. Their notes and write-ups are kept in the
project's shared files (`meetings/`), not in this repository; the calls they made are in
[06](06-decisions.md).

| When | What | Build | What came of it |
| --- | --- | --- | --- |
| 2026-10-14 | Design meetings 1 and 2, the retreat | main | The First Hour as the only milestone ([D95](06-decisions.md)), its route ([D101](06-decisions.md)), the pillars ([D99](06-decisions.md)) |
| 2026-10-15 morning | The gamers' conference | main | The First Hour setting, Ascend first, Atlas first ([D104](06-decisions.md) to [D110](06-decisions.md)) |
| 2026-10-15 | Meeting 3 (a first-time player's timed run) | `10e7163` | Nobody got into the Tower; nobody died. Door, saves, harder hour, floor shapes ([D111](06-decisions.md) to [D114](06-decisions.md)) |
| 2026-10-15 11:20 | Ewan's (`doug-md`) play-test 2, PC browser | `bdfdfc6` | Found the door, cleared floors 1 and 2, then the Tower locked him out; difficulty "fair". Meeting 4's fix batches ([D115](06-decisions.md) to [D124](06-decisions.md)) |
| 2026-10-15 13:02 | Meeting 4, voted without the founders on `dougie`'s word | — | [D115](06-decisions.md) to [D124](06-decisions.md) |
| 2026-10-15 | Eight bot runs to floor 5 ([D117](06-decisions.md)) | `156f986` | No falls before floor 5 in 8 runs, every chapter one closed in about 2.5 minutes: easy side of the 1 to 3 target. Numbers kept for Ewan's next run (`dougie`, 18:02) |
| 2026-10-15 22:54 | Ewan's (`doug-md`) play-test 3, about 45 minutes as Ultor, in the Godot editor on his PC, thinking aloud ([transcript](worldbuilding/voice-notes/2026-10-15-doug-md-play-test-3.md)) | the evening's main, about `4196128` | Got through Greyhollow, the Tower to floor 10 and Coldrun. Liked the floors' design, the city's layout, different news from different people and the chapter one. Stutters crossing tiles; the land empty of life; fights taken off to an arena. First fixes [D178](06-decisions.md); his bigger asks [below](#play-test-3s-asks), waiting on his order |
| 2026-10-17 00:48 | Ewan's (`doug-md`) play-test 4, about 35 minutes, a new game as Janus, in the Godot editor on his PC, thinking aloud ([transcript](worldbuilding/voice-notes/2026-10-17-doug-md-play-test-4.md)), with the play log on | main of 2026-10-16 night (after #177), not all of it picked up by his Godot (his word, 2026-10-17: the Warden's pictures and the memory theme failed to load) | Saw the land's birds and bugs; liked click-to-walk, the Watch's different lines, the open plains, Muck Muck and Sinner. His log: the Tower from floor 3 to 20 with Janus, Atlas and Kandro, then five with Luc and Caesar, every fight above floor 5 won in 2 to 18 seconds, no deaths. Floors 6 up easier than 1 to 5, still no person met on the land to fight. First fixes [D189](06-decisions.md); his bigger asks [below](#play-test-4s-asks) |
| 2026-10-15 21:12 | The creatives' meeting (writers, art, music, world) | — | The chapter ones' rules and rewrites, the route's people, the replay's lines ([D151](06-decisions.md), [D153](06-decisions.md), [D154](06-decisions.md)); the music brief below |
| 2026-10-15 21:20 | The designers' week, with bot runs on PC and phone | `39b7728` | Ten findings: the hook only seen on a loss, the keeper as a figure, Auto parked at the door, a save every step at the door. The lights going out, Auto's stops, the Warden ([D149](06-decisions.md), [D150](06-decisions.md), [D156](06-decisions.md)) |
| 2026-10-15 22:04 | The designers' fortnight (Will's list of sixty-one, simulated) | — | The bestiary, names, wares, a second gate, the store page ([D143](06-decisions.md) to [D148](06-decisions.md)) |
| 2026-10-15 23:50 | Five strangers: bot personas, two on PC, three on phones | `4196128` | After the city nobody found the first gate; phone held upright unplayable; a gate's fight opened the old screen; no deaths in 95 minutes ([D161](06-decisions.md), [D162](06-decisions.md), [D163](06-decisions.md)) |
| planned | Five real people, chosen by the founders, with the play log on (call AV) | `e3ed512` or later | Then meeting 5. Who and when: [30](30-questions-for-the-founders.md), question 4 |

### Play-test 3's asks

What `doug-md` asked for in play-test 3 that needs more than a fix, **planned**, in no order until he
gives one. Already done: the first fixes ([D178](06-decisions.md)); a gate is gone into with E beside
it and fought on its plaza ([D116](06-decisions.md), [D162](06-decisions.md), built after his build);
picking fighters by clicking, dragging a box or Tab, and right-click to move, were there (the fight's
tip now says so).
1. **The opening as a small film**: the fall, the crater forming, Bram walking over; Bram carries the
   lead to a hut near the crater, they wake there, and he hands over the journal ("you came down with
   this too"). The crater is no safe place.
2. **A small square map** in the corner with north, east, south and west on its sides, instead of the
   compass; right-click a place for "Go here" (Auto) or "Place a marker", the marker shown on it.
3. **The far Tower** at the screen's edge is too big and distracting: a better way to show where it
   is; and the Tower should rise, not look flat.
4. **Life on the land**: animals, birds that move and fly off as you come near, bees and butterflies;
   guards patrolling the roads; people doing things. Built ([D179](06-decisions.md)): the birds and
   bugs, and the Watch on the road; animals that walk wait on their art (A29).
5. **Every fight where it happens**: the roadside toll, defending a town under siege (Coldrun, with
   archers on its towers), and Tower floors 6 up, not a separate arena; a short scene before choosing.
6. **Stormreach built round the Tower**: the Tower in the middle and the town all round it, not a
   door that opens onto a city.
7. **The Guild's board read at the board**, or in the Guild's hall (a tavern), not from anywhere in
   town; more named places.
8. **The sword in the Tower's yard** sunk in the ground, pulled with a dice roll, once.
9. **Tower floors** with themes (an ice floor of ice creatures, goblins in winter coats) and harder;
   stairs that look like they go up and cannot be walked through; perhaps "Are you sure?" before
   leaving floor 5.
10. **The chapter-one memory shown** as a little film, not only told.
11. **Height**: levels reached by stairs, as in Pokémon; trees and bushes that cannot be walked through.
12. **Looks**: patches that overlap where they should blend; town walls and towers that line up;
   trees not through walls; shadows from a sun; walks that face the way they go and livelier idles;
   Twin Blade's picture; portraits whose hair fits the frame; Sky's tail (A28); something inside
   houses; a bench and a chest that look placed; a lighthouse that suits the scene.
13. **Coldrun "comes into sight"** before it can be seen.

### Play-test 4's asks

What `doug-md` asked for in play-test 4 that needs more than a fix, **planned**, waiting on his order.
Already done: the first fixes ([D189](06-decisions.md)). Some repeat play-test 3's (noted).
1. **Every fight in real time where it happens**, no pause and no separate box: Tower floors 6 up on
   the Tower's own floor, not a field of grass (play-test 3, item 5).
2. **The map**: click a place on it to "Go to location" or "Waypoint marker" (right-click); the
   party keeps walking while it is open; a small map in a top corner with the compass on it and the
   waypoints, clicked to go (play-test 3, item 2).
3. **Roads and ways**: more paths, dirt roads and signposts; work out the kinds of road and way
   there are (footpaths, carriage roads, bog roads and more), ask which to use, then an art request
   and build them.
4. **People on the land**: more encounters, people to fight ("I still haven't encountered a single
   person I can fight"); other adventurers about and climbing the Tower; the Watch fighting bands
   near them, a fight you can join and be thanked for (play-test 3, item 4).
5. **Inns with rooms**: a kitchen, a dining room and bedrooms, more than one small square; pay for
   a bed and a marker shows which room is yours.
6. **Help on the paths**: a question mark at the right of a choice's banner that says what each
   path is in more words, on hover.
7. **A siege seen**: when Stormreach is attacked and defended, see the fight there, not be taken
   somewhere else and put back.
8. **Towers that match their land**: the scenery round a tower to fit the ground it stands on.
9. **The bottom of the screen**: something there (the party's pictures or a building) does not fit
   the screen and wants resizing and moving. **To ask him which.**
10. **Followers facing the way they walk** when walking down. Not reproduced: a suite walking a party
    of three down, up and down again finds them facing the leader's way. **To ask him where it was.**
11. **A town of your own**, later in the game: settle a village, people come to it, it grows to a
    city or a stronghold.

## Music the hour still needs

The fan covers are out of every build ([D100](06-decisions.md)). The hour plays on Ewan's two
Ableton tracks and, until his cues arrive, five stand-ins made in code by `tools/make_music.py`
([D185](06-decisions.md)), all in D minor and sharing the memory theme's first notes, A D C A. What
plays where (`data/music.json`: a scene's set, a place's over it, a dialogue's over both):

| Where | Plays | Whose |
| --- | --- | --- |
| Title, the opening and its replay, the credits | Angelic, quiet | Ewan's |
| The road and the land | Angelic | Ewan's |
| The crater (the lead's landing tile) | `crater`: wind, a fire ticking, the memory phrase once, far off (30 s loop) | in-house |
| Stormreach, its streets and tavern | `stormreach`: lute, hand drum, a reed tune, the motif in the bass (32 s) | in-house |
| Tower floors 1 to 5 | `tower_floors`: an organ chord, a footfall, the motif on a bell, slow and low (32 s) | in-house |
| A chapter one, while it is open | `memory_theme`: one piano, a phrase stopped dead, then a held D (30 s) | in-house |
| Every fight | Bday Project | Ewan's |
| The death screen and the world's last look | `world_ending`: the memory phrase broken off (24 s) | in-house |

How each sounds and where it plays is **Inferred** (agenda items 113 and 114). The creatives' meeting
(C7, 2026-10-15) asked Ewan for these, in this order; each of his replaces a stand-in by its path in
the set, or comes in with a set and a place or scene key. Still **planned**: a layer added a floor up
the Tower (3) and the replay thinning as fewer are left (6); the opening's replay keeps the title's
Angelic. Ewan's to make ([30](30-questions-for-the-founders.md), question 13).
1. **The memory theme**: 40 to 60 seconds, one instrument, a short phrase that stops dead on
   "White.", then a held note. All sixteen chapter ones use it; three or four notes of it for the
   other cues to borrow.
2. **The world ending** (the death screen, Ascend): the memory phrase, broken off early.
3. **The Tower floors**: a slow loop, lower than the road; a layer added a floor if that is easy.
4. **Stormreach**: busy, the Tower's motif under it.
5. **The crater**: near silence, wind and fire, the memory phrase once, far off, when Bram speaks.
6. **The opening's replay**: the film's music thinner as fewer are left (many left, two, the last).

The whole game's list, these six placed by how long a player hears each, is [31](31-music.md)
([D186](06-decisions.md)).

## Builds on itch.io

The browser build goes to `dougie`'s itch.io page (both the `html5` and `web` channels) only on
`dougie`'s word. The commit is the version, and this table is the marker for which build a play-test
played: `git checkout <commit>` gives it back.

**A devlog with each push** ([D148](06-decisions.md)). Every push carries a short devlog post on the
itch page: what changed since the last build, a line or two per change, in a player's words, not the
decision numbers. Whoever pushes drafts it with the build; it goes up with the build, on `dougie`'s word.

| Pushed (UTC) | Commit | What it carried |
| --- | --- | --- |
| 2026-10-13 | main | The first browser build on the page |
| 2026-10-14 22:30 | `ffcd508` | First Hour steps 1 to 4, the pillars ([D99](06-decisions.md)), the fan covers out ([D100](06-decisions.md)) |
| 2026-10-15 07:26 | main after #127 | The gamers' week: First Hour setting, Ascend first, Atlas first, sixteen quiz answers ([D104](06-decisions.md) to [D110](06-decisions.md)) |
| 2026-10-15 11:05 | `bdfdfc6` | Frozen for Ewan's play-test 2: door art, saves, harder hour, five floor shapes ([D111](06-decisions.md) to [D114](06-decisions.md)) |
| 2026-10-15 18:14 | `9f1b267` | Meeting 4's batches, the play log, the road, Auto climbs, biome edges, Tower floors, scenery by rule, the roadside drawn ([D115](06-decisions.md) to [D131](06-decisions.md)) |
| 2026-10-15 20:25 | `4196128` | The art hour (stair and runes, yard, crater, city paving, [D132](06-decisions.md) to [D137](06-decisions.md)), Cato's chapter one and the replayed opening ([D135](06-decisions.md)), seven more chapter ones ([D138](06-decisions.md)) |
| 2026-10-16 07:02 | `e3ed512` | The designers' fortnight and the night's work: the Tower's bestiary and names ([D143](06-decisions.md), [D144](06-decisions.md)), all sixteen chapter ones ([D145](06-decisions.md), [D151](06-decisions.md)), three wares at a market ([D146](06-decisions.md)), two gates at the Guild ([D147](06-decisions.md)), a light goes out at the hour's end ([D149](06-decisions.md)), Auto stops for the fights that matter ([D150](06-decisions.md)), gate crossings ([D152](06-decisions.md)), the replay's memory line and the route's people ([D153](06-decisions.md), [D154](06-decisions.md)), the Warden of the Fifth, six lands and the huge Tower drawn ([D156](06-decisions.md) to [D158](06-decisions.md)), the compass points at the first gate after the city ([D161](06-decisions.md)) |
| 2026-10-16 09:11 | `9c64cb3` | A gate's fight fought where the party stands, not on the old fight screen ([D162](06-decisions.md)), and a phone held upright laid out tall with the ground filling it and larger text ([D163](06-decisions.md)) |
