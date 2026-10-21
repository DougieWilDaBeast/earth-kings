extends Node
## Headless smoke test for sending companions away on jobs — M16, [D38].
##
##   godot --headless --path . res://tests/dispatch_smoke_test.tscn
##
## Somebody sent on an errand leaves the company, walks it on the step clock,
## sees it done, and comes back — or meets something on the road alone.

const Dispatch := preload("res://src/chronicle/dispatch.gd")
const RumourJobs := preload("res://src/chronicle/rumour_jobs.gd")
const Guild := preload("res://src/chronicle/guild.gd")
const Company := preload("res://tests/company.gd")
const Atlas := preload("res://src/chronicle/atlas.gd")
const Moods := preload("res://src/chronicle/moods.gd")
const QuickWheel := preload("res://src/ui/quick_wheel.gd")

var _failures: Array[String] = []


func _ready() -> void:
	GameState.new_game(5)
	var world: World = GameState.world
	var roster: Roster = Company.join(GameState.roster)
	var rules: Dictionary = Database.world_rules["dispatch"]
	var kept := rules.duplicate()
	var lead := roster.player()
	var juno: Character = roster.party_members()[1]

	_expect(not Dispatch.can_send(lead, roster, GameState.away), "the lead could be sent away")
	_expect(Dispatch.can_send(juno, roster, GameState.away), "a companion on her feet could not be sent")

	# A quiet road: nothing is met, the errand is done, and she comes home.
	rules["trouble_min"] = 0.0
	rules["trouble_max"] = 0.0
	var look := _errand("look", world.player_cell + Vector2i(6, 0))
	GameState.errands.append(look)
	var party_before := roster.party.size()
	var line := Dispatch.send(world, roster, GameState.away, juno, look)
	print(line)
	_expect(line != "", "sending her failed")
	_expect(roster.party.size() == party_before - 1, "she did not leave the marching order")
	_expect(not Dispatch.can_send(juno, roster, GameState.away), "she could be sent twice")
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
	_expect(roster.party.has(juno.id), "she came home but did not rejoin")

	# A hunt, won: the cull is done and paid when she is back.
	rules["win_base"] = 1.0
	var cull := _errand("cull", Vector2i(-1, -1))
	cull["target"] = "wolf"
	cull["count"] = 3
	cull["from"] = [world.player_cell.x, world.player_cell.y]
	GameState.errands.append(cull)
	Dispatch.send(world, roster, GameState.away, juno, cull)
	job = GameState.away[0]
	world.steps = int(job["out_at"])
	_walk()
	_expect(Errand.is_complete(cull), "a won hunt did not count its kills")
	_expect(Progression.has_beaten(juno, "wolf") or juno.beaten.has("wolf"), "she learned nothing from the hunt")
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
	Dispatch.send(world, roster, GameState.away, juno, second)
	job = GameState.away[0]
	world.steps = int(job["out_at"])
	print("  " + " / ".join(_walk()))
	if juno.is_alive():
		_expect(GameState.away.size() == 1, "she survived the fall but lost her job")
	else:
		_expect(GameState.away.is_empty(), "the job outlived her")
		_expect(str(second.get(Dispatch.TAKEN_BY, "")) == "", "the errand still names someone who is gone")
	print("  lost a fight alone: %s" % juno.status)

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
	_check_muster(world)
	_check_gate_band(world)
	_check_moods(world)
	_check_rumour_jobs(world, roster)
	_check_play_test_eight(world, roster)
	_finish()


## Somebody sent to stand with a Guild muster waits with it until it goes in,
## and comes back with what happened — or does not come back (M16, D38).
func _check_muster(world: World) -> void:
	var terms: Dictionary = Database.guild["muster"]
	var kept_terms := terms.duplicate()
	var quiet: Dictionary = Database.world_rules["dispatch"]
	var kept_quiet := quiet.duplicate()
	quiet["trouble_min"] = 0.0
	quiet["trouble_max"] = 0.0
	var gate: Site = world.sites_of_kind(Site.GATE)[1]
	var kept_gate := gate.to_dict()
	var kept_musters := world.musters.duplicate(true)

	for won: bool in [true, false]:
		gate.rank = "S"
		gate.open = true
		gate.broken = false
		gate.cleared = false
		world.musters.clear()
		terms["win_base"] = 2.0 if won else -2.0
		var roster := Company.found()
		var sent: Character = roster.party_members()[1]
		var errands: Array = []
		var away: Array = []
		Guild.upkeep(world, errands)
		var muster := Guild.muster_at(world, gate.cell)
		_expect(not muster.is_empty(), "an open S-rank gate raised no muster")
		if muster.is_empty():
			break
		Guild.join(world, muster, errands)
		var standing: Dictionary = errands[0]
		_expect(Dispatch.send(world, roster, away, sent, standing) != "", "nobody could be sent to stand with a muster")
		var job: Dictionary = away[0]
		world.steps = int(job["back_at"])
		Dispatch.walk(world, roster, away, errands)
		_expect(away.size() == 1, "she came home before the muster went in")
		muster["strength"] = int(muster["needed"])
		muster["waited"] = int(terms.get("wait_upkeeps", 4))
		var said := Guild.upkeep(world, errands)
		_expect(Guild.muster_at(world, gate.cell).is_empty(), "a ready muster nobody stood with in person never went in")
		_expect(gate.cleared == won and gate.broken != won, "the muster went in and the gate was left %s" % ("open" if not gate.cleared else "shut"))
		var gold := GameState.gold
		var lines := Dispatch.walk(world, roster, away, errands)
		print("  muster %s: %s / %s" % ["won" if won else "lost", " ".join(said), " / ".join(lines)])
		_expect(not errands.has(standing), "the muster errand outlived the muster")
		if won:
			_expect(away.is_empty() and roster.party.has(sent.id), "she did not come home from a won muster")
			_expect(GameState.gold > gold, "standing with a won muster paid nothing")
		else:
			_expect(away.is_empty(), "the job outlived a lost muster")

	for key: String in kept_terms:
		terms[key] = kept_terms[key]
	for key: String in kept_quiet:
		quiet[key] = kept_quiet[key]
	var restored := Site.from_dict(kept_gate)
	gate.rank = restored.rank
	gate.open = restored.open
	gate.broken = restored.broken
	gate.cleared = restored.cleared
	world.musters = kept_musters


## A band of the company's own sent to shut a gate ([D278]): closed until a gate has been shut,
## two sent to the same gate go together, and they come back having shut it, or not all of them do.
func _check_gate_band(world: World) -> void:
	var gates: Array[Site] = world.sites_of_kind(Site.GATE)
	var kept := gates.map(func(g: Site) -> Dictionary: return g.to_dict())
	var kept_rng := world.rng.state
	for g: Site in gates:
		g.cleared = false
		g.open = true
	_expect(not Dispatch.unlocked(world), "sending people out was open before any gate was shut")
	gates[0].cleared = true
	gates[0].open = false
	_expect(Dispatch.unlocked(world), "shutting a gate did not open sending people out")
	var gate: Site = gates[1]
	Atlas.mark(world, gate)
	_expect(Dispatch.open_gates(world).has(gate), "a known open gate could not be sent to")
	_expect(not Dispatch.open_gates(world).has(gates[0]), "a shut gate could be sent to")

	for won: bool in [true, false]:
		gate.rank = "E"
		gate.open = true
		gate.cleared = false
		var roster := Company.found()
		var lead := roster.player()
		var first: Character = roster.party_members()[1]
		var second: Character = roster.party_members()[2]
		var away: Array = []
		var errands: Array = []
		var alone := Dispatch.gate_chance([first], gate)
		_expect(Dispatch.send_to_gate(world, roster, away, first, gate) != "", "nobody could be sent to a gate")
		_expect(Dispatch.send_to_gate(world, roster, away, second, gate) != "", "a second could not follow the first")
		_expect(away.size() == 1 and (away[0]["band"] as Array).size() == 2, "two sent to one gate did not go together")
		_expect(Dispatch.gate_chance([first, second], gate) > alone, "a second pair of hands did not help")
		_expect(roster.party_members() == [lead], "the band did not leave the marching order")
		var rules: Dictionary = Database.world_rules["dispatch"]
		var kept_rules := rules.duplicate()
		rules["gate_min"] = 1.0 if won else 0.0
		rules["gate_max"] = 1.0 if won else 0.0
		world.steps = int(away[0]["out_at"])
		var lines := Dispatch.walk(world, roster, away, errands)
		print("  gate band %s: %s" % ["won" if won else "lost", " / ".join(lines)])
		_expect(gate.cleared == won, "a band that %s left the gate %s" % ["won" if won else "lost", "shut" if gate.cleared else "open"])
		if not away.is_empty():
			world.steps = int(away[0]["back_at"])
			Dispatch.walk(world, roster, away, errands)
		_expect(away.is_empty(), "the band never came home")
		if won:
			_expect(roster.party.has(first.id) and roster.party.has(second.id), "a band that shut its gate did not come back")
		for key: String in kept_rules:
			rules[key] = kept_rules[key]

	# Sent with a town to meet in ([D294], [D300]): back there, a crow says so if the company is
	# elsewhere, they wait, and they fall in when it comes.
	var places := Dispatch.meeting_places(world)
	var town: Site = null
	for site: Site in world.sites:
		if site.kind == Site.VILLAGE:
			town = site
			break
	if town != null:
		Atlas.mark(world, town)
		places = Dispatch.meeting_places(world)
	_expect(town != null and places.has(town), "a known village is no place to meet")
	if town != null:
		gate.rank = "E"
		gate.open = true
		gate.cleared = false
		var roster := Company.found()
		var lead := roster.player()
		var first: Character = roster.party_members()[1]
		var away: Array = []
		var rules: Dictionary = Database.world_rules["dispatch"]
		var kept_rules := rules.duplicate()
		rules["gate_min"] = 1.0
		rules["gate_max"] = 1.0
		var kept_cell := world.player_cell
		var said := Dispatch.send_to_gate(world, roster, away, first, gate, town)
		_expect(said.contains(town.display_name), "the band was not told where to meet: %s" % said)
		world.steps = int(away[0]["out_at"])
		Dispatch.walk(world, roster, away, [])
		_expect(Dispatch.where_now(away[0], world) == gate.cell, "the band was not drawn at its gate")
		world.player_cell = gate.cell if gate.cell != town.cell else town.cell + Vector2i.RIGHT
		world.steps = int(away[0]["back_at"])
		var crow := Dispatch.walk(world, roster, away, [])
		print("  met at %s: %s" % [town.display_name, " / ".join(crow)])
		_expect(crow.any(func(l: String) -> bool: return l.contains("crow")) and away.size() == 1, "nobody brought word the band was back")
		_expect(Dispatch.where_now(away[0], world) == town.cell, "a band waiting was not drawn where it waits")
		_expect(not roster.party.has(first.id), "a band waiting at a town fell in from afar")
		world.player_cell = town.cell
		world.steps += 1
		Dispatch.walk(world, roster, away, [])
		_expect(away.is_empty() and roster.party.has(first.id), "the band did not fall in when the company reached the town")
		_expect(roster.party_members()[0] == lead, "the lead lost the front")
		world.player_cell = kept_cell
		for key: String in kept_rules:
			rules[key] = kept_rules[key]
	for i in gates.size():
		var restored := Site.from_dict(kept[i])
		gates[i].rank = restored.rank
		gates[i].open = restored.open
		gates[i].broken = restored.broken
		gates[i].cleared = restored.cleared
	world.rng.state = kept_rng


## How each of them feels ([D279]): a fight won, a floor climbed and a friend lost become thoughts,
## the mood they make nudges a fight, it saves, and at the end of their rope one of them sits out.
func _check_moods(world: World) -> void:
	var roster := Company.found()
	var flags := {}
	var ledger := Ledger.fresh()
	var away: Array = []
	var kept_floor := world.tower_floor
	var kept_steps := world.steps
	var one: Character = roster.party_members()[1]
	var two: Character = roster.party_members()[2]
	var calm := one.attack()
	Moods.tick(world, roster, away, flags, ledger)
	_expect(one.thoughts.is_empty() and one.mood() == int(Moods.rules().get("base", 50)), "a mood began with something on its mind")
	ledger["battles_won"] = 1
	world.tower_floor += 1
	Moods.tick(world, roster, away, flags, ledger)
	var ids: Array = one.thoughts.map(func(t: Dictionary) -> String: return str(t["id"]))
	_expect(ids.has("won_fight") and ids.has("climbed"), "a fight won and a floor climbed went unnoticed: %s" % str(ids))
	var climbed: Dictionary = Moods.rules()["thoughts"]["climbed"]
	var worth := int(climbed.get("by_group", {}).get(Moods.group(one), climbed.get("mood", 0)))
	var held: Array = one.thoughts.filter(func(t: Dictionary) -> bool: return t["id"] == "climbed")
	_expect(int(held[0]["mood"]) == worth, "%s's temper did not decide how climbing felt" % one.display_name)
	one.bonds[two.id] = 5
	two.status = Fate.DEAD
	world.steps += 1
	Moods.tick(world, roster, away, flags, ledger)
	var grief: Array = one.thoughts.filter(func(t: Dictionary) -> bool: return t["id"] == "friend_fell")
	_expect(not grief.is_empty() and str(grief[0]["label"]).contains(two.display_name), "%s did not grieve %s" % [one.display_name, two.display_name])
	two.status = Fate.ALIVE
	var saved := Character.from_dict(one.to_dict())
	_expect(saved.thoughts.size() == one.thoughts.size() and saved.mood() == one.mood(), "thoughts did not survive a save")
	one.thoughts.append({ "id": "test", "label": "test", "mood": -80, "until": world.steps + 1000 })
	_expect(str(Moods.band(one).get("id", "")) == "broken" and one.attack() < calm, "at the end of their rope, %s fought as hard as ever" % one.display_name)
	var rules: Dictionary = Database.world_rules["moods"]
	var kept_chance: float = rules["break_chance"]
	rules["break_chance"] = 1.0
	world.steps += 1
	var lines := Moods.tick(world, roster, away, flags, ledger)
	print("  moods: %s / %s" % [Moods.summary(one), " / ".join(lines)])
	_expect(not roster.party.has(one.id) and away.size() == 1, "%s at the end of their rope never sat out" % one.display_name)
	_expect(roster.party.has(roster.player().id), "the lead walked off in a mood")
	world.steps = int(away[0]["back_at"]) if not away.is_empty() else world.steps
	Dispatch.walk(world, roster, away, [])
	_expect(away.is_empty() and roster.party.has(one.id), "%s never came back from sitting out" % one.display_name)
	rules["break_chance"] = kept_chance
	world.tower_floor = kept_floor
	world.steps = kept_steps


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
		var roster := Company.found()
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


## Play-test 8's asks, call BX ([D326]): a job says how far off it is and how long until it is
## back; the quick wheel's slices and its Eat (food first); a companion let go is gone for good.
func _check_play_test_eight(world: World, roster: Roster) -> void:
	var from := world.player_cell
	var job := {"id": "nobody", "from": [from.x, from.y], "to": [from.x + 6, from.y],
			"sent_at": world.steps, "out_at": world.steps + 6, "back_at": world.steps + 12, "arrived": false}
	var kept_steps := world.steps
	world.steps += 3
	var read := Dispatch.reading(job, world)
	_expect(int(read["tiles"]) == 3 and int(read["steps"]) == 9, "a job half way out read %s" % [read])
	_expect(Dispatch.reading_words(job, world) == "3 tiles off, back in about 9 steps",
			"a job's reading said \"%s\"" % Dispatch.reading_words(job, world))
	job["waiting"] = true
	_expect(int(Dispatch.reading(job, world)["steps"]) == -1, "a band waiting at its meeting place gave steps to come")
	world.steps = kept_steps

	_expect(QuickWheel.sector_of(Vector2(0, -50), 6) == 0, "straight up was not the wheel's first slice")
	_expect(QuickWheel.sector_of(Vector2(50, 0), 4) == 1 and QuickWheel.sector_of(Vector2(0, 50), 4) == 2 \
			and QuickWheel.sector_of(Vector2(-50, 0), 4) == 3, "the wheel's slices do not go round clockwise")

	var hungry: Character = roster.party_members()[roster.party_members().size() - 1]
	var kept_stores := GameState.stores.duplicate()
	GameState.stores.clear()
	GameState.stores.append_array(["red_draught", "bread"])
	hungry.hp = maxi(1, hungry.max_hp() / 3)
	var line := QuickWheel.feed_the_hurt()
	_expect(line.contains("eats the Loaf") and GameState.stores.has("red_draught") and not GameState.stores.has("bread"),
			"the wheel's Eat did not feed the hurt one food first: \"%s\"" % line)
	GameState.stores.clear()
	GameState.stores.append_array(kept_stores)

	_expect(roster.let_go(roster.player().id) == null, "the lead could be let go")
	var going: Character = roster.party_members()[roster.party_members().size() - 1]
	_expect(roster.let_go(going.id) == going, "a companion could not be let go")
	_expect(roster.by_id(going.id) == null and not roster.party.has(going.id), "a companion let go was still on the roster")


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
