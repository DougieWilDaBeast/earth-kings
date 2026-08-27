class_name Pathfinder
extends RefCounted
## Movement queries over a [BattleGrid]: Dijkstra flood-fill that respects
## per-tile move cost, height differences (jump), and blocking units.

var _grid: BattleGrid


func _init(grid: BattleGrid) -> void:
	_grid = grid


## Flood-fill every cell reachable within [param move_points].
## [param blocks_movement] is called with a [Vector2i] and returns true for
## cells that cannot be entered at all (e.g. hostile units).
func build_move_field(
	start: Vector2i, move_points: int, jump: int, blocks_movement: Callable
) -> MoveField:
	var field := MoveField.new(start)
	var frontier: Array[Vector2i] = [start]

	while not frontier.is_empty():
		var current := _pop_cheapest(frontier, field)
		var current_cost := field.cost_to(current)
		for next in _grid.neighbours(current):
			if not _grid.is_walkable(next) or blocks_movement.call(next):
				continue
			if absi(_grid.height_at(next) - _grid.height_at(current)) > jump:
				continue
			var next_cost := current_cost + _grid.move_cost(next)
			if next_cost > move_points:
				continue
			if field.can_reach(next) and field.cost_to(next) <= next_cost:
				continue
			field.costs[next] = next_cost
			field.came_from[next] = current
			frontier.append(next)

	return field


## Cells within a Manhattan ring of [param origin], used for ability ranges.
func cells_in_range(origin: Vector2i, min_range: int, max_range: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dx in range(-max_range, max_range + 1):
		for dy in range(-max_range, max_range + 1):
			var distance := absi(dx) + absi(dy)
			if distance < min_range or distance > max_range:
				continue
			var cell := origin + Vector2i(dx, dy)
			if _grid.in_bounds(cell):
				out.append(cell)
	return out


static func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


# Grids are small, so a linear scan beats the overhead of a real heap.
func _pop_cheapest(frontier: Array[Vector2i], field: MoveField) -> Vector2i:
	var best_index := 0
	for i in range(1, frontier.size()):
		if field.cost_to(frontier[i]) < field.cost_to(frontier[best_index]):
			best_index = i
	var cell := frontier[best_index]
	frontier.remove_at(best_index)
	return cell
