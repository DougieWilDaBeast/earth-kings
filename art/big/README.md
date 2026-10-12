# Big units, at 96 on their own bodies

Generated 2026-10-12 with `tools/pixellab.py character <unit> 96 --model v3`
([D57](../../docs/06-decisions.md)): units too big to dress onto the base body, each made on its own
body at 96 pixels and drawn taller in a fight by its `body_scale` in `data/units.json`. `club_ogre`,
made the same way, is in [`art/tier1/`](../tier1/README.md).

```
art/big/<unit>/idle/<facing>.png                  8 facings
art/big/<unit>/<state>/<facing>/frame_000.png     walk, attack, skill, hit, death; south, east, north, west
art/big/<unit>/metadata.json                      the prompt, the moves asked for, and what each cost
```

Bipeds (`tree_sentinel`, `dirte`, `frozen_wolfman`, `axe_bear`, `sword_bear`, `beast_titan`,
`colossal_titan`) walk, flinch and fall on PixelLab's stock skeleton moves; the rest
(`cannon_bear`, `caterpillar_warrior`, `turret_cannon`, `king_slime`) move from words. Attacks and
skills are words for everyone.

`beast_titan`, `colossal_titan` and `king_slime` are drawn from the new prompts in
[23](../../docs/23-originality-pass.md), not their old borrowed looks. `frozen_wolfman`'s prompt was
rewritten as a frost werewolf with bone claws.

**Not used by the game yet**: they go in with the full redo, with [Tier 1](../tier1/README.md).
Wiring one is a `sprite_dir` change in `data/units.json`.
