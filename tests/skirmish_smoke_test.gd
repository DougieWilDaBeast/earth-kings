extends Node
## Headless smoke test for the real-time skirmish (M11, [D36]).
##
##   godot --headless --path . res://tests/skirmish_smoke_test.tscn
##
## Checks that pause really stops the clock, that orders given while paused
## wait for it, that skills come back on their cooldowns, that a downed ally can
## be got back up, and then lets the whole fight play itself to an end on fixed
## ticks — no frames to wait on, so a minute of fight takes a moment. Then the
## fight the world starts: allies, auto, and everything written back onto the
## world (what the retired turn-based battle's test guarded, carried over).

## A fight that has not ended by then is stuck, not slow.
const SIM_LIMIT := 300.0

## By path rather than by class name, as the skirmish itself does, so the test
## runs on a checkout whose class cache has not been rebuilt by the editor.
const Fighter := preload("res://src/skirmish/fighter.gd")
const SkirmishRules := preload("res://src/skirmish/skirmish_rules.gd")
const SkirmishBrain := preload("res://src/skirmish/skirmish_brain.gd")
const SkirmishPassives := preload("res://src/skirmish/skirmish_passives.gd")

var _skirmish: Node2D
var _failures: Array[String] = []


func _ready() -> void:
	EventBus.battle_log.connect(func(line: String) -> void: print(line))
	# Damage rolls and opening tempo are random; a fixed seed keeps a failure
	# reproducible.
	seed(7)
	_skirmish = load("res://src/skirmish/skirmish.tscn").instantiate()
	_skirmish.boot_payload = {"encounter": {"map": _proving_ground()}, "sandbox": true}
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

	# The move order is carried out as soon as the clock runs, here or below;
	# once there the lead may well step off again into the fight.
	var walked := false
	# A skill spent is a skill waiting.
	_skirmish.manual = true
	_skirmish.paused = false
	var caster := _first_with_slots(party)
	if caster != null:
		var ability := caster.slot_ability(0)
		var wait := SkirmishRules.cooldown(ability)
		# Played by hand while it waits, so Auto Skill does not spend it again
		# the moment it is back and hide that it ever came back.
		caster.auto_skill = false
		_skirmish._land(caster, 0, caster.unit, caster.unit.cell)
		_expect(not caster.slot_ready(0), "%s came straight back" % ability.get("display_name", "?"))
		for _i in int(ceil(wait / SkirmishRules.TICK)) + 2:
			_skirmish.tick()
			walked = walked or lead.unit.cell != start_cell
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
		walked = walked or lead.unit.cell != start_cell
	_expect(walked, "a move order was never walked")

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
	# The fight is heard ([D76]): swings, blows landing, and how it ended.
	var heard: Dictionary = Sfx.counts
	_expect(int(heard.get("swing", 0)) + int(heard.get("shoot", 0)) > 0, "no swing or shot was heard")
	_expect(int(heard.get("hit", 0)) + int(heard.get("crit", 0)) > 0, "no blow was heard landing")
	_expect(int(heard.get("victory", 0)) + int(heard.get("defeat", 0)) == 1, "the end of the fight was heard %d times, not once" % [
		int(heard.get("victory", 0)) + int(heard.get("defeat", 0))])
	_expect(not Sfx.cue("no_such_cue"), "a cue that is not in data/sfx.json made a sound")
	print("heard: %s" % str(heard))
	await _check_touch()
	await _check_box_select()
	await _check_fight_rules()
	await _check_surround()
	await _check_allies_and_auto()
	await _check_the_world_hears()


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
	fight.boot_payload = {"encounter": {"map": _proving_ground()}, "touch": true, "sandbox": true}
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
	fight.boot_payload = {"encounter": {"map": _proving_ground()}, "touch": false, "sandbox": true}
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
	fight.boot_payload = {"encounter": {"map": _proving_ground()}, "touch": false, "sandbox": true}
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
		# Standing, and not on Bram's own tile: the fallen can lie anywhere.
		if not f.is_party() and f.is_standing() and f.unit.cell != bram.unit.cell \
				and int(Database.ability(f.basic).get("range", 1)) <= 1:
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
	# Nobody falls while they gather: what is checked is where they stand, and a
	# brigand Bram cuts down on his way in cannot stand anywhere.
	for f: Fighter in fight.fighters:
		if not f.is_party():
			f.unit.max_hp = 999999
			f.unit.hp = f.unit.max_hp
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


## Ported from the turn-based battle's own test when it was retired: a second
## fight, with two allies on the party's side, played on auto. The allies take
## the field, are friends to the party and foes to the enemy, think with the
## same brain, and the fight still comes to an end. Switching auto on from
## outside the fight (as the touch bar or a soak does) starts a paused clock.
func _check_allies_and_auto() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var map := BattleMapGen.generate_on("grass", "Allied field", [
		{"unit": "goblin", "level": 2}, {"unit": "goblin", "level": 2}, {"unit": "wolf", "level": 2},
	], rng)
	BattleMapGen.add_allies(map, [{"unit": "brigand", "level": 2}, {"unit": "brigand_archer", "level": 2}])
	var fight: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
	fight.boot_payload = {"encounter": {"title": "Allied field", "map": map}, "sandbox": true, "touch": false}
	add_child(fight)
	await get_tree().process_frame
	var allies: Array = fight.fighters.filter(func(f: Fighter) -> bool: return f.unit.team == Unit.Team.ALLY)
	var foes: Array = fight.fighters.filter(func(f: Fighter) -> bool: return not f.unit.sides_with_party())
	_expect(allies.size() == 2, "%d allies took the field, not 2" % allies.size())
	for ally: Fighter in allies:
		_expect(not fight.party_fighters().has(ally), "an ally can be picked like the party")
		var aim := SkirmishBrain.pick_target(ally, fight.fighters)
		_expect(aim == null or not aim.sides_with_party(), "an ally went for someone on its own side")
		if not foes.is_empty():
			_expect(ally.unit.is_hostile_to(foes[0].unit), "an ally and the enemy are at peace")
	_expect(fight.paused, "a fight played by hand did not open paused")
	var was := Pace.auto
	Pace.auto = true
	_expect(not fight.paused, "switching auto on from outside the fight left the clock stopped")
	# The key that hands the party over takes it back mid-fight too, and stops
	# the clock for the first order; without it the fight could not be had back.
	var take_back := InputEventAction.new()
	take_back.action = "battle_auto"
	take_back.pressed = true
	fight._unhandled_input(take_back)
	_expect(not Pace.auto, "the auto key did not take the party back in the middle of a fight")
	_expect(fight.paused, "taking the party back mid-fight did not stop the clock for an order")
	_expect(fight.armed_slot < 0, "taking the party back also readied a skill")
	Pace.auto = true
	fight.manual = true
	while not fight.over and fight.sim_time < SIM_LIMIT:
		fight.tick()
	_expect(fight.over, "the allied fight on auto did not end within %.0f seconds" % SIM_LIMIT)
	print("allies: %d fought beside the party on auto; over after %.1fs, victory %s" % [
		allies.size(), fight.sim_time, fight.victory])
	Pace.auto = was
	fight.queue_free()
	GameState.heal_party()


## A fight the world started is written back onto it, as the turn-based battle
## was: the world is told it began and how it ended, the first of a kind teaches,
## practice counts, the journal fills, a healer is remembered, draughts are
## spent from the stores, wounds carry out, an ambush gives the party the jump,
## and a fall the company cannot reach is settled for real by [Fate].
func _check_the_world_hears() -> void:
	var started: Array = []
	var finished: Array = []
	var fell: Array = []
	var on_start := func(map_id: String) -> void: started.append(map_id)
	var on_finish := func(result: Dictionary) -> void: finished.append(result)
	var on_fall := func(who: RefCounted, outcome: Dictionary) -> void: fell.append([who, outcome])
	EventBus.battle_started.connect(on_start)
	EventBus.battle_finished.connect(on_finish)
	EventBus.character_fell.connect(on_fall)
	GameState.heal_party()

	var map := _proving_ground()
	map["enemies"] = [
		{"unit": "goblin", "cell": [6, 1], "level": 2},
		{"unit": "goblin", "cell": [3, 2], "level": 2},
		{"unit": "brigand", "cell": [8, 1], "level": 3},
	]
	var fight: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
	fight.boot_payload = {
		"encounter": {"title": "The road", "map": map, "ambush": true},
		"return_scene": "world", "touch": false,
	}
	add_child(fight)
	await get_tree().process_frame
	fight.manual = true
	fight.paused = false
	_expect(started.size() == 1, "a fight the world started did not say so")
	var party: Array[Fighter] = fight.party_fighters()
	for f: Fighter in fight.fighters:
		if not f.unit.sides_with_party():
			_expect(f.attack_timer >= SkirmishPassives.rule("ambush_head_start", 2.0) - 0.01,
				"an ambushed %s was not held back" % f.unit.display_name)
	var bram := _by_template(fight, "bram")
	var toln := _by_template(fight, "toln")

	# A healer is remembered by whoever they healed.
	if bram != null and toln != null:
		bram.unit.hp = maxi(1, bram.unit.max_hp / 2)
		fight._strike(toln, bram.unit, Database.ability("mend"), "mend")
		_expect((fight._healed_by.get(bram.unit, []) as Array).has(toln.unit.character),
			"a heal was not remembered for the healer's assist")

	# What is drunk is gone from the stores.
	GameState.stores.append("herbs")
	fight._fill_pouch()
	var herbs_before := GameState.stores.count("herbs")
	if bram != null:
		bram.unit.hp = maxi(1, bram.unit.max_hp / 3)
		bram.items_used = 0
		_expect(fight.use_item(bram, "herbs"), "could not use herbs in a fight on the road")
		var ticks := 0
		while bram.is_using() and ticks < 100:
			fight.tick()
			ticks += 1
		_expect(GameState.stores.count("herbs") == herbs_before - 1, "herbs used on the road were not taken from the stores")

	# The first goblin down teaches; practice is counted; the journal writes it down.
	var killer: Fighter = party[0]
	var practice_before := _practice(party)
	var goblin: Fighter = null
	for f: Fighter in fight.fighters:
		if f.unit.template_id == "goblin" and f.is_standing():
			goblin = f
			break
	var knew := Progression.has_beaten(killer.unit.character, "goblin")
	if goblin != null:
		goblin.unit.hp = 1
		var swung := false
		for _try in 20:
			if fight._strike(killer, goblin.unit, Database.ability(killer.basic), killer.basic):
				swung = true
				break
		_expect(swung and not goblin.is_standing(), "a goblin on one hit point stood")
		_expect(knew or Progression.has_beaten(killer.unit.character, "goblin"),
			"the first goblin down taught %s nothing" % killer.unit.display_name)
		_expect(Journal.is_felled(GameState.world, "goblin"), "the journal did not write down a goblin felled")
	var caster := _first_with_slots(party)
	if caster != null:
		caster.cooldowns[0] = 0.0
		caster.energy = caster.energy_max
		var target: Unit = caster.unit
		if not SkirmishRules.is_support(caster.slot_ability(0)):
			for f: Fighter in fight.fighters:
				if not f.unit.sides_with_party() and f.is_standing():
					target = f.unit
					f.unit.hp = f.unit.max_hp
					break
		var ability := caster.slot_ability(0)
		# Close enough for anything to land: the test is the counting, not the reach.
		if not AbilityResolver.affected_cells(ability, target.cell).is_empty():
			fight._land(caster, 0, target, target.cell)
	_expect(_practice(party) > practice_before, "nothing landed in a fight on the road was counted as practice")

	# Down with nobody coming: when the window runs out, Fate settles it.
	var patient: Fighter = party[party.size() - 1]
	var who: Character = patient.unit.character
	patient.unit.take_damage(patient.unit.hp)
	fight._drop(patient)
	_expect(patient.is_downed(), "a party member at zero was not downed on the road")
	patient.near_death = SkirmishRules.TICK * 0.5
	fight.tick()
	_expect(fell.size() == 1 and fell[0][0] == who, "a fall on the road was not settled through Fate")
	if fell.size() == 1:
		var outcome: Dictionary = fell[0][1]
		match str(outcome["outcome"]):
			Fate.DEAD:
				_expect(who.status == Fate.DEAD and patient.fallen, "Fate said dead and %s is not" % who.display_name)
			Fate.CAPTURED:
				_expect(who.status == Fate.CAPTURED and patient.fallen, "Fate said taken and %s is not" % who.display_name)
			_:
				_expect(who.is_alive(), "Fate said alive and %s is not" % who.display_name)
		print("fate: %s — %s" % [outcome["outcome"], outcome["line"]])

	# The rest of it, hands off; then the world hears how it went.
	while not fight.over and fight.sim_time < SIM_LIMIT:
		fight.tick()
	_expect(fight.over, "the fight on the road did not end within %.0f seconds" % SIM_LIMIT)
	_expect(finished.size() == 1, "the world was told %d times that the fight ended" % finished.size())
	if finished.size() == 1:
		_expect(finished[0].has("victory") and finished[0].has("map_id"),
			"the result the world reads is missing a key: %s" % [finished[0]])
		_expect(bool(finished[0]["victory"]) == fight.victory, "the world was told the wrong result")
		_expect(GameState.has_flag("last_victory") == fight.victory, "last_victory does not say how the fight went")
	var standing := 0
	for f: Fighter in party:
		if not f.is_standing():
			continue
		standing += 1
		var most := f.unit.character.max_hp()
		var share: float = maxf(fight._share_left(f), Difficulty.post_battle_heal_ratio())
		var expected := clampi(roundi(share * float(most)), 1, most)
		_expect(f.unit.character.current_hp() == expected, "%s walked off with %d hp, not the %d the fight left" % [
			f.unit.display_name, f.unit.character.current_hp(), expected])
	_expect(not who.is_lost() or not GameState.roster.party_members().has(who),
		"%s was lost and still marches" % who.display_name)
	print("road: %s after %.1fs; %d walked off carrying their wounds; %d fell" % [
		"won" if fight.victory else "lost", fight.sim_time, standing, fell.size()])

	# A sandbox fight says nothing to the world.
	var sand: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
	sand.boot_payload = {"encounter": {"map": _proving_ground()}, "sandbox": true, "touch": false}
	add_child(sand)
	await get_tree().process_frame
	sand.manual = true
	sand.paused = false
	while not sand.over and sand.sim_time < SIM_LIMIT:
		sand.tick()
	_expect(finished.size() == 1, "a sandbox fight told the world it had ended")
	EventBus.battle_started.disconnect(on_start)
	EventBus.battle_finished.disconnect(on_finish)
	EventBus.character_fell.disconnect(on_fall)
	fight.queue_free()
	sand.queue_free()


func _practice(group: Array[Fighter]) -> int:
	var total := 0
	for f: Fighter in group:
		for uses: int in f.unit.character.practice.values():
			total += uses
	return total


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
