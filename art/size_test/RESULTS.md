# Size test — results

Filled in as the test is done. Instructions: [docs/20](../../docs/20-pixellab-size-test.md).

## What it cost

Generated 2026-10-12 through the API (`tools/pixellab.py`), on the Tier 2 plan: 5,000
generations a month. The whole test cost **34 generations** (0.7 % of a month). Same prompt, view
(low top-down) and template (mannequin) as the 64s; "standard" mode unless the row says otherwise.

| # | Generated | Size | Directions | Frames | Generations | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `sworn_blade` | 32 | 8 | — | 1 | Comes back on a 48 × 48 canvas; the body is 19 × 34 |
| 2 | `goblin` | 32 | 8 | — | 1 | |
| 3 | `club_ogre` | 32 | 8 | — | 1 | A thin man with a club: the template is human-sized, so it is not hulking |
| 4 | `sworn_blade` | 16 | 8 | — | 1 | 24 × 24 canvas, body 10 × 17 |
| 5 | `goblin` | 16 | 8 | — | 1 | Reads as a person in a green shirt |
| 6 | `sworn_blade` attack, 32 | 32 | 4 (S E N W) | 9 a direction (8 asked + the start pose) | 4 | 1 a direction. Drifts: a round red shield appears halfway through |
| 7 | `sworn_blade` portrait | 128 | — | — | 15 | Made from the 32 body; 160 is not offered for this view |
| 8 | `sworn_blade` 32, **pro** mode | 32 | 8 | — | 10 | Extra, not in docs/20: closer to the prompt (mail, shield) but big-headed. Not in the viewer; see below |

**What that says about a month.** A body is 1 generation in standard mode, 10–25 in pro. An
animation is 1 a direction in standard (v3) mode, so the fighting set of six states on four facings
is about 24 a unit. Tier 1's eleven units would be roughly 11 bodies + 264 animation generations —
under 6 % of a month in standard mode.

**The 64s on disk are not what the API makes at 64.** They fill their 64 canvas (Bram is 49 × 59) and
look heroic and detailed. The API's standard mode at 32 makes a plainer, thinner figure on a bigger
canvas. Some of the difference between columns is the mode and the model, not only the size.

![battle scale](../../docs/images/size-test/generated-battle.png)
![same pixel size](../../docs/images/size-test/generated-pixel.png)
![crowd](../../docs/images/size-test/generated-crowd.png)
![portrait](../../docs/images/size-test/generated-portrait.png)

Bram: the 64 on disk, 32 standard, 32 pro, 16 standard, each drawn the same height:

![Bram four ways](../../docs/images/size-test/bram-standard-vs-pro.png)

The 32 attack, facing east, frame by frame:

![attack](../../docs/images/size-test/bram-attack-east.png)

The ogre at 16 was not generated (docs/20 says not to), so it is still a preview, outlined in red.

## The base body, 2026-10-12

The founders made a blank body in PixelLab on 2026-09-25, "Blank Male character". Dressing it as
Bram with one sentence (`python3 tools/pixellab.py dress sworn_blade`) kept his mail, surcoat,
beard, sword and kite shield in every facing, at about 65 pixels tall, for 10 generations. It is
in the viewer as the 64 Bram. Left to right: the base, dressed Bram in four facings, the 64 on disk.

![base dressed as Bram](../../docs/images/size-test/base-dressed-as-bram.png)

Animated on the base: the overhead slash from words (8 generations, 9 frames, Bram stays Bram;
the shield swings to the front) and PixelLab's walk template in the steadier skeleton mode
(12 generations, 6 frames).

![attack on the base](../../docs/images/size-test/base-bram-attack-east.png)
![walk on the base](../../docs/images/size-test/base-bram-walk-east.png)

Running total for the day: 64 generations of 5,000.

## What we saw

Filled in on 2026-10-12 by Claude from the viewer's screenshots, at `doug-md`'s request; **Inferred**
until a founder has looked for themselves. The 64 column is the art on disk, except the attack row,
which is the dressed base body.

| Question (viewer key) | 64 | 32 | 16 |
| --- | --- | --- | --- |
| Reads at battle scale (1) | Yes: kit, faces and weapons all read | Yes, but plainer and thinner | No: the goblin is a man in a green shirt |
| Crowd still reads (3) | Yes: busy, but every body can be told apart | Yes | No: it turns to brown and grey blocks |
| Facing reads (F) | Yes: the dressed base is clear in all four | Yes | Barely |
| Big units larger? (B) | Not as the fight drew them (all 1.15 tiles); yes with B on | Same | Same, and blocky |
| Attack reads (A) | Yes: 9 frames, Bram stays Bram, the shield comes to the front | Yes, but it drifts: a round red shield appears halfway | Not made |

Big units are fixed in the game, not the art: each unit now has a `body_scale` ([D57](../../docs/06-decisions.md)).

## The call

- dougie (Will): handed the call to Claude on 2026-10-12, with the blank body as the base.
  His own answer: \_\_ — because \_\_
- doug-md: **confirmed it** on 2026-10-12: the 64 class on the base body, ogres bigger than a
  normal body, and the base's look blended with the heroic 64s ([D57](../../docs/06-decisions.md)).
- **Chosen: the 64 class, dressed onto the base body.** Written into docs/06 as D55 on 2026-10-12,
  confirmed by `doug-md` the same day (D57); waits on `dougie`.
