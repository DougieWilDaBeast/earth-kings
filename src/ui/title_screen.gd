extends Control
## Boot menu: start a fresh run or continue from the save in `user://`.

const SaveFile := preload("res://src/chronicle/save_file.gd")
const Sixteen := preload("res://src/chronicle/sixteen.gd")
## Where the player's own settings live; the tutorial offer is remembered there.
const SETTINGS_PATH := "user://settings.cfg"

## Set by [Game] before the scene enters the tree; unused here.
var boot_payload: Dictionary = {}

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _tutorial_button: Button = %TutorialButton
@onready var _how_to_play_button: Button = %HowToPlayButton
@onready var _training_button: Button = %TrainingButton
@onready var _coliseum_button: Button = %ColiseumButton
@onready var _museum_button: Button = %MuseumButton
@onready var _credits_button: Button = %CreditsButton
@onready var _quit_button: Button = %QuitButton
@onready var _crest: TextureRect = %Crest
@onready var _version_label: Label = %VersionLabel


func _ready() -> void:
	# A soak left running is not something to carry into the next run.
	Pace.reset()
	_continue_button.disabled = not GameState.has_save()
	_continue_button.pressed.connect(_on_continue_pressed)
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_tutorial_button.pressed.connect(func() -> void: EventBus.tutorial_requested.emit())
	_how_to_play_button.pressed.connect(func() -> void: EventBus.how_to_play_requested.emit())
	# The page shuts on top of this menu; the keyboard comes back to where it was.
	EventBus.overlay_closed.connect(func() -> void:
		if is_inside_tree() and _how_to_play_button.is_visible_in_tree():
			_how_to_play_button.grab_focus()
	)
	_training_button.pressed.connect(func() -> void: EventBus.request_scene.emit("training", {}))
	_coliseum_button.pressed.connect(func() -> void: EventBus.request_scene.emit("coliseum", {}))
	_museum_button.pressed.connect(func() -> void: EventBus.request_scene.emit("museum", {}))
	_credits_button.pressed.connect(func() -> void: EventBus.request_scene.emit("credits", {}))
	_quit_button.pressed.connect(func() -> void: get_tree().quit())
	# A page cannot close its own tab: quitting in the browser only freezes the
	# last frame on screen, so the button is not offered there.
	_quit_button.visible = not OS.has_feature("web")
	for button in [
		_continue_button, _new_game_button, _tutorial_button, _how_to_play_button, _training_button, _coliseum_button,
		_museum_button, _credits_button, _quit_button,
	]:
		button.theme_type_variation = &"GrandButton"
		# Keeps the mouse and the keyboard pointing at the same entry.
		button.mouse_entered.connect(_on_button_hovered.bind(button))
		button.focus_entered.connect(_on_button_focused.bind(button))
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
	_offer_the_tour()


## The very first time the game is opened, with no run to continue, the tutorial is offered
## (D63). Asked once per player (`settings.cfg`, section "tutorial"); the button stays either way.
func _offer_the_tour() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	if bool(config.get_value("tutorial", "offered", false)) or GameState.has_save() \
			or DisplayServer.get_name() == "headless":
		return
	config.set_value("tutorial", "offered", true)
	config.save(SETTINGS_PATH)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var card := PanelContainer.new()
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color("#16131c")
	backing.border_color = Color("#c9a45f")
	backing.set_border_width_all(2)
	backing.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", backing)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	shade.add_child(card)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	var heading := Label.new()
	heading.text = "New to Earth Kings?"
	heading.add_theme_font_size_override("font_size", 28)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	var words := Label.new()
	words.text = "Take the ten-minute tour: walk a village, talk, trade, do a favour and win\na sparring fight. Nothing in it is saved. You can take it again from the menu."
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(words)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	var take := Button.new()
	take.text = "Take the tour"
	take.theme_type_variation = &"GrandButton"
	var later := Button.new()
	later.text = "Not now"
	for button: Button in [take, later]:
		row.add_child(button)
		Sfx.attend(button)
	take.pressed.connect(func() -> void:
		shade.queue_free()
		EventBus.tutorial_requested.emit()
	)
	later.pressed.connect(func() -> void:
		shade.queue_free()
		_new_game_button.grab_focus()
	)
	take.grab_focus()


## The crest is whoever you are playing as, read off the save. With no save it
## stays the sworn blade the scene ships with.
func _wear_your_own_face() -> void:
	var face := Database.unit_face(_saved_lead())
	if face != null:
		_crest.texture = face


func _saved_lead() -> String:
	if not GameState.has_save():
		return ""
	var parsed: Variant = SaveFile.read(GameState.SAVE_PATH)
	if typeof(parsed) != TYPE_DICTIONARY:
		return ""
	for entry: Dictionary in parsed.get("roster", {}).get("characters", []):
		if bool(entry.get("is_player", false)):
			return String(entry.get("template_id", ""))
	return ""


func _on_button_hovered(button: Button) -> void:
	if not button.disabled:
		button.grab_focus()


func _on_button_focused(button: Button) -> void:
	# Subtle responsive spring on focused button for a tactile, slick feel
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(button, "scale", Vector2(1.025, 1.025), 0.16)
	button.focus_exited.connect(func() -> void:
		var back_tw := button.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		back_tw.tween_property(button, "scale", Vector2.ONE, 0.14)
	, CONNECT_ONE_SHOT)


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
	EventBus.request_scene.emit("temper_quiz", {
		"fallen": Sixteen.fallen_tempers(), "fallen_heroes": Sixteen.fallen_heroes(),
	})

