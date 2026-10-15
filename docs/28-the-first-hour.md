# 28 — The First Hour

**What a new player plays today, start to finish, and how it got that way.** The First Hour is the
only milestone until it is done ([D95](06-decisions.md)); everything else built is hidden behind
`data/world_rules.json` → `first_hour.hidden` ([D97](06-decisions.md)). The order of work and what
is next is in the [roadmap](05-roadmap.md#next-steps-in-order); this doc describes what exists.

## The route

1. **New Game.** No quiz on the first life: the lead is Atlas (`first_hour.first_life`), on the
   **First Hour** setting, where a fall is for good ([D104](06-decisions.md), [D106](06-decisions.md)).
   The opening plays ([25](25-the-opening.md)).
2. **The crater.** Atlas comes down with Sky in a scorched crater ([D134](06-decisions.md)) 12 to 16
   tiles from Stormreach ([D101](06-decisions.md)). Bram pulls him out. Five boxes, then he walks
   ([D122](06-decisions.md)).
3. **The road.** A cobble road runs from the crater to the great city, on to the first gate and back
   to the Tower ([D126](06-decisions.md)). The compass and Auto point the way: town, then the Guild at
   the Tower's door, then the first gate, then the Tower ([D96](06-decisions.md), [D107](06-decisions.md)).
   Bands met on the land are fought on that ground with no change of screen ([D98](06-decisions.md));
   on the road itself they are brigands, poachers, cabin hands and cutpurses ([D144](06-decisions.md)).
   Lands blend where they meet ([D128](06-decisions.md)); the jungle and the barrow downs on the way
   have their own ground, drawn in house ([D140](06-decisions.md)); scenery stands by rule
   ([D130](06-decisions.md)), and the roadside scenes stand on the road ([D131](06-decisions.md)).
4. **Stormreach and the Guild.** The great city stands at the Tower's foot, paved in sandstone
   ([D136](06-decisions.md)). The first time the party stands at the Tower's door the Guild's register
   opens by itself; Sennet keeps it ([D107](06-decisions.md), [D112](06-decisions.md)). Nobody climbs
   until a gate is shut ([D101](06-decisions.md)). A market lays out three wares: Z turns to the next,
   B buys the one in hand ([D146](06-decisions.md)).
5. **The first gate.** Greyhollow, rank E, eight tiles from the city and open in every world. E beside
   it goes in; walking onto it does not ([D116](06-decisions.md)). Its plaza runs up to its gate, a
   standing doorway of rune stones with the gate's light turning in it ([D137](06-decisions.md),
   [D141](06-decisions.md)). Shutting it gives the Guild's mark.
6. **The Tower.** A door drawn in house with lit rune stones up the yard ([D111](06-decisions.md)), a
   stand-in shaft over it until art A9 ([D108](06-decisions.md)), seen from far off beside the way ahead
   rather than over it ([D142](06-decisions.md)), the yard paved plainly
   ([D133](06-decisions.md)). "E to climb" at the door.
7. **Floors 1 to 5**, each walked ([D102](06-decisions.md)) and each its own shape: a pillared hall,
   a ring round a core, a split floor, zigzag terraces, the keeper's room ([D114](06-decisions.md)),
   dressed as a tower with a stair and lit runes ([D129](06-decisions.md), [D132](06-decisions.md)). Each floor brings a kind of foe not met on the one before, and floors 1 to 4 carry none of the
   sprites docs/22 marks dev only ([D143](06-decisions.md)).
   E at the stair goes straight to the next floor; only floor 5, its keeper beaten, brings the party
   back out to the yard ([D115](06-decisions.md)). Auto climbs too ([D127](06-decisions.md)). Floor 5
   is kept by the Warden of the Fifth, an armoured figure with a glaive whose big swing shows before
   it lands, drawn in house ([D156](06-decisions.md)).
8. **Chapter one.** In floor 5's west alcove, before the keeper, lies the lead's own keepsake
   ([below](#the-chapter-ones)). Picking it up plays their chapter one and writes it in the journal
   ([D103](06-decisions.md)).
9. **A death.** The death screen has Ascend selected ([D105](06-decisions.md)); the world ends, the
   quiz picks the next of the sixteen ([D110](06-decisions.md), naming tempers, not their letters, [D144](06-decisions.md)); while some leads have no
   chapter one yet, it deals only those who do ([D145](06-decisions.md)), and the opening plays again for who is
   left, story shots only ([D135](06-decisions.md)).

**How hard.** The First Hour setting sits just easier than Even: foes two levels down, half healed
after a fight, about a level a fight, the floor 5 keeper at level 7 ([D113](06-decisions.md), kept
by [D117](06-decisions.md)). **Saves**: on walking into a town or the city, opening the register,
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
| 2026-10-15 evening | Ewan's play-test 3, PC and phone | `4196128`, or `9f1b267` if he began before 20:25 UTC | Waiting for his play log and notes; then meeting 5 ([D124](06-decisions.md)) |

## Builds on itch.io

The browser build goes to `dougie`'s itch.io page (both the `html5` and `web` channels) only on
`dougie`'s word. The commit is the version, and this table is the marker for which build a play-test
played: `git checkout <commit>` gives it back.

| Pushed (UTC) | Commit | What it carried |
| --- | --- | --- |
| 2026-10-13 | main | The first browser build on the page |
| 2026-10-14 22:30 | `ffcd508` | First Hour steps 1 to 4, the pillars ([D99](06-decisions.md)), the fan covers out ([D100](06-decisions.md)) |
| 2026-10-15 07:26 | main after #127 | The gamers' week: First Hour setting, Ascend first, Atlas first, sixteen quiz answers ([D104](06-decisions.md) to [D110](06-decisions.md)) |
| 2026-10-15 11:05 | `bdfdfc6` | Frozen for Ewan's play-test 2: door art, saves, harder hour, five floor shapes ([D111](06-decisions.md) to [D114](06-decisions.md)) |
| 2026-10-15 18:14 | `9f1b267` | Meeting 4's batches, the play log, the road, Auto climbs, biome edges, Tower floors, scenery by rule, the roadside drawn ([D115](06-decisions.md) to [D131](06-decisions.md)) |
| 2026-10-15 20:25 | `4196128` | The art hour (stair and runes, yard, crater, city paving, [D132](06-decisions.md) to [D137](06-decisions.md)), Cato's chapter one and the replayed opening ([D135](06-decisions.md)), seven more chapter ones ([D138](06-decisions.md)) |
