class_name WorldGen
extends RefCounted
## Builds a world from a seed: ground first, then the places worth walking to.

const NAME_PREFIX := ["Grey", "Hollow", "Ash", "Wither", "Bright", "Storm", "Cold", "Elder", "Fen", "Mourn"]
const NAME_SUFFIX := ["water", "ford", "reach", "hold", "march", "gate", "barrow", "vale", "run", "spire"]

const GIVEN_NAMES := [
	"Aldric", "Bryn", "Cael", "Dara", "Edran", "Fenn", "Gale", "Hesk", "Isolde", "Joran",
	"Kestrel", "Lys", "Maren", "Nel", "Orin", "Perrin", "Quill", "Rusk", "Sable", "Tamsin",
]

## Sites are kept this far apart so the map doesn't clump.
const MIN_SITE_SPACING := 5

## Hand-built places under `data/areas`, dealt out one per site so two villages
## are never the same village.
const AREA_POOLS := {
	Site.VILLAGE: ["village", "village_fen", "village_pines", "village_shore"],
	Site.KEEP: ["keep", "keep_thorn"],
}

const COUNTS := {
	Site.KEEP: 2,
	Site.VILLAGE: 4,
	Site.LIBRARY: 3,
	Site.GATE: 6,
	Site.HUT: 4,
}


static func generate(world_seed: int) -> World:
	var world := World.new()
	world.world_seed = world_seed
	world.rng.seed = world_seed
	world.size = World.SIZE
	world.tiles = _carve_ground(world)
	_place_sites(world)
	_seed_first_doctrine(world)
	world.player_cell = _starting_cell(world)
	return world


# --- ground -------------------------------------------------------------------


static func _carve_ground(world: World) -> Array:
	var elevation := FastNoiseLite.new()
	elevation.seed = world.world_seed
	elevation.frequency = 0.055
	var damp := FastNoiseLite.new()
	damp.seed = world.world_seed + 7717
	damp.frequency = 0.09

	var rows: Array = []
	for y in world.size.y:
		var row := ""
		for x in world.size.x:
			row += _symbol_for(elevation.get_noise_2d(x, y), damp.get_noise_2d(x, y))
		rows.append(row)
	return rows


static func _symbol_for(height: float, wet: float) -> String:
	if height < -0.34:
		return "~"
	if height > 0.52:
		return "#"
	if height > 0.34:
		return "A"
	if height > 0.16:
		return "^"
	if wet > 0.22:
		return ","
	return "."


# --- places -------------------------------------------------------------------


static func _place_sites(world: World) -> void:
	# The Tower goes down first and claims the far corner, so everything else
	# arranges itself around the thing you are eventually walking towards.
	var tower_cell := _find_open_cell(world, Vector2i(world.size.x - 6, 5), 8)
	var tower := Site.create(Site.TOWER, tower_cell, "The Tower")
	world.sites.append(tower)

	var used_names: Dictionary = {}
	for kind: String in COUNTS:
		for i in COUNTS[kind]:
			var cell := _scatter_cell(world)
			if cell.x < 0:
				continue
			world.sites.append(Site.create(kind, cell, _place_name(world.rng, used_names)))
	_deal_areas(world)
	_rank_gates(world)
	_place_home(world)


static func _deal_areas(world: World) -> void:
	for kind: String in AREA_POOLS:
		var pool: Array = AREA_POOLS[kind].duplicate()
		_shuffle(pool, world.rng)
		var sites := world.sites_of_kind(kind)
		for i in sites.size():
			sites[i].data["area"] = pool[i % pool.size()]


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var swap: Variant = items[i]
		items[i] = items[j]
		items[j] = swap


## Somewhere of your own, put down within reach of the first village so the run
## always starts with a roof you can walk back to.
static func _place_home(world: World) -> void:
	var villages := world.sites_of_kind(Site.VILLAGE)
	var anchor: Vector2i = villages[0].cell if not villages.is_empty() else world.size / 2
	for radius in range(1, 9):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var cell := anchor + Vector2i(dx, dy)
				if world.site_at(cell) != null or not world.is_walkable(cell):
					continue
				if world.terrain_id_at(cell) == "water":
					continue
				world.sites.append(Site.create(Site.HOME, cell, "Home"))
				return


## Spread gates across the whole E-to-S ladder by how far they sit from the
## Tower, so a new world always has somewhere survivable to start.
static func _rank_gates(world: World) -> void:
	var gates := world.sites_of_kind(Site.GATE)
	if gates.is_empty():
		return
	var tower := world.tower()
	gates.sort_custom(
		func(a: Site, b: Site) -> bool:
			return Pathfinder.distance(a.cell, tower.cell) > Pathfinder.distance(b.cell, tower.cell)
	)
	for i in gates.size():
		var rung := 0 if gates.size() == 1 else roundi(float(i) / float(gates.size() - 1) * float(Site.RANKS.size() - 1))
		gates[i].rank = Site.RANKS[rung]
		# Half the world's gates are already spilling when you arrive.
		gates[i].open = world.rng.randf() < 0.5
		gates[i].opened_at = 0


static func _seed_first_doctrine(world: World) -> void:
	# Every world begins with one book already on a shelf (docs/16).
	var libraries := world.sites_of_kind(Site.LIBRARY)
	if libraries.is_empty():
		return
	libraries[0].data["doctrine"] = "the_open_palm"
	for i in range(1, libraries.size()):
		libraries[i].data["doctrine"] = _random_doctrine(world)


static func _random_doctrine(world: World) -> String:
	var ids: Array = Database.doctrine_ids()
	ids.erase("the_open_palm")
	if ids.is_empty():
		return "the_open_palm"
	return ids[world.rng.randi() % ids.size()]


# --- placement helpers --------------------------------------------------------


static func _scatter_cell(world: World) -> Vector2i:
	for attempt in 400:
		var cell := Vector2i(world.rng.randi() % world.size.x, world.rng.randi() % world.size.y)
		if _is_site_ready(world, cell):
			return cell
	return Vector2i(-1, -1)


static func _is_site_ready(world: World, cell: Vector2i) -> bool:
	if not world.is_walkable(cell) or world.terrain_id_at(cell) == "water":
		return false
	for site in world.sites:
		if Pathfinder.distance(site.cell, cell) < MIN_SITE_SPACING:
			return false
	return true


## Walk outwards from [param around] until solid ground turns up.
static func _find_open_cell(world: World, around: Vector2i, radius: int) -> Vector2i:
	for r in radius:
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var cell := around + Vector2i(dx, dy)
				if world.is_walkable(cell) and world.terrain_id_at(cell) != "water":
					return cell
	return Vector2i(world.size.x / 2, world.size.y / 2)


static func _starting_cell(world: World) -> Vector2i:
	var house := world.home()
	if house != null:
		return house.cell

	var villages := world.sites_of_kind(Site.VILLAGE)
	if villages.is_empty():
		return _find_open_cell(world, world.size / 2, 12)
	var home: Site = villages[0]
	for offset: Vector2i in [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT]:
		if world.is_walkable(home.cell + offset):
			return home.cell + offset
	return home.cell


static func _place_name(rng: RandomNumberGenerator, used: Dictionary) -> String:
	for attempt in 60:
		var name_ := "%s%s" % [
			NAME_PREFIX[rng.randi() % NAME_PREFIX.size()],
			NAME_SUFFIX[rng.randi() % NAME_SUFFIX.size()],
		]
		if not used.has(name_):
			used[name_] = true
			return name_
	return "Nameless %d" % used.size()


## A name for someone you meet on the road.
static func person_name(rng: RandomNumberGenerator) -> String:
	return "%s of %s%s" % [
		GIVEN_NAMES[rng.randi() % GIVEN_NAMES.size()],
		NAME_PREFIX[rng.randi() % NAME_PREFIX.size()],
		NAME_SUFFIX[rng.randi() % NAME_SUFFIX.size()],
	]


## A name for somewhere nobody built anything — a spot people still talk about.
static func wild_name(rng: RandomNumberGenerator) -> String:
	return "%s%s" % [
		NAME_PREFIX[rng.randi() % NAME_PREFIX.size()],
		NAME_SUFFIX[rng.randi() % NAME_SUFFIX.size()],
	]
