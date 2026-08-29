class_name CutsceneLayer
extends CanvasLayer
## The frame a cutscene plays inside: black bars closing in from the top and
## bottom, and a line of narration across the lower one.
##
## Nothing here decides what happens; it is only the border around it. The
## staging lives in [AreaCutscene].

const BAR_HEIGHT := 88.0
const SLIDE_TIME := 0.35

@onready var _top: ColorRect = %TopBar
@onready var _bottom: ColorRect = %BottomBar
@onready var _caption: Label = %CaptionLabel

var _open: bool = false


func _ready() -> void:
	add_to_group(EventBus.MODAL_OVERLAY_GROUP)
	add_to_group(EventBus.CUTSCENE_FRAME_GROUP)
	_caption.text = ""
	_caption.modulate.a = 0.0
	_set_bars(0.0)


## Walking is held while the bars are out, like any other overlay.
func is_open() -> bool:
	return _open


func open() -> void:
	if _open:
		return
	_open = true
	await _slide_to(BAR_HEIGHT)


func close() -> void:
	if not _open:
		return
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
