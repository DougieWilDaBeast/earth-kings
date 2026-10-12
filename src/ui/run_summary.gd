extends Control
## What the run amounted to, shown once the lead is gone — and, in Classic, the
## moment before it, when the fall can still be taken back ([D51]).
##
## Classic stops on the fall first: the lead's name, what took them, and two
## choices. **Reload** goes back to the last save and writes nothing down.
## **Ascend** accepts it, and only then is the run filed in the hall and the
## lead in the record of the fallen ([D47]). Iron Man has no such moment: the
## record is written on the fall and the save goes with the lead.
##
## Either way the world is over once the lead has gone: the save is let go
## with them, and the way on is choosing the next lead. Whether the save should
## outlive an ascent in Classic is a build choice, **Inferred** (agenda item 40).
## "Ascend" is the label the founders used; what ascending means for the lead's
## standing quest is agenda item 22, and nothing here answers it.
##
## Nothing is counted here — the numbers are read off [Ledger] and the [World]
## that outlived them.

const Sixteen := preload("res://src/chronicle/sixteen.gd")
const RunMode := preload("res://src/chronicle/run_mode.gd")

const FALL_RED := Color(0.906, 0.447, 0.322)
const SOFT := Color(0.686, 0.663, 0.616)

## Set by [Game] before the scene enters the tree. `ending` is one of the
## [Museum] endings; without one it is read off the world.
var boot_payload: Dictionary = {}

var _ending: String = ""
var _lead: Character = null
## The Classic moment, while it is up.
var _beat: Control = null

@onready var _content: Control = $Content
@onready var _epitaph: Label = %EpitaphLabel
@onready var _chapters: GridContainer = %Chapters
@onready var _fallen: Label = %FallenLabel
@onready var _next_button: Button = %NextButton
@onready var _title_button: Button = %TitleButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	var world: World = GameState.world
	var roster: Roster = GameState.roster
	_ending = str(boot_payload.get("ending", Museum.CONQUERED if (world != null and world.tower_topped) else Museum.FELL))
	_lead = roster.player() if roster != null else null

	_next_button.visible = _ending == Museum.FELL
	_next_button.text = "Ascend" if _lead_is_dead() and RunMode.is_iron_man() else "Choose the next lead"
	_next_button.pressed.connect(_choose_the_next_lead)
	_title_button.pressed.connect(func() -> void: EventBus.request_scene.emit("title", {}))
	_quit_button.pressed.connect(func() -> void: get_tree().quit())
	for button in [_next_button, _title_button, _quit_button]:
		button.theme_type_variation = &"GrandButton"
		Sfx.attend(button)

	if can_take_it_back():
		_content.hide()
		_hold_the_moment()
		return
	_settle()
	_reveal()


## Classic, a lead who fell, and a save of this run to go back to.
func can_take_it_back() -> bool:
	return _ending == Museum.FELL and GameState.tallying and RunMode.offers_reload() \
		and GameState.save_is_this_run()


## Write the run down. Called once: on arriving in Iron Man, on ascending in
## Classic.
func _settle() -> void:
	var world: World = GameState.world
	var roster: Roster = GameState.roster
	# The save is about to be started over; the hall is where these people keep.
	Museum.remember(world, roster, GameState.ledger, _ending)
	if _ending == Museum.FELL and GameState.tallying:
		if _lead_is_dead():
			Sixteen.fall(_lead.template_id)
		# The world ends with its lead. Nothing is left to continue.
		GameState.forget_save()


func _reveal() -> void:
	var world: World = GameState.world
	var roster: Roster = GameState.roster
	_epitaph.text = Ledger.epitaph(world, roster, GameState.ledger)
	for chapter: Dictionary in Ledger.chapters(world, roster, GameState.ledger):
		_chapters.add_child(_chapter_block(chapter))
	_fallen.text = _roll_of_the_dead(Ledger.the_fallen(world, roster))
	_content.show()
	(_next_button if _next_button.visible else _title_button).grab_focus()

	_content.modulate = Color(1.0, 1.0, 1.0, 0.0)
	create_tween().tween_property(_content, "modulate:a", 1.0, 0.9)


func _lead_is_dead() -> bool:
	return _lead != null and _lead.status == Fate.DEAD


func _choose_the_next_lead() -> void:
	EventBus.request_scene.emit("temper_quiz", {
		"fallen": Sixteen.fallen_tempers(), "fallen_heroes": Sixteen.fallen_heroes(),
	})


# --- the moment (Classic) -----------------------------------------------------


func _hold_the_moment() -> void:
	var name_text: String = _lead.display_name if _lead != null else "Your lead"
	_beat = CenterContainer.new()
	_beat.name = "TheFall"
	_beat.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_beat)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(760, 0)
	box.add_theme_constant_override("separation", 16)
	_beat.add_child(box)

	var heading := _line(
		("%s has fallen." if _lead_is_dead() else "%s has been taken.") % name_text, 46, FALL_RED
	)
	heading.add_theme_color_override("font_outline_color", Color(0.067, 0.043, 0.039))
	heading.add_theme_constant_override("outline_size", 10)
	box.add_child(heading)

	var cause := _cause_of_it(name_text)
	if cause != "":
		box.add_child(_line(cause, 19, SOFT))

	box.add_child(_line(_what_a_reload_is(), 16, Color(0.769, 0.612, 0.494)))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	box.add_child(buttons)
	var reload := _choice("ReloadButton", "Reload", _reload)
	var ascend := _choice("AscendButton", "Ascend" if _lead_is_dead() else "Let it end", _ascend)
	buttons.add_child(reload)
	buttons.add_child(ascend)
	reload.grab_focus()

	# A breath of black before the name, so the fall is felt before it is read.
	_beat.modulate = Color(1.0, 1.0, 1.0, 0.0)
	heading.pivot_offset = Vector2(380, 30)
	heading.scale = Vector2(1.08, 1.08)
	var tween := create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(_beat, "modulate:a", 1.0, 1.4).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(heading, "scale", Vector2.ONE, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _cause_of_it(name_text: String) -> String:
	if not _lead_is_dead():
		return "They are held somewhere out there, and the company has nobody left to lead it."
	for entry: Dictionary in Ledger.the_fallen(GameState.world, GameState.roster):
		if entry.get("name", "") == name_text and str(entry.get("killer", "")) != "":
			return "Cut down by %s, at level %d." % [entry["killer"], int(entry.get("level", 1))]
	return "Their world goes dark with them."


func _what_a_reload_is() -> String:
	var ago := GameState.world.steps - GameState.last_save_steps if GameState.world != null else 0
	var when := "just before" if ago <= 0 else ("a step ago" if ago == 1 else "%d steps ago" % ago)
	var note := GameState.last_save_note
	if note == "":
		return "Reload goes back to the last save, %s." % when
	return "Reload goes back to when %s, %s." % [note, when]


func _choice(node_name: String, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.theme_type_variation = &"GrandButton"
	button.custom_minimum_size = Vector2(220, 0)
	button.mouse_entered.connect(button.grab_focus)
	button.pressed.connect(action)
	Sfx.attend(button)
	return button


func _line(text: String, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


## Back to the last save. Nothing has been written down, so nothing is undone.
func _reload() -> void:
	if GameState.load_save():
		EventBus.request_scene.emit("world", {})


## The fall is accepted: written down now, and the run told.
func _ascend() -> void:
	if _beat == null:
		return
	var beat := _beat
	_beat = null
	_settle()
	var tween := create_tween()
	tween.tween_property(beat, "modulate:a", 0.0, 0.6)
	tween.tween_callback(beat.queue_free)
	tween.tween_callback(_reveal)


# --- the run, told ------------------------------------------------------------


func _chapter_block(chapter: Dictionary) -> Control:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 4)
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var heading := Label.new()
	heading.text = chapter.get("title", "")
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", Color(0.96, 0.83, 0.44))
	block.add_child(heading)

	var rows := GridContainer.new()
	rows.columns = 2
	rows.add_theme_constant_override("h_separation", 18)
	rows.add_theme_constant_override("v_separation", 2)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for row: Array in chapter.get("rows", []):
		rows.add_child(_cell(row[0], Color(0.66, 0.64, 0.59), HORIZONTAL_ALIGNMENT_LEFT))
		rows.add_child(_cell(row[1], Color(0.9, 0.87, 0.79), HORIZONTAL_ALIGNMENT_RIGHT))
	block.add_child(rows)
	return block


func _cell(text: String, colour: Color, align: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", colour)
	label.horizontal_alignment = align
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _roll_of_the_dead(fallen: Array) -> String:
	if fallen.is_empty():
		return "Nobody was buried. The company simply stopped walking."
	var names: Array[String] = []
	for entry: Dictionary in fallen:
		var line := "%s, %s of level %d" % [entry["name"], entry["job"], entry["level"]]
		if entry.get("killer", "") != "":
			line += ", to %s" % entry["killer"]
		names.append(line)
	return "Buried on the way:  " + "  ·  ".join(names)
