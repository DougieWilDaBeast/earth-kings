extends Control
## One quick slot drawn as a tile: its key, its name, and a dark sweep that
## winds back round as the cooldown runs out. Flashes once when it comes back.
## Also laid over the touch buttons as [member overlay_only], sweep and all.

signal pressed

const BACK := Color(0.13, 0.15, 0.2, 0.95)
const BORDER_READY := Color(0.62, 0.92, 0.62)
const BORDER_WAIT := Color(0.35, 0.38, 0.45)
const ARMED := Color(1.0, 0.86, 0.3)
const SWEEP := Color(0, 0, 0, 0.62)
const KEY := Color(0.95, 0.9, 0.7)
const NAME := Color(0.88, 0.9, 0.95)
const PING_TIME := 0.35

var key_label: String = ""
var title: String = ""
## Seconds left, and the cooldown it is counting down from.
var left: float = 0.0
var total: float = 1.0
var armed: bool = false
## Only the sweep and the seconds: something else draws the rest.
var overlay_only: bool = false
## How wide the tile asks to be; a card shared six ways asks for less.
var width: float = 56.0

var _was_waiting: bool = false
var _ping: float = 0.0


func _ready() -> void:
	clip_contents = true
	if overlay_only:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		mouse_filter = Control.MOUSE_FILTER_STOP
		custom_minimum_size = Vector2(width, 40)


func show_slot(key: String, ability_name: String, seconds_left: float, cooldown: float, is_armed: bool) -> void:
	var waiting := seconds_left > 0.0
	if _was_waiting and not waiting:
		_ping = PING_TIME
	_was_waiting = waiting
	key_label = key
	title = ability_name
	left = seconds_left
	total = maxf(0.01, cooldown)
	armed = is_armed
	queue_redraw()


func _process(delta: float) -> void:
	if _ping > 0.0:
		_ping = maxf(0.0, _ping - delta)
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if overlay_only:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var font := ThemeDB.fallback_font
	if not overlay_only:
		draw_rect(rect, BACK)
	if left > 0.0:
		_draw_sweep(rect, clampf(left / total, 0.0, 1.0))
		var seconds := "%.1f" % left if left < 10.0 else "%d" % ceili(left)
		var at := Vector2(0, size.y * 0.5 + 6)
		draw_string_outline(font, at, seconds, HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, 3, Color(0, 0, 0, 0.9))
		draw_string(font, at, seconds, HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, Color.WHITE)
	if not overlay_only:
		draw_string(font, Vector2(4, 13), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, KEY)
		if left <= 0.0:
			draw_string(font, Vector2(2, size.y - 6), title, HORIZONTAL_ALIGNMENT_CENTER, size.x - 4, 10, NAME)
		var border := ARMED if armed else (BORDER_READY if left <= 0.0 else BORDER_WAIT)
		draw_rect(rect, border, false, 2.0 if armed or left <= 0.0 else 1.0)
	if _ping > 0.0:
		var t := _ping / PING_TIME
		draw_rect(rect.grow(3.0 * (1.0 - t)), Color(BORDER_READY, t), false, 2.0)
		draw_rect(rect, Color(1, 1, 1, 0.35 * t))


## The part still cooling down, as a dark wedge that winds away clockwise.
## The control clips its own drawing, so the wedge can overshoot the corners.
func _draw_sweep(rect: Rect2, share: float) -> void:
	var centre := rect.get_center()
	var radius := rect.size.length()
	var points := PackedVector2Array([centre])
	var steps := maxi(2, int(40 * share))
	for i in steps + 1:
		var angle := -PI * 0.5 + TAU * share * float(i) / float(steps)
		points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
	if share > 0.01:
		draw_colored_polygon(points, SWEEP)
