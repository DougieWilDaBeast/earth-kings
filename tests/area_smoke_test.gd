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
	"tower_floor_1", "tower_floor_2", "tower_floor_3", "tower_floor_4", "tower_floor_5",
	"camp", "tutorial",
	"city", "city_streets", "city_tavern",
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
const AreaCritter := preload("res://src/area/area_critter.gd")
const FirstRoad := preload("res://src/area/first_road.gd")
const Memories := preload("res://src/chronicle/memories.gd")
const Chapters := preload("res://src/chronicle/chapters.gd")
const Sixteen := preload("res://src/chronicle/sixteen.gd")
const Siblings := preload("res://src/chronicle/siblings.gd")
const Company := preload("res://tests/company.gd")
const GateInside := preload("res://src/chronicle/gate_inside.gd")

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
	_check_the_builder_and_the_healer()
	_check_story_npcs()
	await _check_tutorial()
	await _check_last_stand()
	await _check_practice_band()
	await _check_tower_floor()
	await _check_inside_a_gate()
	await _check_people_on_the_land()
	await _check_the_land()
	await _check_the_joined_land()
	await _check_play_test_three()
	await _check_life_on_the_land()
	await _check_play_test_four()
	await _check_followers_face()
	_check_tracks()
	await _check_play_hud()

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
	# A band the area stands up itself (a floor of the Tower's, D102) is people too.
	for watch: Node2D in scene.get("_watches"):
		expected += (watch.get("figures") as Array).size()
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

	# Somebody at their work ([D85]) walks to every stop of their rounds from where they stand.
	for stop: Dictionary in person.get("rounds", []):
		var at := AreaMap.to_cell(stop.get("cell", [0, 0]))
		if not map.is_walkable(at) or map.find_cell_path(cell, at).is_empty():
			_fail("%s: %s cannot get to their work at %s" % [area_id, who, at])

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
## Stormreach's builder and its healer ([D176]): Muck Muck stands by the ruined bathhouse and talks
## about building; Sinner mends the whole company for gold while anyone is hurt, takes the money
## once, and with nobody hurt only looks them over, for nothing.
func _check_the_builder_and_the_healer() -> void:
	var map := AreaMap.load_area("city_streets")
	var muck := {}
	var sinner := {}
	for person: Dictionary in map.people:
		match person.get("name", ""):
			"Muck Muck": muck = person
			"Sinner": sinner = person
	if muck.is_empty() or sinner.is_empty():
		_fail("city: Muck Muck or Sinner is missing from the streets")
		return
	if (Talk.build("Muck Muck", muck["talk"], false, 0.5, "met:test")["menu"]["options"] as Array).size() < 3:
		_fail("city: Muck Muck has nothing to be asked")
	var nodes: Dictionary = Talk.build("Sinner", sinner["talk"], false, 0.5, "met:test")
	var hurt: Character = GameState.party_characters()[0]
	hurt.hp = maxi(1, hurt.max_hp() / 3)
	GameState.gold = 1000
	var mend: Dictionary = {}
	for option: Dictionary in DialogueScript.available_options(nodes["menu"]):
		if bool(option.get("heal", false)):
			mend = option
	if mend.is_empty():
		_fail("city: Sinner offers no healing to a hurt company")
		return
	DialogueScript.apply_effects(mend)
	if GameState.party_is_wounded():
		_fail("city: Sinner took the money and nobody was mended")
	if GameState.gold != 1000 - int(mend.get("requires_gold", 0)) or GameState.gold == 1000:
		_fail("city: Sinner's mending cost nothing (%d gold left)" % GameState.gold)
	var whole := DialogueScript.available_options(nodes["menu"])
	if whole.any(func(o: Dictionary) -> bool: return bool(o.get("heal", false))):
		_fail("city: Sinner still asks money to mend a company with nobody hurt")
	if not whole.any(func(o: Dictionary) -> bool: return o.get("goto", "") == "whole"):
		_fail("city: Sinner has nothing to say to a company that is whole")
	hurt.hp = maxi(1, hurt.max_hp() / 3)
	GameState.gold = 0
	if DialogueScript.available_options(nodes["menu"]).any(func(o: Dictionary) -> bool: return bool(o.get("heal", false))):
		_fail("city: Sinner mends a company that cannot pay")
	GameState.heal_party()
	GameState.gold = GameState.DEFAULT_GOLD


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


## Atlas's last stand (D191): its last step calls out a band Atlas cannot beat; when that fight
## ends he is written into the record of the fallen as the first world that ended, the fall is
## told, and the quiz picks who comes next. Played again once he has fallen it writes nothing and
## goes back to the title; skipped, he still falls. Uses its own copies of the record and of the
## settings, never the player's.
func _check_last_stand() -> void:
	var rules: Dictionary = SaveFile.read("res://data/tutorial.json")
	var last: Dictionary = rules["steps"][-1]
	if not bool(last.get("doom", false)):
		_fail("last stand: the tutorial's last step is not the doomed fight")
	var village: Dictionary = SaveFile.read("res://data/areas/%s.json" % rules["area"])
	var doomed := (village.get("bands", []) as Array).filter(
		func(band: Dictionary) -> bool: return bool(band.get("doomed", false)))
	if doomed.is_empty():
		_fail("last stand: Hearthwick has no doomed band")
	elif not (last.get("on_start", {}).get("set_flag", []) as Array).has(doomed[0].get("requires", "")):
		_fail("last stand: the last step does not call the doomed band out")

	var record_was := Sixteen.path
	var settings_was: String = TutorialGuide.settings_path
	Sixteen.path = "user://earth-kings.sixteen.last-stand-test.json"
	TutorialGuide.settings_path = "user://settings.last-stand-test.cfg"
	for each in [Sixteen.path, TutorialGuide.settings_path]:
		if FileAccess.file_exists(each):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(each))

	# The first time: played through, Atlas falls and is written down.
	var guide: Node = TutorialGuide.new()
	add_child(guide)
	guide.call("start")
	guide.call("_show", (rules["steps"] as Array).size() - 1)
	if not GameState.has_flag(str(doomed[0].get("requires", "") if not doomed.is_empty() else "")):
		_fail("last stand: reaching the last step did not call out the band")
	_requests.clear()
	EventBus.player_did.emit("fight_lost")
	await get_tree().create_timer(TutorialGuide.FALL_PAUSE + 0.4).timeout
	var lead := str(rules["lead"])
	if not Sixteen.fallen_heroes().has(lead):
		_fail("last stand: losing the last fight did not write %s down as fallen" % lead)
	var ended: Array = Sixteen.worlds()
	if ended.size() != 1 or not bool(ended[0].get("last_stand", false)) or str(ended[0].get("hero", "")) != lead:
		_fail("last stand: the world that ended is not Atlas's last stand (%s)" % [ended])
	elif int(ended[0].get("base_seed", 0)) == int(rules["seed"]):
		_fail("last stand: the worlds after it would be built on the last stand's own seed, the same for everyone")
	if not guide.call("is_telling_the_fall"):
		_fail("last stand: the fall was not told")
	if not TutorialGuide.finished_once():
		_fail("last stand: finishing it was not remembered")
	guide.call("_after_the_fall")
	if _requests.is_empty() or _requests[-1]["key"] != "temper_quiz" or not bool(_requests[-1]["payload"].get("opening", false)):
		_fail("last stand: after the fall it did not go to the quiz and the opening")
	elif not (_requests[-1]["payload"].get("fallen_heroes", []) as Array).has(lead):
		_fail("last stand: the quiz could still pick Atlas")
	if FirstHour.first_life() != "":
		_fail("last stand: after it, New Game would still be Atlas (%s)" % FirstHour.first_life())
	if not Sixteen.first_life():
		_fail("last stand: the run after it is not the player's first life (where they land, the first gate)")
	if FirstHour.challenger("janus") != 1:
		_fail("last stand: the floor 5 keeper would count the next lead as challenger %d, not the first" % FirstHour.challenger("janus"))
	guide.queue_free()

	# The next world is built from his, with his echo in it.
	GameState.new_game(SEED, "janus")
	Siblings.arrive(GameState.world, GameState.roster, Sixteen.worlds())
	if Siblings.echo_of(GameState.world, lead).is_empty():
		_fail("last stand: the next world has no echo of Atlas")

	# Played again: nothing more is written, and it ends at the title.
	guide = TutorialGuide.new()
	add_child(guide)
	guide.call("start")
	guide.call("_show", (rules["steps"] as Array).size() - 1)
	_requests.clear()
	EventBus.player_did.emit("fight_won")
	await get_tree().create_timer(TutorialGuide.FALL_PAUSE + 0.4).timeout
	if Sixteen.worlds().size() != 1:
		_fail("last stand: a replay wrote another world down")
	guide.call("_after_the_fall")
	if _requests.is_empty() or _requests[-1]["key"] != "title":
		_fail("last stand: a replay did not end at the title")
	guide.queue_free()

	# Skipped: he still falls, once.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Sixteen.path))
	TutorialGuide.skip_it()
	TutorialGuide.skip_it()
	if Sixteen.worlds().size() != 1 or not bool(Sixteen.worlds()[0].get("last_stand", false)):
		_fail("last stand: skipping it did not write Atlas's fall down once (%s)" % [Sixteen.worlds()])

	for each in [Sixteen.path, TutorialGuide.settings_path]:
		if FileAccess.file_exists(each):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(each))
	Sixteen.path = record_was
	TutorialGuide.settings_path = settings_was
	EventBus.scene_changed.emit("title")
	GameState.new_game(SEED)
	print("last stand: Atlas falls once, the quiz is next, a replay writes nothing, a skip still falls")


## The tutorial's sparring pair (D75): not in the village until the fight step calls it, then
## standing there with its red ground, never on top of the party; a step into the red starts a
## practice fight on that ground (nobody can die, nothing counted) that comes back to the village,
## and the pair does not stand there again.
func _check_practice_band() -> void:
	GameState.new_game(SEED, "atlas", true)
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
	while waited < 3.0 and scene.get("_fight") == null:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	# Fought where it was met (step 4 of the First Hour): put down on the village's own ground, with
	# no change of scene.
	var fight: Node2D = scene.get("_fight")
	_expect_tut(fight != null, "the sparring pair did not start a fight")
	_expect_tut(not _requests.any(func(r: Dictionary) -> bool: return r["key"] == "skirmish"),
		"the sparring fight changed the screen instead of being fought on the village ground")
	if fight != null:
		var payload: Dictionary = fight.get("boot_payload")
		_expect_tut(bool(payload.get("sandbox", false)), "the sparring fight is not practice: someone could die in it")
		_expect_tut(not (payload.get("field", {}) as Dictionary).is_empty(), "the sparring fight is not on the village's own ground")
		_expect_tut(bool(fight.get("in_place")) and fight.get_parent() == scene, "the sparring fight is not laid on the village")
		_expect_tut(not bool(fight.get("paused")), "the sparring fight opened paused")
		# Sent off the edge of the field, the party gets clear: over, neither won nor lost, and the
		# fight goes while the party walks on from where it stood.
		fight.set_process(false)
		fight.call("_select", fight.call("party_fighters"))
		fight.call("_make_for_the_edge", Vector2i(-3, 1))
		for i in 6000:
			if bool(fight.get("over")):
				break
			fight.call("tick")
		_expect_tut(bool(fight.get("over")) and bool(fight.get("fled_field")), "walking off the field's edge did not get the party clear")
		waited = 0.0
		while waited < 3.0 and scene.get("_fight") != null:
			await get_tree().create_timer(0.1).timeout
			waited += 0.1
		_expect_tut(scene.get("_fight") == null and not bool(scene.get("_leaving")), "the village did not carry on after the sparring fight")
		_expect_tut(GameState.has_flag("tut:sparred"), "the sparring pair would stand there again after the fight")
	scene.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED)
	print("tutorial: the sparring pair came out when called, was walked into, and sparred on the village ground")


## A floor of the Tower is walked (D102): its band is fought for real on its own ground, and
## standing on the stair up wins the floor, paid out by the continent as a won Tower fight.
## D247 (play-test 6): a gate gone into is walked. Every kind of gate lays out a floor that loads,
## whose way down can be walked to from the doorway past every band; the floor's bands are held and
## fought where they stand, with the Guild's people beside the party; the way down goes on to the
## next floor, and on the last floor it stays shut until the keeper is down, then shuts the gate.
func _check_inside_a_gate() -> void:
	GameState.new_game(SEED)
	var world: World = GameState.world
	var party := GameState.party_characters()
	var kinds := {}
	var deep: Site = null
	for site: Site in world.sites_of_kind(Site.GATE):
		var look := str(site.data.get("area", ""))
		if site.floors() >= 2 and (deep == null or site.floors() < deep.floors()):
			deep = site
		if kinds.has(look):
			continue
		kinds[look] = true
		for depth in [0, site.floors() - 1]:
			var id := GateInside.area_for(world, site, depth, party)
			var map := AreaMap.load_area(id)
			_expect(map != null, "inside a gate: %s floor %d does not load" % [site.display_name, depth + 1])
			if map == null:
				continue
			_expect(map.width * map.height >= 34 * 26, "inside a gate: %s floor %d is only %dx%d" % [site.display_name, depth + 1, map.width, map.height])
			for sheet: String in map.layers:
				_expect(not Database.tileset_sheet(sheet).is_empty(), "inside a gate: %s has no ground sheet '%s'" % [look, sheet])
			_expect(map.stairs.size() == 2 and map.find_cell_path(map.spawn, map.stairs[0]).size() > 1,
				"inside a gate: %s floor %d has no way from the doorway to the way down" % [site.display_name, depth + 1])
			_expect(map.is_walkable(map.exits[1]) and map.is_exit(map.exits[1]),
				"inside a gate: %s floor %d has no way back out" % [site.display_name, depth + 1])
			_expect(map.bands.size() >= 1, "inside a gate: nobody holds %s floor %d" % [site.display_name, depth + 1])
			var keepers := 0
			for band: Dictionary in map.bands:
				var at: Array = band.get("at", [0, 0])
				_expect(bool(band.get("held", false)), "inside a gate: %s is not held" % band.get("key", ""))
				_expect(map.find_cell_path(map.spawn, Vector2i(int(at[0]), int(at[1]))).size() > 1,
					"inside a gate: %s stands where nobody can walk to" % band.get("key", ""))
				if bool(band.get("boss", false)):
					keepers += 1
			_expect(keepers == (1 if depth == site.floors() - 1 else 0),
				"inside a gate: %s floor %d has %d keepers" % [site.display_name, depth + 1, keepers])
			# The same floor of the same gate is laid out the same way.
			_expect(GateInside.layout(world, site, depth, party)["rows"] == Database.area(id)["rows"],
				"inside a gate: %s floor %d is laid out differently a second time" % [site.display_name, depth + 1])
	if deep == null:
		_fail("inside a gate: no gate deeper than one floor")
		return

	# The first floor: a band fought where it stands, with the Guild's people; the way down goes on.
	var ally := { "unit": "keep_watchman", "level": 3, "name": "a Guild blade" }
	var first: Node = load("res://src/area/area_scene.tscn").instantiate()
	first.set("boot_payload", {
		"area_id": GateInside.area_for(world, deep, 0, party), "return_scene": "world",
		"gate_cell": [deep.cell.x, deep.cell.y], "gate_depth": 0, "gate_final": false, "allies": [ally],
	})
	add_child(first)
	for i in 10:
		await get_tree().process_frame
	var map: AreaMap = first.get("map")
	var watches: Array = first.get("_watches")
	_expect(watches.size() == map.bands.size(), "inside a gate: %d of %d bands stand on the floor" % [watches.size(), map.bands.size()])
	if not watches.is_empty():
		var watch: Node2D = watches[0]
		var into: Vector2i = (watch.watched as Dictionary).keys()[0]
		first.call("_check_the_watch", map.cell_at(first.get("_leader").position))
		first.get("_leader").position = map.centre_of(into)
		first.call("_check_the_watch", into)
		var waited := 0.0
		while waited < 3.0 and first.get("_fight") == null:
			await get_tree().create_timer(0.05).timeout
			waited += 0.05
		var fight: Node2D = first.get("_fight")
		_expect(fight != null and bool(fight.get("in_place")), "inside a gate: the band was not fought where it stood")
		_expect(str(GameState.pending_outcome.get("kind", "")) == "gate_band" and GameState.pending_outcome.get("cell") == deep.cell,
			"inside a gate: the band's fight is not settled as the gate's (%s)" % GameState.pending_outcome)
		if fight != null:
			var field: Dictionary = (fight.get("boot_payload") as Dictionary).get("field", {})
			_expect((field.get("allies", []) as Array).any(func(a: Dictionary) -> bool: return str(a.get("name", "")) == "a Guild blade"),
				"inside a gate: the Guild's people did not fight beside the party")
			fight.set_process(false)
	first.queue_free()
	await get_tree().process_frame
	GameState.pending_outcome = {}
	_requests.clear()
	var again: Node = load("res://src/area/area_scene.tscn").instantiate()
	again.set("boot_payload", {
		"area_id": GateInside.area_for(world, deep, 0, party), "return_scene": "world",
		"gate_cell": [deep.cell.x, deep.cell.y], "gate_depth": 0, "gate_final": false,
	})
	add_child(again)
	for i in 10:
		await get_tree().process_frame
	var down: AreaMap = again.get("map")
	(again.get("_leader") as Node2D).position = down.centre_of(down.stairs[0] + Vector2i(0, 1))
	_expect(str(again.call("_prompt_text")).ends_with("to go down to floor 2 of %d" % deep.floors()),
		"inside a gate: at the way down nothing says how to take it (%s)" % again.call("_prompt_text"))
	again.call("_climb_the_stair")
	var on: Array = _requests.filter(func(r: Dictionary) -> bool: return r["key"] == "world")
	_expect(not on.is_empty() and bool((on[0]["payload"] as Dictionary).get("gate_on", false)), "inside a gate: the way down went nowhere")
	_expect(str(GameState.pending_outcome.get("kind", "")) == "gate" and not bool(GameState.pending_outcome.get("final", true))
			and bool(GameState.pending_outcome.get("walked", false)) and GameState.has_flag("last_victory"),
		"inside a gate: the way down did not win the floor (%s)" % GameState.pending_outcome)
	GameState.pending_outcome = {}
	GameState.set_flag("last_victory", false)
	again.queue_free()
	await get_tree().process_frame

	# The last floor: shut until its keeper falls, and then the way out shuts the gate.
	var last := deep.floors() - 1
	var keeper := GateInside.keeper_flag(deep, last)
	_requests.clear()
	var bottom: Node = load("res://src/area/area_scene.tscn").instantiate()
	bottom.set("boot_payload", {
		"area_id": GateInside.area_for(world, deep, last, party), "return_scene": "world",
		"gate_cell": [deep.cell.x, deep.cell.y], "gate_depth": last, "gate_final": true, "gate_keeper": keeper,
	})
	add_child(bottom)
	for i in 10:
		await get_tree().process_frame
	var end: AreaMap = bottom.get("map")
	_expect(end.bands.any(func(b: Dictionary) -> bool: return "done:%s" % str(b.get("key", "")) == keeper),
		"inside a gate: the keeper's fall is not what opens the last floor's way down")
	(bottom.get("_leader") as Node2D).position = end.centre_of(end.stairs[0] + Vector2i(0, 1))
	_expect(str(bottom.call("_prompt_text")).contains("will not open"), "inside a gate: the way down is open with its keeper standing (%s)" % bottom.call("_prompt_text"))
	bottom.call("_climb_the_stair")
	_expect(_requests.is_empty() and GameState.pending_outcome.is_empty(), "inside a gate: the last floor was left past its keeper")
	_expect(bottom.call("_keeper_cell") != Vector2i(-1, -1), "inside a gate: Auto would not know where the keeper stands")
	GameState.set_flag(keeper)
	_expect(str(bottom.call("_prompt_text")).ends_with("to shut %s" % deep.display_name), "inside a gate: with the keeper down nothing says the gate can be shut (%s)" % bottom.call("_prompt_text"))
	bottom.call("_climb_the_stair")
	_expect(str(GameState.pending_outcome.get("kind", "")) == "gate" and bool(GameState.pending_outcome.get("final", false)),
		"inside a gate: the last floor's way out did not shut the gate")
	GameState.pending_outcome = {}
	GameState.set_flag("last_victory", false)
	bottom.queue_free()
	await get_tree().process_frame


func _check_tower_floor() -> void:
	GameState.new_game(SEED)
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "tower_floor_1", "return_scene": "world", "tower_floor": 1 })
	add_child(scene)
	for i in 10:
		await get_tree().process_frame
	var watches: Array = scene.get("_watches")
	_expect(not watches.is_empty(), "tower floor: nobody stands on floor 1")
	if watches.is_empty():
		scene.queue_free()
		return
	var watch: Node2D = watches[0]
	var map: AreaMap = scene.get("map")
	var at: Vector2i = map.cell_at(scene.get("_leader").position)
	var into: Vector2i = (watch.watched as Dictionary).keys()[0]
	scene.call("_check_the_watch", at)
	scene.get("_leader").position = map.centre_of(into)
	_expect(scene.call("_check_the_watch", into), "tower floor: stepping into a band's red was not seen")
	var waited := 0.0
	while waited < 3.0 and scene.get("_fight") == null:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	var fight: Node2D = scene.get("_fight")
	_expect(fight != null, "tower floor: the band did not fight")
	if fight != null:
		_expect(not bool((fight.get("boot_payload") as Dictionary).get("sandbox", false)), "tower floor: the fight is practice")
		_expect(str(GameState.pending_outcome.get("kind", "")) == "tower_band", "tower floor: the fight is not settled as the Tower's")
		fight.set_process(false)
	scene.queue_free()
	await get_tree().process_frame

	# The stair up.
	GameState.pending_outcome = {}
	_requests.clear()
	var again: Node = load("res://src/area/area_scene.tscn").instantiate()
	again.set("boot_payload", { "area_id": "tower_floor_1", "return_scene": "world", "tower_floor": 1 })
	add_child(again)
	for i in 10:
		await get_tree().process_frame
	var up: AreaMap = again.get("map")
	_expect(not up.stairs.is_empty(), "tower floor: no stair up")
	if not up.stairs.is_empty():
		# Stepping onto it asks rather than climbs (meeting 3); E climbs.
		again.call("_arrive_at", up.stairs[0])
		_expect(not _requests.any(func(r: Dictionary) -> bool: return r["key"] == "world"), "tower floor: stepping on the stair climbed without asking")
		(again.get("_leader") as Node2D).position = up.centre_of(up.stairs[0] + Vector2i(0, 1))
		_expect(str(again.call("_prompt_text")).ends_with("to climb to floor 2"), "tower floor: at the stair nothing says how to climb (%s)" % again.call("_prompt_text"))
		again.call("_climb_the_stair")
		_expect(_requests.any(func(r: Dictionary) -> bool: return r["key"] == "world"), "tower floor: the stair up went nowhere")
		_expect(str(GameState.pending_outcome.get("kind", "")) == "tower" and int(GameState.pending_outcome.get("floor", 0)) == 1
				and GameState.has_flag("last_victory"), "tower floor: the stair up did not win the floor")
	GameState.pending_outcome = {}
	GameState.set_flag("last_victory", false)
	again.queue_free()
	await get_tree().process_frame

	# Floor 6 (D207): walked on a borrowed plan, its bands the floor's own, fought on its ground.
	var plan := Chapters.walked_floor_area(6)
	var six: Node = load("res://src/area/area_scene.tscn").instantiate()
	six.set("boot_payload", { "area_id": plan, "return_scene": "world", "tower_floor": 6 })
	add_child(six)
	for i in 10:
		await get_tree().process_frame
	var on_six: Array = six.get("_watches")
	_expect(not on_six.is_empty() and on_six.all(func(w: Node2D) -> bool: return str(w.band.get("key", "")).begins_with("tower6_")),
			"tower floor: floor 6's bands are not its own")
	if not on_six.is_empty():
		var w6: Node2D = on_six[0]
		var m6: AreaMap = six.get("map")
		var into6: Vector2i = (w6.watched as Dictionary).keys()[0]
		six.call("_check_the_watch", m6.cell_at(six.get("_leader").position))
		six.get("_leader").position = m6.centre_of(into6)
		six.call("_check_the_watch", into6)
		var waited6 := 0.0
		while waited6 < 3.0 and six.get("_fight") == null:
			await get_tree().create_timer(0.05).timeout
			waited6 += 0.05
		var fight6: Node2D = six.get("_fight")
		_expect(fight6 != null and bool(fight6.get("in_place")), "tower floor: floor 6 was not fought on its ground")
		_expect(not _requests.any(func(r: Dictionary) -> bool: return r["key"] == "skirmish"), "tower floor: floor 6 opened a fight screen")
		if fight6 != null:
			fight6.set_process(false)
	six.queue_free()
	GameState.pending_outcome = {}
	await get_tree().process_frame

	# Atlas's chapter-one memory (D103): the buckle lies on floor 5 for him and nobody else.
	GameState.new_game(SEED, "atlas")
	var asked: Array[String] = []
	var listen := func(id: String) -> void: asked.append(id)
	EventBus.dialogue_requested.connect(listen)
	var five: Node = load("res://src/area/area_scene.tscn").instantiate()
	five.set("boot_payload", { "area_id": "tower_floor_5", "return_scene": "world", "tower_floor": 5 })
	add_child(five)
	for i in 10:
		await get_tree().process_frame
	var lying: Dictionary = five.get("_memories")
	_expect(lying.size() == 1, "tower floor: Atlas's buckle is not on floor 5 (%d)" % lying.size())
	if lying.size() == 1:
		var cell: Vector2i = lying.keys()[0]
		_expect((five.get("map") as AreaMap).is_walkable(cell), "tower floor: the buckle lies where nobody can stand")
		# The compass points at it before the stair, so nobody walks past it (D107).
		five.call("_point_the_compass")
		var said := (((five.get("_compass") as Control).get("_label")) as Label).text
		_expect(said == "Something glints", "tower floor: the compass does not point at the buckle first (%s)" % said)
		five.call("_arrive_at", cell)
		_expect(asked.has("memory_atlas_1") and not Database.dialogue("memory_atlas_1").is_empty(),
				"tower floor: picking up the buckle played no scene")
		_expect(Memories.found("atlas").size() == 1, "tower floor: the journal does not have the memory")
		_expect(bool(preload("res://src/chronicle/siblings.gd").remember(GameState.world, GameState.roster, GameState.ledger).get("remembered", false)),
				"tower floor: a world whose lead found their chapter one does not say so when it ends (D153)")
		_expect((five.get("_memories") as Dictionary).is_empty(), "tower floor: the buckle can be picked up twice")
	EventBus.dialogue_requested.disconnect(listen)
	five.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED, "juno")
	var not_his: Node = load("res://src/area/area_scene.tscn").instantiate()
	not_his.set("boot_payload", { "area_id": "tower_floor_5", "return_scene": "world", "tower_floor": 5 })
	add_child(not_his)
	for i in 5:
		await get_tree().process_frame
	# All sixteen have a chapter one now (D151), so Juno sees one keepsake: hers, never Atlas's.
	var hers: Array = (not_his.get("_memories") as Dictionary).values().map(func(m: Dictionary) -> String: return str(m.get("id", "")))
	_expect(hers == ["juno_1"], "tower floor: Juno found Atlas's memory, or not her own (%s)" % [hers])
	not_his.queue_free()
	await get_tree().process_frame
	# Every other lead with a chapter one (D135, D138, D151) finds their own in the same alcove, and nobody else's.
	for lead: String in Database.memories:
		if lead == "atlas" or lead.begins_with("_"):
			continue
		GameState.new_game(SEED, lead)
		var theirs: Node = load("res://src/area/area_scene.tscn").instantiate()
		theirs.set("boot_payload", { "area_id": "tower_floor_5", "return_scene": "world", "tower_floor": 5 })
		add_child(theirs)
		for i in 5:
			await get_tree().process_frame
		var lying_here: Dictionary = theirs.get("_memories")
		_expect(lying_here.size() == 1, "tower floor: %s's keepsake is not on floor 5 (%d)" % [lead, lying_here.size()])
		if lying_here.size() == 1:
			theirs.call("_arrive_at", lying_here.keys()[0])
			_expect(Memories.found(lead).size() == 1 and Memories.found("atlas").is_empty(),
					"tower floor: %s did not find their own memory, or found Atlas's" % lead)
		theirs.queue_free()
		await get_tree().process_frame
	# The Tower's door is the way up (D107): standing at it says how to climb, and the shaft stands over it (D108).
	var foot: Node = load("res://src/area/area_scene.tscn").instantiate()
	foot.set("boot_payload", { "area_id": "tower", "return_scene": "world" })
	add_child(foot)
	for i in 5:
		await get_tree().process_frame
	var door: AreaProp = null
	for thing: AreaProp in foot.get("_things"):
		if thing.act == "_climb_here":
			door = thing
	_expect(door != null, "tower: the Tower's door is not a way up")
	# The Guild's master stands beside Sennet and can mark a lead himself (D154).
	var masters := (Database.area("tower").get("people", []) as Array).filter(func(p: Dictionary) -> bool:
		return str(p.get("name", "")).begins_with("Old Halloran") and bool(p.get("guild", false)))
	_expect(masters.size() == 1, "tower: the Guild's master is not in the Guild")
	var spires := (foot.get("_actors") as Node).get_children().filter(func(n: Node) -> bool: return n.get_script() == preload("res://src/area/area_spire.gd"))
	_expect(spires.size() == 1, "tower: the stand-in Tower is not standing (%d)" % spires.size())
	if door != null:
		# Two cells short of it, with the doorkeeper close by, E is still the door's (meeting 3).
		var leader: Node2D = foot.get("_leader")
		leader.position = door.position + Vector2(0.0, AreaMap.CELL * 2.0)
		foot.call("_refresh_prompt")
		_expect(foot.get("_nearby") == door, "tower: two cells from the door, E is not the door's")
		# And the yard can be walked from where you come in to the door's steps (meeting 3).
		var yard: AreaMap = foot.get("map")
		var to_door: Array = yard.astar.get_id_path(yard.spawn, door.cell + Vector2i(0, 1))
		_expect(not to_door.is_empty(), "tower: the door's steps cannot be walked to from the yard's way in")
		foot.set("_acts", [{ "prompt": "E to climb floor 1 of the Tower", "act": "_climb_here", "key": "interact" }])
		foot.set("_nearby", door)
		_expect(str(foot.call("_prompt_text")) == "E to climb floor 1 of the Tower", "tower: standing at the door does not say how to climb")
		foot.set("_nearby", null)
	foot.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED)
	print("tower floor: a band fought for real on floor 1, the stair up won the floor, Atlas found his buckle on floor 5, and the Tower's door says how to climb")


## People on the land (D215): bands always by the First Hour's road, the Watch beset on the roads
## round a town (and only there) fighting beside the party, and climbers resting on a Tower floor.
func _check_people_on_the_land() -> void:
	GameState.new_game(SEED, "janus")
	var world: World = GameState.world
	world.prowlers.clear()
	Encounter.restock(world, world.rng)
	var rules: Dictionary = Database.encounters.get("near_the_road", {})
	var road: Array = FirstRoad.tiles(world)
	var by_road := 0
	for band: Prowler in world.prowlers:
		var apart := 1 << 20
		for tile: Vector2i in road:
			apart = mini(apart, Pathfinder.distance(band.cell, tile))
		if apart >= int(rules.get("from", 2)) and apart <= int(rules.get("to", 4)):
			by_road += 1
	_expect(by_road >= int(rules.get("bands", 1)), "people: only %d bands by the road (wanted %d)" % [by_road, int(rules.get("bands", 1))])

	# The Watch beset: by a town's roads only, and fighting beside the party.
	var town: Site = null
	for site: Site in world.sites:
		if Town.is_settlement(site) and not Town.is_ruined(site):
			town = site
			break
	var ring := Vector2i(-1, -1)
	var open := Vector2i(-1, -1)
	for y in world.size.y:
		for x in world.size.x:
			var c := Vector2i(x, y)
			if not world.is_walkable(c) or Roadside._near_a_site(world, c):
				continue
			if ring.x < 0 and Roadside.near_town(world, c):
				ring = c
			if open.x < 0 and not Roadside.near_town(world, c):
				open = c
	_expect(town != null and ring.x >= 0 and open.x >= 0, "people: no road round a town, or no open country, to look on")
	var watch_ids := Roadside.events().keys().filter(func(id) -> bool: return bool(Roadside.event(str(id)).get("near_town", false)))
	_expect(not watch_ids.is_empty(), "people: there is no Watch beset among the roadside scenes")
	var seen_by_town: Array = []
	var seen_in_open: Array = []
	for i in 400:
		world.roadside_at = -999
		var here := Roadside.look(world, ring)
		if here != "":
			seen_by_town.append(here)
		world.roadside_at = -999
		var there := Roadside.look(world, open)
		if there != "":
			seen_in_open.append(there)
	_expect(not seen_by_town.is_empty() and seen_by_town.all(func(id) -> bool: return watch_ids.has(id)),
			"people: by a town's road the scenes were %s, not the Watch beset" % [seen_by_town.slice(0, 5)])
	_expect(seen_in_open.all(func(id) -> bool: return not watch_ids.has(id)), "people: the Watch was beset out in the open country")
	var met := Roadside.meeting(world, ring, str(watch_ids[0]), GameState.party_characters(), world.rng)
	var allies: Array = met.get("map", {}).get("allies", [])
	_expect(allies.size() == 2 and allies.all(func(a: Dictionary) -> bool: return str(a.get("name", "")) == "a watchman"),
			"people: the Watch beset does not fight beside the party (%s)" % [allies])

	# Climbers resting by a floor's stair, who talk.
	var climbers: Dictionary = Database.world_rules.get("life", {}).get("climbers", {}).get("on_the_floors", {})
	var floor := -1
	for f in range(int(climbers.get("from", 2)), 60):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([world.world_seed, f, "climbers"])
		if rng.randf() < float(climbers.get("chance", 0.4)):
			floor = f
			break
	_expect(floor > 0, "people: no Tower floor has climbers resting on it")
	if floor > 0:
		var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
		scene.set("boot_payload", { "area_id": Chapters.walked_floor_area(floor), "return_scene": "world", "tower_floor": floor })
		add_child(scene)
		for i in 5:
			await get_tree().process_frame
		var resting: Array = (scene.get("map") as AreaMap).people.filter(func(p: Dictionary) -> bool: return str(p.get("_area", "")) == "climbers_floor")
		_expect(resting.size() >= 2 and not (resting[0].get("talk", {}) as Dictionary).get("hello", []).is_empty(),
				"people: floor %d has no company resting by its stair to talk to (%d)" % [floor, resting.size()])
		scene.queue_free()
		await get_tree().process_frame
	print("people: %d bands by the road, the Watch beset by a town's road, climbers on floor %d" % [by_road, floor])


func _expect(ok: bool, message: String) -> void:
	if not ok:
		_fail(message)


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
		# A walled town ([D85]): its corners stand in the way, and the way in is still the way in.
		if Database.area(area_id).has("walls"):
			if land.is_walkable(rect.position - Vector2i.ONE):
				_fail("land: %s has walls in its data but none round it on the land" % town.display_name)
			var gate: Vector2i = alone.exits[0] if not alone.exits.is_empty() else Vector2i.ZERO
			var outside := (place["origin"] as Vector2i) + AreaMap.to_cell(place["spawn"])
			if land.find_cell_path(outside, rect.position + AreaMap.to_cell(Database.area(area_id).get("spawn", [0, 0]))).is_empty():
				_fail("land: %s's walls leave no way in" % town.display_name)
			var hub := rect.position + gate + Vector2i.DOWN
			for corner: Vector2i in [rect.position + Vector2i(-2, -2), rect.end + Vector2i(1, 1)]:
				if land.slot_rect(town.cell).has_point(corner) and land.is_walkable(corner) \
						and land.find_cell_path(corner, hub).is_empty():
					_fail("land: the lane round %s's walls does not reach the gate from %s" % [town.display_name, corner])

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
	# Walking itself ([D94]): on over the land into the next tile, and never off to the map.
	asked.clear()
	var before := _requests.size()
	var setting := Pace.auto
	Pace.auto = true
	for i in 900:
		await get_tree().physics_frame
		if not asked.is_empty():
			break
	Pace.auto = setting
	for request: Dictionary in _requests.slice(before):
		if str(request["key"]) == "world":
			_fail("land: a party walking itself was sent off the ground to the map")
	if asked.is_empty() or AreaMap.to_cell(asked[0].get("step", [0, 0])) == Vector2i.ZERO:
		_fail("land: a party walking itself never walked over into the next tile")
	if not scene.is_inside_tree() or scene._leaving:
		_fail("land: the ground left the screen while the party walked itself")
	EventBus.continent_requested.disconnect(listen)
	scene.queue_free()
	await get_tree().process_frame
	print("land: tiles walk into each other, %s stands in its tile, a band walks across, a step keeps to the land, and so does walking itself" % town.display_name)


## The small panel on the ground ([D244]): a row for each of the company with a health bar, and the
## purse; out of the way while a box is open.
func _check_play_hud() -> void:
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "village", "return_scene": "world" })
	add_child(scene)
	await get_tree().process_frame
	var hud: Control = scene._play_hud
	if hud == null:
		_fail("play hud: no panel on the ground")
	else:
		hud.refresh()
		var party := GameState.party_characters()
		_expect_tut(hud._rows.get_child_count() == party.size(),
			"play hud: %d rows for a company of %d" % [hud._rows.get_child_count(), party.size()])
		_expect_tut(hud._purse.text.contains(str(GameState.gold)), "play hud: the purse says %s, not %d" % [hud._purse.text, GameState.gold])
		var hurt: Character = party[0]
		var was := hurt.hp
		hurt.hp = maxi(1, hurt.max_hp() / 5)
		hud.refresh()
		var bar: ColorRect = hud._rows.get_child(0).get_child(1).get_child(1).get_child(0)
		_expect_tut(bar.color.r > bar.color.g, "play hud: a lead at a fifth of their health shows a bar that is not red")
		# What wants attention (D245): someone badly hurt and a path owed show as alerts, and pressing
		# the path's opens the party screen.
		var Alerts := preload("res://src/ui/alerts.gd")
		var wanted := Alerts.gather()
		_expect_tut(wanted.any(func(a: Dictionary) -> bool: return str(a["id"]) == "hurt:" + hurt.id),
			"play hud: %s at a fifth of their health raises no alert" % hurt.display_name)
		hurt.pending_class_choice = true
		hud.refresh()
		var owed := Alerts.gather().filter(func(a: Dictionary) -> bool: return str(a["id"]) == "path:" + hurt.id)
		_expect_tut(owed.size() == 1, "play hud: a path owed raises no alert")
		_expect_tut(hud._alerts.get_child_count() >= 2, "play hud: %d alerts shown, not 2" % hud._alerts.get_child_count())
		var opened := [0]
		var on_open := func() -> void: opened[0] += 1
		EventBus.party_screen_requested.connect(on_open)
		if not owed.is_empty():
			hud.act_on(owed[0])
		EventBus.party_screen_requested.disconnect(on_open)
		_expect_tut(opened[0] == 1, "play hud: pressing the path's alert did not open the party screen")
		hurt.pending_class_choice = false
		hurt.hp = was
		scene._physics_process(1.0 / 60.0)
		print("play hud: %d rows and %s" % [hud._rows.get_child_count(), hud._purse.text])
	scene.queue_free()
	await get_tree().process_frame


## Play-test 4's small fixes ([D189]): a click on the ground puts a pin there with a line to it,
## gone on arrival; a shut door is tried once per arrival, not every frame; the baker sells only
## what she bakes; the speeds are 1×, 2×, 3× and 5×.
func _check_play_test_four() -> void:
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "city_streets", "return_scene": "world" })
	add_child(scene)
	await get_tree().process_frame
	var map: AreaMap = scene.map
	var from: Vector2i = map.cell_at(scene._leader.position)
	var goal := Vector2i(-1, -1)
	for radius in range(3, 9):
		for cell: Vector2i in [from + Vector2i(radius, 0), from + Vector2i(-radius, 0), from + Vector2i(0, -radius), from + Vector2i(0, radius)]:
			if goal.x < 0 and map.is_walkable(cell) and map.door_at(cell).is_empty() and map.find_cell_path(from, cell).size() > 2:
				goal = cell
	if goal.x < 0:
		_fail("play-test 4: nowhere open in the streets to click on")
	else:
		scene._walk_to(map.centre_of(goal))
		scene._physics_process(1.0 / 60.0)
		if scene._waymark._way.is_empty():
			_fail("play-test 4: a click on the ground put no pin where it was")
		for i in 300:
			scene._physics_process(1.0 / 60.0)
			if scene._click_path.is_empty():
				break
		scene._physics_process(1.0 / 60.0)
		if not scene._waymark._way.is_empty():
			_fail("play-test 4: the pin stayed after the party got there")
	# Leaning on a shut door: it says so once, not every frame.
	var doors := [0]
	var count := func(what: String) -> void:
		if what.begins_with("door:"):
			doors[0] += 1
	EventBus.player_did.connect(count)
	var shut := Vector2i(-1, -1)
	for building: Dictionary in map.buildings:
		if shut.x < 0 and not Database.has_area(str(building.get("area", ""))) and not building.has("fight"):
			shut = building["door"]
	if shut.x < 0:
		_fail("play-test 4: the streets have no shut door to lean on")
	else:
		scene._on_doorstep = Vector2i(-1, -1)
		for i in 30:
			scene._arrive_at(shut)
		if doors[0] != 1:
			_fail("play-test 4: a shut door was tried %d times in 30 frames, not once" % doors[0])
	EventBus.player_did.disconnect(count)
	scene.queue_free()
	await get_tree().process_frame
	for person: Dictionary in Database.area("city_streets").get("people", []):
		if str(person.get("name", "")) == "Ada the Baker":
			for ware: Dictionary in person.get("talk", {}).get("sells", []):
				if not ["bread", "meat_pie", "honey_cake"].has(str(ware.get("item", ""))):
					_fail("play-test 4: Ada the Baker sells %s, which she did not bake" % ware.get("item", ""))
	if Pace.SPEEDS != [1.0, 2.0, 3.0, 5.0]:
		_fail("play-test 4: the speeds are %s, not 1x, 2x, 3x and 5x" % [Pace.SPEEDS])
	print("play-test 4: a click puts a pin and a line, a shut door is tried once, the baker bakes, speeds 1/2/3/5")


## Followers face the way they walk ([D214], play-test 4: walking down, "my characters that are
## followed behind me are facing the wrong way"). A party of four walks up a clear stretch and then
## back down it at walking pace, a frame at a time; once the turn is behind them (forty frames),
## nobody following faces back the way the leader came. Before the fix a follower keeping pace was
## never turned again, so the second leg was walked looking up.
func _check_followers_face() -> void:
	GameState.new_game(SEED)
	Company.join(GameState.roster, ["juno", "cato", "vesta"])
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "city_streets", "return_scene": "world" })
	add_child(scene)
	await get_tree().process_frame
	var map: AreaMap = scene.map
	var followers: Array = scene._followers
	# A column of open ground fourteen cells long to walk up and down.
	var top := Vector2i(-1, -1)
	for y in range(1, map.height - 15):
		for x in range(1, map.width - 1):
			if top.x >= 0:
				break
			var clear := true
			for dy in 15:
				for dx in [-1, 0, 1]:
					if not map.is_walkable(Vector2i(x + dx, y + dy)):
						clear = false
			if clear:
				top = Vector2i(x, y)
	if followers.size() != 3 or top.x < 0:
		_fail("followers: %d followers, and open ground at %s" % [followers.size(), top])
		scene.queue_free()
		await get_tree().process_frame
		return
	var bottom := map.centre_of(top + Vector2i(0, 14))
	scene._leader.position = bottom
	for f: Node2D in followers:
		f.position = bottom
	scene._reseed_crumbs()
	var wrong: Array[String] = []
	var delta := 1.0 / 60.0
	for leg: Vector2 in [Vector2.UP, Vector2.DOWN]:
		for frame in 110:
			scene._leader.position += leg * scene._walk_speed() * delta
			scene._leader.face(leg)
			scene._drop_crumbs()
			scene._settle_followers(delta)
			if frame < 40:
				continue
			for i in followers.size():
				var facing: Vector2 = followers[i].get("_facing")
				if facing.dot(leg) < -0.1:
					wrong.append("walking %s, follower %d faces %s at frame %d" % [leg, i, facing, frame])
	if not wrong.is_empty():
		_fail("followers face the wrong way: %s (and %d more)" % [wrong[0], wrong.size() - 1])
	else:
		print("followers: walking up and then down, everyone following faces the way they walk")
	scene.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED)


## Footpaths, dirt tracks and signposts ([D233]): tracks join the places people live, a tile on
## one has the track's ground and sheet, every tile's worn paths are footpaths, and where three ways
## meet a signpost stands and names somewhere each way.
func _check_tracks() -> void:
	GameState.new_game(SEED)
	var world: World = GameState.world
	var Tracks := preload("res://src/area/tracks.gd")
	var joined := 0
	for site: Site in Tracks.places(world):
		if not Tracks.sides(world, site.cell).is_empty():
			joined += 1
	if joined * 2 < Tracks.places(world).size():
		_fail("tracks: only %d of %d places have a track to them" % [joined, Tracks.places(world).size()])
	var on_track := Vector2i(-1, -1)
	var post := Vector2i(-1, -1)
	for y in world.size.y:
		for x in world.size.x:
			var tile := Vector2i(x, y)
			if on_track.x < 0 and world.site_at(tile) == null and not Tracks.sides(world, tile).is_empty() \
					and Tracks.ways(world, tile).size() == Tracks.sides(world, tile).size():
				on_track = tile
			if post.x < 0 and Tracks.signpost(world, tile) != "":
				post = tile
	if on_track.x < 0 or post.x < 0:
		_fail("tracks: no open tile on a track (%s) or no signpost anywhere (%s)" % [on_track, post])
		return
	var slot := GroundGen.slot(world, on_track)
	var ground: PackedStringArray = slot.get("terrain", PackedStringArray())
	if not ground.has("track"):
		_fail("tracks: a tile on a track has no track on its ground")
	var layers: Array = (slot.get("patches", [{}]) as Array)[0].get("layers", [])
	if not layers.has("track") or not layers.has("footpath"):
		_fail("tracks: a tile on a track does not draw the track and footpath sheets (%s)" % [layers])
	var says := Tracks.signpost(world, post)
	var standing := (GroundGen.slot(world, post).get("props", []) as Array).filter(
		func(prop: Dictionary) -> bool: return str(prop.get("line", "")) == says)
	if standing.size() != 1 or not says.begins_with("A signpost.") or says.contains("Where You Fell"):
		_fail("tracks: the signpost at %s stands %d times and says %s" % [post, standing.size(), says])
	print("tracks: %d of %d places joined, a track laid on its tiles, a signpost: %s" % [joined, Tracks.places(world).size(), says])


## Play-test 3's small fixes ([D178]): a click on open ground walks the party there; Atlas met
## standing somewhere is drawn as the Atlas who joins (in Sky's saddle); the lighthouse's beam turns
## at its own slower pace.
func _check_play_test_three() -> void:
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "village", "return_scene": "world" })
	add_child(scene)
	await get_tree().process_frame
	var map: AreaMap = scene.map
	var from: Vector2i = map.cell_at(scene._leader.position)
	var goal := Vector2i(-1, -1)
	for radius in range(4, 9):
		for cell: Vector2i in [from + Vector2i(radius, 0), from + Vector2i(-radius, 0), from + Vector2i(0, -radius)]:
			if goal.x < 0 and map.is_walkable(cell) and map.find_cell_path(from, cell).size() > 2:
				goal = cell
	if goal.x < 0:
		_fail("play-test 3: nowhere open near the village's way in to click on")
	else:
		scene._walk_to(map.centre_of(goal))
		for i in 240:
			scene._physics_process(1.0 / 60.0)
			if map.cell_at(scene._leader.position) == goal:
				break
		if map.cell_at(scene._leader.position) != goal:
			_fail("play-test 3: a click on open ground did not walk the party there (at %s, wanted %s)" % [map.cell_at(scene._leader.position), goal])
	scene.queue_free()
	await get_tree().process_frame
	var standing := AreaActor.for_person({ "name": "Atlas", "unit": "atlas" })
	var joined := AreaActor.for_character(Character.create("atlas"))
	if standing.body_scale != joined.body_scale or standing._rotations.get("south") != joined._rotations.get("south"):
		_fail("play-test 3: Atlas standing in a town is not drawn as the Atlas who joins")
	standing.free()
	joined.free()
	if float(Database.prop_size("landmark/lighthouse").get("frame_seconds", 0.13)) <= 0.13:
		_fail("play-test 3: the lighthouse still blinks at the quick pace")


## Life on the land ([D179]): the tiles round the party have birds, butterflies and the like on
## them; a bird takes off when the leader walks up to it and comes down further off; and on the
## First Hour's road the city's Watch walks its rounds.
func _check_life_on_the_land() -> void:
	var world: World = GameState.world
	var road_tile := Vector2i(-1, -1)
	for y in world.size.y:
		for x in world.size.x:
			var tile := Vector2i(x, y)
			if road_tile.x < 0 and not FirstRoad.sides(world, tile).is_empty() and world.site_at(tile) == null:
				var rng := RandomNumberGenerator.new()
				rng.seed = hash([world.shape_seed(), tile.x, tile.y, "watch"])
				if rng.randf() < float(Database.world_rules["life"]["road_watch"]["chance"]):
					road_tile = tile
	if road_tile.x < 0:
		_fail("life: no tile of the road with the Watch on it")
		return
	world.player_cell = road_tile
	GameState.land_cell = null
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "land": true, "return_scene": "world", "planar_mode": true })
	add_child(scene)
	await get_tree().process_frame
	var critters: Array = scene.get_node("Actors").get_children().filter(
		func(n: Node) -> bool: return n.get_script() == AreaCritter)
	var lives := {}
	for c: Node2D in critters:
		lives[c.life] = true
	if critters.size() < 9 or not lives.has("bird") or not lives.has("flutter"):
		_fail("life: the land round the party is empty (%d creatures, %s)" % [critters.size(), lives.keys()])
	var watch: Array = scene._people.filter(func(a: AreaActor) -> bool:
		return str((a.get_meta("person", {}) as Dictionary).get("_area", "")) == "road_watch")
	if watch.size() < 2 or watch.size() % 2 != 0:
		_fail("life: the Watch is not walking the road at %s in pairs (%d of them)" % [road_tile, watch.size()])
	elif not watch[0].can_talk():
		_fail("life: the Watch on the road will not talk")
	else:
		# Trouble led to the Watch (D236): a band setting on the party beside them brings them into
		# the fight, out of their walk, and a win pays their bounty.
		var leader_was: Vector2 = scene._leader.position
		scene._leader.position = (watch[0] as AreaActor).position + Vector2(AreaMap.CELL, 0)
		var field := {}
		scene._call_the_watch(field)
		var came: Array = field.get("allies", [])
		if came.is_empty() or int(field.get("watch", 0)) != came.size() or (watch[0] as AreaActor).visible:
			_fail("watch: a band set on the party beside the Watch, and they did not come (%s)" % field)
		elif str((came[0] as Dictionary).get("unit", "")) == "" or int((came[0] as Dictionary).get("level", 0)) < 1:
			_fail("watch: the Watch came without a unit or level (%s)" % came[0])
		var gold_was := GameState.gold
		var thanks := Roadside.watch_thanks(world, road_tile, GameState.party_characters())
		if GameState.gold <= gold_was or thanks.is_empty():
			_fail("watch: beating a band with the Watch paid no bounty")
		scene._leader.position = leader_was
		for actor: AreaActor in scene._watch_fighting:
			actor.visible = true
		scene._watch_fighting.clear()
	var bird: Node2D = null
	for c: Node2D in critters:
		if c.life == "bird" and c.visible:
			bird = c
			break
	if bird != null:
		var was := bird.position
		scene._leader.position = bird.position + Vector2(40, 0)
		for i in 120:
			bird._process(1.0 / 60.0)
		if bird.position.distance_to(was) < AreaMap.CELL * 2.0:
			_fail("life: a bird stayed put with the leader standing over it")
	scene.queue_free()
	await get_tree().process_frame
	print("life: %d creatures round the party (%s), a bird took off, and the Watch walks the road and comes to a fight" % [critters.size(), ", ".join(lives.keys())])
