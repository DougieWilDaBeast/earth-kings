class_name StashScreen
extends CanvasLayer
## Camp strongbox stash: move gear and supplies between the marching packs and camp storage.

signal closed

const ICON_SIZE := Vector2(32, 32)

@onready var _root: Control = %Root
@onready var _packs_list: VBoxContainer = %PacksList
@onready var _stash_list: VBoxContainer = %StashList
@onready var _packs_count: Label = %PacksCount
@onready var _stash_count: Label = %StashCount
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	_root.hide()
	add_to_group(EventBus.MODAL_OVERLAY_GROUP)
	EventBus.stash_requested.connect(open)
	_close_button.pressed.connect(close)
	Sfx.attend(_close_button)


func is_open() -> bool:
	return _root.visible


func open() -> void:
	_root.show()
	_rebuild()


func close() -> void:
	_root.hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _rebuild() -> void:
	for child in _packs_list.get_children():
		child.queue_free()
	for child in _stash_list.get_children():
		child.queue_free()

	_packs_count.text = "In Packs: %d" % GameState.stores.size()
	_stash_count.text = "In Camp Strongbox: %d" % GameState.camp_stash.size()

	if GameState.stores.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Your marching packs are empty."
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		_packs_list.add_child(empty_label)
	else:
		for item_id: String in GameState.stores:
			_packs_list.add_child(_make_pack_row(item_id))

	if GameState.camp_stash.is_empty():
		var empty_label := Label.new()
		empty_label.text = "The camp strongbox is empty."
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		_stash_list.add_child(empty_label)
	else:
		for item_id: String in GameState.camp_stash:
			_stash_list.add_child(_make_stash_row(item_id))


func _make_pack_row(item_id: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var icon_rect := TextureRect.new()
	icon_rect.texture = Gear.icon(item_id)
	icon_rect.custom_minimum_size = ICON_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon_rect)

	var label := Label.new()
	label.text = "%s (%s)" % [Gear.display_name(item_id), Gear.kind(item_id)]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var deposit_btn := Button.new()
	deposit_btn.text = "Stash ->"
	deposit_btn.pressed.connect(func() -> void:
		GameState.stash_deposit(item_id)
		_rebuild()
	)
	Sfx.attend(deposit_btn)
	row.add_child(deposit_btn)

	return row


func _make_stash_row(item_id: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var withdraw_btn := Button.new()
	withdraw_btn.text = "<- Take"
	withdraw_btn.pressed.connect(func() -> void:
		GameState.stash_withdraw(item_id)
		_rebuild()
	)
	Sfx.attend(withdraw_btn)
	row.add_child(withdraw_btn)

	var icon_rect := TextureRect.new()
	icon_rect.texture = Gear.icon(item_id)
	icon_rect.custom_minimum_size = ICON_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon_rect)

	var label := Label.new()
	label.text = "%s (%s)" % [Gear.display_name(item_id), Gear.kind(item_id)]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	return row
