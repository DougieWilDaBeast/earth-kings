extends Control
## The hall of everyone who walked out.
##
## Every finished run is written to `user://earth-kings.museum.json` by
## [Museum]; the run still being walked is read off the save and stands at the
## front of the hall, unfinished. Nothing here can be spent or resumed. It is
## the one place the game remembers people after their run is overwritten.

const HEADING := Color(0.965, 0.827, 0.443)
const LABEL := Color(0.66, 0.64, 0.59)
const VALUE := Color(0.90, 0.87, 0.79)
const LIVING := Color(0.72, 0.84, 0.72)
const LOST := Color(0.72, 0.55, 0.55)
const FACE := Vector2(72, 72)

## Set by [Game] before the scene enters the tree; unused here.
var boot_payload: Dictionary = {}

@onready var _journeys: VBoxContainer = %JourneyList
@onready var _empty: Label = %EmptyLabel
@onready var _plaque: VBoxContainer = %Plaque
@onready var _back: Button = %BackButton

var _all: Array = []


func _ready() -> void:
	_back.theme_type_variation = &"GrandButton"
	_back.pressed.connect(func() -> void: EventBus.request_scene.emit("title", {}))
	Sfx.attend(_back)

	var live := Museum.in_progress()
	if not live.is_empty():
		_all.append(live)
	_all.append_array(Museum.journeys())

	_empty.visible = _all.is_empty()
	for i in _all.size():
		_journeys.add_child(_journey_button(i))
	if _all.is_empty():
		_back.grab_focus()
		return
	_show(0)
	_journeys.get_child(0).grab_focus()


func _journey_button(index: int) -> Button:
	var journey: Dictionary = _all[index]
	var button := Button.new()
	button.theme_type_variation = &"GrandButton"
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = "%s — %s" % [journey.get("lead", "Nobody"), journey.get("ending", "")]
	button.focus_entered.connect(_show.bind(index))
	button.mouse_entered.connect(button.grab_focus)
	Sfx.attend(button)
	return button


func _show(index: int) -> void:
	for child in _plaque.get_children():
		child.queue_free()
	var journey: Dictionary = _all[index]

	var title := _line(str(journey.get("epitaph", "")), VALUE)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 18)
	_plaque.add_child(title)
	_plaque.add_child(_line(_when(journey), LABEL))

	_plaque.add_child(_heading("The company"))
	var company := HBoxContainer.new()
	company.add_theme_constant_override("separation", 16)
	for person: Dictionary in journey.get("company", []):
		company.add_child(_portrait(person))
	_plaque.add_child(company)

	_plaque.add_child(_heading("What they did"))
	var rows := GridContainer.new()
	rows.columns = 2
	rows.add_theme_constant_override("h_separation", 24)
	rows.add_theme_constant_override("v_separation", 3)
	for row: Array in _numbers(journey):
		rows.add_child(_line(str(row[0]), LABEL))
		rows.add_child(_line(str(row[1]), VALUE))
	_plaque.add_child(rows)


func _numbers(journey: Dictionary) -> Array:
	var nemesis := str(journey.get("nemesis", ""))
	return [
		["Steps walked", str(int(journey.get("steps", 0)))],
		["Gold taken", str(int(journey.get("gold", 0)))],
		["Enemies put down", str(int(journey.get("kills", 0)))],
		["Battles won", str(int(journey.get("battles_won", 0)))],
		["Battles lost", str(int(journey.get("battles_lost", 0)))],
		["Errands settled", str(int(journey.get("errands_done", 0)))],
		["Deeds worth repeating", str(int(journey.get("deeds", 0)))],
		["Tower floors climbed", str(int(journey.get("floors", 0)))],
		["Journal pages", str(int(journey.get("journal", 0)))],
		["Most often killed", nemesis if nemesis != "" else "nothing"],
	]


func _portrait(person: Dictionary) -> Control:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 2)
	block.custom_minimum_size = Vector2(140, 0)

	var face := TextureRect.new()
	face.custom_minimum_size = FACE
	face.texture = Database.unit_face(str(person.get("template_id", "")))
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	block.add_child(face)

	var alive := str(person.get("status", Fate.ALIVE)) == Fate.ALIVE
	var name_line := _line(str(person.get("name", "")), LIVING if alive else LOST)
	if bool(person.get("lead", false)):
		name_line.add_theme_color_override("font_color", HEADING)
	block.add_child(name_line)
	block.add_child(_line("%s L%d" % [person.get("job", ""), int(person.get("level", 1))], LABEL))

	if person.has("background"):
		block.add_child(_line(str(person["background"]), LABEL))
	if person.has("alignment"):
		block.add_child(_line(str(person["alignment"]), LABEL))
	if person.has("equipment") and str(person["equipment"]) != "":
		block.add_child(_line("Gear: %s" % str(person["equipment"]), VALUE))
	if person.has("attack"):
		block.add_child(_line("HP %d · ATK %d · DEF %d" % [
			int(person.get("hp", 0)), int(person.get("attack", 0)), int(person.get("defense", 0))
		], LABEL))
	if int(person.get("hearth", 0)) > 0:
		block.add_child(_line("Vigour +%d HP" % int(person["hearth"]), LIVING))

	if not alive:
		block.add_child(_line(str(person.get("status", "")), LOST))
	return block


func _when(journey: Dictionary) -> String:
	if bool(journey.get("live", false)):
		return "Still out there."
	var stamp := int(journey.get("ended_at", 0))
	if stamp <= 0:
		return ""
	var date := Time.get_datetime_dict_from_unix_time(stamp)
	return "Ended %04d-%02d-%02d." % [date["year"], date["month"], date["day"]]


func _heading(text: String) -> Label:
	var label := _line(text, HEADING)
	label.add_theme_font_size_override("font_size", 19)
	return label


func _line(text: String, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", colour)
	return label
