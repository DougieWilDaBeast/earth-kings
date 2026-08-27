extends Node
## Drives the real walk scene headlessly: walls, the clock, and every site
## interaction. Scene changes are intercepted rather than performed, so a
## battle request can be inspected instead of swapping the scene out.
##
##   godot --headless --path . res://tests/walk_smoke_test.tscn

const SEED := 20260827

var _scene: Node
var _requests: Array[Dictionary] = []
var _failures: Array[String] = []


func _ready() -> void:
	GameState.new_game(SEED)
	EventBus.request_scene.connect(
		func(key: String, payload: Dictionary) -> void:
			_requests.append({ "key": key, "payload": payload })
	)

	_scene = load("res://src/world/world_scene.tscn").instantiate()
	add_child(_scene)
	await get_tree().process_frame

	_check_walls()
	_check_clock()
	_check_rest()
	_check_library()
	_check_gate()
	_check_tower()
	_check_class_prompt()
	_check_save_round_trip()
	_check_run_ends()

	print("")
	if _failures.is_empty():
		print("walk smoke test: PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			print("FAIL: %s" % failure)
		get_tree().quit(1)


# --- walking ------------------------------------------------------------------


func _check_walls() -> void:
	var world: World = GameState.world
	var blocked := _find_cell(func(cell: Vector2i) -> bool:
		if not world.is_walkable(cell):
			return false
		for offset: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if not world.is_walkable(cell + offset):
				return true
		return false
	)
	if blocked.x < 0:
		_expect(false, "the world has no walls to walk into")
		return

	world.player_cell = blocked
	var into_wall := Vector2i.ZERO
	for offset: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if not world.is_walkable(blocked + offset):
			into_wall = offset
			break

	var before := world.steps
	_scene._step(into_wall)
	_expect(world.player_cell == blocked, "walked through a wall")
	_expect(world.steps == before, "a blocked step still cost time")
	print("walls hold: stepping into %s from %s went nowhere" % [into_wall, blocked])


func _check_clock() -> void:
	var world: World = GameState.world
	var start := world.steps
	var taken := _wander(40)
	_expect(world.steps == start + taken, "the clock lost %d steps" % (start + taken - world.steps))
	print("clock: %d steps walked, %d steps counted" % [taken, world.steps - start])


# --- sites --------------------------------------------------------------------


func _check_rest() -> void:
	var wounded: Character = GameState.roster.party_members()[0]
	wounded.hp = 3
	_expect(GameState.party_is_wounded(), "a character on 3 HP does not count as wounded")

	if not _walk_onto(Site.VILLAGE):
		return
	_expect(not GameState.party_is_wounded(), "resting at a village healed nobody")
	print("rest: the party recovered at a village")


func _check_library() -> void:
	var world: World = GameState.world
	var library := _site_where(func(s: Site) -> bool:
		return s.kind == Site.LIBRARY and s.data.get("doctrine", "") != ""
	)
	if library == null:
		_expect(false, "no library holds a book")
		return

	var doctrine_id: String = library.data["doctrine"]
	var knew_before := GameState.roster.party_members().any(
		func(c: Character) -> bool: return c.knows(doctrine_id)
	)
	_expect(not knew_before, "the party already knew %s before reading it" % doctrine_id)

	if not _step_onto(library.cell):
		return
	var knows_now := GameState.roster.party_members().any(
		func(c: Character) -> bool: return c.knows(doctrine_id)
	)
	_expect(knows_now, "nobody learned %s from the library" % doctrine_id)
	print("library: %s was read off the shelf" % Doctrine.title(doctrine_id))


func _check_gate() -> void:
	var gate := _site_where(func(s: Site) -> bool: return s.kind == Site.GATE and s.open)
	if gate == null:
		_expect(false, "no gate is open to walk into")
		return

	var gold_before := GameState.gold
	_requests.clear()
	if not _step_onto(gate.cell):
		return

	var fight := _last_battle_request()
	_expect(not fight.is_empty(), "walking into an open gate started no fight")
	if not fight.is_empty():
		var meeting: Dictionary = fight["payload"]["encounter"]
		_expect(meeting["kind"] == Encounter.GATE, "the gate started a %s fight" % meeting["kind"])
		_expect(fight["payload"]["return_scene"] == "world", "a gate fight would not come back to the world")
		_expect(meeting["enemies"].size() >= 3, "the gate fielded only %d" % meeting["enemies"].size())
	_expect(not gate.open, "the gate is still open after being entered")
	_expect(gate.cleared, "the gate was not marked cleared")
	_expect(GameState.gold > gold_before, "clearing a %s-rank gate paid nothing" % gate.rank)
	print("gate: %s fought and shut, paid %d gold" % [gate.label(), GameState.gold - gold_before])


func _check_tower() -> void:
	var world: World = GameState.world
	var tower := world.tower()
	_expect(world.tower_floor == 0, "the Tower had already been climbed")

	_requests.clear()
	if not _step_onto(tower.cell):
		return
	_expect(world.tower_floor == 1, "climbing did not advance the floor log")

	var fight := _last_battle_request()
	_expect(not fight.is_empty(), "the Tower started no fight")
	if not fight.is_empty():
		_expect(fight["payload"]["encounter"]["kind"] == Encounter.TOWER, "the Tower fought the wrong thing")
	print("tower: floor %d entered" % world.tower_floor)


# --- prompts and persistence --------------------------------------------------


func _check_class_prompt() -> void:
	var member: Character = GameState.roster.party_members()[0]
	member.class_id = ""
	member.level = 1
	member.pending_class_choice = false
	Progression.award(member, Progression.xp_to_next(1), GameState.world)

	_expect(member.pending_class_choice, "levelling to 2 did not ask for a class")
	_expect(GameState.roster.awaiting_class_choice() == member, "the roster is not waiting on anyone")

	var screen: PartyScreen = load("res://src/ui/party_screen.tscn").instantiate()
	add_child(screen)
	screen.open()

	var options := Progression.class_options(member)
	_expect(options.size() > 0, "a levelling character was offered no classes")
	_expect(not screen.choose_class(member, "no_such_class"), "the picker accepted a made-up class")
	_expect(screen.choose_class(member, options[0]), "the picker rejected a valid choice")
	_expect(not member.pending_class_choice, "the prompt did not clear when answered")
	_expect(member.class_id == options[0], "the picker set a different class than the one chosen")
	print("class prompt: %s offered %s, settled as %s" % [
		member.display_name, str(options), member.class_name_text()
	])

	_check_party_screen(screen)
	screen.queue_free()


func _check_party_screen(screen: PartyScreen) -> void:
	var party := GameState.roster.party_members()
	var teacher: Character = party[0]
	var student: Character = party[1]

	Doctrine.learn(teacher, "keen_edge", GameState.world.steps)
	_expect(not student.knows("keen_edge"), "the student already knew the book")
	_expect("keen_edge" in Doctrine.teachable(teacher, student), "the book is not offered for teaching")
	_expect(screen.teach(teacher, student, "keen_edge"), "teaching through the screen failed")
	_expect(student.knows("keen_edge"), "the student did not retain the lesson")
	_expect(not screen.teach(teacher, student, "keen_edge"), "the same book was taught twice")

	var attack_before := teacher.attack()
	screen.toggle_yoke(teacher)
	_expect(teacher.yoke, "the Yoke did not go on")
	_expect(teacher.attack() < attack_before, "the Yoke cost nothing")
	screen.toggle_yoke(teacher)
	_expect(not teacher.yoke, "the Yoke would not come off")
	_expect(teacher.attack() == attack_before, "taking the Yoke off did not restore attack")
	print("party screen: taught a book and worked the Yoke (%d attack -> %d)" % [
		attack_before, attack_before - roundi(attack_before * Character.YOKE_ATTACK_PENALTY)
	])


func _check_run_ends() -> void:
	var ended := [false]
	EventBus.run_ended.connect(func() -> void: ended[0] = true)
	for character in GameState.roster.party_members():
		character.status = Fate.DEAD
	GameState.roster.drop_the_lost()
	_expect(GameState.roster.is_broken(), "killing everyone did not break the roster")

	_scene._check_party()
	_expect(ended[0], "losing the whole party did not end the run")
	print("run end: the last death ended the run")


func _check_save_round_trip() -> void:
	var world: World = GameState.world
	var before := {
		"steps": world.steps,
		"cell": world.player_cell,
		"floor": world.tower_floor,
		"gold": GameState.gold,
		"party": GameState.roster.party.size(),
		"doctrine": GameState.roster.party_members()[0].doctrine.size(),
	}

	GameState.save()
	_expect(GameState.has_save(), "saving produced no file")
	GameState.new_game(1)
	_expect(GameState.world.steps != before["steps"], "a new game kept the old clock")
	_expect(GameState.load_save(), "the save would not load back")

	var after: World = GameState.world
	_expect(after.steps == before["steps"], "the clock did not survive the save")
	_expect(after.player_cell == before["cell"], "the player moved across a save")
	_expect(after.tower_floor == before["floor"], "the floor log did not survive the save")
	_expect(GameState.gold == before["gold"], "gold did not survive the save")
	_expect(GameState.roster.party.size() == before["party"], "the party did not survive the save")
	_expect(
		GameState.roster.party_members()[0].doctrine.size() == before["doctrine"],
		"what a character had read did not survive the save"
	)
	print("save: %d steps, floor %d and %d gold all came back" % [
		before["steps"], before["floor"], before["gold"]
	])


# --- helpers ------------------------------------------------------------------


## Put the player beside [param cell], then step onto it for real.
func _step_onto(cell: Vector2i) -> bool:
	var world: World = GameState.world
	for offset: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if not world.is_walkable(cell + offset):
			continue
		world.player_cell = cell + offset
		_scene._step(-offset)
		if world.player_cell != cell:
			_expect(false, "could not step onto %s" % cell)
			return false
		return true
	_expect(false, "%s is walled in on every side" % cell)
	return false


func _walk_onto(kind: String) -> bool:
	var site := _site_where(func(s: Site) -> bool: return s.kind == kind)
	if site == null:
		_expect(false, "the world has no %s" % kind)
		return false
	return _step_onto(site.cell)


func _site_where(predicate: Callable) -> Site:
	for site in GameState.world.sites:
		if predicate.call(site):
			return site
	return null


func _find_cell(predicate: Callable) -> Vector2i:
	var world: World = GameState.world
	for y in world.size.y:
		for x in world.size.x:
			if predicate.call(Vector2i(x, y)):
				return Vector2i(x, y)
	return Vector2i(-1, -1)


## Take up to [param count] legal steps; returns how many actually happened.
func _wander(count: int) -> int:
	var world: World = GameState.world
	var taken := 0
	for i in count:
		var options: Array[Vector2i] = []
		for offset: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if world.is_walkable(world.player_cell + offset):
				options.append(offset)
		if options.is_empty():
			break
		_scene._step(options[world.rng.randi() % options.size()])
		taken += 1
	return taken


func _last_battle_request() -> Dictionary:
	for i in range(_requests.size() - 1, -1, -1):
		if _requests[i]["key"] == "battle":
			return _requests[i]
	return {}


func _expect(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)
