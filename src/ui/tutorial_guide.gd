extends CanvasLayer
## The tutorial (D73): a card in the corner that walks a new player through the game in the
## training village, one step at a time, and ticks each off as they do it.
##
## Asked for with [signal EventBus.tutorial_requested]. It starts a run that is never saved
## ([member GameState.rehearsing]), opens the village, and listens: to
## [signal EventBus.player_did] for what the player does, to the party screen and the journal
## opening, and to the flags conversations set. The steps are `data/tutorial.json`. Leaving the
## village (or the fights started from it) for anywhere else ends it.
##
## Lives under the game's root, so it outlasts the scenes it guides through. Loaded by path ([D41]).

const DATA_PATH := "res://data/tutorial.json"
const SaveFile := preload("res://src/chronicle/save_file.gd")
const Sixteen := preload("res://src/chronicle/sixteen.gd")
## How long a step stays on the card, ticked, before the next comes up.
const DONE_PAUSE := 1.2
## Scenes the tutorial goes on through. Anywhere else, it is over.
const ITS_SCENES := ["area", "skirmish", "battle"]
const WIDTH := 430.0
## The gap beside a fight's field is narrower than a town's corner.
const FIGHT_WIDTH := 290.0

var _steps: Array = []
var _rules: Dictionary = {}
var _index: int = -1
var _active: bool = false
var _done: bool = false

var _panel: PanelContainer
var _count: Label
var _title: Label
var _body: Label
var _main_button: Button
var _skip_button: Button
var _end_button: Button
var _back_button: Button


func _ready() -> void:
	layer = 40
	_load()
	_build()
	_panel.visible = false
	EventBus.tutorial_requested.connect(start)
	EventBus.player_did.connect(_on_player_did)
	EventBus.party_screen_requested.connect(func() -> void: _on_opened("party"))
	EventBus.journal_requested.connect(func() -> void: _on_opened("journal"))
	EventBus.scene_changed.connect(_on_scene_changed)


func is_running() -> bool:
	return _active


## The step the player is on, by id, or "" when the tutorial is not running.
func step_id() -> String:
	return str(_steps[_index].get("id", "")) if _active and _index >= 0 and _index < _steps.size() else ""


## A practice run that is never saved, the training village, and the first step.
func start() -> void:
	if _steps.is_empty():
		push_error("Tutorial: %s has no steps" % DATA_PATH)
		return
	GameState.new_game(int(_rules.get("seed", 0)), str(_rules.get("lead", "")), true)
	_active = true
	_dock("area")
	_show(0)
	EventBus.request_scene.emit("area", {
		"area_id": str(_rules.get("area", "tutorial")),
		"return_scene": "title",
	})


## Stop guiding. [param to_title] goes back to the title screen as well.
func stop(to_title: bool = false) -> void:
	_active = false
	_panel.visible = false
	if to_title:
		EventBus.request_scene.emit("title", {})


func _load() -> void:
	var parsed: Variant = SaveFile.read(DATA_PATH)
	_rules = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	_steps = _rules.get("steps", [])


func _process(_delta: float) -> void:
	if not _active or _done:
		return
	var flag := str(_done_rule().get("flag", ""))
	if flag != "" and GameState.has_flag(flag):
		_complete()


func _done_rule() -> Dictionary:
	if _index < 0 or _index >= _steps.size():
		return {}
	return _steps[_index].get("done", {})


func _on_player_did(what: String) -> void:
	if not _active or _done:
		return
	var wanted := str(_done_rule().get("did", ""))
	if wanted == "":
		return
	if what == wanted or (wanted.ends_with(":") or wanted.ends_with("_")) and what.begins_with(wanted):
		_complete()


func _on_opened(screen: String) -> void:
	if _active and not _done and str(_done_rule().get("opened", "")) == screen:
		_complete()


## Anywhere the tutorial does not go means it is over: the title, a run of the player's own, the
## save loaded from the menu.
func _on_scene_changed(scene_key: String) -> void:
	if _active and not ITS_SCENES.has(scene_key):
		stop()
		return
	_dock(scene_key)


## Top right in a town, under its buttons; on the left in a fight, clear of the field and its orders.
## In a town it sits in the top corner, above where the conversation box opens; in a fight it is
## narrower, in the gap left of the field.
func _dock(scene_key: String) -> void:
	var in_a_fight := scene_key == "skirmish" or scene_key == "battle"
	var width := FIGHT_WIDTH if in_a_fight else WIDTH
	_panel.anchor_left = 0.0 if in_a_fight else 1.0
	_panel.anchor_right = 0.0 if in_a_fight else 1.0
	_panel.offset_left = 12.0 if in_a_fight else -width - 16.0
	_panel.offset_right = width + 12.0 if in_a_fight else -16.0
	# The touch overlay keeps a bar of buttons along the top.
	_panel.offset_top = 70.0 if in_a_fight else (84.0 if Pace.is_touch_enabled() else 16.0)
	_panel.offset_bottom = _panel.offset_top
	_body.custom_minimum_size = Vector2(width - 28.0, 0)
	_fit.call_deferred()


func _complete() -> void:
	_done = true
	_count.text = "%s  ·  done" % _count.text.split("  ·  ")[0]
	_count.add_theme_color_override("font_color", Color("#9fd27a"))
	await get_tree().create_timer(DONE_PAUSE, true, false, true).timeout
	if _active:
		_show(_index + 1)


func _show(index: int) -> void:
	if index >= _steps.size():
		stop(true)
		return
	_index = index
	_done = false
	var step: Dictionary = _steps[index]
	_count.text = "TUTORIAL  %d of %d" % [index + 1, _steps.size()]
	_count.remove_theme_color_override("font_color")
	_title.text = str(step.get("title", ""))
	_body.text = str(step.get("text", ""))
	var button := str(step.get("done", {}).get("button", ""))
	_main_button.visible = button != ""
	_main_button.text = button
	_skip_button.visible = button == ""
	_back_button.visible = bool(step.get("finish", false))
	_end_button.visible = not bool(step.get("finish", false))
	_panel.visible = true
	_fit.call_deferred()


## Wrapped words are measured narrow first, which leaves the card too tall; once they are laid out
## at the card's width it is shrunk back to them.
func _fit() -> void:
	_panel.offset_bottom = _panel.offset_top
	_panel.reset_size()


func _on_main_pressed() -> void:
	if bool(_steps[_index].get("finish", false)):
		# Into a run of their own: the four questions that pick a hero.
		_active = false
		_panel.visible = false
		EventBus.request_scene.emit("temper_quiz", {
			"fallen": Sixteen.fallen_tempers(), "fallen_heroes": Sixteen.fallen_heroes(),
		})
		return
	_complete()


func _on_skip_pressed() -> void:
	if not _done:
		_complete()


func _build() -> void:
	_panel = PanelContainer.new()
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color(0.07, 0.06, 0.09, 0.92)
	backing.border_color = Color("#c9a45f")
	backing.set_border_width_all(2)
	backing.set_corner_radius_all(6)
	_panel.add_theme_stylebox_override("panel", backing)
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.offset_left = -WIDTH - 16.0
	_panel.offset_right = -16.0
	_panel.offset_top = 16.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	_count = Label.new()
	_count.add_theme_font_size_override("font_size", 13)
	_count.modulate = Color(1, 1, 1, 0.7)
	box.add_child(_count)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", Color("#e8c46a"))
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title)
	_body = Label.new()
	_body.add_theme_font_size_override("font_size", 16)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(WIDTH - 28.0, 0)
	box.add_child(_body)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	_main_button = _button(row, "Next", _on_main_pressed)
	_skip_button = _button(row, "Skip this step", _on_skip_pressed)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_back_button = _button(row, "Back to the title", func() -> void: stop(true))
	_end_button = _button(row, "End tutorial", func() -> void: stop(true))


## A button the keyboard never lands on, so walking and talking keep their keys.
func _button(row: HBoxContainer, text: String, pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(pressed)
	Sfx.attend(button)
	row.add_child(button)
	return button
