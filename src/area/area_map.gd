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
## cell -> the line said when the party first stands there.
var spots: Dictionary = {}
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
## Where the party sits when there is a fire to sit around.
var seats: Array[Vector2i] = []
## Light the whole place is seen in, for areas that are not at noon.
var tint: String = ""
## A cutscene played the moment the party walks in.
var opening: String = ""
## What the bottom of the screen says when nobody is standing near anybody.
var hint: String = ""

var _terrain: Array[String] = []
## Cells a piece of furniture is standing on, which nobody walks through.
var _blocked: Dictionary = {}


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
	map.spawn = _to_cell(data.get("spawn", [0, 0]))
	for pair: Array in data.get("exits", []):
		map.exits.append(_to_cell(pair))
	for spot: Dictionary in data.get("spots", []):
		map.spots[_to_cell(spot.get("cell", [0, 0]))] = spot.get("line", "")
	for chest: Dictionary in data.get("chests", []):
		map.chests[_to_cell(chest.get("cell", [0, 0]))] = chest
	for prop: Dictionary in data.get("props", []):
		var placed := prop.duplicate(true)
		placed["cell"] = _to_cell(prop.get("cell", [0, 0]))
		if bool(placed.get("solid", false)):
			map._blocked[placed["cell"]] = true
		map.props.append(placed)
	for entry: Dictionary in data.get("buildings", []):
		var building := entry.duplicate(true)
		building["cell"] = _to_cell(entry.get("cell", [0, 0]))
		building["size"] = _to_cell(entry.get("size", [3, 3]))
		building["door"] = _to_cell(entry.get("door", entry.get("cell", [0, 0])))
		map.buildings.append(building)
	for person: Dictionary in data.get("people", []):
		map.people.append(person)
	if data.has("fire"):
		map.fire = _to_cell(data["fire"])
	for pair: Array in data.get("seats", []):
		map.seats.append(_to_cell(pair))
	map.tint = data.get("tint", "")
	map.opening = data.get("opening", "")
	map.hint = data.get("hint", "")
	return map


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
	var building := building_at(cell)
	if not building.is_empty() and building["door"] != cell:
		return false
	return bool(Database.area_terrain(terrain_at(cell)).get("walkable", true))


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
