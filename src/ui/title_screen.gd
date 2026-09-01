extends Control
## Boot menu: start a fresh run or continue from the save in `user://`.

## Set by [Game] before the scene enters the tree; unused here.
var boot_payload: Dictionary = {}

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _training_button: Button = %TrainingButton
@onready var _museum_button: Button = %MuseumButton
@onready var _quit_button: Button = %QuitButton
@onready var _crest: TextureRect = %Crest
@onready var _version_label: Label = %VersionLabel


func _ready() -> void:
	# A soak left running is not something to carry into the next run.
	Pace.reset()
	_continue_button.disabled = not GameState.has_save()
	_continue_button.pressed.connect(_on_continue_pressed)
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_training_button.pressed.connect(func() -> void: EventBus.request_scene.emit("training", {}))
	_museum_button.pressed.connect(func() -> void: EventBus.request_scene.emit("museum", {}))
	_quit_button.pressed.connect(func() -> void: get_tree().quit())
	for button in [_continue_button, _new_game_button, _training_button, _museum_button, _quit_button]:
		button.theme_type_variation = &"GrandButton"
		# Keeps the mouse and the keyboard pointing at the same entry.
		button.mouse_entered.connect(_on_button_hovered.bind(button))
		Sfx.attend(button)
	if _continue_button.disabled:
		_new_game_button.grab_focus()
	else:
		_continue_button.grab_focus()

	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	_version_label.text = "Earth Kings — %s" % version if version != "" else "Earth Kings"
	_wear_your_own_face()
	_breathe_crest()
	_fade_in()


## The crest is whoever you are playing as, read off the save. With no save it
## stays the sworn blade the scene ships with.
func _wear_your_own_face() -> void:
	var face := Database.unit_face(_saved_lead())
	if face != null:
		_crest.texture = face


func _saved_lead() -> String:
	if not GameState.has_save():
		return ""
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GameState.SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return ""
	for entry: Dictionary in parsed.get("roster", {}).get("characters", []):
		if bool(entry.get("is_player", false)):
			return String(entry.get("template_id", ""))
	return ""


func _on_button_hovered(button: Button) -> void:
	if not button.disabled:
		button.grab_focus()


func _fade_in() -> void:
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	create_tween().tween_property(self, "modulate:a", 1.0, 0.6)


func _breathe_crest() -> void:
	var tween := create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tween.tween_property(_crest, "scale", Vector2(1.03, 1.03), 2.4)
	tween.tween_property(_crest, "scale", Vector2.ONE, 2.4)


func _on_continue_pressed() -> void:
	if GameState.load_save():
		EventBus.request_scene.emit("world", {})


func _on_new_game_pressed() -> void:
	EventBus.request_scene.emit("character_select", {})

