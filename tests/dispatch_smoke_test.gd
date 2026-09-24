extends Node
## Headless smoke test for sending companions away on jobs — M16, [D38].
##
##   godot --headless --path . res://tests/dispatch_smoke_test.tscn
##
## Somebody sent on an errand leaves the company, walks it on the step clock,
## sees it done, and comes back — or meets something on the road alone.

const Dispatch := preload("res://src/chronicle/dispatch.gd")

var _failures: Array[String] = []


func _ready() -> void:
	GameState.new_game(5)
	var world: World = GameState.world
	var roster: Roster = GameState.roster
	var rules: Dictionary = Database.world_rules["dispatch"]
	var kept := rules.duplicate()
	var lead := roster.player()
	var sera: Character = roster.party_members()[1]

	_expect(not Dispatch.can_send(lead, roster, GameState.away), "the lead could be sent away")
	_expect(Dispatch.can_send(sera, roster, GameState.away), "a companion on her feet could not be sent")

	# A quiet road: nothing is met, the errand is done, and she comes home.
	rules["trouble_min"] = 0.0
	rules["trouble_max"] = 0.0
	var look := _errand("look", world.player_cell + Vector2i(6, 0))
	GameState.errands.append(look)
	var party_before := roster.party.size()
	var line := Dispatch.send(world, roster, GameState.away, sera, look)
	print(line)
	_expect(line != "", "sending her failed")
	_expect(roster.party.size() == party_before - 1, "she did not leave the marching order")
	_expect(not Dispatch.can_send(sera, roster, GameState.away), "she could be sent twice")
	_expect(Dispatch.open_errands(GameState.errands).is_empty(), "the errand was still open after it was taken")

	var job: Dictionary = GameState.away[0]
	var gold := GameState.gold
	world.steps = int(job["out_at"]) - 1
	_expect(_walk().is_empty(), "something happened before she got there")
	world.steps = int(job["out_at"])
	_walk()
	_expect(GameState.gold > gold, "a look errand was not paid when she reached the place")
	_expect(not GameState.errands.has(look), "the settled errand stayed on the list")
	world.steps = int(job["back_at"])
	_walk()
	_expect(GameState.away.is_empty(), "she never came home")
	_expect(roster.party.has(sera.id), "she came home but did not rejoin")

	# A hunt, won: the cull is done and paid when she is back.
	rules["win_base"] = 1.0
	var cull := _errand("cull", Vector2i(-1, -1))
	cull["target"] = "wolf"
	cull["count"] = 3
	cull["from"] = [world.player_cell.x, world.player_cell.y]
	GameState.errands.append(cull)
	Dispatch.send(world, roster, GameState.away, sera, cull)
	job = GameState.away[0]
	world.steps = int(job["out_at"])
	_walk()
	_expect(Errand.is_complete(cull), "a won hunt did not count its kills")
	_expect(Progression.has_beaten(sera, "wolf") or sera.beaten.has("wolf"), "she learned nothing from the hunt")
	world.steps = int(job["back_at"])
	gold = GameState.gold
	_walk()
	_expect(GameState.gold > gold, "the hunt was not paid on her return")

	# A hunt, lost: it goes the way any fall goes, and nothing is left dangling.
	rules["win_base"] = 0.0
	rules["win_per_level"] = 0.0
	var second := _errand("cull", Vector2i(-1, -1))
	second["target"] = "wolf"
	second["count"] = 2
	second["from"] = [world.player_cell.x, world.player_cell.y]
	GameState.errands.append(second)
	Dispatch.send(world, roster, GameState.away, sera, second)
	job = GameState.away[0]
	world.steps = int(job["out_at"])
	print("  " + " / ".join(_walk()))
	if sera.is_alive():
		_expect(GameState.away.size() == 1, "she survived the fall but lost her job")
	else:
		_expect(GameState.away.is_empty(), "the job outlived her")
		_expect(str(second.get(Dispatch.TAKEN_BY, "")) == "", "the errand still names someone who is gone")
	print("  lost a fight alone: %s" % sera.status)

	# Default odds, many times over, to see what sending people away costs.
	for key: String in kept:
		rules[key] = kept[key]
	var soaked_back := 0
	var soaked_dead := 0
	for setting: String in ["gentle", "even"]:
		GameState.difficulty = setting
		var result := _soak(world)
		soaked_back += int(result["back"])
		soaked_dead += int(result["dead"])
	GameState.difficulty = Difficulty.DEFAULT
	_expect(soaked_back > soaked_dead, "sending someone away is more likely to kill them than not")
	_finish()


## Two hundred trips to the mouth of an open gate — the worst road there is.
func _soak(world: World) -> Dictionary:
	var outcomes := {"back": 0, "captured": 0, "dead": 0}
	var gates: Array[Site] = world.sites_of_kind(Site.GATE).filter(func(s: Site) -> bool: return s.open)
	for i in 200:
		var roster := Roster.found()
		var sent: Character = roster.party_members()[1]
		var errands: Array = []
		var away: Array = []
		var to: Vector2i = gates[i % gates.size()].cell if not gates.is_empty() else world.player_cell + Vector2i(8, 0)
		var far := _errand("fetch", to)
		errands.append(far)
		Dispatch.send(world, roster, away, sent, far)
		if away.is_empty():
			continue
		var job: Dictionary = away[0]
		var start := world.steps
		world.steps = int(job["back_at"])
		Dispatch.walk(world, roster, away, errands)
		world.steps = start
		match sent.status:
			Fate.ALIVE:
				outcomes["back"] += 1
			Fate.CAPTURED:
				outcomes["captured"] += 1
			_:
				outcomes["dead"] += 1
	print("soak, 200 trips to open gates on %s: %d back, %d taken, %d dead" % [
		Difficulty.current(), outcomes["back"], outcomes["captured"], outcomes["dead"],
	])
	return outcomes


func _errand(kind: String, to: Vector2i) -> Dictionary:
	var errand := {
		"kind": kind, "title": "A test %s" % kind, "giver": "Someone",
		"from": [GameState.world.player_cell.x, GameState.world.player_cell.y], "from_name": "Home",
		"gold": 50, "done": 0, "reached": false,
	}
	if to != Vector2i(-1, -1):
		errand["to"] = [to.x, to.y]
		errand["to_name"] = "Testing Ford"
	return errand


func _walk() -> Array[String]:
	var lines := Dispatch.walk(GameState.world, GameState.roster, GameState.away, GameState.errands)
	for line in lines:
		print("  " + line)
	return lines


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("dispatch smoke test: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		print("FAIL  %s" % failure)
	print("dispatch smoke test: FAIL")
	get_tree().quit(1)
