class_name JournalScreen
extends CanvasLayer
## The book of what you have met.
##
## A page is opened by standing across a field from something, and it opens
## nearly blank. Every question mark on it is a thing you have not earned yet:
## fight it, take a blow from it, put one down, and the line fills itself in.
##
## Read-only. Nothing on this screen can be spent, chosen or missed.

signal closed

const UNKNOWN_COLOUR := Color(0.42, 0.40, 0.38)
const KNOWN_COLOUR := Color(0.90, 0.87, 0.79)
const LABEL_COLOUR := Color(0.66, 0.64, 0.59)
const HEADING_COLOUR := Color(0.96, 0.83, 0.44)
const FACE_SIZE := Vector2(96, 96)

@onready var _backdrop: ColorRect = %Backdrop
@onready var _fullness: Label = %FullnessLabel
@onready var _list: VBoxContainer = %EntryList
@onready var _page: VBoxContainer = %Page

var _showing: String = ""


func _ready() -> void:
	_backdrop.hide()
	add_to_group(EventBus.MODAL_OVERLAY_GROUP)
	EventBus.journal_requested.connect(open)


func is_open() -> bool:
	return _backdrop.visible


func open() -> void:
	_backdrop.show()
	_rebuild()


func close() -> void:
	_backdrop.hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_N):
		get_viewport().set_input_as_handled()
		close()


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	var world: World = GameState.world
	var met := Journal.met(world)
	var fullness := Journal.fullness(world)
	_fullness.text = "%d of %d written up" % [fullness[0], fullness[1]]

	if met.is_empty():
		_showing = ""
		_show_page()
		return
	for template_id: String in met:
		var button := Button.new()
		button.text = str(Database.unit_template(template_id).get("display_name", template_id))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_open_page.bind(template_id))
		Sfx.attend(button)
		_list.add_child(button)
	if not met.has(_showing):
		_showing = met[0]
	_show_page()


func _open_page(template_id: String) -> void:
	_showing = template_id
	_show_page()


func _show_page() -> void:
	for child in _page.get_children():
		child.queue_free()
	if _showing == "":
		_page.add_child(_line("Nothing yet. The book fills up by being carried into fights.", LABEL_COLOUR))
		return

	var world: World = GameState.world
	var template := Database.unit_template(_showing)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	var face := TextureRect.new()
	face.custom_minimum_size = FACE_SIZE
	face.texture = Database.unit_face(_showing)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(face)

	var names := VBoxContainer.new()
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var title := _line(str(template.get("display_name", _showing)), HEADING_COLOUR)
	title.add_theme_font_size_override("font_size", 22)
	names.add_child(title)
	names.add_child(_line(str(template.get("job", "")), LABEL_COLOUR))
	head.add_child(names)
	_page.add_child(head)

	var rows := GridContainer.new()
	rows.columns = 2
	rows.add_theme_constant_override("h_separation", 20)
	rows.add_theme_constant_override("v_separation", 3)
	for row: Array in Journal.page(world, _showing):
		rows.add_child(_line(str(row[0]), LABEL_COLOUR))
		var value := str(row[1])
		rows.add_child(_line(value, UNKNOWN_COLOUR if value == Journal.UNKNOWN else KNOWN_COLOUR))
	_page.add_child(rows)

	var heading := _line("What it does", HEADING_COLOUR)
	heading.add_theme_font_size_override("font_size", 18)
	_page.add_child(heading)
	for ability: String in Journal.abilities(world, _showing):
		var unknown := ability == Journal.UNKNOWN
		_page.add_child(_line(
			"  something you have not seen" if unknown else "  %s" % ability,
			UNKNOWN_COLOUR if unknown else KNOWN_COLOUR
		))


func _line(text: String, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", colour)
	return label
