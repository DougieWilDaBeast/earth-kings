# Tier 1 — the combat prototype's units, on the base body

Generated 2026-10-12 with `tools/pixellab.py` ([docs/19](../../docs/19-asset-list.md#tier-1--the-combat-prototype-after-the-reset),
[D55](../../docs/06-decisions.md)): each humanoid dressed onto the founders' blank base body, the wolf
from PixelLab's dog template, all low top-down at the 64 class. The five humans (`sworn_blade`,
`longbow`, `hedge_priest`, `magic_swordsman`, `raider`) were dressed again the same evening in the
blended finish (`BLEND_STYLE`, [D57](../../docs/06-decisions.md)), and `club_ogre` made again at 96 on
its own body, as big units are. `goblin` and `wolf` are still the first, plain versions.

```
art/tier1/<unit>/idle/<facing>.png                  8 facings
art/tier1/<unit>/<state>/<facing>/frame_000.png     walk, attack, skill, hit, death; south, east, north, west
art/tier1/<unit>/metadata.json                      what each piece was made from, and what it cost
```

**In the game since 2026-10-13.** `dougie` first wanted these held back for the full redo, so as not
to mix two looks in one fight, then chose to wire the early game's set at once (2026-10-13): the
founders (`bram`, `sera`, `toln` and the innkeeper, who shares Toln's body), `brigand`, `wolf`,
`goblin`, `ogre`, and the first of the early foes as they are made: `brigand_archer`
(`jester_thief`), `cabin_boy`, `hat_fox`. `magic_swordsman` is not wired yet. Wiring one is a
`sprite_dir` change in `data/units.json`.

To make another: `python3 tools/pixellab.py dress <unit>`, then `animate` for each state, then
`unpack downloads/pixellab/<unit>_base.zip art/tier1/<unit>`.
