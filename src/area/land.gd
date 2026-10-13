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

## How far a path is looked for round where it starts and ends, before looking wider.
const PATH_MARGIN := 10
const PATH_MARGIN_WIDE := 28

var world: World
## The size of one tile's slot, in cells.
var slot := Vector2i(32, 22)
## Tile -> its slot, as [method GroundGen.slot] laid it out, plus `origin` (the land cell of its
## top left) and `place_rect` (where its place stands, in land cells, or an empty rect).
var chunks: Dictionary = {}
## Campfires standing on the land, by cell.
var fires: Dictionary = {}

## Cell -> the building standing on it.
var _building_cells: Dictionary = {}


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
	var laid := GroundGen.slot(world, tile)
	var chunk := laid.duplicate()
	var origin := tile * slot
	chunk["tile"] = tile
	chunk["origin"] = origin
	var place: Dictionary = laid.get("place", {})
	chunk["place_rect"] = _rect(place.get("rect", []), origin) if not place.is_empty() else Rect2i()
	chunks[tile] = chunk
	var mine: Array[Dictionary] = []
	for prop: Dictionary in laid.get("props", []):
		if not _flags_allow(prop):
			continue
		var placed := prop.duplicate(true)
		placed["cell"] = _cell(prop.get("cell", [0, 0]), origin)
		placed["_tile"] = tile
		if AreaProp.is_solid(placed):
			for cell: Vector2i in base_cells(placed):
				_blocked[cell] = true
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
	for entry: Dictionary in laid.get("buildings", []):
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
	for person: Dictionary in laid.get("people", []):
		var placed := person.duplicate(true)
		placed["cell"] = [int(person.get("cell", [0, 0])[0]) + origin.x, int(person.get("cell", [0, 0])[1]) + origin.y]
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


## Let [param tile] go: everything standing in it comes off the land.
func release(tile: Vector2i) -> void:
	if not chunks.has(tile):
		return
	chunks.erase(tile)
	var area := slot_rect(tile)
	props = props.filter(func(prop: Dictionary) -> bool: return prop.get("_tile") != tile)
	buildings = buildings.filter(func(b: Dictionary) -> bool: return b.get("_tile") != tile)
	people = people.filter(func(p: Dictionary) -> bool: return p.get("_tile") != tile)
	for table: Dictionary in [chests, spots, spot_flags, wards, fires, _blocked, _building_cells, _props_at]:
		for cell: Vector2i in table.keys():
			if area.has_point(cell):
				table.erase(cell)


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
	return bool(Database.area_terrain(terrain_at(cell)).get("walkable", true))


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


## A way from [param from_cell] to [param to_cell] over the held land, worked out over the ground
## between them rather than all of it (the land is far too big for one grid).
func find_cell_path(from_cell: Vector2i, to_cell: Vector2i) -> Array[Vector2]:
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
	for margin: int in [PATH_MARGIN, PATH_MARGIN_WIDE]:
		var path := _path_within(from_cell, to_cell, margin)
		if not path.is_empty():
			return path
	return []


func _path_within(from_cell: Vector2i, to_cell: Vector2i, margin: int) -> Array[Vector2]:
	var lo := Vector2i(mini(from_cell.x, to_cell.x), mini(from_cell.y, to_cell.y)) - Vector2i.ONE * margin
	var hi := Vector2i(maxi(from_cell.x, to_cell.x), maxi(from_cell.y, to_cell.y)) + Vector2i.ONE * margin
	var region := Rect2i(lo, hi - lo + Vector2i.ONE).intersection(bounds())
	var grid := AStarGrid2D.new()
	grid.region = region
	grid.cell_size = Vector2(CELL, CELL)
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var cell := Vector2i(x, y)
			if not is_walkable(cell):
				grid.set_point_solid(cell, true)
	if grid.is_point_solid(from_cell):
		grid.set_point_solid(from_cell, false)
	var path: Array[Vector2] = []
	for cell: Vector2i in grid.get_id_path(from_cell, to_cell):
		path.append(centre_of(cell))
	return path


func setup_astar() -> void:
	pass


func update_cell_solid(_cell: Vector2i, _is_solid: bool) -> void:
	pass


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
