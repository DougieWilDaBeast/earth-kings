extends Node
## Headless smoke test for regional names and earned titles — [D39].
##
##   godot --headless --path . res://tests/names_smoke_test.tscn

const Names := preload("res://src/chronicle/names.gd")

var _failures: Array[String] = []


func _ready() -> void:
	GameState.new_game(9)
	var world: World = GameState.world
	var rng := RandomNumberGenerator.new()
	rng.seed = 9

	# The data: every strong name has somewhere to shorten to.
	var strong: Dictionary = Database.names.get("strong", {})
	_expect(strong.size() >= 20, "fewer than twenty names to draw from")
	for full: String in strong:
		_expect(not (strong[full] as Array).is_empty(), "%s has no stems" % full)

	# Near a keep, mostly the strong form; far from any, mostly stems.
	var keeps := world.sites_of_kind(Site.KEEP)
	_expect(not keeps.is_empty(), "no keeps to be noble near")
	if not keeps.is_empty():
		var near := _share_strong(world, keeps[0].cell, rng)
		var far_cell := _farthest_from_keeps(world)
		var far := _share_strong(world, far_cell, rng)
		print("strong names: %d%% beside a keep, %d%% %d tiles from one" % [
			roundi(near * 100.0), roundi(far * 100.0), _keep_distance(world, far_cell),
		])
		_expect(near > 0.6, "only %d%% strong names beside a keep" % roundi(near * 100.0))
		_expect(far < near, "names far from a keep were no plainer than beside one")

	# Everyone is of somewhere real.
	var places: Array[String] = []
	for site in world.sites:
		places.append(site.display_name)
	for i in 20:
		var name := Names.person(world, world.player_cell, rng)
		var parts := name.split(" of ")
		_expect(parts.size() == 2 and places.has(parts[1]), "%s is not of anywhere on the map" % name)
		if i < 3:
			print("  %s" % name)

	# Titles come from deeds, biggest first.
	var lead := GameState.roster.player().display_name
	_expect(Names.earned_title(world) == "", "a title before doing anything")
	_expect(Names.known_as(world, lead) == lead, "known as something before doing anything")
	world.journal["goblin"] = {"felled": Names.HUNTER_AT}
	_expect(Names.earned_title(world) == "Goblin Hunter", "no hunter's title after %d goblins: '%s'" % [
		Names.HUNTER_AT, Names.earned_title(world)
	])
	_expect(Names.known_as(world, lead) == "Goblin Hunter %s" % lead, "hunter's title in the wrong place")
	Renown.record(world, Renown.GATE_SHUT, world.player_cell, 3, "shut a gate")
	_expect(Names.earned_title(world) == "Gate-Shutter", "a shut gate did not outrank the goblins")
	_expect(Names.known_as(world, lead) == "%s the Gate-Shutter" % lead, "'the' title in the wrong place")
	Renown.record(world, Renown.TOWER_TOPPED, world.player_cell, 8, "topped the Tower")
	_expect(Names.earned_title(world) == "Spire-Climber", "topping the Tower did not outrank everything")
	print("  known as: %s" % Names.known_as(world, lead))

	_finish()


func _share_strong(world: World, cell: Vector2i, rng: RandomNumberGenerator) -> float:
	var strong: Dictionary = Database.names.get("strong", {})
	var count := 0
	for i in 400:
		var given := Names.person(world, cell, rng).split(" of ")[0]
		if strong.has(given):
			count += 1
	return float(count) / 400.0


func _farthest_from_keeps(world: World) -> Vector2i:
	var best := Vector2i.ZERO
	var best_distance := -1
	for y in range(0, world.size.y, 8):
		for x in range(0, world.size.x, 8):
			var cell := Vector2i(x, y)
			var d := _keep_distance(world, cell)
			if d > best_distance:
				best_distance = d
				best = cell
	return best


func _keep_distance(world: World, cell: Vector2i) -> int:
	var best := 9999
	for keep in world.sites_of_kind(Site.KEEP):
		best = mini(best, Pathfinder.distance(cell, keep.cell))
	return best


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("names smoke test: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		print("FAIL  %s" % failure)
	print("names smoke test: FAIL")
	get_tree().quit(1)
