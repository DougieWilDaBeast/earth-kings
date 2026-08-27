class_name PartyScreen
extends CanvasLayer
## The one screen where the party is more than health bars: pick a class, pass
## a book to someone who needs it, take the Yoke on or off.
##
## Rows are built in code because everything on them depends on who the
## character is and what the world has already handed them.

signal closed

@onready var _backdrop: ColorRect = %Backdrop
@onready var _roster_list: VBoxContainer = %RosterList
@onready var _footer: Label = %FooterLabel

var _notice: String = ""


func _ready() -> void:
	_backdrop.hide()
	EventBus.party_screen_requested.connect(open)


func is_open() -> bool:
	return _backdrop.visible


func open() -> void:
	_backdrop.show()
	_rebuild()


func close() -> void:
	_backdrop.hide()
	_notice = ""
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or not event.is_pressed() or event.is_echo():
		return
	if event.is_action("ui_cancel") or (event is InputEventKey and event.keycode == KEY_P):
		get_viewport().set_input_as_handled()
		close()


# --- the choices themselves ---------------------------------------------------


## Public so the walk scene and the tests can settle a class without the UI.
func choose_class(character: Character, class_id: String) -> bool:
	if not Progression.settle_class(character, class_id):
		return false
	_notice = "%s takes up the way of the %s." % [character.display_name, character.class_name_text()]
	_rebuild()
	return true


func teach(teacher: Character, student: Character, doctrine_id: String) -> bool:
	if not Doctrine.teach(teacher, student, doctrine_id, GameState.world.steps):
		return false
	_notice = "%s teaches %s to %s." % [
		teacher.display_name, Doctrine.title(doctrine_id), student.display_name
	]
	_rebuild()
	return true


func toggle_yoke(character: Character) -> void:
	character.yoke = not character.yoke
	_notice = "%s %s the Training Yoke." % [
		character.display_name, "takes on" if character.yoke else "sets down"
	]
	_rebuild()


# --- rendering ----------------------------------------------------------------


func _rebuild() -> void:
	for child in _roster_list.get_children():
		child.queue_free()

	var party := GameState.roster.party_members()
	for character in party:
		_roster_list.add_child(_row_for(character, party))

	var codex := GameState.world.codex_understanding()
	_footer.text = "Codex %d%%  ·  %d gold  ·  step %d%s  ·  P or Esc to close" % [
		roundi(codex * 100.0), GameState.gold, GameState.world.steps,
		"" if _notice == "" else "  ·  " + _notice
	]


func _row_for(character: Character, party: Array[Character]) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var heading := Label.new()
	heading.add_theme_font_size_override("font_size", 18)
	heading.text = "%s  —  level %d %s  ·  %d/%d HP  ·  %d/%d XP%s" % [
		character.display_name, character.level, character.class_name_text(),
		character.current_hp(), character.max_hp(),
		character.xp, Progression.xp_to_next(character.level),
		"  ·  YOKED" if character.yoke else ""
	]
	row.add_child(heading)

	var known := Label.new()
	known.add_theme_color_override("font_color", Color(0.7, 0.75, 0.84))
	known.text = "Read: %s" % _doctrine_summary(character)
	row.add_child(known)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	row.add_child(buttons)

	if character.pending_class_choice:
		var prompt := Label.new()
		prompt.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
		prompt.text = "Choose a path:"
		buttons.add_child(prompt)
		for class_id: String in Progression.class_options(character):
			var pick := Button.new()
			pick.text = Database.character_class(class_id).get("display_name", class_id)
			pick.pressed.connect(func() -> void: choose_class(character, class_id))
			buttons.add_child(pick)
	else:
		var yoke := Button.new()
		yoke.text = "Set down the Yoke" if character.yoke else "Take the Yoke"
		yoke.tooltip_text = "-%d%% attack, +%d%% experience" % [
			roundi(Character.YOKE_ATTACK_PENALTY * 100.0), roundi(Character.YOKE_XP_BONUS * 100.0)
		]
		yoke.pressed.connect(func() -> void: toggle_yoke(character))
		buttons.add_child(yoke)
		_add_teaching_buttons(buttons, character, party)

	return row


func _add_teaching_buttons(into: HBoxContainer, teacher: Character, party: Array[Character]) -> void:
	for student in party:
		if student == teacher:
			continue
		for doctrine_id: String in Doctrine.teachable(teacher, student):
			var button := Button.new()
			button.text = "Teach %s → %s" % [Doctrine.title(doctrine_id), student.display_name]
			button.pressed.connect(func() -> void: teach(teacher, student, doctrine_id))
			into.add_child(button)
			# One offer per student keeps the row readable.
			break


func _doctrine_summary(character: Character) -> String:
	if character.doctrine.is_empty():
		return "nothing yet"
	var titles: Array[String] = []
	for doctrine_id: String in character.doctrine:
		var stale := GameState.world.steps - int(character.doctrine_seen.get(doctrine_id, 0))
		var fading := stale > Doctrine.FADE_AFTER_STEPS * 0.75
		titles.append("%s%s" % [Doctrine.title(doctrine_id), "  (fading)" if fading else ""])
	return "  ·  ".join(titles)
