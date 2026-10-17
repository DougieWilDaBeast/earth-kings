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
const SkirmishMarks := preload("res://src/skirmish/skirmish_marks.gd")
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
	await _check_fight_rules()
	await _check_surround()
	await _check_allies_and_auto()
	await _check_the_world_hears()
	await _check_signatures()
	_check_bout()
	await _check_tactics()


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
		if Pathfinder.distance(f.unit.cell, cato.unit.cell) == 1:
			adjacent += 1
			sides[f.unit.cell - cato.unit.cell] = true
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
