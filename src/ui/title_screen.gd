extends Control
## Boot menu: start a fresh run or continue from the save in `user://`.
##
## Two steps, the way the classics do it. When the game opens, it is a
## title card first: the logo big over the sixteen falling, and "Press any key".
## A key slides the logo up into the corner and the menu in down the left, a
## slim list of words over the sky. Coming back from anywhere else, it is the
## menu straight away. The side modes sit behind **Extras** so the main list is
## five words long.

## Where the player's own settings live; the tutorial offer is remembered there.
const SETTINGS_PATH := "user://settings.cfg"
const SaveFile := preload("res://src/chronicle/save_file.gd")
const Sixteen := preload("res://src/chronicle/sixteen.gd")
const RunMode := preload("res://src/chronicle/run_mode.gd")

## Left edge of the menu column, and the gap above the logo once it is up.
const MARGIN_X := 72.0
const MARGIN_TOP := 40.0
## How small the logo sits once the menu is out.
const LOGO_MENU_SCALE := 0.5
const ENTRY_FONT_SIZE := 28
const ENTRY_INDENT := 22.0
const ENTRY_FOCUS_INDENT := 38.0

const COLOR_ENTRY := Color(0.82, 0.78, 0.70)
const COLOR_FOCUS := Color(1.0, 0.86, 0.55)
const COLOR_DISABLED := Color(0.42, 0.40, 0.38)
const COLOR_MARK := Color(0.95, 0.72, 0.38)

const KEYS_MAIN := "W / S to choose     Enter to confirm"
const KEYS_EXTRAS := "W / S to choose     Enter to confirm     Esc to go back"

## Set by [Game] before the scene enters the tree. `from: "boot"` (the game
## opening) opens on the title card; anything else opens on the menu.
var boot_payload: Dictionary = {}

## Set from the scene: the logo's lettering and the carved lettering of the menu.
@export var logo_font: Font
@export var carved_font: Font

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _tutorial_button: Button = %TutorialButton
@onready var _how_to_play_button: Button = %HowToPlayButton
@onready var _extras_button: Button = %ExtrasButton
@onready var _quit_button: Button = %QuitButton
@onready var _training_button: Button = %TrainingButton
@onready var _coliseum_button: Button = %ColiseumButton
@onready var _museum_button: Button = %MuseumButton
@onready var _credits_button: Button = %CreditsButton
@onready var _extras_back_button: Button = %ExtrasBackButton
@onready var _main_list: VBoxContainer = %MainList
@onready var _extras_list: VBoxContainer = %ExtrasList
@onready var _menu: VBoxContainer = %Menu
@onready var _hint_label: Label = %HintLabel
@onready var _marker: Control = %Marker
@onready var _logo: VBoxContainer = %Logo
@onready var _prompt: Label = %Prompt
@onready var _shade: TextureRect = %Shade
@onready var _embers: CPUParticles2D = %Embers
@onready var _crest: TextureRect = %Crest
@onready var _subtitle: Label = %SubtitleLabel
@onready var _version_label: Label = %VersionLabel
@onready var _keys_label: Label = %KeysLabel

var _revealed := false
var _lead_name := ""
var _hints: Dictionary = {}
var _marker_tween: Tween
var _prompt_tween: Tween
## Whether the tour has been offered on this screen yet (D73).
var _offered := false


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
	_extras_button.pressed.connect(_show_extras.bind(true))
	_extras_back_button.pressed.connect(_show_extras.bind(false))
	_training_button.pressed.connect(func() -> void: EventBus.request_scene.emit("training", {}))
	_coliseum_button.pressed.connect(func() -> void: EventBus.request_scene.emit("coliseum", {}))
	_museum_button.pressed.connect(func() -> void: EventBus.request_scene.emit("museum", {}))
	_credits_button.pressed.connect(func() -> void: EventBus.request_scene.emit("credits", {}))
	_quit_button.pressed.connect(func() -> void: get_tree().quit())
	# A page cannot close its own tab: quitting in the browser only freezes the
	# last frame on screen, so the button is not offered there.
	_quit_button.visible = not OS.has_feature("web")

	_lead_name = _saved_lead().get("display_name", "")
	_hints = {
		_continue_button: "Carry on as %s." % _lead_name if _lead_name != "" else "Carry on where you left off.",
		_new_game_button: "A new fall. Sixteen come down out of the sky, and one of them is you.",
		_tutorial_button: "A ten-minute tour of a training village. Nothing in it is saved.",
		_how_to_play_button: "Walking, fighting, and the people who travel with you.",
		_extras_button: "Training Ground, Coliseum, Museum and Credits.",
		_quit_button: "Leave the game. The world keeps until you come back.",
		_training_button: "Pick an enemy and practise on it. Nothing is at stake.",
		_coliseum_button: "Fight night after night for a record. Your real party is untouched.",
		_museum_button: "What your past runs left behind.",
		_credits_button: "Who made this, and with what.",
		_extras_back_button: "Back to the main menu.",
	}
	# The First Hour's cut list (D97): what is hidden is not offered here at all.
	_training_button.visible = not FirstHour.hides("training")
	_coliseum_button.visible = not FirstHour.hides("coliseum")
	_museum_button.visible = not FirstHour.hides("museum")
	var extras: Array[String] = []
	for entry: Button in [_training_button, _coliseum_button, _museum_button, _credits_button]:
		if entry.visible:
			extras.append(entry.text.strip_edges())
	_hints[_extras_button] = ("%s and %s." % [", ".join(extras.slice(0, -1)), extras[-1]]) if extras.size() > 1 \
			else "%s." % extras[0]
	for button: Button in _hints:
		_dress_entry(button)
		# Keeps the mouse and the keyboard pointing at the same entry.
		button.mouse_entered.connect(_on_button_hovered.bind(button))
		button.focus_entered.connect(_on_button_focused.bind(button))
		button.focus_exited.connect(_on_button_unfocused.bind(button))
		Sfx.attend(button)
	_wrap_focus(_main_list)
	_wrap_focus(_extras_list)
	# A button's place is only true once its list has laid it out. Placed on
	# focus alone, the marker opened on the menu beside Continue while New
	# Game was the one chosen.
	_main_list.sort_children.connect(_on_list_sorted)
	_extras_list.sort_children.connect(_on_list_sorted)

	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	_version_label.text = "Earth Kings — %s" % version if version != "" else "Earth Kings"
	_prompt.text = "Tap to begin" if DisplayServer.is_touchscreen_available() else "Press any key"
	_marker.draw.connect(_draw_marker)
	_wear_your_own_face()
	_breathe_crest()
	resized.connect(_layout)

	if str(boot_payload.get("from", "")) == "boot":
		_show_card()
	else:
		_show_menu(false)
	_fade_in()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if not _revealed:
		if event is InputEventKey or event is InputEventMouseButton \
				or event is InputEventScreenTouch or event is InputEventJoypadButton:
			get_viewport().set_input_as_handled()
			Sfx.play(Sfx.SELECT)
			_show_menu(true)
		return
	if event.is_action_pressed("ui_cancel") and _extras_list.visible:
		get_viewport().set_input_as_handled()
		_show_extras(false)


# --- the two steps ------------------------------------------------------------


func _show_card() -> void:
	_revealed = false
	_menu.visible = false
	_marker.visible = false
	_shade.modulate.a = 0.0
	_keys_label.text = ""
	_prompt.visible = true
	_layout()
	_prompt_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	_prompt_tween.tween_property(_prompt, "modulate:a", 0.35, 1.1)
	_prompt_tween.tween_property(_prompt, "modulate:a", 1.0, 1.1)


## The menu, slid in when [param animate] (from the card), or simply there.
func _show_menu(animate: bool) -> void:
	_revealed = true
	_menu.visible = true
	_keys_label.text = KEYS_MAIN
	if _prompt_tween != null:
		_prompt_tween.kill()
	if not animate:
		_prompt.visible = false
		_shade.modulate.a = 1.0
		_subtitle.modulate.a = 0.0
		_layout()
		_focus_first()
		return

	var logo_from := _logo.position
	var logo_scale_from := _logo.scale
	_layout()
	var logo_to := _logo.position
	var menu_to := _menu.position
	_logo.position = logo_from
	_logo.scale = logo_scale_from
	_menu.position = menu_to - Vector2(40.0, 0.0)
	_menu.modulate.a = 0.0
	_marker.visible = false

	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(_prompt, "modulate:a", 0.0, 0.25)
	# Too small to read once the logo is up in the corner.
	tween.tween_property(_subtitle, "modulate:a", 0.0, 0.3)
	tween.tween_property(_logo, "position", logo_to, 0.8)
	tween.tween_property(_logo, "scale", Vector2.ONE * LOGO_MENU_SCALE, 0.8)
	tween.tween_property(_shade, "modulate:a", 1.0, 0.8)
	tween.tween_property(_menu, "position", menu_to, 0.7).set_delay(0.25)
	tween.tween_property(_menu, "modulate:a", 1.0, 0.5).set_delay(0.25)
	tween.chain().tween_callback(func() -> void:
		_prompt.visible = false
		_focus_first()
	)


func _show_extras(open: bool) -> void:
	_main_list.visible = not open
	_extras_list.visible = open
	_keys_label.text = KEYS_EXTRAS if open else KEYS_MAIN
	# The list changed under the marker; it moves once the new entry has a place.
	await get_tree().process_frame
	if open:
		for entry in _extras_list.get_children():
			if entry is Button and entry.visible:
				entry.grab_focus()
				break
	else:
		_extras_button.grab_focus()


func _focus_first() -> void:
	_marker.visible = true
	if _continue_button.disabled:
		_new_game_button.grab_focus()
	else:
		_continue_button.grab_focus()
	if not _offered:
		_offered = true
		_offer_the_tour()


# --- layout -------------------------------------------------------------------


## Everything placed from the screen's real size, so it fits whatever the window
## is: the title card centred, the menu column down the left, all of it kept
## clear of the land along the bottom where the party runs.
func _layout() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	_logo.size = _logo.get_combined_minimum_size()
	_logo.pivot_offset = Vector2.ZERO
	var logo_size := _logo.size
	if _revealed:
		_logo.scale = Vector2.ONE * LOGO_MENU_SCALE
		_logo.position = Vector2(MARGIN_X, MARGIN_TOP)
		var logo_bottom := MARGIN_TOP + logo_size.y * LOGO_MENU_SCALE
		_menu.position = Vector2(MARGIN_X - ENTRY_INDENT, logo_bottom + 18.0)
	else:
		# Big, but never wider than the screen with a margin either side.
		var fit := minf(1.0, (w - 80.0) / logo_size.x)
		_logo.scale = Vector2.ONE * fit
		_logo.position = Vector2((w - logo_size.x * fit) * 0.5, h * 0.40 - logo_size.y * fit * 0.5)
		_prompt.offset_top = h * 0.40 + logo_size.y * fit * 0.5 + 44.0
		_prompt.offset_bottom = _prompt.offset_top + 32.0
	_menu.size = _menu.get_combined_minimum_size()
	_shade.offset_right = minf(w * 0.6, 680.0)
	_embers.position = Vector2(w * 0.5, h + 28.0)
	_embers.emission_rect_extents = Vector2(w * 0.55, 24.0)
	var focused := get_viewport().gui_get_focus_owner() as Button
	if focused != null and _hints.has(focused):
		_place_marker(focused, false)


# --- entries ------------------------------------------------------------------


## A menu entry is a carved word, not a panel: no frame, a warm colour, and a
## step to the right with a marker beside it when it is the one chosen.
func _dress_entry(button: Button) -> void:
	button.theme_type_variation = &""
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE if button.disabled else Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if carved_font != null:
		button.add_theme_font_override("font", carved_font)
	button.add_theme_font_size_override("font_size", ENTRY_FONT_SIZE)
	button.add_theme_color_override("font_color", COLOR_ENTRY)
	button.add_theme_color_override("font_hover_color", COLOR_FOCUS)
	button.add_theme_color_override("font_focus_color", COLOR_FOCUS)
	button.add_theme_color_override("font_hover_pressed_color", COLOR_FOCUS)
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 0.8))
	button.add_theme_color_override("font_disabled_color", COLOR_DISABLED)
	button.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.03))
	button.add_theme_constant_override("outline_size", 6)
	_indent(button, ENTRY_INDENT)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", _plain(ENTRY_INDENT))


func _indent(button: Button, left: float) -> void:
	var box := _plain(left)
	for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, box)


func _plain(left: float) -> StyleBoxEmpty:
	var box := StyleBoxEmpty.new()
	box.content_margin_left = left
	box.content_margin_right = 12.0
	box.content_margin_top = 6.0
	box.content_margin_bottom = 6.0
	return box


## Up from the top entry goes to the bottom one, and down from the bottom to the top.
func _wrap_focus(list: VBoxContainer) -> void:
	var entries: Array[Button] = []
	for child in list.get_children():
		if child is Button and child.visible and not child.disabled:
			entries.append(child)
	if entries.size() < 2:
		return
	entries[0].focus_neighbor_top = entries[-1].get_path()
	entries[-1].focus_neighbor_bottom = entries[0].get_path()


func _on_button_hovered(button: Button) -> void:
	if not button.disabled and _revealed:
		button.grab_focus()


func _on_button_focused(button: Button) -> void:
	_indent(button, ENTRY_FOCUS_INDENT)
	_hint_label.text = String(_hints.get(button, ""))
	_place_marker(button, _marker.visible)
	_marker.visible = _revealed


func _on_list_sorted() -> void:
	var focused := get_viewport().gui_get_focus_owner() as Button
	if focused == null or not _hints.has(focused):
		return
	_place_marker(focused, _marker_tween != null and _marker_tween.is_running())


func _on_button_unfocused(button: Button) -> void:
	_indent(button, ENTRY_INDENT)


## The marker: a small lit diamond beside the chosen word, sliding between them.
func _place_marker(button: Button, animate: bool) -> void:
	var target := Vector2(
		button.global_position.x - global_position.x + 14.0,
		button.global_position.y - global_position.y + button.size.y * 0.5
	)
	if _marker_tween != null:
		_marker_tween.kill()
	if not animate:
		_marker.position = target
		return
	_marker_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_marker_tween.tween_property(_marker, "position", target, 0.14)


func _draw_marker() -> void:
	var r := 6.0
	var glow := COLOR_MARK
	glow.a = 0.18
	_marker.draw_circle(Vector2.ZERO, r * 2.4, glow)
	_marker.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -r), Vector2(r, 0.0), Vector2(0.0, r), Vector2(-r, 0.0),
	]), COLOR_MARK)
	_marker.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -r * 0.45), Vector2(r * 0.45, 0.0), Vector2(0.0, r * 0.45), Vector2(-r * 0.45, 0.0),
	]), Color(1.0, 0.95, 0.82))


# --- the save -----------------------------------------------------------------


## The crest is whoever you are playing as, read off the save. With no save it
## stays the sworn blade the scene ships with.
func _wear_your_own_face() -> void:
	var face := Database.unit_face(String(_saved_lead().get("template_id", "")))
	if face != null:
		_crest.texture = face


## The lead's entry in the save's roster, or empty with no save.
func _saved_lead() -> Dictionary:
	if not GameState.has_save():
		return {}
	var parsed: Variant = SaveFile.read(GameState.SAVE_PATH)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	for entry: Dictionary in parsed.get("roster", {}).get("characters", []):
		if bool(entry.get("is_player", false)):
			return entry
	return {}


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


## A new game plays the opening (docs/25) once the lead is picked: `opening` rides
## the quiz and the pick so the lead who falls in it is the one chosen.
## The first life is always the First Hour's lead (D106): the quiz waits for the next one.
func _on_new_game_pressed() -> void:
	var first := FirstHour.first_life()
	if first != "":
		GameState.new_game(0, first)
		EventBus.safe_point_reached.emit(RunMode.START, "you set out")
		EventBus.request_scene.emit("opening", {"lead": first})
		return
	EventBus.request_scene.emit("temper_quiz", {
		"fallen": Sixteen.fallen_tempers(), "fallen_heroes": Sixteen.fallen_heroes(), "opening": true,
	})


## The very first time the game is opened, with no run to continue, the tutorial is offered
## (D73). Asked once per player (`settings.cfg`, section "tutorial"); the button stays either way.
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
