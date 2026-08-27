class_name GridOverlay
extends Node2D
## Draws the tactical overlays on top of the grid: movement range, ability
## range, the previewed path, and the hover cursor.

const MOVE_COLOUR := Color(0.35, 0.6, 1.0, 0.35)
const ACTION_COLOUR := Color(1.0, 0.35, 0.35, 0.35)
const PATH_COLOUR := Color(1.0, 1.0, 1.0, 0.45)
const CURSOR_COLOUR := Color(1.0, 0.95, 0.6, 0.9)

var grid: BattleGrid

var move_cells: Array[Vector2i] = []
var action_cells: Array[Vector2i] = []
var path_cells: Array[Vector2i] = []
var cursor_cell: Vector2i = Vector2i(-1, -1)


func clear() -> void:
	move_cells.clear()
	action_cells.clear()
	path_cells.clear()
	queue_redraw()


func set_cursor(cell: Vector2i) -> void:
	if cell == cursor_cell:
		return
	cursor_cell = cell
	queue_redraw()


func set_path(cells: Array[Vector2i]) -> void:
	path_cells = cells
	queue_redraw()


func clear_path() -> void:
	if path_cells.is_empty():
		return
	path_cells = []
	queue_redraw()


func _draw() -> void:
	if grid == null:
		return
	_draw_cells(move_cells, MOVE_COLOUR)
	_draw_cells(action_cells, ACTION_COLOUR)
	_draw_cells(path_cells, PATH_COLOUR)
	if grid.in_bounds(cursor_cell):
		draw_rect(_rect_for(cursor_cell), CURSOR_COLOUR, false, 2.0)


func _draw_cells(cells: Array[Vector2i], colour: Color) -> void:
	for cell in cells:
		draw_rect(_rect_for(cell), colour)


func _rect_for(cell: Vector2i) -> Rect2:
	var size := float(BattleGrid.CELL_SIZE)
	return Rect2(Vector2(cell) * size, Vector2.ONE * size)
