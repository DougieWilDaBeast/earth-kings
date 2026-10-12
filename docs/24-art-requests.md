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
| A1 | **Four ability effects**: a sword slash, an arrow in flight, a heal, and one magic burst. A few frames each, so they can play over a fight | 64 class, transparent background, muted colours | `DROP-ZONE/A1/` | The real-time fight needs them to be readable ([19, item 1.4](19-asset-list.md#tier-1--the-combat-prototype-after-the-reset)) |
| A2 | **Fight screen UI**: four ability-slot frames (Q, W, E, R), a cooldown sweep, a "Paused" banner, a game-speed indicator, and six status icons — stun, bleed, burn, provoke, vulnerable, charging | Icons about 32×32; frames to match the existing UI in `art/ui/` | `DROP-ZONE/A2/` | What the player reads during a real-time fight ([19, item 1.5](19-asset-list.md#tier-1--the-combat-prototype-after-the-reset)) |
| A3 | **Redraw six borrowed characters** so they no longer look like other games' characters: `beast_titan`, `colossal_titan`, `ember_lizard`, `seed_beast`, `blue_slime`, `king_slime` | The 64 class (the two giants bigger); use the new prompts in [23](23-originality-pass.md) | `DROP-ZONE/A3/` | They cannot ship looking like the originals ([23](23-originality-pass.md), [22 item P6](22-asset-provenance.md)) |

## Done

| Id | What | Done |
| --- | --- | --- |
| — | Tier 1 units on the base body: `sworn_blade`, `longbow`, `hedge_priest`, `magic_swordsman`, `goblin`, `raider`, `wolf`, `club_ogre` ([art/tier1](../art/tier1/README.md)) | 2026-10-12 |
