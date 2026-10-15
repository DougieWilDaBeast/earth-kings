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
| A9 | **The huge Tower** ([D101](06-decisions.md), design meeting 2 call D, the one art exception; first on next month's credits, [D100](06-decisions.md)): its foot, as wide as a city tile, with the one door in it, and the shaft going up out of sight; seen from the city's streets and from the crater. Today its foot is rock face and flagstone in `data/areas/tower.json`, with a door drawn in house standing in it (`landmark/tower_door`, by `tools/draw_tower.py`, [D111](06-decisions.md)). Until it lands, a stand-in shaft of wall stone rises over the door (`spire` in `tower.json`, `src/area/area_spire.gd`) and an in-house picture of the Tower (`art/ui/far_tower.png`) stands on the screen's edge from far off (`src/ui/far_tower.gd`, [D108](06-decisions.md)); Will confirmed this request and A10 ([D109](06-decisions.md)) | A ground piece about 20 × 8 cells (1280 × 512) for the foot, 3/4 top-down, dark outline, muted ([D40](06-decisions.md)), plus a tall far silhouette for the horizon; it must read as far bigger than anything in Stormreach | `DROP-ZONE/A9/` | The First Hour's spine is the climb ([D99](06-decisions.md), pillar II); the Tower was small and pulsing in every play-test |
| A10 | **A child's saddle buckle** lying on the Tower's floor: Atlas's chapter-one memory ([D103](06-decisions.md)). Small, tarnished brass, the leather long rotted off, catching the light. Today the coin pile stands in for it | One ground prop, 64 × 64 with the buckle about 24 px across, 3/4 top-down, dark outline, muted ([D40](06-decisions.md)) | `DROP-ZONE/A10/`, then `art/props/memory/saddle_buckle.png` and `art` in `data/memories.json` | The First Hour's last beat: the found object that gives Atlas chapter one back |
| A11 | **A bronze stylus** lying on the Tower's floor: Cato's chapter-one memory ([D135](06-decisions.md)). The kind for writing on wax, a hand long, its point worn flat, dull bronze catching the light. Today the coin pile stands in for it | One ground prop, 64 × 64 with the stylus about 28 px long lying at an angle, 3/4 top-down, dark outline, muted ([D40](06-decisions.md)) | `DROP-ZONE/A11/`, then `art/props/memory/bronze_stylus.png` and `art` in `data/memories.json` | Cato's floor 5 beat: the found object that gives him chapter one back |
| A5 | **Room floors and walls**, to replace the stand-ins drawn by `tools/draw_interiors.py`: floors (oak, pine, dark wet planks, driftwood, clay tiles, flagstones), back-wall faces and wall tops (timber and plaster, logs, sea boards, damp boards, painted adobe, stone). The furniture is made (see Done) | Same names and sizes as the stand-ins in `art/interior/` (64 to a cell; a wall face is 64 × 112, its top 16 the cap seen from above); 3/4 view, dark outline, muted ([D40](06-decisions.md)) | `DROP-ZONE/A5/` | The insides of the inns and halls were bare ([D81](06-decisions.md)); these are drawn in code until made properly |

## Deferred

| What | Why it waits |
| --- | --- |
| A6: proper ground for the other eight lands (ash, jungle, barrow, blossom, slime, crystal, fungal, mist), three sheets each, with `tools/pixellab_world.py ground <land>` (about 65 generations a land) | `dougie`, 2026-10-13: eight lands first, the rest next month |
| Hit and death for the Sleepless Blade (`emo_swordsman`), about 16 generations | The month's generations ran out, 2026-10-14 |
| Redraw the manes of `tide_lion` and `flame_lion` so water and fire read at a glance (about 35 generations each) | `dougie`, 2026-10-13: playability first, come back to it later |

## Done

| Id | What | Done |
| --- | --- | --- |
| A8 | The month's last generations on the early game (`dougie`, 2026-10-14): fight sets in `art/tier1/` for the Ember Dove, the wisp, the eye slinger, the warlock, the red panda master, the staff panda, the element monk, the wraith, Tem the sword monkey (redrawn without the borrowed hat and patch), the village idiot, the fox knight, the duelist, the ice wolf, the mending lion, the silver legionnaire and the butler, and a walk, attack and skill for the Sleepless Blade (no flinch or fall; the month ran out), and Sky, a great lizard with Atlas in the saddle, in `art/big/sky` ([D93](06-decisions.md)); the seven big sets already made wired in | 2026-10-14 |
| A7 | Town walls in three builds (stone, timber palisade, mud brick): a run, a side and a tower each, in `art/props/walls/` (`tools/pixellab_world.py walls`, 14 generations, five of them retries), for the walled villages and the great city ([D85](06-decisions.md)) | 2026-10-14 |
| A5, part | The room furniture: 22 pieces, from the bar counter to the ship's bell, in `art/props/interior/` (`tools/pixellab_world.py rooms`) | 2026-10-13 |
| A6, part | Every land's trees, rocks and plants, and the ground of the blight, snow, dune, savanna, swamp, bog, taiga and badlands (`tools/pixellab_world.py`), asked for by `doug-md` ([voice notes](worldbuilding/voice-notes/2026-10-13-doug-md-continuous-world.md)) | 2026-10-13 |
| — | Tier 1 units on the base body: `sworn_blade`, `longbow`, `hedge_priest`, `magic_swordsman`, `goblin`, `raider`, `wolf`, `club_ogre` ([art/tier1](../art/tier1/README.md)) | 2026-10-12 |
| A1 | Fight effects: slash, arrow, heal, burst, plus a charge-up and a shield-block spark ([art/effects](../art/effects/README.md)), wired 2026-10-13 ([D82](06-decisions.md)) | 2026-10-12 |
| A2, part | The six status icons, plus tired, block, draught and herb (`art/ui/status/`); stun, charging, tired, draught and herb wired 2026-10-13 ([D82](06-decisions.md)) | 2026-10-12 |
| A3, part | `beast_titan`, `colossal_titan` and `king_slime` redrawn at 96 ([art/big](../art/big/README.md)); `king_slime` wired 2026-10-13, the giants not yet; `king_slime` again as a mound on 2026-10-13, its first try kept as the Amber Knight | 2026-10-13 |
| A3, part | `blue_slime` redrawn as the Bog Jelly ([23](23-originality-pass.md)) and wired, in [art/tier1](../art/tier1/README.md) | 2026-10-13 |
| A3, part | `ember_lizard` and `seed_beast` redrawn as the Cinder Newt and the Mossback ([23](23-originality-pass.md)) and wired, in [art/tier1](../art/tier1/README.md) | 2026-10-13 |
