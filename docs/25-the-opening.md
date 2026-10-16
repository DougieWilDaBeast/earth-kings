# 25 — The opening

**Built 2026-10-12** (on `feat/body-scale`, pushed after its pull request had merged, so it reached the game on 2026-10-14, [D88](06-decisions.md)) at `doug-md`'s request: "a cinematic at the start of a new game that
incorporates everything that we have discussed as how we want the game to be".
A **New Game** plays it once the lead is known (Atlas, the first life, [D106](06-decisions.md); later
in the temper quiz or from _Show me all sixteen_), and the lead is the one seen landing and waiting at the fire; then the run
begins on the landing in the world (`data/fall.json` → `landing`) as before. The tutorial does not
play it.

**Every life after the first plays it again** ([D135](06-decisions.md)): after a death the quiz
picks the next lead, and the opening plays before they land, a little changed for who is left, until
only one of the sixteen is. It plays only the story shots (`replay` in `opening.json`: void,
sixteen, worlds, ending, fall, impact, end and title, about 55 s); the how-to-play shots were seen
on the first life. The fallen stand grey in the ring and never light; their worlds are dark in the
worlds shot; the ending shot shows the lead who has just died, with the worlds before theirs dark
behind it, and says how they fell (on which floor, or to what on the road), from the record of the
sixteen (`src/chronicle/sixteen.gd`). `by_left` swaps whole shots' lines for three stages: many left
("Fifteen are still standing"), two left ("Of the two left, one is you") and the last ("There is
nobody after you", every fallen lead at the fire, "The last standing quest"). The words are
**Inferred**.

**The ending shot says what the death cost** ([D153](06-decisions.md), the creatives' meeting's C5).
If the lead who just died had found their chapter one, it says what they had just remembered
("Atlas fell on floor 3 of the Tower. He had just remembered a courtyard, and a gift."); if not,
that they never found out ("Cato fell on the road, to an ogre, and never learned what he carried
down."). The phrases are `remembered` in `opening.json`, the two lines are `fell`, and the world
record keeps `remembered` (`src/chronicle/siblings.gd`). When the new lead is the other half of a
tie with the one who just died, the impact shot gains one line for the pair (`pairs`): Ultor after
Bellona hears "Somewhere a whistle stops blowing." Six lines, one each way for Bellona and Ultor,
Cassius and Caesar, Ares and Liber; none names the tie (Will, call AH).

- **Words and cast:** `data/opening.json`. Rewrite any line there; no code needed. `time` is how
  long a shot holds, shared evenly between its lines. `ending` names whose world is seen ending in
  the `ending` shot (`{other}` in a line is their name).
- **Pictures:** `src/ui/opening.gd`, drawn from the game's own sprites (`art/sixteen/`, the party and
  the ogre from `units.json`, the Tower, a town, a keep, a gate, the campfire) and plain shapes, so it
  needs no art made for it. A new kind of picture needs code.
- **Controls:** click, tap, Space or Enter moves to the next shot; **Esc** (or a phone's back key) skips to the world. About
  ninety seconds if left alone.
- **Tested** in `tests/wishlist_smoke_test.gd` (`_check_opening`): every shot can be drawn,
  everyone in it has a sprite, the lead it is handed is the one who falls, it ends on its own and starts the run, Esc skips, and
  the quiz plays it only after a New Game; a second, a two-left and a last life play the replay
  shots with the right count, the right dead lead, how they fell and what they remembered, and Ultor
  after Bellona hears the whistle stop (`_check_opening_again`).

## The shots

| # | Shot | What you see | What it stands for |
| --- | --- | --- | --- |
| 1 | void | A light growing in the dark | The contest ([17](17-the-sixteen-worlds.md)) |
| 2 | sixteen | The sixteen in a ring, lighting up one by one | The sixteen half-gods ([21](21-the-sixteen-first-draft.md)) |
| 3 | worlds | Sixteen worlds, each with a Tower; all but one dim | Sixteen copies of Earth; only one survives |
| 4 | ending | Another of the sixteen (Bellona, or the next of the sixteen when Bellona leads) on their world as it cracks and goes dark | Death ends a world, shown before it is lived ([D99](06-decisions.md), [D101](06-decisions.md)) |
| 5 | fall | Sixteen streaks falling | The fall, and forgetting |
| 6 | impact | One lands: flash, shockwave, a smoking crater, a body | The landing, where your home is ([D53](06-decisions.md)) |
| 7 | tower | The Tower over the land, its chapter lights | A hundred floors; memory back by the chapter ([D48](06-decisions.md), [D53](06-decisions.md)) |
| 8 | living | Two towns, people going between, a gate glowing until it breaks | A living world; deadlines that can be missed ([D60](06-decisions.md)) — **planned** |
| 9 | company | Six of the sixteen joining one by one; one fades | Up to six ([D60](06-decisions.md)); permadeath |
| 10 | fight | A fight that freezes, a box dragged over the party, then hits | Real time with pause ([D58](06-decisions.md)), drag to select |
| 11 | end | Your world going dark, your weapon streaking into the next, your ghost at the fire | Death ends a world; you go on as another; the weapon lands anywhere ([D60](06-decisions.md)) |
| 12 | title | EARTH KINGS over the Tower | The standing quest: Ascend to heaven |

Shot 8 shows what the founders have asked for but the game does not do yet: it is the game as it is
meant to be, which is what was asked for. Two more shots, a carriage ambushed on a long road (carriages
and road events, agenda item 60) and an ogre rising with the scar you gave it (foes who remember you,
item 61), were cut for the First Hour ([D97](06-decisions.md)); their pictures are still drawn by
`road` and `foe` in `opening.gd`, and they come back with their systems. The cast is the sixteen: the
company is six of them, and a run with no pick shows Atlas falling, as it plays him ([D95](06-decisions.md)).