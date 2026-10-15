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


## Standing at [param floor]'s stair and climbing it.
func _up_the_stair(floor: int) -> bool:
	var on := await _scene_where(func(s: Node) -> bool: return _floor_of(s) == floor)
	if on == null:
		_fail("climb: floor %d never came up; the stair below did not go on to it (on %s)" % [floor, _describe(_current())])
		return false
	on.call("_climb_the_stair")
	return true


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
	var enter := ""
	for each: Dictionary in land.get("_acts"):
		if str(each.get("act", "")) == "_enter_gate_here":
			enter = str(each.get("prompt", ""))
	_expect(enter.ends_with("to enter %s (rank %s)" % [gate.display_name, gate.rank]),
		"gate: standing at %s does not offer to enter it (offers %s)" % [gate.display_name, land.get("_acts")])
	land.call("_ask_the_continent", { "act": "_enter_gate_here" })
	var fight := await _scene_where(func(s: Node) -> bool: return s.get_script() == preload("res://src/skirmish/skirmish.gd"))
	if fight == null:
		_fail("gate: E at %s started no fight (on %s)" % [gate.display_name, _describe(_current())])
		return
	# Won, as the fight screen settles it.
	GameState.set_flag("last_victory", true)
	EventBus.request_scene.emit("world", {})
	land = await _scene_where(func(s: Node) -> bool: return _is_land(s))
	if land == null:
		_fail("gate: winning %s's first floor did not come back to the land" % gate.display_name)
		return
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
	# Fights play themselves while the suite watches (Auto, D94).
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
