class_name TemperQuiz
extends Control
## The questions, and the answers name the life you are about to live.
##
## Asked one preference pair at a time (E/I, then S/N, T/F, J/P), several
## questions to a pair, and each pair is decided by majority: with three to a
## pair, best of three. Once one letter has the majority the pair's last
## question is skipped. The four letters decided map onto the sixteen tempers
## in `data/tempers.json`. Nothing here decides anything about
## the world — it picks a lead and hands off to [GameState], the same way the
## picker at [CharacterSelect] does.
##
## A temper whose character has not been written yet is not a failure state: the
## screen says so and offers the full roster instead.
##
## The quiz is the front door (D44). The full roster is a side door that only
## opens once the questions are answered, next to answering them again.
##
## A lead who has died cannot be answered into again (D43). Pass their temper
## codes as `boot_payload.fallen`: an answer is left out once every temper it
## could still lead to has fallen. When a pair has only one letter left, one
## question is asked with that answer alone, so the player sees the other is
## gone, and the rest of that pair's questions are skipped.

const RunMode := preload("res://src/chronicle/run_mode.gd")

## The widest the question and its answers get, so a long line stays readable.
const COLUMN := 900.0
const COLOR_TEXT := Color(0.86, 0.82, 0.74)
const COLOR_FOCUS := Color(1.0, 0.88, 0.6)
const COLOR_MARK := Color(0.95, 0.72, 0.38)
const COLOR_DIM := Color(0.42, 0.38, 0.34)

## Set from the scene: the carved lettering the start screen uses.
@export var carved_font: Font

var boot_payload: Dictionary = {}

## Temper codes of leads who have died. Their answers are closed.
var _fallen: PackedStringArray = []
## Heroes who died as leads, handed on to the roster so it offers only the living.
var _fallen_heroes: Array = []

const AXES := ["EI", "SN", "TF", "JP"]

## One letter per preference pair decided so far, in axis order.
var _answers: PackedStringArray = []
var _chosen: String = ""
## The pair being asked now, how many of its questions have been asked, and
## the answers given to them so far, letter by letter.
var _axis_at: int = 0
var _asked_in_axis: int = 0
var _votes: Dictionary = {}
## Letters still open on the pair being asked (after D43 has closed the dead).
var _open: PackedStringArray = []
## Questions answered so far, across every pair, for the step line.
var _answered: int = 0

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
@onready var _again_button: Button = %AgainButton
@onready var _all_button: Button = %AllButton
@onready var _back_button: Button = %BackButton
@onready var _progress: Control = %Progress
@onready var _stage: Control = %Stage
@onready var _margin: MarginContainer = %Margin


func _ready() -> void:
	for code in boot_payload.get("fallen", []):
		_fallen.append(str(code))
	_fallen_heroes = boot_payload.get("fallen_heroes", [])
	_begin_button.pressed.connect(_begin)
	_again_button.pressed.connect(_start_over)
	_all_button.pressed.connect(
		func() -> void: EventBus.request_scene.emit("character_select", {"fallen_heroes": _fallen_heroes})
	)
	_back_button.pressed.connect(func() -> void: EventBus.request_scene.emit("title", {}))
	_dress()
	resized.connect(_layout)
	_layout()
	_ask_next()


func questions() -> Array:
	return Database.tempers.get("quiz", [])


## The questions about one preference pair, in the order they are written.
func questions_on(axis: String) -> Array:
	var out: Array = []
	for question: Dictionary in questions():
		if str(question.get("axis", "")) == axis:
			out.append(question)
	return out


# --- the asking ---------------------------------------------------------------


func _ask_next() -> void:
	if _axis_at >= AXES.size():
		_resolve()
		return
	var axis: String = AXES[_axis_at]
	var on_axis := questions_on(axis)
	var prefix := "".join(_answers)
	_open = PackedStringArray()
	for letter in axis:
		if leads_to_the_living(prefix + letter):
			_open.append(letter)
	if _open.is_empty() or on_axis.is_empty():
		# Every answer is closed: all sixteen have fallen.
		_clear_options()
		_question.text = "Nobody is left to answer for."
		_step.text = "All sixteen have fallen."
		_all_button.visible = true
		_progress.queue_redraw()
		_back_button.grab_focus()
		return

	var question: Dictionary = on_axis[mini(_asked_in_axis, on_axis.size() - 1)]
	_step.text = "Question %d" % (_answered + 1)
	_question.text = str(question.get("prompt", ""))
	_clear_options()
	var first: Button = null
	var number := 0
	for option: Dictionary in question.get("options", []):
		if not _open.has(str(option.get("key", ""))):
			continue
		number += 1
		var button := _answer_button(option, number)
		_options.add_child(button)
		if first == null:
			first = button
	_progress.queue_redraw()
	_fade_up()
	if first != null:
		first.grab_focus()


## Whether any temper still living begins with these answers. Codes are written
## in axis order, so the answers so far are a prefix of every code they allow.
func leads_to_the_living(prefix: String) -> bool:
	for code: String in Database.tempers.get("types", {}):
		if code.begins_with(prefix) and not _fallen.has(code):
			return true
	return false


## Old answers go out of the tree immediately, not at the end of the frame —
## otherwise the next question's focus lands on a button that is already dying.
func _clear_options() -> void:
	for child in _options.get_children():
		_options.remove_child(child)
		child.queue_free()


func _answer_button(option: Dictionary, number: int) -> Button:
	var button := Button.new()
	button.text = "%d    %s" % [number, str(option.get("text", ""))]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 64)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_FOCUS)
	button.add_theme_color_override("font_focus_color", COLOR_FOCUS)
	button.add_theme_color_override("font_pressed_color", COLOR_FOCUS)
	button.add_theme_color_override("font_hover_pressed_color", COLOR_FOCUS)
	button.add_theme_constant_override("outline_size", 4)
	button.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.02))
	var plain := _card(Color(0.05, 0.045, 0.06, 0.82), Color(0.45, 0.36, 0.24, 0.55), 1)
	var lit := _card(Color(0.09, 0.075, 0.07, 0.9), COLOR_MARK, 2)
	button.add_theme_stylebox_override("normal", plain)
	button.add_theme_stylebox_override("hover", lit)
	button.add_theme_stylebox_override("pressed", lit)
	button.add_theme_stylebox_override("hover_pressed", lit)
	button.add_theme_stylebox_override("focus", _card(Color(0, 0, 0, 0), COLOR_MARK, 2))
	button.mouse_entered.connect(button.grab_focus)
	Sfx.attend(button)
	button.pressed.connect(_answer.bind(str(option.get("key", ""))))
	return button


func _card(fill: Color, edge: Color, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(width)
	box.set_corner_radius_all(6)
	box.content_margin_left = 24.0
	box.content_margin_right = 24.0
	box.content_margin_top = 16.0
	box.content_margin_bottom = 16.0
	return box


func _answer(key: String) -> void:
	_answered += 1
	_asked_in_axis += 1
	_votes[key] = int(_votes.get(key, 0)) + 1
	var count := questions_on(AXES[_axis_at]).size()
	var decided := ""
	if _open.size() == 1:
		decided = key
	elif int(_votes[key]) * 2 > count:
		decided = key
	elif _asked_in_axis >= count:
		# An even count can end level; the last answer breaks the tie.
		decided = key
	if decided != "":
		_answers.append(decided)
		_axis_at += 1
		_asked_in_axis = 0
		_votes.clear()
	_ask_next()


## 1 and 2 pick the answers, for anyone who would rather not aim.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var index := -1
	match (event as InputEventKey).keycode:
		KEY_1, KEY_KP_1:
			index = 0
		KEY_2, KEY_KP_2:
			index = 1
	if index < 0 or index >= _options.get_child_count():
		return
	get_viewport().set_input_as_handled()
	(_options.get_child(index) as Button).pressed.emit()


# --- the look ------------------------------------------------------------------


func _dress() -> void:
	_progress.draw.connect(_draw_progress)
	for button: Button in [_begin_button, _again_button, _all_button]:
		button.theme_type_variation = &"GrandButton"
		Sfx.attend(button)
	Sfx.attend(_back_button)
	# A setting, not the point of the screen: as quiet as Back.
	(%ModeButton as Button).theme_type_variation = &""


## The column stays centred and no wider than [constant COLUMN], whatever the window.
func _layout() -> void:
	var side := maxf(40.0, (size.x - COLUMN) * 0.5)
	_margin.add_theme_constant_override("margin_left", int(side))
	_margin.add_theme_constant_override("margin_right", int(side))


func _fade_up() -> void:
	_stage.modulate.a = 0.0
	create_tween().tween_property(_stage, "modulate:a", 1.0, 0.35)


## Four marks, one per preference pair: lit once decided, ringed while asked.
func _draw_progress() -> void:
	var gap := 44.0
	var r := 7.0
	var mid := _progress.size * 0.5
	for i in AXES.size():
		var at := Vector2(mid.x + (float(i) - 1.5) * gap, mid.y)
		var diamond := PackedVector2Array([
			at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r), at + Vector2(-r, 0),
		])
		if i < _answers.size():
			var glow := COLOR_MARK
			glow.a = 0.2
			_progress.draw_circle(at, r * 2.2, glow)
			_progress.draw_colored_polygon(diamond, COLOR_MARK)
		else:
			var ring := diamond.duplicate()
			ring.append(diamond[0])
			_progress.draw_polyline(ring, COLOR_FOCUS if i == _axis_at else COLOR_DIM, 1.5, true)
		if i < AXES.size() - 1:
			_progress.draw_line(at + Vector2(r + 6, 0), at + Vector2(gap - r - 6, 0), COLOR_DIM, 1.0)


# --- who that makes you -------------------------------------------------------


func _resolve() -> void:
	var code := "".join(_answers)
	var temper := Database.temper(code)
	_chosen = Database.temper_hero(code)
	if _fallen_heroes.has(_chosen):
		_chosen = ""

	_clear_options()
	_progress.queue_redraw()
	_fade_up()
	_question.text = str(temper.get("display_name", code))
	_step.text = str(temper.get("blurb", ""))
	# Only now, with the quiz answered, do the side doors open.
	_again_button.visible = true
	_all_button.visible = true

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


## Back to the first question, to be answered for someone else.
func _start_over() -> void:
	_answers.clear()
	_chosen = ""
	_axis_at = 0
	_asked_in_axis = 0
	_votes.clear()
	_answered = 0
	_reveal.visible = false
	_begin_button.visible = false
	_again_button.visible = false
	_all_button.visible = false
	_ask_next()


# --- and off you go -----------------------------------------------------------


func _begin() -> void:
	if _chosen == "":
		return
	GameState.new_game(_chosen_seed(), _chosen)
	# Saved at once, so a Classic lead who falls before the first rest still
	# has somewhere to go back to.
	EventBus.safe_point_reached.emit(RunMode.START, "you set out")
	EventBus.request_scene.emit("world", {})


func _chosen_seed() -> int:
	var typed := _seed_field.text.strip_edges()
	if typed.is_valid_int():
		return int(typed)
	# Nothing asked for: the game picks, and after a death that is a sibling
	# of the world that ended (M15).
	return 0
