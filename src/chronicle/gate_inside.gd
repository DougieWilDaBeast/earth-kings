extends RefCounted
## The inside of a gate, one floor at a time (D248): walked, like the Tower's floors.
##
## Play-test 6 (doug-md): "When I enter.or get close to a gate, I want to be able to enter into the gate
## and fight the monsters there and create a whole area where I can fight the monsters in it." So E at
## a gate on the ground no longer fights at its doorway: it opens the floor the party is on, laid out
## here and handed to the area scene like any area ([method Database.register_area]).
##
## A floor is a run of chambers cut out of solid wall, from the doorway at the bottom (the way out) to
## the way down at the top, joined by passages. A band of the gate's own holds every chamber but the
## first; on the last floor the keeper holds the last chamber, in front of the way down, and the way
## down will not open until it falls. How big, how many chambers and how far a band sees are
## `gate.inside` in `data/world_rules.json`.
##
## Gates that grow (play-test 7, D261): "the different areas inside of gates, they're not all the same.
## There could be a frost biome, there could be a fire biome, there could be a grassland biome, there
## could be a cave system, there can be an open plain". A gate's first floor is the ground of the land
## it stands on (`grounds`, `by_land`); a deeper floor of a bigger gate is another kind. The longer the
## rank, the more floors, chambers and bands, and the harder its keeper is to put down; every band on
## a floor must be down before its way down opens, and the keeper's fall scatters the rest. The same floor of the same gate is always laid out the same way; a delve lost starts its
## bands over (`delves`, counted on the site).
##
## Loaded by path, not by `class_name` ([D41]).

const FLOOR := "."
const PATH := ","
const WALL := "A"
const COVER := "m"
const Biome := preload("res://src/chronicle/biome.gd")


static func rules() -> Dictionary:
	return Database.world_rules.get("gate", {}).get("inside", {})


## Whether gates are walked inside at all (the rules say how).
static func walked() -> bool:
	return not rules().is_empty()


## The id the floor of [param site] at [param depth] is registered under.
static func area_id(site: Site, depth: int) -> String:
	return "gate_inside_%d_%d_%d" % [site.cell.x, site.cell.y, depth]


## The done flag of the keeper on the last floor of [param site]: set, the way down is open.
static func keeper_flag(site: Site, depth: int) -> String:
	return "done:%s_%d_keeper" % [area_id(site, depth), int(site.data.get("delves", 0))]


## The floor of [param site] at [param depth] laid out for [param party] (Characters) and registered,
## ready for [method AreaMap.load_area]. Returns its id.
static func area_for(world: World, site: Site, depth: int, party: Array) -> String:
	var id := area_id(site, depth)
	Database.register_area(id, layout(world, site, depth, party))
	return id


## The floor itself, in an area's shape: `rows`, `legend`, `layers`, `spawn`, `exits`, `stairs`,
## `bands`, `tint`, `display_name`, `hint`.
static func layout(world: World, site: Site, depth: int, party: Array) -> Dictionary:
	var r := rules()
	var rank := Site.rank_index(site.rank)
	var final := depth >= site.floors() - 1
	var width := int(r.get("width", 34)) + int(r.get("width_per_rank", 4)) * rank
	var height := int(r.get("height", 26)) + int(r.get("height_per_rank", 3)) * rank
	var count := maxi(2, roundi(float(r.get("chambers", 3)) + float(r.get("chambers_per_rank", 0.6)) * rank))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.world_seed, "gate inside", site.cell.x, site.cell.y, depth])
	var theme := ground(world, site, depth)
	var open := int(theme.get("open", 0))
	width += open * 4
	height += open * 2

	var grid: Array = []
	for y in height:
		var row: Array = []
		row.resize(width)
		row.fill(WALL)
		grid.append(row)

	# The chambers, bottom to top, swinging from side to side so the way through winds.
	var rooms: Array[Rect2i] = []
	var top := 3
	var bottom := height - 4
	for i in count:
		var t := float(i) / float(maxi(1, count - 1))
		var cy := roundi(lerpf(float(bottom), float(top), t))
		var half_w := rng.randi_range(5, 6 + rank / 2) + open * 2
		var half_h := rng.randi_range(3, 4 + rank / 3) + open
		var side := (i % 2) * 2 - 1
		var cx := width / 2 + side * rng.randi_range(0, width / 4)
		if i == 0 or i == count - 1:
			cx = width / 2 + rng.randi_range(-2, 2)
		cx = clampi(cx, half_w + 2, width - half_w - 3)
		cy = clampi(cy, half_h + 2, height - half_h - 3)
		rooms.append(Rect2i(cx - half_w, cy - half_h, half_w * 2 + 1, half_h * 2 + 1))
	for room in rooms:
		_carve_room(grid, room, rng)
	# The passages: a cut three wide from each chamber to the next, a worn track down its middle.
	for i in range(1, rooms.size()):
		_carve_passage(grid, _centre(rooms[i - 1]), _centre(rooms[i]), rng, 1 + open)
	# The doorway below the first chamber and the way down above the last.
	var door := Vector2i(_centre(rooms[0]).x, height - 1)
	_carve_passage(grid, _centre(rooms[0]), door, rng)
	var down := Vector2i(_centre(rooms[-1]).x, 0)
	_carve_passage(grid, _centre(rooms[-1]), Vector2i(down.x, 1), rng)
	# Only the doorway is open on the bottom row and only the way down on the top one: any other
	# edge cell would be a way out of the floor.
	for x in width:
		if absi(x - door.x) > 1:
			grid[height - 1][x] = WALL
		if x != down.x and x != down.x + 1:
			grid[0][x] = WALL
	grid[0][down.x] = PATH
	grid[0][down.x + 1] = PATH
	grid[1][down.x + 1] = PATH
	for x in [0, width - 1]:
		for y in height:
			grid[y][x] = WALL

	var rows: Array = []
	for row: Array in grid:
		rows.append("".join(PackedStringArray(row)))
	var look := Database.area(str(site.data.get("area", "gate")))
	return {
		"display_name": "%s, floor %d of %d" % [site.display_name, depth + 1, site.floors()],
		"ground": str(theme.get("name", "")),
		"rows": rows,
		"legend": {
			FLOOR: str(theme.get("floor", "stone")), PATH: str(theme.get("path", "dirt")),
			WALL: str(theme.get("wall", "crag")), COVER: str(theme.get("cover", "grass")),
		},
		"layers": theme.get("layers", ["stone", "dirt", "crag"]),
		"tint": str(look.get("tint", "")),
		"hint": str(r.get("hint", "")),
		"spawn": [door.x, height - 3],
		"exits": [[door.x - 1, height - 1], [door.x, height - 1], [door.x + 1, height - 1]],
		"stairs": [[down.x, 0], [down.x + 1, 0]],
		"bands": _bands(world, site, depth, final, party, rooms, down, rng, grid),
		"gate_inside": true,
		# A first of a kind teaches in here (D301); a cave keeps this when it is laid out like a gate.
		"teaches": true,
	}


## The bands holding the chambers: one in each but the doorway's; the last floor's last is its keeper.
static func _bands(world: World, site: Site, depth: int, final: bool, party: Array, rooms: Array[Rect2i],
		down: Vector2i, rng: RandomNumberGenerator, grid: Array) -> Array:
	var out: Array = []
	var delves := int(site.data.get("delves", 0))
	var reach := int(rules().get("band_reach", 3))
	var rank := Site.rank_index(site.rank)
	var stout: Array = rules().get("keeper_stout", [])
	# A bigger gate's chambers hold two bands now and then: the longer the rank, the longer the gate.
	var holds: Array = []
	for i in range(1, rooms.size()):
		holds.append(i)
		var last := final and i == rooms.size() - 1
		if not last and rank >= int(rules().get("from_rank_two_bands", 99)) and rng.randf() < float(rules().get("two_band_chance", 0.0)):
			holds.append(-i)
	for hold: int in holds:
		var i := absi(hold)
		var keeper := final and i == rooms.size() - 1
		var met := Encounter.for_gate(world, site, depth, keeper, party, rng)
		var pack: Array = []
		var level := 1
		var boss := ""
		for foe: Dictionary in met.get("enemies", []):
			if bool(foe.get("boss", false)):
				boss = str(foe.get("unit", ""))
			else:
				pack.append(str(foe.get("unit", "")))
			level = maxi(level, int(foe.get("level", 1)))
		# The keeper leads its band, as a fought keeper's fight has it first.
		if boss != "":
			pack.push_front(boss)
		if pack.is_empty():
			continue
		var key := "%s_%d_%s" % [area_id(site, depth), delves, "keeper" if keeper else char(96 + i) + ("2" if hold < 0 else "")]
		var at := _centre(rooms[i])
		if hold < 0:
			# The second band of a chamber, off to one side of the first, on open floor.
			at = _open_beside(grid, at, clampi(rooms[i].size.x / 3, 2, 4))
		if keeper:
			# In front of the way down, where nobody walks past it.
			at = Vector2i(down.x, mini(at.y, rooms[i].position.y + 1))
		out.append({
			"key": key,
			"pack": pack,
			"label": str(met.get("title", site.display_name)) if keeper else _who(pack),
			"faction": str(site.data.get("faction", "")),
			"at": [at.x, at.y],
			"reach": reach + (1 if keeper else 0),
			"level": level,
			"boss": keeper,
			"stout": float(stout[mini(rank, stout.size() - 1)]) if keeper and not stout.is_empty() else 1.0,
			"held": true,
			"requires_not": "done:%s" % key,
			"done_flag": "done:%s" % key,
		})
	return out


## What a band is called when it sees the party: "A goblin and 2 more".
static func _who(pack: Array) -> String:
	var first := str(Database.unit_template(str(pack[0])).get("display_name", "Something"))
	if pack.size() == 1:
		return first
	return "%s and %d more" % [first, pack.size() - 1]


## The ground [param depth] of [param site] is laid in: `floor`, `path`, `wall`, `cover`, `layers`,
## `open` and `name`. The first floor is the land's kind round the gate; a deeper floor of a gate of
## `from_rank_vary` or more is any other kind, the same one every time for that floor.
static func ground(world: World, site: Site, depth: int) -> Dictionary:
	var r := rules()
	var grounds: Dictionary = r.get("grounds", {})
	if grounds.is_empty():
		return {}
	var kind := str(r.get("by_area", {}).get(str(site.data.get("area", "")), ""))
	if kind == "":
		kind = str(r.get("by_land", {}).get(Biome.at(world, site.cell), "cave"))
	if depth > 0 and Site.rank_index(site.rank) >= int(r.get("from_rank_vary", 99)):
		var kinds: Array = grounds.keys()
		kinds.sort()
		kinds.erase(kind)
		var roll := RandomNumberGenerator.new()
		roll.seed = hash([world.world_seed, "gate ground", site.cell.x, site.cell.y, depth])
		kind = str(kinds[roll.randi_range(0, kinds.size() - 1)])
	return look_of(grounds.get(kind, grounds.get("cave", {})))


## A kind of ground spelled out: one with `biome` takes that land's floor, bare ground, pool and
## cover, and its three sheets, unless it says otherwise.
static func look_of(kind: Dictionary) -> Dictionary:
	var look := kind.duplicate()
	var land := str(kind.get("biome", ""))
	if land != "":
		var own := {
			"floor": land + "_floor", "path": land + "_bare", "wall": land + "_liquid", "cover": land + "_cover",
			"layers": [land + "_ground", land + "_pool", land + "_cover"],
		}
		for key: String in own:
			if not look.has(key):
				look[key] = own[key]
		# Walls of rock on a land's ground need the rock's sheet over it.
		if str(look["wall"]) == "crag" and not (look["layers"] as Array).has("crag"):
			look["layers"] = (look["layers"] as Array) + ["crag"]
	return look


## The open cell nearest [param apart] cells to one side of [param from] (either side), else [param from].
static func _open_beside(grid: Array, from: Vector2i, apart: int) -> Vector2i:
	for step in range(apart, 0, -1):
		for side in [1, -1]:
			var at := from + Vector2i(step * side, 0)
			if _inside(grid, at) and grid[at.y][at.x] != WALL:
				return at
	return from


static func _centre(room: Rect2i) -> Vector2i:
	return room.position + room.size / 2


## A chamber: rounded off at the corners and ragged at the edge, never a box, with long grass or
## loose ground in a patch or two.
static func _carve_room(grid: Array, room: Rect2i, rng: RandomNumberGenerator) -> void:
	var c := Vector2(_centre(room))
	var rx := float(room.size.x) / 2.0
	var ry := float(room.size.y) / 2.0
	for y in range(room.position.y - 1, room.end.y + 1):
		for x in range(room.position.x - 1, room.end.x + 1):
			if not _inside(grid, Vector2i(x, y)):
				continue
			var d := pow((x - c.x) / rx, 2.0) + pow((y - c.y) / ry, 2.0)
			if d <= 1.0 + rng.randf_range(-0.25, 0.2):
				grid[y][x] = FLOOR
	for patch in rng.randi_range(1, 2):
		var at := Vector2i(rng.randi_range(room.position.x + 1, room.end.x - 2), rng.randi_range(room.position.y + 1, room.end.y - 2))
		for y in range(at.y - 1, at.y + 2):
			for x in range(at.x - 1, at.x + 2):
				if _inside(grid, Vector2i(x, y)) and grid[y][x] == FLOOR and rng.randf() < 0.75:
					grid[y][x] = COVER


## A passage from [param from] to [param to]: across, then up or down, three cells wide, a track
## down the middle where the feet go.
static func _carve_passage(grid: Array, from: Vector2i, to: Vector2i, rng: RandomNumberGenerator, half: int = 1) -> void:
	var cells: Array[Vector2i] = []
	var bend := Vector2i(to.x, from.y) if rng.randf() < 0.5 else Vector2i(from.x, to.y)
	for leg: Array in [[from, bend], [bend, to]]:
		var a: Vector2i = leg[0]
		var b: Vector2i = leg[1]
		var step := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
		var at := a
		cells.append(at)
		while at != b:
			at += step
			cells.append(at)
	for cell in cells:
		for y in range(cell.y - half, cell.y + half + 1):
			for x in range(cell.x - half, cell.x + half + 1):
				if _inside(grid, Vector2i(x, y)) and grid[y][x] == WALL:
					grid[y][x] = FLOOR
	for cell in cells:
		if _inside(grid, cell):
			grid[cell.y][cell.x] = PATH


static func _inside(grid: Array, cell: Vector2i) -> bool:
	return cell.y >= 0 and cell.y < grid.size() and cell.x >= 0 and cell.x < (grid[0] as Array).size()
