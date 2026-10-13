extends CanvasLayer
## The How to Play page. Always present under [Game] and opened by
## [signal EventBus.how_to_play_requested], from the title screen or the menu.
## Every word on it is in `data/how_to_play.json`.
##
## Loaded by path, not by `class_name` ([D41]).

const SaveFile := preload("res://src/chronicle/save_file.gd")

const DATA_PATH := "res://data/how_to_play.json"

var _root: Control
var _body: RichTextLabel
var _jumps: HBoxContainer
## Paragraph each section heading starts on, for the buttons along the top.
var _starts: Array[int] = []


func _ready() -> void:
	layer = 9
	add_to_group(EventBus.MODAL_OVERLAY_GROUP)
	_build()
	_root.hide()
	EventBus.how_to_play_requested.connect(open)


func is_open() -> bool:
	return _root.visible


func open() -> void:
	if _body.get_parsed_text() == "":
		_fill()
	_root.show()
	_body.scroll_to_line(0)
	_body.grab_focus()


func close() -> void:
	_root.hide()
	EventBus.overlay_closed.emit()


## The page's sections, as written in the data file.
static func sections() -> Array:
	var parsed: Variant = SaveFile.read(DATA_PATH)
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	return parsed.get("sections", [])


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or not event.is_pressed() or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel"):
		close()


func _fill() -> void:
	_body.clear()
	_starts.clear()
	for child in _jumps.get_children():
		_jumps.remove_child(child)
		child.queue_free()
	var paragraph := 0
	for section: Dictionary in sections():
		var heading := str(section.get("heading", ""))
		_starts.append(paragraph)
		var index := _starts.size() - 1
		var jump := Button.new()
		jump.text = heading
		jump.focus_mode = Control.FOCUS_NONE
		jump.add_theme_font_size_override("font_size", 12)
		jump.pressed.connect(func() -> void: _body.scroll_to_paragraph(_starts[index]))
		Sfx.attend(jump)
		_jumps.add_child(jump)

		_body.push_font_size(19)
		_body.push_color(Color(0.98, 0.86, 0.52))
		_body.add_text(heading)
		_body.pop()
		_body.pop()
		_body.newline()
		paragraph += 1
		for line: Variant in section.get("lines", []):
			_body.add_text("•  %s" % str(line))
			_body.newline()
			paragraph += 1
		_body.newline()
		paragraph += 1


func _build() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.03, 0.03, 0.05, 0.86)
	_root.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 24
	panel.offset_right = -24
	panel.offset_top = 24
	panel.offset_bottom = -24
	_root.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var heading := Label.new()
	heading.text = "How to Play"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 24)
	column.add_child(heading)

	# Seven buttons do not fit a phone's width in a row, so they scroll sideways.
	var jump_scroll := ScrollContainer.new()
	jump_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	jump_scroll.custom_minimum_size = Vector2(0, 34)
	column.add_child(jump_scroll)
	_jumps = HBoxContainer.new()
	_jumps.add_theme_constant_override("separation", 6)
	jump_scroll.add_child(_jumps)

	_body = RichTextLabel.new()
	_body.name = "Body"
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.scroll_active = true
	_body.focus_mode = Control.FOCUS_ALL
	_body.add_theme_font_size_override("normal_font_size", 15)
	_body.add_theme_constant_override("line_separation", 4)
	column.add_child(_body)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(160, 0)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(close)
	Sfx.attend(close_button)
	column.add_child(close_button)
