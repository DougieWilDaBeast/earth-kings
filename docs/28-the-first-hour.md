# 28 — The First Hour

**What a new player plays today, start to finish, and how it got that way.** The First Hour was the
only milestone until it was done ([D95](06-decisions.md)); `dougie` called it done on 2026-10-16
([D168](06-decisions.md)). What else is built stays hidden behind `data/world_rules.json` →
`first_hour.hidden` ([D97](06-decisions.md)) until each system fits back into the world and the story. The order of work and what
is next is in the [roadmap](05-roadmap.md#next-steps-in-order); this doc describes what exists.

## The route

1. **New Game.** A new player plays **Atlas's last stand** ([D191](06-decisions.md)): the last day of
   Atlas's world in Hearthwick, the game's ways taught on a card in seven steps (fourteen until
   [D300](06-decisions.md)), then a band out of a broken gate he cannot beat. He falls for good, and the quiz picks the first life of the player's own, on the
   **First Hour** setting, where a fall is for good ([D104](06-decisions.md)). The opening plays whole,
   with Atlas's world the one seen ending ([25](25-the-opening.md)). (Until D191 the first life was
   Atlas himself, with no quiz, [D106](06-decisions.md); `first_hour.first_life` still names him.)
   The last stand is not a life of the player's own: the lead after it lands as a first life, below.
2. **The crater.** The lead comes down with their companions (Atlas with Sky, before D191) in a scorched crater ([D134](06-decisions.md)) 12 to 16
   tiles from Stormreach ([D101](06-decisions.md)). Bram pulls them out. Five boxes, then they walk
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
   the ruined bathhouse, and Sinner, a cleric, mends the whole company for 10 silver (40 gold before the four coins, D253) at the old shrine
   ([D176](06-decisions.md)).
5. **The first gate.** Two are offered, both rank E and open in every world: Greyhollow, eight tiles
   south of the city at the road's end, and Elderford, nine tiles north ([D147](06-decisions.md)). E
   beside one goes in; walking onto it does not ([D116](06-decisions.md)). Going in opens its floor, walked
   chamber to chamber past the bands holding them to its keeper, before the way out at the far end
   ([D248](06-decisions.md), play-test 6; until then its fight was fought on the plaza, [D162](06-decisions.md)). Its plaza runs up to its gate, a
   standing doorway of rune stones with the gate's light turning in it ([D137](06-decisions.md),
   [D141](06-decisions.md)). Shutting it gives the Guild's mark. As it shuts, its light opens onto the
   same gate in another lead's world, and that lead, the original, is standing in it shutting their
   side: one line from them, and the light closes ([D152](06-decisions.md), [below](#the-crossing)).
6. **The Tower.** A door drawn in house with lit rune stones up the yard ([D111](06-decisions.md)), a
   the huge Tower's round, rune-banded shaft over it, drawn in house
   until art A9 ([D158](06-decisions.md)), seen from far off beside the way ahead
   rather than over it ([D142](06-decisions.md)), the yard paved plainly
   ([D133](06-decisions.md)). "E to climb" at the door. Auto walks across the Tower's tile to the
   door and stops there; switched on again, it goes in ([D206](06-decisions.md)).
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
by [D117](06-decisions.md), corrected by [D150](06-decisions.md); left at 9 by [D301](06-decisions.md)). **Saves**: on walking into a town or the city (once an arrival: in and out over its edge is not saved again until the party has been three tiles off, [D206](06-decisions.md)), opening the register,
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
| 2026-10-17 14:43 | Ewan's (`doug-md`) play log, about 45 minutes, no transcript: Iris leading Atlas, Saturn and Ocka, then Demetrios | his Godot, about the main of 2026-10-17 afternoon | The Tower from floor 1 to 20 in half an hour, chapters 1 to 4 closed, three gates shut and a B-rank gate; 68 fights, none lost, nobody below a quarter of their health. Most fights played at 5x (his word): on the log's clock floors 1 to 5 took a median of 3 seconds a fight (the keeper 24), floors 6 to 20 a median of 5 (longest 25), the land and gates a median of 1, 18 of 31 a second or less, so at 1x about 15 s, 25 s (the longest two minutes) and 5 s; the party went from about level 5 to 13. The fights on the Tower's upper floors are long enough; those on the land are over at once, and none of them hurt. One engine error ten times (a list scrolled to a button already gone), fixed; the log now names each fight's place and foes, since every fight read `verdant_pass`; floors 6 up hit harder since ([D222](06-decisions.md)) |
| 2026-10-15 21:12 | The creatives' meeting (writers, art, music, world) | — | The chapter ones' rules and rewrites, the route's people, the replay's lines ([D151](06-decisions.md), [D153](06-decisions.md), [D154](06-decisions.md)); the music brief below |
| 2026-10-15 21:20 | The designers' week, with bot runs on PC and phone | `39b7728` | Ten findings: the hook only seen on a loss, the keeper as a figure, Auto parked at the door, a save every step at the door. The lights going out, Auto's stops, the Warden ([D149](06-decisions.md), [D150](06-decisions.md), [D156](06-decisions.md)) |
| 2026-10-15 22:04 | The designers' fortnight (Will's list of sixty-one, simulated) | — | The bestiary, names, wares, a second gate, the store page ([D143](06-decisions.md) to [D148](06-decisions.md)) |
| 2026-10-15 23:50 | Five strangers: bot personas, two on PC, three on phones | `4196128` | After the city nobody found the first gate; phone held upright unplayable; a gate's fight opened the old screen; no deaths in 95 minutes ([D161](06-decisions.md), [D162](06-decisions.md), [D163](06-decisions.md)) |
| 2026-10-17 08:29 | Design meeting 5, chaired by the intern, voted without the founders on `dougie`'s word, with three self-played runs on main (`4852d22`, seeds 77, 1, 2, 15 minutes at 2×) | `4852d22` | City in 3 to 4 minutes and a gate shut in every run; none reached the Tower (Auto stops after the gate); one fall, on the road at 11:53. The milestones redrawn, the order of work, stances, the Second Hour, play-test 5's brief ([D193](06-decisions.md) to [D200](06-decisions.md)) |
| 2026-10-17 | D197's fixes, reproduced and shown with self-played runs ([D206](06-decisions.md)) | this PR, after `afb8008` | Before (`4852d22`, Atlas): no run stood at the Tower's door in 15 minutes. After, as Atlas: seeds 77, 1, 2 at the door at 5:10, 3:08, 6:30, every chapter one closed, no fall before floor 5; a killer named on every fall. As dealt leads (Bellona, Iris, Pluto, Vesta, Diana): 6 of 8 fell on the road or at the first gate, at levels 1 to 4 |
| 2026-10-17 | Auto rests when hurt, nine self-played runs as dealt leads ([D210](06-decisions.md)) | after #259 | After a lost fight Auto now rests in town (Iris back to 40 of 40). All eight runs still fell, nearly all at full health to their first road fights at levels 1 and 2 (Axe Bear, Flame Lion, Sword Monkey, Cutpurse): the stakes work, issue #230 |
| 2026-10-17 | The First Hour's road for a lead walking alone, seven self-played runs as dealt leads and one as Atlas ([D211](06-decisions.md)) | after #262 | Before (main, seeds 1, 2, 3): every one fell, at levels 1 to 3, two in their first fight (a Flame Lion, a Sword Monkey met at a quarter health after the cold). After (seeds 1 to 6): no fall in a first fight; falls after five minutes at levels 3 to 7; Liber to floor 4, Iris to floor 3, Pluto shut a gate. Diana (77) at the door at 3:39 (7:35 before), Atlas at 4:55. Stances (#261) merged after these runs |
| 2026-10-18 | The Second Hour's sixteen self-played climbs to floor 10 ([D258](06-decisions.md), #234; the table is below) | `e5628b9` and this PR | Alone, every climber fell by floor 6. With 0 to 3 companions rolled at random (`dougie`'s call): 6 of 16 reached floor 10, 4 fell (two to the Keeper of the Tenth's floor), 6 stalled. A party of three or more is fair; alone or with one, nobody reached floor 10 |
| 2026-10-18 23:16 | Ewan's (`doug-md`) play-test 7, about an hour, a new game as Juno (the fourth life of the world) with Pluto, Vesta and Atlas, in his Godot, thinking aloud ([transcript](worldbuilding/voice-notes/2026-10-18-doug-md-play-test-7.md), [play log](worldbuilding/voice-notes/2026-10-18-doug-md-play-test-7.playlog.txt)) | his Godot, main of 2026-10-18 evening (`e5628b9` or later: the Keeper of the Tenth is in it) | Liked going into the gates ("Great addition") and Stormreach walked outside ("This looks fantastic"). His log: the Tower from floor 1 to 20 and four gates shut in about 53 minutes, chapters 1 to 4 closed; 58 fights, none lost, nobody below half their health after any; on the fight clock floors 1 to 5 a median of 5.5 seconds, 6 to 20 about 11, the land and gates 5; the Warden of the Fifth and the Keeper of the Tenth each down in under 15. A party of four is past fair, the same as the Second Hour's climbs. First fixes [D259](06-decisions.md); his bigger asks [below](#play-test-7s-asks) |
| 2026-10-21 09:19 | Ewan's (`doug-md`) play-test 8, about 40 minutes, a new game as Janus with Fennick the Scrivener, Cal of Stormreach and Brother Oswin (later Orin, Captain Edda and Atlas), thinking aloud ([transcript](worldbuilding/voice-notes/2026-10-21-doug-md-play-test-8.md), [play log](worldbuilding/voice-notes/2026-10-21-doug-md-play-test-8.playlog.txt)) | `6f8fcf6` (main with #386, #387) | Liked the formations ("working very well"), the Gilded Flagon ("looked very good") and a gate opening beside the Tower; "I think it is really good." His log: Greyhollow and Elderford shut, the Tower from floor 1 to 15, chapters 1 to 3 closed, 46 fights in about 40 minutes; one lost, four wolves on the ground by the Tower at 5×, Janus, Fennick and Cal dead and the run over. A `called:` error in nearly every fight (already fixed on main), 10 to 14 fps for the ten seconds after fights with new foes began, levels still won in the Tower and on the ground (milestone B, [D292](06-decisions.md)). First fixes [D324](06-decisions.md); his bigger asks [below](#play-test-8s-asks) |
| planned | Five real people, chosen by the founders, with the play log on (call AV) | `e3ed512` or later | Then meeting 5. Who and when: [30](30-questions-for-the-founders.md), question 4 |

### The Second Hour's climbs

Sixteen self-played climbs, seeds 1 to 16, each the lead the quiz deals, on the First Hour setting
at 2×, stopped at floor 10 won or after 40 minutes (`tools/soak.gd --until-floor=10
--companions=random`, [D258](06-decisions.md)). Each walks out with 0 to 3 companions of the inns'
kinds at levels 1 to 6, rolled from the seed (`dougie`, 2026-10-18: "random amounts of random leveled
companions to each climber, so that we can see value of parties"). Auto rests before it goes up,
turns back down a floor when hurt, and after a chapter goes to the easiest gate. Main `e5628b9` with
this PR's Auto changes. Floor is the one fought on.

| Seed | Lead | Companions | Outcome | Time |
| --- | --- | --- | --- | --- |
| 1 | Janus | Bram 1, Bram 6, Sera 6 | **Floor 10 won**, level 5 | 6:04 |
| 2 | Liber | Bram 4 | Fell on floor 10 to the Keeper of the Tenth, level 7 | 6:52 |
| 3 | Iris | Bram 2 | Fell on floor 5 to the Warden of the Fifth, level 4 | 3:50 |
| 4 | Pluto | Toln 1, Toln 3 | **Floor 10 won**, level 8 | 6:31 |
| 5 | Vesta | Bram 3, Bram 1 | **Floor 10 won**, level 7 | 7:00 |
| 6 | Liber | none | Stalled after floor 3, level 6 | 40:00 |
| 7 | Ceres | Toln 3 | Stalled after floor 4, level 5 | 40:00 |
| 8 | Ares | Toln 2 | Stalled after floor 9, level 9 | 40:00 |
| 9 | Bellona | none | Fell on floor 10 to a goblin, level 9 | 15:14 |
| 10 | Juno | Sera 5, Bram 2 | **Floor 10 won**, level 7 | 6:42 |
| 11 | Ultor | Toln 2, Bram 2 | **Floor 10 won**, level 8 | 11:24 |
| 12 | Liber | none | Stalled after floor 1, level 5 | 40:00 |
| 13 | Cassius | Sera 4, Sera 1, Toln 4 | Fell on floor 10 to a poacher, level 8 (Toln with him) | 6:13 |
| 14 | Iris | Bram 2, Toln 3, Bram 1 | Stuck at the Tower's door after floor 5, level 4 | 5:30 |
| 15 | Juno | Toln 6, Sera 2, Sera 4 | **Floor 10 won**, level 8 | 6:54 |
| 16 | Ares | none | Stalled after floor 7, level 9 | 40:00 |

**4 falls in 16**, inside [D197](06-decisions.md)'s 2 to 5. Six reached floor 10, all with two or three
companions, in 6 to 11 minutes. By party: with two companions 4 of 4 won; with three, 2 of 4 won and 1
fell; with one, 2 of 4 fell and none won; alone, 1 of 4 fell and none won. The stalled runs were hurt
with nowhere known to rest (Stormreach is walked into, not rested at by arriving), so Auto went in and
out of the door; it now turns back only when there is somewhere to rest. The first batch, everyone
alone and no companions, fell 13 of 13 by floor 6 (one on floor 1, two on 3, seven on 4 to the Warden
or its Bog Jellies, three on floor 6), and is why Auto rests and turns back.

**Levelling in gates** ([D301](06-decisions.md), #378): sixteen self-played runs of ten minutes at five times
speed, seeds 101 to 108, each once alone and once with random companions, on main after #415 with D301. Levels come only from new kinds in a gate. Level after the first gate, then the floor won and the
level at the end. Floor is the highest won.

| Seed | Lead | Companions | After the first gate | Outcome |
| --- | --- | --- | --- | --- |
| 101 | Bellona | none | 4 | Floor 5 won, level 7, hunting gates |
| 102 | Ares | none | 3 | Floor 7 won, level 6 |
| 103 | Bellona | none | 3 | Floor 6 won, level 7 |
| 104 | Ares | none | 3 | Floor 6 won, level 7 |
| 105 | Cato | none | 3 | Floor 6 won, level 7 |
| 106 | Diana | none | 2 | Fell on floor 5 to the Warden, level 2 (no gate at her rank left) |
| 107 | Ultor | none | 3 | Fell on floor 5 to the Warden, level 4 |
| 108 | Ares | none | 4 | Floor 8 won, level 8 |
| 101 | Bellona | Bram 4, Sera 2 | 4 | Fell on the land to an Axe Bear, level 4 (1:23) |
| 102 | Ares | Bram 3 | 3 | Floor 5 won, level 6, hunting gates |
| 103 | Bellona | Bram 5, Toln 3, Sera 1 | 2 | Floor 8 won, level 5 |
| 104 | Ares | Bram 5, Bram 3, Sera 1 | 2 | Floor 5 won, level 6, hunting gates |
| 105 | Cato | Bram 5, Toln 3, Toln 5 | 3 | Floor 9 won, level 6 |
| 106 | Diana | Toln 5, Toln 5 | 1 | Fell on floor 6 with Toln, level 7 (8:27) |
| 107 | Ultor | Toln 3, Bram 6, Sera 2 | 4 | **Floor 10 won**, level 8 (9:20) |
| 108 | Ares | Bram 4, Bram 6, Bram 1 | 4 | Fell on the land to a Dread Wraith, level 4 (1:14) |

**5 falls in 16**, inside [D197](06-decisions.md)'s 2 to 5; no script errors and no stalls. The first gate
brings a lead to level 3 or 4 (12 of 16; Diana, the slowest learner, 1 to 2). Floors 1 to 5 were won in 14 of
16. Lone leads stand at floor 5 to 8 after ten minutes at level 6 to 8, going out to gates between climbs;
one party in eight reached floor 10, against six in sixteen in 6 to 11 minutes before. Three earlier rounds
found the faults fixed with it: Auto stalled on the way to the Tower in every run (a tree over a tile's edge),
stood at a gate too strong to go into, paced one tile's border for minutes, and climbed on into the Warden at
level 3. These runs had floor 5's keeper at level 6 and floors 6 up a level higher for each of the company
past the first; `dougie` put both back as they were (keeper 9, floors flat), to revisit once a later lead carries
strength from the worlds before ([D301](06-decisions.md)). Logs: `/mnt/project-files/simulations/2026-10-21-levelling-in-gates/`.

**How long the Second Hour took to build** (#234): the build half, floors 6 to 10, the sixteen chapter
twos into the game, the Keeper of the Tenth, suites and docs ([D254](06-decisions.md), PR #324), took
one Claude thread about 30 minutes (17:59 to 18:29 UTC, 2026-10-18), with the plan ([D196](06-decisions.md))
and the chapter-two drafts ([D182](06-decisions.md)) already written. The runs and the Auto fixes they
turned up took about four hours (18:30 to 22:40), most of it waiting on the runs, which play in real time.
Art (A34 to A36) is not drawn yet. **Inferred**, for sizing the hours after it: about half a day of one
thread a hour of play once its words and plan exist, plus the art.

### Play-test 3's asks

What `doug-md` asked for in play-test 3 that needs more than a fix, **planned**, in no order until he
gives one. Each open one is an issue on the board ([D208](06-decisions.md)): 1 #245, 3 #247, 6 #238, 7 #248,
8 #249, 9 #250, 10 #246, 11 #251, 12 #252, 13 #253. Already done: the first fixes ([D178](06-decisions.md)); a gate is gone into with E beside
it and fought on its plaza ([D116](06-decisions.md), [D162](06-decisions.md), built after his build);
picking fighters by clicking, dragging a box or Tab, and right-click to move, were there (the fight's
tip now says so).
1. **The opening as a small film**: the fall, the crater forming, Bram walking over; Bram carries the
   lead to a hut near the crater, they wake there, and he hands over the journal ("you came down with
   this too"). The crater is no safe place.
2. **A small square map** in the corner with north, east, south and west on its sides, instead of the
   compass; right-click a place for "Go here" (Auto) or "Place a marker", the marker shown on it. Built ([D232](06-decisions.md)).
3. **The far Tower** at the screen's edge is too big and distracting: a better way to show where it
   is; and the Tower should rise, not look flat.
4. **Life on the land**: animals, birds that move and fly off as you come near, bees and butterflies;
   guards patrolling the roads; people doing things. Built ([D179](06-decisions.md)): the birds and
   bugs, and the Watch on the road; animals that walk wait on their art (A29).
5. **Every fight where it happens**: the roadside toll, defending a town under siege (Coldrun, with
   archers on its towers), and Tower floors 6 up, not a separate arena; a short scene before choosing.
6. **Stormreach built round the Tower**: the Tower in the middle and the town all round it, not a
   door that opens onto a city. Built ([D247](06-decisions.md), play-test 6, pick B): the city is walked on the land
   with no door, the Tower beside it to the north.
7. **The Guild's board read at the board**, or in the Guild's hall (a tavern), not from anywhere in
   town; more named places. The board built ([D359](06-decisions.md), 2026-10-21): a notice board beside the
   Guild's clerk in every village and keep and in Stormreach, read only standing at it; more named places still planned.
8. **The sword in the Tower's yard** sunk in the ground, pulled with a dice roll, once. Built
   ([D318](06-decisions.md), 2026-10-21): one pull a run, one chance in six, a Silver Blade.
9. **Tower floors** with themes (an ice floor of ice creatures, goblins in winter coats) and harder;
   stairs that look like they go up and cannot be walked through; perhaps "Are you sure?" before
   leaving floor 5.
10. **The chapter-one memory shown** as a little film, not only told.
11. **Height**: levels reached by stairs, as in Pokémon; trees and bushes that cannot be walked through.
12. **Looks**: patches that overlap where they should blend; town walls and towers that line up;
   trees not through walls; shadows from a sun; walks that face the way they go and livelier idles;
   Twin Blade's picture; portraits whose hair fits the frame; Sky's tail (A28); something inside
   houses; a bench and a chest that look placed; a lighthouse that suits the scene.
13. **Coldrun "comes into sight"** before it can be seen. Fixed ([D238](06-decisions.md)): walking the
    ground, the line waits until the place is within a tile, about what the screen shows.

### Play-test 4's asks

What `doug-md` asked for in play-test 4 that needs more than a fix, **planned** unless marked.
Already done: the first fixes ([D189](06-decisions.md)). Some repeat play-test 3's (noted). His order
(2026-10-17, [D204](06-decisions.md)): item 1 first, then item 4, ahead of meeting five's list. On the board
([D208](06-decisions.md)): 1 #205 (done), 2 #209, 3 #244, 4 #206, 5 #239, 6 #254, 7 #255, 8 #256, 9 #257, 11 #258.
1. **Every fight in real time where it happens**, no pause and no separate box: Tower floors 6 up on
   the Tower's own floor, not a field of grass (play-test 3, item 5). Part one built
   ([D204](06-decisions.md)): no stop before a fight on the ground and no box round it. Part two built
   ([D207](06-decisions.md)): no separate fight screens. Tower floors 6 up are walked on a borrowed plan
   of floors 1 to 4, with their own foes and at least as many as the plan's bands (floor 6: two bands
   of two), the top floor's keeper before the stair; gate floors already were ([D162](06-decisions.md));
   a roadside fight is fought where its scene stands, a town defended or raided and a captive taken
   back just ahead of the party. The Second Hour ([D196](06-decisions.md)) gives 6 to 10 rooms
   of their own (built, [D254](06-decisions.md)).
2. **The map**: click a place on it to "Go to location" or "Waypoint marker" (right-click); the
   party keeps walking while it is open; a small map in a top corner with the compass on it and the
   waypoints, clicked to go (play-test 3, item 2). Built ([D232](06-decisions.md)), his first pick.
3. **Roads and ways**: more paths, dirt roads and signposts; work out the kinds of road and way
   there are (footpaths, carriage roads, bog roads and more), ask which to use, then an art request
   and build them. He picked **footpaths and dirt tracks** (2026-10-17): built, with signposts
   where three ways meet ([D233](06-decisions.md)), the art asked for (A32).
4. **People on the land** (next after item 1, all three parts together): more encounters, people to fight ("I still haven't encountered a single
   person I can fight"); other adventurers about and climbing the Tower; the Watch fighting bands
   near them, a fight you can join and be thanked for (play-test 3, item 4). Built
   ([D215](06-decisions.md), issue #206): six bands always camp near the road, 2 to 4 tiles off it
   and clear of places, half of them brigands (there were none or one within 4 tiles of it); on the
   roads round a town, the Watch beset by brigands or wolves, joined or walked past; companies of
   climbers walking the road, and resting by the stair on Tower floors 2 up, who talk.
5. **Inns with rooms**: a kitchen, a dining room and bedrooms, more than one small square; pay for
   a bed and a marker shows which room is yours. Built for the three inns with an innkeep
   ([D242](06-decisions.md)): the Ford and Crown, the Oasis Serai, the Gilded Flagon.
6. **Help on the paths**: a question mark at the right of a choice's banner that says what each
   path is in more words, on hover. Built ([D237](06-decisions.md)): on each path card at level 2,
   hover or press the **?**.
7. **A siege seen**: when Stormreach is attacked and defended, see the fight there, not be taken
   somewhere else and put back.
8. **Towers that match their land**: the scenery round a tower to fit the ground it stands on.
9. **The bottom of the screen**: something there (the party's pictures or a building) does not fit
   the screen and wants resizing and moving. **He said which** (2026-10-17, [his answers](worldbuilding/voice-notes/2026-10-17-doug-md-founders-questions-2.md)): the fight's party
   cards, with each one's name, skills and the draughts and food to drink or eat. Only one to three
   of a party of five or six showed, so the rest could not use a skill or a draught (#257). Fixed ([D231](06-decisions.md)).
10. **Followers facing the way they walk** when walking down, out on the open land (his answer,
    2026-10-17): once in step they never turned, so after walking up they walked down looking up.
    Fixed ([D214](06-decisions.md)).
11. **A town of your own**, later in the game: settle a village, people come to it, it grows to a
    city or a stronghold.

### Play-test 6's asks

What `doug-md` asked for in play-test 6 ([transcript](worldbuilding/voice-notes/2026-10-17-doug-md-play-test-6.md))
that needs more than a fix, **planned**, waiting on his order. Already done: the first fixes
([D246](06-decisions.md)): the black screen and the jumping at 5×, fighters dancing side by side,
text crossing at the bottom of the screen, a far-too-strong gate asking twice, climbers who fight.
1. **Stormreach walked outside**: the city laid out in the open, big, the Tower beside it or in its
   middle, not entered through a small building. Built ([D247](06-decisions.md), pick B): a walled city
   on the land, the Tower just past its north gate.
2. **Fights inside a gate**: going into a gate opens a whole area to fight through; fights outside a
   gate only when it breaks (this turns back [D162](06-decisions.md)). His first pick (2026-10-18):
   built ([D248](06-decisions.md), #314): each floor rock chambers from the doorway to the way down, a
   band in each, the keeper before the way down on the last floor.
3. **Tower floors that grow**: each floor bigger than the last, towards three hundred tiles.
4. **Climbers with a part to play**: fighting monsters (or the party) on the floors, getting ready
   or recovering; a short recruitment, joining arms with a company.
5. **Places worth going to**: hamlets of three or four houses, a lone homestead behind a low wall,
   more places to go inside; a reason to explore beyond Stormreach, the gate and the Tower. Art
   for them when PixelLab's credits come back.
6. **The paths and the gates' ground**: footpaths and tracks that run on without a hard cut and meet
   cleanly where four cross; a gate's ground that fits the land round it, not a square; the hard
   straight edge where a tile meets ground that cannot be walked.
7. **The play screen after RimWorld**: little on screen, quick to move (begun in
   [D244](06-decisions.md) and [D245](06-decisions.md)).
8. **Carriages**, and other ways to travel.
9. **5× speed** still runs heavy on a slower machine (the jumping is gone, [D246](06-decisions.md)).

### Play-test 7's asks

What `doug-md` asked for in play-test 7 ([transcript](worldbuilding/voice-notes/2026-10-18-doug-md-play-test-7.md))
that needs more than a fix, **planned**, in the founders' order ([D260](06-decisions.md), call BR, 2026-10-19): items 1
and 4 next, in that order; 11 (Sennet), 12 (the journal at the side first), 15 and the climbers' stone (from 2) as small
pieces now; 14 yes; 7, 8 and 10 after the gates and tiers; who wields what stays as it is. The six and the
Tower's agelessness (2) are canon, the six's names `doug-md`'s. Already done: the first fixes ([D259](06-decisions.md)): the party gone after the wilds, Hob's Lot
standing by on floor 2, the boxes at the bottom far too big, a cache always a coin pile (art A37 asked
for), the ground said to shake but not seen to. Some repeat play-test 6's (noted).
1. **Gates that grow** (grows play-test 6, item 2): ground of its own kind inside (frost, fire, grass,
   cave, open plain); length by rank, an S-rank gate 10 to 15 minutes with a boss fight of 5 to 7; shut
   only when every monster in it is dead, or its lord falls and the rest scatter; the gate left broken on
   the ground after; the people round it cheering, and the tale told on. **Built** ([D261](06-decisions.md),
   [below](#gates-that-grow)).
2. **A legendary company of six**: humans who climbed long ago and are still alive high up (about floor
   70), since nobody ages inside the Tower; their monuments, tales and who they were before, on the
   land. And **climbers' names on the Tower**, a board of how high each got (built, [D266](06-decisions.md):
   a stone at the Tower's door, the fallen leads and their floors, the lead while climbing, six worn names at its
   top). Canon: the founders'.
3. **The world's history**: how Earth Kings came to be the way it is, so the game is more than the climb.
4. **Five tiers of each monster** (lesser, plain, high, hob, and a chieftain or a caster), and
   **creatures that fit the land** they are in (no grasshoppers in magma). The goblins', the wolves' and 24 more monsters' five **built** ([D262](06-decisions.md), [D264](06-decisions.md) and [D267](06-decisions.md) to [D270](06-decisions.md)), dealt by the fight's level, art asked for (A39, A40 and A42 to A45).
   The named one-off monsters keep one kind. Creatures that fit the land **built** ([D355](06-decisions.md)): a
   faction's band on the land is drawn only from what can live there (nothing of fire on the snow, nothing of the
   cold on the dunes, no slime in the ash), the land's own creatures coming when none can; the land's own
   creatures' art waits on A56. `doug-md`, 2026-10-19:
   "The more monster tiers the better. Give more variety for long term game"; more than five a family is **planned**. Each tier fights its own way, built ([D275](06-decisions.md)): the lesser runs when badly hurt,
   the high charges and flanks, the hob fights harder near death, the chieftain spurs its kin, the caster finds the weak spot; pips over the bar show the rank. Each family has a trick
   of its own from the hob up, built ([D276](06-decisions.md)): goblins' Spite, the wolves' Howl, the slime's Ooze Back. S gates stay at five floors for now (`dougie`, 2026-10-19, call BS).
5. **Bodies that stay** after a fight, searched for loot. **Built** ([D352](06-decisions.md)) for bands beaten on
   the land: the fallen lie ahead of the party to walk up to and search (coin, sometimes a piece to carry);
   drawn as a cache until art A63. The bodies of a gate's or the Tower's floors are **planned**.
6. **Gear you can see**: weapons and armour shown on the fighter; an equipment screen; a shop list with
   an icon beside each item (art from PixelLab). The party screen shows what each carries with its picture, and a
   weapon is drawn in the fighter's hand where its art is in ([D290](06-decisions.md), held art A52). **Built**
   ([D353](06-decisions.md)): every ware a seller offers shows its picture beside its name and price. **Built**
   ([D357](06-decisions.md)): armour worn beside the weapon held, both counted in a fight; the Gear page is an
   equipment screen, the fighter drawn large in what they wear with a row for the hand and one for the body; armour
   seen on the fighter as a plate of its colour until its art (A64) is in.
7. **Crafting**: herbs into potions, a blacksmith who makes and upgrades weapons; and who can wield what
   (he said both "only weapons they're affiliated with" and "everyone can use the same weapons"). Built
   ([D280](06-decisions.md)): four draughts mixed from herbs on the party screen, and three smiths who hone a
   weapon a notch at a time; anyone still wields anything. Enchanting ([D327](06-decisions.md)): four runes from
   charms and herbs laid on a carried weapon from the party screen, each a fight passive. Herbs grow on the
   land to pick, by what each land grows ([D335](06-decisions.md)). Forging from parts is **planned**.
8. **Recruiting anyone**, by charisma, or by quests that win their trust after a no (built,
   [D277](06-decisions.md): "Walk with us." on anyone with something to say who keeps no post, a
   Charisma check, and after a no their own favour or a few fights won to bring them round; sellswords for
   coin off the Gilded Flagon's book, who go when the job is done, and the roaming leads drinking in the
   Flagon, built [D345](06-decisions.md)); **sending your own
   people out** on quests and into gates on Auto (built, [D278](06-decisions.md): from the party screen once a
   gate is shut, a band to a gate shutting it on the odds); **moods after RimWorld**, and some who will not climb
   (built, [D279](06-decisions.md): thoughts from fights, gates, floors and friends lost; most feel dragged up the
   Tower; at the bottom one walks off a while; since [D347](06-decisions.md) a friend beside them, a fall seen, a
   friend gone, rest and care move it too, it shows on each card, and low or glad colours their lines).
9. **Places worth going to** (repeats play-test 6, item 5): the reading hall at Ondry's has no walls;
   every place with loot, a quest or a story; small houses, a family, a caravan, traders.
10. **Caves** to go into, like Pokémon's, and **heights** on the land, which is flat. Caves built
    ([D282](06-decisions.md)): a mouth on about three hill tiles in ten, a place of its own behind it with bands,
    a keeper and a cache. Heights built: the wind scarp's shelves ([D308](06-decisions.md)), the cloud peak
    three heights up ([D321](06-decisions.md)), and rises of the land's own floor on every tile, a height up
    with a rock face below, climbed only at a slope, more on hills and crag ([D332](06-decisions.md)). Ladders that
    climb two heights, and a Climbing Rope that scales any face a height up ([D337](06-decisions.md)).
    Six hamlets to come upon, a sheepfold, a mill and salt pans, each with folk who sell, a job and a trouble
    ([D333](06-decisions.md)). Two caravans that walk between the towns, one selling the makings of runes
    ([D334](06-decisions.md)).
11. **Seeing, not reading**: Sennet as a ghostly blue figure when he speaks from afar (built,
    [D265](06-decisions.md): his figure beside the lead in blue light, his face the same in the box); walking
    into a gate or the grove, not cut to it (a gate built, [D354](06-decisions.md): the company walks into its
    doorway and fades as the screen goes dark, and the floor inside comes up out of the dark; the grove
    built, [D360](06-decisions.md): the company walks in among the nearest trees and fades, and the grove comes up
    out of the same dark); the chapter visions shown as pictures.
12. **A play screen you arrange** (grows play-test 6, item 7): panels moved, resized and coloured; the
    journal open at the side while the game keeps going (built, [D271](06-decisions.md): N opens it down the
    right, the game going on; Full page puts it over everything). Moving and resizing panels: built ([D351](06-decisions.md)), as play-test 8's ask 7.
13. **Sound and music**: a big music update; a sound for every monster; better effects.
14. **A writers' pass** over every line every character says. Built ([D274](06-decisions.md)): about 430 of 3,850
    lines rewritten, the rules for new lines in [13](13-heroes-and-tempers.md#the-lines).
15. **The frame rate walking Stormreach** ("massive frame rate drop"): built ([D263](06-decisions.md)). The
    townsfolk's ways and a land's first page were the costs found; the play log now writes a line when ten
    seconds run under 40 fps (`frame rate 31 fps, slowest frame 180 ms, at Stormreach`), so the next play-test
    says what his machine does.

### Play-test 8's asks

What `doug-md` asked for in play-test 8 ([transcript](worldbuilding/voice-notes/2026-10-21-doug-md-play-test-8.md))
that needs more than a fix, **planned**, in the order of call BX ([D325](06-decisions.md), 2026-10-21): 4, 6, 10 and
11 now (held until milestone B is in); after B the 2× cap (built, [D329](06-decisions.md)), 3 (built, [D330](06-decisions.md)) and 5 (built, [D331](06-decisions.md)); later 2, 8, 9 (art from 27 October) and 1. Already done: the first fixes
([D324](06-decisions.md)): a fighter taken off the field seen to go, food eaten not drunk, foes' moves
loaded ahead. Some repeat earlier asks (noted).
1. **The opening cinematic**, "a major update".
2. **More to say**: the same four lines (who are you, have you been up the Tower, any advice, goodbye) on
   everyone; far more for the people met in the Tower. **Built** ([D341](06-decisions.md)): each of the seven
   companies speaks in its own voice on the road, resting on a floor and climbing a shared floor beside the
   party (which it now waits on, by the way in, to talk); the party asks its questions a few ways; two more
   only that company is asked, and two drawn from where it is met and fitted to the floor; the folk living
   on a floor have eight more things to say between them, the host and the trader two each.
3. **A nemesis system** after Shadow of Mordor: people remember what you did, hold grudges or thanks, and
   some come for you. A first version is built and hidden for the First Hour ([D97](06-decisions.md):
   `nemesis` in `first_hour.hidden`, a broken band's survivor who takes an epithet and comes back). **Built**
   ([D330](06-decisions.md)): back in the game, a survivor a level up each return and finished when beaten again;
   an errand's giver who remembers meets the company on the road with thanks and coin.
4. **Letting people go**: disband a companion so they go their own way in the world. **Built** ([D326](06-decisions.md)):
   Let go beside each card, asked once, gone from the roster.
5. **A hunger bar** under every member, and **Auto eating and using what it carries** when it needs to. **Built**
   ([D331](06-decisions.md)): a thin bar under each health bar, hungry after about three days on the land, starving
   hurts but never fells; food eaten whole when hungry, a bed fills everyone, Auto eats under the line.
6. **A quick wheel** on a held middle click, after Ark Survival Evolved's (eat, send a party, and so on)
   instead of the whole menu (grows formations' "the wheel on a held key", [D305](06-decisions.md)). **Built**
   ([D326](06-decisions.md)): held still 0.3 s, Eat, Party, Send away, Formation, Map, Journal and Auto on the land; Eat, Stance and Auto in a fight.
7. **Text boxes sized right, and panels moved and resized** in the game (repeats play-test 7, item 12). **Built**
   ([D351](06-decisions.md)): Arrange the Screen in the menu (or Arrange on the quick wheel) frames the place's name,
   the compass, the company, the corner map, the log, the hint line and the box people talk in; drag one to move it,
   the log's corner to size its box, the wheel over any to grow it and its words; kept until Put It All Back.
8. **More buildings to go into** in the city; most doors are shut. **Built** ([D342](06-decisions.md)): six more
   doors open, the Cathedral of the Ascent (a blessing before the climb), the apothecary, the smithy (an edge
   on your weapons), the old shrine, the ruined bathhouse and the Sign of the Fish, each with its people.
9. **Groves that look like groves**, hard to find, with good things in them, even if their keeper has to be fought.
10. **A sent-away band seen on its way**: how far off and how long until it is back ([D294](06-decisions.md)'s band on the map).
    **Built** ([D326](06-decisions.md)): tiles off and steps to come, under the cards and beside its face on the map.
11. **Getting the fallen up**: when one goes down, one of the rest goes to them while the others fight on,
    and the formation closes round it. **Built** ([D326](06-decisions.md)): the nearest free member goes unasked, the rest
    turn on the foe nearest the fallen.

### Gates that grow

Play-test 7's first ask, built ([D261](06-decisions.md), agenda 172). Inside, a gate is ground of its own
kind, the kind of the land it stands on for its first floor (ten kinds in `gate.inside.grounds`); a deeper
floor of a C gate or bigger is another kind. It grows by rank: E one floor of three chambers up to S five
floors of seven, a second band in half the chambers from B. On each floor but the last the way down opens
only when every band on it is down; on the last, its keeper's fall scatters the rest. A shut gate lies
broken where it stood, three folk round it cheering.

How long a gate takes, by `tools/gate_clock.tscn` (Juno leading Pluto, Vesta and Atlas at the rank's
level, Auto walking, headless at 5× and read back at 1×; 2026-10-19, before the keeper's toughness was cut
to the numbers in D261). A gate's foes stand at the party's level or the rank's, whichever is higher,
plus the floor's depth (`Encounter`; a B gate or bigger lower since [D273](06-decisions.md)), so raising
the party (`--above`) does not make it easier.

| Rank | Floors | Walked to the end | Fights | Longest fight |
| --- | --- | --- | --- | --- |
| E | 1 | shut, 0:36 to 0:47 | 2 | 0:18 |
| D | 2 | shut, 1:33 | 5 | 0:12 |
| C | 3 | shut, 3:49 to 5:28 (one in four runs lost Juno) | 10 to 12 | 0:35 |
| B | 3 | shut once in 6:24 (18 fights, four levels up); else Juno fell at 2 to 7 minutes | 1 to 19 | 1:10 |
| A | 4 | Juno fell, or a fight lost, at 2 to 10 minutes; never shut | 1 to 10 | 0:59 |
| S | 5 | still on floor 3 or 4 when lost, at 10:05 to 15:01 | 15 to 22 | 4:37 |

What it says: an S gate already runs past Ewan's 10 to 15 minutes before its keeper, and its deep fights
already run minutes; the keeper's fight was not reached in any run, so its 5 to 7 minutes is not measured.
And in the clock, a party of four at the rank's level loses its lead in most B, A and S gates, even put back
to full health after every fight (`--rested`), which main does too (B: Juno fell in the first fight; A:
after eight). That is the opposite of Ewan's hand (58 fights won, mostly E and D gates), and it is for the
monster tiers and the dangerous ground fights to settle. Two runs stopped with nothing moving, both after a
fall: a companion falling mid-fight, and the whole party down outside a fight with Juno still standing.

**Big gates pitched** ([D273](06-decisions.md), agenda 184, issue #357). Most of the lost leads above came from
the clock: it raised the party to the rank's level and left them on their starting gear. The clock now gives
each the best piece a player of that level could have bought (`--bare` for the old way). Geared, B gates as
they stood still lost the lead in 2 of 4 runs, and the gate monsters' tiers ([D270](06-decisions.md)) made A
gates harder. So a big gate's bands now stand lower (`gate.pitch`): B 2 levels down, A and S 4 down, half a
level a floor; E, D and C as before. Measured on main with the tiers, rested, Auto, seeds 77, 5, 9 and 11:

| Rank | Before (bare) | Geared, as they stood | Geared and pitched |
| --- | --- | --- | --- |
| B | lead fell 4 of 4 | shut 2 of 4, lead fell 2 | shut 3 of 4, lead fell once (second fight) |
| A | lead fell 1 of 1 | lead fell 2 of 2 (after the tiers) | shut 1 of 3, lead fell once, keeper's fight lost once |
| S | | | shut 2 of 2 (38 to 41 fights) |
| C | | | shut (10 fights) |

Where the lead still falls, foes pile onto whoever leads, and Juno (a `keeper`, fighting from behind) backs
off alone to the edge of the ground and falls there; that is fighters' behaviour, not a gate's pitch, and is
left as its own piece. Four clocks shared one machine, so their 1× times run long and are not given here.

**The party keeps together** ([D281](06-decisions.md), agenda 192). The piece above, built: the company
comes to a hurt lead, keeps within 3 tiles of each other, and stands against a foe already hitting them.
Measured the same way (geared, pitched, seeds 77 and 5), with it and with it turned off (`keep_together`):
B gates shut 4 of 4 either way; A gates shut 1 of 2 with it, 0 of 2 without (the lead fell in both).
Where Juno still fell, she fell beside Vesta and Atlas, to two or three foes at once in a few seconds;
Vesta's Mend heals 15 against Juno's 504 at level 17, which is the next piece.

**Heals keep pace** ([D284](06-decisions.md), agenda 195). A mend now heals 10% more for every level past 3.
Measured with a party of four (Juno, Vesta, Pluto, Atlas) against four and five of the land's foes, twelve
fights each, with it and with mends flat: level 3 the same to the blow; level 9 the same; level 17 against
five, every fight won and the lead never down with it, one lost and the lead down without (the company
ending at 72% of its health against 68%). The gate clock (A gates, two runs each) could not tell them
apart: one shut and one stuck either way, the stuck runs Auto halting after a fall ([D261](06-decisions.md)).

**Something on the road every few minutes** ([D286](06-decisions.md), agenda 197). The fun review's walk from
the crater to the gate had nothing in it for seven minutes: a roadside scene rested 40 steps and then came
one step in twenty, and the walk is 25 to 30 steps. The road now keeps a clock: 3 steps in, then every 6 to
9, a band waiting on the road ahead, a roadside scene, a traveller with a line, or something left by the
road. Self-played as Atlas at 2× (seeds 77 and 2, four minutes each), before and after:

| Seed | Before | After |
|---|---|---|
| 77 | nothing on the road; the gate at 2:00 | a band (fought and won on the road), a traveller, a second band, a find; the gate at 2:00 |
| 2 | nothing on the road; the gate at 2:30 | a find, a roadside scene (walked by), a band; the gate at 2:30 |

Auto walking itself keeps to its way, so a band it does not walk into is gone round; a player walking by
hand sees it on the road and chooses. Both runs then stood at the Tower's door with Auto stuck there, the
same before and after.

## Music the hour still needs

The fan covers are out of every build ([D100](06-decisions.md)). The hour plays on Ewan's two
Ableton tracks and, until his cues arrive, five stand-ins made in code by `tools/make_music.py`
([D185](06-decisions.md)), all in D minor and sharing the memory theme's first notes, A D C A. What
plays where (`data/music.json`: a scene's set, a place's over it, a dialogue's over both).
Every itch build up to `3fe49a5` was silent in the browser, phone and desktop alike: the buses were made at
runtime, which the browser build never sounds ([D234](06-decisions.md)). `1daa322` is the first build with sound.

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
| 2026-10-17 08:26 | `3fe49a5` | Atlas's last stand as a new player's first game ([D191](06-decisions.md)), fight tactics on every side ([D187](06-decisions.md)), a slightly harder hour ([D188](06-decisions.md)), the quest list ([D190](06-decisions.md)), the Warden speaks and counts ([D184](06-decisions.md)), a word carried between lives ([D183](06-decisions.md)), in-house music and two fight sounds ([D185](06-decisions.md)), life on the land ([D179](06-decisions.md)), Muck Muck and Sinner ([D176](06-decisions.md)), copper coins ([D177](06-decisions.md)), play-test 3 and 4 fixes ([D178](06-decisions.md), [D189](06-decisions.md)) |
| 2026-10-17 17:40 | `1daa322` | Sound in the browser at last ([D234](06-decisions.md)), New Game offers to skip the last stand when a save exists ([D235](06-decisions.md)), moves you can see land ([D192](06-decisions.md)), stances, a smarter Auto, people and bands on the road, fights beside the Watch, a map over the ground, footpaths and signposts, scars, keeper prizes, treasure maps, harder upper floors, Ewan's play-test fixes, his answers to the founders' questions |
| 2026-10-18 11:22 | `ba09ffb` | A journal for each land with a trinket for finishing it, Stormreach walked outside ([D247](06-decisions.md)), gates you go inside and walk floor by floor ([D248](06-decisions.md)), a small company panel and a list of what wants attention while you walk, a ? on each path card, phones fit better on their side and upright, play-test 6's first fixes ([D246](06-decisions.md)) |
| 2026-10-18 22:06 | `e5628b9` | The Second Hour: floors 6 to 10 with chapter twos and the Keeper of the Tenth ([D254](06-decisions.md)), no slimes above floor 5 ([D243](06-decisions.md)), the world remembers what you did ([D249](06-decisions.md)), a story for every companion ([D250](06-decisions.md), [D256](06-decisions.md)), inns with rooms ([D242](06-decisions.md)), a house in Stormreach ([D252](06-decisions.md)), your own town at the crater ([D251](06-decisions.md)), coins in four metals ([D253](06-decisions.md)) |
| 2026-10-21 10:05 | `6f8fcf6` | Play-test 8's build, main after #387: fights that run on the open land and first strike with G, five tiers of every monster, gates that grow, caves under the hills, your own people sent into gates from each card's Send button, moods and crafting, the climbers' stone, Sennet as a ghost, the journal at the side, a writers' pass and a seven-step tutorial (#331 to #387, meeting six's [D287](06-decisions.md) to [D299](06-decisions.md)) |
| 2026-10-21 17:25 | `1548179` | Main after #432, the opening cinematic remade: three acts with the lead's chapter-one object falling with them and Bram's "Give me your hand." ([D328](06-decisions.md), [D340](06-decisions.md)); levels only from new foes in gates, with a log of foes for each of the company (milestone B, [D301](06-decisions.md)); formations, a leader who rises, the Tower past floor 10, heights, wild places and their quests, a fight you can walk out of ([D304](06-decisions.md) to [D321](06-decisions.md)); play-test 8's fixes and asks ([D324](06-decisions.md), [D326](06-decisions.md)); enchanting ([D327](06-decisions.md)); hand fights start at 2× at most ([D329](06-decisions.md)); the nemesis back ([D330](06-decisions.md)); hamlets, caravans, herbs, ladders and rope, Charisma and orders ([D332](06-decisions.md) to [D339](06-decisions.md)); the Tower's people's lines ([D341](06-decisions.md)); six more Stormreach doors ([D342](06-decisions.md)) |
| 2026-10-22 00:10 | `c5b5ac1` | Main after #464, Will's push after the queue: high ground in a fight and heights on the map ([D343](06-decisions.md)); somewhere for PixelLab's art to land ([D344](06-decisions.md)); sellswords at the Gilded Flagon ([D345](06-decisions.md)); crafting by a fire and at a smithy ([D346](06-decisions.md)); deeper moods ([D347](06-decisions.md)); a band sent to clear a wild place ([D348](06-decisions.md)); hunger with a bar under every member ([D331](06-decisions.md)); Send on Auto ([D349](06-decisions.md)); the play screen arranged by hand ([D351](06-decisions.md)); the fallen searched after a fight ([D352](06-decisions.md)); wares with pictures ([D353](06-decisions.md)); gates walked into ([D354](06-decisions.md)); creatures that fit their land ([D355](06-decisions.md)); armour beside the weapon and an equipment screen ([D357](06-decisions.md)); the second writers' pass ([D350](06-decisions.md)) |
