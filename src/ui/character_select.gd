extends Control
## Who you play as. Every life on this page is a real start: a different lead,
## a different band behind them, and a difficulty that follows from both.

## Set by [Game] before the scene enters the tree; unused here.
var boot_payload: Dictionary = {}

## How the number in `data/heroes.json` reads on screen, hardest last.
const RATINGS := ["", "Steady", "Wary", "Hard", "Punishing", "Ruinous"]
const PIPS := 5
const PIP_SIZE := Vector2(18, 18)
const PIP_LIT := Color(0.95, 0.6, 0.28)
const PIP_DARK := Color(0.24, 0.22, 0.22)

@onready var _lives: VBoxContainer = %Lives
@onready var _portrait: TextureRect = %Portrait
@onready var _name: Label = %NameLabel
@onready var _title: Label = %TitleLabel
@onready var _pips: HBoxContainer = %Pips
@onready var _rating: Label = %RatingLabel
@onready var _warband: Label = %WarbandLabel
@onready var _stats: Label = %StatsLabel
@onready var _blurb: Label = %BlurbLabel
@onready var _back: Button = %BackButton
@onready var _difficulty: Button = %DifficultyButton
@onready var _seed: LineEdit = %SeedField


func _ready() -> void:
	for i in PIPS:
		var pip := ColorRect.new()
		pip.custom_minimum_size = PIP_SIZE
		_pips.add_child(pip)

	var ids: Array = Database.heroes.keys()
	# Gentlest first, so the list itself reads as the warning.
	ids.sort_custom(func(a: String, b: String) -> bool:
		var left := int(Database.hero(a).get("difficulty", 1))
		var right := int(Database.hero(b).get("difficulty", 1))
		return left < right if left != right else a < b
	)
	for hero_id: String in ids:
		_lives.add_child(_life_button(hero_id))
	_back.theme_type_variation = &"GrandButton"
	_back.pressed.connect(func() -> void: EventBus.request_scene.emit("title", {}))
	_difficulty.theme_type_variation = &"GrandButton"
	_difficulty.pressed.connect(_cycle_difficulty)
	Sfx.attend(_back)
	Sfx.attend(_difficulty)
	_seed.tooltip_text = "Leave it empty for a country nobody has walked yet."
	_show_difficulty()
	if ids.is_empty():
		return
	_show(ids[0])
	_lives.get_child(0).grab_focus()


func _life_button(hero_id: String) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"GrandButton"
	var rating := clampi(int(Database.hero(hero_id).get("difficulty", 1)), 1, PIPS)
	button.text = "%s  ·  %s" % [_name_of(hero_id), RATINGS[rating]]
	button.focus_entered.connect(_show.bind(hero_id))
	# Keeps the mouse and the keyboard pointing at the same entry.
	button.mouse_entered.connect(button.grab_focus)
	button.pressed.connect(_begin.bind(hero_id))
	Sfx.attend(button)
	return button


func _show(hero_id: String) -> void:
	var hero := Database.hero(hero_id)
	var template := Database.unit_template(hero_id)
	_name.text = _name_of(hero_id)
	_title.text = hero.get("title", template.get("job", ""))
	_portrait.texture = Database.unit_face(hero_id)
	_blurb.text = hero.get("blurb", "")

	var rating := clampi(int(hero.get("difficulty", 1)), 1, PIPS)
	for i in PIPS:
		_pips.get_child(i).color = PIP_LIT if i < rating else PIP_DARK
	_rating.text = RATINGS[rating]

	_warband.text = "Warband — %s" % _band_text(hero)
	_stats.text = "HP %d    Attack %d    Defence %d    Move %d    Speed %d" % [
		int(template.get("max_hp", 0)),
		int(template.get("attack", 0)),
		int(template.get("defense", 0)),
		int(template.get("move", 0)),
		int(template.get("speed", 0)),
	]


func _band_text(hero: Dictionary) -> String:
	var names: Array[String] = []
	for companion_id: String in hero.get("companions", []):
		names.append(_name_of(companion_id))
	if names.is_empty():
		return "you ride out alone"
	return "you and " + " and ".join(names)


func _name_of(unit_id: String) -> String:
	return Database.unit_template(unit_id).get("display_name", unit_id)


## How hard the country is, separate from which life you take into it.
func _cycle_difficulty() -> void:
	var settings: Array = Difficulty.settings().keys()
	if settings.is_empty():
		return
	var at := settings.find(GameState.difficulty)
	GameState.difficulty = settings[(at + 1) % settings.size()]
	_show_difficulty()


func _show_difficulty() -> void:
	_difficulty.text = "Difficulty: %s" % Difficulty.display_name()
	_difficulty.tooltip_text = Difficulty.blurb()


func _begin(hero_id: String) -> void:
	GameState.new_game(_chosen_seed(), hero_id)
	EventBus.request_scene.emit("world", {})


## A country you can go back to. Anything that is not a number is nothing, and
## nothing means a fresh one — which is what almost everybody wants.
func _chosen_seed() -> int:
	var typed := _seed.text.strip_edges()
	if typed.is_valid_int():
		# new_game() reads zero as "pick one", so a typed zero has to become
		# something else rather than silently doing what it was not asked to.
		return maxi(1, absi(typed.to_int()))
	return randi()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		EventBus.request_scene.emit("title", {})
