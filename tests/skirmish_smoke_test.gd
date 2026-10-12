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
const SkirmishBrain := preload("res://src/skirmish/skirmish_brain.gd")

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

	_check_passives_and_graces(party, foes)

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
	await _check_touch()
	await _check_box_select()
	await _check_fight_rules()
	await _check_surround()


## Passives come from the data and do something; enemies get their roles; and a
## grace from [Fate] can stand a downed fighter back up without spending a charm.
func _check_passives_and_graces(party: Array[Fighter], foes: Array) -> void:
	for f in party:
		_expect(not f.passives.is_empty(), "%s has no passives" % f.unit.display_name)
	print("passives: %s" % ", ".join(party.map(func(f: Fighter) -> String:
		return "%s [%s]" % [f.unit.display_name, ", ".join(f.passives.map(func(p: Dictionary) -> String: return str(p["id"])))])))
	var roles: Array = foes.map(func(f: Fighter) -> String: return f.role)
	_expect(roles.has("charger") and roles.has("kiter"), "brigands and archers should charge and kite, got %s" % [roles])

	# Bloodthirst heals the one who lands the blow.
	var biter: Fighter = party[0]
	var foe: Fighter = null
	for other: Fighter in foes:
		if other.is_standing():
			foe = other
			break
	if foe != null:
		var kept := biter.passives
		biter.passives = [{"id": "test", "effect": "lifesteal", "value": 0.5}]
		biter.unit.hp = maxi(1, biter.unit.max_hp / 2)
		var before := biter.unit.hp
		var saved_hp := foe.unit.hp
		foe.unit.hp = foe.unit.max_hp * 10
		_skirmish._strike(biter, foe.unit, Database.ability(biter.basic), biter.basic)
		_expect(biter.unit.hp > before, "lifesteal healed nobody")
		foe.unit.hp = saved_hp
		biter.passives = kept

	# A grace: down someone with a charm on them and let the window run out.
	if party.size() >= 2:
		var patient: Fighter = party[1]
		var charms_before: Array = patient.unit.character.charms.duplicate()
		patient.unit.character.charms.append("grave_token")
		var saved := false
		for _try in 40:
			patient.unit.take_damage(patient.unit.hp)
			_skirmish._drop(patient)
			patient.near_death = SkirmishRules.TICK * 0.5
			_skirmish.tick()
			if patient.is_standing():
				saved = true
				break
			# Nobody saved them this time: put them back for another roll.
			patient.fallen = false
			patient.near_death = 0.0
			patient.unit.hp = patient.unit.max_hp
		_expect(saved and patient.graces > 0, "no grace ever stood a downed fighter back up")
		_expect(patient.unit.character.charms.has("grave_token"), "a training grace spent a charm")
		patient.unit.character.charms = charms_before


## Under a thumb there is no right button and no keyboard: a tap on anything
## that is not picking somebody is the order, and the keys are buttons.
func _check_touch() -> void:
	var fight: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
	fight.boot_payload = {"encounter": {"map": _proving_ground()}, "touch": true}
	add_child(fight)
	await get_tree().process_frame
	var buttons: Dictionary = fight.hud._buttons
	_expect(buttons.has("pause") and buttons.has("slot0") and buttons.has("hold"), "touch play built no buttons")
	if not buttons.has("pause"):
		fight.queue_free()
		return

	(buttons["pause"] as Button).pressed.emit()
	_expect(not fight.paused, "the Pause button did not start the fight")
	(buttons["pause"] as Button).pressed.emit()
	_expect(fight.paused, "the Pause button did not stop it again")

	var party: Array[Fighter] = fight.party_fighters()
	var foe: Fighter = fight.fighters.filter(func(f: Fighter) -> bool: return not f.is_party())[0]
	var lead: Fighter = party[0]
	fight.hud.card_clicked.emit(0)
	_expect(fight.selected == [lead], "tapping a card did not pick that fighter")
	fight._on_left_click(foe.unit.cell, false)
	_expect(lead.order == Fighter.Order.ATTACK and lead.order_target == foe.unit, "tapping an enemy did not send the picked fighter at it")
	var free := _free_cell_near(lead)
	fight._on_left_click(free, false)
	_expect(lead.order == Fighter.Order.MOVE and lead.order_cell == free, "tapping the ground did not send them there")
	if party.size() > 1:
		fight._on_left_click(party[1].unit.cell, false)
		_expect(fight.selected == [party[1]], "tapping a companion gave an order instead of picking them")
		fight.hud.card_clicked.emit(0)

	(buttons["hold"] as Button).pressed.emit()
	_expect(lead.hold, "the Hold button did nothing")
	var caster := _first_with_slots(party)
	if caster != null and str(caster.slot_ability(0).get("target", "enemy")) != "self":
		fight._select([caster])
		(buttons["slot0"] as Button).pressed.emit()
		_expect(fight.armed_slot == 0, "the first skill button did not ready the skill")
		(buttons["slot0"] as Button).pressed.emit()
		_expect(fight.armed_slot == -1, "tapping the skill again did not put it away")
	fight.queue_free()


## Click and drag picks every companion the box touches (D58); shift adds; a box
## over empty ground keeps the pick; and enemies are never picked.
func _check_box_select() -> void:
	var fight: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
	fight.boot_payload = {"encounter": {"map": _proving_ground()}, "touch": false}
	add_child(fight)
	await get_tree().process_frame
	var party: Array[Fighter] = fight.party_fighters()
	var foes: Array = fight.fighters.filter(func(f: Fighter) -> bool: return not f.is_party())
	var all := Rect2(fight.units_root.position + party[0].unit.position, Vector2.ZERO)
	for f: Fighter in party:
		all = all.expand(fight.units_root.position + f.unit.position)
	all = all.grow(2.0)
	fight._select([party[0]])
	fight.box_select(all, false)
	_expect(fight.selected.size() == party.size(), "dragging a box over the party did not pick them all")
	for foe: Fighter in foes:
		_expect(not fight.selected.has(foe), "dragging a box picked an enemy")
	fight.box_select(Rect2(Vector2(-5000, -5000), Vector2(10, 10)), false)
	_expect(fight.selected.size() == party.size(), "a box over nobody threw the pick away")
	if party.size() > 1:
		var one := Rect2(fight.units_root.position + party[1].unit.position - Vector2(4, 4), Vector2(8, 8))
		fight._select([party[0]])
		fight.box_select(one, true)
		_expect(fight.selected.has(party[0]) and fight.selected.has(party[1]), "shift and a box did not add to the pick")
		fight.box_select(one, false)
		_expect(fight.selected == [party[1]], "a box without shift did not replace the pick")
		# The button itself: a release with no box is still a click on what was pressed.
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.pressed = false
		fight._select([party[1]])
		fight._press_at = fight.units_root.position + party[0].unit.position
		fight._unhandled_input(release)
		_expect(fight.selected == [party[0]], "a click without a drag no longer picked the fighter")
		fight._press_at = all.position
		fight.drag_box = all
		fight._unhandled_input(release)
		_expect(fight.selected.size() == party.size() and not fight.drag_box.has_area(), "letting go of a dragged box did not pick inside it")
	fight.queue_free()


func _new_fight() -> Node2D:
	var fight: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
	fight.boot_payload = {"encounter": {"map": _proving_ground()}, "touch": false}
	add_child(fight)
	await get_tree().process_frame
	fight.manual = true
	fight.paused = false
	return fight


func _by_template(fight: Node2D, template_id: String) -> Fighter:
	for f: Fighter in fight.fighters:
		if f.unit.template_id == template_id:
			return f
	return null


## D59: stuns break casts, charged spells, energy, draughts and herbs, shields.
func _check_fight_rules() -> void:
	var fight := await _new_fight()
	var bram := _by_template(fight, "bram")
	var toln := _by_template(fight, "toln")
	var foe: Fighter = fight.fighters.filter(func(f: Fighter) -> bool: return not f.is_party())[0]
	_expect(bram != null and toln != null, "the training party is not Bram and Toln")
	if bram == null or toln == null:
		fight.queue_free()
		return

	# A charged spell takes its time and hits harder.
	# Pyre on a slot, as a hedge priest who has learnt it would carry it.
	toln.slots.append("pyre")
	toln.cooldowns.append(0.0)
	var ember := toln.slots.size() - 1
	_expect(SkirmishRules.is_charged(toln.slot_ability(ember)), "Pyre is not a charged spell")
	_expect(SkirmishRules.is_charged(Database.ability("ember")), "Ember is not a charged spell")
	_expect(not SkirmishRules.is_charged(Database.ability("strike")), "a plain strike counts as charged")
	if ember >= 0:
		fight._begin_cast(toln, ember, foe.unit, foe.unit.cell)
		_expect(toln.is_casting() and float(toln.cast["total"]) >= 2.0, "Ember did not wind up for two seconds or more")
		# Shield Bash stuns and breaks it off.
		var bash := Database.ability("shield_bash")
		fight._strike(bram, toln.unit, bash, "shield_bash")
		_expect(not toln.is_casting(), "a stun did not break the cast")
		_expect(toln.is_stunned() and bram.interrupts == 1, "a stun did not stun, or was not counted")
		for _i in int(ceil(float(bash["stun"]) / SkirmishRules.TICK)) + 2:
			fight.tick()
		_expect(not toln.is_stunned(), "a stun never wore off")
		toln.unit.hp = toln.unit.max_hp

	# The brain keeps a stun for somebody casting.
	var bash_slot := bram.slots.find("shield_bash")
	_expect(bash_slot >= 0, "Bram has no Shield Bash")
	if bash_slot >= 0:
		var idle := SkirmishBrain.pick_skill(bram, fight.fighters)
		_expect(idle.is_empty() or int(idle["slot"]) != bash_slot, "a stun was thrown at somebody not casting")

	# Energy: skills drain it, an empty bar means tired, and it comes back.
	var skill := 0 if not bram.slots.is_empty() else -1
	if skill >= 0:
		var cost := SkirmishRules.energy_cost(bram.slot_ability(skill))
		bram.energy = cost
		bram.spend_energy(bram.slot_ability(skill))
		_expect(bram.tired and not bram.slot_ready(skill), "an empty bar did not leave Bram tired")
		var ticks := 0
		while bram.tired and ticks < 800:
			fight.tick()
			ticks += 1
		_expect(not bram.tired, "a tired fighter never recovered")
		_expect(bram.energy >= bram.energy_max * 0.5 - 0.01, "recovered before half the bar was back")

	# A draught or herb: it takes a moment, it cannot be stunned, and it mends.
	var items: Array = fight.pouch_items()
	_expect(not items.is_empty(), "the fight has nothing in the pouch")
	if not items.is_empty():
		var item_id: String = items[0]
		var before := int(fight.pouch[item_id])
		bram.unit.hp = maxi(1, bram.unit.max_hp / 4)
		var hp_before := bram.unit.hp
		_expect(fight.use_item(bram, item_id), "could not use the %s" % item_id)
		_expect(bram.is_using(), "using an item took no time")
		fight._stun(bram, null, 2.0)
		_expect(not bram.is_stunned() and bram.is_using(), "somebody drinking was stunned")
		var ticks := 0
		while bram.is_using() and ticks < 100:
			fight.tick()
			ticks += 1
		_expect(bram.unit.hp > hp_before, "the %s mended nothing" % item_id)
		_expect(int(fight.pouch.get(item_id, 0)) == before - 1, "the %s was not taken from the pouch" % item_id)
		bram.items_used = 99
		_expect(fight.item_refusal(bram, item_id) != "", "a fighter can drink without end")

	# A shield turns a sword swing from the front, never one from behind.
	var brute: Fighter = null
	for f: Fighter in fight.fighters:
		if not f.is_party() and int(Database.ability(f.basic).get("range", 1)) <= 1:
			brute = f
	_expect(bram.shield, "Bram does not carry a shield")
	if brute != null and bram.shield:
		var rules: Dictionary = Database.skirmish["rules"]
		var saved := [rules.get("block_chance"), rules.get("block_max")]
		rules["block_chance"] = 1.0
		rules["block_max"] = 1.0
		bram.unit.face_towards(brute.unit.cell)
		_expect(fight._blocks(brute, bram, brute.basic), "a shield never blocks a swing from the front")
		bram.unit.facing = -Unit.dominant_direction(brute.unit.cell - bram.unit.cell)
		_expect(not fight._blocks(brute, bram, brute.basic), "a shield blocked a swing from behind")
		_expect(not fight._blocks(brute, toln, brute.basic), "somebody without a shield blocked")
		rules["block_chance"] = saved[0]
		rules["block_max"] = saved[1]
	fight.queue_free()


## Told at one enemy, a crowd should stand round him, not queue up on one side.
func _check_surround() -> void:
	var fight := await _new_fight()
	var bram := _by_template(fight, "bram")
	if bram == null:
		fight.queue_free()
		return
	for f: Fighter in fight.party_fighters():
		if f != bram:
			f.fallen = true
			f.unit.visible = false
	bram.unit.max_hp = 999999
	bram.unit.hp = bram.unit.max_hp
	bram.hold = true
	bram.auto_skill = false
	for _i in int(12.0 / SkirmishRules.TICK):
		fight.tick()
	var sides := {}
	var adjacent := 0
	for f: Fighter in fight.fighters:
		if f.is_party() or not f.is_standing():
			continue
		if Pathfinder.distance(f.unit.cell, bram.unit.cell) == 1:
			adjacent += 1
			sides[f.unit.cell - bram.unit.cell] = true
	print("  surround: %d brigands at Bram's side, on %d sides" % [adjacent, sides.size()])
	_expect(adjacent >= 3 and sides.size() >= 3, "melee foes clumped instead of surrounding (%d on %d sides)" % [adjacent, sides.size()])
	fight.queue_free()


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
