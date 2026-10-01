extends CanvasLayer
## The Adventurers Guild hall (`src/chronicle/guild.gd`): the register of gates,
## worst first, and contracts to shut the open ones. Always present under
## [Game], opened by [signal EventBus.guild_requested] on the hall the party is
## standing in, from the world map or from a clerk inside the settlement.

const Guild := preload("res://src/chronicle/guild.gd")

var _root: Control
var _title: Label
var _said: Label
var _list: VBoxContainer
var _close_button: Button


func _ready() -> void:
	layer = 8
	_build()
	_root.hide()
	add_to_group(EventBus.MODAL_OVERLAY_GROUP)
	EventBus.guild_requested.connect(open)


func is_open() -> bool:
	return _root.visible


func open() -> void:
	var world: World = GameState.world
	if world == null or Guild.hall_at(world, world.player_cell) == null:
		return
	_said.text = ""
	_root.show()
	_rebuild()
	_close_button.grab_focus()


func close() -> void:
	_root.hide()
	EventBus.overlay_closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("site_guild"):
		get_viewport().set_input_as_handled()
		close()


func _rebuild() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var world: World = GameState.world
	var hall := Guild.hall_at(world, world.player_cell)
	if hall == null:
		close()
		return
	_title.text = Guild.line("welcome", {"hall": hall.display_name})

	for muster: Dictionary in world.musters:
		_list.add_child(_muster_row(world, hall, muster))

	var register := Guild.register(world, hall.cell, GameState.errands)
	if register.is_empty():
		_list.add_child(_label(Guild.line("empty")))
		return
	for entry: Dictionary in register:
		_list.add_child(_row(world, hall, entry))


func _muster_row(world: World, hall: Site, muster: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var text := _label(Guild.describe_muster(muster))
	text.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var gate_cell := Vector2i(int(muster["gate"][0]), int(muster["gate"][1]))
	var here := Vector2i(int(muster["hall"][0]), int(muster["hall"][1])) == hall.cell
	if here and Guild.standing_with(GameState.errands, gate_cell).is_empty():
		var join := Button.new()
		join.text = "Stand with them"
		join.pressed.connect(
			func() -> void:
				_said.text = Guild.join(world, muster, GameState.errands)
				_rebuild()
		)
		Sfx.attend(join)
		row.add_child(join)
	return row


func _row(world: World, hall: Site, entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var text := _label(Guild.describe(entry))
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	if entry["state"] != Guild.BREWING and not entry["contracted"]:
		var take := Button.new()
		take.text = "Take the contract"
		take.pressed.connect(
			func() -> void:
				_said.text = Guild.take(world, hall, world.site_at(entry["cell"]), GameState.errands)
				_rebuild()
		)
		Sfx.attend(take)
		row.add_child(take)
	return row


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.04, 0.04, 0.06, 0.88)
	_root.add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	_root.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var heading := Label.new()
	heading.text = "The Adventurers Guild"
	heading.add_theme_font_size_override("font_size", 22)
	column.add_child(heading)

	_title = _label("")
	column.add_child(_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

	_said = _label("")
	_said.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	column.add_child(_said)

	_close_button = Button.new()
	_close_button.text = "Close"
	_close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_close_button.pressed.connect(close)
	Sfx.attend(_close_button)
	column.add_child(_close_button)
