# 25 — The opening

**Built 2026-10-12** (on `feat/body-scale`, pushed after its pull request had merged, so it reached the game on 2026-10-14, [D88](06-decisions.md)) at `doug-md`'s request: "a cinematic at the start of a new game that
incorporates everything that we have discussed as how we want the game to be".
A **New Game** plays it once the lead is known (picked in the temper quiz or from _Show me all
sixteen_), and the lead is the one seen landing and waiting at the fire; then the run begins on the
landing in the world (`data/fall.json` → `landing`) as before. A new player comes to it straight
from **Atlas's last stand** ([D191](06-decisions.md)): Atlas has just fallen in Hearthwick, the quiz
has picked who comes next, and the opening plays **whole**, the how-to-play shots too, with Atlas's
world the one seen ending ("You have seen one of the worlds end already. Atlas fell in Hearthwick,
at the edge of his own village, and his world went dark with him. It never comes back.";
`last_stand` in `opening.json`, **Inferred**) and his ghost at the fire in the end shot.

**Remade 2026-10-21** ([D340](06-decisions.md)) from the storyboard `dougie` settled in call BZ
([D328](06-decisions.md); `/mnt/project-files/story/opening-cinematic-storyboard.md`), at `doug-md`'s
play-test 8 ask ("A major update to the cinematic opening scene needs to be done"): fourteen shots
in three acts (the contest, the fall, the climb), about 100 seconds, with a camera moving across every
shot. The lead lights last in the ring, in their own colour; the thing their chapter one turns on falls
with them and is found again on floor 5; a demon king's eyes open in a gate as another world ends; Bram
reaches into the crater; and the film ends on his "Give me your hand." under the title (W2).

**Every life after the first plays it again** ([D135](06-decisions.md)): after a death the quiz
picks the next lead, and the opening plays before they land, a little changed for who is left, until
only one of the sixteen is. It plays only the story shots (`replay` in `opening.json`: void,
sixteen, worlds, ending, fall, impact, tower, stair, end and title, each held `replay_pace` (0.8)
of its time, about 60 s); the how-to-play shots were seen
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
- **Camera:** each shot's `camera` in `opening.json` moves from `from` to `to`, each `[zoom, x, y]`
  with x and y the point looked at as a share of the screen (`"lead"` for the lead's spot in the
  ring), eased, and never showing past the picture's edge.
- **Pictures:** `src/ui/opening.gd`, drawn from the game's own sprites (`art/sixteen/`, the party,
  the ogre and Bram (`helper`) from `units.json`, the Tower, a town, a keep, a gate, the campfire)
  and plain shapes, so it needs no art made for it. A new kind of picture needs code.
- **Art asked for:** `objects` names each lead's chapter-one object and where its art goes (A58); a
  spark of the lead's own colour (`color` in `units.json`) stands in. `art` holds the demon king's
  gate (A59), the ring of light (A60) and the burning world (A61); each is drawn once its file exists,
  and the shapes stand in until then ([24](24-art-requests.md)).
- **Controls:** click, tap, Space or Enter moves to the next shot; **Esc** (or a phone's back key) skips to the world. About
  a hundred seconds if left alone.
- **Photographed** by `tests/opening_shot.tscn` (needs a display: `xvfb-run godot --path .
  --rendering-driver opengl3 res://tests/opening_shot.tscn`), every shot half way and near its end,
  into `.art_stage/opening_*.png`.
- **Tested** in `tests/wishlist_smoke_test.gd` (`_check_opening`): every shot can be drawn,
  everyone in it has a sprite, the lead it is handed is the one who falls, it ends on its own and starts the run, Esc skips, and
  the quiz plays it only after a New Game; a second, a two-left and a last life play the replay
  shots with the right count, the right dead lead, how they fell and what they remembered, and Ultor
  after Bellona hears the whistle stop (`_check_opening_again`).

## The shots

| # | Shot | What you see | What it stands for |
| --- | --- | --- | --- |
| 1 | void | A light growing in the dark; the camera pushes in | The contest ([17](17-the-sixteen-worlds.md)) |
| 2 | sixteen | The sixteen in a ring, lighting one by one; the lead last and brightest, in their own colour, and the camera moves to them | The sixteen half-gods ([21](21-the-sixteen-first-draft.md)) |
| 3 | worlds | Sixteen worlds, each with a Tower; all but one dim | Sixteen copies of Earth; only one survives |
| 4 | ending | Another of the sixteen (Bellona, or the next when Bellona leads) on their world as it cracks and goes dark; then a gate in the dark opens red eyes | Death ends a world, shown before it is lived ([D99](06-decisions.md)); what is left of its keeper waits in the gates of the others ([D328](06-decisions.md)) |
| 5 | fall | Sixteen streaks falling; the lead tumbling through the middle, their object falling beside them until it slips away | The fall, and forgetting; what you carried falls too |
| 6 | impact | One lands: flash, shockwave, a smoking crater, a body; Bram's hand reaches in | The landing, where your home is ([D53](06-decisions.md)) |
| 7 | tower | The Tower over the land, its chapter lights; near floor 5 a window flares in the lead's colour | A hundred floors; memory back by the chapter ([D48](06-decisions.md)) |
| 8 | land | A pan across the land: the city, a road with a carriage, a village, a band on red ground, a cave | A living world that will not wait |
| 9 | gate | A gate with its rank (E) over it; the camera pushes in and the screen goes dark | Gates are where you grow ([D303](06-decisions.md)) |
| 10 | inside | The company in a wedge, the first strike, then the world stopped and a box dragged over the party | Fights as you walk into them, a first strike, pause ([D288](06-decisions.md)) |
| 11 | company | Six joining one by one; one goes down and is lifted; another goes down and stays; five walk on | Up to six ([D60](06-decisions.md)); permadeath |
| 12 | stair | The lead climbing a stair to an alcove on floor 5, picking up their object; white | The Tower is where you prove it; chapter one |
| 13 | end | Your world going dark, your weapon streaking into the next, a scorched ring where it lands with a foe coming towards it, your ghost at the fire | Death ends a world; you go on as another; the weapon lands anywhere ([D296](06-decisions.md)) |
| 14 | title | EARTH KINGS over the Tower; "The standing quest: Ascend to heaven." and Bram's "Give me your hand." | The standing quest, and the first words of the landing (W2) |

The how-to-play shots (land, gate, inside, company) play on the first life only. Four older
pictures, `living` (two towns and a gate breaking), `road` (a carriage ambushed), `fight` and `foe`
(an ogre rising with the scar you gave it), are still drawn by `opening.gd` but no shot uses them;
the road and foe come back with their systems ([D97](06-decisions.md)). The cast is the sixteen: the
company is six of them, and a run with no pick shows Atlas falling, as it plays him ([D95](06-decisions.md)).
