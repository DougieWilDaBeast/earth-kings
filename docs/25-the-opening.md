# 25 — The opening

**Built 2026-10-12** (on `feat/body-scale`, pushed after its pull request had merged, so it reached the game on 2026-10-14, [D88](06-decisions.md)) at `doug-md`'s request: "a cinematic at the start of a new game that
incorporates everything that we have discussed as how we want the game to be"
. It plays after **New Game** and before the temper quiz, then hands over
to it; the landing in the world (`data/fall.json` → `landing`) follows as before.

- **Words and cast:** `data/opening.json`. Rewrite any line there; no code needed. `time` is how
  long a shot holds, shared evenly between its lines.
- **Pictures:** `src/ui/opening.gd`, drawn from the game's own sprites (`art/sixteen/`, the party and
  the ogre from `units.json`, the Tower, a town, a keep, a gate, the campfire) and plain shapes, so it
  needs no art made for it. A new kind of picture needs code.
- **Controls:** click, tap, Space or Enter moves to the next shot; **Esc** skips to the quiz. About
  a minute and a half if left alone.
- **Tested** in `tests/wishlist_smoke_test.gd` (`_check_opening`): every shot can be drawn,
  everyone in it has a sprite, it ends on its own and hands the quiz its payload, and Esc skips.

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
| 8 | road | A carriage on a long road, ambushed | Carriages and road events (agenda item 60) — **planned** |
| 9 | company | The party growing to six; one fades | Up to six ([D60](06-decisions.md)); permadeath |
| 10 | fight | A fight that freezes, a box dragged over the party, then hits | Real time with pause ([D58](06-decisions.md)), drag to select |
| 11 | foe | An ogre rising, taking a scar | Big units drawn big ([D57](06-decisions.md)); foes who remember you (item 61) — **planned** |
| 12 | end | Your world going dark, your weapon streaking into the next, your ghost at the fire | Death ends a world; you go on as another; the weapon lands anywhere ([D60](06-decisions.md)) |
| 13 | title | EARTH KINGS over the Tower | The standing quest: Ascend to heaven |

Shots 7, 8 and 11 show what the founders have asked for but the game does not do yet: they are the
game as it is meant to be, which is what was asked for.
