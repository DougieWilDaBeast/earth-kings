extends CanvasLayer
## A line along the top of the screen that says something about the save, then
## fades: upgraded, restored from the backup, or left alone ([D56]). Lives on
## [Game], above whichever scene is in, so a notice raised while loading from the
## title screen is still up when the world comes in.
##
## Loaded by path, not by `class_name` ([D41]).

const SHOWN_FOR := 5.0
const FADE := 0.6

var _label: Label
var _tween: Tween


func _ready() -> void:
	layer = 90
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_label.offset_top = 16.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_constant_override("outline_size", 6)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.modulate.a = 0.0
	add_child(_label)
	EventBus.save_notice.connect(show_notice)


func show_notice(text: String) -> void:
	# Two notices at once (an old save that was also restored) read as one line.
	if _label.modulate.a > 0.0 and _label.text != "" and _label.text != text:
		text = "%s  %s" % [_label.text, text]
	_label.text = text
	if _tween != null:
		_tween.kill()
	_label.modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_interval(SHOWN_FOR)
	_tween.tween_property(_label, "modulate:a", 0.0, FADE)
