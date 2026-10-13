class_name JournalScreen
extends CanvasLayer
## The book the lead carries: found in the furrow beside them when they fell
## ([D66]), bound in leather, written in ink on two facing pages.
##
## The Company is its first page: a sheet for each companion, every number
## the game keeps on them in one place ([D66]). The Bestiary is the book of
## what you have met. A page there is opened by standing across a field from
## something, and it opens nearly blank. Every question mark on it is a thing
## you have not earned yet: fight it, take a blow from it, put one down, and the
## line fills itself in.
##
## Read-only. Nothing on this screen can be spent, chosen or missed; a sheet
## with a path or a power owed offers one button, to the party screen where it
## is chosen.
##
## The map is kept here ([D61]): the continent, black where the company has
## never been, opened from the journal and nowhere else.

## Loaded by path ([D41]): regional names (see its header).
const Names := preload("res://src/chronicle/names.gd")
const Fall := preload("res://src/chronicle/fall.gd")
const Wanderers := preload("res://src/chronicle/wanderers.gd")
const Siblings := preload("res://src/chronicle/siblings.gd")
const SheetParts := preload("res://src/ui/sheet_parts.gd")

signal closed

enum Tab { SHEET, BESTIARY, ROUTES, ANNALS, QUESTS }

## Ink on parchment ([D66]).
const UNKNOWN_COLOUR := Color(0.60, 0.52, 0.40)
const KNOWN_COLOUR := Color(0.20, 0.13, 0.08)
const LABEL_COLOUR := Color(0.44, 0.34, 0.23)
const HEADING_COLOUR := Color(0.55, 0.13, 0.09)
const FACE_SIZE := Vector2(96, 96)

## The binding.
const LEATHER := Color(0.31, 0.18, 0.10)
const LEATHER_EDGE := Color(0.15, 0.08, 0.04)
const TOOLED_GOLD := Color(0.86, 0.68, 0.36)
const PARCHMENT := Color(0.94, 0.88, 0.73)
const PARCHMENT_FACING := Color(0.95, 0.90, 0.76)
const GUTTER := Color(0.78, 0.68, 0.50)
const PAGE_EDGE := Color(0.70, 0.59, 0.42)
const SPINE := Color(0.20, 0.11, 0.06)
## A pencil line: rules, scrollbars, an entry under the reader's finger.
const PENCIL := Color(0.52, 0.40, 0.26, 0.55)
const TRACK := Color(0.80, 0.72, 0.56)

## A silk ribbon for each tab, so a tab is found by its colour.
const RIBBONS := {
	Tab.SHEET: Color(0.60, 0.16, 0.13),
	Tab.BESTIARY: Color(0.27, 0.40, 0.19),
	Tab.ROUTES: Color(0.17, 0.27, 0.47),
	Tab.ANNALS: Color(0.64, 0.44, 0.12),
	Tab.QUESTS: Color(0.40, 0.19, 0.40),
}
const MAP_RIBBON := Color(0.13, 0.40, 0.38)

## Serif faces the book asks the computer for, best first. Wherever none are
## found (and on the web build) it falls back to the game's own face.
const BOOK_FACES := [
	"Georgia", "Palatino Linotype", "Book Antiqua", "Palatino", "Times New Roman",
	"Liberation Serif", "DejaVu Serif", "FreeSerif", "serif",
]
## A companion's face on their sheet, and on the list of the company.
const SHEET_FACE := Vector2(112, 112)
const LIST_FACE := 36

@onready var _backdrop: ColorRect = %Backdrop
@onready var _title: Label = %TitleLabel
@onready var _fullness: Label = %FullnessLabel
@onready var _footer: Label = %FooterLabel
@onready var _book: PanelContainer = %Book
@onready var _left_leaf: PanelContainer = %LeftLeaf
@onready var _right_leaf: PanelContainer = %RightLeaf
@onready var _spine: PanelContainer = %Spine
@onready var _sheet_btn: Button = %SheetButton
@onready var _list: VBoxContainer = %EntryList
@onready var _page: VBoxContainer = %Page
@onready var _bestiary_btn: Button = %BestiaryButton
@onready var _routes_btn: Button = %RoutesButton
@onready var _annals_btn: Button = %AnnalsButton
@onready var _quests_btn: Button = %QuestsButton
@onready var _map_btn: Button = %MapButton
@onready var _close_btn: Button = %CloseButton

var _showing: String = ""
var _tab: Tab = Tab.SHEET
var _selected_route_idx: int = 0
## Whose sheet is open on the Company page, by id.
var _sheet_id: String = ""


func _ready() -> void:
	_backdrop.hide()
	add_to_group(EventBus.MODAL_OVERLAY_GROUP)
	EventBus.journal_requested.connect(open)
	_dress_book()
	_sheet_btn.pressed.connect(func() -> void: _set_tab(Tab.SHEET))
	_bestiary_btn.pressed.connect(func() -> void: _set_tab(Tab.BESTIARY))
	_routes_btn.pressed.connect(func() -> void: _set_tab(Tab.ROUTES))
	_annals_btn.pressed.connect(func() -> void: _set_tab(Tab.ANNALS))
	_quests_btn.pressed.connect(func() -> void: _set_tab(Tab.QUESTS))
	_map_btn.pressed.connect(open_map)
	# Escape is the only other way out, and a phone has no Escape.
	_close_btn.pressed.connect(close)
	Sfx.attend(_sheet_btn)
	Sfx.attend(_bestiary_btn)
	Sfx.attend(_routes_btn)
	Sfx.attend(_annals_btn)
	Sfx.attend(_quests_btn)
	Sfx.attend(_map_btn)
	Sfx.attend(_close_btn)


func _set_tab(tab: Tab) -> void:
	_tab = tab
	_rebuild()


## Turn to a tab by name: "company", "bestiary", "routes", "annals" or "quests".
## For the bench and the tests; false for a name the book has no ribbon for.
func turn_to(tab_name: String) -> bool:
	var by_name := {
		"company": Tab.SHEET, "bestiary": Tab.BESTIARY, "routes": Tab.ROUTES,
		"annals": Tab.ANNALS, "quests": Tab.QUESTS,
	}
	if not by_name.has(tab_name):
		return false
	_set_tab(by_name[tab_name])
	return true


## Which tab is open, by the same names.
func open_tab() -> String:
	return ["company", "bestiary", "routes", "annals", "quests"][_tab]


func is_open() -> bool:
	return _backdrop.visible


func open() -> void:
	_backdrop.show()
	_rebuild()


func close() -> void:
	_backdrop.hide()
	closed.emit()
	EventBus.overlay_closed.emit()


## Shut the book and look at the map. Whichever ground the party is on opens
## it, so it comes back to the same spot when the map is put away.
func open_map() -> void:
	close()
	EventBus.map_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_N):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey and event.keycode == KEY_M:
		get_viewport().set_input_as_handled()
		open_map()


func _rebuild() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var world: World = GameState.world
	if world == null:
		return
	var lead := GameState.roster.player() if GameState.roster != null else null
	_title.text = "The Journal of %s" % lead.display_name if lead != null else "The Journal"
	_mark_ribbons()

	if _tab == Tab.SHEET:
		var party: Array = GameState.roster.party_members() if GameState.roster != null else []
		_fullness.text = "%d in the company" % party.size()
		_sheet_character()
		for member: Character in party:
			_list.add_child(_company_entry(member))
		_show_sheet()
	elif _tab == Tab.BESTIARY:
		var met := Journal.met(world)
		var fullness := Journal.fullness(world)
		_fullness.text = "%d of %d written up" % [fullness[0], fullness[1]]

		if met.is_empty():
			_showing = ""
			_show_page()
			return
		for template_id: String in met:
			var button := Button.new()
			button.text = str(Database.unit_template(template_id).get("display_name", template_id))
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.pressed.connect(_open_page.bind(template_id))
			Sfx.attend(button)
			_list.add_child(button)
		if not met.has(_showing):
			_showing = met[0]
		_show_page()
	elif _tab == Tab.ROUTES:
		_fullness.text = "%d active trade routes" % world.routes.size()
		if world.routes.is_empty():
			var label := Label.new()
			label.text = "No open trade routes."
			label.add_theme_color_override("font_color", LABEL_COLOUR)
			_list.add_child(label)
		else:
			for idx in world.routes.size():
				var route: Dictionary = world.routes[idx]
				var button := Button.new()
				button.text = "%s (%d gold)" % [route.get("name", "Route"), int(route.get("pay", 0))]
				button.alignment = HORIZONTAL_ALIGNMENT_LEFT
				button.pressed.connect(func() -> void:
					_selected_route_idx = idx
					_show_routes_page()
				)
				Sfx.attend(button)
				_list.add_child(button)
		_show_routes_page()
	elif _tab == Tab.QUESTS:
		var others := world.wanderers.size()
		_fullness.text = "%d of the others known of" % Wanderers.known(world).size() if others > 0 else ""
		var standing := Button.new()
		standing.text = Fall.quest_title()
		standing.alignment = HORIZONTAL_ALIGNMENT_LEFT
		Sfx.attend(standing)
		_list.add_child(standing)
		for errand: Dictionary in GameState.errands:
			var label := _line(Errand.summary(errand), KNOWN_COLOUR)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_list.add_child(label)
		_show_quests_page()
	else:
		_fullness.text = "%d chronicle entries" % world.annals.size()
		var label := Label.new()
		label.text = "Chronicle of Earth Kings"
		label.add_theme_color_override("font_color", HEADING_COLOUR)
		_list.add_child(label)
		var sub := Label.new()
		sub.text = "%d notable deeds recorded across the continent." % world.annals.size()
		sub.add_theme_color_override("font_color", LABEL_COLOUR)
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(sub)
		_show_annals_page()


## The standing quest every lead carries ([D53]), the errands taken, and what
## is known of the others who fell (M13).
func _show_quests_page() -> void:
	_clear_page()
	var world: World = GameState.world
	if world == null:
		return

	var title := _line(Fall.quest_title(), HEADING_COLOUR)
	title.add_theme_font_size_override("font_size", 22)
	_page.add_child(title)
	var brief := _line(Fall.quest_brief(), KNOWN_COLOUR)
	brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_page.add_child(brief)
	var progress := _line(Fall.quest_progress(world), LABEL_COLOUR)
	progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_page.add_child(progress)
	_page.add_child(HSeparator.new())

	var errands_title := _line("Errands taken", HEADING_COLOUR)
	errands_title.add_theme_font_size_override("font_size", 18)
	_page.add_child(errands_title)
	if GameState.errands.is_empty():
		_page.add_child(_line("None. A settlement's board has work, if you want it.", LABEL_COLOUR))
	for errand: Dictionary in GameState.errands:
		_page.add_child(_line("  %s" % Errand.summary(errand), KNOWN_COLOUR))
	_page.add_child(HSeparator.new())

	var others_title := _line("The others who fell", HEADING_COLOUR)
	others_title.add_theme_font_size_override("font_size", 18)
	_page.add_child(others_title)
	var known := Wanderers.known(world)
	for each: Dictionary in known:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var face := TextureRect.new()
		face.custom_minimum_size = Vector2(36, 36)
		face.texture = Database.unit_face(str(each.get("id", "")))
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(face)
		var said := _line(Wanderers.whereabouts(world, each), KNOWN_COLOUR)
		said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		said.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(said)
		_page.add_child(row)
	var unknown := world.wanderers.size() - known.size()
	if unknown > 0:
		_page.add_child(_line(
			"%d more carry the mark somewhere out there. Ask at an inn, or rest where people talk." % unknown,
			LABEL_COLOUR
		))

	# The worlds that ended before this one, and what has come through (M15).
	var gone := Siblings.past(world)
	if gone.is_empty():
		return
	_page.add_child(HSeparator.new())
	var worlds_title := _line("World %d of the sixteen. The worlds that ended" % Siblings.number(world), HEADING_COLOUR)
	worlds_title.add_theme_font_size_override("font_size", 18)
	_page.add_child(worlds_title)
	for echo: Dictionary in gone:
		var weapon: Dictionary = echo.get("weapon", {})
		var where := "Their weapon has not come down yet: it waits until you have got as far as they did."
		if bool(weapon.get("found", false)):
			where = "You carry %s." % Gear.display_name(str(weapon.get("id", "")))
		elif bool(weapon.get("landed", false)):
			where = "%s has fallen%s. Their ghost sits at the fire." % [
				Gear.display_name(str(weapon.get("id", ""))),
				", and you have word of where" if bool(weapon.get("heard", false)) else " somewhere near where you came down",
			]
		var said := _line("%s died at level %d, %s. %s" % [
			str(echo.get("name", "")), int(echo.get("level", 1)),
			"on floor %d of the Tower" % int(echo.get("floor", 0)) if int(echo.get("floor", 0)) > 0 else "before the Tower",
			where,
		], KNOWN_COLOUR)
		said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_page.add_child(said)


func _show_annals_page() -> void:
	_clear_page()
	var world: World = GameState.world
	if world == null:
		return

	var annals_title := _line("The Annals of the Company", HEADING_COLOUR)
	annals_title.add_theme_font_size_override("font_size", 22)
	_page.add_child(annals_title)

	var subtitle := _line("An unbroken chronicle of what this company dared, discovered, and endured.", LABEL_COLOUR)
	_page.add_child(subtitle)

	if world.annals.is_empty():
		_page.add_child(_line("The pages are fresh. The history of this company is yet to be written.", LABEL_COLOUR))
		return

	for i in range(world.annals.size() - 1, -1, -1):
		var entry: Dictionary = world.annals[i]
		var step_num: int = int(entry.get("step", 0))
		var region_str: String = str(entry.get("region", "Wilds"))
		var text_str: String = str(entry.get("text", ""))

		var entry_row := VBoxContainer.new()
		entry_row.add_theme_constant_override("separation", 2)

		var meta := _line("Step %d  ·  %s" % [step_num, region_str], HEADING_COLOUR)
		meta.add_theme_font_size_override("font_size", 14)
		entry_row.add_child(meta)

		var body_line := _line("  %s" % text_str, KNOWN_COLOUR)
		body_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry_row.add_child(body_line)

		_page.add_child(entry_row)


func _show_routes_page() -> void:
	_clear_page()
	var world: World = GameState.world
	if world == null:
		return

	# Seasons of the Land
	var s_title := _line("Seasons of the Land", HEADING_COLOUR)
	s_title.add_theme_font_size_override("font_size", 22)
	_page.add_child(s_title)

	var s_box := HBoxContainer.new()
	s_box.add_theme_constant_override("separation", 16)

	var s_icon := TextureRect.new()
	s_icon.custom_minimum_size = Vector2(48, 48)
	s_icon.texture = Season.clover_texture(world)
	s_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	s_box.add_child(s_icon)

	var s_info := VBoxContainer.new()
	s_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s_curr := Season.current(world)
	var s_head := _line("%s  ·  %s" % [Season.label(world), s_curr["clover_name"]], KNOWN_COLOUR)
	s_head.add_theme_font_size_override("font_size", 17)
	s_info.add_child(s_head)

	var s_sub := _line("Step %d of %d in the season  ·  %d steps until next season" % [
		Season.step_in_season(world), Season.steps_per_season(), Season.steps_remaining(world)
	], LABEL_COLOUR)
	s_sub.add_theme_font_size_override("font_size", 13)
	s_info.add_child(s_sub)

	var s_blurb := _line(str(s_curr.get("blurb", "")), KNOWN_COLOUR)
	s_blurb.add_theme_font_size_override("font_size", 13)
	s_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s_info.add_child(s_blurb)
	s_box.add_child(s_info)
	_page.add_child(s_box)

	# 4 Clovers Row
	var clover_row := HBoxContainer.new()
	clover_row.add_theme_constant_override("separation", 18)
	for sea: Dictionary in Season.SEASONS:
		var c_pill := HBoxContainer.new()
		c_pill.add_theme_constant_override("separation", 6)
		var c_tex := TextureRect.new()
		c_tex.custom_minimum_size = Vector2(20, 20)
		c_tex.texture = Season.texture_by_key(sea["clover"])
		c_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		c_pill.add_child(c_tex)
		var is_active: bool = (sea["index"] == Season.index(world))
		var col: Color = (sea["colour"] as Color).darkened(0.4) if is_active else UNKNOWN_COLOUR
		var c_lbl := _line("%s (%s)" % [sea["display_name"], sea["clover_name"]], col)
		c_lbl.add_theme_font_size_override("font_size", 12)
		c_pill.add_child(c_lbl)
		clover_row.add_child(c_pill)
	_page.add_child(clover_row)

	_page.add_child(HSeparator.new())

	var routes_title := _line("Trade Routes", HEADING_COLOUR)
	routes_title.add_theme_font_size_override("font_size", 20)
	_page.add_child(routes_title)

	if world.routes.is_empty():
		_page.add_child(_line("No merchants run goods for you yet. Escort a stranded trader on the roadside to establish a trade route.", LABEL_COLOUR))
	else:
		_selected_route_idx = clampi(_selected_route_idx, 0, world.routes.size() - 1)
		var route: Dictionary = world.routes[_selected_route_idx]
		var name_str := str(route.get("name", "Unknown"))
		var pay := int(route.get("pay", 0))
		var age := world.steps - int(route.get("since", 0))
		var left := maxi(0, Roadside.ROUTE_LIFE - age)

		var route_head := _line("Contract: The %s Road" % name_str, KNOWN_COLOUR)
		route_head.add_theme_font_size_override("font_size", 18)
		_page.add_child(route_head)

		var details := GridContainer.new()
		details.columns = 2
		details.add_theme_constant_override("h_separation", 20)
		details.add_theme_constant_override("v_separation", 4)

		details.add_child(_line("Destination Settlement", LABEL_COLOUR))
		details.add_child(_line(name_str, KNOWN_COLOUR))
		details.add_child(_line("Seasonal Income", LABEL_COLOUR))
		details.add_child(_line("%d gold per upkeep" % pay, KNOWN_COLOUR))
		details.add_child(_line("Remaining Contract", LABEL_COLOUR))
		details.add_child(_line("%d steps remaining" % left, KNOWN_COLOUR))
		_page.add_child(details)

	# Active Caravan Escort Status
	if Roadside.escorting(world):
		var escort_title := _line("Caravan Under Escort", HEADING_COLOUR)
		escort_title.add_theme_font_size_override("font_size", 18)
		_page.add_child(escort_title)
		var dest_site := Roadside.destination(world)
		var dest_name := dest_site.display_name if dest_site != null else "destination"
		_page.add_child(_line("Escorting wagon to %s. Patience remaining: %d steps." % [
			dest_name, int(world.escort.get("patience", 0))
		], KNOWN_COLOUR))

	# Renown & Standing on this Ground
	var renown_title := _line("Regional Renown & Standing", HEADING_COLOUR)
	renown_title.add_theme_font_size_override("font_size", 18)
	_page.add_child(renown_title)

	var here := world.player_cell
	var standing_val := Renown.standing(world, here)
	var notoriety_val := Renown.notoriety(world, here)
	var player_title := Renown.title(world, here)

	var standing_grid := GridContainer.new()
	standing_grid.columns = 2
	standing_grid.add_theme_constant_override("h_separation", 20)
	standing_grid.add_theme_constant_override("v_separation", 4)

	standing_grid.add_child(_line("Title on Current Ground", LABEL_COLOUR))
	standing_grid.add_child(_line(player_title.capitalize(), KNOWN_COLOUR))
	var earned := Names.earned_title(world)
	standing_grid.add_child(_line("Known As", LABEL_COLOUR))
	standing_grid.add_child(_line(
		Names.known_as(world, GameState.roster.player().display_name) if earned != "" else "Nothing yet",
		KNOWN_COLOUR
	))
	standing_grid.add_child(_line("Local Standing", LABEL_COLOUR))
	standing_grid.add_child(_line("%+d" % standing_val, KNOWN_COLOUR))
	standing_grid.add_child(_line("Local Notoriety", LABEL_COLOUR))
	standing_grid.add_child(_line("%d" % notoriety_val, KNOWN_COLOUR))
	standing_grid.add_child(_line("Total Deeds in Chronicle", LABEL_COLOUR))
	standing_grid.add_child(_line("%d deeds recorded" % world.deeds.size(), KNOWN_COLOUR))

	_page.add_child(standing_grid)


func _open_page(template_id: String) -> void:
	_showing = template_id
	_show_page()


func _show_page() -> void:
	_clear_page()
	if _showing == "":
		_page.add_child(_line("Nothing yet. The book fills up by being carried into fights.", LABEL_COLOUR))
		return

	var world: World = GameState.world
	var template := Database.unit_template(_showing)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	var face := TextureRect.new()
	face.custom_minimum_size = FACE_SIZE
	face.texture = Database.unit_face(_showing)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(face)

	var names := VBoxContainer.new()
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var title := _line(str(template.get("display_name", _showing)), HEADING_COLOUR)
	title.add_theme_font_size_override("font_size", 22)
	names.add_child(title)
	names.add_child(_line(str(template.get("job", "")), LABEL_COLOUR))
	head.add_child(names)
	_page.add_child(head)

	var rows := GridContainer.new()
	rows.columns = 2
	rows.add_theme_constant_override("h_separation", 20)
	rows.add_theme_constant_override("v_separation", 3)
	for row: Array in Journal.page(world, _showing):
		rows.add_child(_line(str(row[0]), LABEL_COLOUR))
		var value := str(row[1])
		rows.add_child(_line(value, UNKNOWN_COLOUR if value == Journal.UNKNOWN else KNOWN_COLOUR))
	_page.add_child(rows)

	var heading := _line("What it does", HEADING_COLOUR)
	heading.add_theme_font_size_override("font_size", 18)
	_page.add_child(heading)
	for ability: String in Journal.abilities(world, _showing):
		var unknown := ability == Journal.UNKNOWN
		_page.add_child(_line(
			"  something you have not seen" if unknown else "  %s" % ability,
			UNKNOWN_COLOUR if unknown else KNOWN_COLOUR
		))


# --- the Company: a sheet for each companion ([D66]) --------------------------------


## A companion on the left-hand page: their face and name, and a mark when a
## path or a power is owed them.
func _company_entry(member: Character) -> Button:
	var entry := Button.new()
	entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
	entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	entry.custom_minimum_size = Vector2(0, LIST_FACE + 14)
	entry.icon = Database.unit_face(member.template_id)
	entry.expand_icon = false
	entry.add_theme_constant_override("icon_max_width", LIST_FACE)
	entry.add_theme_constant_override("h_separation", 10)
	var owed := _owed_text(member)
	entry.text = "%s\nLevel %d %s%s" % [
		member.display_name, member.level, member.class_name_text(),
		"  ·  " + owed if owed != "" else "",
	]
	if member.id == _sheet_id:
		entry.add_theme_stylebox_override("normal", _pencil_box(Color(PENCIL, 0.22)))
	entry.pressed.connect(func() -> void:
		_sheet_id = member.id
		_rebuild()
	)
	Sfx.attend(entry)
	return entry


func _owed_text(member: Character) -> String:
	if member.pending_class_choice:
		return "a path to choose"
	if member.rungs > 0 and not member.trees.is_empty():
		return "a power to take" if member.rungs == 1 else "%d powers to take" % member.rungs
	return ""


## Whose sheet is open, falling back to the lead.
func _sheet_character() -> Character:
	if GameState.roster == null:
		return null
	var party := GameState.roster.party_members()
	if party.is_empty():
		return null
	for member in party:
		if member.id == _sheet_id:
			return member
	_sheet_id = party[0].id
	return party[0]


## Everything the game keeps on one companion, on one page: who they are, how
## far they have come, what their numbers are and what each level adds, what
## they carry, what they can do, and what they have learned from.
func _show_sheet() -> void:
	_clear_page()
	var character := _sheet_character()
	if character == null:
		_page.add_child(_line("Nobody walks with you.", LABEL_COLOUR))
		return
	var colour := SheetParts.colour_of(character)
	var ink_colour := colour.darkened(0.35)

	# Who they are.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	var frame := PanelContainer.new()
	var frame_box := SheetParts.box(colour.darkened(0.55), LEATHER_EDGE, 3, 8)
	frame_box.border_color = colour.darkened(0.2)
	frame.add_theme_stylebox_override("panel", frame_box)
	frame.custom_minimum_size = SHEET_FACE
	var face := TextureRect.new()
	face.texture = Database.unit_face(character.template_id)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(face)
	head.add_child(frame)

	var who := VBoxContainer.new()
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.add_theme_constant_override("separation", 4)
	var name_line := _line(character.display_name, KNOWN_COLOUR)
	name_line.add_theme_font_size_override("font_size", 30)
	who.add_child(name_line)
	var class_line := _line("Level %d  %s" % [character.level, character.class_name_text()], ink_colour)
	class_line.add_theme_font_size_override("font_size", 19)
	who.add_child(class_line)
	var bits: Array[String] = []
	if character.is_player:
		bits.append("Leads the company")
	var temper := str(Database.temper(character.temper).get("display_name", "")) if character.temper != "" else ""
	if temper != "":
		bits.append(temper)
	if character.background != "":
		bits.append(character.background_display())
	if character.creed != "":
		bits.append("Creed: %s" % character.creed_display())
	if not bits.is_empty():
		var about := _line("  ·  ".join(bits), LABEL_COLOUR)
		about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		who.add_child(about)
	who.add_child(_meter_row("Health", character.current_hp(), character.max_hp(), Color(0.66, 0.18, 0.14)))
	who.add_child(_meter_row("Experience", character.xp, Progression.xp_to_next(character.level), ink_colour))
	head.add_child(who)
	_page.add_child(head)

	var owed := _owed_text(character)
	if owed != "":
		_page.add_child(_owed_callout(character, owed))

	# Their numbers, and what a level adds.
	var middle := HBoxContainer.new()
	middle.add_theme_constant_override("separation", 30)
	var numbers := VBoxContainer.new()
	numbers.add_theme_constant_override("separation", 4)
	numbers.add_child(_section("Attributes"))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 3)
	var growth: Dictionary = character.class_data().get("growth", {})
	for row: Array in [
		["Health", character.max_hp(), "max_hp"],
		["Attack", character.attack(), "attack"],
		["Guard", character.defense(), "defense"],
		["Speed", character.speed(), "speed"],
		["Move", character.move_points(), ""],
		["Jump", character.jump(), ""],
	]:
		grid.add_child(_line(str(row[0]), LABEL_COLOUR))
		var value := _line(str(row[1]), KNOWN_COLOUR)
		value.add_theme_font_size_override("font_size", 18)
		grid.add_child(value)
		var per := float(growth.get(str(row[2]), 0.0))
		grid.add_child(_line("+%s a level" % String.num(per, 1) if per > 0.0 else "", ink_colour))
	if character.flash_step() > 0:
		grid.add_child(_line("Flash step", LABEL_COLOUR))
		grid.add_child(_line("%d tiles" % character.flash_step(), KNOWN_COLOUR))
		grid.add_child(_line("", LABEL_COLOUR))
	numbers.add_child(grid)
	middle.add_child(numbers)

	var path_box := VBoxContainer.new()
	path_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_box.add_theme_constant_override("separation", 6)
	path_box.add_child(_section("The path"))
	if character.class_id == "":
		var wait := _line("No path yet. One is chosen at level %d." % Progression.CLASS_LEVEL, LABEL_COLOUR)
		wait.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		path_box.add_child(wait)
	else:
		path_box.add_child(SheetParts.growth_bars(character.class_id, LABEL_COLOUR, TRACK))
		var themes := _line("Powers of %s" % "  ·  ".join(SheetParts.theme_names(character.class_id)), LABEL_COLOUR)
		themes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		path_box.add_child(themes)
	middle.add_child(path_box)
	_page.add_child(middle)

	# What they carry.
	_page.add_child(_section("Carried"))
	var in_hand := character.equipment if character.equipment != "" else Gear.issued_id(character)
	_page.add_child(_line(
		"%s  —  %s" % [Gear.display_name(in_hand), Gear.summary(in_hand, character)] if in_hand != "" else "Empty hands.",
		KNOWN_COLOUR
	))
	for charm_id: String in character.charms:
		_page.add_child(_line("%s  —  %s" % [Gear.display_name(charm_id), Gear.summary(charm_id, character)], KNOWN_COLOUR))
	if character.yoke:
		_page.add_child(_line("Wears the Training Yoke: less attack, more experience.", LABEL_COLOUR))

	# What they can do.
	_page.add_child(_section("Powers"))
	var grants: Array = character.class_data().get("grants", [])
	for ability_id: String in character.abilities():
		var ability := Database.ability(ability_id)
		var whence := "learned on the path" if ability_id in character.learned \
				else ("from the %s" % character.class_name_text() if ability_id in grants else "their own")
		var line := _line("%s  —  %s  (%s)" % [
			ability.get("display_name", ability_id), SheetParts.ability_shape(ability), whence
		], KNOWN_COLOUR)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_page.add_child(line)
	if character.trees.is_empty() and character.level < Progression.FIRST_TREE_LEVEL:
		_page.add_child(_line("Their first tree of powers uncovers at level %d." % Progression.FIRST_TREE_LEVEL, LABEL_COLOUR))

	# What they have read, and what they have learned from.
	if not character.doctrine.is_empty():
		_page.add_child(_section("Read"))
		var titles: Array[String] = []
		for doctrine_id: String in character.doctrine:
			titles.append(Doctrine.title(doctrine_id))
		var read := _line("  ·  ".join(titles), KNOWN_COLOUR)
		read.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_page.add_child(read)
	_page.add_child(_section("Learned from"))
	if character.beaten.is_empty():
		_page.add_child(_line("Nothing yet. The first of each kind they help put down teaches them.", LABEL_COLOUR))
	else:
		var kinds: Array[String] = []
		for kind: String in character.beaten:
			kinds.append(str(Database.unit_template(kind).get("display_name", kind)))
		var learned := _line("%d kinds: %s" % [kinds.size(), ", ".join(kinds)], KNOWN_COLOUR)
		learned.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_page.add_child(learned)


## A heading on a sheet, with a pencil rule under it.
func _section(text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var title := _line(text, HEADING_COLOUR)
	title.add_theme_font_size_override("font_size", 18)
	box.add_child(title)
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 1)
	rule.color = PENCIL
	box.add_child(rule)
	return box


func _meter_row(label: String, value: int, most: int, fill: Color) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var name_line := _line(label, LABEL_COLOUR)
	name_line.custom_minimum_size = Vector2(96, 0)
	row.add_child(name_line)
	var meter := SheetParts.bar(float(value) / float(maxi(1, most)), fill, TRACK, Vector2(220, 12))
	meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(meter)
	row.add_child(_line("%d / %d" % [value, most], KNOWN_COLOUR))
	return row


## The one thing on a sheet that can be pressed: a path or a power owed, and
## the way to the party screen where it is chosen.
func _owed_callout(character: Character, owed: String) -> Control:
	var callout := PanelContainer.new()
	var box := SheetParts.box(Color(RIBBONS[Tab.SHEET], 0.12), RIBBONS[Tab.SHEET], 2, 6)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	callout.add_theme_stylebox_override("panel", box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var said := _line("%s has %s." % [character.display_name, owed], HEADING_COLOUR)
	said.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	said.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(said)
	var go := Button.new()
	go.text = "Choose it"
	go.custom_minimum_size = Vector2(120, 40)
	_ribbon_dress(go, RIBBONS[Tab.SHEET], true)
	go.pressed.connect(func() -> void:
		close()
		EventBus.growth_choice_requested.emit(character)
	)
	Sfx.attend(go)
	row.add_child(go)
	callout.add_child(row)
	return callout


func _clear_page() -> void:
	for child in _page.get_children():
		_page.remove_child(child)
		child.queue_free()


# --- the binding ([D66]) ----------------------------------------------------------


## Leather round the outside, two parchment leaves inside with the spine between,
## ribbons for tabs, and ink for every word on the pages.
func _dress_book() -> void:
	var cover := SheetParts.box(LEATHER, LEATHER_EDGE, 6, 16)
	cover.content_margin_left = 22
	cover.content_margin_right = 22
	cover.content_margin_top = 14
	cover.content_margin_bottom = 12
	cover.shadow_color = Color(0, 0, 0, 0.6)
	cover.shadow_size = 26
	_book.add_theme_stylebox_override("panel", cover)

	var left := SheetParts.box(PARCHMENT, PAGE_EDGE, 1, 10)
	left.corner_radius_top_right = 0
	left.corner_radius_bottom_right = 0
	left.border_width_right = 8
	left.border_color = PAGE_EDGE
	left.content_margin_left = 22
	left.content_margin_right = 18
	left.content_margin_top = 18
	left.content_margin_bottom = 18
	# The page darkens towards the gutter, the way a bound page does.
	left.border_blend = true
	_left_leaf.add_theme_stylebox_override("panel", left)

	var right := SheetParts.box(PARCHMENT_FACING, PAGE_EDGE, 1, 10)
	right.corner_radius_top_left = 0
	right.corner_radius_bottom_left = 0
	right.border_width_left = 8
	right.content_margin_left = 26
	right.content_margin_right = 24
	right.content_margin_top = 18
	right.content_margin_bottom = 18
	right.border_blend = true
	_right_leaf.add_theme_stylebox_override("panel", right)

	var spine := StyleBoxFlat.new()
	spine.bg_color = SPINE
	spine.border_color = GUTTER.darkened(0.5)
	spine.border_width_left = 1
	spine.border_width_right = 1
	_spine.add_theme_stylebox_override("panel", spine)

	var ink := _ink_theme()
	_left_leaf.theme = ink
	_right_leaf.theme = ink

	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(BOOK_FACES)
	_book.add_theme_font_override("font", serif)
	for label: Label in [_title, _fullness, _footer]:
		label.add_theme_font_override("font", serif)
	_title.add_theme_color_override("font_color", TOOLED_GOLD)
	_title.add_theme_constant_override("outline_size", 3)
	_title.add_theme_color_override("font_outline_color", LEATHER_EDGE)

	var tabs := %Tabs as HBoxContainer
	tabs.add_theme_constant_override("separation", 6)
	(tabs.get_parent() as VBoxContainer).add_theme_constant_override("separation", 0)
	_ribbon_dress(_close_btn, LEATHER.lightened(0.12), true)
	_close_btn.add_theme_font_override("font", serif)
	_ribbon_dress(_map_btn, MAP_RIBBON, false)


## Ink for the leaves: every label, and the plain buttons the lists are made of,
## which read as entries written on the page rather than grey keys.
func _ink_theme() -> Theme:
	var ink := Theme.new()
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(BOOK_FACES)
	ink.default_font = serif
	ink.default_font_size = 17
	ink.set_color("font_color", "Label", KNOWN_COLOUR)
	# The game's own theme rings its words in black so they read over the
	# world; on a page that is a smudge.
	ink.set_constant("outline_size", "Label", 0)
	ink.set_constant("outline_size", "Button", 0)
	var plain := StyleBoxEmpty.new()
	plain.content_margin_left = 8
	plain.content_margin_right = 8
	plain.content_margin_top = 5
	plain.content_margin_bottom = 5
	ink.set_stylebox("normal", "Button", plain)
	ink.set_stylebox("hover", "Button", _pencil_box(Color(PENCIL, 0.28)))
	ink.set_stylebox("pressed", "Button", _pencil_box(Color(PENCIL, 0.4)))
	ink.set_stylebox("focus", "Button", _pencil_box(Color(0, 0, 0, 0), PENCIL))
	ink.set_stylebox("disabled", "Button", plain)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		ink.set_color(state, "Button", KNOWN_COLOUR)
	ink.set_color("font_disabled_color", "Button", UNKNOWN_COLOUR)
	var line := StyleBoxLine.new()
	line.color = PENCIL
	line.thickness = 1
	ink.set_stylebox("separator", "HSeparator", line)
	ink.set_constant("separation", "HSeparator", 10)
	var grabber := SheetParts.box(PENCIL, Color(0, 0, 0, 0), 0, 4)
	var groove := StyleBoxFlat.new()
	groove.bg_color = Color(PENCIL, 0.12)
	groove.set_corner_radius_all(4)
	for part: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
		ink.set_stylebox(part, "VScrollBar", grabber)
	ink.set_stylebox("scroll", "VScrollBar", groove)
	return ink


func _pencil_box(fill: Color, edge: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var box := SheetParts.box(fill, edge, 1 if edge.a > 0.0 else 0, 4)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 5
	box.content_margin_bottom = 5
	return box


## A tab as a silk ribbon. The open one stands brighter and taller, as if it were
## the ribbon the book was opened at.
func _ribbon_dress(button: Button, colour: Color, raised: bool) -> void:
	var face := SheetParts.box(colour if raised else colour.darkened(0.35), colour.darkened(0.55), 1, 0)
	face.corner_radius_top_left = 6
	face.corner_radius_top_right = 6
	face.content_margin_left = 14
	face.content_margin_right = 14
	face.content_margin_top = 10 if raised else 6
	face.content_margin_bottom = 6
	var lit := face.duplicate() as StyleBoxFlat
	lit.bg_color = colour.lightened(0.15)
	for state: String in ["normal", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, face)
	button.add_theme_stylebox_override("hover", lit)
	button.add_theme_stylebox_override("pressed", lit)
	var text := Color(0.99, 0.95, 0.85) if raised else Color(0.93, 0.86, 0.72, 0.85)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, text)
	button.size_flags_vertical = Control.SIZE_SHRINK_END


func _mark_ribbons() -> void:
	var buttons := {
		Tab.SHEET: _sheet_btn, Tab.BESTIARY: _bestiary_btn, Tab.ROUTES: _routes_btn,
		Tab.ANNALS: _annals_btn, Tab.QUESTS: _quests_btn,
	}
	for tab: Tab in buttons:
		_ribbon_dress(buttons[tab], RIBBONS[tab], tab == _tab)


func _line(text: String, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", colour)
	return label
