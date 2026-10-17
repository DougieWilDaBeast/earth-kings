extends CanvasLayer
## Atlas's last stand ([D191], once D73's tour): a new player's first game. A card in the corner
## walks them through the last day of Atlas's world in Hearthwick, one step at a time, ticking
## each off as they do it, and ends in a fight he cannot win.
##
## Asked for with [signal EventBus.tutorial_requested] (New Game, for a player who has never
## finished it). It starts a run that is never saved ([member GameState.rehearsing]), opens the
## village, and listens: to [signal EventBus.player_did] for what the player does, to the party
## screen and the journal opening, and to the flags conversations set. The steps are
## `data/tutorial.json`. When the `doom` step's fight ends, Atlas falls for good: he is written into
## the record of the fallen as the first world that ended ([Sixteen], [Siblings]), his fall is told,
## and the quiz picks who comes next, with the opening after it showing his world going dark.
## Leaving the village (or its fights) for anywhere else ends it, unfinished, and it starts again
## on the next New Game.
##
## Lives under the game's root, so it outlasts the scenes it guides through. Loaded by path ([D41]).

const DATA_PATH := "res://data/tutorial.json"
const SaveFile := preload("res://src/chronicle/save_file.gd")
const Sixteen := preload("res://src/chronicle/sixteen.gd")
const Siblings := preload("res://src/chronicle/siblings.gd")
## Where the player's own settings live; finishing the last stand is remembered there. Tests
## point it somewhere else so a player's own settings are never touched.
static var settings_path := "user://settings.cfg"
## Seconds the lost fight stays on screen before the fall is told over it.
const FALL_PAUSE := 1.6
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
## Whether this last stand counts: Atlas is not yet among the fallen. Played again once he is,
## it is only a replay, and nothing is written down.
var _counts: bool = false
var _fall_layer: CanvasLayer

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
	# A fight here is put down on the village's own ground (D98), not a scene of its own: the card
	# moves aside for it, and back when it is over.
	EventBus.battle_started.connect(func(_map_id: String) -> void:
		if _active:
			_dock("skirmish")
	)


func is_running() -> bool:
	return _active


## The step the player is on, by id, or "" when the tutorial is not running.
func step_id() -> String:
	return str(_steps[_index].get("id", "")) if _active and _index >= 0 and _index < _steps.size() else ""


## Whether this player has played the last stand through to Atlas's fall ([D191]).
static func finished_once() -> bool:
	var config := ConfigFile.new()
	config.load(settings_path)
	return bool(config.get_value("tutorial", "finished", false))


static func _mark_finished() -> void:
	var config := ConfigFile.new()
	config.load(settings_path)
	config.set_value("tutorial", "finished", true)
	config.save(settings_path)


## The lead of the last stand: Atlas (`data/tutorial.json` → `lead`).
static func lead_id() -> String:
	var parsed: Variant = SaveFile.read(DATA_PATH)
	return str((parsed if typeof(parsed) == TYPE_DICTIONARY else {}).get("lead", "atlas"))


## Skip the last stand (offered once it has been played through): Atlas still falls, off
## screen, so the run begins as it would have, with the next of the sixteen ([D191]).
static func skip_it() -> void:
	var lead := lead_id()
	if lead == "" or Sixteen.fallen_heroes().has(lead):
		return
	var parsed: Variant = SaveFile.read(DATA_PATH)
	var rules: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	Sixteen.fall(lead, _seed_the_next({
		"hero": lead, "name": str(Database.unit_template(lead).get("display_name", lead.capitalize())),
		"temper": Database.hero_temper(lead),
		"level": 1, "floor": 0, "steps": 0,
		"killer": str(rules.get("fall", {}).get("killer", "")), "remembered": false,
		"weapon": Siblings.signature_of(lead), "last_stand": true,
	}))


## The worlds after the first that ended are built from its seed ([Siblings]). Atlas's last stand
## is the same village for everyone, so the worlds after it are built from a seed of this player's
## own, and no two players walk the same land.
static func _seed_the_next(world: Dictionary) -> Dictionary:
	var fresh := randi()
	world["seed"] = fresh
	world["base_seed"] = fresh
	world["sibling"] = 0
	return world


## A run that is never saved, the village, and the first step.
func start() -> void:
	if _steps.is_empty():
		push_error("Tutorial: %s has no steps" % DATA_PATH)
		return
	_counts = not Sixteen.fallen_heroes().has(str(_rules.get("lead", "")))
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
	if _active and what.begins_with("fight_"):
		_dock("area")
	if not _active or _done:
		return
	# The last fight, won or lost: Atlas's world ends with him.
	if _index >= 0 and _index < _steps.size() and bool(_steps[_index].get("doom", false)) \
			and what.begins_with("fight_"):
		_the_fall()
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
	# While the fall is told, the lost fight going back to the village is under it. Anywhere
	# else (the quiz, or the title from the menu) and the telling is over.
	if _fall_layer != null:
		if scene_key != "temper_quiz" and scene_key != "title":
			return
		_fall_layer.queue_free()
		_fall_layer = null
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
	# What a step sets in motion when it comes up: the practice band coming out for the fight.
	for key: Variant in step.get("on_start", {}).get("set_flag", []):
		GameState.set_flag(str(key))
	_count.text = "ATLAS'S LAST STAND  %d of %d" % [index + 1, _steps.size()]
	_count.remove_theme_color_override("font_color")
	_title.text = str(step.get("title", ""))
	_body.text = str(step.get("text", ""))
	var button := str(step.get("done", {}).get("button", ""))
	_main_button.visible = button != ""
	_main_button.text = button
	# The last fight is not one to skip.
	_skip_button.visible = button == "" and not bool(step.get("doom", false))
	_back_button.visible = bool(step.get("finish", false))
	# A new player's last stand is played through; a replay can be left.
	_end_button.visible = not bool(step.get("finish", false)) and not _counts
	_panel.visible = true
	_fit.call_deferred()


## Wrapped words are measured narrow first, which leaves the card too tall; once they are laid out
## at the card's width it is shrunk back to them.
func _fit() -> void:
	_panel.offset_bottom = _panel.offset_top
	_panel.reset_size()


## Atlas falls for good. Written down as the first world that ended (unless he already has, when
## this was a replay), his fall told over the lost fight, and then who comes next.
func _the_fall() -> void:
	_done = true
	_panel.visible = false
	await get_tree().create_timer(FALL_PAUSE, true, false, true).timeout
	var lead := str(_rules.get("lead", ""))
	var fall: Dictionary = _rules.get("fall", {})
	if _counts and GameState.world != null and GameState.roster != null:
		var world := Siblings.remember(GameState.world, GameState.roster, GameState.ledger)
		if world.is_empty():
			world = {"hero": lead}
		world["last_stand"] = true
		world["killer"] = str(fall.get("killer", ""))
		world["floor"] = 0
		_seed_the_next(world)
		Sixteen.fall(lead, world)
	_mark_finished()
	_tell_the_fall(fall)


func _tell_the_fall(fall: Dictionary) -> void:
	_fall_layer = CanvasLayer.new()
	_fall_layer.layer = 95
	add_child(_fall_layer)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.0)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fall_layer.add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.custom_minimum_size = Vector2(720, 0)
	box.add_theme_constant_override("separation", 18)
	shade.add_child(box)
	var shown: Array[Control] = []
	for line: Variant in fall.get("lines", []):
		var said := Label.new()
		said.text = str(line)
		said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		said.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		said.add_theme_font_size_override("font_size", 20)
		said.modulate.a = 0.0
		box.add_child(said)
		shown.append(said)
	var next := Button.new()
	next.text = str(fall.get("button", "Choose who comes next")) if _counts else "Back to the title"
	next.theme_type_variation = &"GrandButton"
	next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next.modulate.a = 0.0
	box.add_child(next)
	Sfx.attend(next)
	next.pressed.connect(_after_the_fall)
	var tween := create_tween().set_ignore_time_scale(true)
	tween.tween_property(shade, "color:a", 1.0, 1.2)
	for said in shown:
		tween.tween_property(said, "modulate:a", 1.0, 0.9)
		tween.tween_interval(0.5)
	tween.tween_property(next, "modulate:a", 1.0, 0.4)
	tween.tween_callback(next.grab_focus)


## Into the quiz, which picks the next of the sixteen; the opening plays once they are picked,
## with Atlas's world seen ending. A replay goes back to the title.
func _after_the_fall() -> void:
	_active = false
	_panel.visible = false
	if _fall_layer != null:
		_fall_layer.queue_free()
		_fall_layer = null
	if not _counts:
		EventBus.request_scene.emit("title", {})
		return
	EventBus.request_scene.emit("temper_quiz", {
		"fallen": Sixteen.fallen_tempers(), "fallen_heroes": Sixteen.fallen_heroes(), "opening": true,
	})


## Whether Atlas's fall is being told: the last fight is over and the game waits on the button.
func is_telling_the_fall() -> bool:
	return _fall_layer != null


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
