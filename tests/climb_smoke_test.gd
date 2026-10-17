extends Node
## The First Hour's climb, played through the game's own scenes (meeting 4, D115, D120): Atlas at
## the Tower's door, up floors 1 to 5, out to a gate and back, and into the Tower again.
##
##   godot --headless --path . res://tests/climb_smoke_test.tscn
##
## Ewan's second play-test (2026-10-15) stopped at floor 2: the stair put him back in the world, the
## Tower would not let him in again (B1), and walking away from a gate dropped him into its second
## floor (B2). Each is checked here, through the same scene changes a player makes.

const SEED := 20260829
const Chapters := preload("res://src/chronicle/chapters.gd")
const AutoRoad := preload("res://src/world/auto_road.gd")
const Route := preload("res://src/world/route.gd")
const Guild := preload("res://src/chronicle/guild.gd")
## Frames a scene change is given to settle before the check gives up on it.
const PATIENCE := 240

var _failures: Array[String] = []
var _game: Node = null


func _ready() -> void:
	_game = load("res://src/main.tscn").instantiate()
	add_child(_game)
	await _frames(5)
	_new_run()
	await _two_packs_at_once()
	_new_run()
	await _climb_to_the_top()
	_new_run()
	await _auto_climbs()
	_new_run()
	await _auto_walks_to_the_door()
	_new_run()
	await _roadside_stands()
	await _the_warden_counts()

	print("")
	if _failures.is_empty():
		print("climb smoke test: PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			print("FAIL: %s" % failure)
		get_tree().quit(1)


## Atlas, alone, at the Tower's foot with the Guild's mark (a gate already shut, D101).
func _new_run() -> void:
	GameState.new_game(SEED, "atlas")
	GameState.set_flag("seen:prologue")
	var world: World = GameState.world
	world.tower_sealed_at = -1
	world.player_cell = world.tower().cell
	Pace.auto = false


## Ewan's run, played as he played it (meeting 4): into the yard, a level gained on the way so a
## path waits to be chosen, through the door, up floors 1 and 2 (the stair goes straight on, D115),
## down the way he came in, out to a gate, a floor of it won and walked away from (B2), back to
## the Tower, whose door still climbs (B1), and on to floor 5, whose keeper sends the party out.
func _climb_to_the_top() -> void:
	var atlas := GameState.roster.player()
	Progression.award(atlas, Progression.xp_to_next(atlas.level) * 3, GameState.world)
	_expect(atlas.pending_class_choice or atlas.rungs > 0, "climb: Atlas levelled with nothing to choose, so B1 goes unchecked")
	if not await _in_by_the_door("with a path to choose"):
		return
	for floor in [1, 2]:
		if not await _up_the_stair(floor):
			return
	# Floor 3, left by the way in: back down in the yard, the floors climbed kept.
	var three := await _scene_where(func(s: Node) -> bool: return _floor_of(s) == 3)
	if three == null:
		_fail("climb: the stair of floor 2 did not go on to floor 3 (on %s)" % _describe(_current()))
		return
	three.call("_leave")
	_expect(await _scene_where(func(s: Node) -> bool: return _is_land(s)) != null, "climb: the way down from floor 3 did not come out in the yard")
	_expect(GameState.world.tower_floor == 2, "climb: two floors climbed but the Tower counts %d" % GameState.world.tower_floor)

	await _out_to_a_gate_and_back()

	if not await _in_by_the_door("after the gate"):
		return
	for floor in [3, 4, 5]:
		if not await _up_the_stair(floor):
			return
	var out := await _scene_where(func(s: Node) -> bool: return _is_land(s))
	_expect(out != null, "climb: the keeper's floor did not bring the party back out (on %s)" % _describe(_current()))
	_expect(GameState.world.tower_floor == 5, "climb: five floors climbed but the Tower counts %d" % GameState.world.tower_floor)
	# AK (D149): one of the other sixteen's lights went out as floor 5 was won, never the lead or
	# anyone in the company, and the census counts them out.
	var went: Dictionary = GameState.world.echoes.get("light_out", {})
	_expect(not went.is_empty(), "climb: floor 5 won and no light went out")
	var company: Array = []
	for hero: Character in GameState.roster.characters:
		company.append(hero.template_id)
	_expect(not company.has(str(went.get("hero", ""))), "climb: the light that went out was %s, who is in the company" % went.get("hero", ""))
	_expect(Chapters.census(GameState.world) == 15, "climb: the census after the hour's end is %d, not 15" % Chapters.census(GameState.world))
	_expect(FirstHour.put_out_a_light(GameState.world, 5, company).is_empty(), "climb: a second light went out on floor 5")


## D184 (D174): the floor 5 keeper speaks as its fight begins and counts the challengers. Atlas,
## the first life, hears that the first challenger arrives, by name; once Atlas has fallen, the next
## lead hears that the second approaches; the sixteenth hears that they are the last. The fallen are
## kept in a file of the suite's own, so a real record is never touched.
func _the_warden_counts() -> void:
	var Sixteen := preload("res://src/chronicle/sixteen.gd")
	Sixteen.path = "user://earth-kings.sixteen.climb-test.json"
	if FileAccess.file_exists(Sixteen.path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Sixteen.path))
	var heard := await _the_warden_says("atlas")
	_expect(heard.contains("first challenger arrives"), "climb: Atlas, the first life, heard \"%s\" from the Warden" % heard)
	_expect(heard.contains(GameState.roster.player().display_name), "climb: the Warden did not name Atlas (\"%s\")" % heard)
	Sixteen.fall("atlas")
	var next := ""
	for hero_id: String in Database.heroes:
		if hero_id != "atlas":
			next = hero_id
			break
	heard = await _the_warden_says(next)
	_expect(heard.contains("second challenger approaches"), "climb: the second life, %s, heard \"%s\" from the Warden" % [next, heard])
	var many := 0
	for hero_id: String in Database.heroes:
		if hero_id != next and many < 15:
			Sixteen.fall(hero_id)
			many += 1
	if many == 15:
		var last := str(FirstHour.warden_line("tower5_keeper", next, "Them").get("text", ""))
		_expect(last.contains("sixteenth and final challenger"), "climb: the sixteenth life heard \"%s\"" % last)
	_expect(FirstHour.warden_line("tower5_a", next, "Them").is_empty(), "climb: a band that is not the keeper spoke the Warden's line")
	if FileAccess.file_exists(Sixteen.path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Sixteen.path))
	Sixteen.path = Sixteen.DEFAULT_PATH


## [param lead] at the Tower's door, floor 5 opened, and the keeper's fight begun where it stands:
## what the conversation box was asked to show as it began.
func _the_warden_says(lead: String) -> String:
	GameState.new_game(SEED, lead)
	GameState.set_flag("seen:prologue")
	var world: World = GameState.world
	world.tower_sealed_at = -1
	world.tower_floor = 4
	Pace.auto = false
	if not await _in_by_the_door("for the Warden (%s)" % lead):
		return ""
	var five := _current()
	var keeper: Node2D = null
	for watch: Node2D in five.get("_watches"):
		if str(watch.band.get("key", "")) == "tower5_keeper":
			keeper = watch
	if keeper == null:
		_fail("climb: floor 5 has no keeper standing for %s" % lead)
		return ""
	var heard: Array = []
	var listen := func(lines: Array) -> void: heard.append_array(lines)
	EventBus.conversation_requested.connect(listen)
	five.call("_fight_held", keeper, {}, false)
	EventBus.conversation_requested.disconnect(listen)
	var fight: Node = five.get("_fight")
	if fight != null:
		(fight.get("boot_payload") as Dictionary)["sandbox"] = true
		five.call("_after_the_fight")
	await _frames(2)
	var box := _game.get_node_or_null("DialogueBox")
	for i in 4:
		if box != null and box.has_method("is_open") and box.is_open():
			box.call("_advance")
	for line: Variant in heard:
		if line is Dictionary and str((line as Dictionary).get("speaker", "")) == "The Warden of the Fifth":
			return str((line as Dictionary).get("text", ""))
	return ""


## The yard, from the Tower's tile, and E at the door: true once the next floor is up.
func _in_by_the_door(when: String) -> bool:
	var world: World = GameState.world
	world.player_cell = world.tower().cell
	EventBus.request_scene.emit("world", {})
	var yard := await _scene_where(func(s: Node) -> bool: return _is_land(s))
	if yard == null:
		_fail("climb: the Tower's yard never came up %s" % when)
		return false
	var door := _door_in(yard)
	if door == null:
		_fail("climb: no door in the Tower's yard %s" % when)
		return false
	if (yard.call("_act_of", door) as Dictionary).is_empty():
		_fail("climb: %s the Tower's door does not climb (B1; the yard offers %s)" % [when, yard.get("_acts")])
		return false
	var next := world.tower_floor + 1
	yard.call("_examine", door)
	if await _scene_where(func(s: Node) -> bool: return _floor_of(s) == next) == null:
		_fail("climb: the door did not open onto floor %d %s (on %s)" % [next, when, _describe(_current())])
		return false
	return true


## Auto, switched on inside floor 1, walks to the stair (fighting what it meets) and climbs it, not
## back out the way in.
func _auto_climbs() -> void:
	if not await _in_by_the_door("for Auto"):
		return
	Pace.auto = true
	var up := await _scene_where(func(s: Node) -> bool: return _floor_of(s) == 2 or _is_land(s), PATIENCE * 30)
	Pace.auto = false
	if up == null or _floor_of(up) != 2:
		_fail("climb: Auto on floor 1 did not climb to floor 2 (on %s)" % _describe(_current()))
	# AM (D150): Auto fights only trash. It stops for a gate's fight, a keeper, and a foe more than
	# a level over the lead, and hands that fight over paused.
	_expect(not FirstHour.auto_stops_for([{"unit": "slime", "level": 2}], "tower", 1), "climb: Auto stops for a floor 1 slime")
	_expect(FirstHour.auto_stops_for([{"unit": "king_slime", "level": 9, "boss": true}], "tower", 9), "climb: Auto fights the keeper itself")
	_expect(FirstHour.auto_stops_for([{"unit": "goblin", "level": 1}], "gate", 5), "climb: Auto fights a gate's fight itself")
	_expect(FirstHour.auto_stops_for([{"unit": "wolf", "level": 6}], "", 4), "climb: Auto fights a band two levels over the lead")
	var floor_now := _current()
	if _floor_of(floor_now) > 0:
		Pace.auto = true
		floor_now.call("_fight_here", {"encounter": {"enemies": [{"unit": "slime", "level": 30, "boss": true}], "title": "A test"}, "field": {}})
		var fight: Node = floor_now.get("_fight")
		_expect(fight != null and bool(fight.get("paused")) and not Pace.auto, "climb: Auto did not stop and hand over a keeper's fight")
		if fight != null:
			(fight.get("boot_payload") as Dictionary)["sandbox"] = true
			floor_now.call("_after_the_fight")
		_expect(not bool(floor_now.get("_auto_after_fight")), "climb: a lost stopped fight left Auto waiting to walk on")
		Pace.auto = false
		# AM (D150, the five strangers): a memory of the lead's lying on the floor is where Auto
		# heads before the stair, so Auto never climbs past chapter one.
		var floor_map: Variant = floor_now.get("map")
		if not floor_map.exits.is_empty():
			var glint: Vector2i = floor_map.exits[0]
			floor_now.set("_memories", {glint: {"id": "test"}})
			(floor_now.get("_auto_exit_path") as Array).clear()
			floor_now.call("_auto_axis")
			var path: Array = floor_now.get("_auto_exit_path")
			_expect(not path.is_empty() and floor_map.cell_at(path.back()) == glint,
				"climb: Auto on a floor with a memory lying there did not head for it before the stair")
			floor_now.set("_memories", {})
			(floor_now.get("_auto_exit_path") as Array).clear()


## D197: Auto, a gate shut and the Tower next, walks from two tiles off over the Tower's tile to its
## door and stops there, "E to climb" up; switched on again at the door it goes in. Before, it
## stopped where it crossed onto the tile and, switched on again, wandered off and back for good.
func _auto_walks_to_the_door() -> void:
	var world: World = GameState.world
	var tower := world.tower()
	GameState.set_flag(AutoRoad.TOWN_REACHED)
	GameState.set_flag(Guild.VISITED)
	for gate: Site in world.sites_of_kind(Site.GATE):
		gate.cleared = true
		break
	world.prowlers.clear()
	# A world nobody has stepped in yet is stocked with bands as it opens (and since D215 some camp by
	# the road): this walk is about the door, not the bands, so it is one already walked.
	world.steps = maxi(world.steps, 1)
	# No band restocks on the way, or Auto goes after it first, as it should.
	var bands: Variant = Database.encounters.get("bands", 0)
	Database.encounters["bands"] = 0
	var start := Vector2i(-1, -1)
	for side: Vector2i in [Vector2i(0, 2), Vector2i(0, -2), Vector2i(2, 0), Vector2i(-2, 0)]:
		var cell := tower.cell + side
		if world.is_walkable(cell) and Route.between(world, cell, tower.cell, 0).size() == 2:
			start = cell
			break
	if start.x < 0:
		_fail("auto to the door: no open ground two tiles from the Tower")
		Database.encounters["bands"] = bands
		return
	world.player_cell = start
	EventBus.request_scene.emit("world", {})
	var land := await _scene_where(func(s: Node) -> bool: return _is_land(s))
	if land == null:
		_fail("auto to the door: the land never came up")
		Database.encounters["bands"] = bands
		return
	_expect(bool(AutoRoad.objective(world).get("door", false)), "auto to the door: the Tower is not where Auto is headed (%s)" % AutoRoad.objective(world))
	Pace.auto = true
	var at_door := await _scene_where(func(s: Node) -> bool: return _is_land(s) and s.get("_auto_at_door") == true, PATIENCE * 30)
	if at_door == null:
		_fail("auto to the door: Auto never stood at the Tower's door (at %s, auto %s, on %s)" % [world.player_cell, Pace.auto, _describe(_current())])
		Pace.auto = false
		Database.encounters["bands"] = bands
		return
	_expect(not Pace.auto, "auto to the door: Auto walked on past the Tower's door without handing back")
	_expect(world.player_cell == tower.cell, "auto to the door: stopped at %s, not on the Tower's tile" % world.player_cell)
	Pace.auto = true
	var inside := await _scene_where(func(s: Node) -> bool: return _floor_of(s) == 1, PATIENCE * 4)
	Pace.auto = false
	Database.encounters["bands"] = bands
	_expect(inside != null, "auto to the door: switched on again at the door, Auto did not go in (on %s)" % _describe(_current()))


## D131: a roadside scene come upon on the land stands there to be seen (the cart, the driver, the
## four round him), and goes when a fight starts.
func _roadside_stands() -> void:
	var world: World = GameState.world
	world.player_cell = world.home().cell
	EventBus.request_scene.emit("world", {})
	var land := await _scene_where(func(s: Node) -> bool: return _is_land(s))
	if land == null:
		_fail("roadside: the land never came up")
		return
	land.call("_stage_roadside", "trader_ambush")
	var staged: Array = land.get("_roadside_nodes")
	_expect(staged.size() == 6, "roadside: the stopped cart stood %d things on the ground, not the cart, the driver and four" % staged.size())
	land.call("_stage_roadside", "")
	_expect((land.get("_roadside_nodes") as Array).is_empty(), "roadside: walking off left the scene standing")


## Standing at [param floor]'s stair and climbing it.
func _up_the_stair(floor: int) -> bool:
	var on := await _scene_where(func(s: Node) -> bool: return _floor_of(s) == floor)
	if on == null:
		_fail("climb: floor %d never came up; the stair below did not go on to it (on %s)" % [floor, _describe(_current())])
		return false
	_floor_is_dressed(on, floor)
	on.call("_climb_the_stair")
	return true


## A floor shows its stair up and lit runes on its walls (D132).
func _floor_is_dressed(on: Node, floor: int) -> void:
	var stair := 0
	var runes := 0
	for node in on.find_children("*", "", true, false):
		if node is AreaProp:
			var art := str((node as AreaProp).art)
			if art == "tower_inside/stair_up":
				stair += 1
			elif art.begins_with("tower_inside/rune_"):
				runes += 1
	_expect(stair == 2, "floor %d: %d halves of the stair up stand on it, not 2" % [floor, stair])
	_expect(runes >= 4, "floor %d: only %d lit runes on its walls" % [floor, runes])


## The nearest open gate deeper than one floor: walked onto, its first floor won, walked away from.
## The walk away is a walk, not the gate's next floor (B2).
func _out_to_a_gate_and_back() -> void:
	var world: World = GameState.world
	var gate: Site = null
	for site: Site in world.sites_of_kind(Site.GATE):
		if site.cleared or site.floors() < 2:
			continue
		if gate == null or _apart(site.cell, world.tower().cell) < _apart(gate.cell, world.tower().cell):
			gate = site
	if gate == null:
		_fail("gate: no gate deeper than one floor to walk out of")
		return
	if not gate.open:
		world.open_gate(gate)
	var beside := Vector2i(-1, -1)
	for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if world.is_walkable(gate.cell + side) and world.site_at(gate.cell + side) == null:
			beside = gate.cell + side
	if beside == Vector2i(-1, -1):
		_fail("gate: %s has no open ground beside it" % gate.display_name)
		return
	world.player_cell = beside
	EventBus.request_scene.emit("world", {})
	var land := await _scene_where(func(s: Node) -> bool: return _is_land(s))
	if land == null:
		_fail("gate: the land beside %s never came up" % gate.display_name)
		return
	var into := gate.cell - beside
	land.call("_ask_the_continent", { "step": [into.x, into.y] })
	# Walking onto the gate is not going in (D116): the land stays, and E beside it is offered.
	await _frames(30)
	_expect(_is_land(_current()), "gate: walking onto %s started its fight without being asked (on %s)" % [gate.display_name, _describe(_current())])
	land = _current()
	var enter: Dictionary = {}
	for each: Dictionary in land.get("_acts"):
		if str(each.get("act", "")) == "_enter_gate_here":
			enter = each
	_expect(str(enter.get("prompt", "")).ends_with("to enter %s (rank %s)" % [gate.display_name, gate.rank]),
		"gate: standing at %s does not offer to enter it (offers %s)" % [gate.display_name, land.get("_acts")])
	land.call("_do_act", enter)
	# A gate far above the company asks twice (D245): the first E says so, the second goes in.
	if bool(land.call("_gate_too_strong", gate)):
		_expect(land.get("_fight") == null and int(land.get("_gate_warned_until")) > 0,
			"gate: %s, far above the company, was gone into without a word" % gate.display_name)
		land.call("_do_act", enter)
	# Fought where the party stands, on the land, never on a fight screen of its own (D162).
	var fight: Node = null
	for i in PATIENCE:
		await get_tree().process_frame
		if _current() != land:
			break
		fight = land.get("_fight")
		if fight != null:
			break
	if fight == null:
		_fail("gate: E at %s started no fight on the land (on %s)" % [gate.display_name, _describe(_current())])
		return
	_expect(bool(fight.get("in_place")) and fight.get_parent() == land,
		"gate: %s's fight is not laid on the land it was gone into from" % gate.display_name)
	_expect(not (fight.get("encounter") as Dictionary).get("enemies", []).is_empty(),
		"gate: %s's fight on the land has nobody keeping the gate" % gate.display_name)
	# Won, as the fight settles it.
	fight.set("victory", true)
	GameState.set_flag("last_victory", true)
	fight.emit_signal("gone")
	for i in PATIENCE:
		await get_tree().process_frame
		if land.get("_fight") == null and not bool(land.get("_asking")) and not bool(land.get("_talking")):
			break
	_expect(_is_land(_current()) and _current() == land,
		"gate: winning %s's first floor did not stay on the land (on %s)" % [gate.display_name, _describe(_current())])
	_expect(gate.depth() == 1, "gate: %s's first floor won but its depth is %d" % [gate.display_name, gate.depth()])
	land.call("_ask_the_continent", { "step": [-into.x, -into.y] })
	await _frames(30)
	var after := _current()
	_expect(_is_land(after), "gate: walking away from %s after its first floor put the party in %s (B2)" % [gate.display_name, _describe(after)])
	_expect(world.player_cell == beside, "gate: walking away from %s did not move the party off it" % gate.display_name)
	_expect(GameState.delving.is_empty(), "gate: walked away from %s but still held inside it" % gate.display_name)
	_expect(gate.depth() == 1, "gate: walking away from %s lost the floor won" % gate.display_name)


## Two packs on the ground in front of the party, fought one after the other where they stand
## (Ewan's black screen came in a fight against two packs, B3). Each fight ends with the party
## back on its feet on the ground, seen, with the hint line up and nothing left holding the keys.
func _two_packs_at_once() -> void:
	var world: World = GameState.world
	world.prowlers.clear()
	var next_to := world.player_cell + Vector2i.RIGHT
	if not world.is_walkable(next_to):
		next_to = world.player_cell + Vector2i.DOWN
	world.prowlers.append(Prowler.create(next_to, ["wolf", "wolf"]))
	world.prowlers.append(Prowler.create(next_to, ["slime", "slime"]))
	EventBus.request_scene.emit("world", {})
	var land := await _scene_where(func(s: Node) -> bool: return _is_land(s))
	if land == null:
		_fail("two packs: the land never came up")
		return
	await _frames(10)
	_expect((land.get("_watches") as Array).size() == 2, "two packs: %d bands on the ground, not 2" % (land.get("_watches") as Array).size())
	# Fights play themselves while the suite watches (Auto, D94); these wolves are over the lead, so
	# Auto's stop for stronger bands (D150) is lifted here.
	var stops: Variant = Database.world_rules["first_hour"].get("auto_stops")
	Database.world_rules["first_hour"].erase("auto_stops")
	Pace.auto = true
	for pack in 2:
		var watches: Array = land.get("_watches")
		if watches.is_empty():
			_fail("two packs: pack %d is not on the ground" % (pack + 1))
			break
		var watched: Dictionary = (watches[0] as Node2D).get("watched")
		(land.get("_leader") as Node2D).position = land.get("map").centre_of(watched.keys()[0])
		var fought := false
		var over := false
		for i in 60 * 40:
			await get_tree().process_frame
			if _current() != land:
				break
			if land.get("_fight") != null:
				fought = true
			elif fought and not bool(land.get("_talking")) and not bool(land.get("_asking")):
				over = true
				break
		if not over:
			_fail("two packs: fight %d did not end back on the ground (fought: %s, on %s, ui %s, talking %s, asking %s)" % [
				pack + 1, fought, _describe(_current()), (land.get_node("UI") as CanvasLayer).visible if is_instance_valid(land) else "-",
				land.get("_talking") if is_instance_valid(land) else "-", land.get("_asking") if is_instance_valid(land) else "-"])
			break
		var leader: Node2D = land.get("_leader")
		_expect((land.get_node("UI") as CanvasLayer).visible, "two packs: after fight %d the ground's lines are still hidden" % (pack + 1))
		_expect(leader != null and leader.visible, "two packs: after fight %d the party is not on the ground" % (pack + 1))
		_expect((land.get("_camera") as Camera2D).is_current(), "two packs: after fight %d the ground's camera is not the one looking" % (pack + 1))
		if GameState.roster.run_is_over():
			_fail("two packs: the party fell to pack %d, so the second fight goes unchecked" % (pack + 1))
			break
	Pace.auto = false
	if stops != null:
		Database.world_rules["first_hour"]["auto_stops"] = stops


func _apart(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


# --- helpers -----------------------------------------------------------------


func _current() -> Node:
	var holder := _game.get_node("CurrentScene")
	return holder.get_child(0) if holder.get_child_count() > 0 else null


func _is_land(scene: Node) -> bool:
	return scene != null and scene.get_script() == preload("res://src/area/area_scene.gd") and bool(scene.get("_land_mode"))


func _floor_of(scene: Node) -> int:
	if scene == null or scene.get_script() != preload("res://src/area/area_scene.gd"):
		return 0
	return int(scene.get("_tower_floor"))


func _describe(scene: Node) -> String:
	if scene == null:
		return "nothing"
	if _is_land(scene):
		return "the land"
	if _floor_of(scene) > 0:
		return "floor %d" % _floor_of(scene)
	return str(scene.name)


## The scene on screen once [param wanted] says it is the one, or null after [constant PATIENCE].
func _scene_where(wanted: Callable, patience: int = PATIENCE) -> Node:
	for i in patience:
		await get_tree().process_frame
		var scene := _current()
		if scene != null and scene.is_node_ready() and wanted.call(scene):
			await _frames(3)
			return scene
	return null


func _door_in(scene: Node) -> AreaProp:
	for node: Node in scene.find_children("*", "AreaProp", true, false):
		if (node as AreaProp).act == "_climb_here":
			return node
	return null


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _expect(ok: bool, message: String) -> void:
	if not ok:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
