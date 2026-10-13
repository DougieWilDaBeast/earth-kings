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

**Not used by the game yet.** The other bodies in `art/units/` are still the older, more detailed
64s, so switching only these would mix two looks in one fight. `dougie` (2026-10-12): they go in
with the full redo, all at once. Wiring them then is a `sprite_dir` change per template in
`data/units.json`.

To make another: `python3 tools/pixellab.py dress <unit>`, then `animate` for each state, then
`unpack downloads/pixellab/<unit>_base.zip art/tier1/<unit>`.
