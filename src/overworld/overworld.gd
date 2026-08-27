extends Node2D
## Travel map between battles: nodes you can walk to along connections, each
## able to trigger a conversation and/or a battle on arrival.

const NODE_RADIUS := 16.0
const CLICK_RADIUS := 26.0

var boot_payload: Dictionary = {}

@onready var camera: Camera2D = $Camera2D
@onready var _title: Label = %TitleLabel
@onready var _hint: Label = %HintLabel

var _locations: Dictionary = {}
var _hovered: String = ""


func _ready() -> void:
	_locations = Database.overworld.get("locations", {})
	camera.position = Vector2(640, 360)
	camera.enabled = true
	_refresh_labels()
	_arrive(GameState.current_location)


func _arrive(location_id: String) -> void:
	await get_tree().process_frame
	var location: Dictionary = _locations.get(location_id, {})
	_refresh_labels()

	var dialogue_id: String = location.get("dialogue", "")
	if dialogue_id != "" and not GameState.has_flag("seen:" + dialogue_id):
		GameState.set_flag("seen:" + dialogue_id)
		EventBus.dialogue_requested.emit(dialogue_id)
		await EventBus.dialogue_finished

	var battle_map: String = location.get("battle", "")
	if battle_map != "" and not GameState.is_battle_cleared(battle_map):
		EventBus.request_scene.emit("battle", {"map_id": battle_map})


func _travel_to(location_id: String) -> void:
	if not _can_travel_to(location_id):
		return
	GameState.previous_location = GameState.current_location
	GameState.current_location = location_id
	queue_redraw()
	_arrive(location_id)


func _can_travel_to(location_id: String) -> bool:
	var here: Dictionary = _locations.get(GameState.current_location, {})
	return location_id in here.get("connections", [])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
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


func _location_at(pos: Vector2) -> String:
	for id: String in _locations:
		if _position_of(id).distance_to(pos) <= CLICK_RADIUS:
			return id
	return ""


func _position_of(location_id: String) -> Vector2:
	var pair: Array = _locations[location_id].get("pos", [0, 0])
	return Vector2(pair[0], pair[1])


func _refresh_labels() -> void:
	var here: Dictionary = _locations.get(GameState.current_location, {})
	_title.text = "%s  ·  %d gold" % [here.get("name", "Unknown"), GameState.gold]
	if _hovered == "":
		_hint.text = "Click a connected location to travel."
	elif _hovered == GameState.current_location:
		_hint.text = "You are here."
	elif _can_travel_to(_hovered):
		_hint.text = "Travel to %s" % _locations[_hovered].get("name", _hovered)
	else:
		_hint.text = "%s is not reachable from here." % _locations[_hovered].get("name", _hovered)


func _draw() -> void:
	for id: String in _locations:
		for other: String in _locations[id].get("connections", []):
			if _locations.has(other):
				draw_line(_position_of(id), _position_of(other), Color(0.4, 0.42, 0.5), 3.0)

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


func _colour_for(location_id: String) -> Color:
	if location_id == GameState.current_location:
		return Color(0.95, 0.78, 0.32)
	var battle_map: String = _locations[location_id].get("battle", "")
	if battle_map != "" and not GameState.is_battle_cleared(battle_map):
		return Color(0.8, 0.34, 0.34)
	if _can_travel_to(location_id):
		return Color(0.45, 0.72, 0.95)
	return Color(0.35, 0.37, 0.44)
