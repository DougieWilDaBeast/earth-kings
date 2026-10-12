extends RefCounted
## The battlefield for a fight met on the ground ([D66]): cut out of the ground itself, round
## where everybody was standing when they were seen, so the fight happens where the party is.
##
## Each cell of the cut becomes the battle terrain its ground names (`data/tilesets.json` →
## `terrains.<id>.battle`): a path is road, tall meadow is brush, water and rock faces are not
## walked. Whatever stands in the way on the ground — a tree, a well, a house — is a wall in the
## fight; a bush you could walk through is brush. The party starts where they stood and the band
## where it stood. The ground's own picture is drawn under the fight (`backdrop`, [AreaBackdrop]).
##
## Loaded by path ([D41]).

## The fight's terrains (`data/terrain.json`), one letter each.
const LEGEND := {
	".": "grass", ",": "brush", "=": "road", "^": "hill", "A": "crag", "~": "water",
	"#": "wall", "L": "lake", "s": "sand", "f": "forest", "m": "marsh", "*": "snow",
}


## `data/world_rules.json` → `ground_watch`.
static func rule(key: String, fallback: Variant) -> Variant:
	return Database.world_rules.get("ground_watch", {}).get(key, fallback)


static func _pair(key: String, fallback: Vector2i) -> Vector2i:
	var value: Variant = rule(key, [])
	return Vector2i(int(value[0]), int(value[1])) if value is Array and value.size() >= 2 else fallback


## The field. [param party] and [param foes] are ground cells, in order; the band's units are
## put on `foe_cells` by [method place_enemies] once the world has said who they are.
static func build(map: AreaMap, party: Array, foes: Array, title: String = "", view: Dictionary = {}) -> Dictionary:
	var window := _window(map, party + foes)
	var symbol_of := {}
	for key: String in LEGEND:
		symbol_of[LEGEND[key]] = key
	var through := _passable_props(map)
	var rows: Array = []
	for y in window.size.y:
		var row := ""
		for x in window.size.x:
			var battle := battle_terrain(map, window.position + Vector2i(x, y), through)
			row += str(symbol_of.get(battle, "."))
		rows.append(row)

	var taken: Dictionary = {}
	var spawns: Array = []
	for cell: Vector2i in party:
		var spot := _free(rows, cell - window.position, taken)
		if spot.x >= 0:
			spawns.append([spot.x, spot.y])
	var foe_cells: Array = []
	for cell: Vector2i in foes:
		var spot := _free(rows, cell - window.position, taken)
		if spot.x >= 0:
			foe_cells.append([spot.x, spot.y])
	return {
		"id": "ground_%s_%d_%d" % [map.id, window.position.x, window.position.y],
		"name": title if title != "" else map.display_name,
		"legend": LEGEND,
		"tiles": rows,
		"player_spawns": spawns,
		"foe_cells": foe_cells,
		"enemies": [],
		"backdrop": { "area_id": map.id, "origin": [window.position.x, window.position.y] },
		"view": _view_in_field(view, window),
	}


## The ground's camera ([param view]: `centre` in ground pixels, `zoom`) as the fight's: the same
## spot, at the same size on screen, so the fight opens on exactly what was being looked at.
static func _view_in_field(view: Dictionary, window: Rect2i) -> Dictionary:
	if view.is_empty():
		return {}
	var ratio := float(BattleGrid.CELL_SIZE) / float(AreaMap.CELL)
	var centre: Array = view.get("centre", [0, 0])
	var at := (Vector2(float(centre[0]), float(centre[1])) - Vector2(window.position) * AreaMap.CELL) * ratio
	return { "centre": [at.x, at.y], "zoom": float(view.get("zoom", 1.0)) / ratio }


## The band's units, on the cells they stood on: in order, and anyone more than there were
## cells for (a survivor come for revenge) on the nearest open ground to the others.
static func place_enemies(field: Dictionary, enemies: Array) -> Dictionary:
	var out := field.duplicate(true)
	var rows: Array = out.get("tiles", [])
	var cells: Array = out.get("foe_cells", [])
	var taken: Dictionary = {}
	for pair: Array in out.get("player_spawns", []):
		taken[Vector2i(int(pair[0]), int(pair[1]))] = true
	var placed: Array = []
	for i in enemies.size():
		var want := Vector2i(int(cells[i][0]), int(cells[i][1])) if i < cells.size() \
			else (Vector2i(int(cells[0][0]), int(cells[0][1])) if not cells.is_empty() else Vector2i(rows[0].length() / 2, 1))
		var spot := _free(rows, want, taken)
		if spot.x < 0:
			continue
		var entry: Dictionary = (enemies[i] as Dictionary).duplicate()
		entry["cell"] = [spot.x, spot.y]
		placed.append(entry)
	out["enemies"] = placed
	out.erase("foe_cells")
	return out


## What a ground cell is in a fight.
static func battle_terrain(map: AreaMap, cell: Vector2i, through: Dictionary = {}) -> String:
	var ground: Dictionary = Database.area_terrain(map.terrain_at(cell))
	if not bool(ground.get("walkable", true)):
		return str(ground.get("battle", "wall"))
	if not map.is_walkable(cell):
		# A tree, a well, a house: in the way on the ground, in the way in the fight.
		return "wall"
	if through.has(cell):
		return "brush"
	return str(ground.get("battle", "grass"))


## Cells with a bush or a hedge on them that the party could walk through: cover in a fight.
static func _passable_props(map: AreaMap) -> Dictionary:
	var out := {}
	for prop: Dictionary in map.props:
		var kind := str(Database.prop_size(str(prop.get("art", ""))).get("kind", ""))
		if kind == "bush" and not AreaProp.is_solid(prop):
			out[prop["cell"]] = true
	return out


## A cut round [param cells], `field_smallest` to `field_largest`, inside the map.
static func _window(map: AreaMap, cells: Array) -> Rect2i:
	var lo := Vector2i(map.width, map.height)
	var hi := Vector2i(-1, -1)
	for cell: Vector2i in cells:
		lo = Vector2i(mini(lo.x, cell.x), mini(lo.y, cell.y))
		hi = Vector2i(maxi(hi.x, cell.x), maxi(hi.y, cell.y))
	if hi.x < 0:
		lo = Vector2i.ZERO
		hi = Vector2i(map.width - 1, map.height - 1)
	var smallest := _pair("field_smallest", Vector2i(16, 11))
	var largest := _pair("field_largest", Vector2i(22, 14))
	var margin := int(rule("field_margin", 2))
	var size := Vector2i(
		clampi(hi.x - lo.x + 1 + margin * 2, smallest.x, largest.x),
		clampi(hi.y - lo.y + 1 + margin * 2, smallest.y, largest.y)
	)
	size = Vector2i(mini(size.x, map.width), mini(size.y, map.height))
	var centre := (lo + hi) / 2
	var origin := centre - size / 2
	origin = Vector2i(clampi(origin.x, 0, map.width - size.x), clampi(origin.y, 0, map.height - size.y))
	return Rect2i(origin, size)


## The cell nearest [param want] inside the field that a unit can stand on and nobody has.
static func _free(rows: Array, want: Vector2i, taken: Dictionary) -> Vector2i:
	var height := rows.size()
	var width := str(rows[0]).length() if height > 0 else 0
	var start := Vector2i(clampi(want.x, 0, width - 1), clampi(want.y, 0, height - 1))
	for radius in range(0, maxi(width, height)):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var cell := start + Vector2i(dx, dy)
				if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height or taken.has(cell):
					continue
				var terrain: String = LEGEND.get(str(rows[cell.y]).substr(cell.x, 1), "grass")
				if bool(Database.terrain_type(terrain).get("walkable", true)):
					taken[cell] = true
					return cell
	return Vector2i(-1, -1)
