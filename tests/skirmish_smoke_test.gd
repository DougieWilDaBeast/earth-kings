extends Node
## Headless smoke test for the real-time skirmish (M11, [D36]).
##
##   godot --headless --path . res://tests/skirmish_smoke_test.tscn
##
## Checks that pause really stops the clock, that orders given while paused
## wait for it, that skills come back on their cooldowns, that a downed ally can
## be got back up, and then lets the whole fight play itself to an end on fixed
## ticks — no frames to wait on, so a minute of fight takes a moment.

## A fight that has not ended by then is stuck, not slow.
const SIM_LIMIT := 300.0

## By path rather than by class name, as the skirmish itself does, so the test
## runs on a checkout whose class cache has not been rebuilt by the editor.
const Fighter := preload("res://src/skirmish/fighter.gd")
const SkirmishRules := preload("res://src/skirmish/skirmish_rules.gd")

var _skirmish: Node2D
var _failures: Array[String] = []


func _ready() -> void:
	EventBus.battle_log.connect(func(line: String) -> void: print(line))
	# Damage rolls and opening tempo are random; a fixed seed keeps a failure
	# reproducible.
	seed(7)
	_skirmish = load("res://src/skirmish/skirmish.tscn").instantiate()
	_skirmish.boot_payload = {"encounter": {"map": _proving_ground()}}
	add_child(_skirmish)
	await get_tree().process_frame
	await _run()
	if _failures.is_empty():
		print("skirmish smoke test: PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			print("FAIL  %s" % failure)
		print("skirmish smoke test: FAIL")
		get_tree().quit(1)


func _run() -> void:
	var party: Array[Fighter] = _skirmish.party_fighters()
	var foes: Array = _skirmish.fighters.filter(func(f: Fighter) -> bool: return not f.is_party())
	_expect(not party.is_empty(), "no party fighters")
	_expect(not foes.is_empty(), "no enemy fighters")
	_expect(_skirmish.paused, "the fight should open paused")
	if party.is_empty() or foes.is_empty():
		return
	print("party: %s" % ", ".join(party.map(func(f: Fighter) -> String:
		return "%s [%s | %s]" % [f.unit.display_name, f.basic, ", ".join(f.slots)])))

	# Paused means paused: frames pass, the clock does not.
	var lead: Fighter = party[0]
	var start_cell := lead.unit.cell
	var free := _free_cell_near(lead)
	_skirmish.order_move(lead, free)
	for _i in 20:
		await get_tree().process_frame
	_expect(_skirmish.sim_time == 0.0, "the clock ran while paused")
	_expect(lead.unit.cell == start_cell, "a unit moved while paused")
	_expect(lead.order == Fighter.Order.MOVE, "an order given while paused was lost")

	# A skill spent is a skill waiting.
	_skirmish.manual = true
	_skirmish.paused = false
	var caster := _first_with_slots(party)
	if caster != null:
		var ability := caster.slot_ability(0)
		var wait := SkirmishRules.cooldown(ability)
		_skirmish._land(caster, 0, caster.unit, caster.unit.cell)
		_expect(not caster.slot_ready(0), "%s came straight back" % ability.get("display_name", "?"))
		for _i in int(ceil(wait / SkirmishRules.TICK)) + 2:
			_skirmish.tick()
		_expect(caster.slot_ready(0), "%s never came off cooldown (%.1fs)" % [ability.get("display_name", "?"), wait])
		# The fullest auto-pause also stops when a hand-played unit's skill comes back.
		var skirmish_script: Script = _skirmish.get_script()
		skirmish_script.auto_pause = 2
		caster.auto_skill = false
		caster.cooldowns[0] = SkirmishRules.TICK * 0.5
		_skirmish.manual = false
		_skirmish.tick()
		_expect(_skirmish.paused, "auto-pause did not stop for a ready skill")
		_skirmish.manual = true
		_skirmish.paused = false
		caster.auto_skill = true
		skirmish_script.auto_pause = 1
	else:
		print("  (nobody has a quick slot yet — cooldown check skipped)")

	# Unpaused, the order is carried out.
	_skirmish.manual = true
	_skirmish.paused = false
	for _i in 80:
		_skirmish.tick()
	_expect(lead.unit.cell != start_cell, "a move order was never walked")

	# Down, and back up again.
	if party.size() >= 2:
		var patient: Fighter = party[1]
		var helper: Fighter = party[0]
		patient.unit.take_damage(patient.unit.hp)
		# Played by hand, a fall stops the clock (auto-pause's default).
		_skirmish.manual = false
		_skirmish._drop(patient)
		_expect(_skirmish.paused, "auto-pause did not stop the fight when someone went down")
		_skirmish.manual = true
		_skirmish.paused = false
		_expect(patient.is_downed(), "a party member at zero was not downed")
		_skirmish.order_aid(helper, patient.unit)
		var ticks := 0
		while patient.is_downed() and ticks < 400:
			_skirmish.tick()
			ticks += 1
		_expect(patient.is_standing(), "%s was never got back up (%s)" % [patient.unit.display_name, patient.activity()])

	# Then the whole fight, hands off.
	var ticks := 0
	while not _skirmish.over and _skirmish.sim_time < SIM_LIMIT:
		_skirmish.tick()
		ticks += 1
		if ticks % 400 == 0:
			await get_tree().process_frame
	_expect(_skirmish.over, "the fight did not end within %.0f seconds" % SIM_LIMIT)
	var swings := 0
	var casts := 0
	for f: Fighter in _skirmish.fighters:
		swings += f.swings
		casts += f.casts
	print("skirmish over after %.1fs of fight — victory: %s — %d basic attacks, %d skills" % [
		_skirmish.sim_time, _skirmish.victory, swings, casts,
	])
	_expect(swings > 0, "nobody ever swung")


## The first authored map, with its brigands levelled up and doubled. Out of the
## box they fall to one arrow each, and a four-second fight tests nothing.
func _proving_ground() -> Dictionary:
	var map: Dictionary = Database.map("verdant_pass").duplicate(true)
	map["enemies"] = [
		{"unit": "brigand", "cell": [6, 1], "level": 8},
		{"unit": "brigand", "cell": [3, 2], "level": 8},
		{"unit": "brigand", "cell": [8, 1], "level": 8},
		{"unit": "brigand", "cell": [5, 2], "level": 8},
		{"unit": "brigand_archer", "cell": [10, 2], "level": 8},
		{"unit": "brigand_archer", "cell": [9, 3], "level": 8},
	]
	return map


func _first_with_slots(group: Array[Fighter]) -> Fighter:
	for f in group:
		if not f.slots.is_empty():
			return f
	return null


func _free_cell_near(f: Fighter) -> Vector2i:
	for cell: Vector2i in _skirmish.pathfinder.cells_in_range(f.unit.cell, 1, 2):
		if _skirmish.grid.is_walkable(cell) and _skirmish.occupant(cell) == null:
			return cell
	return f.unit.cell


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
