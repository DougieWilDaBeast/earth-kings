## Loaded by path ([D41]): `const Biome := preload("res://src/chronicle/biome.gd")`.
extends RefCounted
## Which land a tile of the continent is: snow, desert, swamp, the blight round
## an open gate. The ground generator lays each one out its own way, and the map
## is tinted by it.
##
## Worked out from the world's seed, the tile's terrain and what stands near
## it, never stored and never drawn from the world's dice, so a world gets the
## same lands every time it is loaded and an old save gains them for free. The
## terrain under it still decides how a tile is walked; the land decides what
## it looks like when you are standing in it.
##
## The lands are in `data/biomes.json`. Snow, desert, grassland, forest, ash,
## slime, bog and swamp are `doug-md`'s (2026-10-12); badlands, savanna, jungle,
## taiga, crystal fields, fungal groves, the blight, blossom vales, barrow downs
## and the mistlands came from looking at Necesse, Terraria, Valheim, Don't
## Starve, Core Keeper and Minecraft, and he took all ten ([D66]). Gates
## reshaping the land round them is his, from the first worldbuilding session.

const GRASSLAND := "grassland"
const FOREST := "forest"
const SNOW := "snow"
const DESERT := "dune"
const BADLANDS := "badlands"
const SAVANNA := "savanna"
const ASH := "ash"
const BLIGHT := "blight"
const SLIME := "slime"
const BOG := "bog"
const SWAMP := "swamp"
const CRYSTAL := "crystal"
const FUNGAL := "fungal"
const BLOSSOM := "blossom"
const BARROW := "barrow"
const JUNGLE := "jungle"
const TAIGA := "taiga"
const MIST := "mist"

## How far off the ordinary a patch of country has to be before it turns
## strange (slime, crystal, fungus, mist): only the far ends of the patchwork
## noise, so they come in small pockets worth finding (`doug-md`, 2026-10-13).
const RARE := 0.36
## How near an open gate the land goes bad. It recovers when the gate shuts.
const BLIGHT_REACH := 2
## How near a gate that opened onto fire the ground is ash.
const ASH_REACH := 6
## The gates whose insides are burning, by the area dealt to them.
const ASH_GATES := ["gate_ash"]
## Where on the map, top to bottom, the grass starts drying out ahead of the sand.
const SAVANNA_LATITUDE := 0.66
## The hot wet band through the middle ([doug-md]: "if you're in the middle it's
## more warmer, kind of like an equator"): from here down to the savanna.
const JUNGLE_LATITUDE := 0.46
## How far south of the snow the cold still holds: forest here is taiga.
const TAIGA_LATITUDE := 0.34

## Noise per world, so it is built once and not for every tile asked about.
static var _noises: Dictionary = {}
## Lands already worked out, for the map, which asks about every tile it draws.
## Thrown away whenever the world takes a step, since gates open and shut.
static var _known: Dictionary = {}
static var _known_for: String = ""


## The land at [param cell], by id in `data/biomes.json`.
static func at(world: World, cell: Vector2i) -> String:
	var stamp := "%d:%d" % [world.world_seed, world.steps]
	if stamp != _known_for:
		_known.clear()
		_known_for = stamp
	if not _known.has(cell):
		_known[cell] = _work_out(world, cell)
	return _known[cell]


static func _work_out(world: World, cell: Vector2i) -> String:
	var terrain := world.terrain_id_at(cell)
	var wide := _noise(world, 0).get_noise_2d(cell.x, cell.y)
	var odd := _noise(world, 1).get_noise_2d(cell.x, cell.y)
	if terrain in ["ocean", "lake", "water", "wall"]:
		return GRASSLAND

	# What the gates have done to the country comes first: it is the newest
	# thing about it, and it goes away when they are shut.
	if world.is_walkable(cell):
		var fire := _distance_to_burning_gate(world, cell)
		if fire <= ASH_REACH:
			return ASH
		if world.distance_to_open_gate(cell) <= BLIGHT_REACH:
			return BLIGHT

	match terrain:
		"snow":
			return CRYSTAL if odd > RARE else SNOW
		"sand":
			return BADLANDS if wide > 0.1 else DESERT
		"marsh":
			if odd > RARE:
				return SLIME
			return BOG if wide > 0.0 else SWAMP
		"forest":
			if odd > RARE:
				return FUNGAL
			if _latitude(world, cell, wide) < TAIGA_LATITUDE:
				return TAIGA
			if _in_jungle_band(world, cell, wide):
				return JUNGLE
			if odd < -0.38:
				return BLOSSOM
			return FOREST
		"crag":
			if wide < -0.3:
				return ASH
			if odd < -RARE:
				return MIST
			return CRYSTAL if odd > RARE else BARROW
		"hill":
			if wide < -0.32:
				return ASH
			if wide > 0.4 and odd > RARE - 0.15:
				return CRYSTAL
			if odd < -RARE:
				return MIST
			return BARROW if odd > 0.15 else GRASSLAND
	# Grass, brush and road: most of the continent, so most of the variety. The
	# wet low ground goes to fen and bog the way the world's marshes do.
	var latitude := _latitude(world, cell, 0.0)
	if latitude > SAVANNA_LATITUDE + wide * 0.08:
		return SAVANNA
	var damp := _damp(world).get_noise_2d(cell.x, cell.y)
	# Wet low ground first: bog in the cold, swamp in the warm, slime where
	# something has got into the water.
	if damp > 0.14:
		if odd > RARE:
			return SLIME
		if latitude < JUNGLE_LATITUDE:
			return BOG if wide > -0.1 else SWAMP
		return SWAMP if wide > -0.15 else BOG
	if latitude < TAIGA_LATITUDE and damp > -0.05:
		return TAIGA
	if _in_jungle_band(world, cell, wide) and damp > 0.0:
		return JUNGLE
	# Damp enough for trees: woods break the open country up.
	if damp > -0.1:
		return FOREST
	if odd > 0.3:
		return BARROW
	if odd < -0.36:
		return BLOSSOM
	if damp < -0.38 and wide > 0.15:
		return BADLANDS
	return GRASSLAND


static func _latitude(world: World, cell: Vector2i, wander: float) -> float:
	return float(cell.y) / float(maxi(1, world.size.y - 1)) + wander * 0.06


static func _in_jungle_band(world: World, cell: Vector2i, wide: float) -> bool:
	var latitude := _latitude(world, cell, wide)
	return latitude > JUNGLE_LATITUDE and latitude < SAVANNA_LATITUDE


## The same damp the world was carved with ([WorldGen]), so wet country here is
## wet country there.
static func _damp(world: World) -> FastNoiseLite:
	var key := "%d:damp" % world.world_seed
	if not _noises.has(key):
		var noise := FastNoiseLite.new()
		noise.seed = world.world_seed + 7717
		noise.frequency = 0.045
		_noises[key] = noise
	return _noises[key]


static func data(biome_id: String) -> Dictionary:
	var found := Database.biome(biome_id)
	return found if not found.is_empty() else Database.biome(GRASSLAND)


static func display_name(biome_id: String) -> String:
	return str(data(biome_id).get("name", biome_id))


## What the land does to the party on its ground (`effects` in `data/biomes.json`):
## `slow` (walking speed, 1 for none), `sight` (cells added to how far a band
## sees), `fog` (how thick the screen is fogged, 0 to 1), `hazard` (cold, heat,
## ooze or "" for none). `doug-md` asked for a few simple ones (2026-10-13).
static func effects(biome_id: String) -> Dictionary:
	var out := { "slow": 1.0, "sight": 0, "fog": 0.0, "hazard": "" }
	out.merge(data(biome_id).get("effects", {}), true)
	return out


## Whether [param character] carries something that keeps [param hazard] off
## (a piece of gear or a charm whose `proof` names it, `data/equipment.json`).
static func spared(character: Character, hazard: String) -> bool:
	if hazard == "":
		return true
	var carried: Array = character.charms.duplicate()
	carried.append(character.equipment if character.equipment != "" else Gear.issued_id(character))
	for piece_id: Variant in carried:
		if Gear.piece(str(piece_id)).get("proof", []).has(hazard):
			return true
	return false


## The colour the map is washed with for this land, or clear for none.
static func tint(biome_id: String) -> Color:
	var hex := str(data(biome_id).get("tint", ""))
	return Color(hex) if hex != "" else Color.WHITE


static func _noise(world: World, which: int) -> FastNoiseLite:
	var key := "%d:%d" % [world.world_seed, which]
	if not _noises.has(key):
		var noise := FastNoiseLite.new()
		noise.seed = world.world_seed + 4241 + which * 977
		noise.frequency = 0.035 if which == 0 else 0.07
		_noises[key] = noise
	return _noises[key]


static func _distance_to_burning_gate(world: World, cell: Vector2i) -> int:
	var best := 1 << 20
	for site: Site in world.sites:
		if site.kind != Site.GATE or str(site.data.get("area", "")) not in ASH_GATES:
			continue
		best = mini(best, Pathfinder.distance(site.cell, cell))
	return best
