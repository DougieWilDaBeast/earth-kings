extends Control
## What the run amounted to, shown once the last of the party is gone.
##
## Nothing is counted here — the numbers are read off [Ledger] and the [World]
## that outlived them.

## Set by [Game] before the scene enters the tree; unused here.
var boot_payload: Dictionary = {}

@onready var _epitaph: Label = %EpitaphLabel
@onready var _chapters: GridContainer = %Chapters
@onready var _fallen: Label = %FallenLabel
@onready var _title_button: Button = %TitleButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	var world: World = GameState.world
	var roster: Roster = GameState.roster
	_epitaph.text = Ledger.epitaph(world, roster, GameState.ledger)
	for chapter: Dictionary in Ledger.chapters(world, roster, GameState.ledger):
		_chapters.add_child(_chapter_block(chapter))
	_fallen.text = _roll_of_the_dead(Ledger.the_fallen(world, roster))

	_title_button.pressed.connect(func() -> void: EventBus.request_scene.emit("title", {}))
	_quit_button.pressed.connect(func() -> void: get_tree().quit())
	_title_button.grab_focus()

	modulate = Color(1.0, 1.0, 1.0, 0.0)
	create_tween().tween_property(self, "modulate:a", 1.0, 0.9)


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
