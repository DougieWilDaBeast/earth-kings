class_name GridOverlay
extends Node2D
## Draws the tactical overlays on top of the grid: movement range, ability
## range, the previewed path, and the hover cursor.

const MOVE_COLOUR := Color(0.35, 0.6, 1.0, 0.35)
const FLASH_COLOUR := Color(0.7, 0.45, 1.0, 0.35)
const ACTION_COLOUR := Color(1.0, 0.35, 0.35, 0.35)
const PATH_COLOUR := Color(1.0, 1.0, 1.0, 0.45)
## Outline used for the range of an action the player is only hovering over.
const PREVIEW_ALPHA := 0.85
const CURSOR_COLOUR := Color(1.0, 0.95, 0.6, 0.9)
const ACTIVE_ALLY_COLOUR := Color(1.0, 0.86, 0.3, 1.0)
const ACTIVE_ENEMY_COLOUR := Color(1.0, 0.4, 0.35, 1.0)
const ACTIVE_PULSE_SPEED := 4.0

var grid: BattleGrid

var move_cells: Array[Vector2i] = []
var flash_cells: Array[Vector2i] = []
var action_cells: Array[Vector2i] = []
var path_cells: Array[Vector2i] = []
## Range of the command under the mouse, shown without arming it.
var preview_cells: Array[Vector2i] = []
var preview_colour: Color = ACTION_COLOUR
var cursor_cell: Vector2i = Vector2i(-1, -1)
var active_cell: Vector2i = Vector2i(-1, -1)
var active_is_enemy: bool = false
## Squad members who still have something to spend but are not selected.
var pending_cells: Array[Vector2i] = []

var _pulse: float = 0.0


func _ready() -> void:
	set_process(false)


func clear() -> void:
	move_cells.clear()
	flash_cells.clear()
	action_cells.clear()
	path_cells.clear()
	preview_cells.clear()
	queue_redraw()


func set_preview(cells: Array[Vector2i], colour: Color) -> void:
	preview_cells = cells
	preview_colour = colour
	queue_redraw()


func clear_preview() -> void:
	if preview_cells.is_empty():
		return
	preview_cells = []
	queue_redraw()


## Marks whose turn it is by lighting the tile they are standing on.
func set_active(cell: Vector2i, is_enemy: bool) -> void:
	active_cell = cell
	active_is_enemy = is_enemy
	_pulse = 0.0
	set_process(grid != null and grid.in_bounds(cell))
	queue_redraw()


func clear_active() -> void:
	pending_cells = []
	set_active(Vector2i(-1, -1), false)


func _process(delta: float) -> void:
	_pulse += delta
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
	_draw_active()
	_draw_cells(move_cells, MOVE_COLOUR)
	_draw_cells(flash_cells, FLASH_COLOUR)
	_draw_cells(action_cells, ACTION_COLOUR)
	_draw_cells(path_cells, PATH_COLOUR)
	for cell in preview_cells:
		draw_rect(_rect_for(cell).grow(-1.0), Color(preview_colour, PREVIEW_ALPHA), false, 2.0)
	if grid.in_bounds(cursor_cell):
		draw_rect(_rect_for(cursor_cell), CURSOR_COLOUR, false, 2.0)


func _draw_active() -> void:
	for cell in pending_cells:
		draw_rect(_rect_for(cell).grow(-2.0), Color(ACTIVE_ALLY_COLOUR, 0.4), false, 2.0)
	if not grid.in_bounds(active_cell):
		return
	var beat := 0.5 + 0.5 * sin(_pulse * ACTIVE_PULSE_SPEED)
	var colour := ACTIVE_ENEMY_COLOUR if active_is_enemy else ACTIVE_ALLY_COLOUR
	var rect := _rect_for(active_cell)
	draw_rect(rect, Color(colour, 0.16 + 0.14 * beat))
	draw_rect(rect.grow(-1.5), Color(colour, 0.6 + 0.4 * beat), false, 3.0)


func _draw_cells(cells: Array[Vector2i], colour: Color) -> void:
	for cell in cells:
		draw_rect(_rect_for(cell), colour)


func _rect_for(cell: Vector2i) -> Rect2:
	var size := float(BattleGrid.CELL_SIZE)
	return Rect2(Vector2(cell) * size, Vector2.ONE * size)
