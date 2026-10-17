# 31 — What needs music, and in what order

**Planned.** `doug-md` asked for this on 2026-10-16 ([D186](06-decisions.md)): a list, to come back
to when the music is made, of which scenes actually need music and which come first. Ewan's two
Ableton tracks play on the road (`angelic.wav`) and in every fight (`bday_project.wav`). Five rows
have in-house stand-ins the team made in code until Ewan's own arrive ([D185](06-decisions.md),
`tools/make_music.py`): the memory theme (row 1), Stormreach (4), the Tower floors (5), the crater (8)
and the world ending (9); "Plays today" says which. The fan covers are out of every build
([D100](06-decisions.md)). Every itch build before `1daa322` (2026-10-17) was silent in the browser
([D234](06-decisions.md)), so the stand-ins are first heard there: `dougie` keeps or drops each (#218), and
`doug-md` gives a word on each in play-test 5 (#219).

**How the order was set.** Ewan's word first: the memory theme leads ([30](30-questions-for-the-founders.md),
question 13). After it, `dougie`'s rule ([D175](06-decisions.md)): the stretches a player runs through
longest come first, because a track heard for twenty minutes matters more than one heard for twenty
seconds. The creatives' six cues ([28](28-the-first-hour.md#music-the-hour-still-needs)) are all in
here, placed by that rule. **Inferred**: the order after the memory theme, the lengths and the moods
are the build's proposal, for the founders to change (agenda row 115).

## The list

"Heard" is roughly how long a player of the First Hour spends with it, from the play-tests and the
eight bot runs ([28](28-the-first-hour.md#how-it-was-tested)).

| # | What | Where in the game | Heard | Plays today | What it should feel like | Shape |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | **The memory theme** | Every chapter one (the keepsake on floor 5); its phrase is borrowed by 6, 8 and 9 | 2 to 3 min a life, every life | `memory_theme` (stand-in) | One instrument, a short phrase that stops dead on "White.", then a held note | 40 to 60 s, not looped |
| 2 | **The road** | Walking the land between places: most of the hour | 20 to 30 min | `angelic` | Travel: steady, open, a little lonely; never tiring on the twentieth loop | 2 to 3 min loop |
| 3 | **A fight** | Every band met on the land, every gate fight | 8 to 12 min, in pieces | `bday_project` | Drive and danger; starts strong, since a fight starts at once | 1.5 to 2 min loop |
| 4 | **Stormreach** | The great city at the Tower's foot, the Guild, the market | 5 to 8 min | `stormreach` (stand-in) | Busy and crowded, the Tower's motif under it | 2 min loop |
| 5 | **The Tower floors** | Floors 1 to 4 | 5 to 8 min | `tower_floors` (stand-in; fights: `bday_project`) | Slow, lower and darker than the road; a layer more each floor if that is easy | 2 min loop |
| 6 | **The keeper** | The floor 5 fight, the Warden of the Fifth | 1 to 3 min | `bday_project` | The hour's last fight: bigger than 3, the memory phrase hidden in it | 1.5 min loop |
| 7 | **The title** | Title card and menus, the quiz | under a minute each time | `angelic` | Can stay `angelic`; a theme of the game's own later | keep for now |
| 8 | **The crater** | The landing, Bram pulling the lead out | 1 to 2 min, every life | `crater` (stand-in) | Near silence: wind and fire, the memory phrase once, far off, when Bram speaks | ambience, not a song |
| 9 | **The world ending** | The death screen, Ascend | under a minute | `world_ending` (stand-in) | The memory phrase, broken off early | 20 to 40 s |
| 10 | **The opening and its replay** | The film at New Game, and the shorter replay after a death | 1 to 2 min | `angelic` | Thinner each time, as fewer of the sixteen are left (many, two, the last) | three versions of one piece |
| 11 | **Inside** | The inns and halls ([D81](06-decisions.md)) | a few minutes | `angelic` (the `hearth` set) | Warm, low, a room with people in it | 1.5 min loop |

## Short pieces, later

Not songs: a few seconds each, played over whatever is playing. They come after the list above.

- **A gate shutting**, and its light opening onto another lead's world ([D152](06-decisions.md)).
- **A level gained** ([D77](06-decisions.md)), the keepsake picked up, the Guild's mark given.
- **A fight won, a fight lost.**
- **One of the sixteen's lights going out** in the Tower ([D149](06-decisions.md)).

## Variations, later still

- **The road by land**: the same road theme with a different instrument or layer for snow, desert,
  swamp, ash and the strange lands ([D71](06-decisions.md)), so a new land is heard as well as seen.
- **Night** on the road, if night comes to matter.
- **The cut list** when it comes back ([D168](06-decisions.md)): coliseum (can share 3), training
  ground (can share 2), museum and credits (can share 7).

## What does not need its own music

- **The journal, the map, the party screen and the menu**: what was playing carries on, quieter.
- **Talking**: the music dips under the words rather than stopping.
- **The quiz and choosing the next lead**: the title's music.

## When a track is made

Put it in `audio/music/` (WAV or OGG, 44.1 kHz) and say which row it is for; the team wires it with a
set in `data/music.json` and the scene it belongs to. A loop should end where it can start again
without a jump. Credit is "Ewan" ([D175](06-decisions.md)) until he gives another name.
