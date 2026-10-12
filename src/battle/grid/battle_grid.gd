class_name BattleGrid
extends Node2D
## The battlefield: terrain per cell, coordinate conversion, and the tile render.
##
## Cells are [Vector2i] in grid space; world space is cell centres.
## Terrain (move cost / height / walkability) comes from `data/terrain.json`.

const CELL_SIZE := 48

var width: int = 0
var height: int = 0
var map_name: String = ""

## Off when the fight is laid over real ground ([D66]): only a faint grid is
## drawn, so the tiles underneath are the battlefield.
var draw_floor: bool = true

var _terrain_ids: Dictionary = {}  ## Vector2i -> terrain id String
var _ground_decor: Dictionary = {}

const _NEIGHBOUR_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
]


func _ready() -> void:
	_load_decor()


func _load_decor() -> void:
	var paths := {
		"flowers_yellow": "res://art/props/nature/wildflowers_orange.png",
		"flowers_blue": "res://art/props/nature/wildflowers_blue.png",
		"flowers_red": "res://art/props/nature/wildflowers_red.png",
		"flowers_white": "res://art/props/nature/grass_tuft.png",
		"fern": "res://art/props/nature/fern.png",
		"thistle": "res://art/props/nature/thistle.png",
	}
	for k: String in paths:
		if ResourceLoader.exists(paths[k]):
			_ground_decor[k] = load(paths[k])


func load_map(map: Dictionary) -> void:
	_terrain_ids.clear()
	map_name = map.get("name", "")
	var rows: Array = map.get("tiles", [])
	var legend: Dictionary = map.get("legend", {})
	height = rows.size()
	width = 0
	for y in rows.size():
		var row: String = rows[y]
		width = maxi(width, row.length())
		for x in row.length():
			var symbol := row[x]
			_terrain_ids[Vector2i(x, y)] = legend.get(symbol, "grass")
	queue_redraw()


func in_bounds(cell: Vector2i) -> bool:
	return _terrain_ids.has(cell)


## The terrain id under [param cell]: "grass", "brush", "crag"…
func terrain_id_at(cell: Vector2i) -> String:
	return str(_terrain_ids.get(cell, "grass"))


func terrain_at(cell: Vector2i) -> Dictionary:
	return Database.terrain_type(_terrain_ids.get(cell, "grass"))


func move_cost(cell: Vector2i) -> int:
	return int(terrain_at(cell).get("move_cost", 1))


func height_at(cell: Vector2i) -> int:
	return int(terrain_at(cell).get("height", 0))


func is_walkable(cell: Vector2i) -> bool:
	return in_bounds(cell) and terrain_at(cell).get("walkable", true)


func neighbours(cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for offset in _NEIGHBOUR_OFFSETS:
		var next := cell + offset
		if in_bounds(next):
			out.append(next)
	return out


## Where [param count] of the party start: the map's own spawns first, then the
## nearest open ground to them, so a map drawn for four still takes six.
## [param taken] are cells somebody else already stands on.
func muster_cells(spawns: Array, count: int, taken: Array[Vector2i] = []) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for value: Variant in spawns:
		var pair: Array = value
		out.append(Vector2i(int(pair[0]), int(pair[1])))
	if out.size() >= count or out.is_empty():
		return out.slice(0, count) if out.size() > count else out
	var seen: Dictionary = {}
	var frontier: Array[Vector2i] = out.duplicate()
	for cell in out:
		seen[cell] = true
	while out.size() < count and not frontier.is_empty():
		var cell: Vector2i = frontier.pop_front()
		for next in neighbours(cell):
			if seen.has(next):
				continue
			seen[next] = true
			if not is_walkable(next):
				continue
			frontier.append(next)
			if next not in taken and out.size() < count:
				out.append(next)
	return out


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE + CELL_SIZE * 0.5, cell.y * CELL_SIZE + CELL_SIZE * 0.5)


func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL_SIZE), floori(pos.y / CELL_SIZE))


func centre_world() -> Vector2:
	return Vector2(width, height) * CELL_SIZE * 0.5


func _draw() -> void:
	if not draw_floor:
		for cell: Vector2i in _terrain_ids:
			if is_walkable(cell):
				draw_rect(Rect2(Vector2(cell) * CELL_SIZE, Vector2.ONE * CELL_SIZE), Color(0, 0, 0, 0.16), false, 1.0)
		return
	for cell: Vector2i in _terrain_ids:
		var data := terrain_at(cell)
		var rect := Rect2(Vector2(cell) * CELL_SIZE, Vector2.ONE * CELL_SIZE)
		var base_color := Color(data.get("color", "#4f7d3f"))
		var seed_val := absi(hash(cell))
		var shade := 0.94 + float(seed_val % 100) / 1000.0 * 0.12
		draw_rect(rect, base_color * shade)
		draw_rect(rect, Color(0, 0, 0, 0.22), false, 1.0)
		# Raised tiles get a lip so elevation reads at a glance.
		var tile_height := int(data.get("height", 0))
		if tile_height > 0:
			draw_rect(Rect2(rect.position, Vector2(CELL_SIZE, 4)), Color(1, 1, 1, 0.18))

		# Ground nature accents on walkable ground
		var terrain_id: String = _terrain_ids.get(cell, "grass")
		if terrain_id == "grass":
			if seed_val % 4 == 0:
				var flower_keys := ["flowers_yellow", "flowers_blue", "flowers_white", "flowers_red"]
				var key: String = flower_keys[seed_val % flower_keys.size()]
				var tex: Texture2D = _ground_decor.get(key)
				if tex != null:
					var offset := Vector2(float(seed_val % 18) + 8.0, float((seed_val / 10) % 18) + 8.0)
					draw_texture(tex, rect.position + offset)
		elif terrain_id == "brush":
			if seed_val % 3 == 0:
				var tex: Texture2D = _ground_decor.get("fern")
				if tex != null:
					draw_texture(tex, rect.position + Vector2(16, 16))
		elif terrain_id == "hill":
			if seed_val % 3 == 0:
				var tex: Texture2D = _ground_decor.get("thistle")
				if tex != null:
					draw_texture(tex, rect.position + Vector2(16, 16))
