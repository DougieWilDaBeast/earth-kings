# 25 — The opening

**Built 2026-10-12** (on `feat/body-scale`, pushed after its pull request had merged, so it reached the game on 2026-10-14, [D88](06-decisions.md)) at `doug-md`'s request: "a cinematic at the start of a new game that
incorporates everything that we have discussed as how we want the game to be".
A **New Game** plays it once the lead is picked (in the temper quiz or from _Show me all
sixteen_), and the lead picked is the one seen landing and waiting at the fire; then the run
begins on the landing in the world (`data/fall.json` → `landing`) as before. The next world after a
death, and the tutorial, do not play it.

- **Words and cast:** `data/opening.json`. Rewrite any line there; no code needed. `time` is how
  long a shot holds, shared evenly between its lines.
- **Pictures:** `src/ui/opening.gd`, drawn from the game's own sprites (`art/sixteen/`, the party and
  the ogre from `units.json`, the Tower, a town, a keep, a gate, the campfire) and plain shapes, so it
  needs no art made for it. A new kind of picture needs code.
- **Controls:** click, tap, Space or Enter moves to the next shot; **Esc** (or a phone's back key) skips to the world. About
  eighty seconds if left alone.
- **Tested** in `tests/wishlist_smoke_test.gd` (`_check_opening`): every shot can be drawn,
  everyone in it has a sprite, the lead it is handed is the one who falls, it ends on its own and starts the run, Esc skips, and
  the quiz plays it only after a New Game.

## The shots

| # | Shot | What you see | What it stands for |
| --- | --- | --- | --- |
| 1 | void | A light growing in the dark | The contest ([17](17-the-sixteen-worlds.md)) |
| 2 | sixteen | The sixteen in a ring, lighting up one by one | The sixteen half-gods ([21](21-the-sixteen-first-draft.md)) |
| 3 | worlds | Sixteen worlds, each with a Tower; all but one dim | Sixteen copies of Earth; only one survives |
| 4 | fall | Sixteen streaks falling | The fall, and forgetting |
| 5 | impact | One lands: flash, shockwave, a smoking furrow, a body | The landing, where your home is ([D53](06-decisions.md)) |
| 6 | tower | The Tower over the land, its chapter lights | A hundred floors; memory back by the chapter ([D48](06-decisions.md), [D53](06-decisions.md)) |
| 7 | living | Two towns, people going between, a gate glowing until it breaks | A living world; deadlines that can be missed ([D60](06-decisions.md)) — **planned** |
| 8 | company | Six of the sixteen joining one by one; one fades | Up to six ([D60](06-decisions.md)); permadeath |
| 9 | fight | A fight that freezes, a box dragged over the party, then hits | Real time with pause ([D58](06-decisions.md)), drag to select |
| 10 | end | Your world going dark, your weapon streaking into the next, your ghost at the fire | Death ends a world; you go on as another; the weapon lands anywhere ([D60](06-decisions.md)) |
| 11 | title | EARTH KINGS over the Tower | The standing quest: Ascend to heaven |

Shot 7 shows what the founders have asked for but the game does not do yet: it is the game as it is
meant to be, which is what was asked for. Two more shots, a carriage ambushed on a long road (carriages
and road events, agenda item 60) and an ogre rising with the scar you gave it (foes who remember you,
item 61), were cut for the First Hour ([D97](06-decisions.md)); their pictures are still drawn by
`road` and `foe` in `opening.gd`, and they come back with their systems. The cast is the sixteen: the
company is six of them, and a run with no pick shows Atlas falling, as it plays him ([D95](06-decisions.md)).