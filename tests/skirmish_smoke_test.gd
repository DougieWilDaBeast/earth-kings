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
const SkirmishFx := preload("res://src/skirmish/skirmish_fx.gd")
const Formations := preload("res://src/skirmish/formations.gd")
const Recruits := preload("res://src/chronicle/recruits.gd")
const SkirmishMarks := preload("res://src/skirmish/skirmish_marks.gd")
const SkirmishConditions := preload("res://src/skirmish/skirmish_conditions.gd")
const Company := preload("res://tests/company.gd")

var _skirmish: Node2D
var _failures: Array[String] = []


func _ready() -> void:
	EventBus.battle_log.connect(func(line: String) -> void: print(line))
	# Damage rolls and opening tempo are random; a fixed seed keeps a failure
	# reproducible.
	seed(7)
	# The fight's rules are under test, not the difficulty: the checks below were set against
	# Story (once the default, before the First Hour setting, D104).
	GameState.difficulty = "gentle"
	# Cato leading Vesta and Iris: a shield, a healer and a bow. Not Atlas, whose
	# bearer would take the field as a fourth body (see _check_signatures).
	GameState.roster = Company.found("cato", ["vesta", "iris"])
	_skirmish = load("res://src/skirmish/skirmish.tscn").instantiate()
	_skirmish.boot_payload = {"encounter": {"map": _proving_ground()}, "sandbox": true}
	add_child(_skirmish)
	await get_tree().process_frame
	await _run()
	# A company's name is many people: theirs, not "the Late Risers's" ([D373]).
	for pair: Array in [["the Late Risers", "the Late Risers'"], ["Ceres", "Ceres's"], ["the Ninth Stair", "the Ninth Stair's"]]:
		if _skirmish.whose(pair[0]) != pair[1]:
			_failures.append("whose: %s comes out as %s" % [pair[0], _skirmish.whose(pair[0])])
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
	_expect(int(heard.get("engage", 0)) >= 1, "the fight opened without a sound (D185)")
	_expect(not Sfx.cue("no_such_cue"), "a cue that is not in data/sfx.json made a sound")
	for cue_id: String in Database.sfx.get("cues", {}):
		var file := str(Database.sfx["cues"][cue_id].get("file", cue_id))
		_expect(ResourceLoader.exists("%s/%s.wav" % [Sfx.DIR, file]), "the %s cue's sound is not on disk" % cue_id)
	print("heard: %s" % str(heard))
	# And seen: the drawn effects and icons are all on disk, and blows show them.
	for key: String in ["swing", "shot", "spell", "heal", "block", "charged"]:
		_expect(not SkirmishFx.effect_frames(SkirmishFx.effect_for(key)).is_empty(), "no frames for the %s effect" % key)
	for key: String in ["stunned", "casting", "tired", "using"]:
		_expect(SkirmishFx.status_icon(str(Database.skirmish["status_icons"][key])) != null, "no icon for %s" % key)
	_expect(SkirmishFx.status_icon("herb") != null, "no icon for herbs")
	_expect(int(SkirmishFx.played.get("slash", 0)) + int(SkirmishFx.played.get("arrow", 0)) > 0, "no blow was seen landing")
	print("seen: %s" % str(SkirmishFx.played))
	await _check_touch()
	await _check_box_select()
	await _check_cards_fit()
	await _check_lineup()
	await _check_upper_bite()
	await _check_fight_rules()
	await _check_surround()
	await _check_allies_and_auto()
	await _check_the_world_hears()
	await _check_signatures()
	await _check_conditions()
	await _check_heights_in_a_fight()
	await _check_into_the_clouds()
	await _check_plan_table()
	_check_bout()
	_check_party_war()
	await _check_tactics()
	await _check_tier_ways()
	await _check_stances()
	await _check_keeping_together()
	await _check_formations()
	await _check_foes_in_formation()
	await _check_leader_and_callouts()
	_check_heal_growth()
	await _check_the_turn()
	await _check_scars()
	await _check_walking_out()
	await _check_reaching_the_fallen()
	_check_hand_fight_speed()


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
	_expect(is_equal_approx(fight.pick_pace(), 1.0), "the fight starts slow on touch with the lead picked for you (D386)")
	fight.hud.card_clicked.emit(0)
	_expect(fight.selected == [lead], "tapping a card did not pick that fighter")
	var slow := float(SkirmishPassives.rule("pick_pace", 1.0))
	_expect(slow < 1.0 and is_equal_approx(fight.pick_pace(), slow),
		"picking a fighter on touch did not slow the fight to pick_pace (D386): %s" % fight.pick_pace())
	fight._on_left_click(foe.unit.cell, false)
	_expect(lead.order == Fighter.Order.ATTACK and lead.order_target == foe.unit, "tapping an enemy did not send the picked fighter at it")
	_expect(is_equal_approx(fight.pick_pace(), 1.0), "the fight stayed slow after the order was given (D386)")
	var free := _free_cell_near(lead)
	fight._on_left_click(free, false)
	_expect(lead.order == Fighter.Order.MOVE and lead.order_cell == free, "tapping the ground did not send them there")
	if party.size() > 1:
		fight._on_left_click(party[1].unit.cell, false)
		_expect(fight.selected == [party[1]], "tapping a companion gave an order instead of picking them")
		fight.hud.card_clicked.emit(0)

	# On touch the order is given as the finger lifts: a drag of the camera gives none, nor does a
	# finger held to ask who stands there (D388).
	var order_before: int = lead.order
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(300, 300)
	fight._unhandled_input(press)
	var lift := InputEventMouseButton.new()
	lift.button_index = MOUSE_BUTTON_LEFT
	lift.position = Vector2(380, 300)
	fight._unhandled_input(lift)
	_expect(lead.order == order_before and fight.selected == [lead], "a finger dragged across the board gave an order (D388)")
	fight._unhandled_input(press)
	EventBus.touch_held.emit(press.position)
	lift.position = press.position
	fight._unhandled_input(lift)
	_expect(lead.order == order_before and fight.selected == [lead], "a finger held to ask gave an order as it lifted (D388)")
	(buttons["hold"] as Button).pressed.emit()
	_expect(lead.hold, "the Hold button did nothing")
	# About 44 points under a thumb, and a skill said by its name, not a key (D387).
	_expect((buttons["pause"] as Button).size.y >= 58.0, "a fight's touch button is under 58 pixels tall: %s" % (buttons["pause"] as Button).size)
	fight._select([lead])
	fight.hud.refresh()
	for slot in 4:
		var skill: Button = buttons["slot%d" % slot]
		if slot < lead.slots.size():
			var name := str(lead.slot_ability(slot).get("display_name", ""))
			_expect(skill.visible and skill.text.ends_with(name) and not skill.text.begins_with(str(SkirmishRules.SLOT_LABELS[slot]) + " "),
				"skill button %d says %s, not the skill's name %s (D387)" % [slot, skill.text, name])
		else:
			_expect(not skill.visible, "skill button %d is up for a skill %s has not got (D387)" % [slot, lead.unit.display_name])
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
	fight._select([party[0]])
	_expect(is_equal_approx(fight.pick_pace(), 1.0), "a pick with the mouse slowed the fight; pick_pace is touch only (D386)")
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


## Six on the field with a pouch of draughts: every party card sits inside the screen, and the
## fight's log above them, not under them ([D231], play-test 4: the cards ran off the bottom).
func _check_cards_fit() -> void:
	var before := GameState.roster
	GameState.roster = Company.found("atlas", ["vesta", "iris", "juno", "cato", "ares"])
	for touch: bool in [false, true]:
		var fight: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
		fight.boot_payload = {"encounter": {"map": _proving_ground()}, "touch": touch, "sandbox": true}
		add_child(fight)
		for i in 3:
			await get_tree().process_frame
		var view := get_viewport().get_visible_rect()
		var cards: Array = fight.hud.get("_cards")
		_expect(cards.size() == 6, "six in the party but %d cards" % cards.size())
		var top := view.end.y
		for card: Control in cards:
			_expect(view.encloses(card.get_global_rect()),
				"a party card runs off the screen (touch %s): %s in %s" % [touch, card.get_global_rect(), view])
			top = minf(top, card.get_global_rect().position.y)
		var log_label: Control = fight.hud.get("_log")
		_expect(log_label.get_global_rect().end.y <= top + 0.5,
			"the fight's log sits under the party cards (touch %s)" % touch)
		fight.queue_free()
		await get_tree().process_frame
	GameState.roster = before
## As a fight starts it says who stands against the party, for the play log (Ewan's log said only
## "verdant_pass" for every fight): the foes with their levels, nobody of the party's side.
func _check_lineup() -> void:
	var said: Array[String] = []
	var hear := func(line: String) -> void: said.append(line)
	EventBus.battle_lineup.connect(hear)
	var fight := await _new_fight()
	EventBus.battle_lineup.disconnect(hear)
	_expect(said.size() == 1, "a fight said who it was against %d times" % said.size())
	if said.size() == 1:
		_expect(said[0].contains(" L"), "the fight's line-up gives no levels: %s" % said[0])
		for f: Fighter in fight.party_fighters():
			_expect(not said[0].contains(f.unit.display_name), "the line-up names %s of the party: %s" % [f.unit.display_name, said[0]])
	fight.queue_free()
	await get_tree().process_frame
## The Tower's upper floors bite harder (D222): the walked floors not at all, floor 6 at `base`,
## higher a floor after, never past `most`; a foe given `bite` hits that much harder in the fight.
func _check_upper_bite() -> void:
	var rules: Dictionary = Database.world_rules["tower"]["upper_bite"]
	var from := int(rules["from_floor"])
	_expect(is_equal_approx(Encounter.upper_bite(from - 1), 1.0), "a walked floor's foes bite harder")
	_expect(is_equal_approx(Encounter.upper_bite(from), float(rules["base"])), "floor %d does not bite at base" % from)
	_expect(Encounter.upper_bite(20) > Encounter.upper_bite(from), "floor 20 bites no harder than floor %d" % from)
	_expect(Encounter.upper_bite(100) <= float(rules["most"]) + 0.001, "a high floor bites past the most")
	# No fought floor fields the Ooze, the beginners' slimes (D243).
	var cohorts: Array = Database.world_rules["tower"]["cohorts"]
	for floor_n in range(from, 41):
		_expect(Encounter._tower_cohort(cohorts, floor_n) != "the_ooze", "Tower floor %d fields the beginners' slimes" % floor_n)
	var met := Encounter.for_tower(GameState.world, GameState.world.tower(), 12, GameState.party_characters(), RandomNumberGenerator.new())
	for entry: Dictionary in met["map"]["enemies"]:
		_expect(is_equal_approx(float(entry.get("bite", 1.0)), Encounter.upper_bite(12)), "a floor 12 foe does not bite as floor 12 says")
	var attack := {}
	for bite: float in [1.0, 2.0]:
		var map := _proving_ground()
		map["enemies"] = [{"unit": "brigand", "cell": [6, 1], "level": 8, "bite": bite}]
		var fight: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
		fight.boot_payload = {"encounter": {"map": map}, "touch": false, "sandbox": true}
		add_child(fight)
		await get_tree().process_frame
		for f: Fighter in fight.fighters:
			if not f.unit.sides_with_party():
				attack[bite] = f.unit.attack
		fight.queue_free()
		await get_tree().process_frame
	_expect(attack.size() == 2 and int(attack[2.0]) >= int(attack[1.0]) * 2 - 1,
		"a foe with bite 2 does not hit twice as hard: %s" % [attack])


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
	var cato := _by_template(fight, "cato")
	var vesta := _by_template(fight, "vesta")
	var foe: Fighter = fight.fighters.filter(func(f: Fighter) -> bool: return not f.is_party())[0]
	_expect(cato != null and vesta != null, "the training party is not Cato and Vesta")
	if cato == null or vesta == null:
		fight.queue_free()
		return

	# A charged spell takes its time and hits harder.
	# Pyre on a slot, as a hedge priest who has learnt it would carry it.
	vesta.slots.append("pyre")
	vesta.cooldowns.append(0.0)
	var ember := vesta.slots.size() - 1
	_expect(SkirmishRules.is_charged(vesta.slot_ability(ember)), "Pyre is not a charged spell")
	_expect(SkirmishRules.is_charged(Database.ability("ember")), "Ember is not a charged spell")
	_expect(not SkirmishRules.is_charged(Database.ability("strike")), "a plain strike counts as charged")
	if ember >= 0:
		fight._begin_cast(vesta, ember, foe.unit, foe.unit.cell)
		_expect(vesta.is_casting() and float(vesta.cast["total"]) >= 2.0, "Ember did not wind up for two seconds or more")
		_expect(SkirmishMarks.status_icons(vesta).has("charging"), "a fighter winding up wears no charging icon")
		# Shield Bash stuns and breaks it off.
		var bash := Database.ability("shield_bash")
		fight._strike(cato, vesta.unit, bash, "shield_bash")
		_expect(not vesta.is_casting(), "a stun did not break the cast")
		_expect(vesta.is_stunned() and cato.interrupts == 1, "a stun did not stun, or was not counted")
		_expect(SkirmishMarks.status_icons(vesta) == (["stun"] as Array[String]), "a stunned fighter wears %s, not the stun icon" % str(SkirmishMarks.status_icons(vesta)))
		for _i in int(ceil(float(bash["stun"]) / SkirmishRules.TICK)) + 2:
			fight.tick()
		_expect(not vesta.is_stunned(), "a stun never wore off")
		vesta.unit.hp = vesta.unit.max_hp

	# The brain keeps a stun for somebody casting.
	var bash_slot := cato.slots.find("shield_bash")
	_expect(bash_slot >= 0, "Cato has no Shield Bash")
	if bash_slot >= 0:
		var idle := SkirmishBrain.pick_skill(cato, fight.fighters)
		_expect(idle.is_empty() or int(idle["slot"]) != bash_slot, "a stun was thrown at somebody not casting")

	# Energy: skills drain it, an empty bar means tired, and it comes back.
	var skill := 0 if not cato.slots.is_empty() else -1
	if skill >= 0:
		var cost := SkirmishRules.energy_cost(cato.slot_ability(skill))
		cato.energy = cost
		cato.spend_energy(cato.slot_ability(skill))
		_expect(cato.tired and not cato.slot_ready(skill), "an empty bar did not leave Cato tired")
		var ticks := 0
		# Only the bar's own recovery: a full fight tick lets the brain spend the energy straight back.
		while cato.tired and ticks < 800:
			cato.recover_energy(SkirmishRules.TICK)
			ticks += 1
		_expect(not cato.tired, "a tired fighter never recovered")
		_expect(cato.energy >= cato.energy_max * 0.5 - 0.01, "recovered before half the bar was back")

	# A draught or herb: it takes a moment, it cannot be stunned, and it mends.
	var items: Array = fight.pouch_items()
	_expect(not items.is_empty(), "the fight has nothing in the pouch")
	if not items.is_empty():
		var item_id: String = items[0]
		var before := int(fight.pouch[item_id])
		cato.unit.hp = maxi(1, cato.unit.max_hp / 4)
		var hp_before := cato.unit.hp
		_expect(fight.use_item(cato, item_id), "could not use the %s" % item_id)
		_expect(cato.is_using(), "using an item took no time")
		fight._stun(cato, null, 2.0)
		_expect(not cato.is_stunned() and cato.is_using(), "somebody drinking was stunned")
		var ticks := 0
		while cato.is_using() and ticks < 100:
			fight.tick()
			ticks += 1
		_expect(cato.unit.hp > hp_before, "the %s mended nothing" % item_id)
		_expect(int(fight.pouch.get(item_id, 0)) == before - 1, "the %s was not taken from the pouch" % item_id)
		cato.items_used = 99
		_expect(fight.item_refusal(cato, item_id) != "", "a fighter can drink without end")

	# A shield turns a sword swing from the front, never one from behind.
	var brute: Fighter = null
	for f: Fighter in fight.fighters:
		# Standing, and not on Cato's own tile: the fallen can lie anywhere.
		if not f.is_party() and f.is_standing() and f.unit.cell != cato.unit.cell \
				and int(Database.ability(f.basic).get("range", 1)) <= 1:
			brute = f
	_expect(cato.shield, "Cato does not carry a shield")
	if brute != null and cato.shield:
		var rules: Dictionary = Database.skirmish["rules"]
		var saved := [rules.get("block_chance"), rules.get("block_max")]
		rules["block_chance"] = 1.0
		rules["block_max"] = 1.0
		cato.unit.face_towards(brute.unit.cell)
		_expect(fight._blocks(brute, cato, brute.basic), "a shield never blocks a swing from the front")
		cato.unit.facing = -Unit.dominant_direction(brute.unit.cell - cato.unit.cell)
		_expect(not fight._blocks(brute, cato, brute.basic), "a shield blocked a swing from behind")
		_expect(not fight._blocks(brute, vesta, brute.basic), "somebody without a shield blocked")
		rules["block_chance"] = saved[0]
		rules["block_max"] = saved[1]
	fight.queue_free()


## Told at one enemy, a crowd should stand round him, not queue up on one side.
func _check_surround() -> void:
	var fight := await _new_fight()
	var cato := _by_template(fight, "cato")
	if cato == null:
		fight.queue_free()
		return
	for f: Fighter in fight.party_fighters():
		if f != cato:
			f.fallen = true
			f.unit.visible = false
	cato.unit.max_hp = 999999
	cato.unit.hp = cato.unit.max_hp
	# Nobody falls while they gather: what is checked is where they stand, and a
	# brigand Cato cuts down on his way in cannot stand anywhere.
	for f: Fighter in fight.fighters:
		if not f.is_party():
			f.unit.max_hp = 999999
			f.unit.hp = f.unit.max_hp
	cato.hold = true
	cato.auto_skill = false
	for _i in int(12.0 / SkirmishRules.TICK):
		fight.tick()
	var sides := {}
	var adjacent := 0
	for f: Fighter in fight.fighters:
		if f.is_party() or not f.is_standing():
			continue
		# At arm's length, the diagonals too: a blow reaches them since D246.
		var off := f.unit.cell - cato.unit.cell
		if maxi(absi(off.x), absi(off.y)) == 1:
			adjacent += 1
			sides[off] = true
	print("  surround: %d brigands at Cato's side, on %d sides" % [adjacent, sides.size()])
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
## A fight you can walk out of, at a cost ([D319]; Ewan's ask, issue #243): whoever reaches the edge
## takes a parting blow of a share of their health, never a fall, and the band keeps a share of the
## company's coin when everyone gets clear.
func _check_walking_out() -> void:
	GameState.heal_party()
	var fight: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
	fight.boot_payload = {"encounter": {"title": "The road", "map": _proving_ground()}, "return_scene": "world", "touch": false}
	add_child(fight)
	await get_tree().process_frame
	fight.manual = true
	fight.paused = true
	var party: Array[Fighter] = fight.party_fighters()
	if party.size() < 2:
		_expect(false, "walking out: no party to walk out")
		fight.queue_free()
		return
	var share := float(SkirmishRules.flee_rules().get("parting_blow", 0.0))
	_expect(share > 0.0 and float(SkirmishRules.flee_rules().get("gold_share", 0.0)) > 0.0, "walking out costs nothing")
	var runner: Fighter = party[0]
	var full := runner.unit.hp
	fight._get_clear(runner)
	_expect(runner.fled and runner.unit.hp == full - maxi(1, roundi(float(runner.unit.max_hp) * share)) and runner.unit.hp > 0,
			"the parting blow took %d of %d, not %.0f%%" % [full - runner.unit.hp, runner.unit.max_hp, share * 100.0])
	# Never a fall: at one hit point the blow is nothing.
	var last: Fighter = party[1]
	last.unit.hp = 1
	fight._get_clear(last)
	_expect(last.fled and last.unit.hp == 1 and last.unit.is_alive(), "a parting blow felled %s" % last.unit.display_name)
	var toll := SkirmishRules.flee_toll(1000)
	_expect(toll == roundi(1000.0 * float(SkirmishRules.flee_rules().get("gold_share", 0.0))) and SkirmishRules.flee_toll(0) == 0 and SkirmishRules.flee_toll(3) <= 3,
			"the toll on the company's coin is %d of 1000" % toll)
	print("walking out: a parting blow of %.0f%% of health, and %.0f%% of the coin dropped in the running" % [share * 100.0, float(SkirmishRules.flee_rules().get("gold_share", 0.0)) * 100.0])
	fight.queue_free()
	await get_tree().process_frame
	GameState.heal_party()


## Scars ([D218], from Kenshi): whoever went down in a fight the company won, and lives, comes out
## with a little more health for good; up to `scars.most`; kept in the save.
func _check_scars() -> void:
	GameState.heal_party()
	var fight: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
	fight.boot_payload = {"encounter": {"title": "The road", "map": _proving_ground()}, "return_scene": "world", "touch": false}
	add_child(fight)
	await get_tree().process_frame
	fight.manual = true
	var party: Array[Fighter] = fight.party_fighters()
	if party.size() < 2:
		_expect(false, "scars: no party to scar")
		fight.queue_free()
		return
	var hurt: Character = party[1].unit.character
	var spared: Character = party[0].unit.character
	var before := hurt.max_hp()
	var spared_before := spared.scars
	party[1].went_down = true
	fight.victory = true
	fight._settle_the_party()
	var per := int(Database.world_rules.get("scars", {}).get("max_hp", 3))
	_expect(hurt.scars == 1, "scars: %s went down and got up, and has %d scars" % [hurt.display_name, hurt.scars])
	_expect(hurt.max_hp() == before + per, "scars: a scar gave %d health, not %d" % [hurt.max_hp() - before, per])
	_expect(spared.scars == spared_before, "scars: %s never went down and was scarred" % spared.display_name)
	_expect(Character.from_dict(hurt.to_dict()).scars == 1, "scars: a scar was lost in the save")
	var most := int(Database.world_rules.get("scars", {}).get("most", 5))
	for i in most + 3:
		hurt.scar()
	_expect(hurt.scars == most, "scars: %d scars, past the most (%d)" % [hurt.scars, most])
	hurt.scars = 0
	fight.queue_free()
	await get_tree().process_frame
	print("scars: down and back up in a won fight leaves +%d health for good, up to %d" % [per, most])


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
	var cato := _by_template(fight, "cato")
	var vesta := _by_template(fight, "vesta")

	# A healer is remembered by whoever they healed.
	if cato != null and vesta != null:
		cato.unit.hp = maxi(1, cato.unit.max_hp / 2)
		fight._strike(vesta, cato.unit, Database.ability("mend"), "mend")
		_expect((fight._healed_by.get(cato.unit, []) as Array).has(vesta.unit.character),
			"a heal was not remembered for the healer's assist")

	# What is drunk is gone from the stores.
	GameState.stores.append("herbs")
	fight._fill_pouch()
	var herbs_before := GameState.stores.count("herbs")
	if cato != null:
		cato.unit.hp = maxi(1, cato.unit.max_hp / 3)
		cato.items_used = 0
		_expect(fight.use_item(cato, "herbs"), "could not use herbs in a fight on the road")
		var ticks := 0
		while cato.is_using() and ticks < 100:
			fight.tick()
			ticks += 1
		_expect(GameState.stores.count("herbs") == herbs_before - 1, "herbs used on the road were not taken from the stores")

	# On the road the first goblin down teaches nothing but goes in the log of foes (D301); in a gate it
	# teaches; practice is counted either way; the journal writes it down.
	var killer: Fighter = party[0]
	var practice_before := _practice(party)
	var knew := Progression.has_beaten(killer.unit.character, "goblin")
	_expect(not fight.teaches(), "a fight on the road teaches levels")
	var goblin := _standing_goblin(fight)
	if goblin != null:
		_cut_down(fight, killer, goblin)
		_expect(knew or not Progression.has_beaten(killer.unit.character, "goblin"),
			"a goblin down on the road taught %s a level" % killer.unit.display_name)
		_expect(knew or int(killer.unit.character.met.get("goblin", 0)) >= 1,
			"a goblin down on the road is not in %s's log of foes" % killer.unit.display_name)
		_expect(Journal.is_felled(GameState.world, "goblin"), "the journal did not write down a goblin felled")
	fight.encounter["teaches"] = true
	goblin = _standing_goblin(fight)
	if goblin != null:
		_cut_down(fight, killer, goblin)
		_expect(Progression.has_beaten(killer.unit.character, "goblin"),
			"the first goblin down in a gate taught %s nothing" % killer.unit.display_name)
	fight.encounter.erase("teaches")
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


## The sixteen's own ways of fighting (agenda item 72): Atlas comes with his
## bearer and is stuck without him, Diana with her wolf, and what Pluto kills
## gets up for him.
func _check_signatures() -> void:
	var fight: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
	var map := _proving_ground()
	map["allies"] = [
		{"unit": "atlas", "cell": [3, 8], "level": 3},
		{"unit": "diana", "cell": [9, 8], "level": 3},
		{"unit": "pluto", "cell": [6, 7], "level": 3},
	]
	fight.boot_payload = {"encounter": {"map": map}, "touch": false, "sandbox": true}
	add_child(fight)
	await get_tree().process_frame
	fight.manual = true
	fight.paused = false
	var atlas := _by_template(fight, "atlas")
	var diana := _by_template(fight, "diana")
	var pluto := _by_template(fight, "pluto")
	_expect(atlas != null and diana != null and pluto != null, "the leads did not come into the fight")
	if atlas == null or diana == null or pluto == null:
		fight.queue_free()
		return
	var bearer: Fighter = atlas.sig.get("bearer")
	var wolf: Fighter = diana.sig.get("beast")
	_expect(bearer != null and bearer.bound_to == atlas and bearer.unit.team == atlas.unit.team, "Atlas came without his bearer")
	_expect(wolf != null and wolf.bound_to == diana and wolf.unit.template_id == "ice_wolf", "Diana came without her wolf")
	if bearer != null:
		_expect(bearer.unit.template_id == "sky" and atlas.aboard == bearer and atlas.unit.cell == bearer.unit.cell,
				"Atlas is not riding Sky")
		_expect(not atlas.targetable() and fight.occupant(bearer.unit.cell) == bearer,
				"Atlas on Sky's back can still be aimed at")
		_expect(fight.signatures.can_step(atlas), "Atlas cannot move on Sky's back")
		bearer.unit.take_damage(bearer.unit.hp)
		fight._drop(bearer)
		fight.signatures.tick(atlas)
		_expect(atlas.aboard == null and atlas.targetable() and atlas.unit.visible, "Atlas was not thrown when Sky fell")
		_expect(not fight.signatures.can_step(atlas), "Atlas moved alone with Sky down")
		pluto.unit.cell = atlas.unit.cell + Vector2i(1, 0)
		_expect(fight.signatures.can_step(atlas), "Atlas could not move with a friend beside him")
	var foe: Fighter = null
	for f: Fighter in fight.fighters:
		if not f.unit.sides_with_party() and f.is_standing():
			foe = f
	if foe != null:
		foe.unit.hp = 1
		fight._strike(pluto, foe.unit, Database.ability(pluto.basic), pluto.basic)
		fight.tick()
		var shades: Array = fight.fighters.filter(func(f: Fighter) -> bool: return f.bound_to == pluto)
		_expect(shades.size() == 1 and shades[0].is_standing() and shades[0].unit.team == pluto.unit.team,
				"what Pluto killed did not rise for him")
	fight.queue_free()


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


## Who wins? ([D180]): two of the sixteen fought hands off end with one of them
## standing, a lead's wolf does not keep its side in the fight, and the same seed
## gives the same answer.
func _check_bout() -> void:
	const WhoWins := preload("res://src/who_wins/who_wins.gd")
	var kept_roster := GameState.roster
	var first: Dictionary = WhoWins.run_bout(self, "cato", "saturn", 5, 7)
	var again: Dictionary = WhoWins.run_bout(self, "cato", "saturn", 5, 7)
	print(WhoWins.verdict_line(first))
	_expect(str(first["winner"]) in ["cato", "saturn"], "a bout ended with nobody winning: %s" % str(first))
	_expect(first["winner"] == again["winner"] and is_equal_approx(first["seconds"], again["seconds"]),
			"the same seed fought two different bouts: %s, then %s" % [str(first), str(again)])
	var wolf: Dictionary = WhoWins.run_bout(self, "ares", "diana", 5, 3)
	print(WhoWins.verdict_line(wolf))
	if wolf["winner"] == "ares":
		_expect(int(wolf["right_hp"]) <= 0, "Diana lost while still standing: %s" % str(wolf))
	GameState.roster = kept_roster


## Party clashes ([D257]): a draw gives each side one to four fighters, each with a stance from
## the data and gear that suits them; the field hands every fighter their gear, calling and
## stance; and a clash fought hands off comes to an answer.
func _check_party_war() -> void:
	const PartyWar := preload("res://src/party_war/party_war.gd")
	var kept_roster := GameState.roster
	var setup: Dictionary = PartyWar.draw(41)
	var stances: Array = Database.party_war.get("stances", [])
	for side: String in ["left", "right"]:
		var members: Array = setup[side]["members"]
		_expect(members.size() >= 1 and members.size() <= 4, "a party of %d was drawn" % members.size())
		for m: Dictionary in members:
			_expect(stances.has(m["stance"]), "a stance not in the data: %s" % str(m))
	var fight: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
	fight.boot_payload = PartyWar.stage(setup)
	fight.manual = true
	add_child(fight)
	var drawn: Array = setup["left"]["members"] + setup["right"]["members"]
	_expect(fight.fighters.filter(func(f: Fighter) -> bool: return f.bound_to == null).size() == drawn.size(),
			"the field does not hold everyone drawn")
	for f: Fighter in fight.fighters:
		if f.bound_to != null:
			continue
		var match_: Array = drawn.filter(func(m: Dictionary) -> bool:
			return m["unit"] == f.unit.template_id and m["stance"] == f.stance \
					and m["gear"] == f.unit.character.equipment and m["class"] == f.unit.character.class_id)
		_expect(not match_.is_empty(), "%s took the field without its gear, calling or stance" % f.unit.template_id)
		if str(f.unit.character.equipment) != "":
			_expect(Gear.suits(f.unit.character.equipment, f.unit.character),
					"%s carries %s, which does not suit them" % [f.unit.template_id, f.unit.character.equipment])
	remove_child(fight)
	fight.free()
	var result: Dictionary = PartyWar.run_quietly(self, PartyWar.draw(41))
	print(PartyWar.row(result))
	_expect(float(result["seconds"]) > 0.0 and str(result["winner"]) in ["left", "right", "none"],
			"a clash came to no answer: %s" % str(result))
	GameState.roster = kept_roster


## Tactics ([D187]): a lead fights to their doctrine. Iris steps back from Ares at
## her elbow; Ares, face to face with Iris, circles to her side; a ranged lead
## would walk further for a hurt foe than for a fresh one beside it.
func _check_tactics() -> void:
	const WhoWins := preload("res://src/who_wins/who_wins.gd")
	var kept_roster := GameState.roster
	var fight: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
	fight.boot_payload = WhoWins.stage("iris", "ares", 5, 11)
	fight.manual = true
	add_child(fight)
	await get_tree().process_frame
	var tactics: Dictionary = Database.skirmish["tactics"]
	var iris: Fighter = fight.fighters.filter(func(f: Fighter) -> bool: return f.unit.template_id == "iris")[0]
	var ares: Fighter = fight.fighters.filter(func(f: Fighter) -> bool: return f.unit.template_id == "ares")[0]
	_expect(SkirmishBrain.doctrine(iris, tactics) == tactics["doctrines"]["ranged"], "Iris does not fight as the ranged do")
	_expect(SkirmishBrain.doctrine(ares, tactics) == tactics["doctrines"]["striker"], "Ares does not fight as a striker")
	iris.unit.cell = Vector2i(8, 7)
	ares.unit.cell = Vector2i(8, 6)
	iris.unit.facing = Vector2i.UP
	ares.unit.facing = Vector2i.DOWN
	var kite := SkirmishBrain.pick_tactic(iris, fight.fighters, ares.unit, tactics)
	_expect(str(kite.get("why", "")) == "kite", "Iris with Ares at her elbow did not step back: %s" % str(kite))
	var flank := SkirmishBrain.pick_tactic(ares, fight.fighters, iris.unit, tactics)
	_expect(str(flank.get("why", "")) == "flank", "Ares face to face with Iris did not circle: %s" % str(flank))
	if str(flank.get("why", "")) == "flank":
		_expect(flank["goal"].call(Vector2i(9, 7)) and flank["goal"].call(Vector2i(8, 8)) \
				and not flank["goal"].call(Vector2i(8, 6)),
				"circling should end at Iris's side or back, not where she is looking")
	fight.queue_free()
	GameState.roster = kept_roster


## Tiers fight their own way ([D275]): the lesser is craven, the high charges and flanks, the hob
## fights harder near death, the chieftain spurs its kin, the caster finds the weak spot; a family's
## own passive (the wolves' pack) stays. A craven one badly hurt runs, and stops running once clear.
func _check_tier_ways() -> void:
	var has := func(template: String, passive: String) -> bool:
		var unit := Unit.create(template, Unit.Team.ENEMY, Vector2i.ZERO)
		var ids: Array = SkirmishPassives.for_unit(unit).map(func(p: Dictionary) -> String: return str(p["id"]))
		unit.free()
		return ids.has(passive)
	var role_of := func(template: String) -> String:
		var unit := Unit.create(template, Unit.Team.ENEMY, Vector2i.ZERO)
		var named := SkirmishPassives.role_for(unit)
		unit.free()
		return named
	_expect(role_of.call("goblin_lesser") == "craven", "a lesser goblin is not craven: %s" % role_of.call("goblin_lesser"))
	_expect(role_of.call("goblin_high") == "charger" and has.call("goblin_high", "hunters_angle"), "a high goblin does not charge and flank")
	_expect(has.call("hobgoblin", "last_stand"), "a hobgoblin does not fight harder near death")
	_expect(has.call("goblin_chieftain", "war_cry"), "a goblin chieftain does not spur its kin")
	_expect(has.call("goblin_shaman", "keen_eye") and not has.call("goblin_shaman", "war_cry"), "the shaman fights as a chieftain")
	_expect(role_of.call("goblin_shaman") == "healer", "the shaman does not hang back and mend: %s" % role_of.call("goblin_shaman"))
	_expect(has.call("pack_alpha", "pack_hunter") and has.call("pack_alpha", "war_cry"), "the pack alpha lost the pack or the cry")
	_expect(role_of.call("goblin") != "craven" and role_of.call("brigand") == "charger", "a plain kind or a brigand fights a tier's way")
	# Each family's own trick ([D276]), from the hob up: every family has one, the plain kind has none.
	var tricks: Dictionary = Database.skirmish["family_tricks"]
	for family: String in Database.encounters["tiers"]["families"]:
		_expect(tricks["families"].has(family), "%s has no trick of its own" % family)
	_expect(has.call("hobgoblin", "spite") and not has.call("goblin", "spite"), "the goblins' spite is not from the hob up")
	_expect(has.call("dire_wolf", "howl") and has.call("dire_wolf", "pack_hunter"), "a dire wolf lost the howl or the pack")
	var fight := await _new_fight()
	var foe: Fighter = null
	for f: Fighter in fight.fighters:
		if not f.is_party():
			foe = f
			break
	var cato := _by_template(fight, "cato")
	if foe == null or cato == null:
		fight.queue_free()
		return
	foe.role = "craven"
	foe.retreat_wait = 0.0
	foe.unit.cell = cato.unit.cell + Vector2i(1, 0)
	var ability := Database.ability(foe.basic)
	_expect(not fight._keep_away(foe, ability, cato.unit), "a craven one at full health ran")
	foe.unit.hp = maxi(1, int(foe.unit.max_hp * 0.2))
	var before := foe.unit.cell
	_expect(fight._keep_away(foe, ability, cato.unit) and foe.unit.cell != before, "a craven one badly hurt did not run")
	fight.queue_free()


## The party keeps together round its lead ([D281]): with Cato under half health and a foe on him,
## Vesta five tiles off comes to stand between them; Vesta with a foe already hitting her does not hang
## back from it; and no falling back takes her further than `keep_with` tiles from every friend.
func _check_keeping_together() -> void:
	for character: Character in GameState.party_characters():
		character.stance = "own"
	var fight := await _new_fight()
	var tactics: Dictionary = Database.skirmish["tactics"]
	var cato := _by_template(fight, "cato")
	var vesta := _by_template(fight, "vesta")
	var iris := _by_template(fight, "iris")
	var foes: Array = fight.fighters.filter(func(f: Fighter) -> bool: return not f.is_party())
	if cato == null or vesta == null or iris == null or foes.is_empty():
		_expect(false, "the proving ground has no company and foe to keep together with")
		fight.queue_free()
		return
	var foe: Fighter = foes[0]
	_expect(cato.unit.character.is_player, "Cato does not lead the company")
	for other: Fighter in foes.slice(1):
		other.unit.cell = Vector2i(0, 0)
	cato.unit.cell = Vector2i(6, 6)
	foe.unit.cell = Vector2i(7, 6)
	foe.target = cato.unit
	cato.target = foe.unit
	iris.unit.cell = Vector2i(6, 9)
	vesta.unit.cell = Vector2i(1, 6)
	vesta.tactic_wait = 0.0
	cato.unit.hp = maxi(1, int(cato.unit.max_hp * 0.3))
	var rally := SkirmishBrain.pick_tactic(vesta, fight.fighters, foe.unit, tactics)
	_expect(str(rally.get("why", "")) == "rally", "Vesta did not come to Cato under half health: %s" % str(rally))
	if str(rally.get("why", "")) == "rally":
		_expect(rally.get("target") == foe.unit and rally["goal"].call(Vector2i(7, 7)) and not rally["goal"].call(Vector2i(1, 6)),
				"the rally does not end between Cato and the foe on him")
	cato.unit.hp = cato.unit.max_hp
	_expect(str(SkirmishBrain.pick_tactic(vesta, fight.fighters, foe.unit, tactics).get("why", "")) != "rally",
			"Vesta rallied to a Cato at full health")
	# A foe at Vesta's elbow hitting her: she fights it, not hangs back from it.
	vesta.unit.cell = Vector2i(5, 7)
	var near: Fighter = foes[1] if foes.size() > 1 else foe
	near.unit.cell = Vector2i(5, 8)
	near.target = vesta.unit
	vesta.tactic_wait = 0.0
	_expect(str(SkirmishBrain.pick_tactic(vesta, fight.fighters, near.unit, tactics).get("why", "")) != "hang_back",
			"Vesta hung back from a foe already hitting her")
	near.target = cato.unit
	var back := SkirmishBrain.pick_tactic(vesta, fight.fighters, near.unit, tactics)
	if str(back.get("why", "")) == "hang_back":
		var keep := int(tactics["keep_with"])
		var alone: Array = fight.pathfinder.cells_in_range(vesta.unit.cell, 1, 12).filter(func(c: Vector2i) -> bool:
			return Pathfinder.distance(c, cato.unit.cell) > keep and Pathfinder.distance(c, iris.unit.cell) > keep)
		_expect(not alone.any(func(c: Vector2i) -> bool: return back["goal"].call(c)),
				"hanging back may take Vesta further than %d tiles from the whole company" % keep)
	tactics["keep_together"] = false
	var apart := SkirmishBrain.pick_tactic(vesta, fight.fighters, foe.unit, tactics)
	tactics["keep_together"] = true
	_expect(str(apart.get("why", "")) != "rally", "keep_together off still rallied")
	fight.queue_free()


## Formations ([D289], [D305]): every shape seats the party in its own cells, the mender is dealt to
## the back and a blade to the front, the shape turns with the lead, and in a fight a companion falls
## in to its slot until the party is in contact, holding it for a little guard.
func _check_formations() -> void:
	var rules: Dictionary = Database.skirmish.get("formations", {})
	_expect(Formations.on(), "formations are off")
	for shape: String in Formations.shapes():
		for n in range(1, 6):
			var slots := Formations.slots(shape, n)
			_expect(slots.size() == n, "%s has %d slots for %d companions" % [shape, slots.size(), n])
			var seen: Array = []
			for slot: Dictionary in slots:
				_expect(slot["at"] != Vector2i.ZERO and not seen.has(slot["at"]), "%s puts two in one cell, or one on the lead" % shape)
				seen.append(slot["at"])
	_expect(Formations.auto_for(4) == "diamond" and Formations.auto_for(6) == "pyramid" and Formations.auto_for(2) == "line",
			"auto picks %s for two, %s for four and %s for six" % [Formations.auto_for(2), Formations.auto_for(4), Formations.auto_for(6)])
	_expect(Formations.next("auto") != "auto" and Formations.next(Formations.names().back()) == "auto", "the shapes do not go round")
	_expect(Formations.line_of("vesta") == "back" and Formations.line_of("ares") == "front" and Formations.line_of("iris") == "back",
			"lines: Vesta %s, Ares %s, Iris %s" % [Formations.line_of("vesta"), Formations.line_of("ares"), Formations.line_of("iris")])
	var dealt := Formations.assign("diamond", ["ares", "vesta", "iris"])
	_expect(dealt.get("vesta") == Vector2i(0, -1) and dealt.get("ares") == Vector2i(0, 1) and dealt.has("iris"),
			"the diamond did not put Vesta behind and Ares ahead: %s" % [dealt])
	_expect(Formations.assign("diamond", ["ares", "vesta", "iris"]) == dealt, "the same party was dealt twice differently")
	# The shape turns with the lead: forward is the way they face, x their right hand.
	_expect(Formations.cell_for(Vector2i(1, 1), Vector2i(5, 5), Vector2i.DOWN) == Vector2i(4, 6), "facing down, a right-forward slot is not down and screen-left")
	_expect(Formations.cell_for(Vector2i(1, 1), Vector2i(5, 5), Vector2i.UP) == Vector2i(6, 4), "facing up, a right-forward slot is not up and screen-right")
	_expect(Formations.cell_for(Vector2i(0, -2), Vector2i(5, 5), Vector2i.RIGHT) == Vector2i(3, 5), "facing right, two behind is not two to the left")
	_expect(Formations.point_for(Vector2i(0, -1), Vector2(100, 100), Vector2.UP, 40.0) == Vector2(100, 140), "a slot behind on the ground is not 40 pixels below")

	for character: Character in GameState.party_characters():
		character.stance = "own"
	var kept := GameState.formation
	GameState.formation = "diamond"
	var fight := await _new_fight()
	var tactics: Dictionary = Database.skirmish["tactics"]
	var cato := _by_template(fight, "cato")
	var vesta := _by_template(fight, "vesta")
	var iris := _by_template(fight, "iris")
	var foes: Array = fight.fighters.filter(func(f: Fighter) -> bool: return not f.is_party())
	if cato == null or vesta == null or iris == null or foes.is_empty():
		_expect(false, "the proving ground has no company to form up")
		fight.queue_free()
		GameState.formation = kept
		return
	for other: Fighter in foes:
		other.unit.cell = Vector2i(0, 0)
	cato.unit.cell = Vector2i(6, 6)
	cato.unit.facing = Vector2i.UP
	vesta.unit.cell = Vector2i(2, 2)
	iris.unit.cell = Vector2i(9, 9)
	vesta.tactic_wait = 0.0
	var slot := Formations.slot_cell(vesta, fight.fighters)
	_expect(slot == Vector2i(6, 7), "Vesta's slot behind Cato facing up is %s, not (6, 7)" % slot)
	_expect(Formations.slot_cell(cato, fight.fighters) == Formations.NONE, "the lead was given a slot")
	var foe: Fighter = foes[0]
	var plan := SkirmishBrain.pick_tactic(vesta, fight.fighters, foe.unit, tactics)
	_expect(str(plan.get("why", "")) == "form", "Vesta did not fall in with nobody in contact: %s" % str(plan))
	if str(plan.get("why", "")) == "form":
		_expect(plan["goal"].call(Vector2i(6, 7)) and plan["goal"].call(Vector2i(5, 7)) and not plan["goal"].call(Vector2i(2, 2)),
				"falling in does not end at Vesta's slot")
	_expect(not Formations.holding(vesta, fight.fighters) and Formations.hold_guard(vesta, fight.fighters) == 0.0,
			"Vesta far from her slot counted as holding it")
	vesta.unit.cell = Vector2i(6, 7)
	vesta.tactic_wait = 0.0
	_expect(Formations.holding(vesta, fight.fighters) and Formations.hold_guard(vesta, fight.fighters) > 0.0, "Vesta in her slot is not holding it")
	_expect(str(SkirmishBrain.pick_tactic(vesta, fight.fighters, foe.unit, tactics).get("why", "")) != "form", "Vesta in her slot still fell in")
	# A foe at Cato's elbow: the party is in contact, and nobody falls in any more.
	vesta.unit.cell = Vector2i(2, 2)
	vesta.tactic_wait = 0.0
	foe.unit.cell = Vector2i(7, 6)
	foe.target = cato.unit
	_expect(Formations.in_contact(fight.fighters), "a foe at Cato's elbow is not contact")
	_expect(str(SkirmishBrain.pick_tactic(vesta, fight.fighters, foe.unit, tactics).get("why", "")) != "form", "Vesta fell in while Cato was fighting")
	rules["on"] = false
	_expect(Formations.slot_cell(vesta, fight.fighters) == Formations.NONE, "formations off still dealt a slot")
	rules["on"] = true
	GameState.formation = kept
	print("formations: %s dealt %s; Vesta's slot %s behind a Cato facing up, held for %.0f%% guard" % [
		"diamond", dealt, slot, float(rules.get("hold_guard", 0.0)) * 100.0])
	fight.queue_free()


## The leader, call-outs and fights shared ([D289], [D306]): the one with the most fights won leads
## and recommends a shape; the caller's shout warns the foe it names; fights won together are a
## little guard and might; a companion at the end of their rope holds no slot.
## Foes in formation ([D289], [D315]): a band of three or more falls in round its caller in the shape its
## size picks, facing the party, each dealt a slot by what it fights with; the caller has no slot, the
## party's own slots are untouched, and a foe off its slot plans to fall in until the band is in contact.
func _check_foes_in_formation() -> void:
	var fight := await _new_fight()
	fight.paused = true
	var foes: Array = fight.fighters.filter(func(f: Fighter) -> bool: return not f.is_party() and f.is_standing())
	var caller: Fighter = Formations.band_caller(fight.fighters)
	_expect(foes.size() >= 3 and caller != null and foes.has(caller), "the proving ground has no band of three with a caller")
	if caller == null:
		fight.queue_free()
		return
	var shape := Formations.auto_for(foes.size())
	var cells: Array = []
	for foe: Fighter in foes:
		var slot: Vector2i = Formations.band_slot_cell(foe, fight.fighters)
		if foe == caller:
			_expect(slot == Formations.NONE, "the band's caller was dealt a slot")
			continue
		_expect(slot != Formations.NONE and not cells.has(slot) and slot != caller.unit.cell,
				"%s has no slot of its own in the band's %s: %s" % [foe.unit.display_name, shape, slot])
		cells.append(slot)
		_expect(Formations.slot_cell(foe, fight.fighters) == Formations.NONE, "a foe was dealt a slot in the party's shape")
	_expect(cells.size() == foes.size() - 1, "%d slots for %d of the band" % [cells.size(), foes.size() - 1])
	# The shape faces the party: its slots lie round the caller as the party's lie round the lead.
	var toward: Fighter = Formations.nearest_of_the_party(caller.unit.cell, fight.fighters)
	var first_slot: Dictionary = Formations.slots(shape, 1)[0]
	var expected := Formations.cell_for(first_slot["at"], caller.unit.cell, toward.unit.cell - caller.unit.cell)
	_expect(cells.has(expected), "the band's first slot is not where the %s facing the party puts it: %s" % [shape, expected])
	# A foe off its slot plans to fall in while nobody of the band is in contact; the party's slots stay its own.
	_expect(not Formations.band_in_contact(fight.fighters), "the band starts in contact")
	var tactics: Dictionary = Database.skirmish["tactics"]
	var away: Fighter = null
	for foe: Fighter in foes:
		if foe != caller and foe.unit.template_id == "brigand" \
				and Pathfinder.distance(foe.unit.cell, Formations.band_slot_cell(foe, fight.fighters)) > int(Formations.rules().get("slack", 1)):
			away = foe
			break
	if away != null:
		away.tactic_wait = 0.0
		var plan: Dictionary = SkirmishBrain.pick_tactic(away, fight.fighters, toward.unit, tactics)
		_expect(str(plan.get("why", "")) == "form", "a foe off its slot does not fall in: %s" % [plan.get("why", "nothing")])
	_expect(Formations.hold_guard(caller, fight.fighters) == 0.0, "the band's caller is guarded for a slot it has not got")
	print("foes in formation: a band of %d falls in as a %s round %s, facing the party" % [foes.size(), Formations.word(shape), caller.unit.display_name])
	fight.queue_free()
	await get_tree().process_frame


func _check_leader_and_callouts() -> void:
	var fight := await _new_fight()
	var cato := _by_template(fight, "cato")
	var vesta := _by_template(fight, "vesta")
	var iris := _by_template(fight, "iris")
	var foes: Array = fight.fighters.filter(func(f: Fighter) -> bool: return not f.is_party())
	if cato == null or vesta == null or iris == null or foes.size() < 2:
		_expect(false, "the proving ground has no company to lead")
		fight.queue_free()
		return
	var party: Array = [cato.unit.character, vesta.unit.character, iris.unit.character]
	for c: Character in party:
		c.fights = {}
		c.shared = {}
		c.thoughts = []
	_expect(Formations.leader_of(party) == null, "somebody led before winning a fight")
	Formations.record_fight(party, true)
	Formations.record_fight(party, true)
	Formations.record_fight(party, false)
	_expect(int(vesta.unit.character.fights.get("won", 0)) == 2 and int(vesta.unit.character.fights.get("lost", 0)) == 1,
			"fights not counted: %s" % [vesta.unit.character.fights])
	_expect(int(vesta.unit.character.shared.get(cato.unit.character.id, 0)) == 2, "fights shared not counted: %s" % [vesta.unit.character.shared])
	_expect(Formations.leader_of(party) == null, "two wins made a leader (from_won is %d)" % int(Formations.leader_rules().get("from_won", 3)))
	vesta.unit.character.fights["won"] = 5
	_expect(Formations.leader_of(party) == vesta.unit.character, "Vesta with the most fights won does not lead")
	# Charisma in who leads ([D338]): it lifts someone up to charisma_lift wins behind, no further, and
	# breaks a tie.
	var talker: Character = iris.unit.character
	var kept_level := talker.level
	talker.level = vesta.unit.character.level + 6
	var lift := int(Formations.leader_rules().get("charisma_lift", 2))
	talker.fights["won"] = 5 - lift
	_expect(Formations.leader_of(party) == talker, "Iris, %d behind with more Charisma, does not lead" % lift)
	talker.fights["won"] = 5 - lift - 1
	_expect(Formations.leader_of(party) == vesta.unit.character, "Charisma lifted Iris from %d wins behind" % (lift + 1))
	talker.level = vesta.unit.character.level
	talker.fights["won"] = 5
	var by_charisma := talker if Recruits.charisma(talker) > Recruits.charisma(vesta.unit.character) else vesta.unit.character
	if Recruits.charisma(talker) != Recruits.charisma(vesta.unit.character):
		_expect(Formations.leader_of(party) == by_charisma, "Charisma did not break a tie of fights won")
	talker.level = kept_level
	talker.fights["won"] = 2
	# Trust ([D339]): a companion who has no trust in the one calling the shape holds no slot.
	var cold := int(Formations.rules().get("break_below_bond", -3))
	var kept_bond := int(cato.unit.character.bonds.get(vesta.unit.character.id, 0))
	cato.unit.character.bonds[vesta.unit.character.id] = cold
	_expect(Formations.broken(cato.unit.character, vesta.unit.character), "Cato with a bond of %d to Vesta still holds her shape" % cold)
	_expect(not Formations.broken(cato.unit.character), "Cato broke a shape nobody called")
	cato.unit.character.bonds[vesta.unit.character.id] = kept_bond
	_expect(not Formations.broken(cato.unit.character, vesta.unit.character), "Cato on even terms with Vesta breaks her shape")
	# A call is an order ([D339]): those free near the one called turn on it; one told what to do does not.
	var called: Fighter = foes[0]
	iris.unit.cell = called.unit.cell + Vector2i(2, 0)
	cato.unit.cell = called.unit.cell + Vector2i(0, 2)
	cato.order = Fighter.Order.MOVE
	var answering := Formations.answer_call(vesta, called, fight.fighters)
	_expect(answering.has(iris) and not answering.has(cato), "the call turned %s" % [answering.map(func(a: Fighter) -> String: return a.unit.display_name)])
	cato.order = Fighter.Order.NONE
	_expect(Formations.leader_fighter(fight.fighters) == vesta, "the leader among the fighters is not Vesta")
	_expect(Formations.recommend(3, vesta.unit.character) == "wedge", "a mender leading did not call for a wedge: %s" % Formations.recommend(3, vesta.unit.character))
	_expect(Formations.badge(vesta.unit.character).contains("5"), "the badge does not say how many: %s" % Formations.badge(vesta.unit.character))
	var kept := GameState.formation
	GameState.formation = "auto"
	cato.unit.cell = Vector2i(6, 6)
	cato.unit.facing = Vector2i.UP
	vesta.unit.cell = Vector2i(2, 2)
	iris.unit.cell = Vector2i(9, 9)
	for other: Fighter in foes:
		other.unit.cell = Vector2i(0, 0)
	_expect(Formations.slot_cell(iris, fight.fighters) == Vector2i(7, 7), "on Auto the wedge Vesta called for did not put Iris at Cato's shoulder: %s" % Formations.slot_cell(iris, fight.fighters))
	_expect(Formations.slot_cell(vesta, fight.fighters) == Vector2i(5, 7), "Vesta's own slot in her wedge is %s" % Formations.slot_cell(vesta, fight.fighters))
	# Fights shared: a little of every blow, capped.
	var bonus := Formations.shared_bonus(vesta, fight.fighters)
	_expect(bonus > 0.0 and bonus <= float(Formations.rules().get("shared", {}).get("cap", 0.08)), "the shared bonus is %f" % bonus)
	vesta.unit.character.shared[cato.unit.character.id] = 1000
	vesta.unit.character.shared[iris.unit.character.id] = 1000
	_expect(is_equal_approx(Formations.shared_bonus(vesta, fight.fighters), float(Formations.rules().get("shared", {}).get("cap", 0.08))), "the shared bonus is not capped")
	_expect(Formations.shared_bonus(foes[0], fight.fighters) == 0.0, "a foe got the party's shared bonus")
	# At the end of their rope, nobody holds a slot.
	vesta.unit.character.thoughts = [{ "id": "test", "label": "test", "mood": -40, "until": 999999 }]
	_expect(Formations.broken(vesta.unit.character), "a mood of %d is not broken" % vesta.unit.character.mood())
	_expect(Formations.slot_cell(vesta, fight.fighters) == Formations.NONE, "Vesta at the end of her rope still held a slot")
	vesta.unit.character.thoughts = []
	# Call-outs: the leader shouts on going for a mender, and the one called is warned.
	var soft: Fighter = null
	for other: Fighter in foes:
		if Formations.is_soft(other):
			soft = other
	if soft == null:
		soft = foes[1]
		soft.heal_below = 0.9
	var word := Formations.callout(vesta, soft, fight.fighters)
	_expect(word != "", "the leader going for a soft foe said nothing")
	_expect(Formations.callout(iris, soft, fight.fighters) == "", "Iris, not leading, called out")
	_expect(Formations.callout(vesta, foes[0] if foes[0] != soft else foes[1], fight.fighters) == "" or Formations.is_soft(foes[0]), "a plain foe was called out")
	vesta.target = soft.unit
	soft.warned = 0.0
	fight._call_out(vesta)
	_expect(soft.warned > 0.0, "the foe called out was not warned")
	var tactics: Dictionary = Database.skirmish["tactics"]
	var tried := SkirmishBrain.moves(soft, tactics)
	_expect(tried.size() > 0 and str(tried[0]) == str((Formations.callout_rules().get("warned_first", []) as Array)[0]), "a warned foe does not try to get clear first: %s" % [tried])
	soft.warned = 0.0
	_expect(Formations.calls_for_its_side(foes[0], fight.fighters) or foes.any(func(f: Fighter) -> bool: return Formations.calls_for_its_side(f, fight.fighters)), "no foe calls for its side")
	print("leader: Vesta leads on %d won, calls for a %s; shared bonus %.1f%% a fight, capped at %.0f%%; \"%s\" warns the one it names for %.0f s" % [
		Formations.won(vesta.unit.character), Formations.recommend(3, vesta.unit.character),
		float(Formations.rules().get("shared", {}).get("per_fight", 0.0)) * 100.0, float(Formations.rules().get("shared", {}).get("cap", 0.0)) * 100.0,
		word, float(Formations.callout_rules().get("warned_for", 0.0))])
	GameState.formation = kept
	for c: Character in party:
		c.fights = {}
		c.shared = {}
	fight.queue_free()


## A mend grows with its caster's level ([D284]): as it was up to `heal_from_level`, more after, and
## the same for a unit with no level.
func _check_heal_growth() -> void:
	var rules: Dictionary = Database.skirmish["rules"]
	var from := int(rules["heal_from_level"])
	var early := Character.create("vesta")
	var later := Character.create("vesta")
	Progression.raise_quietly(later, 17, null)
	var early_unit := Unit.from_character(early, Unit.Team.PLAYER, Vector2i.ZERO)
	var later_unit := Unit.from_character(later, Unit.Team.PLAYER, Vector2i.ZERO)
	var plain := Unit.create("wolf", Unit.Team.ENEMY, Vector2i.ZERO)
	_expect(early.level <= from and is_equal_approx(AbilityResolver.heal_growth(early_unit), 1.0),
			"a level %d mend was changed: %s" % [early.level, AbilityResolver.heal_growth(early_unit)])
	var want := 1.0 + float(rules["heal_per_level"]) * float(17 - from)
	_expect(is_equal_approx(AbilityResolver.heal_growth(later_unit), want) and want > 2.0,
			"a level 17 mend heals %s times, not %s" % [AbilityResolver.heal_growth(later_unit), want])
	_expect(is_equal_approx(AbilityResolver.heal_growth(plain), 1.0), "a unit with no level mends differently")
	for unit: Unit in [early_unit, later_unit, plain]:
		unit.free()


func _standing_goblin(fight: Node2D) -> Fighter:
	for f: Fighter in fight.fighters:
		if f.unit.template_id == "goblin" and f.is_standing():
			return f
	return null


func _cut_down(fight: Node2D, killer: Fighter, foe: Fighter) -> void:
	foe.unit.hp = 1
	var swung := false
	for _try in 20:
		if fight._strike(killer, foe.unit, Database.ability(killer.basic), killer.basic):
			swung = true
			break
	_expect(swung and not foe.is_standing(), "a %s on one hit point stood" % foe.unit.display_name)


## Stances ([D195]): every card opens on Own way, the doctrine as it is; a key or a click on
## the card's word changes it; Keep away puts falling back first and leaves out circling,
## Close in the other way round, Guard walks back to the leader, Hold keeps the ground and
## H again lets go. A stance is kept on the character for the next fight and in the save,
## and Auto fights everyone their own way whatever their card says.
func _check_stances() -> void:
	# The touch check held the lead, and a stance is kept: start this one from Own way.
	for character: Character in GameState.party_characters():
		character.stance = "own"
	var fight: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
	fight.boot_payload = {"encounter": {"map": _proving_ground()}, "sandbox": true}
	add_child(fight)
	await get_tree().process_frame
	var tactics: Dictionary = Database.skirmish["tactics"]
	var party: Array[Fighter] = fight.party_fighters()
	var by_id := {}
	for f: Fighter in party:
		by_id[f.unit.template_id] = f
	_expect(by_id.has("cato") and by_id.has("vesta") and by_id.has("iris"), "the company is not Cato, Vesta and Iris")
	if not (by_id.has("cato") and by_id.has("vesta") and by_id.has("iris")):
		fight.queue_free()
		return
	var cato: Fighter = by_id["cato"]
	var vesta: Fighter = by_id["vesta"]
	var iris: Fighter = by_id["iris"]
	_expect(Fighter.stances() == ["own", "close", "away", "guard", "hold"], "the stances are not the five: %s" % str(Fighter.stances()))
	for f: Fighter in party:
		_expect(f.stance == "own", "%s opened a fight in %s, not Own way" % [f.unit.display_name, f.stance])
		_expect(SkirmishBrain.moves(f, tactics) == SkirmishBrain.doctrine(f, tactics)["moves"],
				"Own way is not %s's doctrine as it is" % f.unit.display_name)
	_expect(fight.hud._card_stances.size() == party.size() and fight.hud._card_stances[0].text == "Own way",
			"the cards do not say their stance")

	fight._select([iris])
	fight.act("stance_away")
	_expect(iris.stance == "away" and iris.unit.character.stance == "away", "Keep away did not take on Iris or her character")
	var away := SkirmishBrain.moves(iris, tactics)
	_expect(away.slice(0, 2) == ["dodge", "kite"] and not away.has("flank"), "Keep away does not put falling back first: %s" % str(away))
	fight._select([cato])
	fight.act("stance_close")
	var close := SkirmishBrain.moves(cato, tactics)
	_expect(close.slice(0, 2) == ["dodge", "flank"] and not close.has("break"), "Close in does not put circling first: %s" % str(close))
	_expect(cato.stance_says("seek"), "Close in does not go and find the fight")
	fight.hud.stance_clicked.emit(party.find(cato))
	_expect(cato.stance == "away", "a click on the card's stance did not step to the next")
	_expect(fight.hud._card_stances[party.find(cato)].text == "Keep away", "the card did not change its word")

	# Guard: Vesta, four tiles from the leader with nobody hurt, makes her way back to him.
	fight._select([vesta])
	fight.act("stance_guard")
	var foe: Fighter = fight.fighters.filter(func(f: Fighter) -> bool: return not f.is_party())[0]
	_expect(cato.unit.character.is_player, "Cato does not lead the company")
	vesta.unit.cell = cato.unit.cell + Vector2i(4, 0)
	vesta.tactic_wait = 0.0
	var back := SkirmishBrain.pick_tactic(vesta, fight.fighters, foe.unit, tactics)
	_expect(str(back.get("why", "")) == "escort", "Guard far from the leader did not go back to him: %s" % str(back))
	if str(back.get("why", "")) == "escort":
		var beside: bool = fight.pathfinder.cells_in_range(cato.unit.cell, 1, 2).any(func(c: Vector2i) -> bool: return back["goal"].call(c))
		_expect(beside and not back["goal"].call(cato.unit.cell + Vector2i(4, 0)), "Guard's walk back does not end beside the leader")
	vesta.unit.cell = cato.unit.cell + Vector2i(1, 1)
	_expect(SkirmishBrain.pick_tactic(vesta, fight.fighters, foe.unit, tactics).get("why", "") != "escort",
			"Guard beside the leader still walked back to him")

	# Hold, as H always did; H again is Own way.
	fight.act("hold")
	_expect(vesta.stance == "hold" and vesta.holding() and vesta.activity() == "holding", "H did not hold Vesta")
	_expect(fight.hud._card_stances[party.find(vesta)].text == "Hold", "the card does not say Hold")

	# The game playing itself: every fighter its own way, nobody held by a card.
	Pace.auto = true
	_expect(SkirmishBrain.moves(iris, tactics) == SkirmishBrain.doctrine(iris, tactics)["moves"], "Auto fought Iris to her card")
	_expect(not vesta.holding(), "Auto left Vesta holding")
	Pace.auto = false
	fight.act("hold")
	_expect(vesta.stance == "own" and not vesta.holding(), "H again did not let Vesta go")

	# Kept: the save carries it, and the next fight opens in it.
	_expect(Character.from_dict(iris.unit.character.to_dict()).stance == "away", "the save lost Iris's stance")
	fight.queue_free()
	await get_tree().process_frame
	var next: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
	next.boot_payload = {"encounter": {"map": _proving_ground()}, "sandbox": true}
	add_child(next)
	await get_tree().process_frame
	var iris_again: Array = next.party_fighters().filter(func(f: Fighter) -> bool: return f.unit.template_id == "iris")
	_expect(not iris_again.is_empty() and iris_again[0].stance == "away", "Iris's stance was not kept for the next fight")
	for f: Fighter in next.party_fighters():
		f.set_stance("own")
	next.queue_free()


## What a move does shows on whoever it lands on ([D192]): a knockback moves them a tile or more
## (fewer on a big body, none on a keeper or into a wall, and the word says so), slows, burns,
## bleeds, knockdowns and sunders stay on them with an icon and wear off, a resisted one says so,
## and a skill that comes down where a dodger stood says "Dodged!".
## Heights inside a fight ([D287], [D313]): a field with heights of its own is climbed only at a way up
## and dropped off anywhere; a body is never shoved up a ledge, and shoved off one it falls, hurt a
## share of its health a height, and lies knocked down where it lands.
func _check_heights_in_a_fight() -> void:
	var map := _proving_ground()
	var heights: Array = []
	for y in 11:
		var row := ""
		for x in 14:
			row += "1" if (y == 3 or y == 4) and (x == 4 or x == 5) else "0"
		heights.append(row)
	map["heights"] = heights
	map["ways_up"] = [[4, 4]]
	var fight: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
	fight.boot_payload = {"encounter": {"map": map}, "touch": false, "sandbox": true}
	add_child(fight)
	await get_tree().process_frame
	fight.manual = true
	fight.paused = true
	var grid: BattleGrid = fight.grid
	_expect(grid.ledged and grid.height_at(Vector2i(4, 3)) == 1 and grid.height_at(Vector2i(6, 3)) == 0, "the field did not take its heights")
	_expect(not grid.may_step(Vector2i(5, 5), Vector2i(5, 4), 1), "a fighter climbed the shelf where there is no way up")
	_expect(grid.may_step(Vector2i(4, 5), Vector2i(4, 4), 1) and grid.may_step(Vector2i(5, 4), Vector2i(5, 5), 1),
			"the slope cannot be climbed, or the shelf not dropped off")
	var nobody := func(_c: Vector2i) -> bool: return false
	var field: MoveField = fight.pathfinder.build_move_field(Vector2i(6, 3), 3, 1, nobody)
	_expect(not field.can_reach(Vector2i(5, 3)) and field.can_reach(Vector2i(6, 5)), "a move field went straight up the shelf, or not along the ground")
	var plain := _proving_ground()
	var flat := BattleGrid.new()
	flat.load_map(plain)
	_expect(not flat.ledged and flat.may_step(Vector2i(8, 2), Vector2i(9, 1), 1) and not flat.may_step(Vector2i(10, 6), Vector2i(11, 6), 0),
			"a hand-made field's heights are no longer the jump's")
	flat.free()
	var cato := _by_template(fight, "cato")
	var foes: Array = fight.fighters.filter(func(f: Fighter) -> bool: return not f.is_party())
	var foe: Fighter = foes[0]
	if cato == null or foe == null:
		_expect(false, "no Cato or no foe on the field")
		fight.queue_free()
		return
	var place := func(f: Fighter, cell: Vector2i) -> void:
		f.stepping = false
		f.unit.cell = cell
		f.unit.position = fight.grid.cell_to_world(cell)
	var tough := func(f: Fighter) -> void:
		f.unit.max_hp = 1000
		f.unit.hp = 1000
		f.conditions.clear()
		f.stunned = 0.0
	for other: Fighter in foes:
		place.call(other, Vector2i(12, 8))
	# Shoved off the shelf's edge (a kick's knockback): down a tile, a tenth of their health gone, and flat on the ground.
	place.call(cato, Vector2i(5, 3))
	place.call(foe, Vector2i(5, 4))
	tough.call(foe)
	fight.conditions.shove(cato, foe, "knockback", 1)
	_expect(foe.unit.cell == Vector2i(5, 5), "a shove at the edge did not put the foe off it: at %s" % foe.unit.cell)
	var share := float(Database.world_rules.get("heights", {}).get("shoved_off", {}).get("share", 0.1))
	_expect(foe.unit.hp == 1000 - roundi(1000.0 * share), "the fall took %d, not %d" % [1000 - foe.unit.hp, roundi(1000.0 * share)])
	_expect(foe.conditions.has("knockdown") and foe.stunned > 0.0, "the foe did not lie where he fell")
	_expect(_popped(fight, "Off the edge"), "the fall was not said over the foe")
	# Shoved at the shelf from below: pinned against it, never up.
	place.call(cato, Vector2i(5, 6))
	place.call(foe, Vector2i(5, 5))
	tough.call(foe)
	fight.conditions.shove(cato, foe, "knockback", 1)
	_expect(foe.unit.cell == Vector2i(5, 5) and foe.unit.hp == 1000, "a shove at the shelf from below moved the foe up it, or hurt him for it")
	_expect(_popped(fight, "Pinned"), "a shove into the shelf did not say Pinned")
	# A blow or a shot from the shelf lands harder ([D343]); from below, level, or on a hand-made field, no more.
	var above: Dictionary = Database.world_rules.get("heights", {}).get("from_above", {})
	var swing := { "range": 1 }
	var shot := { "range": 4 }
	_expect(is_equal_approx(fight.high_ground(Vector2i(5, 3), Vector2i(5, 5), swing), float(above.get("blow", 0.0)))
			and is_equal_approx(fight.high_ground(Vector2i(4, 3), Vector2i(4, 7), shot), float(above.get("shot", 0.0))),
			"a blow or a shot from the shelf was not counted from above")
	_expect(fight.high_ground(Vector2i(5, 5), Vector2i(5, 3), swing) == 0.0 and fight.high_ground(Vector2i(6, 5), Vector2i(7, 5), swing) == 0.0,
			"a blow upward or on level ground was counted from above")
	var heard: Array[String] = []
	var hear := func(line: String) -> void: heard.append(line)
	EventBus.battle_log.connect(hear)
	place.call(cato, Vector2i(5, 4))
	place.call(foe, Vector2i(5, 5))
	tough.call(foe)
	for _try in 6:
		if fight._strike(cato, foe.unit, Database.ability(cato.basic), cato.basic):
			break
	EventBus.battle_log.disconnect(hear)
	_expect(heard.any(func(line: String) -> bool: return line.to_lower().contains("from above")), "a blow from the shelf did not say From above: %s" % [heard])
	print("heights in a fight: a blow from a height up lands %.0f%% harder, a shot %.0f%%, up to %d heights" % [
		float(above.get("blow", 0.0)) * 100.0, float(above.get("shot", 0.0)) * 100.0, int(above.get("most_heights", 2))])
	print("heights in a fight: a kick off the edge takes %.0f%% of the body's health and lays it flat %.1f s; nothing is shoved up a ledge" % [
		share * 100.0, float(Database.world_rules.get("heights", {}).get("shoved_off", {}).get("down_seconds", 1.2))])
	fight.queue_free()
	await get_tree().process_frame


func _check_conditions() -> void:
	var fight := await _new_fight()
	fight.paused = true
	var cato := _by_template(fight, "cato")
	var foes: Array = fight.fighters.filter(func(f: Fighter) -> bool: return not f.is_party())
	var foe: Fighter = foes[0]
	var other: Fighter = foes[1]
	var line := _open_line(fight, 5, [cato, foe, other])
	_expect(not line.is_empty(), "the proving ground has no straight run of five open tiles")
	if line.is_empty() or cato == null:
		fight.queue_free()
		return
	var way: Vector2i = line[1] - line[0]
	var place := func(f: Fighter, cell: Vector2i) -> void:
		f.stepping = false
		f.unit.cell = cell
		f.unit.position = fight.grid.cell_to_world(cell)
	var tough := func(f: Fighter) -> void:
		f.unit.max_hp = 99999
		f.unit.hp = 99999
		f.conditions.clear()
		f.stunned = 0.0
	place.call(other, line[0] - way * 3)
	tough.call(foe)

	# A haymaker knocks two tiles straight back; a kick one.
	place.call(cato, line[0])
	place.call(foe, line[1])
	fight._strike(cato, foe.unit, Database.ability("haymaker"), "haymaker")
	_expect(foe.unit.cell == line[3], "a haymaker did not knock the foe two tiles back: %s, not %s" % [foe.unit.cell, line[3]])
	_expect(foe.stepping, "a knockback did not slide the foe there")
	_expect(_popped(fight, "Knocked back"), "a knockback was not said over the foe")
	place.call(foe, line[1])
	fight._strike(cato, foe.unit, Database.ability("kick"), "kick")
	_expect(foe.unit.cell == line[2], "a kick did not knock the foe back a tile")

	# Somebody behind them: pinned, and it shows.
	place.call(foe, line[1])
	place.call(other, line[2])
	fight._strike(cato, foe.unit, Database.ability("kick"), "kick")
	_expect(foe.unit.cell == line[1], "a foe was knocked back through somebody standing behind him")
	_expect(_popped(fight, "Pinned"), "a knockback into somebody did not say Pinned")
	place.call(other, line[0] - way * 3)

	# A big body is shoved a tile less; a keeper not at all.
	foe.unit.body_scale = 1.6
	fight._strike(cato, foe.unit, Database.ability("kick"), "kick")
	_expect(foe.unit.cell == line[1] and _popped(fight, "Unmoved"), "a kick moved a body as big as an ogre's, or said nothing")
	fight._strike(cato, foe.unit, Database.ability("haymaker"), "haymaker")
	_expect(foe.unit.cell == line[2], "a haymaker did not move a big body one tile")
	foe.unit.body_scale = 1.0
	place.call(foe, line[1])
	foe.unit.set_meta("boss", true)
	fight._strike(cato, foe.unit, Database.ability("haymaker"), "haymaker")
	_expect(foe.unit.cell == line[1], "a keeper was knocked back")
	foe.unit.remove_meta("boss")

	# Undertow drags them in, and slows them.
	place.call(foe, line[2])
	fight._strike(cato, foe.unit, Database.ability("undertow"), "undertow")
	_expect(foe.unit.cell == line[1], "an undertow did not drag the foe in beside the caster")
	_expect(foe.conditions.has("slow"), "an undertow did not slow")

	# Slowed: steps and swings take longer, it has an icon and frost, and it wears off.
	tough.call(foe)
	fight._strike(cato, foe.unit, Database.ability("hamstring"), "hamstring")
	_expect(fight.conditions.step_scale(foe) > 1.0 and fight.conditions.swing_scale(foe) > 1.0, "a slow did not slow")
	_expect(SkirmishMarks.status_icons(foe).has("slow"), "a slowed foe wears no slow icon")
	for _i in int(ceil(float(Database.ability("hamstring")["slow"]) / SkirmishRules.TICK)) + 2:
		fight.conditions.tick(foe)
	_expect(not foe.conditions.has("slow"), "a slow never wore off")

	# Burning and bleeding bite every second, with their own numbers.
	tough.call(foe)
	fight._strike(cato, foe.unit, Database.ability("ember"), "ember")
	_expect(foe.conditions.has("burn") and SkirmishMarks.status_icons(foe).has("burn"), "an ember left no burn, or no burn icon")
	var before := foe.unit.hp
	for _i in int(ceil(1.0 / SkirmishRules.TICK)) + 1:
		fight.conditions.tick(foe)
	_expect(foe.unit.hp < before, "a burn did not bite")
	fight._strike(cato, foe.unit, Database.ability("dart"), "dart")
	_expect(foe.conditions.has("bleed") and SkirmishMarks.status_icons(foe).has("bleed"), "a dart left no bleed")

	# Sundered: takes more, with the cracked-guard icon.
	tough.call(foe)
	fight._strike(cato, foe.unit, Database.ability("sunder"), "sunder")
	_expect(fight.conditions.taken_scale(foe) > 1.0 and SkirmishMarks.status_icons(foe).has("vulnerable"), "a sunder left nothing")

	# Knocked down: stunned, laid flat, and back up after.
	tough.call(foe)
	fight._strike(cato, foe.unit, Database.ability("earthshake"), "earthshake")
	_expect(foe.is_stunned() and foe.conditions.has("knockdown"), "an earthshake did not knock the foe down")
	_expect(SkirmishMarks.status_icons(foe) == (["down"] as Array[String]), "a knocked-down foe wears %s" % str(SkirmishMarks.status_icons(foe)))
	for _i in 6:
		fight._tick_fighter(foe)
	_expect(is_equal_approx(foe.unit.lying, 1.0), "a knocked-down foe is not drawn lying flat")
	for _i in int(ceil(float(Database.ability("earthshake")["knockdown"]) / SkirmishRules.TICK)) + 8:
		fight._tick_fighter(foe)
	_expect(not foe.conditions.has("knockdown") and foe.unit.lying == 0.0, "a knocked-down foe never got up")

	# Shrugged off: Liber's bare hands keep their feet, a fire creature will not burn.
	tough.call(foe)
	foe.signature = {"style": "bare_hands"}
	fight._strike(cato, foe.unit, Database.ability("earthshake"), "earthshake")
	_expect(not foe.is_stunned() and _popped(fight, "Keeps footing"), "bare hands were knocked down, or said nothing")
	foe.signature = {}
	foe.unit.template_id = "flame_lion"
	fight._strike(cato, foe.unit, Database.ability("ember"), "ember")
	_expect(not foe.conditions.has("burn") and _popped(fight, "Fireproof"), "a flame lion burned, or said nothing")
	foe.unit.template_id = "brigand"

	# A plain swing never carries the move's condition, even when it is the same move.
	tough.call(foe)
	var kept_basic := cato.basic
	cato.basic = "hamstring"
	fight._strike(cato, foe.unit, Database.ability("hamstring"), "hamstring")
	_expect(not foe.conditions.has("slow"), "a plain swing carried a slow")
	cato.basic = kept_basic

	# Stepping out of a wind-up shows, and so does a skill on empty ground.
	fight.conditions.dodging(foe, cato)
	var hits: Array[Unit] = []
	fight.conditions.came_down(cato, hits)
	_expect(_popped(fight, "Dodged!") and foe.dodging.is_empty(), "a dodged skill did not say Dodged!")
	fight.conditions.show_miss(line[4])
	_expect(_popped(fight, "Missed"), "a skill on empty ground did not say Missed")

	# The tooltip says it, and every new icon is on disk.
	_expect(not SkirmishConditions.tips(Database.ability("haymaker")).is_empty(), "Haymaker's tooltip does not say it knocks back")
	for key: String in ["down", "slowed", "burning", "bleeding", "exposed"]:
		_expect(SkirmishFx.status_icon(str(Database.skirmish["status_icons"][key])) != null, "no icon for %s" % key)
	fight.queue_free()


## [param length] open tiles in a straight line, nobody on them but [param besides].
func _open_line(fight: Node2D, length: int, besides: Array) -> Array:
	for cell: Vector2i in fight.grid._terrain_ids.keys():
		for way: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var out: Array = []
			for k in length:
				var c: Vector2i = cell + way * k
				var who: Fighter = fight.occupant(c)
				if not fight.grid.is_walkable(c) or (who != null and not besides.has(who)) \
						or (k > 0 and absi(fight.grid.height_at(c) - fight.grid.height_at(c - way)) > 0):
					break
				out.append(c)
			if out.size() == length:
				return out
	return []


## Into the clouds ([D287]: "a fall there is death"; [D321]): a body shoved into a cloud cell below a
## mountain's top goes over and is gone, a foe dead and credited to whoever shoved it, one of the company
## out of the fight; a fall into the clouds has nobody to pull them back and nobody to take them.
func _check_into_the_clouds() -> void:
	var map := _proving_ground()
	var rows: Array = map["tiles"]
	rows[3] = str(rows[3]).substr(0, 9) + "#" + str(rows[3]).substr(10)
	map["tiles"] = rows
	map["heights"] = rows.map(func(_r: String) -> String: return "00000000000000")
	map["ways_up"] = []
	map["clouds"] = [[9, 3]]
	var fight: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
	fight.boot_payload = {"encounter": {"map": map}, "touch": false, "sandbox": true}
	add_child(fight)
	await get_tree().process_frame
	fight.manual = true
	fight.paused = true
	var grid: BattleGrid = fight.grid
	_expect(grid.clouds.has(Vector2i(9, 3)) and not grid.is_walkable(Vector2i(9, 3)), "the field did not take its clouds, or they can be stood on")
	var cato := _by_template(fight, "cato")
	var foes: Array = fight.fighters.filter(func(f: Fighter) -> bool: return not f.is_party())
	if cato == null or foes.size() < 2:
		_expect(false, "no Cato or too few foes on the field")
		fight.queue_free()
		return
	var place := func(f: Fighter, cell: Vector2i) -> void:
		f.stepping = false
		f.unit.cell = cell
		f.unit.position = fight.grid.cell_to_world(cell)
	for other: Fighter in foes:
		place.call(other, Vector2i(12, 8))
	var foe: Fighter = foes[0]
	foe.unit.max_hp = 1000
	foe.unit.hp = 1000
	place.call(cato, Vector2i(7, 3))
	place.call(foe, Vector2i(8, 3))
	fight.conditions.shove(cato, foe, "knockback", 2)
	_expect(foe.fallen and not foe.unit.is_alive() and foe.unit.cell == Vector2i(9, 3), "a foe shoved into the clouds is not gone: fallen %s, at %s" % [foe.fallen, foe.unit.cell])
	_expect(_popped(fight, "Into the clouds"), "going over into the clouds was not said")
	# One of the company goes over the same way, and is out of it.
	var shover: Fighter = foes[1]
	place.call(shover, Vector2i(7, 3))
	place.call(cato, Vector2i(8, 3))
	cato.conditions.clear()
	cato.stunned = 0.0
	fight.conditions.shove(shover, cato, "knockback", 1)
	_expect(cato.fallen and not cato.is_standing() and not cato.is_downed(), "Cato went into the clouds and is still in the fight, or lies there to be reached")
	# Nobody takes a body out of the clouds.
	var who: Character = GameState.party_characters()[0] if not GameState.party_characters().is_empty() else null
	if who != null:
		_expect(not Fate.graces_for(who, {"allies": [], "no_capture": true}).any(func(g: Dictionary) -> bool: return g["reason"] == Fate.BY_CAPTURE),
				"a fall into the clouds can still end with being taken alive")
	print("into the clouds: shoved over the edge of a mountain's top, a foe is dead and one of the company out of the fight")
	fight.queue_free()
	await get_tree().process_frame


## A model's plans, written offline ([D298], [D322]): every fighter's situation is five words the table
## knows; with no side named the table gives nothing, and with the company's side named a company fighter
## gets the table's move and a foe does not.
func _check_plan_table() -> void:
	var fight: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
	fight.boot_payload = {"encounter": {"map": _proving_ground()}, "touch": false, "sandbox": true}
	add_child(fight)
	await get_tree().process_frame
	fight.paused = true
	var tactics: Dictionary = Database.skirmish.get("tactics", {})
	var table: Dictionary = tactics.get("plan_table", {})
	var moves: Dictionary = table.get("moves", {})
	_expect(moves.size() == 72 and str(table.get("side", "x")) == "", "the plan table has %d situations, or is switched on" % moves.size())
	var ours: Fighter = null
	var theirs: Fighter = null
	for f: Fighter in fight.fighters:
		_expect(moves.has(SkirmishBrain.situation(f, fight.fighters, tactics)), "no plan for the situation %s" % SkirmishBrain.situation(f, fight.fighters, tactics))
		if f.is_party() and ours == null:
			ours = f
		elif not f.is_party() and theirs == null:
			theirs = f
	_expect(SkirmishBrain.table_move(ours, fight.fighters, tactics) == "", "the plan table gave a move while switched off")
	table["side"] = "party"
	var given: String = SkirmishBrain.table_move(ours, fight.fighters, tactics)
	_expect(given != "" and given == str(moves[SkirmishBrain.situation(ours, fight.fighters, tactics)]) and SkirmishBrain.table_move(theirs, fight.fighters, tactics) == "",
			"the table switched on for the company gave %s to its fighter, or a move to a foe" % given)
	table["side"] = ""
	print("plan table: %d situations; switched on for the company, %s gets %s" % [moves.size(), ours.unit.display_name, given])
	fight.queue_free()
	await get_tree().process_frame


func _popped(fight: Node2D, text: String) -> bool:
	return fight.fx._popups.any(func(p: Dictionary) -> bool: return str(p["text"]) == text)


## D272 (call BQ): a foe of the ground gets some of every blow past armour; a fight on the ground
## turns once, the first time one of the company is badly hurt, and asks stand, pull back or break
## off; breaking off throws down silver and sends everyone for the edge; Auto fights on.
func _check_the_turn() -> void:
	var fight := await _new_fight()
	var cato := _by_template(fight, "cato")
	var foe: Fighter = fight.fighters.filter(func(f: Fighter) -> bool: return not f.is_party())[0]
	cato.unit.defense = 9999
	var before := cato.unit.hp
	AbilityResolver.apply(foe.unit, {"power": 1.0}, cato.unit)
	_expect(before - cato.unit.hp == 1, "armour no blow gets past took %d" % (before - cato.unit.hp))
	foe.unit.set_meta("graze", 0.5)
	before = cato.unit.hp
	AbilityResolver.apply(foe.unit, {"power": 1.0}, cato.unit)
	_expect(before - cato.unit.hp >= maxi(2, floori(foe.unit.attack * 0.4)),
		"a grazing blow of %d took %d through armour" % [foe.unit.attack, before - cato.unit.hp])
	cato.unit.defense = 0
	fight.queue_free()

	var auto_was := Pace.auto
	var gold_was := GameState.gold
	Pace.auto = false
	GameState.gold = 1000
	var choices_seen: Array = []
	for choice: String in ["break", "pull", "stand"]:
		fight = await _new_fight()
		fight.ground_fight = true
		fight.in_place = true
		cato = _by_template(fight, "cato")
		cato.unit.take_damage(cato.unit.hp - roundi(cato.unit.max_hp * 0.2))
		_expect(fight.turning == cato and fight.paused and fight.hud.turn_showing(),
			"the fight did not turn on %s at a fifth of their health" % cato.unit.display_name)
		choices_seen = fight.turn_choices().map(func(c: Dictionary) -> String: return str(c["id"]))
		_expect(choices_seen == ["stand", "pull", "break"], "the turned fight offers %s" % [choices_seen])
		var thrown: int = fight._dropped()
		var gold_before := GameState.gold
		fight.choose_turn(choice)
		_expect(fight.turning == null and not fight.paused and not fight.hud.turn_showing(),
			"choosing %s left the fight stopped" % choice)
		var cleared: Array = fight.party_fighters().filter(func(f: Fighter) -> bool: return f.fled)
		match choice:
			"break":
				_expect(thrown > 0 and GameState.gold == gold_before - thrown,
					"breaking off threw down %d of %d" % [gold_before - GameState.gold, thrown])
				_expect(cleared.size() == fight.party_fighters().size(), "not everyone broke off: %d" % cleared.size())
				fight.tick()
				_expect(fight.over and fight.fled_field and not fight.victory, "breaking off did not end the fight as got clear")
			"pull":
				_expect(cleared.size() == 1 and cleared[0] == cato, "pulling %s back sent %s" % [cato.unit.display_name, cleared.map(func(f: Fighter) -> String: return f.unit.display_name)])
				_expect(GameState.gold == gold_before, "pulling back cost silver")
				fight.tick()
				_expect(not fight.over, "pulling one back ended the fight")
			"stand":
				_expect(cleared.is_empty() and GameState.gold == gold_before, "standing sent someone off or cost silver")
		# It asks once.
		var vesta := _by_template(fight, "vesta")
		if vesta != null and vesta.is_standing():
			vesta.unit.take_damage(vesta.unit.hp - 1)
			_expect(fight.turning == null, "the fight turned twice")
		fight.queue_free()

	# Auto fights on, and says so; a fight that is not the ground's never turns.
	Pace.auto = true
	fight = await _new_fight()
	fight.ground_fight = true
	fight.in_place = true
	cato = _by_template(fight, "cato")
	cato.unit.take_damage(cato.unit.hp - 1)
	_expect(fight.turned and fight.turning == null and not fight.hud.turn_showing(), "Auto stopped for the turn")
	fight.queue_free()
	Pace.auto = false
	fight = await _new_fight()
	cato = _by_template(fight, "cato")
	cato.unit.take_damage(cato.unit.hp - 1)
	_expect(not fight.turned, "a fight off the ground turned")
	fight.queue_free()
	Pace.auto = auto_was
	GameState.gold = gold_was


## D326 (call BX, play-test 8): one of the company down with nobody coming, the nearest who is
## free goes to them without being told and gets them up; the quick wheel's Stance moves whoever
## is picked on to their next stance.
func _check_reaching_the_fallen() -> void:
	var fight := await _new_fight()
	var cato := _by_template(fight, "cato")
	var vesta := _by_template(fight, "vesta")
	vesta.unit.take_damage(vesta.unit.hp)
	fight._drop(vesta)
	fight.paused = false
	cato.clear_order()
	fight.tick()
	_expect(cato.order == Fighter.Order.AID and cato.order_target == vesta.unit,
			"nobody went to Vesta when she went down (Cato %s)" % cato.activity())
	var ticks := 0
	while vesta.is_downed() and ticks < 600:
		fight.tick()
		ticks += 1
	_expect(vesta.is_standing(), "Vesta was gone to but never got up (%s)" % vesta.activity())
	fight.selected.clear()
	fight.selected.append(cato)
	var was := cato.stance
	EventBus.quick_wheel_chose.emit("stance")
	_expect(cato.stance != was, "the wheel's Stance left Cato's stance as it was")
	fight.queue_free()
	await get_tree().process_frame


## D329 (play-test 8's wolves): a fight played by hand eases a fast walk down to 2x and gives it
## back after; a speed picked in the fight is kept.
func _check_hand_fight_speed() -> void:
	Pace.reset()
	for _i in 3:
		Pace.cycle_speed()
	_expect(Pace.speed() == 5.0, "three presses did not reach 5x")
	Pace.ease_to(2.0)
	_expect(Pace.speed() == 2.0, "a hand-played fight started at %sx" % Pace.speed())
	Pace.ease_back()
	_expect(Pace.speed() == 5.0, "the walking speed did not come back after the fight (%sx)" % Pace.speed())
	Pace.ease_to(2.0)
	Pace.cycle_speed()
	Pace.ease_back()
	_expect(Pace.speed() == 3.0, "a speed picked in the fight was not kept (%sx)" % Pace.speed())
	Pace.reset()
