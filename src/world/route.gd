extends RefCounted
## The way across the country on foot, for a party that is walking itself.
##
## Breadth-first over walkable ground, four ways, every tile costing the same —
## the same rules the party steps by. Nothing about the terrain's danger is
## weighed; this is for getting somewhere, not for getting there safely.
##
## Loaded by path, not by `class_name` ([D41]).

const STEPS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]


## The cells from the one after [param from] up to and including [param to],
## or empty if [param to] cannot be walked to (or is where the party stands).
## With [param longest] above zero, a way longer than that counts as none — for
## chasing something close, where a way that long is not worth it and looking
## for one across the whole country every step is not either.
static func between(world: World, from: Vector2i, to: Vector2i, longest: int = 0) -> Array[Vector2i]:
	var none: Array[Vector2i] = []
	if from == to or not world.is_walkable(to):
		return none
	var came_from: Dictionary = {from: from}
	var depth: Dictionary = {from: 0}
	var frontier: Array[Vector2i] = [from]
	var head := 0
	while head < frontier.size():
		var cell := frontier[head]
		head += 1
		if longest > 0 and int(depth[cell]) >= longest:
			continue
		for offset: Vector2i in STEPS:
			var next := cell + offset
			if came_from.has(next) or not world.is_walkable(next):
				continue
			came_from[next] = cell
			depth[next] = int(depth[cell]) + 1
			if next == to:
				return _walk_back(came_from, from, to)
			frontier.append(next)
	return none


static func _walk_back(came_from: Dictionary, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var route: Array[Vector2i] = []
	var cell := to
	while cell != from:
		route.push_front(cell)
		cell = came_from[cell]
	return route
