## Loaded by path ([D41]): `const Land := preload("res://src/area/land.gd")`.
extends AreaMap
## The continent laid out as one stretch of ground ([D84]): every tile its own slot of land
## ([method GroundGen.slot]), side by side, so walking from one into the next is walking on.
##
## Cells are the land's own: a tile's slot starts at `tile × slot size`. Only the tiles round the
## party are held at once ([method hold]); anything outside them is nowhere, and not walkable.
## Everything an [AreaMap] answers, this answers for whatever is held, so the area scene, the bands
## and the fight that starts on it walk it the same way they walk any area.
##
## A place keeps its own cells for anything written down about it (a chest opened, a ward
## forced): [method area_of] and [method local_of] say whose cell a land cell is.

const GroundGen := preload("res://src/area/ground_gen.gd")

var world: World
## The size of one tile's slot, in cells.
var slot := Vector2i(32, 22)
## Tile -> its slot, as [method GroundGen.slot] laid it out, plus `origin` (the land cell of its
## top left) and `place_rect` (where its place stands, in land cells, or an empty rect).
var chunks: Dictionary = {}
## Campfires standing on the land, by cell.
var fires: Dictionary = {}
## The shallows are walked through, not round, while the company carries a land journal's stilts or
## boots ([D239]). Whoever is on the land with them, a band or a fight, finds the same ground.
var wading: bool = false:
	set(on):
		if on != wading:
			_grid = null
			_steps = null
			for chunk: Dictionary in chunks.values():
				chunk.erase("_walkable")
		wading = on

## Cell -> the building standing on it.
var _building_cells: Dictionary = {}
## The held land as one grid to find ways over, kept until what is held changes: worked out afresh
## for every way, it was every townsperson in Stormreach going round the streets weighing up a
## thousand cells each (play-test 7: "massive frame rate drop" in the city).
var _grid: AStarGrid2D = null
## On held land with heights ([D328]), the same cells as a graph whose steps go one way where a rise
## is only dropped off ([AreaMap.may_step]), kept like [member _grid].
var _steps: AStar2D = null


## The land round [param tile], held [param radius] tiles each way.
static func around(world_: World, tile: Vector2i, radius: int = 1) -> AreaMap:
	var land = (load("res://src/area/land.gd") as GDScript).new()
	land.setup(world_)
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			land.hold(tile + Vector2i(dx, dy))
	return land


func setup(world_: World) -> void:
	world = world_
	id = "land"
	display_name = "the land"
	var size: Array = Database.biomes.get("size", [32, 22])
	slot = Vector2i(int(size[0]), int(size[1]))
	fire = Vector2i(-1, -1)


func tile_of(cell: Vector2i) -> Vector2i:
	return Vector2i(floori(float(cell.x) / slot.x), floori(float(cell.y) / slot.y))


func slot_rect(tile: Vector2i) -> Rect2i:
	return Rect2i(tile * slot, slot)


func is_held(tile: Vector2i) -> bool:
	return chunks.has(tile)


## Lay out [param tile]'s slot and put everything in it on the land. Returns the chunk, or the one
## already held.
func hold(tile: Vector2i) -> Dictionary:
	if chunks.has(tile):
		return chunks[tile]
	_grid = null
	_steps = null
	var laid := GroundGen.slot(world, tile)
	var chunk := laid.duplicate()
	var origin := tile * slot
	chunk["tile"] = tile
	chunk["origin"] = origin
	var place: Dictionary = laid.get("place", {})
	chunk["place_rect"] = _rect(place.get("rect", []), origin) if not place.is_empty() else Rect2i()
	chunks[tile] = chunk
	var mine: Array[Dictionary] = []
	# What has been built since the place was laid out clears its ground of anything drawn there ([D251]).
	var raised := (laid.get("buildings", []) as Array).filter(func(b: Dictionary) -> bool:
		return b.has("requires") and _flags_allow(b))
	for prop: Dictionary in laid.get("props", []):
		if not _flags_allow(prop) or _cleared_by(prop, raised):
			continue
		var placed := prop.duplicate(true)
		placed["cell"] = _cell(prop.get("cell", [0, 0]), origin)
		placed["_tile"] = tile
		if AreaProp.is_solid(placed):
			for cell: Vector2i in base_cells(placed):
				_blocked[cell] = true
				_spilled(cell, tile)
		props.append(placed)
		_index_prop(placed)
	for chest: Dictionary in laid.get("chests", []):
		var placed := chest.duplicate(true)
		placed["_tile"] = tile
		chests[_cell(chest.get("cell", [0, 0]), origin)] = placed
	for spot: Dictionary in laid.get("spots", []):
		var at := _cell(spot.get("cell", [0, 0]), origin)
		spots[at] = spot.get("line", "")
		if spot.has("set_flag"):
			spot_flags[at] = str(spot["set_flag"])
		if bool(spot.get("page", false)):
			story_pages[at] = true
	for entry: Dictionary in laid.get("buildings", []):
		if not _flags_allow(entry):
			continue
		var building := entry.duplicate(true)
		building["cell"] = _cell(entry.get("cell", [0, 0]), origin)
		var look := Database.building_art(str(entry.get("art", "")))
		building["size"] = AreaMap.to_cell(entry.get("size", look.get("size", [3, 3])))
		var front_door := Vector2i(building["cell"].x + building["size"].x / 2, building["cell"].y + building["size"].y - 1)
		building["door"] = _cell(entry["door"], origin) if entry.has("door") \
			else (front_door if not look.is_empty() else building["cell"])
		building["_tile"] = tile
		buildings.append(building)
		var foot := footprint(building)
		for y in range(foot.position.y, foot.end.y):
			for x in range(foot.position.x, foot.end.x):
				_building_cells[Vector2i(x, y)] = building
				_spilled(Vector2i(x, y), tile)
	for person: Dictionary in laid.get("people", []):
		if not _flags_allow(person):
			continue
		var placed := person.duplicate(true)
		placed["cell"] = [int(person.get("cell", [0, 0])[0]) + origin.x, int(person.get("cell", [0, 0])[1]) + origin.y]
		for stop: Dictionary in placed.get("rounds", []):
			var at := _cell(stop.get("cell", [0, 0]), origin)
			stop["cell"] = [at.x, at.y]
		placed["_tile"] = tile
		placed["_area"] = str(laid.get("id", ""))
		people.append(placed)
	for entry: Dictionary in laid.get("wards", []):
		var ward := entry.duplicate(true)
		ward["cell"] = _cell(entry.get("cell", [0, 0]), origin)
		ward["_tile"] = tile
		wards[ward["cell"]] = ward
	for pair: Array in laid.get("fires", []):
		fires[_cell(pair, origin)] = tile
	# Rises of the land's floor, climbed only at their slopes ([D328]).
	for pair: Variant in laid.get("ways_up", []):
		ways_up[_cell(pair, origin)] = true
	for pair: Variant in laid.get("ladders", []):
		ladders[_cell(pair, origin)] = true
	chunk["_heights"] = _has_heights(laid.get("terrain", PackedStringArray()))
	_heights_vary = chunks.values().any(func(c: Dictionary) -> bool: return bool(c.get("_heights", false)))
	# Where somebody is meant to stand stays open, whatever is drawn there.
	var stood_on: Array[Vector2i] = [_cell(laid.get("spawn", [0, 0]), origin)]
	for chest: Dictionary in laid.get("chests", []):
		stood_on.append(_cell(chest.get("cell", [0, 0]), origin))
	for spot: Dictionary in laid.get("spots", []):
		stood_on.append(_cell(spot.get("cell", [0, 0]), origin))
	for person: Dictionary in laid.get("people", []):
		stood_on.append(_cell(person.get("cell", [0, 0]), origin))
	for cell in stood_on:
		_blocked.erase(cell)
	return chunk


## A thing of [param tile]'s standing over its edge onto [param cell] of a tile held before it: that
## tile's own count of its ground is worked out again, or the kept grid walked Auto into a tree
## sticking over from the next tile and held it there for good.
func _spilled(cell: Vector2i, tile: Vector2i) -> void:
	var other := tile_of(cell)
	if other != tile and chunks.has(other):
		(chunks[other] as Dictionary).erase("_walkable")


## Let [param tile] go: everything standing in it comes off the land.
func release(tile: Vector2i) -> void:
	if not chunks.has(tile):
		return
	_grid = null
	_steps = null
	chunks.erase(tile)
	var area := slot_rect(tile)
	props = props.filter(func(prop: Dictionary) -> bool: return prop.get("_tile") != tile)
	buildings = buildings.filter(func(b: Dictionary) -> bool: return b.get("_tile") != tile)
	people = people.filter(func(p: Dictionary) -> bool: return p.get("_tile") != tile)
	for table: Dictionary in [chests, spots, spot_flags, story_pages, wards, fires, _blocked, _building_cells, _props_at, ways_up, ladders]:
		for cell: Vector2i in table.keys():
			if area.has_point(cell):
				table.erase(cell)
	_heights_vary = chunks.values().any(func(c: Dictionary) -> bool: return bool(c.get("_heights", false)))


## Whether any of [param terrain] stands a height up.
static func _has_heights(terrain: PackedStringArray) -> bool:
	var looked := {}
	for id: String in terrain:
		if looked.has(id):
			continue
		looked[id] = true
		if int(Database.area_terrain(id).get("height", 0)) != 0:
			return true
	return false


## The tiles held, nearest [param to] first.
func held_tiles() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(chunks.keys())
	return out


## Whose cell [param cell] is, for anything written down about it: the place standing there, or
## the tile's own ground.
func area_of(cell: Vector2i) -> String:
	var chunk: Dictionary = chunks.get(tile_of(cell), {})
	return str(chunk.get("id", id))


func local_of(cell: Vector2i) -> Vector2i:
	var chunk: Dictionary = chunks.get(tile_of(cell), {})
	if chunk.is_empty():
		return cell
	var rect: Rect2i = chunk["place_rect"]
	if rect.size != Vector2i.ZERO:
		return cell - rect.position
	return cell - (chunk["origin"] as Vector2i)


## The chunk [param cell] is in, or an empty one.
func chunk_at(cell: Vector2i) -> Dictionary:
	return chunks.get(tile_of(cell), {})


## Whether [param cell] is inside the place standing in its tile.
func in_place(cell: Vector2i) -> bool:
	var chunk := chunk_at(cell)
	return not chunk.is_empty() and (chunk["place_rect"] as Rect2i).has_point(cell)


# --- what an area answers -----------------------------------------------------------------


func in_bounds(cell: Vector2i) -> bool:
	return chunks.has(tile_of(cell))


func terrain_at(cell: Vector2i) -> String:
	var chunk: Dictionary = chunks.get(tile_of(cell), {})
	if chunk.is_empty():
		return ""
	var local: Vector2i = cell - (chunk["origin"] as Vector2i)
	return (chunk["terrain"] as PackedStringArray)[local.y * slot.x + local.x]


func is_walkable(cell: Vector2i) -> bool:
	var chunk: Dictionary = chunks.get(tile_of(cell), {})
	if chunk.is_empty():
		return false
	if _blocked.has(cell) or fires.has(cell):
		return false
	if wards.has(cell) and not Ward.is_open(area_of(cell), local_of(cell)):
		return false
	var building: Variant = _building_cells.get(cell, null)
	if building != null and (building as Dictionary)["door"] != cell:
		return false
	var terrain := terrain_at(cell)
	# Pools in open country only: the sea round a tile of it stays the sea.
	if wading and str(chunk.get("kind", "")) == "ground" and (terrain == "water" or terrain.ends_with("_liquid")):
		return true
	return bool(Database.area_terrain(terrain).get("walkable", true))


func building_at(cell: Vector2i) -> Dictionary:
	return _building_cells.get(cell, {})


func is_exit(_cell: Vector2i) -> bool:
	return false


func chest_flag(cell: Vector2i) -> String:
	var local := local_of(cell)
	return "chest:%s:%d,%d" % [area_of(cell), local.x, local.y]


func prop_flag(cell: Vector2i) -> String:
	var local := local_of(cell)
	return "prop:%s:%d,%d" % [area_of(cell), local.x, local.y]


## The held tiles' cells, as one rectangle.
func bounds() -> Rect2i:
	var out := Rect2i()
	var first := true
	for tile: Vector2i in chunks:
		out = slot_rect(tile) if first else out.merge(slot_rect(tile))
		first = false
	return out


func rect() -> Rect2:
	var held := bounds()
	return Rect2(Vector2(held.position) * CELL, Vector2(held.size) * CELL)


## Each tile paints itself, with its own sheets: its ground, then its place over it.
func patches() -> Array:
	var out: Array = []
	for tile: Vector2i in chunks:
		out.append_array(patches_of(tile))
	return out


func patches_of(tile: Vector2i) -> Array:
	var chunk: Dictionary = chunks.get(tile, {})
	var out: Array = []
	for patch: Dictionary in chunk.get("patches", []):
		out.append({ "layers": patch.get("layers", []), "tiles": _rect(patch.get("rect", []), chunk["origin"]) })
	return out


## A way from [param from_cell] to [param to_cell] over the held land, on one grid kept for all of
## it ([method _held_grid]).
## With [param avoid] (cells as keys), a way that keeps off them, or none ([D216]: a party walking
## itself passively goes round a band's red).
func find_cell_path(from_cell: Vector2i, to_cell: Vector2i, avoid: Dictionary = {}) -> Array[Vector2]:
	if not in_bounds(from_cell) or not in_bounds(to_cell):
		return []
	if not is_walkable(to_cell):
		var best := Vector2i(-1, -1)
		var best_dist := INF
		for offset: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = to_cell + offset
			if is_walkable(n):
				var d := float(absi(from_cell.x - n.x) + absi(from_cell.y - n.y))
				if d < best_dist:
					best_dist = d
					best = n
		if best == Vector2i(-1, -1):
			return []
		to_cell = best
	return _path_within(from_cell, to_cell, avoid)


func _path_within(from_cell: Vector2i, to_cell: Vector2i, avoid: Dictionary = {}) -> Array[Vector2]:
	var grid := _held_grid()
	# What is shut for this way alone is opened again after it.
	var shut: Array[Vector2i] = []
	for cell: Vector2i in avoid:
		if grid.is_in_boundsv(cell) and not grid.is_point_solid(cell):
			grid.set_point_solid(cell, true)
			shut.append(cell)
	var opened := grid.is_in_boundsv(from_cell) and grid.is_point_solid(from_cell)
	if opened:
		grid.set_point_solid(from_cell, false)
	var path: Array[Vector2] = []
	for cell: Vector2i in grid.get_id_path(from_cell, to_cell):
		path.append(centre_of(cell))
	if opened:
		grid.set_point_solid(from_cell, true)
	for cell: Vector2i in shut:
		grid.set_point_solid(cell, false)
	# On held land with heights ([D328]) the grid's way stands unless it climbs a rise where there is
	# no slope; then the way is found again on the graph that knows which way a step goes.
	if _heights_vary:
		for i in range(1, path.size()):
			if not may_step(cell_at(path[i - 1]), cell_at(path[i])):
				return _path_over_heights(from_cell, to_cell, avoid)
	return path


## A way over held land with heights ([D328]): on [member _steps], so it climbs a rise only at a slope
## and drops off one anywhere ([D312]'s rule, with no extra cost: a rise is one height, which never hurts).
func _path_over_heights(from_cell: Vector2i, to_cell: Vector2i, avoid: Dictionary = {}) -> Array[Vector2]:
	var steps := _held_steps()
	var region := bounds()
	var id_of := func(cell: Vector2i) -> int:
		return (cell.y - region.position.y) * region.size.x + (cell.x - region.position.x)
	var path: Array[Vector2] = []
	if not steps.has_point(id_of.call(to_cell)):
		return path
	var shut: Array[int] = []
	for cell: Vector2i in avoid:
		var id: int = id_of.call(cell)
		if steps.has_point(id) and not steps.is_point_disabled(id):
			steps.set_point_disabled(id, true)
			shut.append(id)
	# Standing somewhere no way is found from (a door, a fire), the walk starts from the nearest it is.
	var from_id: int = id_of.call(from_cell)
	var added := not steps.has_point(from_id)
	if added:
		steps.add_point(from_id, Vector2(from_cell))
		for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next_id: int = id_of.call(from_cell + side)
			if steps.has_point(next_id) and may_step(from_cell, from_cell + side):
				steps.connect_points(from_id, next_id, false)
	for id in steps.get_id_path(from_id, id_of.call(to_cell)):
		path.append(centre_of(Vector2i(steps.get_point_position(id))))
	if added:
		steps.remove_point(from_id)
	for id in shut:
		steps.set_point_disabled(id, false)
	return path


## Every walkable cell held, joined to each neighbour it may step onto; laid out again when the held
## land changes, like [method _held_grid].
func _held_steps() -> AStar2D:
	if _steps != null:
		return _steps
	var grid := _held_grid()
	var region := bounds()
	_steps = AStar2D.new()
	_steps.reserve_space(region.size.x * region.size.y)
	# Each cell's height read once, by terrain, rather than at every step weighed.
	var tall := PackedInt32Array()
	tall.resize(region.size.x * region.size.y)
	var by_terrain := {}
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var cell := Vector2i(x, y)
			var id := (y - region.position.y) * region.size.x + (x - region.position.x)
			if grid.is_point_solid(cell):
				tall[id] = -1
				continue
			var terrain := terrain_at(cell)
			if not by_terrain.has(terrain):
				by_terrain[terrain] = int(Database.area_terrain(terrain).get("height", 0))
			tall[id] = by_terrain[terrain]
			_steps.add_point(id, Vector2(cell))
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var id := (y - region.position.y) * region.size.x + (x - region.position.x)
			if tall[id] < 0:
				continue
			for side: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
				var nx := x + side.x
				var ny := y + side.y
				if nx >= region.end.x or ny >= region.end.y:
					continue
				var next_id := (ny - region.position.y) * region.size.x + (nx - region.position.x)
				if tall[next_id] < 0:
					continue
				var rise := tall[next_id] - tall[id]
				if rise == 0:
					_steps.connect_points(id, next_id)
					continue
				var by_slope := scaling or ways_up.has(Vector2i(x, y)) or ways_up.has(Vector2i(nx, ny))
				var reach := 1
				if ladders.has(Vector2i(x, y)) or ladders.has(Vector2i(nx, ny)):
					by_slope = true
					reach = ladder_most()
				var there := rise < 0 or (rise <= reach and by_slope)
				var back := rise > 0 or (-rise <= reach and by_slope)
				if there and back:
					_steps.connect_points(id, next_id)
				elif there:
					_steps.connect_points(id, next_id, false)
				elif back:
					_steps.connect_points(next_id, id, false)
	return _steps


## The grid over everything held, every cell that cannot be walked shut; laid out again when the
## held land changes, from what each tile already knows of its own ground ([method _walkable_in]).
func _held_grid() -> AStarGrid2D:
	if _grid != null:
		return _grid
	var region := bounds()
	_grid = AStarGrid2D.new()
	_grid.region = region
	_grid.cell_size = Vector2(CELL, CELL)
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_grid.update()
	# Between held tiles is nowhere: shut, then each tile opened and its own shut cells shut again.
	_grid.fill_solid_region(region, true)
	for tile: Vector2i in chunks:
		_grid.fill_solid_region(slot_rect(tile), false)
		var origin := tile * slot
		var open := _walkable_in(tile)
		for i in open.size():
			if open[i] == 0:
				_grid.set_point_solid(origin + Vector2i(i % slot.x, i / slot.x), true)
	return _grid


## Which of [param tile]'s cells can be walked, one byte a cell, row by row; worked out once a tile
## is held and kept with it.
func _walkable_in(tile: Vector2i) -> PackedByteArray:
	var chunk: Dictionary = chunks[tile]
	if chunk.has("_walkable"):
		return chunk["_walkable"]
	var origin := tile * slot
	var open := PackedByteArray()
	open.resize(slot.x * slot.y)
	for y in slot.y:
		for x in slot.x:
			open[y * slot.x + x] = 1 if is_walkable(origin + Vector2i(x, y)) else 0
	chunk["_walkable"] = open
	return open


func setup_astar() -> void:
	pass


## A ward forced, a prop gone: the kept grid and the tile's own count of its ground follow.
func update_cell_solid(cell: Vector2i, is_solid: bool) -> void:
	var chunk: Dictionary = chunks.get(tile_of(cell), {})
	if chunk.has("_walkable"):
		var local: Vector2i = cell - (chunk["origin"] as Vector2i)
		(chunk["_walkable"] as PackedByteArray)[local.y * slot.x + local.x] = 0 if is_solid else 1
	if _grid != null and _grid.is_in_boundsv(cell):
		_grid.set_point_solid(cell, is_solid)
	_steps = null


static func _cell(pair: Variant, origin: Vector2i) -> Vector2i:
	if pair is Vector2i:
		return (pair as Vector2i) + origin
	var at: Array = pair if pair is Array else [0, 0]
	return AreaMap.to_cell(at) + origin


static func _rect(values: Variant, origin: Vector2i) -> Rect2i:
	var at: Array = values if values is Array else []
	if at.size() < 4:
		return Rect2i()
	return Rect2i(Vector2i(int(at[0]), int(at[1])) + origin, Vector2i(int(at[2]), int(at[3])))


## Carry a rope or not ([D333]): the held graph of steps is laid out again.
func set_scaling(on: bool) -> void:
	if on != scaling:
		_steps = null
	scaling = on
