# 09 — The lands of the continent

`doug-md` asked on 2026-10-12 for the ground to come in different lands — snow, desert,
grassland, forest, ash, slime, bog and swamp — and for other lands to be researched and added. This
is that research, and what was built from it ([D66](../06-decisions.md)). The lands are data in
[`data/biomes.json`](../../data/biomes.json); which land a tile is comes from
`src/chronicle/biome.gd`, and its ground is laid out by `src/area/ground_gen.gd`.

## What the games we looked at do

- **Necesse** — five major lands (forest, plains, snow, swamp, desert), each able to hold a village,
  with special places (dungeons, pirate villages, a desert temple) and incursion lands reached
  through an altar: slime caves, a graveyard, a spider castle, a crystal hollow. The lesson taken:
  a few broad lands, with something worth finding inside each.
- **Terraria** — forest, snow, desert, jungle and ocean on the surface; the Corruption and the
  Crimson as lands that _spread_; mini-lands inside the big ones (an oasis in the desert, glowing
  moss, an ash forest at the underworld's edge, a graveyard where enough tombstones gather, a
  meteorite crater that burns). The lesson taken: land can be changed by what happens on it.
- **Valheim** — lands ranked by danger: meadows, black forest, swamp, mountains, plains,
  mistlands, ashlands, the deep north. Each has its own trees, rocks, creatures and weather, and
  the hardest are furthest out. The lessons taken: fog as a land of its own, and ash and cold at
  the far ends.
- **Don't Starve** — many small lands, each made of its own turf: savanna, marsh, deciduous
  forest, badlands, rockyland, oasis desert, mosaic, meteor fields, and under it mushtree forests
  and a slimy land. The lesson taken: every land gets its own ground tiles and its own handful of
  things standing on them.

The founders' own answers set where the lands go. `doug-md`, 2026-09-14: the middle of the
continent is "more warmer, kind of like an equator"; a tower "will completely reshape that
geography"; over broken gates "lightning and dark clouds"; a fire tower brings "magma, there's
volcanoes" ([part 1c](../worldbuilding/voice-notes/2026-09-14-doug-md-part-1-c-climate-and-season.md),
[1a](../worldbuilding/voice-notes/2026-09-14-doug-md-part-1-a-physical.md),
[1b](../worldbuilding/voice-notes/2026-09-14-doug-md-part-1-b-land-scale-and-edges.md)).

## The eighteen lands

| Land | From | Where it is |
| --- | --- | --- |
| grassland | `doug-md` | the open country between everything else |
| forest | `doug-md` | the world's forest tiles, and damp grassland |
| snowfield | `doug-md` | the cold north |
| desert | `doug-md` | the hot south |
| ashland | `doug-md` | round a gate that opened onto fire, and some scorched high ground |
| slime fen | `doug-md` | wet ground where something got into the water |
| bog | `doug-md` | wet low ground in the cooler half |
| swamp | `doug-md` | wet low ground in the warmer half |
| badlands | Don't Starve, Terraria | dry red rock in the south |
| savanna | Don't Starve, Valheim's plains | dry gold grass ahead of the desert |
| jungle | Terraria | the hot wet band through the middle |
| taiga | Valheim's mountains and deep north | forest and damp grass just south of the snow |
| crystal fields | Necesse's crystal hollow, Terraria | some snow and high ground |
| fungal grove | Don't Starve's mushtree forest, Terraria | patches of forest |
| the blight | Terraria's Corruption, Necesse's graveyard | round an open gate, healing when it is shut |
| blossom vale | Minecraft's cherry grove | patches of grass and forest |
| barrow downs | Necesse's graveyard, Valheim's burial mounds | hills and grass with old graves |
| the mistlands | Valheim | some hills and crags |

`doug-md` took all ten of the researched lands. Which noise threshold gives which land, and how
large each patch is, is **Inferred** and can be tuned in `biome.gd`.

## What a land changes

Its ground tiles (three sheets: the floor against bare earth, against water, against cover), what
stands on it (trees, bushes, rocks, small things, at densities), how many pools, thickets, bare
patches and outcrops a ground gets, the light it is seen in, and the line said on arriving. Every
land but grassland and forest is drawn with stand-in art: the grassland art recoloured by
`tools/recolour_biomes.py`, to be replaced by PixelLab art of the same names
([22](../22-asset-provenance.md)).

## Not built

- Weather per land (snow falling, fog drifting, ash in the air) and storms over broken gates.
- The Tower's element reshaping the land round it: the world's Tower has no element yet.
- Hazards in the ground itself (thin ice, a burning crater, ooze that slows).
- Enemies chosen by land: bands are still dealt by danger and faction, not by where they stand.
