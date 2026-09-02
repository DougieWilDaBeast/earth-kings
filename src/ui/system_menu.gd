extends CanvasLayer
## Save / load overlay. Always present under [Game], like the dialogue box, and
## opened by [signal EventBus.system_menu_requested] so no scene owns it.

@onready var _root: Control = %Root
@onready var _load_button: Button = %LoadButton
@onready var _status: Label = %StatusLabel
@onready var _mute_button: Button = %MuteButton
@onready var _music_slider: HSlider = %MusicSlider
@onready var _chatter_button: Button = %ChatterButton


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
	_music_slider.value = Music.volume
	_music_slider.value_changed.connect(func(level: float) -> void: Music.set_volume(level))
	_mute_button.button_pressed = Music.muted
	_mute_button.toggled.connect(_on_mute_toggled)
	_on_mute_toggled(Music.muted)
	_chatter_button.button_pressed = Pace.quiet_banter
	_chatter_button.toggled.connect(_on_chatter_toggled)
	_on_chatter_toggled(Pace.quiet_banter)


func open() -> void:
	# The seed lives here so a world worth replaying can be written down.
	_status.text = "World seed %d" % GameState.world.world_seed if GameState.world != null else ""
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
	EventBus.request_scene.emit("world", {})


func _on_title_pressed() -> void:
	close()
	EventBus.request_scene.emit("title", {})


func _on_mute_toggled(silent: bool) -> void:
	_mute_button.text = "Music: off" if silent else "Music"
	Music.set_muted(silent)


## Off does not mean silent. The party still talk; it just goes to the log and
## a bubble instead of stopping the game to say it.
func _on_chatter_toggled(quiet: bool) -> void:
	_chatter_button.text = "Chatter: in the log" if quiet else "Chatter: in full"
	Pace.quiet_banter = quiet
