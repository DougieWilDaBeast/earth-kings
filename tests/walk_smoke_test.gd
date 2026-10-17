extends Node
## Drives the real walk scene headlessly: walls, the clock, and every site
## interaction. Scene changes are intercepted rather than performed, so a
## battle request can be inspected instead of swapping the scene out.
##
##   godot --headless --path . res://tests/walk_smoke_test.tscn
##   godot --headless --path . res://tests/walk_smoke_test.tscn -- --check=gate,tower

const CheckFilter := preload("res://tests/check_filter.gd")
const Company := preload("res://tests/company.gd")
const Route := preload("res://src/world/route.gd")
const Chapters := preload("res://src/chronicle/chapters.gd")
const TowerFloors := preload("res://src/chronicle/tower_floors.gd")
const Guild := preload("res://src/chronicle/guild.gd")
const Dispatch := preload("res://src/chronicle/dispatch.gd")
const Fall := preload("res://src/chronicle/fall.gd")
const Wanderers := preload("res://src/chronicle/wanderers.gd")
const Siblings := preload("res://src/chronicle/siblings.gd")
const Sixteen := preload("res://src/chronicle/sixteen.gd")
const Atlas := preload("res://src/chronicle/atlas.gd")
const Fighter := preload("res://src/skirmish/fighter.gd")
const SkirmishBrain := preload("res://src/skirmish/skirmish_brain.gd")
const AutoRoad := preload("res://src/world/auto_road.gd")

const SEED := 20260827
## Every gate this suite shuts leaves a word in the record of the sixteen (D183):
## kept here, so the real record is never touched.
const SIXTEEN_PATH := "user://earth-kings.sixteen.walk-suite.json"
## Every check, in the order a full run takes them. `--check=` picks from these.
const CHECKS := [
	"walls", "autoplay", "clock", "watchers", "banter", "rest", "home", "library", "gate", "tower",
	"class_prompt", "gate_lifecycle", "town_and_captives", "loot", "renown", "raid_and_rescue",
	"tower_top", "save_round_trip", "chapters", "objectives", "town_saves", "auto_rests", "allies", "guild", "map", "muster",
	"fall", "first_hour", "run_ends", "sixteen", "crossing",
]

var _scene: Node
var _requests: Array[Dictionary] = []
var _failures: Array[String] = []


func _ready() -> void:
	Sixteen.path = SIXTEEN_PATH
	_forget_sixteen()
	GameState.new_game(SEED)
	# Atlas leads; two more of the sixteen walk with him, so there is someone to
	# talk to, teach and send away.
	Company.join(GameState.roster)
	EventBus.request_scene.connect(
		func(key: String, payload: Dictionary) -> void:
			_requests.append({ "key": key, "payload": payload })
	)

	_scene = load("res://src/world/world_scene.tscn").instantiate()
	add_child(_scene)
	await get_tree().process_frame

	var unknown: Array = []
	var chosen := CheckFilter.wanted(CHECKS, unknown)
	for name: String in unknown:
		_expect(false, "no check called '%s' (there are: %s)" % [name, ", ".join(CHECKS)])
	if chosen.size() < CHECKS.size():
		print("running only: %s" % ", ".join(chosen))
	for name: String in chosen:
		await call("_check_" + name)

	_forget_sixteen()
	Sixteen.path = Sixteen.DEFAULT_PATH
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


## A party walking itself goes round a wall rather than pacing in front of it,
## and gives up on somewhere it cannot walk to at all.
func _check_autoplay() -> void:
	var world: World = GameState.world
	var home := world.player_cell
	# Giving up on somewhere means wandering, which draws on the world's dice;
	# put them back so the checks after this see the world they always have.
	var dice := world.rng.state
	var start := Vector2i(-1, -1)
	var goal := Vector2i(-1, -1)
	var way: Array[Vector2i] = []
	var tries := 0
	for y in range(2, world.size.y - 2):
		for x in range(2, world.size.x - 6):
			var here := Vector2i(x, y)
			if not world.is_walkable(here) or world.is_walkable(here + Vector2i.RIGHT):
				continue
			for gap in range(2, 5):
				var there := here + Vector2i(gap, 0)
				if not world.is_walkable(there):
					continue
				tries += 1
				var found := Route.between(world, here, there)
				# Straight at it is into the wall; the way there has to go round,
				# and not so far round that something this close is not worth it.
				if found.size() > gap + 2 and found.size() <= _scene.AUTO_DETOUR * 3:
					start = here
					goal = there
					way = found
				break
			if start.x >= 0 or tries > 40:
				break
		if start.x >= 0 or tries > 40:
			break
	if start.x < 0:
		_expect(false, "no wall with a way round it to test walking itself against")
		return

	for step in way:
		_expect(world.is_walkable(step), "the way round goes through %s, which cannot be walked" % step)
	world.player_cell = start
	for i in way.size():
		var direction: Vector2i = _scene._auto_direction(goal)
		_expect(Pathfinder.distance(Vector2i.ZERO, direction) == 1, "walking itself took a step of %s" % direction)
		world.player_cell += direction
	_expect(
		world.player_cell == goal,
		"walking itself from %s to %s round a wall ended at %s after %d steps" % [start, goal, world.player_cell, way.size()]
	)

	var sea := _find_cell(func(cell: Vector2i) -> bool: return not world.is_walkable(cell))
	if sea.x >= 0:
		world.player_cell = start
		_scene._auto_direction(sea)
		_expect(Pace.avoided.has(sea), "walking itself kept aiming for %s, which nobody can stand on" % sea)
		Pace.avoided.erase(sea)
	world.player_cell = home
	world.rng.state = dice

func _check_clock() -> void:
	var world: World = GameState.world
	var start := world.steps
	var taken := _wander(40)
	_expect(world.steps == start + taken, "the clock lost %d steps" % (start + taken - world.steps))
	print("clock: %d steps walked, %d steps counted" % [taken, world.steps - start])


## The party talk to each other, and what they say depends on how well the two
## of them have come to get on.
func _check_banter() -> void:
	var world: World = GameState.world
	var party := GameState.party_characters()
	if party.size() < 2:
		_expect(false, "nobody to talk to")
		return
	var a: Character = party[0]
	var b: Character = party[1]

	# Two people who have never met owe each other nothing.
	var stranger := Character.create("sera")
	_expect(Banter.bond(a, stranger) == 0, "a stranger already has a bond")

	# By now the road has already had them talking, so measure the change.
	var before := Banter.bond(a, b)
	Banter.shared(party, 3)
	_expect(
		Banter.bond(a, b) == before + 3,
		"coming through something together moved the bond %d, not 3" % (Banter.bond(a, b) - before)
	)
	_expect(Banter.bond(b, a) == Banter.bond(a, b), "a bond only went one way")

	# A pair who have been through a lot tell stories; a pair who have not, bicker.
	Banter.remember(a, b, int(Banter.rules().get("warm_at", 6)))
	_expect(Banter.mood(a, b) == Banter.WARM, "a well-earned bond did not read as warm")
	a.bonds[b.id] = int(Banter.rules().get("cold_at", -3))
	b.bonds[a.id] = a.bonds[b.id]
	_expect(Banter.mood(a, b) == Banter.COLD, "a soured bond did not read as cold")

	# Its own generator, so listening in never shifts the world's dice.
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var heard := 0
	for occasion: String in [Banter.ROAD, Banter.REST, Banter.AFTER_BATTLE]:
		var exchange := Banter.pick(world, party, occasion, rng)
		if exchange.is_empty():
			_expect(false, "nobody had anything to say on the %s" % occasion)
			continue
		heard += 1
		for line: Dictionary in exchange:
			var speakers := party.map(func(c: Character) -> String: return c.display_name)
			_expect(line["speaker"] in speakers, "a stranger spoke: %s" % line["speaker"])
			_expect(
				not (line["text"] as String).contains("{"),
				"a line went out unfilled: %s" % line["text"]
			)

	_check_banter_content()
	var written := int(Database.banter.get("exchanges", []).size())
	print("banter: %d exchanges written, %d occasions spoke, bond survived at %d" % [
		written, heard, Banter.bond(a, b)
	])


## Every exchange has to be playable: known occasion and mood, two speakers, and
## no token in the text that nothing will ever fill in.
func _check_banter_content() -> void:
	const SLOTS := ["a", "b", "deed", "fallen", "place"]
	const OCCASIONS := [Banter.ROAD, Banter.REST, Banter.AFTER_BATTLE, Banter.GRAVE]
	const MOODS := [Banter.ANY, Banter.WARM, Banter.COLD, Banter.EVEN]
	for exchange: Dictionary in Database.banter.get("exchanges", []):
		var where: String = exchange.get("occasion", "")
		_expect(where in OCCASIONS, "an exchange is set at '%s', which never happens" % where)
		_expect(exchange.get("mood", Banter.ANY) in MOODS, "'%s' has a mood nobody is in" % where)
		var lines: Array = exchange.get("lines", [])
		_expect(lines.size() >= 2, "an exchange at '%s' is one person talking to themselves" % where)
		for line: Dictionary in lines:
			_expect(line.get("who", "") in ["a", "b"], "a line at '%s' has no speaker" % where)
			for token in _tokens_in(line.get("text", "")):
				_expect(token in SLOTS, "'%s' uses {%s}, which nothing fills" % [where, token])


func _tokens_in(text: String) -> Array[String]:
	var out: Array[String] = []
	var rest := text
	while rest.contains("{"):
		rest = rest.substr(rest.find("{") + 1)
		var close := rest.find("}")
		if close < 0:
			break
		out.append(rest.substr(0, close))
	return out


## Nothing ambushes you. A band has to see you first, and you can see the ground
## it is watching before you set foot on it.
func _check_watchers() -> void:
	var world: World = GameState.world
	# Bands already out there stand their ground as you approach; it is only the
	# fresh ones that have to appear somewhere you are not looking.
	world.prowlers.clear()
	Encounter.restock(world, world.rng)
	_expect(not world.prowlers.is_empty(), "the country put no bands out at all")
	var sprung := world.prowlers.any(func(p: Prowler) -> bool:
		return Pathfinder.distance(p.cell, world.player_cell) < Encounter.SPAWN_CLEARANCE
	)
	_expect(not sprung, "a band was placed within reach of the party")
	var abroad := world.prowlers.size()

	# Country with nobody in it starts no fights, however far you walk across it.
	world.prowlers.clear()
	_requests.clear()
	_wander(20)
	var ambush := _last_battle_request()
	var ambushed: bool = not ambush.is_empty() \
		and ambush["payload"].get("encounter", {}).get("kind", "") == Encounter.WILD
	_expect(not ambushed, "empty country ambushed the party anyway")

	# Now one band, on ground open enough that we know what it can see.
	var post := _find_cell(func(cell: Vector2i) -> bool:
		if world.site_at(cell) != null or Pathfinder.distance(cell, world.player_cell) < 6:
			return false
		for offset: Vector2i in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if world.terrain_id_at(cell + offset) != "grass":
				return false
		return true
	)
	if post.x < 0:
		_expect(false, "nowhere open enough to post a band")
		return

	# Walking those 20 steps let the country restock itself. Clear it again, so
	# the only thing that can see the tile we are about to step on is ours.
	world.prowlers.clear()
	var band := Prowler.create(post, ["wolf", "wolf"], 3)
	world.prowlers.append(band)
	var watched := band.watched(world)
	_expect(watched.has(post), "a band cannot see the ground under its own feet")
	_expect(watched.size() > 4, "a band on open ground watches only %d tiles" % watched.size())

	var red := post + Vector2i.UP
	_expect(band.sees(world, red), "the tile beside a band is not watched")
	_scene._busy = false
	_requests.clear()
	if not _step_onto(red):
		return

	var fight := _last_battle_request()
	_expect(not fight.is_empty(), "walking into watched ground started no fight")
	if not fight.is_empty():
		var meeting: Dictionary = fight["payload"]["encounter"]
		_expect(meeting["kind"] == Encounter.WILD, "being spotted started a %s fight" % meeting["kind"])
		_expect(
			meeting["enemies"].size() == band.pack.size(),
			"the band fielded %d of its %d" % [meeting["enemies"].size(), band.pack.size()]
		)
		_check_field(meeting, "band")
	_expect(not world.prowlers.has(band), "the band that spotted us is still out on the map")
	_scene._busy = false
	print("watchers: %d bands abroad, %d tiles watched from open ground, red ground started the fight" % [
		abroad, watched.size()
	])


# --- sites --------------------------------------------------------------------


func _check_rest() -> void:
	var wounded: Character = GameState.roster.party_members()[0]
	wounded.hp = 3
	_expect(GameState.party_is_wounded(), "a character on 3 HP does not count as wounded")

	if not _walk_onto(Site.VILLAGE):
		return
	_expect(not GameState.party_is_wounded(), "resting at a village healed nobody")
	print("rest: the party recovered at a village")


## Home: always safe, always heals, and the bed is the one thing you can build.
func _check_home() -> void:
	var world: World = GameState.world
	var house := world.home()
	if house == null:
		_expect(false, "the world generated no home")
		return
	_expect(world.distance_to_haven(house.cell) == 0, "home does not count as a haven")
	_expect(not Encounter._can_camp_at(world, house.cell), "a band could camp on the doorstep of home")

	var sleeper: Character = GameState.roster.party_members()[0]
	sleeper.hp = 2
	var plain_hp := sleeper.max_hp()
	if not _walk_onto(Site.HOME):
		return
	_expect(not GameState.party_is_wounded(), "sleeping at home healed nobody")
	_expect(sleeper.max_hp() == plain_hp, "the starting bed handed out free health")

	var better := Home.next_bed(house)
	_expect(not better.is_empty(), "there is no bed to upgrade to")
	# In the First Hour the crater offers no bed (D178); the beds are kept for after it.
	var hidden: Array = Database.world_rules["first_hour"]["hidden"]
	if hidden.has("beds"):
		GameState.gold = 100000
		_scene._upgrade_bed_here()
		_expect(Home.tier(house) == 0, "a bed was sold in the crater in the First Hour")
		_expect(not _scene._actions_here().any(func(doing: Dictionary) -> bool: return doing["call"] == _scene._upgrade_bed_here),
			"the crater still offers a better bed in the First Hour")
		hidden.erase("beds")
	GameState.gold = 0
	_scene._upgrade_bed_here()
	_expect(Home.tier(house) == 0, "bought a bed with no money")

	GameState.gold = int(better.get("cost", 0))
	_scene._upgrade_bed_here()
	_expect(Home.tier(house) == 1, "could not buy a bed with the asking price in hand")
	_expect(GameState.gold == 0, "the bed was not paid for")
	_expect(
		sleeper.max_hp() == plain_hp + int(better.get("vigour", 0)),
		"a %s left %s no tougher" % [better.get("display_name", "bed"), sleeper.display_name]
	)

	# Sleeping somewhere worse must not take the comfort back off them.
	if not _walk_onto(Site.VILLAGE):
		return
	_expect(sleeper.max_hp() == plain_hp + int(better.get("vigour", 0)), "a night away undid the bed")
	if not hidden.has("beds"):
		hidden.append("beds")
	print("home: %s at %s, %s took %s from %d to %d HP" % [
		Home.bed_name(house), house.cell, sleeper.display_name,
		better.get("display_name", "a bed"), plain_hp, sleeper.max_hp()
	])


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
	# The deepest one standing open, so walking through it floor by floor is tested.
	var gate: Site = null
	for site in GameState.world.sites_of_kind(Site.GATE):
		if site.open and (gate == null or site.floors() > gate.floors()):
			gate = site
	if gate == null:
		_expect(false, "no gate is open to walk into")
		return

	# The garrison's composition is under test, not the dial that thins it.
	var setting := GameState.difficulty
	GameState.difficulty = "even"
	var gold_before := GameState.gold
	_requests.clear()
	if not _step_onto(gate.cell):
		GameState.difficulty = setting
		return
	# D116: walking onto the gate is not going in; E beside it is.
	_expect(_last_battle_request().is_empty(), "walking onto an open gate started its fight without being asked")
	var asked: Array = _scene._actions_here().filter(func(a: Dictionary) -> bool:
		return (a["call"] as Callable).is_valid() and (a["call"] as Callable).get_method() == "_enter_gate_here")
	_expect(asked.size() == 1 and str(asked[0]["prompt"]).contains("to enter %s (rank %s)" % [gate.display_name, gate.rank]),
		"standing at an open gate does not offer to enter it")
	_scene._busy = false
	_scene._enter_gate_here()

	var fight := _last_battle_request()
	_expect(not fight.is_empty(), "E at an open gate started no fight")
	if not fight.is_empty():
		var meeting: Dictionary = fight["payload"]["encounter"]
		_expect(meeting["kind"] == Encounter.GATE, "the gate started a %s fight" % meeting["kind"])
		_expect(fight["payload"]["return_scene"] == "world", "a gate fight would not come back to the world")
		_expect(meeting["enemies"].size() >= 3, "the gate fielded only %d" % meeting["enemies"].size())
	_expect(gate.open, "the gate shut before the fight was fought")
	_expect(GameState.gold == gold_before, "the gate paid out before the fight was fought")
	GameState.difficulty = setting

	# Walked out of, it is left exactly as it was found.
	_scene._settle_up(false)
	_expect(gate.open and not gate.cleared, "a gate nobody beat still shut itself")
	_expect(GameState.gold == gold_before, "a gate nobody beat still paid")

	# A gate is as deep as its rank. Every floor but the last gives ground
	# rather than shutting it, so a delve is walked through rather than won once.
	var floors := gate.floors()
	if not _step_onto(gate.cell):
		return
	_scene._busy = false
	_scene._enter_gate_here()
	for floor_number in floors:
		_scene._settle_up(true)
		if floor_number >= floors - 1:
			break
		_expect(gate.open, "%s shut on floor %d of %d" % [gate.label(), floor_number + 1, floors])
		_expect(
			gate.depth() == floor_number + 1,
			"floor %d left the delve at depth %d" % [floor_number + 1, gate.depth()]
		)
		# D115: between floors a step away walks out, the floors won kept; walking back in is the next floor.
		_expect(GameState.delving == [gate.cell.x, gate.cell.y], "won a floor but was not counted inside the gate")
		_requests.clear()
		_expect(_step_onto(gate.cell), "could not walk out of the gate and back in")
		_expect(GameState.world.player_cell == gate.cell, "walking back into the gate left the party outside it")
		_expect(gate.depth() == floor_number + 1, "walking out of the gate lost the floors won")
		_expect(_last_battle_request().is_empty(), "walking back onto the gate forced its next floor")
		_scene._busy = false
		_scene._enter_gate_here()
		_expect(not _last_battle_request().is_empty(), "E at the gate did not start the next floor")
	_expect(GameState.delving.is_empty(), "still held inside a gate that has been shut")

	_expect(not gate.open, "the gate is still open after being cleared")
	_expect(gate.cleared, "the gate was not marked cleared")
	_expect(GameState.gold > gold_before, "clearing a %s-rank gate paid nothing" % gate.rank)
	print("gate: %s is %d floors deep, walked out of once, then walked out of and back into between floors, entered each time with E and shut for %d gold" % [
		gate.label(), floors, GameState.gold - gold_before
	])


func _check_tower() -> void:
	var world: World = GameState.world
	var tower := world.tower()
	_expect(world.tower_floor == 0, "the Tower had already been climbed")
	# A power waiting to be taken is asked about first, and the climb is asked for
	# from a standstill; the walk so far may have left either.
	for member: Character in GameState.roster.party_members():
		member.rungs = 0
	_scene._busy = false

	_requests.clear()
	if not _step_onto(tower.cell):
		return
	_expect(_last_battle_request().is_empty(), "standing at the Tower's foot started a fight")
	_expect(_scene._actions_here().any(func(doing: Dictionary) -> bool: return str(doing["label"]).begins_with("Climb")),
		"nothing at the Tower's foot offered the climb")
	_scene._climb_here()
	_expect(world.tower_floor == 0, "the floor log advanced before the floor was climbed")

	# Floor 1 is walked (D102): its own ground, held bands, and the stair up.
	var climb := _last_climb_request()
	_expect(not climb.is_empty() and climb["key"] == "area", "the Tower's first floor is not walked")
	if not climb.is_empty() and climb["key"] == "area":
		_expect(int(climb["payload"]["tower_floor"]) == 1 and Database.has_area(str(climb["payload"]["area_id"])),
				"the Tower opened onto the wrong floor: %s" % [climb["payload"]])
	for n in range(1, 6):
		var floor_area := Chapters.walked_floor_area(n)
		_expect(floor_area != "", "floor %d of the Tower is not walked" % n)
		var data := Database.area(floor_area)
		_expect(not (data.get("stairs", []) as Array).is_empty(), "floor %d has no stair up" % n)
		var bands: Array = data.get("bands", [])
		_expect(not bands.is_empty() and bands.all(func(b: Dictionary) -> bool: return bool(b.get("held", false))),
				"floor %d has nobody on it to fight for real" % n)
		if n == 5:
			_expect(bands.any(func(b: Dictionary) -> bool: return bool(b.get("boss", false))), "floor 5 has no keeper")
	# Every floor above is walked too, on a borrowed plan (D207), with bands of its own.
	for n: int in [6, 9, 10, 37, world.tower_floors()]:
		var plan := Chapters.walked_floor_area(n)
		_expect(plan != "" and plan != Chapters.walked_floor_area(5) and Chapters.borrows_a_plan(n),
				"floor %d is not walked on a borrowed plan (%s)" % [n, plan])
		if plan == "":
			continue
		var stocked: Array = TowerFloors.restock(Database.area(plan).get("bands", []), world, n, GameState.party_characters(), [Vector2i(12, 0)])
		var own := not stocked.is_empty()
		for b: Dictionary in stocked:
			own = own and bool(b.get("held", false)) and str(b.get("key", "")).begins_with("tower%d_" % n) \
					and str(b.get("done_flag", "")) == "done:%s" % b.get("key", "")
		_expect(own, "floor %d's bands are not its own: %s" % [n, stocked])
		_expect(stocked == TowerFloors.restock(Database.area(plan).get("bands", []), world, n, GameState.party_characters(), [Vector2i(12, 0)]),
				"floor %d is stocked differently each time it is walked" % n)
		if n == world.tower_floors():
			_expect(stocked.size() == 1 and bool(stocked[0].get("boss", false)) and stocked[0]["at"] == [12, 4],
					"the top floor's keeper does not stand before the stair: %s" % [stocked])
		else:
			_expect(stocked.all(func(b: Dictionary) -> bool: return not bool(b.get("boss", false))),
					"floor %d has a keeper it should not" % n)
	_expect(Chapters.walked_floor_area(world.tower_floors() + 1) == "", "a floor past the top is walked")

	# Standing on the stair is the floor won: the continent pays it out.
	GameState.pending_outcome = { "kind": "tower", "cell": tower.cell, "floor": 1 }
	_scene._settle_up(true)
	_expect(world.tower_floor == 1, "climbing did not advance the floor log")
	print("tower: floor %d entered" % world.tower_floor)



## Winning the last floor of a chapter moves the world on, reads the census and
## seals the stair; the seal holds until the company answers the world, and
## survives a save ([D34]).
func _check_chapters() -> void:
	var world: World = GameState.world
	# A check before this one may have loaded the save; walk the world it loaded.
	_scene.world = world
	var tower := world.tower()
	var kept_floor := world.tower_floor
	var kept_topped := world.tower_topped
	var kept_delving := GameState.delving
	# Inside a gate every step is the next floor ([D35]); the Tower is outside.
	GameState.delving = []
	world.tower_topped = false
	world.tower_floor = Chapters.per_chapter() - 1
	world.tower_sealed_at = -1
	var steps_before := world.steps
	var annals_before := world.annals.size()
	var open_before := world.sites_of_kind(Site.GATE).filter(func(s: Site) -> bool: return s.open)
	_scene._busy = false

	_requests.clear()
	if not _step_onto(tower.cell):
		return
	_scene._climb_here()
	_expect(not _last_climb_request().is_empty(), "the last floor of a chapter started no climb")
	GameState.pending_outcome = { "kind": "tower", "cell": tower.cell, "floor": Chapters.per_chapter() }
	_scene._settle_up(true)
	_scene._busy = false
	_expect(world.tower_floor == Chapters.per_chapter(), "the chapter's last floor was not logged")
	_expect(Chapters.sealed(world), "finishing a chapter did not seal the stair")
	_expect(world.steps >= steps_before + World.UPKEEP_INTERVAL * 3, "the world did not move on while the chapter closed")
	var woken := world.sites_of_kind(Site.GATE).filter(
		func(s: Site) -> bool: return s.open and not s.cleared and not open_before.has(s)
	)
	_expect(not woken.is_empty(), "no gate opened as the chapter closed, so the seal might never be answered")
	var told := world.annals.slice(annals_before).map(func(entry: Dictionary) -> String: return str(entry.get("text", "")))
	_expect(told.any(func(line: String) -> bool: return line.contains("sixteen")), "the census was never read")

	# Sealed: stepping up again is turned away, and it holds across a save.
	GameState.save()
	GameState.load_save()
	world = GameState.world
	_scene.world = world
	_expect(Chapters.sealed(world), "the seal did not survive a save")
	_requests.clear()
	if _step_onto(tower.cell):
		_expect(_last_climb_request().is_empty(), "a sealed stair still started a climb")

	# Shutting a gate is answering the world.
	Renown.record(world, Renown.GATE_SHUT, world.player_cell, 3, "shut a gate")
	_expect(not Chapters.sealed(world), "shutting a gate did not break the seal")
	_requests.clear()
	_scene._busy = false
	if _step_onto(tower.cell):
		_scene._climb_here()
		_expect(not _last_climb_request().is_empty(), "the stair stayed shut after the world was answered")
	_scene._busy = false
	print("chapters: floor %d closed chapter %d, %d gate(s) woke, the seal held until a gate was shut" % [
		Chapters.per_chapter(), Chapters.chapter_of(Chapters.per_chapter()), woken.size(),
	])
	world.tower_floor = kept_floor
	world.tower_topped = kept_topped
	GameState.delving = kept_delving


# --- prompts and persistence --------------------------------------------------


func _check_class_prompt() -> void:
	var member: Character = GameState.roster.party_members()[0]
	member.class_id = ""
	member.level = 1
	member.xp = 0
	member.pending_class_choice = false
	# A level earned in play is announced with the numbers it changed ([D67]).
	var heard: Array = []
	var listen := func(_who: RefCounted, before: Dictionary) -> void: heard.append(before)
	EventBus.levelled_up.connect(listen)
	# Said in one line at the side of the screen that takes no clicks ([D77]).
	var notice: CanvasLayer = load("res://src/ui/level_up_banner.gd").new()
	add_child(notice)
	Progression.award(member, Progression.xp_to_next(1), GameState.world)
	EventBus.levelled_up.disconnect(listen)
	_expect(notice.call("showing") == 1, "levels gained together showed %d lines, not one" % notice.call("showing"))
	var said: Array = notice.call("lines")
	_expect(not said.is_empty() and str(said[0]).begins_with(member.display_name) and "level" in str(said[0]),
			"the level-up line did not say who levelled: %s" % str(said))
	_expect(not said.is_empty() and "path to choose" in str(said[0]), "the level-up line did not say a path is waiting")
	for node in notice.find_children("*", "Control", true, false):
		# A text box keeps a hidden scrollbar of its own; hidden, it takes nothing.
		if not (node as Control).is_visible_in_tree():
			continue
		_expect((node as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE,
				"the level-up line catches clicks (%s)" % node.name)
	notice.queue_free()
	# Gentle may hand over more than one level's worth: one banner per level.
	_expect(heard.size() == member.level - 1, "%d levels gained but %d announced" % [member.level - 1, heard.size()])
	_expect(not heard.is_empty() and heard[0].has("max_hp") and heard[0].has("attack"),
			"the level-up did not say what the numbers were before it")

	_expect(member.pending_class_choice, "levelling to 2 did not ask for a class")
	_expect(GameState.roster.awaiting_class_choice() == member, "the roster is not waiting on anyone")

	var screen: PartyScreen = load("res://src/ui/party_screen.tscn").instantiate()
	add_child(screen)
	screen.open()

	var options := Progression.class_options(member)
	_expect(options.size() > 0, "a levelling character was offered no classes")
	screen.open_on_growth(member)
	var cards := _buttons_reading(screen._page_box, "Walk this path")
	_expect(cards.size() == options.size(), "%d paths offered but %d cards to choose from" % [options.size(), cards.size()])
	_expect(not screen.choose_class(member, "no_such_class"), "the picker accepted a made-up class")
	_expect(screen.choose_class(member, options[0]), "the picker rejected a valid choice")
	_expect(not member.pending_class_choice, "the prompt did not clear when answered")
	_expect(member.class_id == options[0], "the picker set a different class than the one chosen")
	print("class prompt: %s offered %s, settled as %s" % [
		member.display_name, str(options), member.class_name_text()
	])
	_check_power_trail(screen, member)
	_check_company_sheet()

	_check_party_screen(screen)
	screen.queue_free()


## A tree of powers is a trail of stones, and the one that can be taken is one
## press ([D67]).
func _check_power_trail(screen: PartyScreen, member: Character) -> void:
	var kept_rungs := member.rungs
	var kept_trees := member.trees.duplicate()
	var kept_learned := member.learned.duplicate()
	Progression.unlock_tree(member, GameState.world)
	if member.rungs <= 0:
		member.rungs = 1
	screen.open_on_growth(member)
	var stones := _buttons_reading(screen._page_box, "I").filter(func(b: Button) -> bool: return not b.disabled)
	_expect(stones.size() >= 1, "no stone on the new tree could be pressed")
	if not stones.is_empty():
		var before := member.learned.size()
		(stones[0] as Button).pressed.emit()
		_expect(member.learned.size() == before + 1, "pressing the glowing stone took no power")
	member.rungs = kept_rungs
	member.trees = kept_trees
	member.learned = kept_learned


## The journal opens at the Company, and every companion has a sheet ([D67]).
func _check_company_sheet() -> void:
	var journal: JournalScreen = load("res://src/ui/journal_screen.tscn").instantiate()
	add_child(journal)
	journal.open()
	_expect(journal.open_tab() == "company", "the journal opened at %s, not the Company" % journal.open_tab())
	var entries := journal._list.get_children()
	_expect(entries.size() == GameState.roster.party_members().size(), "the Company lists %d of %d" % [
		entries.size(), GameState.roster.party_members().size()
	])
	for entry: Node in entries:
		(entry as Button).pressed.emit()
		_expect(journal._page.get_child_count() > 3, "a companion's sheet came out nearly blank")
	_expect(journal.turn_to("bestiary") and journal.open_tab() == "bestiary", "the Bestiary ribbon does not turn")
	_expect(not journal.turn_to("no_such_tab"), "the journal turned to a tab it has no ribbon for")
	journal.close()
	journal.queue_free()


func _buttons_reading(root: Node, text: String) -> Array:
	return root.find_children("*", "Button", true, false).filter(
		func(b: Node) -> bool: return (b as Button).text == text
	)


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

	_check_party_menu(screen, party)


## The menu itself: setting the marching order, and the numbers the gear page
## promises against the ones the fight would actually use.
func _check_party_menu(screen: PartyScreen, party: Array[Character]) -> void:
	var lead: Character = party[0]
	var second: Character = party[1]

	# The marching order, moved from the menu rather than by dismissing anyone.
	var order_before: Array = GameState.roster.party.duplicate()
	_expect(not screen.shift(lead, -1), "the front of the line moved further forward")
	_expect(screen.shift(lead, 1), "nobody would move down the line")
	_expect(GameState.roster.party[0] == second.id, "moving down the line left the order unchanged")
	_expect(screen.shift(lead, -1), "nobody would move back up the line")
	_expect(GameState.roster.party == order_before, "the marching order did not come back")

	# What the gear page promises: the numbers a swap would actually produce.
	GameState.stores.append("steel_blade")
	var carried := Gear.fielded(lead, lead.equipment)
	var offered := Gear.fielded(lead, "steel_blade")
	var swing := Gear.swing("steel_blade", lead)
	_expect(
		int(offered["attack"]) - int(carried["attack"])
			+ int(offered["defense"]) - int(carried["defense"]) == swing,
		"the previewed numbers disagree with the swing the row advertises"
	)

	var best := Gear.best_offer(lead)
	if best == "":
		_expect(not screen.optimise(lead), "Optimise took up a piece it called no improvement")
	else:
		_expect(Gear.swing(best, lead) > 0, "Optimise offered a piece that is not an improvement")
		_expect(screen.optimise(lead), "Optimise would not take up the best piece in the packs")
		_expect(lead.equipment == best, "Optimise took up something other than the best piece")
	_expect(Gear.best_offer(lead) == "", "the packs still hold an improvement after Optimise")
	print("party menu: order kept, %s carries %s" % [
		lead.display_name, Gear.display_name(lead.equipment) if lead.equipment != "" else "nothing"
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
	_expect(danger_broken >= danger_open, "a broken gate is no worse than an open one")
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
	_expect(before < GameState.roster.seats, "the party is already full before hiring")

	var cost := Market.asking_hire_cost(town, world, Market.hire_offer(town))
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

	# Seats: four to start, a fifth at floor 5, a sixth at floor 10 (agenda item 35).
	var seats_were := GameState.roster.seats
	var floor_was := world.tower_floor
	_expect(Roster.Seats.for_floor(0) == 4 and Roster.Seats.for_floor(5) == 5 and Roster.Seats.for_floor(10) == 6,
		"the seats by floor are not four, five and six")
	world.tower_floor = 10
	_expect(Roster.Seats.sync(world, GameState.roster) == 6 - seats_were, "floor 10 did not open two seats")
	_expect(GameState.roster.seats == 6, "the company has %d seats at floor 10" % GameState.roster.seats)
	world.tower_floor = floor_was
	GameState.roster.seats = seats_were

	# Buying: gold is the standard of trade. D146: up to three wares are laid out, Z turns to the
	# next, and B buys the one in hand.
	town.data["wares"] = Market.wares(town).duplicate()
	for id: String in Database.equipment:
		if Market.wares(town).size() >= 4:
			break
		if not Database.equipment[id].has("signature") and id not in Market.wares(town):
			(town.data["wares"] as Array).append(id)
	_expect(Market.on_show(town).size() == 3, "the market laid out %d wares, not 3" % Market.on_show(town).size())
	var first_in_hand := Market.in_hand(town)
	Market.next_ware(town)
	_expect(Market.in_hand(town) != first_in_hand and Market.on_show(town).has(Market.in_hand(town)),
		"turning to the next ware kept the same one in hand")
	for i in 2:
		Market.next_ware(town)
	_expect(Market.in_hand(town) == first_in_hand, "three turns did not come back round to the first ware")
	Market.next_ware(town)
	var goods := Market.wares(town)
	if not goods.is_empty():
		var equipment_id: String = Market.in_hand(town)
		var purse := GameState.gold
		_expect(Market.buy(town, equipment_id, GameState.roster.player(), world), "could not buy with 5000 gold")
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


## Chests and caches: gold always lands, and gear finds a wearer or the packs.
func _check_loot() -> void:
	var world: World = GameState.world
	var taker: Character = GameState.roster.party_members()[0]
	taker.equipment = ""
	GameState.stores.clear()

	var purse := GameState.gold
	var lines := Loot.claim({ "gold": 90, "item": "bone_sword" }, GameState.roster)
	_expect(GameState.gold >= purse + 90, "the gold in the chest never arrived")
	_expect(lines.size() == 2, "a chest with gold and gear reported %d lines" % lines.size())
	var worn := GameState.roster.party_members().any(
		func(c: Character) -> bool: return c.equipment == "bone_sword"
	)
	_expect(worn, "nobody picked up the sword out of the chest")

	# Once everyone is already carrying one, another improves nobody. It is
	# still a sword, so it goes in the packs rather than being sold from under
	# a party who might lose the one they have.
	for member: Character in GameState.roster.party_members():
		member.equipment = "bone_sword"
	GameState.stores.clear()
	Loot.claim({ "gold": 0, "item": "bone_sword" }, GameState.roster)
	_expect(GameState.stores.has("bone_sword"), "a spare nobody could wear went nowhere")

	# Junk is a different matter: worth nothing to anybody here, so it is sold.
	purse = GameState.gold
	Loot.stow("yew_longbow", GameState.roster)
	var kept := GameState.stores.has("yew_longbow")
	_expect(kept or GameState.gold > purse, "a piece nobody wanted was neither packed nor sold")

	# Handing gear out never destroys what was being carried.
	GameState.stores.clear()
	GameState.stores.append("steel_blade")
	var held := taker.equipment
	_expect(Gear.equip(taker, "steel_blade"), "the packs would not give up a blade")
	_expect(taker.equipment == "steel_blade", "the blade was not taken up")
	_expect(GameState.stores.has(held), "what they were carrying was thrown away")

	# A charm is carried, never worn, so it always has a taker.
	var charms := GameState.roster.player().charms.size()
	Loot.claim({ "gold": 0, "item": "grave_token" }, GameState.roster)
	_expect(GameState.roster.player().charms.size() == charms + 1, "the charm went nowhere")

	var haul := Loot.roll(world, 1.0)
	_expect(int(haul.get("gold", 0)) > 0, "a rolled cache held no gold at all")
	print("loot: sword worn, spare packed, blade swapped, charm pocketed, cache rolled %d gold" % int(haul["gold"]))


## Word does not teleport. What you do is known where you did it at once, and
## everywhere else only once word has had time to walk there.
func _check_renown() -> void:
	var world: World = GameState.world
	world.deeds.clear()
	var here := world.player_cell
	var away := here + Vector2i(20, 0)

	_expect(Renown.title(world, here) == "a stranger", "the party is famous before doing anything")
	Renown.record(world, Renown.GATE_SHUT, here, 4, "a gate was shut")
	_expect(Renown.standing(world, here) == 4, "the place it happened has not heard about it")
	_expect(Renown.standing(world, away) == 0, "word crossed twenty tiles instantly")
	_expect(Renown.greeting(world, away, "Atlas") == "", "somewhere that has not heard still greeted us")

	world.steps += Renown.steps_per_tile() * 20
	_expect(Renown.standing(world, away) == 4, "word never travelled at all")
	_expect(Renown.title(world, away) != "a stranger", "word arrived and nobody drew a conclusion")
	_expect(Renown.greeting(world, away, "Atlas") != "", "a place that knows us said nothing")

	# Being welcome is worth money; being hated costs it.
	var welcome := Renown.price_multiplier(world, here)
	Renown.record(world, Renown.TOWN_RAIDED, here, -20, "a town was burnt")
	_expect(Renown.price_multiplier(world, here) > welcome, "burning a town did not raise a single price")
	print("renown: %s where it happened, %s twenty tiles off" % [
		Renown.title(world, here), Renown.title(world, away)
	])


## The two things you can do about a town, and what each costs you.
func _check_raid_and_rescue() -> void:
	var world: World = GameState.world
	world.deeds.clear()

	var saved := _site_where(func(s: Site) -> bool:
		return Town.is_settlement(s) and not Town.is_ruined(s)
	)
	if saved == null:
		_expect(false, "the world has no town to defend")
		return
	saved.data["threatened_at"] = world.steps
	_expect(Town.is_threatened(saved), "the siege did not take hold")

	var purse := GameState.gold
	var rescue := Town.save(saved, world)
	_expect(not rescue.is_empty(), "saving a town said nothing")
	_expect(not Town.is_threatened(saved), "the siege outlived the fight")
	_expect(GameState.gold > purse, "saving a town paid nothing")
	_expect(Renown.standing(world, saved.cell) > 0, "saving a town won no goodwill at all")

	var robbed := _site_where(func(s: Site) -> bool:
		return Town.is_settlement(s) and not Town.is_ruined(s) and s != saved
	)
	if robbed == null:
		_expect(false, "the world has only one town")
		return
	Market.refresh(robbed, world)
	purse = GameState.gold
	var goodwill := Renown.standing(world, robbed.cell)
	Town.raid(robbed, world, GameState.roster)
	_expect(GameState.gold >= purse + Town.purse(robbed), "raiding a town paid less than its strongbox")
	_expect(Town.is_ruined(robbed), "the town carried on as though nothing had happened")
	_expect(Market.wares(robbed).is_empty(), "a burnt town is still keeping shop")
	_expect(Renown.standing(world, robbed.cell) < goodwill, "burning a town cost nothing")

	# A town nobody answers for falls on its own.
	var doomed := _site_where(func(s: Site) -> bool:
		return Town.is_settlement(s) and not Town.is_ruined(s) and s != saved and s != robbed
	)
	if doomed != null:
		doomed.data["threatened_at"] = world.steps - int(Town.rules().get("falls_after_steps", 900)) - 1
		Town.upkeep(world)
		_expect(doomed.data.get(Town.SACKED, false), "a town nobody answered for never fell")
	print("towns: %s held, %s burnt for %d gold" % [
		saved.display_name, robbed.display_name, Town.purse(robbed)
	])


func _check_tower_top() -> void:
	var world: World = GameState.world
	var purse := GameState.gold
	world.tower_hoard = 0
	var lines := Spoils.for_tower_floor(world, 4, GameState.party_characters())
	_expect(not lines.is_empty(), "a Tower floor paid nothing")
	# The floor pays into the hoard, not the purse. Carrying it out is the
	# decision the Tower is built around, so nothing lands until you leave.
	_expect(world.tower_hoard > 0, "a Tower floor added nothing to the hoard")
	_expect(GameState.gold == purse, "a Tower floor paid straight into the purse")

	var carried := world.tower_hoard
	_scene._carry_the_hoard_out()
	_expect(world.tower_hoard == 0, "the hoard did not leave the Tower")
	_expect(GameState.gold == purse + carried, "the hoard did not reach the purse")

	world.tower_floor = world.tower_floors()
	_expect(world.tower_is_topped(), "standing on the last floor is not the top")
	print("tower: %d floors, floor 4 hoarded %d gold and carried it out" % [
		world.tower_floors(), carried
	])


func _check_save_round_trip() -> void:
	var world: World = GameState.world
	# Run on its own the clock has not moved, and a new game's clock would look
	# the same as the saved one. Give it somewhere to have been.
	if world.steps == 0:
		world.steps = 37
	# What today's systems keep: kinds learned from, companions away, and being
	# held inside a gate. Set here so a run of this check alone has some.
	var lead_member: Character = GameState.roster.party_members()[0]
	lead_member.beaten["goblin"] = 3
	GameState.away.append({"id": "nobody", "to": [1, 1], "out_at": 999999, "back_at": 999999})
	GameState.delving = [world.player_cell.x, world.player_cell.y]
	var before := {
		"steps": world.steps,
		"cell": world.player_cell,
		"floor": world.tower_floor,
		"gold": GameState.gold,
		"party": GameState.roster.party.size(),
		"doctrine": GameState.roster.party_members()[0].doctrine.size(),
		"deeds": world.deeds.size(),
		"ruined": world.sites.filter(func(s: Site) -> bool: return Town.is_ruined(s)).size(),
		"bond": Banter.bond(GameState.roster.party_members()[0], GameState.roster.party_members()[1]),
		"beaten": lead_member.beaten.duplicate(),
		"away": GameState.away.size(),
		"delving": GameState.delving.duplicate(),
		"bands": world.prowlers.size(),
	}

	# Saved from the sand, the save holds the run's own people, not the copy
	# out there; and a night left open does not outlive the run it was part of.
	var card: String = Arena.cards().keys()[0]
	var lead_name := GameState.roster.player().display_name
	Arena.open("dirte", card)
	GameState.save()
	Arena.close()
	_expect(GameState.has_save(), "saving produced no file")
	Arena.open("dirte", card)
	GameState.new_game(1)
	_expect(not Arena.is_open(), "a new game left a night on the sand open")
	_expect(GameState.tallying, "a new game started with the ledger switched off")
	_expect(GameState.world.steps != before["steps"], "a new game kept the old clock")
	_expect(GameState.load_save(), "the save would not load back")
	_expect(GameState.roster.player().display_name == lead_name, "a save made on the sand kept the copy, not the run's own lead")

	var after: World = GameState.world
	_expect(after.steps == before["steps"], "the clock did not survive the save")
	_expect(after.player_cell == before["cell"], "the player moved across a save")
	_expect(after.tower_floor == before["floor"], "the floor log did not survive the save")
	_expect(GameState.gold == before["gold"], "gold did not survive the save")
	_expect(after.deeds.size() == before["deeds"], "what the country remembers did not survive the save")
	_expect(
		after.sites.filter(func(s: Site) -> bool: return Town.is_ruined(s)).size() == before["ruined"],
		"a burnt town came back across a save"
	)
	_expect(GameState.roster.party.size() == before["party"], "the party did not survive the save")
	_expect(
		GameState.roster.party_members()[0].doctrine.size() == before["doctrine"],
		"what a character had read did not survive the save"
	)
	_expect(
		Banter.bond(GameState.roster.party_members()[0], GameState.roster.party_members()[1])
			== before["bond"],
		"how well the party get on did not survive the save"
	)
	_expect(GameState.roster.party_members()[0].beaten == before["beaten"], "kinds learned from did not survive the save")
	_expect(GameState.away.size() == before["away"], "companions away did not survive the save")
	_expect(GameState.delving == before["delving"], "being held inside a gate did not survive the save")
	# Continue opens the walk on the loaded world; that must not put more bands out.
	var reopened: Node = load("res://src/world/world_scene.tscn").instantiate()
	add_child(reopened)
	_expect(
		GameState.world.prowlers.size() == before["bands"],
		"opening the walk on a loaded save changed the bands abroad from %d to %d" % [
			before["bands"], GameState.world.prowlers.size()
		]
	)
	remove_child(reopened)
	reopened.free()
	# Only here to be saved: nobody is really away, and no gate is holding anyone.
	GameState.away.clear()
	GameState.delving = []
	print("save: %d steps, floor %d, %d gold and %d bands all came back" % [
		before["steps"], before["floor"], before["gold"], before["bands"]
	])


# --- helpers ------------------------------------------------------------------


## Every generated battlefield has to be one a fight can actually happen on.
## Gates carry an objective, fixed by where they stand. A heart floor marks a
## cell the party can stand on; a keeper only waits on the last floor; and the
## fight itself is won the moment either is done.
func _check_objectives() -> void:
	var world: World = GameState.world
	var gates := world.sites_of_kind(Site.GATE)
	var kinds := Site.objective_rules()
	for gate: Site in gates:
		_expect(kinds.has(gate.objective()), "%s has an unknown objective '%s'" % [gate.label(), gate.objective()])
		_expect(gate.objective() == gate.objective(), "%s changed its objective between two looks" % gate.label())

	var gate: Site = null
	for site: Site in gates:
		if not site.cleared and (gate == null or site.floors() > gate.floors()):
			gate = site
	if gate == null:
		_expect(false, "no gate left standing to set an objective on")
		return
	var kept := gate.data.duplicate(true)
	var party := GameState.party_characters()
	var rng := RandomNumberGenerator.new()

	gate.data["objective"] = Site.OBJECTIVE_GUARDIAN
	gate.data["depth"] = gate.floors() - 1
	_expect(gate.floor_objective() == Site.OBJECTIVE_GUARDIAN, "the last floor of a keeper gate is not a keeper fight")
	if gate.floors() > 1:
		gate.data["depth"] = 0
		_expect(gate.floor_objective() == Site.OBJECTIVE_ROUT, "a keeper gate asked for its keeper on floor 1")

	gate.data["objective"] = Site.OBJECTIVE_HEART
	var heart := Encounter.for_gate(world, gate, gate.depth(), gate.is_final_floor(), party, rng)
	_expect(heart.get("objective") == Site.OBJECTIVE_HEART, "a heart gate fielded a '%s' fight" % heart.get("objective"))
	var map: Dictionary = heart.get("map", {})
	_expect(map.has("heart"), "a heart floor has no heart on it")
	if map.has("heart"):
		var at: Array = map["heart"]
		_expect(str(map["tiles"][int(at[1])])[int(at[0])] == ".", "the heart is on ground nobody can stand on")

	var setting := Pace.auto
	Pace.auto = false
	heart["ambush"] = true
	var battle := _open_battle(heart)
	_expect(battle.objective == Site.OBJECTIVE_HEART, "the fight forgot it was a heart fight")
	_expect(not battle._objective_met(), "a heart fight was won before anyone moved")
	var runner: Fighter = battle.party_fighters()[0]
	runner.unit.cell = battle.heart_cell
	# Atlas rides Sky (D93): the two stand on one cell.
	if runner.aboard != null:
		(runner.aboard as Fighter).unit.cell = battle.heart_cell
	runner.hold = true
	_expect(battle._objective_met(), "standing on the heart did not win the floor")
	battle.manual = true
	battle.tick()
	_expect(battle.over and battle.victory, "reaching the heart did not end the fight in the party's favour")
	battle.free()

	gate.data["objective"] = Site.OBJECTIVE_GUARDIAN
	gate.data["depth"] = gate.floors() - 1
	var keeper := Encounter.for_gate(world, gate, gate.depth(), true, party, rng)
	keeper["ambush"] = true
	battle = _open_battle(keeper)
	_expect(not battle._objective_met(), "a keeper fight was won with the keeper standing")
	var keepers := 0
	for f: Fighter in battle.fighters:
		if f.unit.has_meta("boss"):
			keepers += 1
			f.unit.hp = 0
	_expect(keepers > 0, "a keeper fight fielded no keeper")
	_expect(battle._objective_met(), "felling the keeper did not win the floor")
	battle.free()

	Pace.auto = setting
	gate.data = kept
	print("objectives: %d gates, a heart reached and a keeper felled each win the floor" % gates.size())


## Allies stand on the party's side of a fight without being in the party: they
## act on their own, are struck by the enemy and never by you, and their own
## death does not end it.
func _check_allies() -> void:
	var world: World = GameState.world
	var gate := _site_where(func(s: Site) -> bool: return s.kind == Site.GATE and not s.cleared)
	if gate == null:
		_expect(false, "no gate left standing to raise allies for")
		return
	var meeting := Encounter.for_gate(world, gate, 0, false, GameState.party_characters(), RandomNumberGenerator.new())
	BattleMapGen.add_allies(meeting["map"], [{"unit": "brigand", "level": 3}, {"unit": "brigand_archer", "level": 3}])
	_expect(meeting["map"].get("allies", []).size() == 2, "two allies asked for, %d placed" % meeting["map"].get("allies", []).size())

	var setting := Pace.auto
	Pace.auto = false
	meeting["ambush"] = true
	var battle := _open_battle(meeting)
	# Not counting a lead's own beast (Atlas's Sky, D93): it is bound to them, not raised.
	var allies: Array = battle.fighters.filter(func(f: Fighter) -> bool: return f.unit.team == Unit.Team.ALLY and f.bound_to == null) \
			.map(func(f: Fighter) -> Unit: return f.unit)
	var party: Array = battle.fighters.filter(func(f: Fighter) -> bool: return f.unit.team == Unit.Team.PLAYER) \
			.map(func(f: Fighter) -> Unit: return f.unit)
	var foes: Array = battle.fighters.filter(func(f: Fighter) -> bool: return not f.unit.sides_with_party()) \
			.map(func(f: Fighter) -> Unit: return f.unit)
	_expect(allies.size() == 2, "%d allies took the field" % allies.size())
	if not allies.is_empty() and not party.is_empty() and not foes.is_empty():
		var ally: Unit = allies[0]
		_expect(not ally.is_hostile_to(party[0]) and not party[0].is_hostile_to(ally), "an ally and the party are at each other's throats")
		_expect(ally.is_hostile_to(foes[0]) and foes[0].is_hostile_to(ally), "an ally and the enemy are at peace")
		_expect(
			not AbilityResolver.is_valid_target(party[0], Database.ability("strike"), ally),
			"the party can strike its own allies"
		)
		var target: Unit = SkirmishBrain.pick_target(battle.fighter_of(ally), battle.fighters)
		_expect(target == null or not target.sides_with_party(), "an ally went for someone on its own side")
	battle.free()
	Pace.auto = setting
	print("allies: %d take the field on the party's side and strike only the enemy" % allies.size())


## The Guild keeps a hall in every standing keep and village: a register of the
## gates, worst first, and contracts that pay when the gate is shut.
func _check_guild() -> void:
	var world: World = GameState.world
	_expect(not Guild.rules().get("contract", {}).is_empty(), "data/guild.json has no contract terms")
	var hall := _site_where(func(s: Site) -> bool: return Guild.has_hall(s))
	if hall == null:
		_expect(false, "no keep or village keeps a Guild hall")
		return
	var hut := _site_where(func(s: Site) -> bool: return s.kind == Site.HUT)
	_expect(hut == null or not Guild.has_hall(hut), "a hut keeps a Guild hall")
	var kept := hall.data.duplicate(true)
	hall.data[Town.SACKED] = true
	_expect(not Guild.has_hall(hall), "a sacked town still keeps a Guild hall")
	hall.data = kept

	var accepted: Array = []
	var register := Guild.register(world, hall.cell, accepted)
	_expect(not register.is_empty() or world.sites_of_kind(Site.GATE).all(func(g: Site) -> bool: return g.cleared),
		"the register is empty with gates still standing")
	for i in range(1, register.size()):
		_expect(
			Site.rank_index(register[i - 1]["rank"]) >= Site.rank_index(register[i]["rank"]),
			"the register is not worst first (%s before %s)" % [register[i - 1]["rank"], register[i]["rank"]]
		)

	var gate := _site_where(func(s: Site) -> bool: return s.kind == Site.GATE and s.open and not s.cleared)
	if gate == null:
		_expect(false, "no open gate to take a contract on")
		return
	Guild.take(world, hall, gate, accepted)
	_expect(Guild.is_contracted(accepted, gate.cell), "taking a contract did not put it in the job log")
	_expect(Guild.take(world, hall, gate, accepted) == Guild.line("already"), "the same contract was taken twice")
	_expect(Dispatch.open_errands(accepted).is_empty(), "a companion could be sent to shut a gate alone")
	var brewing := _site_where(func(s: Site) -> bool: return s.kind == Site.GATE and not s.open and not s.cleared)
	if brewing != null:
		Guild.take(world, hall, brewing, accepted)
		_expect(not Guild.is_contracted(accepted, brewing.cell), "the Guild paid in advance for a gate nobody can walk into")

	var gold := GameState.gold
	var pay := Guild.pay_for(gate)
	Errand.on_gate_shut(accepted, gate.cell, world)
	_expect(GameState.gold == gold + pay, "shutting a contracted gate paid %d, not %d" % [GameState.gold - gold, pay])
	_expect(not Guild.is_contracted(accepted, gate.cell), "a paid contract stayed in the job log")
	print("guild: %s keeps a hall; %d gates on the register; a contract on %s paid %d" % [
		hall.display_name, register.size(), gate.display_name, pay
	])


## An S-rank gate raises a muster at the nearest hall. It grows each upkeep,
## waits for a company that stands with it in person and goes into the gate
## beside them, survives a save, and nobody standing with it sends it in alone.
## M13: the lead crash-landed somewhere the seed chose and made it home, the
## others came down too and walk between places, and one of them can be met,
## talked to, joined, and saved.
## Sixteen worlds (M15): a lead dies and ascends, the world is watched to its
## end and kept as gone, and the next lead starts at level 1 in a sibling of it
## with the first lead alive there, their weapon on its way and, once caught up
## with, down where it can be found and their ghost at the fire.
func _check_sixteen() -> void:
	var RunMode := preload("res://src/chronicle/run_mode.gd")
	Sixteen.path = "user://earth-kings.sixteen.walk-test.json"
	if FileAccess.file_exists(Sixteen.path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Sixteen.path))
	var hall: Variant = FileAccess.get_file_as_string(Museum.PATH) if FileAccess.file_exists(Museum.PATH) else null
	var kept_mode := GameState.mode
	GameState.mode = RunMode.IRON_MAN
	# D106: with no world ended yet, New Game starts as the First Hour's lead, not the quiz.
	_expect(FirstHour.first_life() == "atlas", "a new player is not Atlas (%s)" % FirstHour.first_life())

	# The first world: Caesar gets to level 4 and floor 3, and dies.
	GameState.new_game(SEED, "caesar")
	var first: World = GameState.world
	var first_tiles: Array = first.tiles.duplicate()
	var first_lead := GameState.roster.player()
	first_lead.level = 4
	first.tower_floor = 3
	first.steps = 50
	# D147: two open rank E gates near the Tower for the Guild to offer; Caesar shut Elderford.
	var choice := first.sites_of_kind(Site.GATE).filter(func(g: Site) -> bool: return Siblings.is_first_hour_gate(g))
	_expect(choice.size() == 2 and choice.all(func(g: Site) -> bool: return g.open and g.rank == "E"),
		"the First Hour does not offer two open rank E gates (%d)" % choice.size())
	for gate: Site in choice:
		if gate.display_name == "Elderford":
			gate.cleared = true
	first_lead.status = Fate.DEAD
	_requests.clear()
	var summary: Control = load("res://src/ui/run_summary.tscn").instantiate()
	summary.boot_payload = { "ending": Museum.FELL }
	add_child(summary)
	var ending: Dictionary = _requests.back() if not _requests.is_empty() else {}
	_expect(ending.get("key", "") == "world" and bool(ending.get("payload", {}).get("world_ends", false)),
		"an Iron Man lead's death did not go to watch the world end: %s" % str(ending))
	summary.queue_free()
	var gone := Sixteen.worlds()
	_expect(gone.size() == 1 and bool(gone[0].get("gone", false)), "the world that ended was not kept as gone: %s" % str(gone))

	# The end itself: the map, the fire, and back to the summary to tell it.
	var last_look: Node = load("res://src/world/world_scene.tscn").instantiate()
	last_look.boot_payload = { "world_ends": true }
	add_child(last_look)
	for i in 5:
		await get_tree().process_frame
	var burning: Node = last_look.get_node_or_null("WorldEnd")
	_expect(burning != null, "the world ended without anything to watch")
	if burning != null:
		burning.skip()
		var waited := 0
		while not _requests.any(func(r: Dictionary) -> bool: return r["key"] == "summary") and waited < 600:
			await get_tree().process_frame
			waited += 1
		var told := _requests.filter(func(r: Dictionary) -> bool: return r["key"] == "summary")
		_expect(not told.is_empty() and bool(told[0]["payload"].get("settled", false)), "the end of the world never came back to tell the run")
	last_look.queue_free()
	await get_tree().process_frame

	# The next lead, in a sibling world.
	GameState.new_game(0, "ares")
	var world: World = GameState.world
	var lead := GameState.roster.player()
	_expect(world.world_seed == SEED and Siblings.number(world) == 2, "the next world was seed %d, world %d, not a sibling of %d" % [world.world_seed, Siblings.number(world), SEED])
	_expect(world.tiles == first_tiles, "the sibling world is not the same ground")
	_expect(lead.template_id == "ares" and lead.level == 1, "the next lead did not start at level 1")
	_expect(gone.back().get("shut_gate", "") == "Elderford", "the world that ended forgot which gate was shut: %s" % gone.back().get("shut_gate", ""))
	var heard: Array = Fall.landing_dialogue(world, "Ares", "ares").get("lines", [])
	_expect(heard.any(func(l: Dictionary) -> bool: return str(l["text"]).contains("Elderford")),
		"the next life never heard which gate the last one shut")
	_expect(heard.size() <= 5, "the next life's crater has %d boxes, more than five (D122)" % heard.size())
	_expect(world.sites_of_kind(Site.GATE).filter(func(g: Site) -> bool: return Siblings.is_first_hour_gate(g) and g.open).size() == 2,
		"the sibling world shut one of the First Hour's gates")
	_expect(Chapters.census(world) == 16, "the census counted Caesar out before the climb got as far as he did")

	# Caesar, alive here, somewhere findable, and talking like one of the sixteen.
	var copy := Wanderers.entry(world, "caesar")
	_expect(bool(copy.get("echo", false)), "Caesar is not alive in the next world")
	var waiting := world.site_at(Wanderers.cell_of(copy.get("at", [])))
	_expect(waiting != null and not (copy.get("known", []) as Array).is_empty(), "nobody knows where Caesar is")
	var talk_id := Wanderers.talk(world, GameState.roster, "caesar")
	_expect(Database.dialogue(talk_id).get("nodes", {}).has("echo"), "Caesar's copy has nothing to say to the one who knew him")

	# His weapon waits until the new lead has got as far as he did.
	var echo := Siblings.echo_of(world, "caesar")
	var weapon: Dictionary = echo.get("weapon", {})
	_expect(str(weapon.get("id", "")) == "every_morning", "Caesar's weapon is '%s'" % weapon.get("id", ""))
	_expect(Siblings.upkeep(world).is_empty() and not bool(weapon.get("landed", false)), "Caesar's weapon came down before anyone got as far as he did")
	_expect(Siblings.ghosts(world).is_empty(), "Caesar's ghost was at the fire before he had anything to tell")
	lead.level = 4
	world.tower_floor = 3
	_expect(not Siblings.upkeep(world).is_empty() and bool(weapon.get("landed", false)), "Caesar's weapon never came down")
	_expect(Chapters.census(world) == 15, "the census still read sixteen at Caesar's floor")
	_expect(not Siblings.rumour(world).is_empty() and Siblings.heard_weapons(world).size() == 1, "no rumour points at Caesar's weapon")
	var cell := Wanderers.cell_of(weapon.get("cell", []))
	var home := world.home()
	# Anywhere the company can walk (D60), but never on top of where they fell.
	_expect(Pathfinder.distance(cell, home.cell) >= int(Siblings.rules().get("weapon", {}).get("min_distance", 5)), "Caesar's weapon came down on top of where the lead fell")
	_expect(world.site_at(cell) == null and not Fall.NOT_GROUND.has(world.terrain_id_at(cell)), "Caesar's weapon came down somewhere nobody can stand")
	_expect(Siblings.ghosts(world) == [0], "Caesar's ghost is not at the fire")
	var camp: Node = load("res://src/area/area_scene.tscn").instantiate()
	camp.boot_payload = { "area_id": "home", "return_scene": "world" }
	add_child(camp)
	await get_tree().process_frame
	_expect(camp.map.people.any(func(p: Dictionary) -> bool: return p.has("ghost")), "nobody sat at the fire for Caesar")
	camp.queue_free()
	await get_tree().process_frame
	var ghost_id := Siblings.ghost_talk(world, 0)
	_expect(Database.dialogue(ghost_id).get("nodes", {}).has("weapon"), "Caesar's ghost cannot say where his weapon went")
	_expect(not Siblings.on_arrive(world, cell).is_empty() and GameState.stores.has("every_morning"), "walking onto the crater did not find Caesar's weapon")
	_expect(Siblings.pages_shared(echo) == (echo.get("pages", []) as Array).size(), "finding the weapon did not open the ghost fully")

	GameState.save()
	GameState.load_save()
	_expect(bool(Siblings.echo_of(GameState.world, "caesar").get("weapon", {}).get("found", false)), "the save forgot what came through from the world that ended")

	_expect(FirstHour.first_life() == "", "after a world ended, New Game did not go to the quiz")

	if FileAccess.file_exists(Sixteen.path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Sixteen.path))
	Sixteen.path = SIXTEEN_PATH
	GameState.mode = kept_mode
	if hall == null:
		if FileAccess.file_exists(Museum.PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(Museum.PATH))
	else:
		FileAccess.open(Museum.PATH, FileAccess.WRITE).store_string(hall)
	GameState.new_game(SEED)
	print("sixteen worlds: Caesar fell on floor 3, the world burned, and Ares found Caesar alive, then his weapon and his ghost")


## The First Hour's objective (D95): the nearest town until one is stood in,
## then the lowest gate until one is shut, then the Tower; an errand taken comes
## first. Auto walks to it and, at a town, hands control back.
func _check_first_hour() -> void:
	var world: World = GameState.world
	var kept_errands := GameState.errands.duplicate(true)
	var kept_prowlers := world.prowlers.duplicate()
	var kept_cell := world.player_cell
	var kept_auto := Pace.auto
	var kept_floor := world.tower_floor
	var kept_topped := world.tower_topped
	# Earlier checks topped the Tower; the climb is ahead in a First Hour.
	world.tower_floor = 0
	world.tower_topped = false
	GameState.errands.clear()
	world.prowlers.clear()
	GameState.set_flag(AutoRoad.TOWN_REACHED, false)
	GameState.set_flag(Guild.VISITED, false)
	var kept_cleared: Array[Site] = []
	for gate: Site in world.sites_of_kind(Site.GATE):
		if gate.cleared:
			kept_cleared.append(gate)
			gate.cleared = false
	# A new player plays the First Hour setting, where a fall is for good (D104).
	_expect(Difficulty.DEFAULT == "first_hour" and float(Difficulty.settings()["first_hour"].get("permadeath", 0.0)) > 0.0,
		"the First Hour setting is not the default, or a fall there is not for good")

	var goal := AutoRoad.objective(world)
	var town := world.site_at(goal.get("cell", Vector2i(-1, -1)))
	_expect(town != null and Town.is_settlement(town), "the first objective is not a town")
	_expect(bool(goal.get("stop", false)), "Auto would walk on past the first town")
	if town != null:
		_expect(AutoRoad.errand(world) == town.cell or world.player_cell == town.cell, "Auto is not walking to the objective")
		# Standing in it moves the objective on, and a party walking itself stops there.
		Pace.auto = true
		_scene._hand_back_at(goal, town.cell)
		_expect(not Pace.auto, "Auto did not hand back control at the town")
		world.player_cell = town.cell
		_scene._arrive_at(town)
		_scene._busy = false
	_expect(GameState.has_flag(AutoRoad.TOWN_REACHED), "standing in a town did not mark the first leg done")
	var tower := world.tower()
	# AU (D161, the five strangers): after the town the compass goes straight on to the first gate,
	# and Sennet said why as the party walked in; the Guild at the door does not hold it up.
	var to_gate := world.site_at(AutoRoad.objective(world).get("cell", Vector2i(-1, -1)))
	_expect(to_gate != null and to_gate.kind == Site.GATE, "after the town the compass does not point at a gate: %s" % AutoRoad.objective(world))
	if to_gate != null:
		_expect(FirstHour.gate_line(to_gate.display_name).contains(to_gate.display_name), "Sennet's line does not name %s" % to_gate.display_name)
	# With the rule off, the Guild at the Tower's door (D107), where Auto stops, until its register is opened.
	var first_hour: Dictionary = Database.world_rules["first_hour"]
	first_hour["gate_after_city"] = false
	var guild := AutoRoad.objective(world)
	_expect(guild.get("cell", Vector2i(-1, -1)) == tower.cell and bool(guild.get("stop", false)),
		"after the town Auto does not stop at the Guild: %s" % guild)
	_expect(FirstHour.gate_line("Greyhollow") == "", "Sennet sends the party to a gate with the rule off")
	first_hour["gate_after_city"] = true
	GameState.set_flag(Guild.VISITED)
	var next := AutoRoad.objective(world)
	var after := world.site_at(next.get("cell", Vector2i(-1, -1)))
	_expect(after != null and after.kind in [Site.GATE, Site.TOWER], "after the town the objective is %s, not a gate or the Tower" % next)
	# Never a gate above the lead's rank (D97): with none at it open, the Tower.
	var lead := GameState.roster.player()
	if after != null and after.kind == Site.GATE:
		_expect(after.expected_level() <= lead.level, "the compass sent a level %d lead to a rank %s gate" % [lead.level, after.rank])
	var kept_level := lead.level
	lead.level = 0
	var beneath := world.site_at(AutoRoad.objective(world).get("cell", Vector2i(-1, -1)))
	_expect(beneath != null and beneath.kind == Site.TOWER, "a lead below every open gate was not sent to the Tower")
	lead.level = kept_level

	var job := {"kind": Errand.LOOK, "title": "Look", "to": [kept_cell.x, kept_cell.y], "to_name": "the old well"}
	GameState.errands.append(job)
	_expect(AutoRoad.objective(world).get("label", "") == "the old well", "an errand taken is not the objective")

	# The quest list (D190): the road and the errand are both in it; nothing is followed until
	# chosen; L steps on from what the compass shows; a finished errand lets the compass go back.
	var Quests := load("res://src/world/quests.gd")
	Quests.follow("")
	var listed: Array = AutoRoad.quests(world)
	_expect(listed.size() >= 2, "the quest list holds %d, not the road and the errand" % listed.size())
	_expect(not listed.is_empty() and str(listed[0]["id"]) == "road", "the road is not first in the quest list")
	var stepped: Dictionary = AutoRoad.next_quest(world)
	_expect(str(stepped.get("label", "")) != "the old well", "L did not move the compass off the errand it showed")
	_expect(AutoRoad.objective(world).get("label", "") == str(stepped.get("label", "?")), "the compass does not follow the quest chosen")
	_expect(Quests.followed_id() != "", "the quest followed is not kept in the run's flags")
	AutoRoad.next_quest(world)
	_expect(AutoRoad.objective(world).get("label", "") == "the old well", "stepping on again did not come back round to the errand")
	GameState.errands.erase(job)
	_expect(AutoRoad.objective(world).get("label", "") != "the old well", "a finished errand is still followed")
	_expect(Quests.followed_id() == "", "a quest that is gone is still followed")

	GameState.errands.clear()
	GameState.errands.append_array(kept_errands)
	world.prowlers.append_array(kept_prowlers)
	world.player_cell = kept_cell
	world.tower_floor = kept_floor
	world.tower_topped = kept_topped
	for gate: Site in kept_cleared:
		gate.cleared = true
	Pace.auto = kept_auto
	print("first hour: %s, then %s, then %s" % [goal.get("label", "?"), guild.get("label", "?"), next.get("label", "?")])


func _check_fall() -> void:
	var world: World = GameState.world
	var house := world.home()
	_expect(house != null and bool(house.data.get("crash", false)), "home is not the crash site")
	if house == null:
		return
	var tower := world.tower()
	var reach := Fall.reachable(world)
	# The first world's lead comes down on the road to the great city (D101);
	# a later world's keeps the far rule.
	var city := Fall.great_city(world)
	var band: Dictionary = Fall.crash_rules().get("first_world", {})
	_expect(city != null and Pathfinder.distance(city.cell, tower.cell) <= 2, "the great city does not stand at the Tower's foot")
	if city != null:
		var apart := Pathfinder.distance(house.cell, city.cell)
		_expect(apart >= int(band.get("city_min", 12)) and apart <= int(band.get("city_max", 16)),
				"the first world's lead landed %d tiles from the great city" % apart)
	var far := Fall.crash_cell(world, "lead:", reach)
	_expect(
		Pathfinder.distance(far, tower.cell) >= int(Fall.crash_rules().get("min_tower_distance", 24)),
		"a later world's lead lands on the Tower's doorstep"
	)
	_expect(reach.has(house.cell), "the crash site cannot walk to the Tower")
	_expect(far == Fall.crash_cell(world, "lead:", reach), "the same seed landed the lead in two places")
	_expect(Fall.first_crash_cell(world, "lead:atlas", reach) == Fall.first_crash_cell(world, "lead:atlas", reach),
			"the same seed landed the first lead in two places")
	_expect(not Fall.quest_progress(world).is_empty(), "the standing quest says nothing about the climb")
	var landing_said: Array = Fall.landing_dialogue(world, "Atlas", "atlas").get("lines", [])
	_expect(not landing_said.is_empty(), "the landing has nothing to say")
	# D122: at most five boxes before the first step, asked for three times (meeting 4).
	var before_first_step := landing_said.size() + Siblings.landing_lines(world).size()
	_expect(before_first_step <= 5, "the crater puts up %d boxes before the first step, not five or fewer (D122)" % before_first_step)
	_expect(landing_said.any(func(l: Dictionary) -> bool: return str(l["speaker"]) == "Bram"), "nobody pulls the lead out of the crater")
	_expect(landing_said.any(func(l: Dictionary) -> bool: return str(l["text"]).contains("Sky")), "Sky is not in Atlas's crater")
	# A lead with a chapter one answers Bram in their own words, one line, and the crater stays at five (D138).
	for lead: String in Database.memories:
		if lead.begins_with("_"):
			continue
		var named := str(Database.unit_template(lead).get("display_name", lead))
		var theirs: Array = Fall.landing_dialogue(world, named, lead).get("lines", [])
		var own := theirs.filter(func(l: Dictionary) -> bool: return str(l["speaker"]) == named)
		_expect(own.size() == 1, "%s says %d lines in the crater, not one" % [lead, own.size()])
		_expect(theirs.size() + Siblings.landing_lines(world).size() <= 5, "%s's crater puts up more than five boxes (D122)" % lead)
	var juno: Array = Fall.landing_dialogue(world, "Juno", "juno").get("lines", [])
	_expect(juno.size() == landing_said.size() - 1, "Sky came down with somebody who is not Atlas")
	_expect(str(landing_said[0]["text"]).contains(Fall.ground_word(world, world.player_cell)),
			"the landing names ground that is not the ground under the lead")

	# The First Hour's gate: open, rank E, near the city, and open in every world (D101).
	var first_gate: Site = null
	for gate: Site in world.sites_of_kind(Site.GATE):
		if bool(gate.data.get("first_gate", false)):
			first_gate = gate
	_expect(first_gate != null and first_gate.open and first_gate.rank == "E", "there is no open rank E gate for the First Hour")
	if first_gate != null and city != null:
		_expect(Pathfinder.distance(first_gate.cell, city.cell) <= 10, "the First Hour's gate is far from the great city")
		var twin := WorldGen.generate(world.world_seed)
		for sibling in range(1, 6):
			Siblings.perturb(twin, sibling)
			_expect(twin.site_at(first_gate.cell).open, "the First Hour's gate shut in sibling world %d" % sibling)

	# Nobody climbs without the Guild's mark (D101): the Tower's door keeps a hall.
	_expect(Guild.has_hall(tower), "the Guild keeps no desk at the Tower's door")
	if FirstHour.wants_guild_mark():
		var kept_sealed := world.tower_sealed_at
		var kept_deeds := world.deeds.duplicate()
		var kept_floor := world.tower_floor
		world.tower_floor = 0
		world.deeds = []
		world.tower_sealed_at = 0
		_expect(Chapters.sealed(world), "the stair is open before the Guild's mark")
		_expect(Chapters.seal_line(world) == FirstHour.mark_line(), "the doorkeeper does not ask for the Guild's mark")
		world.deeds.append({"kind": Renown.GATE_SHUT, "step": world.steps})
		_expect(not Chapters.sealed(world), "shutting a gate did not earn the Guild's mark")
		world.tower_sealed_at = kept_sealed
		world.deeds = kept_deeds
		world.tower_floor = kept_floor

	# Every lead the run did not start with is out there (D78).
	# Everyone but the lead: the two who joined this suite's company joined after the landing.
	var others := Database.heroes.size() - 1
	_expect(world.wanderers.size() == others, "%d others landed, not %d" % [world.wanderers.size(), others])
	# Each walks first for the kind of place that is their own when someone else leads.
	for each: Dictionary in world.wanderers:
		var own := Wanderers.home_kind(str(each["id"]))
		var going := world.site_at(Wanderers.cell_of(each.get("to", [])))
		# Still on the first leg out of the crater: never stopped anywhere yet.
		if own != "" and going != null and int(each.get("stay_until", 0)) == 0:
			_expect(going.kind == own, "%s set off for a %s, not a %s" % [each["id"], going.kind, own])
	# Time passes: everyone gets somewhere, and stays a while.
	var steps := world.steps
	for i in 20:
		world.steps += World.UPKEEP_INTERVAL
		Wanderers.upkeep(world)
	var settled: Dictionary = {}
	for each: Dictionary in world.wanderers:
		if (each.get("to", []) as Array).is_empty() and not bool(each.get("joined", false)) \
				and not GameState.roster.characters.any(func(c: Character) -> bool: return c.template_id == str(each["id"])):
			settled = each
			break
	_expect(not settled.is_empty(), "after %d steps nobody of the sixteen had got anywhere" % (world.steps - steps))
	if settled.is_empty():
		return
	var site := world.site_at(Wanderers.cell_of(settled["at"]))
	_expect(site != null, "%s stopped somewhere that is not a place" % settled["id"])
	if site == null:
		return

	var hero_id := str(settled["id"])
	# A power waiting to be taken is asked about first; this check is about who is
	# standing here, so the walk so far is not allowed to have earned one.
	for member: Character in GameState.roster.party_members():
		member.rungs = 0
	world.player_cell = site.cell
	var told := Wanderers.on_arrive(world, site)
	_expect(not told.is_empty(), "standing beside %s, nobody saw them" % hero_id)
	_expect(not (settled.get("known", []) as Array).is_empty(), "seeing %s left them unknown" % hero_id)
	var offered: bool = _scene._actions_here().any(func(doing: Dictionary) -> bool:
		return str(doing["label"]).begins_with("Speak with")
	)
	_expect(offered, "nothing offered to speak with %s" % hero_id)

	while not GameState.roster.has_room():
		GameState.roster.party.pop_back()
	var dialogue_id := Wanderers.talk(world, GameState.roster, hero_id)
	_expect(Database.dialogue(dialogue_id).has("nodes"), "no conversation was written for %s" % hero_id)
	GameState.set_flag(Wanderers.JOIN_FLAG + hero_id)
	EventBus.dialogue_finished.emit(dialogue_id)
	var joined := GameState.roster.characters.any(func(c: Character) -> bool: return c.template_id == hero_id)
	_expect(joined, "%s agreed to walk with you and did not" % hero_id)
	_expect(not Wanderers.rumour(world).is_empty(), "the inns have nothing to say about the others")

	GameState.save()
	GameState.load_save()
	world = GameState.world
	_scene.world = world
	_expect(world.wanderers.size() == others, "the others did not survive a save")
	_expect(bool(Wanderers.entry(world, hero_id).get("joined", false)), "a save forgot %s had joined" % hero_id)
	print("fall: landed %s from the Tower, %d others walking, met and joined %s" % [
		Pathfinder.distance(house.cell, tower.cell), world.wanderers.size(), hero_id
	])


## The explored map ([D50]): black until walked, inked in by a Guild map, a
## found fragment and a rumour, and the same after a save.
func _check_map() -> void:
	var world: World = GameState.world
	_expect(Atlas.is_explored(world, world.player_cell), "the ground the party stands on is not on its map")
	var far := Vector2i(world.size.x - 1 - world.player_cell.x, world.size.y - 1 - world.player_cell.y)
	if Pathfinder.distance(far, world.player_cell) > Atlas.sight() * 3:
		_expect(not Atlas.is_explored(world, far), "ground across the continent is on the map unwalked")
	var hall := _site_where(func(s: Site) -> bool: return Guild.has_hall(s) and not Atlas.guild_map_bought(s))
	if hall != null:
		GameState.gold += 10000
		var purse := GameState.gold
		var bought := Atlas.buy_guild_map(world, hall)
		_expect(bool(bought.get("ok", false)), "the Guild would not sell its map: %s" % bought.get("line", ""))
		_expect(GameState.gold == purse - Atlas.guild_map_price(), "the Guild map cost the wrong amount")
		_expect(Atlas.is_charted(world, hall.cell + Vector2i(3, 0)) or not world.in_bounds(hall.cell + Vector2i(3, 0)),
			"the Guild map did not draw the country round %s" % hall.display_name)
		_expect(not bool(Atlas.buy_guild_map(world, hall).get("ok", true)), "the same Guild map sold twice")
	var before := world.marked.size()
	var said := Atlas.read_fragment(world, "smoke")
	_expect(not said.is_empty(), "a map fragment said nothing")
	_expect(world.marked.size() >= before, "a map fragment unmarked something")
	var unknown := _site_where(func(s: Site) -> bool: return not Atlas.knows(world, s))
	if unknown != null:
		Atlas.hear_of(world, "They say %s is worth the walk." % unknown.display_name)
		_expect(Atlas.knows(world, unknown), "a rumour naming %s did not put it on the map" % unknown.display_name)
	var target := Atlas.frontier(world, world.player_cell)
	_expect(target.x < 0 or not Atlas.is_explored(world, target), "the frontier is ground already seen")
	var back := World.from_dict(JSON.parse_string(JSON.stringify(world.to_dict())))
	_expect(back.explored == world.explored and back.charted == world.charted and back.marked == world.marked,
		"the map did not survive a save")
	var payload := world.to_dict()
	payload.erase("explored")
	_expect(Atlas.is_explored(World.from_dict(payload), far), "a save from before the map lost its map")


func _check_muster() -> void:
	var world: World = GameState.world
	var gate := _site_where(func(s: Site) -> bool: return s.kind == Site.GATE and not s.cleared)
	if gate == null:
		_expect(false, "no gate left standing to muster for")
		return
	var kept_gate := gate.to_dict()
	var kept_musters := world.musters.duplicate(true)
	gate.rank = "S"
	gate.open = true
	gate.broken = false
	world.musters.clear()
	var accepted: Array = []
	var terms := Guild.muster_rules()

	Guild.upkeep(world, accepted)
	var muster := Guild.muster_at(world, gate.cell)
	_expect(not muster.is_empty(), "an open S-rank gate raised no muster")
	if muster.is_empty():
		return
	var hall := world.site_at(Vector2i(int(muster["hall"][0]), int(muster["hall"][1])))
	_expect(Guild.has_hall(hall), "the muster gathered somewhere with no Guild hall")
	var start := int(muster["strength"])
	Guild.upkeep(world, accepted)
	_expect(int(muster["strength"]) > start, "the muster did not grow over an upkeep")

	var restored := World.from_dict(JSON.parse_string(JSON.stringify(world.to_dict())))
	_expect(not Guild.muster_at(restored, gate.cell).is_empty(), "the muster was lost across a save")

	_expect(Guild.allies_for(world, gate, accepted, GameState.party_characters()).is_empty(),
		"a muster nobody joined went into the gate with the party")
	Guild.join(world, muster, accepted)
	_expect(Guild.joined_in_person(accepted, gate.cell), "joining the muster did not put the company with it")
	var allies := Guild.allies_for(world, gate, accepted, GameState.party_characters())
	_expect(not allies.is_empty(), "a muster the company stands with sent nobody into the gate")

	muster["strength"] = int(muster["needed"])
	for i in int(terms.get("wait_upkeeps", 4)) + 1:
		Guild.upkeep(world, accepted)
	_expect(not Guild.muster_at(world, gate.cell).is_empty(), "a muster went in alone while the company stood with it")

	accepted.clear()
	for i in int(terms.get("wait_upkeeps", 4)):
		Guild.upkeep(world, accepted)
	_expect(Guild.muster_at(world, gate.cell).is_empty(), "a ready muster nobody stood with never went in")
	_expect(gate.cleared or gate.broken, "a muster went in and left the gate as it was")
	print("muster: %s raised one at %s; %d go in beside the company; alone, it %s" % [
		gate.display_name, hall.display_name, allies.size(), "shut it" if gate.cleared else "broke it"
	])

	var back := Site.from_dict(kept_gate)
	gate.rank = back.rank
	gate.open = back.open
	gate.broken = back.broken
	gate.cleared = back.cleared
	world.musters = kept_musters


## A training fight on [param meeting], built and left paused before anyone moves.
func _open_battle(meeting: Dictionary) -> Node:
	var battle: Node = load("res://src/skirmish/skirmish.tscn").instantiate()
	battle.boot_payload = {"encounter": meeting, "sandbox": true, "return_scene": "world", "paused": true}
	add_child(battle)
	return battle


func _check_field(meeting: Dictionary, label: String) -> void:
	var map: Dictionary = meeting.get("map", {})
	var rows: Array = map.get("tiles", [])
	_expect(not rows.is_empty(), "%s encounter generated no ground" % label)
	_expect(not meeting["enemies"].is_empty(), "%s encounter has nobody in it" % label)
	for entry: Dictionary in map.get("enemies", []):
		_expect(entry.has("cell"), "%s encounter left an enemy unplaced" % label)


## Put the player beside [param cell], then step onto it for real.
## D197: walking in and out over a town's edge is one save for arriving, not one a crossing (eleven
## in four minutes at Stormreach); coming back from further off is an arrival again.
func _check_town_saves() -> void:
	var world: World = GameState.world
	var town := _site_where(func(s: Site) -> bool:
		return Town.is_settlement(s) and s.kind != Site.HUT and not Town.is_ruined(s))
	if town == null:
		_expect(false, "town saves: no town to walk into")
		return
	var RunMode := preload("res://src/chronicle/run_mode.gd")
	var saves: Array[String] = []
	# By name: a save left waiting from an earlier town (they are sent a frame late) is not this one.
	var count := func(point: String, note: String) -> void:
		if point == RunMode.TOWN and note.ends_with(town.display_name):
			saves.append(point)
	EventBus.safe_point_reached.connect(count)
	var was_auto := Pace.auto
	var was_at := world.player_cell
	var flags_were: Dictionary = GameState.flags.duplicate(true)
	Pace.auto = false
	await get_tree().process_frame
	_from_far_off(town)
	for i in 3:
		_step_onto(town.cell)
		await get_tree().process_frame
	_expect(saves.size() == 1, "town saves: in and out of %s three times saved %d times, not once" % [town.display_name, saves.size()])
	_from_far_off(town)
	_step_onto(town.cell)
	await get_tree().process_frame
	_expect(saves.size() == 2, "town saves: back in %s from far off was not saved as an arrival (%d saves)" % [town.display_name, saves.size()])
	EventBus.safe_point_reached.disconnect(count)
	Pace.auto = was_auto
	world.player_cell = was_at
	GameState.flags = flags_were


## D210 (call BL): a party walking itself at under half its health makes for the nearest place
## it rests, before a band or the objective; at full health it does not.
func _check_auto_rests() -> void:
	var world: World = GameState.world
	var kept := {}
	for member: Character in GameState.party_characters():
		kept[member] = member.hp
		member.hp = -1
	_expect(AutoRoad.rest_stop(world).x < 0, "auto rests: a party at full health was sent to rest")
	for member: Character in kept:
		member.hp = maxi(1, member.max_hp() / 10)
	var stop := AutoRoad.rest_stop(world)
	var there := world.site_at(stop)
	_expect(there != null and there.kind in [Site.VILLAGE, Site.KEEP, Site.HUT],
		"auto rests: a party at a tenth of its health was not sent somewhere to rest (%s)" % stop)
	_expect(stop.x < 0 or AutoRoad.errand(world) == stop, "auto rests: hurt, Auto still made for something else first")
	# D211: Auto goes into a gate it crosses only when it is making for it, and never hurt.
	var gates := world.sites_of_kind(Site.GATE)
	for gate: Site in gates:
		_expect(not AutoRoad.goes_into(world, gate.cell), "auto rests: hurt, Auto would go into %s" % gate.display_name)
	for member: Character in kept:
		member.hp = kept[member]
	var goal := AutoRoad.objective(world)
	for gate: Site in gates:
		if not goal.is_empty() and goal["cell"] != gate.cell:
			_expect(not AutoRoad.goes_into(world, gate.cell),
				"auto gates: Auto would go into %s on its way to %s" % [gate.display_name, goal.get("label", goal["cell"])])


## A step taken more than six tiles from [param town], which is being away from it.
func _from_far_off(town: Site) -> void:
	var world: World = GameState.world
	var far := _find_cell(func(c: Vector2i) -> bool:
		return world.is_walkable(c) and Pathfinder.distance(c, town.cell) > 6 and world.site_at(c) == null \
			and world.is_walkable(c + Vector2i.RIGHT) and world.site_at(c + Vector2i.RIGHT) == null)
	world.player_cell = far + Vector2i.RIGHT
	_scene._step(Vector2i.LEFT)


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


## D152: a gate is a seam between the sixteen worlds. The first gate of the first
## life always opens onto another lead as it shuts, alive in their own world; a
## lead whose world has ended is seen as a burning world with nobody in it; the
## company never crosses; and the same gate in the same world always shows the
## same one, so a reload never turns up someone else.
func _check_crossing() -> void:
	var Crossing := preload("res://src/chronicle/crossing.gd")
	var world: World = GameState.world
	var gate := _site_where(func(s: Site) -> bool: return s.kind == Site.GATE)
	if gate == null:
		_expect(false, "no gate to cross at")
		return
	var rules := Crossing.rules()
	for hero_id: String in Database.heroes:
		if not hero_id.begins_with("_"):
			_expect((rules.get("says", {}) as Dictionary).has(hero_id), "%s has nothing to say through a gate" % hero_id)

	var met := Crossing.roll(world, gate, "atlas", [], [], true)
	_expect(not met.is_empty(), "the first gate of the first life opened onto nobody")
	_expect(str(met.get("hero", "atlas")) != "atlas" and not bool(met.get("ended", true)),
		"the first crossing was not another lead, alive: %s" % str(met))
	_expect(Crossing.roll(world, gate, "atlas", [], [], true) == met, "the same gate rolled twice met someone else")
	var lines: Array = Crossing.scene(met, gate, "Atlas").get("lines", [])
	_expect(lines.size() == (rules.get("living", []) as Array).size(), "the crossing scene lost lines")
	_expect(lines.any(func(line: Dictionary) -> bool: return str(line["speaker"]) == str(met["name"])),
		"%s never speaks through the gate" % str(met.get("name", "")))
	_expect(lines.all(func(line: Dictionary) -> bool: return not str(line["text"]).contains("{")),
		"a crossing line kept a blank: %s" % str(lines))

	# Rolled across many worlds: about the rank's chance, never the company, and the dead as ended.
	var kept_seed := world.world_seed
	var company := ["janus", "pluto"]
	var opened := 0
	var ended := 0
	var tries := 400
	for i in tries:
		world.world_seed = 1000 + i
		var roll := Crossing.roll(world, gate, "atlas", company, ["caesar"], false)
		if roll.is_empty():
			continue
		opened += 1
		_expect(not company.has(roll["hero"]), "%s crossed while walking with the lead" % roll["hero"])
		_expect(bool(roll["ended"]) == (roll["hero"] == "caesar"), "%s crossed from the wrong kind of world" % roll["hero"])
		if bool(roll["ended"]):
			ended += 1
			var ash: Array = Crossing.scene(roll, gate, "Atlas").get("lines", [])
			_expect(ash.all(func(line: Dictionary) -> bool: return str(line["speaker"]) == ""), "someone spoke from an ended world")
	world.world_seed = kept_seed
	var chance := float((rules.get("chance", {}) as Dictionary).get(gate.rank, 0.0))
	_expect(absf(float(opened) / tries - chance) < 0.1, "a %s gate opened %d times in %d, not about %d%%" % [
		gate.rank, opened, tries, roundi(chance * 100.0)])
	_expect(ended > 0, "a world that ended was never seen through a gate")

	# Shut in a run: written down, and a scene to play.
	var kept_chance: Dictionary = (rules["chance"] as Dictionary).duplicate()
	(rules["chance"] as Dictionary)[gate.rank] = 1.0
	var dialogue_id := Crossing.on_gate_shut(world, gate)
	rules["chance"] = kept_chance
	_expect(dialogue_id != "" and not Database.dialogue(dialogue_id).is_empty(), "a crossing in a run had no scene to play")
	_expect(GameState.has_flag(Crossing.ANY), "a crossing in a run was not kept")
	print("crossing: first gate met %s; %d of %d %s gates opened, %d onto an ended world" % [
		met.get("name", ""), opened, tries, gate.rank, ended])
	_check_word_carried(gate)


## D183: a word carries. The lead who shuts a gate leaves a word there, kept
## beside the fallen outside the save; the next life, shutting the same gate in
## a sibling of the same world, hears it through the light. At the first gate
## of a life the lead who fell last is heard, or word of them; a world of its
## own hears nothing.
func _check_word_carried(gate: Site) -> void:
	var Crossing := preload("res://src/chronicle/crossing.gd")
	var world: World = GameState.world
	var rules := Crossing.rules()
	var carried: Dictionary = rules.get("carried", {})
	var left: Dictionary = carried.get("left", {})
	for hero_id: String in Database.heroes:
		if not hero_id.begins_with("_"):
			_expect(left.has(hero_id), "%s leaves no word at a gate" % hero_id)
	var lead := GameState.roster.player()
	var first_id := lead.template_id
	var first_name := lead.display_name
	var record := "user://earth-kings.sixteen.crossing-test.json"
	Sixteen.path = record
	_forget_sixteen()
	var kept_flags := GameState.flags.duplicate(true)
	var kept_echoes := world.echoes.duplicate(true)
	var kept_chance: Dictionary = (rules["chance"] as Dictionary).duplicate()
	(rules["chance"] as Dictionary)[gate.rank] = 0.0

	# The first life shuts the gate: the word is written down, once.
	Crossing.on_gate_shut(world, gate)
	Crossing.on_gate_shut(world, gate)
	var words := Sixteen.words()
	_expect(words.size() == 1 and str(words[0].get("hero", "")) == first_id
		and Sixteen.same_cell(words[0].get("cell", []), [gate.cell.x, gate.cell.y])
		and str(words[0].get("word", "")) == str(left.get(first_id, "")),
		"%s's word at %s was not kept once: %s" % [first_name, gate.display_name, str(words)])

	# The first life ends, and the next lead shuts the same gate in its sibling.
	Sixteen.fall(first_id, { "hero": first_id, "name": first_name })
	_expect(Sixteen.words().size() == 1, "a lead falling lost the words carried")
	var next_id := "pluto" if first_id != "pluto" else "cato"
	lead.template_id = next_id
	lead.display_name = Crossing.name_of(next_id)
	GameState.flags = {}
	world.echoes["sibling"] = 1
	var heard_id := Crossing.on_gate_shut(world, gate)
	var heard: Array = Database.dialogue(heard_id).get("lines", [])
	_expect(heard_id == "carried_%s" % first_id, "the next life heard nothing at %s (%s)" % [gate.display_name, heard_id])
	_expect(heard.any(func(line: Dictionary) -> bool:
		return str(line["speaker"]) == first_name and str(line["text"]) == str(left.get(first_id, ""))),
		"%s's word did not carry: %s" % [first_name, str(heard)])
	_expect(heard.size() == (carried.get("voice", []) as Array).size(), "the carried word lost lines")
	_expect(heard.all(func(line: Dictionary) -> bool: return not str(line["text"]).contains("{")),
		"a carried line kept a blank: %s" % str(heard))
	_expect(str((world.annals.back() as Dictionary).get("text", "")).contains(str(left.get(first_id, "_"))),
		"the journal did not write down the word carried")
	_expect(Sixteen.words().size() == 2, "the next lead left no word of their own")

	# Elsewhere: the first gate of a life hears the lead who fell last; later gates nothing.
	var other := _site_where(func(s: Site) -> bool: return s.kind == Site.GATE and s.cell != gate.cell)
	if other != null:
		var fallen := Sixteen.fallen_heroes()
		var at_first := Crossing.carried(world, other, next_id, Sixteen.words(), fallen, true)
		_expect(str(at_first.get("hero", "")) == first_id and str(at_first.get("word", "")) == str(left.get(first_id, "")),
			"the first gate of the next life did not carry the fallen: %s" % str(at_first))
		_expect(Crossing.carried(world, other, next_id, Sixteen.words(), fallen, false).is_empty(),
			"a later gate carried a word nobody left there")
		var silent := Crossing.carried(world, other, next_id, [], ["caesar"], true)
		_expect(str(silent.get("word", "_")) == "" and str(silent.get("hero", "")) == "caesar",
			"a fallen lead with no word was not heard of: %s" % str(silent))
		var word_of: Array = Crossing.carried_scene(silent, other, lead.display_name).get("lines", [])
		_expect(not word_of.is_empty() and word_of.all(func(line: Dictionary) -> bool: return str(line["speaker"]) == ""),
			"word of a fallen lead had someone speaking: %s" % str(word_of))
	world.echoes["sibling"] = 0
	_expect(Crossing.carried(world, gate, next_id, Sixteen.words(), Sixteen.fallen_heroes(), true).is_empty(),
		"a world of its own heard a word from another")

	rules["chance"] = kept_chance
	world.echoes = kept_echoes
	GameState.flags = kept_flags
	lead.template_id = first_id
	lead.display_name = first_name
	_forget_sixteen()
	Sixteen.path = SIXTEEN_PATH
	print("word carried: the next life heard %s at %s: \"%s\"" % [first_name, gate.display_name, str(left.get(first_id, ""))])


func _forget_sixteen() -> void:
	if FileAccess.file_exists(Sixteen.path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Sixteen.path))


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


## The last climb asked for: a floor fought on the fight screen, or one walked on its own
## ground (D102).
func _last_climb_request() -> Dictionary:
	for i in range(_requests.size() - 1, -1, -1):
		var key: String = _requests[i]["key"]
		if key == "skirmish" or (key == "area" and int(_requests[i]["payload"].get("tower_floor", 0)) > 0):
			return _requests[i]
	return {}


func _last_battle_request() -> Dictionary:
	for i in range(_requests.size() - 1, -1, -1):
		if _requests[i]["key"] == "skirmish":
			return _requests[i]
	return {}


func _expect(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)
