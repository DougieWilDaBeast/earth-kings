extends Node
## Headless check on the world model: generation, progression, generated power
## trees, doctrine, and a save/load round trip.
##
##   godot --headless --path . res://tests/world_smoke_test.tscn
##
## Runs as a scene rather than with `-s`, because `--script` runs before the
## autoloads (EventBus / Database / GameState) exist.

const SEED := 20260827

var _failures: Array[String] = []


func _ready() -> void:
	var world := WorldGen.generate(SEED)
	_report_world(world)
	_check_world(world)

	var hero := _grow_a_hero(world)
	_check_progression(hero, world)
	_check_doctrine(hero, world)
	_check_class_choice(world)
	_check_fate(world)
	_check_roster(world)
	_check_encounters(world)
	_check_walking(world)
	_check_round_trip(world, hero)

	print("")
	if _failures.is_empty():
		print("world smoke test: PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			print("FAIL: %s" % failure)
		get_tree().quit(1)


# --- world --------------------------------------------------------------------


func _report_world(world: World) -> void:
	print("world %d  %dx%d  start %s" % [world.world_seed, world.size.x, world.size.y, world.player_cell])
	var terrain_mix: Dictionary = {}
	for y in world.size.y:
		for x in world.size.x:
			var id := world.terrain_id_at(Vector2i(x, y))
			terrain_mix[id] = int(terrain_mix.get(id, 0)) + 1
	print("terrain %s" % terrain_mix)
	for site in world.sites:
		print("  %-8s %-14s %s" % [site.kind, site.label(), site.cell])


func _check_world(world: World) -> void:
	_expect(world.tiles.size() == world.size.y, "world has %d rows" % world.tiles.size())
	for row: String in world.tiles:
		if row.length() != world.size.x:
			_expect(false, "a row is %d wide, expected %d" % [row.length(), world.size.x])
			break
	_expect(world.tower() != null, "world has no Tower")
	_expect(world.is_walkable(world.player_cell), "player starts on unwalkable ground")

	var gates := world.sites_of_kind(Site.GATE)
	_expect(not gates.is_empty(), "world has no gates")
	var ranks: Array = []
	for gate in gates:
		_expect(gate.rank in Site.RANKS, "gate rank '%s' is not a rank" % gate.rank)
		_expect(world.is_walkable(gate.cell), "gate %s sits on unwalkable ground" % gate.display_name)
		if gate.rank not in ranks:
			ranks.append(gate.rank)
	# A world with no gentle gate is a world you cannot start playing.
	_expect("E" in ranks, "no E-rank gate — nowhere is survivable at level 1")
	_expect(ranks.size() >= 4, "gate ranks only span %d steps of the ladder" % ranks.size())

	var names: Array = []
	for site in world.sites:
		_expect(site.display_name not in names, "two places are both called %s" % site.display_name)
		names.append(site.display_name)

	var libraries := world.sites_of_kind(Site.LIBRARY)
	_expect(not libraries.is_empty(), "world has no libraries")
	_expect(
		libraries.any(func(s: Site) -> bool: return s.data.get("doctrine", "") == "the_open_palm"),
		"no library holds the first doctrine"
	)


# --- characters ---------------------------------------------------------------


func _grow_a_hero(world: World) -> Character:
	var hero := Character.create("bram", "", true)
	Progression.raise_to(hero, 12, world)
	print("")
	print("%s — level %d %s, hp %d, atk %d, def %d, spd %d" % [
		hero.display_name, hero.level, hero.class_name_text(),
		hero.max_hp(), hero.attack(), hero.defense(), hero.speed()
	])
	for tree_id: String in hero.trees:
		var tree := world.tree(tree_id)
		print("  tree %s (%s)" % [tree.get("display_name", tree_id), tree.get("theme", "?")])
	for ability_id: String in hero.abilities():
		var ability := Database.ability(ability_id)
		print("  - %-22s range %s-%s splash %s power %s" % [
			ability.get("display_name", ability_id),
			ability.get("min_range", 1), ability.get("range", 1),
			ability.get("splash", 0), ability.get("power", 1.0)
		])
	return hero


func _check_progression(hero: Character, world: World) -> void:
	_expect(hero.class_id != "", "level 12 character never took a class")
	_expect(hero.trees.size() == 2, "expected 2 trees by level 12, got %d" % hero.trees.size())
	_expect(not hero.learned.is_empty(), "character learned nothing from its trees")
	for ability_id: String in hero.abilities():
		_expect(not Database.ability(ability_id).is_empty(), "ability '%s' resolves to nothing" % ability_id)

	# The Yoke trades power for growth.
	var plain := hero.attack()
	hero.yoke = true
	_expect(hero.attack() < plain, "the Training Yoke did not reduce attack")
	hero.yoke = false

	_expect(world.codex_understanding() > 0.0, "codex catalogued nothing")


func _check_doctrine(hero: Character, world: World) -> void:
	var before := hero.attack()
	Doctrine.learn(hero, "keen_edge", world.steps)
	_expect(hero.attack() > before, "doctrine gave no bonus")

	var student := Character.create("sera")
	_expect(Doctrine.teach(hero, student, "keen_edge", world.steps), "teaching failed")
	_expect(student.knows("keen_edge"), "student did not retain the doctrine")
	_expect(not Doctrine.teach(hero, student, "keen_edge", world.steps), "taught the same thing twice")

	var forgotten := Doctrine.decay(student, world.steps + Doctrine.FADE_AFTER_STEPS)
	_expect("keen_edge" in forgotten, "unused doctrine never faded")
	_expect(not student.knows("keen_edge"), "forgotten doctrine is still known")


# --- fate ---------------------------------------------------------------------


func _check_class_choice(world: World) -> void:
	# A party member is asked; the world waits for the answer.
	var mine := Character.create("bram", "", true)
	Progression.award(mine, Progression.xp_to_next(1), world)
	_expect(mine.level == 2, "one level's worth of XP did not level anyone")
	_expect(mine.pending_class_choice, "a player character was not offered a class choice")
	_expect(mine.class_id == "", "a player character was assigned a class without asking")
	_expect(not Progression.settle_class(mine, "hedge_priest"), "accepted a class outside the options")
	_expect(Progression.settle_class(mine, "magic_swordsman"), "rejected a valid class choice")
	_expect(not mine.pending_class_choice, "the choice stayed pending after being made")

	# Anyone who is not the player settles into a class on their own.
	var theirs := Character.create("brigand")
	Progression.award(theirs, Progression.xp_to_next(1), world)
	_expect(theirs.class_id != "", "an NPC never settled into a class")
	_expect(not theirs.pending_class_choice, "an NPC is waiting on the player")


func _check_fate(world: World) -> void:
	print("")
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242

	# Alone, unarmed, unread, in the middle of nowhere: death is the default.
	var doomed := Character.create("sera")
	var graces := Fate.graces_for(doomed, {"enemy_kind": "beast"})
	var bare_odds := 0.0
	for grace: Dictionary in graces:
		bare_odds += float(grace["chance"])
	print("bare survival odds: %d%%" % roundi(bare_odds * 100.0))
	_expect(bare_odds < 0.2, "dying alone is too survivable at %d%%" % roundi(bare_odds * 100.0))

	var deaths := 0
	for i in 200:
		var victim := Character.create("sera")
		if Fate.resolve(victim, {"enemy_kind": "beast"}, rng)["outcome"] == Fate.DEAD:
			deaths += 1
	print("fell alone 200 times, died %d" % deaths)
	_expect(deaths > 150, "only %d of 200 lone deaths stuck" % deaths)

	# A charm is spent to buy one life, and is gone afterwards.
	var carried := Character.create("bram")
	carried.charms.append("grave_token")
	var saved_by_charm := 0
	for i in 200:
		var victim := Character.create("bram")
		victim.charms.append("grave_token")
		var outcome := Fate.resolve(victim, {"enemy_kind": "beast"}, rng)
		if outcome["reason"] == Fate.BY_CHARM:
			saved_by_charm += 1
			_expect(victim.charms.is_empty(), "the charm was not spent")
			_expect(victim.is_alive(), "the charm saved a corpse")
	print("grave token caught %d of 200" % saved_by_charm)
	_expect(saved_by_charm > 60, "the charm fired only %d times in 200" % saved_by_charm)

	# Raiders take prisoners; captives leave the party but not the world.
	var captures := 0
	for i in 200:
		var victim := Character.create("toln")
		var outcome := Fate.resolve(victim, {"enemy_kind": "raider", "world": world, "cell": world.player_cell}, rng)
		if outcome["outcome"] == Fate.CAPTURED:
			captures += 1
			_expect(victim.captured_at != "", "a captive is being held nowhere")
			_expect(not victim.is_alive() and victim.is_lost(), "a captive is still in the party")
	print("taken alive by raiders %d of 200" % captures)
	_expect(captures > 30, "raiders captured only %d in 200" % captures)

	# Standing allies and read books both buy real odds.
	var alone := Character.create("bram")
	var lone_odds := _total_odds(alone, {"enemy_kind": "beast"})
	var helped := Character.create("bram")
	var friends: Array = [Character.create("sera"), Character.create("toln")]
	var helped_odds := _total_odds(helped, {"enemy_kind": "beast", "allies": friends})
	_expect(helped_odds > lone_odds, "allies did not improve the odds")

	var read := Character.create("bram")
	Doctrine.learn(read, "the_vigil", 0)
	_expect(_total_odds(read, {"enemy_kind": "beast"}) > lone_odds, "doctrine did not improve the odds")
	print("odds alone %d%%, with two allies %d%%, having read one book %d%%" % [
		roundi(lone_odds * 100.0), roundi(helped_odds * 100.0),
		roundi(_total_odds(read, {"enemy_kind": "beast"}) * 100.0)
	])


func _total_odds(character: Character, context: Dictionary) -> float:
	var total := 0.0
	for grace: Dictionary in Fate.graces_for(character, context):
		total += float(grace["chance"])
	return total


# --- persistence --------------------------------------------------------------


func _check_roster(world: World) -> void:
	var roster := Roster.found()
	_expect(roster.characters.size() == Roster.FOUNDING.size(), "founding roster is the wrong size")
	_expect(roster.party.size() == Roster.FOUNDING.size(), "not everyone founding is marching")
	_expect(roster.player() != null and roster.player().is_player, "nobody on the roster is the player")
	_expect(roster.fit_to_fight().size() == 3, "the founding party cannot fight")
	_expect(not roster.is_broken(), "a fresh roster is already broken")

	# The dead and the taken come off the marching order but stay on the books.
	var fallen: Character = roster.party_members()[1]
	fallen.status = Fate.DEAD
	var taken: Character = roster.party_members()[2]
	taken.status = Fate.CAPTURED
	taken.captured_at = "Hollowbarrow"

	var lost := roster.drop_the_lost()
	_expect(lost.size() == 2, "lost %d characters, expected 2" % lost.size())
	_expect(roster.party.size() == 1, "the party did not shrink")
	_expect(roster.characters.size() == 3, "a lost character was deleted instead of remembered")
	_expect(roster.by_id(taken.id) != null, "the captive is gone from the world entirely")
	_expect(not roster.is_broken(), "one survivor should still be a run")

	roster.party_members()[0].status = Fate.DEAD
	roster.drop_the_lost()
	_expect(roster.is_broken(), "losing everyone did not end the run")


# --- encounters ---------------------------------------------------------------


func _check_encounters(world: World) -> void:
	print("")
	var party := Roster.found().party_members()

	# Danger is a property of place: loud near an open gate, quiet by a hearth.
	var open_gates := world.sites_of_kind(Site.GATE).filter(func(s: Site) -> bool: return s.open)
	_expect(not open_gates.is_empty(), "no gate is open, so nothing is dangerous")
	if not open_gates.is_empty():
		var at_gate := Encounter.chance_at(world, open_gates[0].cell)
		var at_home := Encounter.chance_at(world, world.player_cell)
		print("danger at an open gate %d%%, at the starting village %d%%" % [
			roundi(at_gate * 100.0), roundi(at_home * 100.0)
		])
		_expect(at_gate > at_home, "standing in a gate's mouth is no worse than standing at home")
		_expect(at_gate <= 0.45, "encounter chance %f is out of bounds" % at_gate)

	_check_field(Encounter.wild(world, world.player_cell, party, world.rng), "wild")

	var gate: Site = world.sites_of_kind(Site.GATE)[0]
	var delve := Encounter.for_gate(world, gate, 0, true, party, world.rng)
	_check_field(delve, "gate")
	_expect(delve["enemies"].size() >= 3, "a guarded gate fielded only %d" % delve["enemies"].size())

	var climb := Encounter.for_tower(world, world.tower(), 6, party, world.rng)
	_check_field(climb, "tower")
	var shallow := Encounter.for_tower(world, world.tower(), 1, party, world.rng)
	_expect(
		_top_level(climb) > _top_level(shallow),
		"the Tower is no harder at floor 6 than at floor 1"
	)
	print("tower floor 1 fields level %d, floor 6 fields level %d" % [_top_level(shallow), _top_level(climb)])


## Every generated battlefield has to be one a fight can actually happen on.
func _check_field(meeting: Dictionary, label: String) -> void:
	var map: Dictionary = meeting.get("map", {})
	var rows: Array = map.get("tiles", [])
	_expect(not rows.is_empty(), "%s encounter generated no ground" % label)
	_expect(rows.size() == BattleMapGen.SIZE.y, "%s field is %d rows" % [label, rows.size()])
	for row: String in rows:
		if row.length() != BattleMapGen.SIZE.x:
			_expect(false, "%s field has a ragged row" % label)
			break

	_expect(not meeting["enemies"].is_empty(), "%s encounter has nobody in it" % label)
	_expect(
		map["player_spawns"].size() >= Roster.FOUNDING.size(),
		"%s field has room for only %d of the party" % [label, map["player_spawns"].size()]
	)

	var legend: Dictionary = map["legend"]
	for spawn: Array in map["player_spawns"]:
		_expect(_walkable(rows, legend, spawn), "%s field spawns the party in a wall" % label)
	for entry: Dictionary in map["enemies"]:
		_expect(entry.has("cell"), "%s encounter left an enemy unplaced" % label)
		_expect(int(entry.get("level", 0)) > 0, "%s encounter fielded a level-zero foe" % label)
		_expect(_walkable(rows, legend, entry["cell"]), "%s field spawns a foe in a wall" % label)


func _walkable(rows: Array, legend: Dictionary, cell: Array) -> bool:
	var symbol: String = rows[int(cell[1])][int(cell[0])]
	return Database.terrain_type(legend.get(symbol, "grass")).get("walkable", true)


func _top_level(meeting: Dictionary) -> int:
	var best := 0
	for entry: Dictionary in meeting["enemies"]:
		best = maxi(best, int(entry.get("level", 0)))
	return best


## Walk a long way and make sure the loop survives it.
func _check_walking(world: World) -> void:
	print("")
	var party := Roster.found().party_members()
	var walker := world.player_cell
	var fights := 0
	var notices := 0
	var steps := 800

	for i in steps:
		var options: Array[Vector2i] = []
		for offset: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if world.is_walkable(walker + offset):
				options.append(walker + offset)
		_expect(not options.is_empty(), "walked into a dead end at %s" % walker)
		if options.is_empty():
			break

		walker = options[world.rng.randi() % options.size()]
		world.player_cell = walker
		notices += world.step().size()
		if not Encounter.roll(world, walker, party, world.rng).is_empty():
			fights += 1

	_expect(world.steps >= steps, "the clock did not keep up with the walking")
	_expect(fights > 0, "walked %d steps without meeting anything" % steps)
	_expect(fights < steps / 2, "met something on %d of %d steps" % [fights, steps])
	print("walked %d steps: %d encounters, %d world notices" % [steps, fights, notices])

	var open_now := world.sites_of_kind(Site.GATE).filter(func(s: Site) -> bool: return s.open).size()
	print("gates open after the walk: %d" % open_now)


# --- persistence --------------------------------------------------------------

func _check_round_trip(world: World, hero: Character) -> void:
	var payload: Dictionary = JSON.parse_string(JSON.stringify(world.to_dict()))
	var restored := World.from_dict(payload)
	_expect(restored.world_seed == world.world_seed, "seed lost in the round trip")
	_expect(restored.sites.size() == world.sites.size(), "sites lost in the round trip")
	_expect(restored.tiles == world.tiles, "ground changed in the round trip")
	_expect(restored.trees.size() == world.trees.size(), "generated trees lost in the round trip")

	var hero_payload: Dictionary = JSON.parse_string(JSON.stringify(hero.to_dict()))
	var hero_again := Character.from_dict(hero_payload)
	_expect(hero_again.level == hero.level, "character level lost in the round trip")
	_expect(hero_again.abilities() == hero.abilities(), "character abilities lost in the round trip")
	for ability_id: String in hero_again.abilities():
		_expect(
			not Database.ability(ability_id).is_empty(),
			"generated ability '%s' did not survive the round trip" % ability_id
		)


func _expect(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)
