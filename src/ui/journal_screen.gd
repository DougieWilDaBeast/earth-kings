class_name JournalScreen
extends CanvasLayer
## The book of what you have met.
##
## A page is opened by standing across a field from something, and it opens
## nearly blank. Every question mark on it is a thing you have not earned yet:
## fight it, take a blow from it, put one down, and the line fills itself in.
##
## Read-only. Nothing on this screen can be spent, chosen or missed.

signal closed

enum Tab { BESTIARY, ROUTES, ANNALS }

const UNKNOWN_COLOUR := Color(0.42, 0.40, 0.38)
const KNOWN_COLOUR := Color(0.90, 0.87, 0.79)
const LABEL_COLOUR := Color(0.66, 0.64, 0.59)
const HEADING_COLOUR := Color(0.96, 0.83, 0.44)
const FACE_SIZE := Vector2(96, 96)

@onready var _backdrop: ColorRect = %Backdrop
@onready var _fullness: Label = %FullnessLabel
@onready var _list: VBoxContainer = %EntryList
@onready var _page: VBoxContainer = %Page
@onready var _bestiary_btn: Button = %BestiaryButton
@onready var _routes_btn: Button = %RoutesButton
@onready var _annals_btn: Button = %AnnalsButton

var _showing: String = ""
var _tab: Tab = Tab.BESTIARY
var _selected_route_idx: int = 0


func _ready() -> void:
	_backdrop.hide()
	add_to_group(EventBus.MODAL_OVERLAY_GROUP)
	EventBus.journal_requested.connect(open)
	_bestiary_btn.pressed.connect(func() -> void: _set_tab(Tab.BESTIARY))
	_routes_btn.pressed.connect(func() -> void: _set_tab(Tab.ROUTES))
	_annals_btn.pressed.connect(func() -> void: _set_tab(Tab.ANNALS))
	Sfx.attend(_bestiary_btn)
	Sfx.attend(_routes_btn)
	Sfx.attend(_annals_btn)


func _set_tab(tab: Tab) -> void:
	_tab = tab
	_rebuild()


func is_open() -> bool:
	return _backdrop.visible


func open() -> void:
	_backdrop.show()
	_rebuild()


func close() -> void:
	_backdrop.hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_N):
		get_viewport().set_input_as_handled()
		close()


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	var world: World = GameState.world
	if world == null:
		return

	if _tab == Tab.BESTIARY:
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


func _show_annals_page() -> void:
	for child in _page.get_children():
		child.queue_free()
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
	for child in _page.get_children():
		child.queue_free()
	var world: World = GameState.world
	if world == null:
		return

	var routes_title := _line("Trade Routes", HEADING_COLOUR)
	routes_title.add_theme_font_size_override("font_size", 22)
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
	for child in _page.get_children():
		child.queue_free()
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


func _line(text: String, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", colour)
	return label
