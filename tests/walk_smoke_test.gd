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
	_check_watchers()
	_check_banter()
	_check_rest()
	_check_home()
	_check_library()
	_check_gate()
	_check_tower()
	_check_class_prompt()
	_check_gate_lifecycle()
	_check_town_and_captives()
	_check_loot()
	_check_renown()
	_check_raid_and_rescue()
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
	var gate := _site_where(func(s: Site) -> bool: return s.kind == Site.GATE and s.open)
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

	var fight := _last_battle_request()
	_expect(not fight.is_empty(), "walking into an open gate started no fight")
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

	if not _step_onto(gate.cell):
		return
	_scene._settle_up(true)
	_expect(not gate.open, "the gate is still open after being cleared")
	_expect(gate.cleared, "the gate was not marked cleared")
	_expect(GameState.gold > gold_before, "clearing a %s-rank gate paid nothing" % gate.rank)
	print("gate: %s walked out of once, then shut for %d gold" % [gate.label(), GameState.gold - gold_before])


func _check_tower() -> void:
	var world: World = GameState.world
	var tower := world.tower()
	_expect(world.tower_floor == 0, "the Tower had already been climbed")

	_requests.clear()
	if not _step_onto(tower.cell):
		return
	_expect(world.tower_floor == 0, "the floor log advanced before the fight was fought")

	var fight := _last_battle_request()
	_expect(not fight.is_empty(), "the Tower started no fight")
	if not fight.is_empty():
		_expect(fight["payload"]["encounter"]["kind"] == Encounter.TOWER, "the Tower fought the wrong thing")

	_scene._settle_up(true)
	_expect(world.tower_floor == 1, "climbing did not advance the floor log")
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

	# Buying: gold is the standard of trade.
	var goods := Market.wares(town)
	if not goods.is_empty():
		var equipment_id: String = goods[0]
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


## Chests and caches: gold always lands, and gear finds a wearer or a buyer.
func _check_loot() -> void:
	var world: World = GameState.world
	var taker: Character = GameState.roster.party_members()[0]
	taker.equipment = ""

	var purse := GameState.gold
	var lines := Loot.claim({ "gold": 90, "item": "bone_sword" }, GameState.roster)
	_expect(GameState.gold >= purse + 90, "the gold in the chest never arrived")
	_expect(lines.size() == 2, "a chest with gold and gear reported %d lines" % lines.size())
	var worn := GameState.roster.party_members().any(
		func(c: Character) -> bool: return c.equipment == "bone_sword"
	)
	_expect(worn, "nobody picked up the sword out of the chest")

	# Once everyone is already carrying one, another improves nobody, so it is
	# sold on the spot rather than shelved somewhere nobody will look.
	for member: Character in GameState.roster.party_members():
		member.equipment = "bone_sword"
	purse = GameState.gold
	Loot.claim({ "gold": 0, "item": "bone_sword" }, GameState.roster)
	_expect(GameState.gold > purse, "a piece nobody wanted was neither worn nor sold")

	# A charm is carried, never worn, so it always has a taker.
	var charms := GameState.roster.player().charms.size()
	Loot.claim({ "gold": 0, "item": "grave_token" }, GameState.roster)
	_expect(GameState.roster.player().charms.size() == charms + 1, "the charm went nowhere")

	var haul := Loot.roll(world, 1.0)
	_expect(int(haul.get("gold", 0)) > 0, "a rolled cache held no gold at all")
	print("loot: sword worn, spare sold, charm pocketed, cache rolled %d gold" % int(haul["gold"]))


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
	_expect(Renown.greeting(world, away, "Bram") == "", "somewhere that has not heard still greeted us")

	world.steps += Renown.steps_per_tile() * 20
	_expect(Renown.standing(world, away) == 4, "word never travelled at all")
	_expect(Renown.title(world, away) != "a stranger", "word arrived and nobody drew a conclusion")
	_expect(Renown.greeting(world, away, "Bram") != "", "a place that knows us said nothing")

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
		"deeds": world.deeds.size(),
		"ruined": world.sites.filter(func(s: Site) -> bool: return Town.is_ruined(s)).size(),
		"bond": Banter.bond(GameState.roster.party_members()[0], GameState.roster.party_members()[1]),
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
