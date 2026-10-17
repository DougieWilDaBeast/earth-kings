extends RefCounted
## The First Hour's road ([D126]): a laid road on the land from where the lead came down to the
## great city, on to the first gate, and back to the Tower, so the way reads on the ground itself
## and not only on the compass. Worked out once per world over the tiles (four ways, as the party
## steps, [code]route.gd[/code]); a tile on it knows which of its sides the road leaves by.
##
## Loaded by path, not by `class_name` ([D41]).

const Route := preload("res://src/world/route.gd")
const SIDE_OF := {
	Vector2i.UP: "north", Vector2i.DOWN: "south", Vector2i.LEFT: "west", Vector2i.RIGHT: "east",
}

## World shape seed and crater -> tile -> the sides the road leaves it by.
static var _laid: Dictionary = {}


## The sides of [param tile] the road leaves by, or none when it does not pass.
static func sides(world: World, tile: Vector2i) -> Array:
	var home := world.home()
	var key := "%d|%s" % [world.shape_seed(), home.cell if home != null else Vector2i(-1, -1)]
	if not _laid.has(key):
		if _laid.size() > 4:
			_laid.clear()
		_laid[key] = _lay(world)
	return (_laid[key] as Dictionary).get(tile, [])


## Every tile the road passes through ([D208]: the bands that camp near it are counted from these).
static func tiles(world: World) -> Array:
	sides(world, Vector2i.ZERO)
	var home := world.home()
	var key := "%d|%s" % [world.shape_seed(), home.cell if home != null else Vector2i(-1, -1)]
	return (_laid.get(key, {}) as Dictionary).keys()


## The road's stops, in order: the crater, the great city, the first gate, the Tower.
static func stops(world: World) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var home := world.home()
	if home != null:
		out.append(home.cell)
	for kind: String in ["city", "first_gate"]:
		for site: Site in world.sites:
			if bool(site.data.get(kind, false)):
				out.append(site.cell)
				break
	var tower := world.tower()
	if tower != null:
		out.append(tower.cell)
	return out


static func _lay(world: World) -> Dictionary:
	var laid: Dictionary = {}
	var at := stops(world)
	for i in range(1, at.size()):
		var from: Vector2i = at[i - 1]
		for next: Vector2i in Route.between(world, from, at[i]):
			var step := next - from
			if SIDE_OF.has(step):
				_add(laid, from, SIDE_OF[step])
				_add(laid, next, SIDE_OF[-step])
			from = next
	return laid


static func _add(laid: Dictionary, tile: Vector2i, side: String) -> void:
	var list: Array = laid.get(tile, [])
	if not list.has(side):
		list.append(side)
	laid[tile] = list
