## Loaded by path ([D41]): `const GroundGen := preload("res://src/area/ground_gen.gd")`.
extends RefCounted
## The ground of one tile of open country, laid out for walking in.
##
## Every tile of the continent that is not a place gets its own ground, made
## from its land ([Biome]) and the tiles around it: a way out only on the sides
## the party can walk to, a shore against the sea, a rock wall under the
## mountains; paths worn between the ways out; pools, thickets, outcrops and
## bare patches in the proportions its land has; and now and then something
## somebody left (a cold fire, a ring of stones, a cairn). It is made from the
## world's seed and the tile, so walking back into it finds it the same.
##
## Laid out as the same dictionary a hand-built area under `data/areas` is, and
## handed to the [Database] under an id of its own, so [AreaMap] and
## [AreaScene] cannot tell the difference.

const Biome := preload("res://src/chronicle/biome.gd")

const FLOOR := "."
const BARE := ","
const LIQUID := "~"
const COVER := "\""

const SIDES := {
	"north": Vector2i.UP, "south": Vector2i.DOWN, "west": Vector2i.LEFT, "east": Vector2i.RIGHT,
}
## How wide a way out is, in cells.
const GAP := 4
## How far in from a side its border runs.
const BORDER := 1
## Room left clear round where the paths meet, so arriving is never into a tree.
const HUB_CLEAR := 2

## Things somebody left, and what the party makes of them.
const LANDMARKS := [
	{ "kind": "camp", "props": ["camp/fire_ring", "village/bench"],
	  "line": "A ring of cold stones and a log to sit on. Somebody camped here, and left in a hurry." },
	{ "kind": "circle", "props": ["biome/standing_stone", "biome/standing_stone", "biome/standing_stone"],
	  "line": "Standing stones in a ring, older than any road. The middle of it is very quiet." },
	{ "kind": "cairn", "props": ["biome/cairn"],
	  "line": "A cairn over somebody nobody named. Stones have been added to it lately." },
	{ "kind": "cache", "props": ["nature/dead_tree"], "chest": true,
	  "line": "Something has been hidden here under the roots, and hidden well." },
]


## The id of the ground at [param cell], made the first time it is asked for.
static func for_cell(world: World, cell: Vector2i) -> String:
	var land := Biome.at(world, cell)
	var id := "ground_%d_%d_%s" % [cell.x, cell.y, land]
	if not Database.has_area(id):
		Database.register_area(id, build(world, cell, land))
	return id


## Where the party comes in from [param side] (north, south, east, west): just
## inside the way out on that side, or the middle if there is none.
static func entry(area: Dictionary, side: String) -> Vector2i:
	var at: Array = area.get("entries", {}).get(side, area.get("spawn", [0, 0]))
	return Vector2i(int(at[0]), int(at[1]))


static func side_of(dir: Vector2i) -> String:
	for side: String in SIDES:
		if SIDES[side] == dir:
			return side
	return ""


static func build(world: World, cell: Vector2i, land: String) -> Dictionary:
	var biome := Biome.data(land)
	var size: Array = Database.biomes.get("size", [32, 22])
	var w := int(size[0])
	var h := int(size[1])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.world_seed, cell.x, cell.y, "ground"])

	var grid: Array[PackedStringArray] = []
	for y in h:
		var row := PackedStringArray()
		row.resize(w)
		row.fill(FLOOR)
		grid.append(row)
	# Cells nothing may be put on: the paths, the ways out and the meeting of them.
	var kept: Dictionary = {}
	var blocked: Dictionary = {}
	var props: Array = []
	var hub := Vector2i(w / 2 + rng.randi_range(-3, 3), h / 2 + rng.randi_range(-2, 2))

	# The ways out, and the edges that have none.
	var exits: Array = []
	var entries := {}
	for side: String in SIDES:
		var dir: Vector2i = SIDES[side]
		var next := cell + dir
		var open := world.in_bounds(next) and world.is_walkable(next)
		var along := _gap_start(world, cell, next, w if dir.y != 0 else h)
		for i in (w if dir.y != 0 else h):
			var at := _edge_cell(side, i, w, h)
			var in_gap := open and i >= along and i < along + GAP
			if in_gap:
				exits.append([at.x, at.y])
				kept[at] = true
				continue
			_close_edge(world, next, at, dir, grid, blocked, props, biome, rng)
		if open:
			var mid := _edge_cell(side, along + GAP / 2, w, h) - dir * (BORDER + 1)
			entries[side] = [mid.x, mid.y]
			_wear_path(grid, kept, mid + dir * BORDER, hub, rng, w, h)

	for dy in range(-HUB_CLEAR, HUB_CLEAR + 1):
		for dx in range(-HUB_CLEAR, HUB_CLEAR + 1):
			kept[hub + Vector2i(dx, dy)] = true

	# Patches, in the proportions the land has them.
	var features: Dictionary = biome.get("features", {})
	for i in _count(float(features.get("bare", 1.0)), rng):
		_blob(grid, kept, BARE, _anywhere(rng, w, h), rng.randi_range(2, 4), rng, w, h, false)
	for i in _count(float(features.get("cover", 1.0)), rng):
		_blob(grid, kept, COVER, _anywhere(rng, w, h), rng.randi_range(2, 4), rng, w, h, false)
	for i in _count(float(features.get("pools", 1.0)), rng):
		_blob(grid, kept, LIQUID, _anywhere(rng, w, h), rng.randi_range(1, 3), rng, w, h, true)
	var pool: Dictionary = biome.get("props", {})
	for i in _count(float(features.get("outcrops", 1.0)), rng):
		_outcrop(grid, kept, blocked, props, pool.get("rocks", []), _anywhere(rng, w, h), rng, w, h)

	# Something somebody left.
	var spots: Array = []
	var chests: Array = []
	if rng.randf() < float(Database.biomes.get("landmark_chance", 0.2)):
		_landmark(grid, kept, blocked, props, spots, chests, rng, w, h, cell)

	# What grows and lies about.
	var density: Dictionary = biome.get("density", {})
	for y in range(BORDER, h - BORDER):
		for x in range(BORDER, w - BORDER):
			var at := Vector2i(x, y)
			if kept.has(at) or blocked.has(at) or grid[y][x] == LIQUID:
				continue
			for kind: String in ["trees", "rocks", "bushes", "small"]:
				var choices: Array = pool.get(kind, [])
				if choices.is_empty() or rng.randf() >= float(density.get(kind, 0.0)):
					continue
				var solid := kind == "trees" or kind == "rocks"
				props.append({ "art": str(choices[rng.randi() % choices.size()]), "cell": [x, y], "solid": solid })
				if solid:
					blocked[at] = true
				break

	var rows: Array = []
	for row in grid:
		rows.append("".join(row))
	var ground: Dictionary = biome.get("ground", {})
	return {
		"display_name": str(biome.get("name", land)),
		"biome": land,
		"layers": biome.get("layers", ["dirt"]),
		"legend": {
			FLOOR: str(ground.get("floor", "grass")), BARE: str(ground.get("bare", "dirt")),
			LIQUID: str(ground.get("liquid", "water")), COVER: str(ground.get("cover", "meadow")),
		},
		"tint": str(biome.get("tint", "")),
		"hint": "WASD to walk  ·  the ways out follow the land  ·  red ground is being watched",
		"rows": rows,
		"spawn": [hub.x, hub.y],
		"entries": entries,
		"exits": exits,
		"props": props,
		"spots": spots,
		"chests": chests,
	}


## Where along a side its way out starts. Worked out from the edge between the
## two tiles rather than either one, so leaving north out of one ground and
## arriving south into the next come through the same gap.
static func _gap_start(world: World, a: Vector2i, b: Vector2i, length: int) -> int:
	var lo := a if (a.x < b.x or (a.x == b.x and a.y < b.y)) else b
	var hi := b if lo == a else a
	var span := maxi(1, length - GAP - 8)
	return 4 + absi(hash([world.world_seed, lo.x, lo.y, hi.x, hi.y])) % span


static func _edge_cell(side: String, i: int, w: int, h: int) -> Vector2i:
	match side:
		"north":
			return Vector2i(i, 0)
		"south":
			return Vector2i(i, h - 1)
		"west":
			return Vector2i(0, i)
	return Vector2i(w - 1, i)


## A side with no way out is closed by what is beyond it: the sea or a lake
## comes in as water, a mountain as rock, and open country you cannot reach
## from here as a hedge of whatever grows in this land.
static func _close_edge(world: World, next: Vector2i, at: Vector2i, dir: Vector2i, grid: Array,
		blocked: Dictionary, props: Array, biome: Dictionary, rng: RandomNumberGenerator) -> void:
	var beyond := world.terrain_id_at(next) if world.in_bounds(next) else "ocean"
	# A land whose pools are not water (lava, blood, ooze) meets the sea at a
	# cliff instead of a shore.
	if beyond in ["ocean", "lake", "water"] and bool(biome.get("sea_shore", true)):
		for depth in 2:
			var c: Vector2i = at - dir * depth
			grid[c.y][c.x] = LIQUID
		return
	var pool: Dictionary = biome.get("props", {})
	var choices: Array = []
	if beyond in ["wall", "crag", "ocean", "lake", "water"]:
		choices = pool.get("rocks", [])
	if choices.is_empty():
		choices = pool.get("trees", [])
	if choices.is_empty():
		choices = pool.get("rocks", [])
	if choices.is_empty():
		choices = ["biome/boulder"]
	props.append({ "art": str(choices[rng.randi() % choices.size()]), "cell": [at.x, at.y], "solid": true })
	blocked[at] = true


## A path worn from a way out to where the paths meet, wandering a little.
static func _wear_path(grid: Array, kept: Dictionary, from: Vector2i, to: Vector2i,
		rng: RandomNumberGenerator, w: int, h: int) -> void:
	var at := from
	var guard := 0
	while at != to and guard < 200:
		guard += 1
		kept[at] = true
		if at.x >= 1 and at.y >= 1 and at.x < w - 1 and at.y < h - 1:
			grid[at.y][at.x] = BARE
		var step := Vector2i(signi(to.x - at.x), 0) if (rng.randf() < 0.5 and at.x != to.x) or at.y == to.y \
			else Vector2i(0, signi(to.y - at.y))
		at += step
	kept[to] = true


static func _blob(grid: Array, kept: Dictionary, symbol: String, centre: Vector2i, radius: int,
		rng: RandomNumberGenerator, w: int, h: int, keep_clear: bool) -> void:
	var rx := float(radius) + rng.randf() * 1.5
	var ry := float(radius) + rng.randf() * 1.0
	for y in range(centre.y - radius - 2, centre.y + radius + 3):
		for x in range(centre.x - radius - 2, centre.x + radius + 3):
			if x < 2 or y < 2 or x >= w - 2 or y >= h - 2:
				continue
			var at := Vector2i(x, y)
			var d := pow((x - centre.x) / rx, 2.0) + pow((y - centre.y) / ry, 2.0)
			if d > 1.0 + rng.randf() * 0.35:
				continue
			# Water never cuts a path, and nothing is grown over the ways out.
			if kept.has(at) and (keep_clear or symbol == COVER):
				continue
			if kept.has(at) and grid[y][x] == BARE:
				continue
			grid[y][x] = symbol


static func _outcrop(grid: Array, kept: Dictionary, blocked: Dictionary, props: Array, rocks: Array,
		centre: Vector2i, rng: RandomNumberGenerator, w: int, h: int) -> void:
	if rocks.is_empty():
		return
	for i in rng.randi_range(3, 6):
		var at := centre + Vector2i(rng.randi_range(-2, 2), rng.randi_range(-2, 2))
		if at.x < 2 or at.y < 2 or at.x >= w - 2 or at.y >= h - 2:
			continue
		if kept.has(at) or blocked.has(at) or grid[at.y][at.x] == LIQUID:
			continue
		props.append({ "art": str(rocks[rng.randi() % rocks.size()]), "cell": [at.x, at.y], "solid": true })
		blocked[at] = true


static func _landmark(grid: Array, kept: Dictionary, blocked: Dictionary, props: Array, spots: Array,
		chests: Array, rng: RandomNumberGenerator, w: int, h: int, cell: Vector2i) -> void:
	var mark: Dictionary = LANDMARKS[rng.randi() % LANDMARKS.size()]
	var at := _anywhere(rng, w, h)
	for _try in 12:
		if not kept.has(at) and grid[at.y][at.x] != LIQUID:
			break
		at = _anywhere(rng, w, h)
	var art: Array = mark["props"]
	var ring := [Vector2i(0, -2), Vector2i(2, 1), Vector2i(-2, 1)]
	for i in art.size():
		var spot: Vector2i = at + (ring[i] if art.size() > 1 else Vector2i(0, -1))
		if spot.x < 2 or spot.y < 2 or spot.x >= w - 2 or spot.y >= h - 2 or kept.has(spot):
			continue
		props.append({ "art": str(art[i]), "cell": [spot.x, spot.y], "solid": true })
		blocked[spot] = true
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var c := at + Vector2i(dx, dy)
			if c.x > 0 and c.y > 0 and c.x < w - 1 and c.y < h - 1 and grid[c.y][c.x] == LIQUID:
				grid[c.y][c.x] = BARE
			kept[c] = true
	spots.append({ "cell": [at.x, at.y], "line": str(mark["line"]) })
	if bool(mark.get("chest", false)):
		chests.append({
			"cell": [at.x, at.y], "art": "chest_broken",
			"gold": 20 + absi(hash([cell.x, cell.y])) % 60,
			"line": "Under the roots: a box gone soft with damp, and coin inside it.",
		})


static func _anywhere(rng: RandomNumberGenerator, w: int, h: int) -> Vector2i:
	return Vector2i(rng.randi_range(3, w - 4), rng.randi_range(3, h - 4))


## A whole number of patches near [param mean]: the whole part always, the rest
## by chance.
static func _count(mean: float, rng: RandomNumberGenerator) -> int:
	var whole := int(floor(mean))
	return whole + (1 if rng.randf() < mean - float(whole) else 0)
