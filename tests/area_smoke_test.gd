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
	"village_dune", "dune_serai",
	"keep", "keep_hall",
	"keep_thorn", "thorn_hall",
	"library", "library_cloister", "library_vault",
	"gate", "gate_barrow", "gate_drowned", "gate_ash", "gate_dune",
	"hut", "hut_stilt", "hut_cairn", "hut_orchard",
	"wild_grove", "wild_fen", "wild_scarp", "wild_thicket", "wild_oasis",
	"tower", "home",
	"camp", "tutorial",
]
## Longest a staged meeting is allowed to take before the talking starts.
const CUTSCENE_PATIENCE := 20.0
const SaveFile := preload("res://src/chronicle/save_file.gd")
const Talk := preload("res://src/dialogue/talk.gd")
const TutorialGuide := preload("res://src/ui/tutorial_guide.gd")
const RunMode := preload("res://src/chronicle/run_mode.gd")
const GroundGen := preload("res://src/area/ground_gen.gd")
const Biome := preload("res://src/chronicle/biome.gd")
const Land := preload("res://src/area/land.gd")

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
	_check_trading()
	_check_story_npcs()
	await _check_tutorial()
	await _check_practice_band()
	await _check_the_land()
	await _check_the_joined_land()

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
		if layer is TileMapLayer:
			painted += (layer as TileMapLayer).get_used_cells().size()
		elif layer is Sprite2D:
			painted += 1
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


## A `talk` block builds into a conversation whose every reply leads somewhere, refused or not,
## and sells only things that exist ([Talk]).
func _check_talk(area_id: String, person: Dictionary) -> void:
	var who: String = person.get("name", "someone")
	for roll: float in [0.0, 0.99]:
		var nodes: Dictionary = Talk.build(who, person["talk"], false, roll, "met:test")
		if not nodes.has("hello") or not nodes.has("menu"):
			_fail("%s: %s's talk has no greeting or no menu" % [area_id, who])
		for node_id: String in nodes:
			var node: Dictionary = nodes[node_id]
			var targets: Array = [node.get("next", "end")]
			for option: Dictionary in node.get("options", []):
				targets.append(option.get("goto", "end"))
				if option.has("check"):
					targets.append(option["check"].get("success", ""))
					targets.append(option["check"].get("failure", ""))
			for target: String in targets:
				if target != "end" and not nodes.has(target):
					_fail("%s: %s's talk node '%s' leads to '%s', which is not there" % [area_id, who, node_id, target])
	for ware: Dictionary in person["talk"].get("sells", []):
		if Database.equipment_piece(str(ware.get("item", ""))).is_empty():
			_fail("%s: %s sells '%s', which is not in equipment.json" % [area_id, who, ware.get("item", "")])
	var job: Dictionary = person["talk"].get("job", {})
	if not job.is_empty() and (str(job.get("flag", "")) == "" or str(job.get("done_flag", "")) == ""):
		_fail("%s: %s's job has no flag or no done_flag" % [area_id, who])


## A door has to be on the house it belongs to, and lead somewhere real.
func _check_building(area_id: String, map: AreaMap, building: Dictionary) -> void:
	var who: String = building.get("name", "a house")
	var door: Vector2i = building["door"]
	if not AreaMap.footprint(building).has_point(door):
		_fail("%s: the door of %s is not on it" % [area_id, who])
	if not map.is_walkable(door):
		_fail("%s: the door of %s cannot be reached" % [area_id, who])
	# A house nobody can go into says so in its own words (`shut`); any other door leads somewhere.
	if not Database.has_area(building.get("area", "")) and building.get("area", "") != "coliseum" \
			and not building.has("shut") and not building.has("fight"):
		_fail("%s: %s has no inside to walk into" % [area_id, who])
	# A door into a sparring fight names opponents who exist.
	for foe: Dictionary in building.get("fight", {}).get("enemies", []):
		if Database.unit_template(str(foe.get("unit", ""))).is_empty():
			_fail("%s: %s sends you to fight '%s', who has no unit template" % [area_id, who, foe.get("unit", "")])
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
	if person.has("talk"):
		_check_talk(area_id, person)
	elif dialogue_id == "":
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


## The original twelve are people in the world now (D79): each stands in the area
## `data/story_npcs.json` gives them, drawn from their own body, with something to say.
func _check_story_npcs() -> void:
	if Database.story_npcs.size() != 12:
		_fail("story people: %d of the original twelve in story_npcs.json" % Database.story_npcs.size())
	for npc_id: String in Database.story_npcs:
		var npc := Database.story_npc(npc_id)
		var map := AreaMap.load_area(str(npc.get("area", "")))
		if map == null:
			_fail("story people: %s stands in '%s', which is not an area" % [npc_id, npc.get("area", "")])
			continue
		var standing: Array = map.people.filter(func(p: Dictionary) -> bool:
			return p.get("story_npc", "") == npc_id and p.get("unit", "") == npc.get("unit", ""))
		if standing.is_empty():
			_fail("story people: %s is not standing in %s" % [npc_id, map.id])
		elif not standing[0].has("talk"):
			_fail("story people: %s has nothing to talk about" % npc_id)


## Buying from a stall, paying a fox to listen, and a favour from asking to being paid, done the
## way the dialogue box does them: each reply's effects, then the node it leads to.
func _check_trading() -> void:
	var map := AreaMap.load_area("village")
	var hesk := {}
	var fox := {}
	var wat := {}
	for person: Dictionary in map.people:
		match person.get("name", ""):
			"Hesk the Stallholder": hesk = person
			"a fox in a stolen hat": fox = person
			"Wat the Village Idiot": wat = person
	if hesk.is_empty() or fox.is_empty() or wat.is_empty():
		_fail("village: Hesk, the fox or Wat is missing")
		return

	var nodes: Dictionary = Talk.build("Hesk", hesk["talk"], false, 0.5, "met:test")
	var loaf: Dictionary = {}
	for option: Dictionary in nodes["shop"]["options"]:
		if str(option.get("text", "")).begins_with("Loaf"):
			loaf = option
	GameState.gold = 100
	var stores := GameState.stores.size()
	DialogueScript.apply_effects(loaf)
	DialogueScript.apply_effects(nodes[loaf.get("goto", "")])
	if GameState.gold != 100 - int(loaf.get("requires_gold", 0)) or GameState.gold == 100:
		_fail("village: buying a loaf did not take the money (%d gold left)" % GameState.gold)
	if GameState.stores.size() != stores + 1 or GameState.stores[-1] != "bread":
		_fail("village: the loaf bought never went in the packs")

	nodes = Talk.build("fox", fox["talk"], false, 0.5, "met:test")
	if not nodes.has("door"):
		_fail("village: the fox talked without being paid")
	else:
		var coin: Dictionary = nodes["door"]["options"][0]
		DialogueScript.apply_effects(coin)
		DialogueScript.apply_effects(nodes[coin["goto"]])
		if not GameState.has_flag("fox:paid") or Talk.build("fox", fox["talk"], false, 0.5, "met:test").has("door"):
			_fail("village: a paid fox still would not talk")

	var job: Dictionary = wat["talk"]["job"]
	nodes = Talk.build("Wat", wat["talk"], false, 0.5, "met:test")
	DialogueScript.apply_effects(nodes["job_offer"]["options"][0])
	if not GameState.has_flag(job["flag"]):
		_fail("village: taking Wat's job did not mark it taken")
	var hand_over: Array = DialogueScript.available_options(nodes["job_check"])
	if hand_over.any(func(o: Dictionary) -> bool: return o.get("goto", "") == "job_paid"):
		_fail("village: Wat paid out before the stone was found")
	GameState.set_flag(job["done_flag"])
	var before := GameState.gold
	DialogueScript.apply_effects(nodes["job_paid"])
	if GameState.gold != before + int(job["gold"]) or not GameState.has_flag(job["flag"] + ":paid"):
		_fail("village: finishing Wat's job did not pay")
	print("village: bought a loaf, paid the fox, found Wat's stone")


## The tutorial (D73): every step points at something in its village, it never saves, it starts
## on its first step, and doing what a step asks moves it on.
func _check_tutorial() -> void:
	var rules: Variant = SaveFile.read("res://data/tutorial.json")
	if typeof(rules) != TYPE_DICTIONARY or (rules as Dictionary).get("steps", []).is_empty():
		_fail("tutorial: data/tutorial.json has no steps")
		return
	var village := FileAccess.get_file_as_string("res://data/areas/%s.json" % rules.get("area", ""))
	var map := AreaMap.load_area(str(rules.get("area", "")))
	if map == null:
		_fail("tutorial: its area '%s' does not exist" % rules.get("area", ""))
		return
	var names: Array = map.people.map(func(p: Dictionary) -> String: return str(p.get("name", "")))
	for step: Dictionary in rules["steps"]:
		var done: Dictionary = step.get("done", {})
		var did := str(done.get("did", ""))
		if did.begins_with("talked:") and not names.has(did.trim_prefix("talked:")):
			_fail("tutorial: step '%s' wants a word with %s, who is not in the village" % [step.get("id", ""), did])
		var flag := str(done.get("flag", ""))
		if flag != "" and not village.contains('"%s' % flag.trim_suffix(":paid")):
			_fail("tutorial: step '%s' waits on flag %s, which nothing in the village sets" % [step.get("id", ""), flag])
		if done.is_empty():
			_fail("tutorial: step '%s' can never be done" % step.get("id", ""))

	var had_save := GameState.has_save()
	var before := FileAccess.get_file_as_string(GameState.SAVE_PATH) if had_save else ""
	var guide: Node = TutorialGuide.new()
	add_child(guide)
	_requests.clear()
	guide.call("start")
	if not GameState.rehearsing:
		_fail("tutorial: the run it started is not marked a rehearsal")
	if _requests.is_empty() or str(_requests[-1]["payload"].get("area_id", "")) != str(rules["area"]):
		_fail("tutorial: it did not open its village")
	GameState.save()
	GameState.reached(RunMode.REST, "tutorial")
	if GameState.has_save() != had_save or (had_save and FileAccess.get_file_as_string(GameState.SAVE_PATH) != before):
		_fail("tutorial: a save was written during the tutorial")
	if guide.call("step_id") != "welcome":
		_fail("tutorial: it did not start on its first step (on '%s')" % guide.call("step_id"))
	guide.call("_on_main_pressed")
	await get_tree().create_timer(TutorialGuide.DONE_PAUSE + 0.2).timeout
	EventBus.player_did.emit("walked")
	await get_tree().create_timer(TutorialGuide.DONE_PAUSE + 0.2).timeout
	EventBus.player_did.emit("talked:Maren the Guide")
	await get_tree().create_timer(TutorialGuide.DONE_PAUSE + 0.2).timeout
	GameState.set_flag("tut:asked")
	await get_tree().create_timer(TutorialGuide.DONE_PAUSE + 0.4).timeout
	if guide.call("step_id") != "buy":
		_fail("tutorial: walking, talking and asking did not bring it to buying (on '%s')" % guide.call("step_id"))
	EventBus.scene_changed.emit("title")
	if guide.call("is_running"):
		_fail("tutorial: it kept running after the title came back")
	guide.queue_free()
	GameState.new_game(SEED)
	if GameState.rehearsing:
		_fail("tutorial: a new run after it was still a rehearsal")
	print("tutorial: %d steps, never saved, walked through to '%s'" % [rules["steps"].size(), "buy"])


## The tutorial's sparring pair (D75): not in the village until the fight step calls it, then
## standing there with its red ground, never on top of the party; a step into the red starts a
## practice fight on that ground (nobody can die, nothing counted) that comes back to the village,
## and the pair does not stand there again.
func _check_practice_band() -> void:
	GameState.new_game(SEED, "bram", true)
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "tutorial", "return_scene": "title" })
	add_child(scene)
	for i in 10:
		await get_tree().process_frame
	var watches: Array = scene.get("_watches")
	_expect_tut(watches.is_empty(), "the sparring pair was in the village before the fight step called it")
	GameState.set_flag("tut:spar_ready")
	scene.call("_post_practice_bands")
	watches = scene.get("_watches")
	_expect_tut(watches.size() == 1, "calling the sparring pair out did not put it in the village (%d)" % watches.size())
	if watches.size() != 1:
		scene.queue_free()
		return
	var watch: Node2D = watches[0]
	var map: AreaMap = scene.get("map")
	var at: Vector2i = map.cell_at(scene.get("_leader").position)
	_expect_tut(not watch.watched.has(at), "the sparring pair was put down already looking at the party")
	var into: Vector2i = (watch.watched as Dictionary).keys()[0]
	_requests.clear()
	scene.call("_check_the_watch", at)
	scene.get("_leader").position = map.centre_of(into)
	_expect_tut(scene.call("_check_the_watch", into), "stepping into the sparring pair's red was not seen")
	var waited := 0.0
	while waited < 3.0 and not _requests.any(func(r: Dictionary) -> bool: return r["key"] == "skirmish"):
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	var asked: Array = _requests.filter(func(r: Dictionary) -> bool: return r["key"] == "skirmish")
	_expect_tut(not asked.is_empty(), "the sparring pair did not start a fight")
	if not asked.is_empty():
		var payload: Dictionary = asked[0]["payload"]
		_expect_tut(bool(payload.get("sandbox", false)), "the sparring fight is not practice: someone could die in it")
		_expect_tut(not (payload.get("field", {}) as Dictionary).is_empty(), "the sparring fight is not on the village's own ground")
		_expect_tut(str(payload.get("return_scene", "")) == "area"
			and str(payload.get("return_payload", {}).get("area_id", "")) == "tutorial",
			"the sparring fight does not come back to the village")
		_expect_tut(GameState.has_flag("tut:sparred"), "the sparring pair would stand there again after the fight")
	scene.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED)
	print("tutorial: the sparring pair came out when called, was walked into, and sparred on the village ground")


func _expect_tut(ok: bool, message: String) -> void:
	if not ok:
		_fail("tutorial: %s" % message)


## The fire seats the party itself: nobody is authored into it, and speaking to
## one of your own is banter rather than a written conversation.
func _check_camp() -> void:
	var map := AreaMap.load_area("camp")
	if map.is_walkable(map.fire):
		_fail("camp: the fire can be walked into")
	if map.seats.size() < Roster.most() - 1:
		_fail("camp: %d seats for a party of %d" % [map.seats.size(), Roster.most()])
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

## Snow drags at the feet and the cold wears at whoever has nothing against it,
## but never past a quarter of their health, and somebody in a padded coat walks
## through untouched (`data/biomes.json` → `effects`, `hazards`).
func _check_the_land() -> void:
	var world: World = GameState.world
	var snow := Vector2i(-1, -1)
	for y in world.size.y:
		for x in world.size.x:
			var cell := Vector2i(x, y)
			if snow.x < 0 and world.is_walkable(cell) and world.site_at(cell) == null and Biome.at(world, cell) == "snow":
				snow = cell
	if snow.x < 0:
		_fail("no snowfield on the continent to walk")
		return
	world.player_cell = snow
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", {
		"area_id": GroundGen.for_cell(world, snow), "return_scene": "world", "planar_mode": true,
	})
	add_child(scene)
	await get_tree().process_frame
	if scene._walk_speed() >= scene.WALK_SPEED:
		_fail("the snow does not slow the party")
	var party := GameState.party_characters()
	var coated: Character = party[0]
	var bare: Character = party[-1] if party.size() > 1 else null
	coated.charms = []
	coated.equipment = "padded_coat"
	if bare != null:
		bare.equipment = ""
		bare.charms = []
		bare.hp = bare.max_hp()
	coated.hp = coated.max_hp()
	for i in 200:
		scene._weather(1000.0)
	if coated.current_hp() != coated.max_hp():
		_fail("the cold got through a padded coat")
	if bare != null and not Biome.spared(bare, "cold"):
		var low := ceili(float(bare.max_hp()) * float(Database.biomes["hazards"]["floor"]))
		if bare.current_hp() == bare.max_hp():
			_fail("the cold did nothing to %s, who has nothing against it" % bare.display_name)
		if bare.current_hp() < low:
			_fail("the cold took %s below a quarter of their health" % bare.display_name)
	GameState.heal_party()
	scene.queue_free()
	await get_tree().process_frame


## The land ([D84]): the tiles round the party laid side by side as one stretch of ground. Every
## tile that can be walked can be walked into from the next one; the sea and the mountains cannot
## be walked at all; a place stands in its tile and keeps its own cells for what is written down
## about it; and walking over into the next tile asks the continent for the step, lays out the
## tiles ahead and lets go of the ones far behind, without the ground ever leaving the screen.
func _check_the_joined_land() -> void:
	var world: World = GameState.world
	var town: Site = null
	for site: Site in world.sites:
		if site.kind == Site.VILLAGE and not site.data.has("ward") and Database.has_area(str(site.data.get("area", site.kind))):
			town = site
			break
	if town == null:
		_fail("land: no village to stand the land round")
		return
	var land = Land.around(world, town.cell, 2)
	var walked := 0
	for tile: Vector2i in land.held_tiles():
		var chunk: Dictionary = land.chunks[tile]
		var origin: Vector2i = chunk["origin"]
		var spawn: Vector2i = AreaMap.to_cell(chunk["spawn"]) + origin
		if not world.in_bounds(tile) or not world.is_walkable(tile):
			for y in land.slot.y:
				for x in land.slot.x:
					if land.is_walkable(origin + Vector2i(x, y)):
						_fail("land: %s cannot be walked on the continent but its ground can (%s)" % [tile, chunk["kind"]])
						return
			continue
		if not land.is_walkable(spawn):
			_fail("land: the way into %s (%s) cannot be stood on" % [tile, chunk["kind"]])
		for dir: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			var next: Vector2i = tile + dir
			if not land.is_held(next) or not world.is_walkable(next):
				continue
			var there: Dictionary = land.chunks[next]
			var to: Vector2i = AreaMap.to_cell(there["spawn"]) + (there["origin"] as Vector2i)
			if land.find_cell_path(spawn, to).is_empty():
				_fail("land: no way over from %s into %s" % [tile, next])
			walked += 1
	if walked == 0:
		_fail("land: no two tiles side by side to walk between")
	var place: Dictionary = land.chunks[town.cell]
	var area_id := str(town.data.get("area", town.kind))
	if str(place.get("kind", "")) != "place" or str(place.get("id", "")) != area_id:
		_fail("land: %s does not stand in its own tile" % town.display_name)
	else:
		var alone := AreaMap.load_area(area_id)
		var rect: Rect2i = place["place_rect"]
		for cell: Vector2i in alone.chests:
			if land.chest_flag(cell + rect.position) != alone.chest_flag(cell):
				_fail("land: a chest in %s is not the same chest on the land" % town.display_name)
		if land.area_of(rect.position) != area_id or land.local_of(rect.position + Vector2i(2, 3)) != Vector2i(2, 3):
			_fail("land: the land does not say whose cells %s's are" % town.display_name)

	# Walked: the scene on the land, the leader put over into the next tile, the step asked for.
	var here := town.cell + Vector2i.LEFT
	if not world.is_walkable(here):
		here = town.cell + Vector2i.RIGHT
	world.player_cell = here
	GameState.land_cell = null
	var asked: Array = []
	var listen := func(payload: Dictionary) -> void: asked.append(payload)
	EventBus.continent_requested.connect(listen)
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "land": true, "return_scene": "world", "planar_mode": true })
	add_child(scene)
	await get_tree().process_frame
	if scene._tile_ground.size() != 9:
		_fail("land: %d tiles laid out round the party, not 9" % scene._tile_ground.size())
	if scene.map.tile_of(scene.map.cell_at(scene._leader.position)) != here:
		_fail("land: the party did not start on the tile the continent has it on")
	# A band on the next tile stands there; moved a tile by the continent, it walks across; gone
	# from the continent's word, it goes.
	var band := { "key": "band", "pack": ["goblin"], "reach": 2, "faction": "", "label": "Goblin", "tile": [here.x, here.y - 1] }
	scene._sync_bands([band])
	var watches: Array = scene.get("_watches")
	if watches.size() != 1 or not scene.map.slot_rect(here + Vector2i.UP).has_point(watches[0].anchor):
		_fail("land: a band on the next tile is not standing in it")
	else:
		var moved := band.duplicate()
		moved["tile"] = [here.x - 1, here.y - 1]
		scene._sync_bands([moved])
		if not watches[0].travelling or watches[0].region != scene.map.slot_rect(here + Vector2i(-1, -1)):
			_fail("land: a band moved a tile by the continent did not set off across the land")
		scene._sync_bands([])
		if not (scene.get("_watches") as Array).is_empty():
			_fail("land: a band the continent no longer has is still on the land")
	var dir := town.cell - here
	var into: Vector2i = scene.map.slot_rect(town.cell).get_center()
	scene._leader.position = scene.map.centre_of(into)
	scene._mind_the_border()
	if asked.size() != 1 or AreaMap.to_cell(asked[0].get("step", [0, 0])) != dir or not bool(asked[0].get("embedded", false)):
		_fail("land: walking over into the next tile did not ask the continent for that step")
	# The continent's answer, as it gives it.
	world.player_cell = town.cell
	EventBus.continent_answered.emit({ "land": true, "title": town.label(), "actions": [], "bands": [], "notes": ["Walked on."], "held": {} })
	for i in 12:
		await get_tree().process_frame
	var far := here - dir
	if not scene.map.is_held(town.cell + dir) or not scene.map.is_held(town.cell + dir + Vector2i.UP):
		_fail("land: the tiles ahead were not laid out after the step")
	if scene.map.is_held(far - dir):
		_fail("land: a tile three behind is still held")
	if not scene.is_inside_tree() or scene._leaving:
		_fail("land: the ground left the screen for a step")
	EventBus.continent_requested.disconnect(listen)
	scene.queue_free()
	await get_tree().process_frame
	print("land: tiles walk into each other, %s stands in its tile, a band walks across, and a step keeps to the land" % town.display_name)
