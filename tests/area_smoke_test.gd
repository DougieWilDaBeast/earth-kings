extends Node
## Boots every area in `data/areas` and walks the party around inside one, so
## a broken tileset, legend or exit shows up without opening the editor.
##
##   godot --headless --path . res://tests/area_smoke_test.tscn

const SEED := 20260829
const AREAS := [
	"village", "village_inn",
	"village_fen", "fen_alehouse",
	"village_pines", "pine_longhouse",
	"village_shore", "shore_taphouse",
	"keep", "keep_hall",
	"keep_thorn", "thorn_hall",
	"library", "gate", "hut", "tower", "home",
	"camp",
]
## Longest a staged meeting is allowed to take before the talking starts.
const CUTSCENE_PATIENCE := 20.0

var _requests: Array[Dictionary] = []
var _failures: Array[String] = []
## Conversations the area asked for, in order. A lambda captures a local by
## value, so the signal has to land on the node itself.
var _opened: Array[String] = []


func _ready() -> void:
	GameState.new_game(SEED)
	EventBus.request_scene.connect(
		func(key: String, payload: Dictionary) -> void:
			_requests.append({ "key": key, "payload": payload })
	)
	# The letterbox normally lives in main.tscn; a cutscene needs it to play into.
	add_child(load("res://src/ui/cutscene_layer.tscn").instantiate())

	for area_id in AREAS:
		await _check_area(area_id)
	await _check_camp()

	print("")
	if _failures.is_empty():
		print("area smoke test: PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			print("FAIL: %s" % failure)
		get_tree().quit(1)


func _check_area(area_id: String) -> void:
	var map := AreaMap.load_area(area_id)
	if map == null:
		_fail("%s: no such area" % area_id)
		return
	if map.width == 0 or map.height == 0:
		_fail("%s: empty grid" % area_id)
	if not map.is_walkable(map.spawn):
		_fail("%s: the party spawns inside a wall" % area_id)
	for exit_cell in map.exits:
		if not map.is_walkable(exit_cell):
			_fail("%s: exit %s cannot be reached" % [area_id, exit_cell])
	for cell: Vector2i in map.spots:
		if not map.is_walkable(cell):
			_fail("%s: spot %s cannot be stood on" % [area_id, cell])
	for person: Dictionary in map.people:
		_check_person(area_id, map, person)
	for building: Dictionary in map.buildings:
		_check_building(area_id, map, building)

	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": area_id, "return_scene": "world" })
	add_child(scene)
	await get_tree().process_frame

	var painted := 0
	for layer in scene.get_node("Layers").get_children():
		painted += (layer as TileMapLayer).get_used_cells().size()
	if painted == 0:
		_fail("%s: nothing was painted" % area_id)
	# The y-sorted layer holds scenery too, so count only the people in it.
	var arrived := scene.get_node("Actors").get_children().filter(
		func(node: Node) -> bool: return node is AreaActor
	).size()
	var expected := GameState.party_characters().size() + map.people.size()
	if arrived != expected:
		_fail("%s: %d actors turned up, expected %d" % [area_id, arrived, expected])

	await _check_talking(scene, area_id)
	_walk_in(scene, map)
	_walk_out(scene, map)
	scene.queue_free()
	await get_tree().process_frame


## A door has to be on the house it belongs to, and lead somewhere real.
func _check_building(area_id: String, map: AreaMap, building: Dictionary) -> void:
	var who: String = building.get("name", "a house")
	var door: Vector2i = building["door"]
	if not AreaMap.footprint(building).has_point(door):
		_fail("%s: the door of %s is not on it" % [area_id, who])
	if not map.is_walkable(door):
		_fail("%s: the door of %s cannot be reached" % [area_id, who])
	if not Database.has_area(building.get("area", "")):
		_fail("%s: %s has no inside to walk into" % [area_id, who])
	if map.step_out_of(building) == door:
		_fail("%s: coming out of %s puts you back in the doorway" % [area_id, who])
	for cell: Vector2i in map.spots:
		if map.building_at(cell) == building:
			_fail("%s: a spot is buried under %s" % [area_id, who])
	for cell: Vector2i in map.chests:
		if map.building_at(cell) == building:
			_fail("%s: a chest is buried under %s" % [area_id, who])


## Standing on a door should hand play to the area behind it, and leave a way back.
func _walk_in(scene: Node, map: AreaMap) -> void:
	if map.buildings.is_empty():
		return
	var building: Dictionary = map.buildings[0]
	_requests.clear()
	scene.call("_arrive_at", building["door"])
	if _requests.is_empty() or _requests[0]["key"] != "area":
		_fail("%s: the door of %s opens on nothing" % [map.id, building.get("name", "a house")])
		return
	var payload: Dictionary = _requests[0]["payload"]
	if payload.get("area_id", "") != building.get("area", ""):
		_fail("%s: the door leads to '%s'" % [map.id, payload.get("area_id", "")])
	var back: Dictionary = payload.get("return_payload", {})
	if back.get("area_id", "") != map.id:
		_fail("%s: there is no way back out of %s" % [map.id, building.get("name", "a house")])
	if AreaMap.to_cell(back.get("spawn_cell", [])) == Vector2i(building["door"]):
		_fail("%s: leaving %s drops you straight back inside" % [map.id, building.get("name", "a house")])
	scene.set("_leaving", false)


## Walking onto an exit should hand play back to the scene that sent us here.
func _walk_out(scene: Node, map: AreaMap) -> void:
	_requests.clear()
	scene.call("_arrive_at", map.exits[0])
	if _requests.is_empty() or _requests[0]["key"] != "world":
		_fail("%s: the road out leads nowhere" % map.id)


## Everybody standing about has to be reachable and have something to say.
func _check_person(area_id: String, map: AreaMap, person: Dictionary) -> void:
	var cell := AreaMap.to_cell(person.get("cell", [0, 0]))
	var who: String = person.get("name", "someone")
	if not map.is_walkable(cell):
		_fail("%s: %s is standing in a wall" % [area_id, who])
	if Database.unit_template(person.get("unit", "")).is_empty():
		_fail("%s: %s has no unit template to be drawn from" % [area_id, who])

	var dialogue_id: String = person.get("dialogue", "")
	if dialogue_id == "":
		# Background townsfolk are not mute: they mutter as they go about.
		if person.get("chatter", []).is_empty():
			_fail("%s: %s has nothing to say" % [area_id, who])
	elif DialogueScript.nodes(dialogue_id).is_empty():
		_fail("%s: %s has nothing to say" % [area_id, who])
	elif not DialogueScript.nodes(dialogue_id).has(DialogueScript.start_id(dialogue_id)):
		_fail("%s: %s opens on a node that is not there" % [area_id, who])
	for node_id: String in DialogueScript.nodes(dialogue_id):
		_check_replies(area_id, who, dialogue_id, DialogueScript.nodes(dialogue_id)[node_id])

	var cutscene_id: String = person.get("cutscene", "")
	if cutscene_id != "" and Database.cutscene(cutscene_id).is_empty():
		_fail("%s: %s's cutscene '%s' has no beats" % [area_id, who, cutscene_id])


## Every reply and every branch of a check has to land on a real node.
func _check_replies(area_id: String, who: String, dialogue_id: String, node: Dictionary) -> void:
	var nodes := DialogueScript.nodes(dialogue_id)
	var targets: Array[String] = []
	for option: Dictionary in node.get("options", []):
		targets.append(option.get("goto", DialogueScript.END))
		var check: Dictionary = option.get("check", {})
		if not check.is_empty():
			targets.append(check.get("success", DialogueScript.END))
			targets.append(check.get("failure", DialogueScript.END))
	for target in targets:
		if target != DialogueScript.END and not nodes.has(target):
			_fail("%s: %s has a reply going nowhere ('%s')" % [area_id, who, target])


## Pressing talk should stage the meeting and then open the dialogue box.
func _check_talking(scene: Node, area_id: String) -> void:
	var map: AreaMap = scene.get("map")
	if map.people.is_empty():
		return
	# People who seat themselves talk banter, which is checked at the fire.
	if map.people[0].get("dialogue", "") == "":
		return

	_opened.clear()
	var watch := func(id: String) -> void: _opened.append(id)
	EventBus.dialogue_requested.connect(watch)
	scene.call("_speak_to", 0)
	await get_tree().process_frame

	var person: Dictionary = map.people[0]
	var frame := get_tree().get_first_node_in_group(EventBus.CUTSCENE_FRAME_GROUP)
	if person.get("cutscene", "") != "":
		if frame == null:
			_fail("%s: there is no letterbox for a cutscene to play into" % area_id)
		elif not frame.is_open():
			_fail("%s: the bars never came in for the cutscene" % area_id)
		if not _opened.is_empty():
			_fail("%s: the conversation started before the cutscene did" % area_id)

	# The beats run on timers, so wait them out rather than guessing their length.
	var patience := get_tree().create_timer(CUTSCENE_PATIENCE)
	while _opened.is_empty() and patience.time_left > 0.0:
		await get_tree().process_frame
	EventBus.dialogue_requested.disconnect(watch)

	if _opened.is_empty() or _opened[0] != person.get("dialogue", ""):
		_fail("%s: the cutscene never handed over to %s's conversation" % [
			area_id, person.get("name", "someone")
		])
		return
	if frame != null and frame.is_open():
		_fail("%s: the bars were still up when the talking started" % area_id)
	print("%s: %s staged the meeting, then opened '%s'" % [
		area_id, person.get("cutscene", ""), _opened[0]
	])


## The fire seats the party itself: nobody is authored into it, and speaking to
## one of your own is banter rather than a written conversation.
func _check_camp() -> void:
	var map := AreaMap.load_area("camp")
	if map.is_walkable(map.fire):
		_fail("camp: the fire can be walked into")
	if map.seats.size() < Roster.MAX_PARTY - 1:
		_fail("camp: %d seats for a party of %d" % [map.seats.size(), Roster.MAX_PARTY])
	for seat in map.seats:
		if not map.is_walkable(seat):
			_fail("camp: seat %s is not on ground anybody can sit on" % seat)

	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "camp", "return_scene": "world" })
	add_child(scene)
	await get_tree().process_frame

	var expected := GameState.party_characters().size() - 1
	var seated: Array = scene.get("_people")
	if seated.size() != expected:
		_fail("camp: %d of %d sat down at the fire" % [seated.size(), expected])
	elif expected > 0:
		await _check_fireside(scene)
	scene.queue_free()
	await get_tree().process_frame


func _check_fireside(scene: Node) -> void:
	# The opening cutscene has the scene until it is done with it.
	var patience := get_tree().create_timer(CUTSCENE_PATIENCE)
	while scene.get("_talking") and patience.time_left > 0.0:
		await get_tree().process_frame

	# This checks the dialogue-box path, so the player's preference for keeping
	# chatter in the log has to be set aside for it (see [Pace]).
	var chatter := Pace.quiet_banter
	Pace.quiet_banter = false

	var party := GameState.party_characters()
	var before := Banter.bond(party[0], party[1])
	_opened.clear()
	var watch := func(id: String) -> void: _opened.append(id)
	EventBus.dialogue_requested.connect(watch)
	scene.call("_speak_to", 0)
	await get_tree().process_frame
	EventBus.dialogue_requested.disconnect(watch)
	Pace.quiet_banter = chatter

	if _opened.is_empty():
		_fail("camp: %s had nothing to say at the fire" % party[1].display_name)
		return
	# Nothing is listening for the box here, so let the waiting call finish.
	EventBus.dialogue_finished.emit(_opened[0])
	await get_tree().process_frame

	if not scene.get("_people")[0].can_talk():
		print("camp: %s said their piece and settled ('%s'), bond %d -> %d" % [
			party[1].display_name, _opened[0], before, Banter.bond(party[0], party[1])
		])
	else:
		_fail("camp: %s can be talked in circles" % party[1].display_name)


func _fail(message: String) -> void:
	_failures.append(message)