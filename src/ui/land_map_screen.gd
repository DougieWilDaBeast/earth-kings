extends CanvasLayer
## The large map, opened over the ground with M or from the journal ([D232]). The ground goes on
## under it: a party walking itself, or walking to a click, keeps walking while it is open
## (`doug-md`, play-test 4). WASD or the arrows move the map rather than the party; M or Esc puts it
## away. Right-click a place for "Go here" or "Place a marker".
##
## Not one of the modal screens: those stop the ground, and this must not.
##
## Loaded by path, not by `class_name` ([D41]).

const LandMap := preload("res://src/ui/land_map.gd")

## Cells a second the keys move the map at the default zoom.
const PAN_SPEED := 22.0
const MARGIN := 28.0

signal said(line: String)
signal closed

var map: Control
var _dim: ColorRect
var _title: Label
var _hint: Label
## The last thing the map said ("Marker 2 placed on the map."), since the ground's log is under it.
var _status: Label
## A phone's way round the large map, which has no M, C, + or - to press ([D377]).
var _buttons: HBoxContainer


func _ready() -> void:
	layer = 40
	add_to_group(EventBus.BIG_MAP_GROUP)
	visible = false
	_dim = ColorRect.new()
	_dim.color = Color(0.0, 0.0, 0.0, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	map = LandMap.new()
	map.full = true
	map.cell_px = 22.0
	map.set_anchors_preset(Control.PRESET_FULL_RECT)
	map.offset_left = MARGIN
	map.offset_top = MARGIN + 30.0
	map.offset_right = -MARGIN
	map.offset_bottom = -MARGIN - 26.0
	map.said.connect(func(line: String) -> void:
		_status.text = line
		said.emit(line))
	add_child(map)
	_title = _line(20, Color(0.98, 0.86, 0.52))
	_title.position = Vector2(MARGIN, MARGIN - 4.0)
	_status = _line(15, Color(0.9, 0.95, 0.88))
	_status.anchor_left = 1.0
	_status.anchor_right = 1.0
	_status.offset_left = -760.0
	_status.offset_right = -MARGIN
	_status.offset_top = MARGIN
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint = _line(14, Color(0.86, 0.86, 0.9))
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_left = MARGIN
	_hint.offset_top = -MARGIN - 18.0
	# Wrapped upwards on a screen too narrow for it in one line, a phone held upright ([D377]).
	_hint.anchor_right = 1.0
	_hint.offset_right = -MARGIN
	_hint.offset_bottom = -MARGIN + 4.0
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Pad.changed.connect(_say)
	_buttons = HBoxContainer.new()
	_buttons.anchor_left = 1.0
	_buttons.anchor_right = 1.0
	# In the map's top right corner, clear of the hint, which wraps upwards on a phone.
	_buttons.offset_left = -MARGIN - 8.0
	_buttons.offset_right = -MARGIN - 8.0
	_buttons.offset_top = MARGIN + 38.0
	_buttons.offset_bottom = MARGIN + 94.0
	_buttons.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_buttons.add_theme_constant_override("separation", 8)
	add_child(_buttons)
	for each: Array in [["+", func() -> void: map.zoom(1.0)], ["-", func() -> void: map.zoom(-1.0)],
			["Party", func() -> void: map.recentre()], ["Close", close]]:
		var button := Button.new()
		button.text = str(each[0])
		button.custom_minimum_size = Vector2(56, 56)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(each[1])
		Sfx.attend(button)
		_buttons.add_child(button)


func _line(font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func is_open() -> bool:
	return visible


func open() -> void:
	visible = true
	_buttons.visible = Pace.is_touch_enabled()
	_status.text = ""
	map.recentre()
	_say()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()
	EventBus.overlay_closed.emit()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _say() -> void:
	var world: World = GameState.world
	_title.text = "The map" + ("  ·  %s" % world.region_at(world.player_cell) if world != null else "")
	_hint.text = Pad.say("Right-click a place: Go here, or Place a marker  ·  click a marker to go there  ·  %s or drag to look about  ·  wheel to zoom  ·  C to come back to the party  ·  M or Esc to put it away" % (
		"the stick" if Pad.using_pad else "WASD"))


func _process(delta: float) -> void:
	if not visible:
		return
	var axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if axis != Vector2.ZERO:
		map.pan(axis * PAN_SPEED * delta * 12.0 / map.cell_px)


func _input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and (event as InputEventKey).keycode == KEY_M):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey and (event as InputEventKey).keycode == KEY_C:
		get_viewport().set_input_as_handled()
		map.recentre()
	elif event is InputEventKey and (event as InputEventKey).keycode in [KEY_EQUAL, KEY_KP_ADD]:
		get_viewport().set_input_as_handled()
		map.zoom(1.0)
	elif event is InputEventKey and (event as InputEventKey).keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
		get_viewport().set_input_as_handled()
		map.zoom(-1.0)
