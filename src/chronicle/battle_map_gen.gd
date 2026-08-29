class_name BattleMapGen
extends RefCounted
## Builds a battlefield out of the ground you were standing on when the fight
## started, so a scrap in the reeds does not look like a scrap on a ridge.

const SIZE := Vector2i(12, 10)
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
