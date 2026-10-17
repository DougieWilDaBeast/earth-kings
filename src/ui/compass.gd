extends Control
## The compass on the ground (D95): N, E, S and W round a ring, a needle
## pointing at the objective, and what the objective is and how many tiles off.
## It is told where to point (`point`); it works nothing out for itself.
##
## Loaded by path, not by `class_name` ([D41]).

## A click on the ring: follow the next thing in the quest list ([D188]).
signal pressed

const RADIUS := 26.0
const RING := Color(0.98, 0.86, 0.52, 0.85)
const FACE := Color(0.06, 0.06, 0.09, 0.72)
const NEEDLE := Color(0.95, 0.42, 0.3)
const LETTERS := Color(0.9, 0.9, 0.94)

var _bearing := Vector2.ZERO
var _label: Label
## What the compass is pointing at, and how many things there are to follow.
var _what := ""
var _count := 0
var _key := ""


func _ready() -> void:
	# The ring takes a click (the next quest); the words beside it do not.
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(RADIUS * 2.0 + 8.0, RADIUS * 2.0 + 8.0)
	size = custom_minimum_size
	_label = Label.new()
	_label.position = Vector2(RADIUS * 2.0 + 14.0, RADIUS - 11.0)
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", RING)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


## Point at [param bearing] (screen-space: x east, y south), naming [param what],
## [param tiles] away. Zero tiles is standing on it.
func point(bearing: Vector2, what: String, tiles: int) -> void:
	_bearing = bearing
	_what = what if tiles <= 0 else "%s  ·  %d %s" % [what, tiles, "tile" if tiles == 1 else "tiles"]
	_count = 0
	_say()
	queue_redraw()


## How many things the quest list holds, and the key that steps through them: with more than one,
## the words beside the ring say so ("1 of 3 · L").
func set_count(count: int, key: String) -> void:
	_count = count
	_key = key
	_say()


func _say() -> void:
	_label.text = _what
	if _count > 1:
		_label.text += "   (%d to follow%s)" % [_count, "  ·  %s for the next" % _key if _key != "" else ""]


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		pressed.emit()


func _draw() -> void:
	var centre := Vector2(RADIUS + 4.0, RADIUS + 4.0)
	draw_circle(centre, RADIUS, FACE)
	draw_arc(centre, RADIUS, 0.0, TAU, 40, RING, 2.0, true)
	var font := get_theme_default_font()
	for each: Array in [["N", Vector2.UP], ["E", Vector2.RIGHT], ["S", Vector2.DOWN], ["W", Vector2.LEFT]]:
		var at: Vector2 = centre + (each[1] as Vector2) * (RADIUS - 8.0)
		draw_string(font, at + Vector2(-4.0, 5.0), str(each[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, LETTERS)
	if _bearing.length() < 0.01:
		draw_circle(centre, 4.0, NEEDLE)
		return
	var way := _bearing.normalized()
	var side := Vector2(-way.y, way.x)
	var tip := centre + way * (RADIUS - 3.0)
	draw_colored_polygon(PackedVector2Array([tip, centre + side * 5.0, centre - side * 5.0]), NEEDLE)
	draw_circle(centre, 3.0, RING)
