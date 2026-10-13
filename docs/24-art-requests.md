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
| A3 | **Redraw two borrowed characters** so they no longer look like other games' characters: `ember_lizard`, `seed_beast`. The two giants, `king_slime` and `blue_slime` are done (see Done) | The 64 class; use the new prompts in [23](23-originality-pass.md) | `DROP-ZONE/A3/` | They cannot ship looking like the originals ([23](23-originality-pass.md), [22 item P6](22-asset-provenance.md)) |
| A4 | **Sixteen signature weapon icons**, one per lead: Atlas's orb, Janus's key, Bellona's standard-spear, Cassius's rapier, Saturn's sickle, Vesta's lamp, Caesar's tower shield, Iris's throwing knives, Pluto's bident, Ceres's threshing flail, Cato's short sword and shield, Juno's kitchen knife, Ultor's two daggers, Diana's hunting bow, Ares's greataxe, Liber's cestus. Today each borrows an existing icon | Item icons at the size and finish of `art/items/` | `DROP-ZONE/A4/`, named by the weapon id in `data/equipment.json` (`pale_orb`, `first_key`, `last_wall`, `the_answer`, `long_harvest`, `kept_flame`, `every_morning`, `passing_word`, `the_tally`, `threshing_day`, `last_word`, `hosts_knife`, `grudge_and_reckoning`, `wolfs_tooth`, `first_blow`, `open_hands`) | The weapon a dead lead leaves to the next world ([D33](06-decisions.md), [D78](06-decisions.md)) |

## Done

| Id | What | Done |
| --- | --- | --- |
| — | Tier 1 units on the base body: `sworn_blade`, `longbow`, `hedge_priest`, `magic_swordsman`, `goblin`, `raider`, `wolf`, `club_ogre` ([art/tier1](../art/tier1/README.md)) | 2026-10-12 |
| A1 | Fight effects: slash, arrow, heal, burst, plus a charge-up and a shield-block spark ([art/effects](../art/effects/README.md)), not yet wired | 2026-10-12 |
| A2, part | The six status icons, plus tired, block, draught and herb (`art/ui/status/`), not yet wired | 2026-10-12 |
| A3, part | `beast_titan`, `colossal_titan` and `king_slime` redrawn at 96 ([art/big](../art/big/README.md)); `king_slime` wired 2026-10-13, the giants not yet; `king_slime` again as a mound on 2026-10-13, its first try kept as the Amber Knight | 2026-10-13 |
| A3, part | `blue_slime` redrawn as the Bog Jelly ([23](23-originality-pass.md)) and wired, in [art/tier1](../art/tier1/README.md) | 2026-10-13 |
