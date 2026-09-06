extends CanvasLayer
## Save / load overlay. Always present under [Game], like the dialogue box, and
## opened by [signal EventBus.system_menu_requested] so no scene owns it.

const SETTINGS_PATH := "user://settings.cfg"

const MAPPABLE_ACTIONS := [
	{ "action": "move_up", "label": "Move Up" },
	{ "action": "move_down", "label": "Move Down" },
	{ "action": "move_left", "label": "Move Left" },
	{ "action": "move_right", "label": "Move Right" },
	{ "action": "interact", "label": "Interact / Step In" },
	{ "action": "toggle_view", "label": "World / Planar View" },
	{ "action": "open_party", "label": "Party Screen" },
	{ "action": "site_errands", "label": "Errands / Job Board" },
	{ "action": "site_grimoire", "label": "Grimoire / Spells" },
	{ "action": "battle_auto", "label": "Auto-Walk / Auto-Play" },
	{ "action": "battle_speed", "label": "Game Speed" },
	{ "action": "command_move", "label": "Battle Move" },
	{ "action": "command_flash_step", "label": "Battle Flash Step" },
	{ "action": "command_wait", "label": "Battle Wait" },
	{ "action": "cycle_next", "label": "Cycle Unit / Turn" },
	{ "action": "camera_zoom_in", "label": "Zoom In" },
	{ "action": "camera_zoom_out", "label": "Zoom Out" },
	{ "action": "camera_recentre", "label": "Recentre Camera" },
]

@onready var _root: Control = %Root
@onready var _main_panel: PanelContainer = $Root/Panel
@onready var _controls_panel: PanelContainer = %ControlsPanel
@onready var _bindings_list: VBoxContainer = %BindingsList
@onready var _controls_button: Button = %ControlsButton
@onready var _reset_bindings_button: Button = %ResetBindingsButton
@onready var _back_from_controls_button: Button = %BackFromControlsButton
@onready var _load_button: Button = %LoadButton
@onready var _status: Label = %StatusLabel
@onready var _mute_button: Button = %MuteButton
@onready var _music_slider: HSlider = %MusicSlider
@onready var _chatter_button: Button = %ChatterButton
@onready var _difficulty_button: Button = %DifficultyButton
@onready var _touch_button: Button = %TouchButton

var _rebind_action: String = ""
var _rebind_button: Button = null


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
	_difficulty_button.pressed.connect(_on_difficulty_pressed)
	_update_difficulty_button()
	_touch_button.pressed.connect(_on_touch_pressed)
	_update_touch_button()

	_controls_button.pressed.connect(_open_controls)
	_back_from_controls_button.pressed.connect(_close_controls)
	_reset_bindings_button.pressed.connect(_reset_controls_to_defaults)

	for btn in [save_button, _load_button, title_button, close_button, _mute_button, _chatter_button, _difficulty_button, _touch_button, _controls_button, _back_from_controls_button, _reset_bindings_button]:
		Sfx.attend(btn)

	_load_custom_bindings()


func open() -> void:
	# The seed lives here so a world worth replaying can be written down.
	_status.text = "World seed %d" % GameState.world.world_seed if GameState.world != null else ""
	_load_button.disabled = not GameState.has_save()
	_update_difficulty_button()
	_main_panel.show()
	_controls_panel.hide()
	_rebind_action = ""
	_root.show()


func close() -> void:
	_rebind_action = ""
	_root.hide()


func is_open() -> bool:
	return _root.visible


func _unhandled_input(event: InputEvent) -> void:
	if not _root.visible:
		return
	if _rebind_action != "":
		if event is InputEventKey and event.pressed and not event.echo:
			get_viewport().set_input_as_handled()
			if event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE:
				_cancel_rebind()
			else:
				_apply_rebind(_rebind_action, event)
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _controls_panel.visible:
			_close_controls()
		else:
			close()


func _open_controls() -> void:
	_main_panel.hide()
	_controls_panel.show()
	_rebuild_controls_list()


func _close_controls() -> void:
	_cancel_rebind()
	_controls_panel.hide()
	_main_panel.show()


func _rebuild_controls_list() -> void:
	for child in _bindings_list.get_children():
		child.queue_free()

	for entry: Dictionary in MAPPABLE_ACTIONS:
		var action: String = entry["action"]
		var label_text: String = entry["label"]

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl := Label.new()
		name_lbl.text = label_text
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 13)
		row.add_child(name_lbl)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(120, 26)
		btn.add_theme_font_size_override("font_size", 12)
		btn.text = _action_key_text(action)
		btn.pressed.connect(func() -> void: _start_rebind(action, btn))
		Sfx.attend(btn)
		row.add_child(btn)

		_bindings_list.add_child(row)


func _action_key_text(action: String) -> String:
	if not InputMap.has_action(action):
		return "None"
	var events := InputMap.action_get_events(action)
	for ev in events:
		if ev is InputEventKey:
			var key_ev := ev as InputEventKey
			var code: Key = key_ev.physical_keycode if key_ev.physical_keycode != KEY_NONE else key_ev.keycode
			return OS.get_keycode_string(code)
		if ev is InputEventMouseButton:
			var mouse_ev := ev as InputEventMouseButton
			if mouse_ev.button_index == MOUSE_BUTTON_WHEEL_UP:
				return "Wheel Up"
			if mouse_ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				return "Wheel Down"
			return "Mouse %d" % mouse_ev.button_index
	return "None"


func _start_rebind(action: String, button: Button) -> void:
	if _rebind_button != null and is_instance_valid(_rebind_button):
		_rebind_button.text = _action_key_text(_rebind_action)
	_rebind_action = action
	_rebind_button = button
	button.text = "[ Press Key... ]"


func _cancel_rebind() -> void:
	if _rebind_button != null and is_instance_valid(_rebind_button):
		_rebind_button.text = _action_key_text(_rebind_action)
	_rebind_action = ""
	_rebind_button = null


func _apply_rebind(action: String, event: InputEventKey) -> void:
	var code: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	# Erase existing key events for this action
	var to_remove: Array[InputEvent] = []
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			to_remove.append(ev)
	for ev in to_remove:
		InputMap.action_erase_event(action, ev)

	var new_ev := InputEventKey.new()
	new_ev.physical_keycode = code
	InputMap.action_add_event(action, new_ev)

	_save_custom_binding(action, code)
	_cancel_rebind()
	_rebuild_controls_list()


func _save_custom_binding(action: String, keycode: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("controls", action, keycode)
	cfg.save(SETTINGS_PATH)


func _load_custom_bindings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK or not cfg.has_section("controls"):
		return
	for action in cfg.get_section_keys("controls"):
		var keycode: int = int(cfg.get_value("controls", action, 0))
		if keycode != 0 and InputMap.has_action(action):
			var to_remove: Array[InputEvent] = []
			for ev in InputMap.action_get_events(action):
				if ev is InputEventKey:
					to_remove.append(ev)
			for ev in to_remove:
				InputMap.action_erase_event(action, ev)
			var new_ev := InputEventKey.new()
			new_ev.physical_keycode = keycode
			InputMap.action_add_event(action, new_ev)


func _reset_controls_to_defaults() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK and cfg.has_section("controls"):
		cfg.erase_section("controls")
		cfg.save(SETTINGS_PATH)
	InputMap.load_from_project_settings()
	_cancel_rebind()
	_rebuild_controls_list()


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


func _on_difficulty_pressed() -> void:
	GameState.difficulty = Difficulty.cycle(GameState.difficulty)
	_update_difficulty_button()


func _update_difficulty_button() -> void:
	_difficulty_button.text = "Difficulty: %s" % Difficulty.display_name(GameState.difficulty)
	_difficulty_button.tooltip_text = Difficulty.blurb(GameState.difficulty)


func _on_touch_pressed() -> void:
	Pace.cycle_touch_mode()
	_update_touch_button()


func _update_touch_button() -> void:
	match Pace.touch_mode:
		"on":
			_touch_button.text = "Touch Controls: On"
		"off":
			_touch_button.text = "Touch Controls: Off"
		_:
			_touch_button.text = "Touch Controls: Auto (%s)" % ("On" if Pace.is_touch_enabled() else "Off")
