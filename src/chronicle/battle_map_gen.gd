class_name BattleMapGen
extends RefCounted
## Builds a battlefield out of the ground you were standing on when the fight
## started, so a scrap in the reeds does not look like a scrap on a ridge.

const SIZE := Vector2i(18, 14)
## Rows kept clear at the top and bottom for the two sides to form up on.
const MUSTER_ROW := 1

## World terrain -> the symbols that battlefield is made of, weighted by repeats.
const PALETTES := {
	"grass": [".", ".", ".", ".", ",", "^"],
	"brush": [",", ",", ".", ".", ",", "^"],
	"road": ["=", "=", ".", ".", ",", "^"],
	"hill": ["^", "^", ".", ".", "A", ","],
	"crag": ["A", "^", "^", ".", "#", "."],
	"water": ["~", "~", ".", ",", ".", "^"],
	"wall": ["#", "A", "^", ".", ".", ","],
}

const LEGEND := {
	".": "grass",
	",": "brush",
	"=": "road",
	"^": "hill",
	"A": "crag",
	"~": "water",
	"#": "wall",
}


## [param enemies] is a list of { "unit": template_id, "level": int }.
static func generate(world: World, cell: Vector2i, enemies: Array, rng: RandomNumberGenerator) -> Dictionary:
	var map := generate_on(world.terrain_id_at(cell), world.terrain_at(cell).get("name", "Open ground"), enemies, rng)
	map["id"] = "field_%d_%d" % [cell.x, cell.y]
	return map


## Same field, built from a terrain id alone — for fights with no world behind them.
static func generate_on(terrain_id: String, display_name: String, enemies: Array, rng: RandomNumberGenerator) -> Dictionary:
	var palette: Array = PALETTES.get(terrain_id, PALETTES["grass"])

	var rows: Array = []
	for y in SIZE.y:
		var row := ""
		for x in SIZE.x:
			row += palette[rng.randi() % palette.size()]
		rows.append(row)

	var player_spawns := _muster(rows, SIZE.y - 1 - MUSTER_ROW, Roster.MAX_PARTY)
	var enemy_cells := _muster(rows, MUSTER_ROW, enemies.size())

	var placed: Array = []
	for i in mini(enemies.size(), enemy_cells.size()):
		var entry: Dictionary = enemies[i].duplicate()
		entry["cell"] = enemy_cells[i]
		placed.append(entry)

	return {
		"id": "field_%s" % terrain_id,
		"name": display_name,
		"legend": LEGEND,
		"tiles": rows,
		"player_spawns": player_spawns,
		"enemies": placed,
	}


## Clear a strip of ground in the middle of [param row] and hand back the cells.
static func _muster(rows: Array, row: int, count: int) -> Array:
	var cells: Array = []
	var start := maxi(1, (SIZE.x - count * 2) / 2)
	for i in count:
		var x := start + i * 2
		if x >= SIZE.x - 1:
			break
		rows[row] = _set_symbol(rows[row], x, ".")
		# Keep the tile in front of each fighter passable so nobody starts boxed in.
		var ahead := row + (1 if row < SIZE.y / 2 else -1)
		rows[ahead] = _set_symbol(rows[ahead], x, ".")
		cells.append([x, row])
	return cells


static func _set_symbol(row: String, x: int, symbol: String) -> String:
	return row.substr(0, x) + symbol + row.substr(x + 1)


## Form [param allies] up on the back row, behind the party. Each entry is
## { "unit": template_id, "level": int }; anyone with no room is left behind.
static func add_allies(map: Dictionary, allies: Array) -> void:
	var rows: Array = map.get("tiles", [])
	if rows.is_empty() or allies.is_empty():
		return
	var cells := _muster(rows, rows.size() - 1, allies.size())
	var placed: Array = []
	for i in cells.size():
		var entry: Dictionary = allies[i].duplicate()
		entry["cell"] = cells[i]
		placed.append(entry)
	map["allies"] = placed


## Put the gate's heart on the far edge, behind the enemy line, with clear ground
## round it so it can always be stood on.
static func mark_heart(map: Dictionary) -> void:
	var rows: Array = map.get("tiles", [])
	if rows.size() < 2:
		return
	var width := str(rows[0]).length()
	var x := width / 2
	for y in 2:
		for dx in range(-1, 2):
			rows[y] = _set_symbol(rows[y], clampi(x + dx, 0, width - 1), ".")
	map["heart"] = [x, 0]
