class_name SpeechBubble
extends Node2D
## A line said out loud over somebody's head: it appears, holds for about as
## long as the line takes to read, and is gone.
##
## Nothing waits on it. A bubble never takes the keys, never stops the party
## walking, and a second line from the same speaker replaces the first rather
## than stacking up.

## Widest a bubble gets before the line wraps.
const WRAP_WIDTH := 240.0
const FONT_SIZE := 15
## How long it takes to appear, to fade, and how long it holds in between.
const FADE_IN := 0.12
const FADE_OUT := 0.45
const HOLD_BASE := 1.2
const HOLD_PER_CHAR := 0.045
const HOLD_MIN := 1.8
const HOLD_MAX := 6.0
const PANEL := Color(0.09, 0.08, 0.12, 0.92)
const EDGE := Color(0.74, 0.64, 0.4, 0.9)
const TEXT := Color(0.94, 0.92, 0.86)
## The spike under the bubble that points at whoever is speaking.
const TAIL := Vector2(9.0, 10.0)

var _panel: PanelContainer
var _label: Label
## How far above the node's own origin the bubble floats.
var _height: float = 96.0
var _age: float = 0.0
var _hold: float = 0.0


static func create(height: float) -> SpeechBubble:
	var bubble := SpeechBubble.new()
	bubble._height = height
	# Above the y-sorted crowd, whoever happens to be standing in front.
	bubble.z_index = 200
	bubble.z_as_relative = false

	var box := StyleBoxFlat.new()
	box.bg_color = PANEL
	box.border_color = EDGE
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.content_margin_left = 9.0
	box.content_margin_right = 9.0
	box.content_margin_top = 5.0
	box.content_margin_bottom = 5.0

	bubble._panel = PanelContainer.new()
	bubble._panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble._panel.add_theme_stylebox_override("panel", box)
	bubble.add_child(bubble._panel)

	bubble._label = Label.new()
	bubble._label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble._label.add_theme_font_size_override("font_size", FONT_SIZE)
	bubble._label.add_theme_color_override("font_color", TEXT)
	bubble._panel.add_child(bubble._label)
	return bubble


## Long enough to read the line, and no longer.
static func time_for(text: String) -> float:
	return clampf(HOLD_BASE + text.length() * HOLD_PER_CHAR, HOLD_MIN, HOLD_MAX)


## Say something new, whether or not the last line has faded.
func say(text: String) -> void:
	# A wrapping label will collapse to a single letter given the chance, so a
	# short line is left unwrapped and a long one is pinned to the wrap width.
	var wraps := text.length() > 34
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wraps else TextServer.AUTOWRAP_OFF
	_label.custom_minimum_size.x = WRAP_WIDTH if wraps else 0.0
	_label.text = text
	_age = 0.0
	_hold = time_for(text)
	modulate.a = 0.0


func _process(delta: float) -> void:
	_age += delta
	# Nothing lays out a Control hanging off a Node2D, so it is done by hand.
	_panel.size = _panel.get_combined_minimum_size()
	_panel.position = Vector2(-_panel.size.x / 2.0, -_height - _panel.size.y)
	if _age < FADE_IN:
		modulate.a = _age / FADE_IN
	elif _age < _hold:
		modulate.a = 1.0
	elif _age < _hold + FADE_OUT:
		modulate.a = 1.0 - (_age - _hold) / FADE_OUT
	else:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if _panel.size == Vector2.ZERO:
		return
	var base := -_height
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-TAIL.x, base), Vector2(TAIL.x, base), Vector2(0, base + TAIL.y)
		]),
		PANEL
	)
