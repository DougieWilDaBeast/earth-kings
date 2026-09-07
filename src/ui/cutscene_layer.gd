class_name CutsceneLayer
extends CanvasLayer
## The frame a cutscene plays inside: black bars closing in from the top and
## bottom, and a line of narration across the lower one.
##
## Nothing here decides what happens; it is only the border around it. The
## staging lives in [AreaCutscene].

signal skip_requested

const BAR_HEIGHT := 88.0
const SLIDE_TIME := 0.35

@onready var _top: ColorRect = %TopBar
@onready var _bottom: ColorRect = %BottomBar
@onready var _caption: Label = %CaptionLabel
@onready var _skip_button: Button = %SkipButton

var _open: bool = false


func _ready() -> void:
	add_to_group(EventBus.MODAL_OVERLAY_GROUP)
	add_to_group(EventBus.CUTSCENE_FRAME_GROUP)
	_caption.text = ""
	_caption.modulate.a = 0.0
	_set_bars(0.0)
	if _skip_button != null:
		_skip_button.visible = false
		_skip_button.modulate.a = 0.0
		_skip_button.pressed.connect(func() -> void:
			if _open:
				skip_requested.emit()
		)


## Walking is held while the bars are out, like any other overlay.
func is_open() -> bool:
	return _open


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_pressed() and not event.is_echo():
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.physical_keycode in [KEY_SPACE, KEY_ESCAPE, KEY_ENTER] or key_event.keycode in [KEY_SPACE, KEY_ESCAPE, KEY_ENTER]:
				get_viewport().set_input_as_handled()
				skip_requested.emit()
				return
		elif event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				get_viewport().set_input_as_handled()
				skip_requested.emit()
				return
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			skip_requested.emit()


func open() -> void:
	if _open:
		return
	_open = true
	if _skip_button != null:
		_skip_button.visible = true
		_skip_button.modulate.a = 0.0
	await _slide_to(BAR_HEIGHT)
	if _skip_button != null and _open:
		var tween := create_tween()
		tween.tween_property(_skip_button, "modulate:a", 1.0, 0.2)


func close() -> void:
	if not _open:
		return
	if _skip_button != null:
		_skip_button.visible = false
		_skip_button.modulate.a = 0.0
	await say("")
	await _slide_to(0.0)
	_open = false


## Put a line of narration up, or clear it with an empty string.
func say(text: String) -> void:
	var tween := create_tween()
	tween.tween_property(_caption, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func() -> void: _caption.text = text)
	if text != "":
		tween.tween_property(_caption, "modulate:a", 1.0, 0.2)
	await tween.finished


func _slide_to(height: float) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_top, "offset_bottom", height, SLIDE_TIME)
	tween.tween_property(_bottom, "offset_top", -height, SLIDE_TIME)
	await tween.finished


func _set_bars(height: float) -> void:
	_top.offset_bottom = height
	_bottom.offset_top = -height
