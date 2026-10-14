# 24 — Art requests

**The art waiting to be made, one request per row.** This is the short, current to-do list;
[19 — Asset list](19-asset-list.md) is the long plan it is taken from.

## How it works

1. **Asking.** When the game needs art, the request is written here: what it is, how big, how it
   should look, and where it goes. `doug-md` (or a coding agent working with him) adds it.
2. **Telling.** `doug-md` tells `dougie` there is art to make. Only `dougie`'s PixelLab account
   generates art.
3. **Making.** `dougie` makes each open request, with `tools/pixellab.py` or the PixelLab website,
   and puts the results in `DROP-ZONE/<request id>/` (for example `DROP-ZONE/A1/`). The PixelLab
   export zip is fine as it is.
4. **Closing.** Whoever wires the art into the game moves it from `DROP-ZONE/` into `art/`, keeps
   its `metadata.json`, and moves the row to **Done** with the date.

Every request follows the [conventions in 19](19-asset-list.md#conventions): dark fantasy, muted
colours ([D40](06-decisions.md)), the 64 class on the founders' base body ([D55](06-decisions.md)),
big units drawn bigger.

## Open

| Id | What to make | Size and look | Put it in | Why |
| --- | --- | --- | --- | --- |
| A2 | **Fight screen UI**: four ability-slot frames (Q, W, E, R), a cooldown sweep, a "Paused" banner and a game-speed indicator. The status icons are made (see Done) | Frames to match the existing UI in `art/ui/` | `DROP-ZONE/A2/` | What the player reads during a real-time fight ([19, item 1.5](19-asset-list.md#tier-1--the-combat-prototype-after-the-reset)) |
| A4 | **Sixteen signature weapon icons**, one per lead: Atlas's orb, Janus's key, Bellona's standard-spear, Cassius's rapier, Saturn's sickle, Vesta's lamp, Caesar's tower shield, Iris's throwing knives, Pluto's bident, Ceres's threshing flail, Cato's short sword and shield, Juno's kitchen knife, Ultor's two daggers, Diana's hunting bow, Ares's greataxe, Liber's cestus. Today each borrows an existing icon | Item icons at the size and finish of `art/items/` | `DROP-ZONE/A4/`, named by the weapon id in `data/equipment.json` (`pale_orb`, `first_key`, `last_wall`, `the_answer`, `long_harvest`, `kept_flame`, `every_morning`, `passing_word`, `the_tally`, `threshing_day`, `last_word`, `hosts_knife`, `grudge_and_reckoning`, `wolfs_tooth`, `first_blow`, `open_hands`) | The weapon a dead lead leaves to the next world ([D33](06-decisions.md), [D81](06-decisions.md)) |
| A5 | **Room floors and walls**, to replace the stand-ins drawn by `tools/draw_interiors.py`: floors (oak, pine, dark wet planks, driftwood, clay tiles, flagstones), back-wall faces and wall tops (timber and plaster, logs, sea boards, damp boards, painted adobe, stone). The furniture is made (see Done) | Same names and sizes as the stand-ins in `art/interior/` (64 to a cell; a wall face is 64 × 112, its top 16 the cap seen from above); 3/4 view, dark outline, muted ([D40](06-decisions.md)) | `DROP-ZONE/A5/` | The insides of the inns and halls were bare ([D81](06-decisions.md)); these are drawn in code until made properly |

## Deferred

| What | Why it waits |
| --- | --- |
| A6: proper ground for the other eight lands (ash, jungle, barrow, blossom, slime, crystal, fungal, mist), three sheets each, with `tools/pixellab_world.py ground <land>` (about 65 generations a land) | `dougie`, 2026-10-13: eight lands first, the rest next month |
| Redraw the manes of `tide_lion` and `flame_lion` so water and fire read at a glance (about 35 generations each) | `dougie`, 2026-10-13: playability first, come back to it later |

## Done

| Id | What | Done |
| --- | --- | --- |
| A7 | Town walls in three builds (stone, timber palisade, mud brick): a run, a side and a tower each, in `art/props/walls/` (`tools/pixellab_world.py walls`, 14 generations, five of them retries), for the walled villages and the great city ([D85](06-decisions.md)) | 2026-10-14 |
| A5, part | The room furniture: 22 pieces, from the bar counter to the ship's bell, in `art/props/interior/` (`tools/pixellab_world.py rooms`) | 2026-10-13 |
| A6, part | Every land's trees, rocks and plants, and the ground of the blight, snow, dune, savanna, swamp, bog, taiga and badlands (`tools/pixellab_world.py`), asked for by `doug-md` ([voice notes](worldbuilding/voice-notes/2026-10-13-doug-md-continuous-world.md)) | 2026-10-13 |
| — | Tier 1 units on the base body: `sworn_blade`, `longbow`, `hedge_priest`, `magic_swordsman`, `goblin`, `raider`, `wolf`, `club_ogre` ([art/tier1](../art/tier1/README.md)) | 2026-10-12 |
| A1 | Fight effects: slash, arrow, heal, burst, plus a charge-up and a shield-block spark ([art/effects](../art/effects/README.md)), wired 2026-10-13 ([D82](06-decisions.md)) | 2026-10-12 |
| A2, part | The six status icons, plus tired, block, draught and herb (`art/ui/status/`); stun, charging, tired, draught and herb wired 2026-10-13 ([D82](06-decisions.md)) | 2026-10-12 |
| A3, part | `beast_titan`, `colossal_titan` and `king_slime` redrawn at 96 ([art/big](../art/big/README.md)); `king_slime` wired 2026-10-13, the giants not yet; `king_slime` again as a mound on 2026-10-13, its first try kept as the Amber Knight | 2026-10-13 |
| A3, part | `blue_slime` redrawn as the Bog Jelly ([23](23-originality-pass.md)) and wired, in [art/tier1](../art/tier1/README.md) | 2026-10-13 |
| A3, part | `ember_lizard` and `seed_beast` redrawn as the Cinder Newt and the Mossback ([23](23-originality-pass.md)) and wired, in [art/tier1](../art/tier1/README.md) | 2026-10-13 |
