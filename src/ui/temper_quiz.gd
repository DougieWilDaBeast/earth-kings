class_name TemperQuiz
extends Control
## Four questions, and the four answers name the life you are about to live.
##
## One question per preference pair, so the sixteen answers map exactly onto the
## sixteen tempers in `data/tempers.json`. Nothing here decides anything about
## the world — it picks a lead and hands off to [GameState], the same way the
## picker at [CharacterSelect] does.
##
## A temper whose character has not been written yet is not a failure state: the
## screen says so and offers the full roster instead.

var boot_payload: Dictionary = {}

## One letter per question answered so far, in axis order.
var _answers: PackedStringArray = []
var _asked: int = 0
var _chosen: String = ""

@onready var _step: Label = %StepLabel
@onready var _question: Label = %QuestionLabel
@onready var _options: VBoxContainer = %Options
@onready var _reveal: PanelContainer = %Reveal
@onready var _portrait: TextureRect = %Portrait
@onready var _name: Label = %NameLabel
@onready var _title: Label = %TitleLabel
@onready var _temper: Label = %TemperLabel
@onready var _warband: Label = %WarbandLabel
@onready var _history: Label = %HistoryLabel
@onready var _blurb: Label = %BlurbLabel
@onready var _stats: Label = %StatsLabel
@onready var _seed_field: LineEdit = %SeedField
@onready var _begin_button: Button = %BeginButton
@onready var _all_button: Button = %AllButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_begin_button.pressed.connect(_begin)
	_all_button.pressed.connect(func() -> void: EventBus.request_scene.emit("character_select", {}))
	_back_button.pressed.connect(func() -> void: EventBus.request_scene.emit("title", {}))
	_ask(0)


func questions() -> Array:
	return Database.tempers.get("quiz", [])


# --- the asking ---------------------------------------------------------------


func _ask(index: int) -> void:
	var quiz := questions()
	if index >= quiz.size():
		_resolve()
		return
	_asked = index
	var question: Dictionary = quiz[index]
	_step.text = "%s of %s" % [_ordinal(index + 1), _ordinal(quiz.size())]
	_question.text = str(question.get("prompt", ""))
	_clear_options()
	var first: Button = null
	for option: Dictionary in question.get("options", []):
		var button := _answer_button(option)
		_options.add_child(button)
		if first == null:
			first = button
	if first != null:
		first.grab_focus()


## Old answers go out of the tree immediately, not at the end of the frame —
## otherwise the next question's focus lands on a button that is already dying.
func _clear_options() -> void:
	for child in _options.get_children():
		_options.remove_child(child)
		child.queue_free()


func _answer_button(option: Dictionary) -> Button:
	var button := Button.new()
	button.text = str(option.get("text", ""))
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 52)
	button.pressed.connect(_answer.bind(str(option.get("key", ""))))
	return button


func _answer(key: String) -> void:
	_answers.append(key)
	_ask(_asked + 1)


static func _ordinal(n: int) -> String:
	const WORDS := ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight"]
	return WORDS[n] if n < WORDS.size() else str(n)


# --- who that makes you -------------------------------------------------------


func _resolve() -> void:
	var code := "".join(_answers)
	var temper := Database.temper(code)
	_chosen = Database.temper_hero(code)

	_clear_options()
	_question.text = str(temper.get("display_name", code))
	_step.text = str(temper.get("blurb", ""))

	if _chosen == "":
		# The grid is written before the roster is, so this is an ordinary
		# state for a while rather than a broken one.
		_reveal.visible = false
		_begin_button.visible = false
		_question.text = "Nobody answers to %s yet." % str(temper.get("display_name", code))
		_step.text = "That life has not been written. Pick from the ones that have."
		_all_button.grab_focus()
		return

	_show(_chosen, code)


func _show(hero_id: String, code: String) -> void:
	var hero := Database.hero(hero_id)
	var template := Database.unit_template(hero_id)
	_reveal.visible = true
	_begin_button.visible = true

	_portrait.texture = Database.unit_face(hero_id)
	_name.text = str(template.get("display_name", hero_id))
	_title.text = str(hero.get("title", template.get("job", "")))
	_temper.text = "%s · %s" % [str(Database.temper(code).get("display_name", code)), code]
	_warband.text = "Warband — %s" % _band_text(hero)
	_history.text = _history_text(hero)

	var blurb: String = hero.get("blurb", "")
	var origin: String = hero.get("origin", "")
	_blurb.text = "%s\n\n%s" % [blurb, origin] if origin != "" else blurb
	_stats.text = "HP %d    Attack %d    Defence %d    Move %d    Speed %d" % [
		int(template.get("max_hp", 0)),
		int(template.get("attack", 0)),
		int(template.get("defense", 0)),
		int(template.get("move", 0)),
		int(template.get("speed", 0)),
	]
	_begin_button.grab_focus()


## Their authored history, skipping whatever has not been cast on them yet.
func _history_text(hero: Dictionary) -> String:
	var parts: Array[String] = []
	for field: String in Character.TRAIT_POOLS:
		var piece := Database.lore_piece(Character.TRAIT_POOLS[field], str(hero.get(field, "")))
		if not piece.is_empty():
			parts.append(str(piece.get("display_name", "")))
	if parts.is_empty():
		return "No history written down yet."
	return " · ".join(parts)


func _band_text(hero: Dictionary) -> String:
	var names: Array[String] = []
	for companion_id: String in hero.get("companions", []):
		names.append(str(Database.unit_template(companion_id).get("display_name", companion_id)))
	if names.is_empty():
		return "you ride out alone"
	return "you and " + " and ".join(names)


# --- and off you go -----------------------------------------------------------


func _begin() -> void:
	if _chosen == "":
		return
	GameState.new_game(_chosen_seed(), _chosen)
	EventBus.request_scene.emit("world", {})


func _chosen_seed() -> int:
	var typed := _seed_field.text.strip_edges()
	if typed.is_valid_int():
		return int(typed)
	return randi()
