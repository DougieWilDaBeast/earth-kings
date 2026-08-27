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
	_check_gate_lifecycle()
	_check_town_and_captives()
	_check_tower_top()
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

	# Losing a companion is a loss, not the end of the story.
	var companion: Character = GameState.roster.party_members()[1]
	companion.status = Fate.DEAD
	GameState.roster.drop_the_lost()
	_scene._check_party()
	_expect(not ended[0], "losing a companion ended the whole run")
	_expect(not GameState.roster.run_is_over(), "the run is over while the player still stands")

	# The player falling is where it stops.
	GameState.roster.player().status = Fate.DEAD
	GameState.roster.drop_the_lost()
	_expect(GameState.roster.run_is_over(), "the player died and the run continued")
	_scene._check_party()
	_expect(ended[0], "the player's death did not end the run")
	print("run end: a companion's death carried on, the player's did not")


func _check_gate_lifecycle() -> void:
	var world: World = GameState.world
	var shut := _site_where(func(s: Site) -> bool: return s.kind == Site.GATE and s.cleared)
	if shut != null:
		var before_open := shut.open
		for i in 40:
			world._upkeep()
		_expect(shut.open == before_open and not shut.open, "a cleared gate swung open again")

	# Left open long enough, a gate stops spilling and breaks.
	var standing := _site_where(func(s: Site) -> bool: return s.kind == Site.GATE and not s.cleared)
	if standing == null:
		_expect(false, "no gate is left standing to break")
		return
	world.open_gate(standing)
	standing.opened_at = world.steps - 100000

	# A failed roll resets the gate's clock, so it gets one chance per patience
	# window. Let whole windows pass rather than spinning on the same instant.
	var patience := int(Database.world_rules.get("gate", {}).get("break_after_steps", 600))
	var broke := false
	for i in 30:
		world.steps += patience + 1
		world._upkeep()
		if standing.broken:
			broke = true
			break
	_expect(broke, "a gate left open forever never broke")

	var danger_broken := Encounter.chance_at(world, standing.cell)
	standing.broken = false
	var danger_open := Encounter.chance_at(world, standing.cell)
	standing.broken = broke
	_expect(danger_broken > danger_open, "a broken gate is no worse than an open one")
	print("gates: cleared stays shut; a neglected gate broke and took danger %d%% -> %d%%" % [
		roundi(danger_open * 100.0), roundi(danger_broken * 100.0)
	])


func _check_town_and_captives() -> void:
	var world: World = GameState.world
	var town := _site_where(func(s: Site) -> bool: return s.kind == Site.VILLAGE)
	Market.refresh(town, world)
	GameState.gold = 5000

	# Hiring: parties are temporary, and everyone has a price.
	# Forced rather than rolled, so the path is actually exercised every run.
	town.data["hire"] = { "template": "sera", "display_name": "Kestrel of Greyford", "level": 3 }
	var before := GameState.roster.party.size()
	_expect(before < Roster.MAX_PARTY, "the party is already full before hiring")

	var cost := Market.hire_cost(Market.hire_offer(town))
	GameState.gold = cost - 1
	_expect(Market.hire(town, GameState.roster, world) == null, "hired without the money")

	GameState.gold = 5000
	var hired := Market.hire(town, GameState.roster, world)
	_expect(hired != null, "could not hire with 5000 gold in hand")
	if hired != null:
		_expect(GameState.roster.party.size() == before + 1, "the hire never joined the party")
		_expect(GameState.roster.by_id(hired.id) != null, "the hire is not on the roster")
		_expect(hired.level == 3, "the hire arrived at level %d, not the level advertised" % hired.level)
		_expect(Market.hire_offer(town).is_empty(), "the town is still offering someone it already sold")
		print("hire: %s joined at level %d for %d gold" % [hired.display_name, hired.level, cost])
		_expect(GameState.roster.dismiss(hired.id), "could not part ways with a hire")
		_expect(
			not GameState.roster.dismiss(GameState.roster.player().id),
			"the player could walk out on their own run"
		)

	# Buying: gold is the standard of trade.
	var goods := Market.wares(town)
	if not goods.is_empty():
		var equipment_id: String = goods[0]
		var purse := GameState.gold
		_expect(Market.buy(town, equipment_id, GameState.roster.player()), "could not buy with 5000 gold")
		_expect(GameState.gold < purse, "buying cost nothing")
		_expect(equipment_id not in Market.wares(town), "the shop still has the thing it sold")
		print("market: bought %s for %d gold" % [equipment_id, purse - GameState.gold])

	# Captives: buyable, and on a clock.
	var taken := Character.create("sera", "Captive")
	GameState.roster.add(taken)
	taken.status = Fate.CAPTURED
	Captivity.take(taken, world, town)
	_expect(taken.captive.has("ransom"), "a captive was taken without a price")
	_expect(Captivity.held_at(taken) == town.cell, "the captive is not where they were taken to")

	GameState.gold = 0
	_expect(not Captivity.ransom(taken, GameState.roster), "bought a captive back with no money")
	GameState.gold = 5000
	_expect(Captivity.ransom(taken, GameState.roster), "could not buy a captive back")
	_expect(taken.is_alive(), "the ransomed captive is not free")
	_expect(taken.id in GameState.roster.party, "the ransomed captive did not rejoin")
	print("captive: ransomed for %d gold" % Captivity.ransom_for(taken))

	# Or taken back the hard way.
	var stolen := Character.create("bram", "Stolen")
	GameState.roster.add(stolen)
	stolen.status = Fate.CAPTURED
	Captivity.take(stolen, world, town)
	var captors := Encounter.for_captors(world, town, GameState.party_characters(), world.rng)
	_check_field(captors, "captors")
	Captivity.free_by_force(stolen, GameState.roster)
	_expect(stolen.is_alive(), "fighting for a captive did not free them")
	_expect(stolen.captive.is_empty(), "a freed captive still has terms on them")
	print("captive: %d captors fought, freed by force" % captors["enemies"].size())

	# Left too long, they are moved on or sold off.
	var forgotten := Character.create("toln", "Forgotten")
	GameState.roster.add(forgotten)
	forgotten.status = Fate.CAPTURED
	Captivity.take(forgotten, world, town)
	forgotten.captive["due"] = world.steps - 1
	_expect(Captivity.is_overdue(forgotten, world), "the deadline did not run out")
	var outcome := Captivity.resolve_deadline(forgotten, world)
	_expect(outcome in [Captivity.SOLD, Captivity.HELD], "an overdue captive resolved to '%s'" % outcome)
	print("captive: overdue and %s" % outcome)


func _check_tower_top() -> void:
	var world: World = GameState.world
	var purse := GameState.gold
	var lines := Spoils.for_tower_floor(world, 4, GameState.party_characters())
	_expect(not lines.is_empty(), "a Tower floor paid nothing")
	_expect(GameState.gold > purse, "a Tower floor paid no gold")

	world.tower_floor = world.tower_floors()
	_expect(world.tower_is_topped(), "standing on the last floor is not the top")
	print("tower: %d floors, floor 4 paid %d gold" % [world.tower_floors(), GameState.gold - purse])


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


## Every generated battlefield has to be one a fight can actually happen on.
func _check_field(meeting: Dictionary, label: String) -> void:
	var map: Dictionary = meeting.get("map", {})
	var rows: Array = map.get("tiles", [])
	_expect(not rows.is_empty(), "%s encounter generated no ground" % label)
	_expect(not meeting["enemies"].is_empty(), "%s encounter has nobody in it" % label)
	for entry: Dictionary in map.get("enemies", []):
		_expect(entry.has("cell"), "%s encounter left an enemy unplaced" % label)


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
