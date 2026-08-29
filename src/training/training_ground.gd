extends Control
## A sandbox for looking at everything the game owns — unit art, terrain,
## abilities, gear — and for throwing a real fight at any of it.
##
## Nothing here writes to the save. Training fights run with `sandbox` set, so
## the party walks out of them whole (see [Battle]).

const ROTATIONS := ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
## Cardinals are the only rotations [Unit] actually draws; the rest are stock.
const USED_ROTATIONS := ["south", "north", "east", "west"]
const SPRITE_ZOOM := 2
const FIELD_CELL := 22
## Widest a column of prose is allowed to get before it wraps.
const PROSE_WIDTH := 340

var boot_payload: Dictionary = {}

@onready var _tabs: TabContainer = %Tabs
@onready var _back_button: Button = %BackButton

var _rng := RandomNumberGenerator.new()
var _unit_id: String = ""
var _state_dir: String = ""

var _rotation_row: HBoxContainer
var _state_row: HBoxContainer
var _unit_stats: Label
var _terrain_pick: OptionButton
var _count_pick: SpinBox
var _level_pick: SpinBox
var _field_terrain: OptionButton
var _field: Control
var _field_map: Dictionary = {}
var _theme_pick: OptionButton
var _tree_out: Label
var _errand_out: Label
var _codex_out: Label


func _ready() -> void:
	_rng.randomize()
	# Nothing done in here belongs in the run's ledger.
	GameState.tallying = false
	_back_button.pressed.connect(func() -> void: EventBus.request_scene.emit("title", {}))
	_build_units_tab()
	_build_terrain_tab()
	_build_abilities_tab()
	_build_errands_tab()
	_build_codex_tab()
	_build_gear_tab()
	var ids: Array = Database.units.keys()
	if not ids.is_empty():
		_select_unit(ids[0])


func _exit_tree() -> void:
	GameState.tallying = true


# --- units --------------------------------------------------------------------


func _build_units_tab() -> void:
	var page := HBoxContainer.new()
	page.name = "Units"
	page.add_theme_constant_override("separation", 16)
	_tabs.add_child(page)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(220, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for id: String in Database.units:
		var template: Dictionary = Database.units[id]
		var button := Button.new()
		button.text = "%s  ·  %s" % [template.get("display_name", id), template.get("job", "")]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = id
		button.pressed.connect(_select_unit.bind(id))
		list.add_child(button)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	page.add_child(right)

	_state_row = HBoxContainer.new()
	right.add_child(_state_row)

	# Eight rotations are wider than any window, so that one row scrolls sideways.
	var rotations := ScrollContainer.new()
	rotations.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rotations.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rotations.custom_minimum_size = Vector2(0, 48 * SPRITE_ZOOM + 44)
	right.add_child(rotations)

	_rotation_row = HBoxContainer.new()
	_rotation_row.add_theme_constant_override("separation", 8)
	rotations.add_child(_rotation_row)

	var stats_scroll := ScrollContainer.new()
	stats_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(stats_scroll)

	_unit_stats = Label.new()
	_unit_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_unit_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_scroll.add_child(_unit_stats)

	# The fight row stays pinned below the scroll, so it is always reachable.
	right.add_child(_build_fight_row())


func _build_fight_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	row.add_child(_labelled("Ground"))
	_terrain_pick = OptionButton.new()
	for id: String in BattleMapGen.PALETTES:
		_terrain_pick.add_item(Database.terrain_type(id).get("name", id))
		_terrain_pick.set_item_metadata(_terrain_pick.item_count - 1, id)
	row.add_child(_terrain_pick)

	row.add_child(_labelled("How many"))
	_count_pick = SpinBox.new()
	_count_pick.min_value = 1
	_count_pick.max_value = 4
	_count_pick.value = 2
	row.add_child(_count_pick)

	row.add_child(_labelled("Level"))
	_level_pick = SpinBox.new()
	_level_pick.min_value = 0
	_level_pick.max_value = 40
	_level_pick.value = 0
	_level_pick.tooltip_text = "0 uses the raw template, without levelling it up."
	row.add_child(_level_pick)

	var fight := Button.new()
	fight.text = "Fight this"
	fight.pressed.connect(_start_training_fight)
	row.add_child(fight)
	return row


func _select_unit(id: String) -> void:
	_unit_id = id
	_state_dir = ""
	_refresh_states()
	_refresh_rotations()
	_refresh_stats()


func _character_dir() -> String:
	var sprite_dir: String = Database.unit_template(_unit_id).get("sprite_dir", "")
	return sprite_dir.get_base_dir() if sprite_dir != "" else ""


func _refresh_states() -> void:
	for child in _state_row.get_children():
		child.queue_free()
	var dir := _character_dir()
	if dir == "":
		_state_row.add_child(_labelled("no art yet — drawn as a coloured token"))
		return
	var states: PackedStringArray = DirAccess.get_directories_at(dir)
	if states.is_empty():
		return
	_state_dir = Database.unit_template(_unit_id).get("sprite_dir", "").get_file()
	for state in states:
		var button := Button.new()
		button.text = state
		button.toggle_mode = true
		button.button_pressed = state == _state_dir
		button.pressed.connect(func() -> void:
			_state_dir = state
			_refresh_states()
			_refresh_rotations()
		)
		_state_row.add_child(button)


func _refresh_rotations() -> void:
	for child in _rotation_row.get_children():
		child.queue_free()
	var dir := _character_dir()
	if dir == "" or _state_dir == "":
		return
	for rotation in ROTATIONS:
		_rotation_row.add_child(_rotation_cell("%s/%s/%s.png" % [dir, _state_dir, rotation], rotation))


func _rotation_cell(path: String, rotation: String) -> Control:
	var box := VBoxContainer.new()
	var frame := TextureRect.new()
	frame.custom_minimum_size = Vector2.ONE * 48 * SPRITE_ZOOM
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(path):
		frame.texture = load(path)
	box.add_child(frame)

	var caption := Label.new()
	caption.text = rotation if frame.texture != null else "%s — missing" % rotation
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Dim the diagonals nothing reads yet, so a gap in the cardinals stands out.
	if rotation not in USED_ROTATIONS:
		caption.modulate = Color(1, 1, 1, 0.45)
		frame.modulate = Color(1, 1, 1, 0.55)
	box.add_child(caption)
	return box


func _refresh_stats() -> void:
	var t := Database.unit_template(_unit_id)
	var lines := [
		"%s  (%s)" % [t.get("display_name", _unit_id), _unit_id],
		"job %s · kind %s" % [t.get("job", "—"), t.get("kind", "default")],
		"hp %d · attack %d · defense %d" % [int(t.get("max_hp", 0)), int(t.get("attack", 0)), int(t.get("defense", 0))],
		"move %d · jump %d · speed %d · flash %d" % [
			int(t.get("move", 0)), int(t.get("jump", 0)), int(t.get("speed", 0)), int(t.get("flash_step", 0))
		],
		"abilities: %s" % ", ".join(PackedStringArray(t.get("abilities", []))),
		"classes: %s" % ", ".join(PackedStringArray(t.get("classes", []))),
		"weapon: %s" % t.get("weapon", "—"),
		"capture chance against you: %d%%" % roundi(
			float(Database.fate.get("capture_by", {}).get(t.get("kind", "default"), 0.15)) * 100.0
		),
	]
	_unit_stats.text = "\n".join(lines)


func _start_training_fight() -> void:
	var terrain_id: String = _terrain_pick.get_item_metadata(_terrain_pick.selected)
	var enemies: Array = []
	for i in int(_count_pick.value):
		enemies.append({"unit": _unit_id, "level": int(_level_pick.value)})
	var map := BattleMapGen.generate_on(
		terrain_id, Database.terrain_type(terrain_id).get("name", terrain_id), enemies, _rng
	)
	EventBus.request_scene.emit("battle", {
		"encounter": {"map": map, "title": "Training"},
		"return_scene": "training",
		"sandbox": true,
	})


# --- terrain ------------------------------------------------------------------


func _build_terrain_tab() -> void:
	var page := _scrolling_page("Terrain")

	var table := GridContainer.new()
	table.columns = 5
	table.add_theme_constant_override("h_separation", 18)
	for heading in ["", "terrain", "move cost", "height", "walkable"]:
		table.add_child(_labelled(heading))
	for id: String in Database.terrain:
		var data: Dictionary = Database.terrain[id]
		var swatch := ColorRect.new()
		swatch.color = Color(data.get("color", "#ffffff"))
		swatch.custom_minimum_size = Vector2(28, 20)
		table.add_child(swatch)
		table.add_child(_labelled("%s  (%s)" % [data.get("name", id), id]))
		table.add_child(_labelled(str(data.get("move_cost", 1))))
		table.add_child(_labelled(str(data.get("height", 0))))
		table.add_child(_labelled("yes" if data.get("walkable", true) else "no"))
	page.add_child(table)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_labelled("Generated field"))
	_field_terrain = OptionButton.new()
	for id: String in BattleMapGen.PALETTES:
		_field_terrain.add_item(Database.terrain_type(id).get("name", id))
		_field_terrain.set_item_metadata(_field_terrain.item_count - 1, id)
	_field_terrain.item_selected.connect(func(_i: int) -> void: _reroll_field())
	row.add_child(_field_terrain)
	var reroll := Button.new()
	reroll.text = "Reroll"
	reroll.pressed.connect(_reroll_field)
	row.add_child(reroll)
	page.add_child(row)

	_field = Control.new()
	_field.custom_minimum_size = Vector2(BattleMapGen.SIZE) * FIELD_CELL
	_field.draw.connect(_draw_field)
	page.add_child(_field)
	_reroll_field()


func _reroll_field() -> void:
	var terrain_id: String = _field_terrain.get_item_metadata(maxi(0, _field_terrain.selected))
	_field_map = BattleMapGen.generate_on(terrain_id, terrain_id, [], _rng)
	_field.queue_redraw()


func _draw_field() -> void:
	var legend: Dictionary = _field_map.get("legend", {})
	var rows: Array = _field_map.get("tiles", [])
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var data := Database.terrain_type(legend.get(row[x], "grass"))
			var rect := Rect2(Vector2(x, y) * FIELD_CELL, Vector2.ONE * FIELD_CELL)
			_field.draw_rect(rect, Color(data.get("color", "#ffffff")))
			if int(data.get("height", 0)) > 0:
				_field.draw_rect(Rect2(rect.position, Vector2(FIELD_CELL, 3)), Color(1, 1, 1, 0.2))
	for spawn: Array in _field_map.get("player_spawns", []):
		_mark_field(spawn, Color(0.4, 0.7, 1.0))


func _mark_field(cell: Array, colour: Color) -> void:
	var rect := Rect2(Vector2(int(cell[0]), int(cell[1])) * FIELD_CELL, Vector2.ONE * FIELD_CELL)
	_field.draw_rect(rect, colour, false, 2.0)


# --- abilities ----------------------------------------------------------------


func _build_abilities_tab() -> void:
	var page := _scrolling_page("Abilities")

	var table := GridContainer.new()
	table.columns = 6
	table.add_theme_constant_override("h_separation", 18)
	for heading in ["ability", "target", "range", "splash", "power", "description"]:
		table.add_child(_labelled(heading))
	for id: String in Database.abilities:
		var a: Dictionary = Database.abilities[id]
		table.add_child(_labelled(a.get("display_name", id)))
		table.add_child(_labelled(a.get("target", "enemy")))
		table.add_child(_labelled("%d–%d" % [int(a.get("min_range", 1)), int(a.get("range", 1))]))
		table.add_child(_labelled(str(a.get("splash", 0))))
		table.add_child(_labelled("%s%s" % [str(a.get("power", 1.0)), " hp" if a.get("heal", false) else "×"]))
		table.add_child(_wrapped(a.get("description", "")))
	page.add_child(table)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_labelled("Roll a tree from the grammar"))
	_theme_pick = OptionButton.new()
	for theme_id: String in AbilityGrammar.THEMES:
		_theme_pick.add_item(AbilityGrammar.THEMES[theme_id]["name"])
		_theme_pick.set_item_metadata(_theme_pick.item_count - 1, theme_id)
	row.add_child(_theme_pick)
	var roll := Button.new()
	roll.text = "Roll"
	roll.pressed.connect(_roll_tree)
	row.add_child(roll)
	page.add_child(row)

	_tree_out = Label.new()
	_tree_out.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_tree_out)


func _roll_tree() -> void:
	var theme_id: String = _theme_pick.get_item_metadata(maxi(0, _theme_pick.selected))
	var tree := AbilityGrammar.generate_tree(theme_id, _rng)
	var lines := [tree["display_name"]]
	var definitions: Dictionary = tree["definitions"]
	for rung in tree["abilities"].size():
		var a: Dictionary = definitions[tree["abilities"][rung]]
		lines.append("  %d. %s — %s, range %d–%d, splash %d, power %s" % [
			rung + 1, a["display_name"], a["target"],
			int(a["min_range"]), int(a["range"]), int(a["splash"]), str(a["power"]),
		])
	_tree_out.text = "\n".join(lines)


# --- errands ------------------------------------------------------------------


func _build_errands_tab() -> void:
	var page := VBoxContainer.new()
	page.name = "Errands"
	page.add_theme_constant_override("separation", 10)
	_tabs.add_child(page)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_labelled("What the boards are offering"))
	var roll := Button.new()
	roll.text = "Roll 8"
	roll.pressed.connect(_roll_errands)
	row.add_child(roll)
	page.add_child(row)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)

	_errand_out = Label.new()
	_errand_out.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_errand_out.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_errand_out)
	_roll_errands()


func _roll_errands() -> void:
	var world: World = GameState.world
	var boards: Array = world.sites.filter(
		func(s: Site) -> bool: return s.kind == Site.VILLAGE or s.kind == Site.KEEP or s.kind == Site.HUT
	)
	if boards.is_empty():
		_errand_out.text = "This world has nowhere to post an errand."
		return

	var lines: Array[String] = []
	for i in 8:
		var site: Site = boards[i % boards.size()]
		# Clearing the board is how you ask it for another one.
		site.data["errand"] = {}
		Errand.refresh(site, world)
		var errand := Errand.board(site)
		lines.append("%s — %s (%s)\n  %s\n  %s\n" % [
			site.display_name, errand.get("title", ""), errand.get("kind", ""),
			errand.get("giver", ""), Errand.detail(errand),
		])
	site_boards_cleanup(boards)
	_errand_out.text = "\n".join(lines)


## Training should not leave real errands pinned up around the world.
func site_boards_cleanup(boards: Array) -> void:
	for site: Site in boards:
		site.data["errand"] = {}


# --- codex --------------------------------------------------------------------


func _build_codex_tab() -> void:
	var page := VBoxContainer.new()
	page.name = "Codex"
	page.add_theme_constant_override("separation", 10)
	_tabs.add_child(page)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var find := Button.new()
	find.text = "Find a trivial spell"
	find.pressed.connect(func() -> void:
		Trivia.discover(GameState.world)
		_refresh_codex()
	)
	row.add_child(find)
	var books := Button.new()
	books.text = "Open 6 grimoires"
	books.pressed.connect(_open_grimoires)
	row.add_child(books)
	page.add_child(row)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)

	_codex_out = Label.new()
	_codex_out.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_codex_out.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_codex_out)
	_refresh_codex()


func _refresh_codex() -> void:
	var world: World = GameState.world
	var lines: Array[String] = [
		"Understanding %d%%  ·  themes %d/%d  ·  trivial spells %d/%d" % [
			roundi(world.codex_understanding() * 100.0),
			world.codex.size(), AbilityGrammar.THEMES.size(),
			world.trivia.size(), Trivia.total(),
		],
		"",
	]
	for entry: Dictionary in world.trivia:
		lines.append("  %s" % Trivia.line(entry))
	if world.trivia.is_empty():
		lines.append("  Nothing written down yet.")

	var graves: Array = world.sites.filter(func(s: Site) -> bool: return Memorial.is_grave(s))
	lines.append("")
	lines.append("Graves: %d" % graves.size())
	for site: Site in graves:
		lines.append("  %s  %s" % [str(site.cell), Memorial.epitaph(site, world)])
	_codex_out.text = "\n".join(lines)


## Roll the odds without the world paying for it.
func _open_grimoires() -> void:
	var world: World = GameState.world
	var shelf := Site.create(Site.VILLAGE, Vector2i.ZERO, "a stall")
	var reader := GameState.roster.player()
	var purse := GameState.gold
	GameState.gold = 1000000

	var lines: Array[String] = []
	for i in 6:
		Grimoire.stock(shelf, world)
		lines.append_array(Grimoire.buy_and_read(shelf, reader, world))
		lines.append("")
	GameState.gold = purse
	_codex_out.text = "\n".join(lines)


# --- gear ---------------------------------------------------------------------


func _build_gear_tab() -> void:
	var page := _scrolling_page("Gear")
	page.add_theme_constant_override("separation", 12)

	for id: String in Database.equipment:
		var piece: Dictionary = Database.equipment[id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var sprite_dir: String = piece.get("sprite_dir", "")
		for rotation in USED_ROTATIONS:
			var path := "%s/%s.png" % [sprite_dir, rotation]
			if sprite_dir == "" or not ResourceLoader.exists(path):
				continue
			var frame := TextureRect.new()
			frame.custom_minimum_size = Vector2.ONE * 48 * 2
			frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			frame.texture = load(path)
			row.add_child(frame)

		row.add_child(_wrapped("%s (%s)\nattack +%d · defense +%d · grace %d%% · %d gold\n%s" % [
			piece.get("display_name", id), id,
			int(piece.get("attack", 0)), int(piece.get("defense", 0)),
			roundi(float(piece.get("grace", 0.0)) * 100.0), Market.price_of(id),
			piece.get("text", ""),
		]))
		page.add_child(row)


# --- helpers ---------------------------------------------------------------


## Every table here is taller and wider than the window, so each tab is its own
## scroller rather than something that quietly runs off the edge of the screen.
func _scrolling_page(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(scroll)

	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 10)
	scroll.add_child(page)
	return page


func _labelled(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


func _wrapped(text: String) -> Label:
	var label := _labelled(text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(PROSE_WIDTH, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label
