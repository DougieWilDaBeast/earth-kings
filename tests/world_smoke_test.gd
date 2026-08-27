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
