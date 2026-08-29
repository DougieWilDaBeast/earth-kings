extends Node2D
## Travel map between battles: nodes you can walk to along connections, each
## able to trigger a conversation and/or a battle on arrival.
##
## Nothing here teleports. Leaving a place puts the party on the road between
## it and the next one, and they only get there by being walked there.

const NODE_RADIUS := 16.0
const CLICK_RADIUS := 26.0
## How fast the party crosses the map, in pixels a second.
const WALK_SPEED := 95.0
## How square-on to a road you have to be pointing before the party takes it.
const HEADING_TOLERANCE := 0.35

var boot_payload: Dictionary = {}

@onready var camera: CameraRig = $Camera2D
@onready var _title: Label = %TitleLabel
@onready var _party: Label = %PartyLabel
@onready var _hint: Label = %HintLabel

var _locations: Dictionary = {}
var _hovered: String = ""

## Exactly where the party is standing, which is usually not on top of anything.
var _party_pos: Vector2 = Vector2.ZERO
## The road under their feet. Both empty while they are stood at a place.
var _road_from: String = ""
var _road_to: String = ""
var _road_progress: float = 0.0
## +1 or -1 while the party is walking a clicked route on their own; 0 while the
## player is steering them by hand.
var _auto_pace: float = 0.0
## Arrivals take over: no walking under a conversation or into a loading battle.
var _busy: bool = false


func _ready() -> void:
	_locations = Database.overworld.get("locations", {})
	_party_pos = _position_of(GameState.current_location)
	camera.frame(_map_bounds())
	camera.focus_on(_party_pos, true)
	_refresh_labels()
	_arrive(GameState.current_location)


## The box every place on the map fits inside, so the camera can hold it all.
func _map_bounds() -> Rect2:
	var bounds := Rect2()
	var started := false
	for id: String in _locations:
		if started:
			bounds = bounds.expand(_position_of(id))
		else:
			bounds = Rect2(_position_of(id), Vector2.ZERO)
			started = true
	return bounds


func _arrive(location_id: String) -> void:
	_busy = true
	await get_tree().process_frame
	var location: Dictionary = _locations.get(location_id, {})
	_refresh_labels()

	var dialogue_id: String = location.get("dialogue", "")
	if dialogue_id != "" and not GameState.has_flag("seen:" + dialogue_id):
		GameState.set_flag("seen:" + dialogue_id)
		EventBus.dialogue_requested.emit(dialogue_id)
		await EventBus.dialogue_finished

	if location.get("rest", false) and GameState.party_is_wounded():
		GameState.heal_party()
		_refresh_labels()
		_hint.text = "The party rests at %s and recovers." % location.get("name", location_id)

	var battle_map: String = location.get("battle", "")
	if battle_map != "" and not GameState.is_battle_cleared(battle_map):
		EventBus.request_scene.emit("battle", {"map_id": battle_map})
		return
	_busy = false


# --- walking ------------------------------------------------------------------


func _process(delta: float) -> void:
	if _busy or _overlay_open():
		return
	var heading := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _road_to == "":
		_set_out(heading)
	else:
		_walk(heading, delta)


## Step off a place onto whichever road lies the way you are pointing.
func _set_out(heading: Vector2) -> void:
	if heading == Vector2.ZERO:
		return
	var road := _road_towards(heading)
	if road == "":
		return
	_road_from = GameState.current_location
	_road_to = road
	_road_progress = 0.0
	_auto_pace = 0.0
	_refresh_labels()


func _walk(heading: Vector2, delta: float) -> void:
	var from := _position_of(_road_from)
	var to := _position_of(_road_to)
	var length := maxf(from.distance_to(to), 1.0)
	# Taking hold of the keys stops the party walking themselves anywhere.
	if heading != Vector2.ZERO:
		_auto_pace = 0.0
	var pace := _auto_pace if _auto_pace != 0.0 else heading.dot((to - from).normalized())
	if absf(pace) < HEADING_TOLERANCE:
		return

	_road_progress = clampf(_road_progress + signf(pace) * WALK_SPEED * delta / length, 0.0, 1.0)
	_party_pos = from.lerp(to, _road_progress)
	camera.focus_on(_party_pos)
	_refresh_labels()
	queue_redraw()

	if _road_progress >= 1.0:
		_reach(_road_to)
	elif _road_progress <= 0.0:
		_reach(_road_from)


## The road ends. Coming back the way you came is not an arrival — you never
## left, as far as the world is concerned.
func _reach(location_id: String) -> void:
	var turned_back := location_id == _road_from
	_road_from = ""
	_road_to = ""
	_road_progress = 0.0
	_auto_pace = 0.0
	_party_pos = _position_of(location_id)
	camera.focus_on(_party_pos)
	queue_redraw()
	if turned_back:
		_refresh_labels()
		return
	GameState.previous_location = GameState.current_location
	GameState.current_location = location_id
	_arrive(location_id)


## Pick the connected place lying that way, so the map can be walked by keyboard.
func _road_towards(heading: Vector2) -> String:
	var here := _position_of(GameState.current_location)
	var best := ""
	# Anything less than this is more sideways than it is in the direction asked for.
	var best_score := HEADING_TOLERANCE
	for id: String in _locations.get(GameState.current_location, {}).get("connections", []):
		if not _locations.has(id):
			continue
		var score := (_position_of(id) - here).normalized().dot(heading)
		if score > best_score:
			best_score = score
			best = id
	return best


## Send the party off by themselves, for players who would rather click.
func _travel_to(location_id: String) -> void:
	if _busy:
		return
	if _road_to != "":
		if location_id == _road_to:
			_auto_pace = 1.0
		elif location_id == _road_from:
			_auto_pace = -1.0
		return
	if not _can_travel_to(location_id):
		return
	_road_from = GameState.current_location
	_road_to = location_id
	_road_progress = 0.0
	_auto_pace = 1.0
	_refresh_labels()


func _can_travel_to(location_id: String) -> bool:
	if _road_to != "":
		return location_id == _road_to or location_id == _road_from
	var here: Dictionary = _locations.get(GameState.current_location, {})
	return location_id in here.get("connections", [])


func _overlay_open() -> bool:
	for overlay in get_tree().get_nodes_in_group(EventBus.MODAL_OVERLAY_GROUP):
		if overlay.is_open():
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		EventBus.system_menu_requested.emit()
	elif event is InputEventMouseMotion:
		var hovered := _location_at(get_global_mouse_position())
		if hovered != _hovered:
			_hovered = hovered
			_refresh_labels()
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked := _location_at(get_global_mouse_position())
		if clicked != "":
			get_viewport().set_input_as_handled()
			_travel_to(clicked)
	elif event.is_action_pressed("ui_accept") and _hovered != "":
		get_viewport().set_input_as_handled()
		_travel_to(_hovered)


func _location_at(pos: Vector2) -> String:
	for id: String in _locations:
		if _position_of(id).distance_to(pos) <= CLICK_RADIUS:
			return id
	return ""


func _position_of(location_id: String) -> Vector2:
	var pair: Array = _locations.get(location_id, {}).get("pos", [0, 0])
	return Vector2(pair[0], pair[1])


func _refresh_labels() -> void:
	var here: Dictionary = _locations.get(GameState.current_location, {})
	_party.text = _party_summary()

	if _road_to != "":
		_title.text = "On the road to %s  ·  %d%%  ·  %d gold" % [
			_name_of(_road_to), roundi(_road_progress * 100.0), GameState.gold
		]
		_hint.text = "Hold a direction to walk on, or the other way to turn back to %s." % _name_of(_road_from)
		return

	_title.text = "%s  ·  %d gold" % [here.get("name", "Unknown"), GameState.gold]
	if _hovered == "" or _hovered == GameState.current_location:
		_hint.text = "Hold WASD to walk a road out of here, or click where you want to go.  ·  Esc for the menu."
	elif _can_travel_to(_hovered):
		_hint.text = "Set out for %s  ·  Enter" % _name_of(_hovered)
	else:
		_hint.text = "%s is not reachable from here." % _name_of(_hovered)


func _name_of(location_id: String) -> String:
	return _locations.get(location_id, {}).get("name", location_id)


func _party_summary() -> String:
	var entries: Array[String] = []
	for character in GameState.roster.party_members():
		entries.append("%s  L%d  %d/%d" % [
			character.display_name, character.level, character.current_hp(), character.max_hp()
		])
	return "  ·  ".join(entries)


func _draw() -> void:
	for id: String in _locations:
		for other: String in _locations[id].get("connections", []):
			if _locations.has(other):
				draw_line(_position_of(id), _position_of(other), Color(0.4, 0.42, 0.5), 3.0)

	# The stretch of road already under their boots, so progress is visible.
	if _road_to != "":
		draw_line(_position_of(_road_from), _party_pos, Color(0.95, 0.78, 0.32), 4.0)

	for id: String in _locations:
		draw_circle(_position_of(id), NODE_RADIUS, _colour_for(id))
		if id == _hovered:
			draw_arc(_position_of(id), NODE_RADIUS + 5.0, 0.0, TAU, 32, Color.WHITE, 2.0, true)
		var label: String = _locations[id].get("name", id)
		draw_string(
			ThemeDB.fallback_font,
			_position_of(id) + Vector2(-40, NODE_RADIUS + 20),
			label,
			HORIZONTAL_ALIGNMENT_CENTER,
			80,
			14
		)

	draw_circle(_party_pos, 7.0, Color(0.98, 0.95, 0.85))
	draw_arc(_party_pos, 7.0, 0.0, TAU, 20, Color(0.12, 0.12, 0.15), 2.0, true)


func _colour_for(location_id: String) -> Color:
	if location_id == GameState.current_location and _road_to == "":
		return Color(0.95, 0.78, 0.32)
	var battle_map: String = _locations[location_id].get("battle", "")
	if battle_map != "" and not GameState.is_battle_cleared(battle_map):
		return Color(0.8, 0.34, 0.34)
	if _can_travel_to(location_id):
		return Color(0.45, 0.72, 0.95)
	return Color(0.35, 0.37, 0.44)
