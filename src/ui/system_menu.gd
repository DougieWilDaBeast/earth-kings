extends CanvasLayer
## Save / load overlay. Always present under [Game], like the dialogue box, and
## opened by [signal EventBus.system_menu_requested] so no scene owns it.

@onready var _root: Control = %Root
@onready var _load_button: Button = %LoadButton
@onready var _status: Label = %StatusLabel


func _ready() -> void:
	_root.hide()
	add_to_group(EventBus.MODAL_OVERLAY_GROUP)
	EventBus.system_menu_requested.connect(open)
	var save_button: Button = %SaveButton
	save_button.pressed.connect(_on_save_pressed)
	_load_button.pressed.connect(_on_load_pressed)
	var title_button: Button = %TitleButton
	title_button.pressed.connect(_on_title_pressed)
	var close_button: Button = %CloseButton
	close_button.pressed.connect(close)


func open() -> void:
	_status.text = ""
	_load_button.disabled = not GameState.has_save()
	_root.show()


func close() -> void:
	_root.hide()


func is_open() -> bool:
	return _root.visible


func _unhandled_input(event: InputEvent) -> void:
	if _root.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _on_save_pressed() -> void:
	GameState.save()
	_load_button.disabled = not GameState.has_save()
	_status.text = "Progress saved."


func _on_load_pressed() -> void:
	if not GameState.load_save():
		_status.text = "No save to load."
		return
	close()
	EventBus.request_scene.emit("overworld", {})


func _on_title_pressed() -> void:
	close()
	EventBus.request_scene.emit("title", {})
