class_name AreaMap
extends RefCounted
## A walkable place: one terrain per cell, plus where you come in, where you
## leave, and what is worth stopping at.
##
## Tiles are drawn half a cell up and to the left of the grid, so a tile's four
## corners land on the middle of four cells. Standing in a cell therefore means
## standing on that cell's terrain, whatever the transitions around it look like.

const CELL := 64

var id: String = ""
var display_name: String = ""
var width: int = 0
var height: int = 0
## Sheet ids from `data/tilesets.json`, bottom layer first.
var layers: Array[String] = []
var spawn: Vector2i = Vector2i.ZERO
var exits: Array[Vector2i] = []
## The stair up, on a floor of the Tower that is walked ([D102]): standing on it climbs.
var stairs: Array[Vector2i] = []
## cell -> the line said when the party first stands there.
var spots: Dictionary = {}
## cell -> a flag standing there sets: something found for somebody's favour ([Talk]).
var spot_flags: Dictionary = {}
## The spots that are pages of the place's story ([D314]): cell -> true.
var story_pages: Dictionary = {}
## cell -> what is in the chest sitting on it; opened ones stay opened.
var chests: Dictionary = {}
## Houses standing in the area: solid ground with one door leading inside.
var buildings: Array[Dictionary] = []
## Furniture and dressing standing about; see [AreaProp].
var props: Array[Dictionary] = []
## Somebody standing in the area waiting to be spoken to; see [AreaScene].
var people: Array[Dictionary] = []
## A campfire burning here, or (-1, -1) for a place with no fire.
var fire: Vector2i = Vector2i(-1, -1)
## A hearth anywhere inside (an inn, a tavern: the area's `hearth`), to brew by ([D346]).
var hearth: bool = false
## Where the party sits when there is a fire to sit around.
var seats: Array[Vector2i] = []
## cell -> a thing in the way that is not a wall (see [Ward]).
var wards: Dictionary = {}
## Light the whole place is seen in, for areas that are not at noon.
var tint: String = ""
## A cutscene played the moment the party walks in.
var opening: String = ""
## What the bottom of the screen says when nobody is standing near anybody.
var hint: String = ""

## Bands the area places itself (a practice band in the tutorial's village, D75): the same shape
## the world sends, plus `spar` (fought as practice, never through the world), `at` (the spot it
## would rather stand on), `level`, `requires` / `requires_not` (flags) and `done_flag`. A `held`
## band is fought for real, with nobody from the world behind it (the Tower's floors, [D102]);
## `boss` marks a keeper.
var bands: Array = []
## Navigation grid ensuring characters navigate around walls rather than cutting through them.
var astar: AStarGrid2D = null

var _terrain: Array[String] = []
## Cells where higher ground can be climbed onto, or climbed off, from the ground a height below
## ([D308]): a slope, a ladder, a rope. Anywhere else a shelf is only dropped off.
var ways_up: Dictionary = {}
## Ladders ([D337]): cells where a ladder stands against a face, climbed up as far as `ladder_most`
## heights (`world_rules.json` → `heights`), a slope's way for a taller face.
var ladders: Dictionary = {}
## Whether the party carries a climbing rope ([D337]): any face one height up is a way up, as at a slope.
var scaling: bool = false
## Whether any terrain of this area stands a height up, so the step rule and the ledges apply.
var _heights_vary: bool = false
## Whether any terrain of this area is cloud round a mountain's top ([D321]), so the clouds are drawn.
var _clouds: bool = false
## Cells a piece of furniture is standing on, which nobody walks through.
var _blocked: Dictionary = {}
## Cell -> the props standing on it, so asking what is on a cell is not a walk through all of them.
var _props_at: Dictionary = {}


static func load_area(area_id: String) -> AreaMap:
	var data := Database.area(area_id)
	if data.is_empty():
		return null

	var map := AreaMap.new()
	map.id = area_id
	map.display_name = data.get("display_name", area_id)
	var legend: Dictionary = data.get("legend", {})
	var rows: Array = data.get("rows", [])
	map.height = rows.size()
	map.width = 0
	for row: String in rows:
		map.width = maxi(map.width, row.length())
	for row: String in rows:
		for x in map.width:
			var symbol := row.substr(x, 1) if x < row.length() else "."
			map._terrain.append(legend.get(symbol, "grass"))

	for sheet_id: String in data.get("layers", ["dirt"]):
		map.layers.append(sheet_id)
	for terrain_id: Variant in legend.values():
		if int(Database.area_terrain(str(terrain_id)).get("height", 0)) != 0:
			map._heights_vary = true
		if bool(Database.area_terrain(str(terrain_id)).get("clouds", false)):
			map._clouds = true
	for pair: Array in data.get("ways_up", []):
		map.ways_up[_to_cell(pair)] = true
	for pair: Array in data.get("ladders", []):
		map.ladders[_to_cell(pair)] = true
	map.spawn = _to_cell(data.get("spawn", [0, 0]))
	for pair: Array in data.get("exits", []):
		map.exits.append(_to_cell(pair))
	for pair: Array in data.get("stairs", []):
		map.stairs.append(_to_cell(pair))
	for spot: Dictionary in data.get("spots", []):
		map.spots[_to_cell(spot.get("cell", [0, 0]))] = spot.get("line", "")
		if spot.has("set_flag"):
			map.spot_flags[_to_cell(spot.get("cell", [0, 0]))] = str(spot["set_flag"])
		if bool(spot.get("page", false)):
			map.story_pages[_to_cell(spot.get("cell", [0, 0]))] = true
	for chest: Dictionary in data.get("chests", []):
		map.chests[_to_cell(chest.get("cell", [0, 0]))] = chest
	# `dressing` is scenery written by tools/dress_areas.py, kept apart from the props an area's
	# author placed so it can be written again without touching theirs.
	var raised := (data.get("buildings", []) as Array).filter(func(b: Dictionary) -> bool:
		return b.has("requires") and _flags_allow(b))
	for prop: Dictionary in data.get("props", []) + data.get("dressing", []):
		if not _flags_allow(prop) or _cleared_by(prop, raised):
			continue
		var placed := prop.duplicate(true)
		placed["cell"] = _to_cell(prop.get("cell", [0, 0]))
		# A place redrawn (`redrawn`: picture → its own new picture, [D371]) shows the new one once
		# it is in, wherever the old one stands, dressing included, so a re-dressing keeps it.
		var redrawn := str(data.get("redrawn", {}).get(str(placed.get("art", "")), ""))
		if redrawn != "" and AreaProp.has_art(redrawn):
			placed["art"] = redrawn
		if AreaProp.is_solid(placed):
			for cell: Vector2i in base_cells(placed):
				map._blocked[cell] = true
		map.props.append(placed)
		map._index_prop(placed)
	for entry: Dictionary in data.get("buildings", []):
		if not _flags_allow(entry):
			continue
		var building := entry.duplicate(true)
		building["cell"] = _to_cell(entry.get("cell", [0, 0]))
		# A building drawn from a picture stands on that picture's footprint unless it says otherwise,
		# with its door in the middle of the front row ([Database.building_art]).
		var look := Database.building_art(str(entry.get("art", "")))
		building["size"] = _to_cell(entry.get("size", look.get("size", [3, 3])))
		var front_door := [
			int(building["cell"].x) + int(building["size"].x) / 2,
			int(building["cell"].y) + int(building["size"].y) - 1,
		]
		building["door"] = _to_cell(entry.get("door", front_door if not look.is_empty() else entry.get("cell", [0, 0])))
		map.buildings.append(building)
	for person: Dictionary in data.get("people", []):
		if _flags_allow(person):
			map.people.append(person)
	if data.has("fire"):
		map.fire = _to_cell(data["fire"])
	map.hearth = bool(data.get("hearth", false))
	for pair: Array in data.get("seats", []):
		map.seats.append(_to_cell(pair))
	for entry: Dictionary in data.get("wards", []):
		var ward := entry.duplicate(true)
		ward["cell"] = _to_cell(entry.get("cell", [0, 0]))
		map.wards[ward["cell"]] = ward
	# A cell the area's author means somebody to stand on stays open, whatever is drawn there:
	# the spot by the fountain, a seat at the fire, a chest, where someone waits.
	var stood_on: Array[Vector2i] = [map.spawn]
	stood_on.append_array(map.exits)
	stood_on.append_array(map.stairs)
	stood_on.append_array(map.seats)
	for cell: Vector2i in map.spots:
		stood_on.append(cell)
	for cell: Vector2i in map.chests:
		stood_on.append(cell)
	for person: Dictionary in map.people:
		stood_on.append(_to_cell(person.get("cell", [0, 0])))
	for cell in stood_on:
		map._blocked.erase(cell)
	map.bands = data.get("bands", [])
	map.tint = data.get("tint", "")
	map.opening = data.get("opening", "")
	map.hint = data.get("hint", "")
	map.setup_astar()
	return map


func setup_astar() -> void:
	if width == 0 or height == 0:
		return
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, width, height)
	astar.cell_size = Vector2(CELL, CELL)
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for y in height:
		for x in width:
			var cell := Vector2i(x, y)
			if not is_walkable(cell):
				astar.set_point_solid(cell, true)


func update_cell_solid(cell: Vector2i, is_solid: bool) -> void:
	if astar != null and in_bounds(cell):
		astar.set_point_solid(cell, is_solid)


func find_path(from_pixel: Vector2, to_pixel: Vector2) -> Array[Vector2]:
	var from_cell := cell_at(from_pixel)
	var to_cell := cell_at(to_pixel)
	return find_cell_path(from_cell, to_cell)


func find_cell_path(from_cell: Vector2i, to_cell: Vector2i) -> Array[Vector2]:
	if astar == null:
		setup_astar()
	if not in_bounds(from_cell) or not in_bounds(to_cell):
		return []
	if not is_walkable(to_cell):
		var best_neighbor := Vector2i(-1, -1)
		var best_dist := INF
		for offset: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = to_cell + offset
			if is_walkable(n):
				var d := float(abs(from_cell.x - n.x) + abs(from_cell.y - n.y))
				if d < best_dist:
					best_dist = d
					best_neighbor = n
		if best_neighbor != Vector2i(-1, -1):
			to_cell = best_neighbor
		else:
			return []
	# Ground with heights is walked only where a walker may step ([D312]).
	if _heights_vary:
		return _height_path(from_cell, to_cell)
	var cell_path := astar.get_id_path(from_cell, to_cell)
	var path: Array[Vector2] = []
	for cell in cell_path:
		path.append(centre_of(cell))
	return path


## The props standing on [param cell].
func props_at(cell: Vector2i) -> Array:
	return _props_at.get(cell, [])


## Something put down in the area after it was loaded (a lead's memory lying on a floor, D103):
## drawn like any prop, and stood on rather than walked round.
func place(prop: Dictionary) -> void:
	var placed := prop.duplicate(true)
	placed["solid"] = false
	props.append(placed)
	_index_prop(placed)
	_blocked.erase(placed["cell"])
	update_cell_solid(placed["cell"], not is_walkable(placed["cell"]))


func _index_prop(prop: Dictionary) -> void:
	var cell: Vector2i = prop["cell"]
	if not _props_at.has(cell):
		_props_at[cell] = []
	(_props_at[cell] as Array).append(prop)


## Every cell of the area, as one rectangle ([Land] answers for what it holds).
func bounds() -> Rect2i:
	return Rect2i(0, 0, width, height)


## What paints the ground: each part's sheets, bottom first, and the tiles it paints (a tile's
## corners sit on the middle of four cells; tile (x, y) has cell (x, y) at its bottom right). One
## part here, one more tile each way so the edge cells are painted all the way out.
func patches() -> Array:
	return [{ "layers": layers, "tiles": Rect2i(0, 0, width + 1, height + 1) }]


## Whose cell this is, for anything written down about it (a chest opened, a ward forced); an
## area's cells are its own. [Land] answers with the place or tile the cell belongs to.
func area_of(_cell: Vector2i) -> String:
	return id


func local_of(cell: Vector2i) -> Vector2i:
	return cell


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func terrain_at(cell: Vector2i) -> String:
	# Outside the map reads as its nearest edge, so the border tiles away
	# cleanly instead of transitioning against nothing.
	var clamped := Vector2i(clampi(cell.x, 0, width - 1), clampi(cell.y, 0, height - 1))
	return _terrain[clamped.y * width + clamped.x]


func is_walkable(cell: Vector2i) -> bool:
	if not in_bounds(cell):
		return false
	if cell == fire or _blocked.has(cell):
		return false
	if wards.has(cell) and not Ward.is_open(id, cell):
		return false
	var building := building_at(cell)
	if not building.is_empty() and building["door"] != cell:
		return false
	return bool(Database.area_terrain(terrain_at(cell)).get("walkable", true))


# --- heights ([D287], [D308]) --------------------------------------------------------------


## Whether this ground has any higher ground on it.
func has_heights() -> bool:
	return _heights_vary


## How many heights up [param cell] stands: its terrain's `height` (`tilesets.json`), 0 for most.
func height_at(cell: Vector2i) -> int:
	if not _heights_vary:
		return 0
	return int(Database.area_terrain(terrain_at(cell)).get("height", 0))


## Whether a walker on [param from] may step onto [param to]: down is always free, up one height only
## onto or off a way up (a slope), or anywhere with a rope ([member scaling]), up a ladder as far as it
## reaches ([D337]), up two or more otherwise never. [param to] still has to be walkable.
func may_step(from: Vector2i, to: Vector2i) -> bool:
	if not _heights_vary or from == to:
		return true
	var rise := height_at(to) - height_at(from)
	if rise <= 0:
		return true
	if ladders.has(to) or ladders.has(from):
		return rise <= ladder_most()
	return rise == 1 and (scaling or ways_up.has(to) or ways_up.has(from))


## How many heights a ladder climbs ([D337]).
static func ladder_most() -> int:
	return int(Database.world_rules.get("heights", {}).get("ladder_most", 2))


## Carry a rope or not ([D337]); a way already found is found again.
func set_scaling(on: bool) -> void:
	scaling = on


## Whether any of this ground is cloud below a mountain's top ([D287], [D321]).
func has_clouds() -> bool:
	return _clouds


## Whether [param cell] is cloud: never walked, drawn as the sky below, and in a fight a body shoved
## into it is gone ([D321]).
func is_cloud(cell: Vector2i) -> bool:
	return _clouds and in_bounds(cell) and bool(Database.area_terrain(terrain_at(cell)).get("clouds", false))


## How many heights a walker drops stepping from [param from] to [param to]; 0 for level or up.
func drop(from: Vector2i, to: Vector2i) -> int:
	if not _heights_vary:
		return 0
	return maxi(0, height_at(from) - height_at(to))


## A way over ground with heights ([D312]): the shortest by cells that steps only where a walker may
## ([method may_step]: down anywhere, up only at a way up), a drop that would hurt counted as
## `heights.path_drop_cost` cells more, so a walk goes round by the slope rather than at the shelf and
## off a long drop only when there is no other way. Empty when there is none. Flat ground keeps the
## grid's own search; the grid's shut cells (walls, a ward) are shut here too.
func _height_path(from_cell: Vector2i, to_cell: Vector2i) -> Array[Vector2]:
	var path: Array[Vector2] = []
	if from_cell == to_cell:
		path.append(centre_of(from_cell))
		return path
	var rules: Dictionary = Database.world_rules.get("heights", {})
	var hurt_from := int(rules.get("hurt_from", 2))
	var drop_cost := float(rules.get("path_drop_cost", 6))
	var cost: Dictionary = { from_cell: 0.0 }
	var came: Dictionary = {}
	var open: Array = [[_as_the_crow_flies(from_cell, to_cell), 0.0, from_cell]]
	while not open.is_empty():
		var best := 0
		for i in range(1, open.size()):
			if open[i][0] < open[best][0]:
				best = i
		var here: Array = open.pop_at(best)
		var cell: Vector2i = here[2]
		if cell == to_cell:
			break
		if float(here[1]) > float(cost[cell]):
			continue
		for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next := cell + step
			if not in_bounds(next) or astar.is_point_solid(next) or not may_step(cell, next):
				continue
			var so_far := float(cost[cell]) + 1.0 + (drop_cost if drop(cell, next) >= hurt_from else 0.0)
			if not cost.has(next) or so_far < float(cost[next]):
				cost[next] = so_far
				came[next] = cell
				open.append([so_far + _as_the_crow_flies(next, to_cell), so_far, next])
	if not came.has(to_cell):
		return path
	var back := to_cell
	while back != from_cell:
		path.push_front(centre_of(back))
		back = came[back]
	path.push_front(centre_of(from_cell))
	return path


static func _as_the_crow_flies(a: Vector2i, b: Vector2i) -> float:
	return float(absi(a.x - b.x) + absi(a.y - b.y))


## The cells a solid prop stands on: its own, or a `base` [width, depth] centred on it and
## running back from it (a tower's foot is three cells wide), from the prop or its kind.
static func base_cells(prop: Dictionary) -> Array[Vector2i]:
	var cell: Vector2i = prop["cell"]
	var base: Variant = prop.get("base", Database.prop_size(str(prop.get("art", ""))).get("base", [1, 1]))
	var size := _to_cell(base) if base is Array else Vector2i.ONE
	var out: Array[Vector2i] = []
	for dy in maxi(1, size.y):
		for dx in maxi(1, size.x):
			out.append(cell + Vector2i(dx - (size.x - 1) / 2, -dy))
	return out


## Whether [param prop] stands where one of [param raised] has been built since ([D251]: Muck Muck's
## buildings at the crater): on its footprint or a cell round it. Both in the place's own cells.
static func _cleared_by(prop: Dictionary, raised: Array) -> bool:
	# Something that waits on a flag of its own was put there on purpose: a wall, the smith's anvil.
	if prop.has("requires"):
		return false
	var at := _to_cell(prop.get("cell", [0, 0]))
	for building: Dictionary in raised:
		var size := _to_cell(building.get("size", Database.building_art(str(building.get("art", ""))).get("size", [3, 3])))
		if Rect2i(_to_cell(building.get("cell", [0, 0])), size).grow(1).has_point(at):
			return true
	return false


## Whether a prop is there at all: one with `requires` only turns up once those flags are set
## (the ring somebody asked you to look for), one with `requires_not` is gone once they are.
static func _flags_allow(entry: Dictionary) -> bool:
	if GameState == null:
		return true
	for key: String in _flag_list(entry.get("requires", [])):
		if not GameState.has_flag(key):
			return false
	for key: String in _flag_list(entry.get("requires_not", [])):
		if GameState.has_flag(key):
			return false
	return true


static func _flag_list(value: Variant) -> Array:
	if value is Array:
		return value
	return [] if str(value) == "" else [str(value)]


static func footprint(building: Dictionary) -> Rect2i:
	return Rect2i(building["cell"], building["size"])


## The house standing on [param cell], door included.
func building_at(cell: Vector2i) -> Dictionary:
	for building: Dictionary in buildings:
		if footprint(building).has_point(cell):
			return building
	return {}


## The house you would walk into by standing on [param cell].
func door_at(cell: Vector2i) -> Dictionary:
	for building: Dictionary in buildings:
		if building["door"] == cell:
			return building
	return {}


## Where the party lands when it comes back out of [param building].
func step_out_of(building: Dictionary) -> Vector2i:
	var door: Vector2i = building["door"]
	for offset: Vector2i in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
		if is_walkable(door + offset) and building_at(door + offset).is_empty():
			return door + offset
	return door


func is_exit(cell: Vector2i) -> bool:
	return cell in exits


## A chest is opened once per world, not once per visit.
func chest_flag(cell: Vector2i) -> String:
	return "chest:%s:%d,%d" % [id, cell.x, cell.y]


## Whatever was tucked into a prop is only there to be found once.
func prop_flag(cell: Vector2i) -> String:
	return "prop:%s:%d,%d" % [id, cell.x, cell.y]


## Corner code for the tile at [param tile] on a sheet that draws
## [param feature] as the bit [param feature_bit]. A terrain the sheet knows
## nothing about counts as its other side, so a road does not read as stone.
func corner_code(tile: Vector2i, feature: String, feature_bit: int) -> int:
	var nw := _corner_bit(tile + Vector2i(-1, -1), feature, feature_bit)
	var ne := _corner_bit(tile + Vector2i(0, -1), feature, feature_bit)
	var sw := _corner_bit(tile + Vector2i(-1, 0), feature, feature_bit)
	var se := _corner_bit(tile, feature, feature_bit)
	return nw * 8 + ne * 4 + sw * 2 + se


func _corner_bit(cell: Vector2i, feature: String, feature_bit: int) -> int:
	return feature_bit if terrain_at(cell) == feature else 1 - feature_bit


func rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(width, height) * CELL)


func centre_of(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * CELL


func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / CELL), floori(point.y / CELL))


static func _to_cell(pair: Array) -> Vector2i:
	if pair.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(pair[0]), int(pair[1]))


static func to_cell(pair: Array) -> Vector2i:
	return _to_cell(pair)
