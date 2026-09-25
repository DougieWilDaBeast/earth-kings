extends Node
## Headless smoke test for sending companions away on jobs — M16, [D38].
##
##   godot --headless --path . res://tests/dispatch_smoke_test.tscn
##
## Somebody sent on an errand leaves the company, walks it on the step clock,
## sees it done, and comes back — or meets something on the road alone.

const Dispatch := preload("res://src/chronicle/dispatch.gd")
const RumourJobs := preload("res://src/chronicle/rumour_jobs.gd")

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
	_check_rumour_jobs(world, roster)
	_finish()


## What the host passes on can post work: one job per rumour, never twice, and
## only on a bare board. Each is an ordinary errand a companion can be sent on.
func _check_rumour_jobs(world: World, roster: Roster) -> void:
	var villages := world.sites.filter(func(site: Site) -> bool: return site.kind == Site.VILLAGE)
	var home: Site = villages[0]
	var besieged: Site = villages[1]
	world.player_cell = home.cell
	home.data["errand"] = {}
	_expect(RumourJobs.post(world) == "" or not Errand.board(home).has("rumour"), "a job was posted from no news at all")
	home.data["errand"] = {}

	world.survivors.append({"unit": "goblin", "name": "Grisk the Unburied", "cell": [0, 0], "place": "the ford", "steps": 1, "encounters": 1})
	var gate: Site = world.sites_of_kind(Site.GATE)[0]
	gate.open = true
	gate.broken = true
	gate.cleared = false
	besieged.data["threatened_at"] = world.steps
	besieged.data["threatened_by"] = "the fen"

	var kinds: Dictionary = {}
	for i in 3:
		var line := RumourJobs.post(world)
		var job := Errand.board(home)
		_expect(line != "", "rumour %d posted nothing" % (i + 1))
		_expect(not line.contains("{") and not str(job.get("title", "")).contains("{"), "a rumour job was left with a blank in it: %s" % line)
		_expect(int(job.get("gold", 0)) > 0, "a rumour job pays nothing")
		_expect(not job.has("posted"), "the host's line was left on the errand")
		kinds[str(job.get("kind", ""))] = true
		# Somebody else posting on a board that is not bare is not a rumour's business.
		_expect(RumourJobs.post(world) == "", "a rumour job went on a board that already had one")
		if i == 0:
			print("  heard at the inn: %s — %s" % [job.get("title", ""), Errand.detail(job)])
		if job.get("kind", "") != Errand.BOUNTY:
			var sent := Errand.accept(home, GameState.errands, world)
			var companion: Character = roster.party_members()[1]
			_expect(Dispatch.send(world, roster, GameState.away, companion, sent) != "", "a companion could not be sent on a rumour job")
			GameState.away.clear()
			roster.party.append(companion.id)
			GameState.errands.erase(sent)
		home.data["errand"] = {}
	for kind: String in [Errand.BOUNTY, Errand.LOOK, Errand.DELIVER]:
		_expect(kinds.has(kind), "no rumour ever posted a %s job" % kind)
	_expect(RumourJobs.post(world) == "", "the same rumour posted twice")


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
