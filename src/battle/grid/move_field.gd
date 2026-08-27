class_name MoveField
extends RefCounted
## Result of a movement flood-fill: which cells a unit can reach, at what cost,
## and the path back to where it started.

var origin: Vector2i
var costs: Dictionary = {}      ## Vector2i -> int accumulated move cost
var came_from: Dictionary = {}  ## Vector2i -> Vector2i previous cell


func _init(start: Vector2i) -> void:
	origin = start
	costs[start] = 0


func can_reach(cell: Vector2i) -> bool:
	return costs.has(cell)


func cost_to(cell: Vector2i) -> int:
	return int(costs.get(cell, -1))


func cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for cell: Vector2i in costs:
		out.append(cell)
	return out


## Cells the unit can actually stop on (reachable and not blocked by an ally).
func stoppable_cells(is_occupied: Callable) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for cell: Vector2i in costs:
		if cell != origin and not is_occupied.call(cell):
			out.append(cell)
	return out


## Ordered list of cells from origin (exclusive) to [param cell] (inclusive).
func path_to(cell: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if not can_reach(cell):
		return path
	var current := cell
	while current != origin:
		path.push_front(current)
		current = came_from[current]
	return path
