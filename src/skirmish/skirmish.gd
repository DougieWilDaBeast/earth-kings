extends Node2D
## The real-time fight — the M11 prototype of [D36]
## (see `docs/18-combat-direction.md` and
## `docs/investigation/07-dungeon-settlers-combat.md`).
##
## Same grid, same units, same damage maths as [Battle]; what changes is time.
## Nobody waits for a turn: units walk tile to tile at their own pace, swing
## on their own tempo, and skills come back on cooldowns. The player can pause
## at any moment and give orders while paused.
##
## A training fight only, for now: nothing is written back onto the world, and
## the party walks off healed. It sits beside [Battle] until both have been
## played and one of them chosen.

## Loaded by path, not by `class_name`: a global class name only resolves once the
## editor has rescanned the project, and a checkout that has not been opened in
## the editor since this landed would otherwise fail to parse the whole skirmish.
const Fighter := preload("res://src/skirmish/fighter.gd")
const SkirmishRules := preload("res://src/skirmish/skirmish_rules.gd")
const SkirmishBrain := preload("res://src/skirmish/skirmish_brain.gd")
const SkirmishMarks := preload("res://src/skirmish/skirmish_marks.gd")
const SkirmishHUD := preload("res://src/skirmish/skirmish_hud.gd")

signal finished(victory: bool)

const DEFAULT_MAP := "verdant_pass"
const END_SCREEN_DELAY := 2.0
## How much of the screen height the party cards take.
const HUD_SHARE := 0.24
## Most fixed ticks a single frame may run, so a hitch cannot snowball.
const MAX_TICKS_PER_FRAME := 16

## Set by [Game] before the scene enters the tree.
var boot_payload: Dictionary = {}

@onready var grid: BattleGrid = $Grid
@onready var overlay: GridOverlay = $Overlay
@onready var units_root: Node2D = $Units
@onready var marks: SkirmishMarks = $Marks
@onready var camera: CameraRig = $Camera2D
@onready var hud: SkirmishHUD = $HUD

var map_id: String = DEFAULT_MAP
var encounter: Dictionary = {}
var pathfinder: Pathfinder
var fighters: Array[Fighter] = []
## Party fighters taking orders; the first is the one quick-slot keys speak for.
var selected: Array[Fighter] = []
var paused: bool = true
var over: bool = false
var victory: bool = false
## Seconds of fight that have actually been simulated.
var sim_time: float = 0.0
## Set by tests, which call [method tick] themselves instead of waiting on frames.
var manual: bool = false

## The quick slot waiting for a left-click to say where it goes; -1 when none.
var armed_slot: int = -1

var _accumulator: float = 0.0


func _ready() -> void:
	map_id = str(boot_payload.get("map_id", DEFAULT_MAP))
	encounter = boot_payload.get("encounter", {})
	# Nothing done in here belongs in the run's ledger.
	GameState.tallying = false
	paused = bool(boot_payload.get("paused", true))
	_build_battlefield()
	marks.skirmish = self
	hud.setup(self)
	hud.card_clicked.connect(_on_card_clicked)
	var party := party_fighters()
	if not party.is_empty():
		_select([party[0]])
	_say("A real-time skirmish. The fight is paused — Space to begin." if paused \
			else "A real-time skirmish.")
	EventBus.battle_started.emit(map_id)


func _exit_tree() -> void:
	GameState.tallying = true


# --- setup -------------------------------------------------------------------


func _build_battlefield() -> void:
	var map: Dictionary = encounter.get("map", {}) if not encounter.is_empty() else Database.map(map_id)
	grid.load_map(map)
	overlay.grid = grid
	pathfinder = Pathfinder.new(grid)
	# The party cards cover the bottom of the screen, so the camera frames the
	# field with that much empty ground below it and the whole fight sits above.
	var field := Vector2(grid.width, grid.height) * BattleGrid.CELL_SIZE
	var framed := Rect2(Vector2.ZERO, Vector2(field.x, field.y / (1.0 - HUD_SHARE)))
	camera.frame(framed)
	camera.focus_on(framed.get_center(), true)
	units_root.y_sort_enabled = true

	var spawns: Array = map.get("player_spawns", [])
	var members := GameState.party_characters()
	for i in mini(members.size(), spawns.size()):
		_enlist(Unit.from_character(members[i], Unit.Team.PLAYER, _to_cell(spawns[i])))
	for entry: Dictionary in map.get("enemies", []):
		var cell := _to_cell(entry.get("cell", [0, 0]))
		var level := int(entry.get("level", 0))
		if level <= 0:
			_enlist(Unit.create(str(entry.get("unit", "")), Unit.Team.ENEMY, cell))
			continue
		var foe := Character.create(str(entry.get("unit", "")))
		Progression.raise_quietly(foe, level, GameState.world)
		_enlist(Unit.from_character(foe, Unit.Team.ENEMY, cell))
	_face_the_other_side()


func _enlist(unit: Unit) -> void:
	# Wounds carry in as a share, so a hurt party starts the fight as hurt.
	var share := float(unit.hp) / float(maxi(1, unit.max_hp))
	unit.max_hp = roundi(float(unit.max_hp) * SkirmishRules.HEALTH_SCALE)
	unit.hp = maxi(1, roundi(share * float(unit.max_hp)))
	unit.snap_to_cell(grid)
	units_root.add_child(unit)
	fighters.append(Fighter.new(unit))


## Both lines start looking at each other, as in [Battle].
func _face_the_other_side() -> void:
	for f in fighters:
		var centre := Vector2.ZERO
		var count := 0
		for other in fighters:
			if other.unit.is_hostile_to(f.unit):
				centre += Vector2(other.unit.cell)
				count += 1
		if count > 0:
			f.unit.face_towards(Vector2i((centre / float(count)).round()))


# --- the clock ---------------------------------------------------------------


func _process(delta: float) -> void:
	if not manual and not paused and not over:
		# Engine.time_scale already folds the game speed into delta.
		_accumulator += delta
		var ticks := 0
		while _accumulator >= SkirmishRules.TICK and ticks < MAX_TICKS_PER_FRAME:
			tick()
			_accumulator -= SkirmishRules.TICK
			ticks += 1
		if ticks == MAX_TICKS_PER_FRAME:
			_accumulator = 0.0
	_place_steppers()
	marks.queue_redraw()
	hud.refresh()


func set_paused(value: bool) -> void:
	if over:
		return
	paused = value
	_accumulator = 0.0
	hud.refresh()


## One fixed step of the fight.
func tick() -> void:
	if over:
		return
	sim_time += SkirmishRules.TICK
	for f in fighters:
		_tick_fighter(f)
	_check_end()


## Units between tiles are drawn part-way along, using whatever part of a tick
## has built up, so movement is smooth at any frame rate.
func _place_steppers() -> void:
	for f in fighters:
		if not f.stepping:
			continue
		var left := maxf(0.0, f.step_left - _accumulator)
		var t := 1.0 - left / maxf(0.001, f.step_total)
		f.unit.position = f.step_from.lerp(f.step_to, clampf(t, 0.0, 1.0))


func _tick_fighter(f: Fighter) -> void:
	if f.fallen:
		return
	for i in f.cooldowns.size():
		f.cooldowns[i] = maxf(0.0, f.cooldowns[i] - SkirmishRules.TICK)
	if f.is_downed():
		f.near_death -= SkirmishRules.TICK
		if f.near_death <= 0.0:
			_fall(f)
		return
	f.attack_timer = maxf(0.0, f.attack_timer - SkirmishRules.TICK)

	if f.stepping:
		f.step_left -= SkirmishRules.TICK
		if f.step_left > 0.0:
			return
		f.stepping = false
		f.unit.position = f.step_to
		f.unit.set_running(false)

	if f.is_casting():
		f.cast["left"] = float(f.cast["left"]) - SkirmishRules.TICK
		if float(f.cast["left"]) <= 0.0:
			_release(f)
		return

	if f.aiding > 0.0:
		_keep_aiding(f)
		return

	f.think_timer -= SkirmishRules.TICK
	if f.think_timer <= 0.0:
		f.think_timer = SkirmishRules.THINK_INTERVAL
		if _think(f):
			return

	match f.order:
		Fighter.Order.MOVE:
			_pursue_move(f)
		Fighter.Order.ATTACK:
			var foe := f.order_target
			if not is_standing(foe):
				f.clear_order()
				f.target = null
			else:
				_fight(f, foe, true)
		Fighter.Order.CAST:
			_pursue_cast(f)
		Fighter.Order.AID:
			_pursue_aid(f)
		_:
			if f.target != null and is_standing(f.target):
				_fight(f, f.target, not f.hold)


## Reconsider: use a ready skill if Auto Skill is on, and pick who to swing at.
## Returns true if the fighter started something that takes the rest of the tick.
func _think(f: Fighter) -> bool:
	var free_hand := f.order == Fighter.Order.NONE or f.order == Fighter.Order.ATTACK
	if f.auto_skill and free_hand:
		var plan := SkirmishBrain.pick_skill(f, fighters)
		if not plan.is_empty():
			var who: Unit = plan["target"]
			_begin_cast(f, int(plan["slot"]), who, who.cell)
			return true
	if f.order == Fighter.Order.NONE:
		var reach := -1
		if f.is_party():
			reach = _basic_reach(f) if f.hold else SkirmishRules.PARTY_AGGRO_RANGE
		f.target = SkirmishBrain.pick_target(f, fighters, reach)
		# The company fights together: once one of them is in it, the rest
		# come, unless told to hold.
		if f.target == null and f.is_party() and not f.hold and _party_engaged():
			f.target = SkirmishBrain.pick_target(f, fighters)
	return false


func _party_engaged() -> bool:
	return fighters.any(func(other: Fighter) -> bool:
		return other.is_party() and other.is_standing() and other.target != null \
				and is_standing(other.target))


# --- doing things ------------------------------------------------------------


## Swing at [param foe] if it is in reach, otherwise walk into reach if allowed.
func _fight(f: Fighter, foe: Unit, may_walk: bool) -> void:
	var ability := Database.ability(f.basic)
	if AbilityResolver.in_range(ability, f.unit.cell, foe.cell):
		if f.attack_timer <= 0.0:
			_swing(f, foe, ability)
		else:
			f.unit.face_towards(foe.cell)
	elif may_walk:
		_step_towards(f, func(c: Vector2i) -> bool:
			return AbilityResolver.in_range(ability, c, foe.cell))


func _swing(f: Fighter, foe: Unit, ability: Dictionary) -> void:
	f.unit.face_towards(foe.cell)
	_say(AbilityResolver.apply(f.unit, ability, foe, f.basic))
	f.swings += 1
	f.attack_timer = SkirmishRules.attack_interval(f.unit)
	if not foe.is_alive():
		_drop(fighter_of(foe))


func _pursue_move(f: Fighter) -> void:
	if f.unit.cell == f.order_cell:
		f.clear_order()
		return
	var goal := f.order_cell
	# Someone got there first: stop beside them rather than circling forever.
	if occupant(goal, f) != null and Pathfinder.distance(f.unit.cell, goal) <= 1:
		f.clear_order()
		return
	if not _step_towards(f, func(c: Vector2i) -> bool: return c == goal):
		f.clear_order()


func _pursue_cast(f: Fighter) -> void:
	var slot := f.order_slot
	var ability := f.slot_ability(slot)
	var who := f.order_target
	if ability.is_empty() or (who != null and not is_standing(who)):
		f.clear_order()
		return
	var centre := who.cell if who != null else f.order_cell
	if AbilityResolver.in_range(ability, f.unit.cell, centre) or (who == f.unit):
		# In reach: wait for the slot to come back if it has to, then let it go.
		if f.slot_ready(slot):
			_begin_cast(f, slot, who, centre)
		else:
			f.unit.face_towards(centre)
		return
	if not _step_towards(f, func(c: Vector2i) -> bool:
			return AbilityResolver.in_range(ability, c, centre)):
		f.clear_order()


func _pursue_aid(f: Fighter) -> void:
	var patient := fighter_of(f.order_target)
	if patient == null or not patient.is_downed():
		f.clear_order()
		return
	if Pathfinder.distance(f.unit.cell, patient.unit.cell) == 1:
		f.aiding = SkirmishRules.AID_TIME
		f.unit.face_towards(patient.unit.cell)
		_say("%s kneels beside %s." % [f.unit.display_name, patient.unit.display_name])
		return
	var at := patient.unit.cell
	if not _step_towards(f, func(c: Vector2i) -> bool: return Pathfinder.distance(c, at) == 1):
		f.clear_order()


func _keep_aiding(f: Fighter) -> void:
	var patient := fighter_of(f.order_target)
	if patient == null or not patient.is_downed():
		f.aiding = 0.0
		f.clear_order()
		return
	f.aiding -= SkirmishRules.TICK
	if f.aiding > 0.0:
		return
	f.aiding = 0.0
	f.clear_order()
	patient.near_death = 0.0
	patient.unit.hp = maxi(1, roundi(float(patient.unit.max_hp) * SkirmishRules.AID_HEALTH))
	patient.unit.modulate = Color.WHITE
	patient.unit.queue_redraw()
	patient.attack_timer = 1.0
	_say("%s gets %s back on their feet." % [f.unit.display_name, patient.unit.display_name])


## Take one step along the cheapest walk to a cell [param is_goal] accepts.
## Returns false when there is no way there at all. A step that is blocked this
## instant is not a failure — the fighter waits and tries again next tick.
func _step_towards(f: Fighter, is_goal: Callable) -> bool:
	var me := f.unit
	var blocked := func(c: Vector2i) -> bool: return occupant(c, f) != null
	var path := pathfinder.path_to_nearest(me.cell, me.jump, blocked, is_goal)
	if path.is_empty():
		# Boxed in by friends: plan through them and wait for them to move.
		var hostile_only := func(c: Vector2i) -> bool:
			var other := occupant(c, f)
			return other != null and other.unit.is_hostile_to(me)
		path = pathfinder.path_to_nearest(me.cell, me.jump, hostile_only, is_goal)
		if path.is_empty():
			return false
	var next: Vector2i = path[0]
	if occupant(next, f) != null:
		return true
	f.stepping = true
	f.step_from = me.position
	f.step_to = grid.cell_to_world(next)
	f.step_total = SkirmishRules.step_time(me, grid, next)
	f.step_left = f.step_total
	me.facing = Unit.dominant_direction(next - me.cell)
	# The tile is claimed as the step begins, so nobody else walks into it.
	me.cell = next
	me.set_running(true)
	return true


func _begin_cast(f: Fighter, slot: int, who: Unit, centre: Vector2i) -> void:
	var ability := f.slot_ability(slot)
	var wind_up := SkirmishRules.cast_time(ability)
	f.unit.face_towards(centre)
	if wind_up <= 0.0:
		_land(f, slot, who, centre)
		return
	f.cast = {"slot": slot, "target": who, "cell": centre, "left": wind_up, "total": wind_up}


func _release(f: Fighter) -> void:
	var slot := int(f.cast["slot"])
	var who: Unit = f.cast["target"]
	var centre: Vector2i = f.cast["cell"]
	f.cast = {}
	var ability := f.slot_ability(slot)
	if who != null:
		# A skill aimed at someone follows them, but not out of reach and not
		# onto the fallen.
		if not is_standing(who) or Pathfinder.distance(f.unit.cell, who.cell) > int(ability.get("range", 1)) + 1:
			f.cooldowns[slot] = SkirmishRules.cooldown(ability) * 0.5
			_say("%s's %s finds nobody there." % [f.unit.display_name, ability.get("display_name", "skill")])
			if f.order == Fighter.Order.CAST:
				f.clear_order()
			return
		centre = who.cell
	_land(f, slot, who, centre)


func _land(f: Fighter, slot: int, _who: Unit, centre: Vector2i) -> void:
	var ability_id := f.slots[slot]
	var ability := Database.ability(ability_id)
	var hits: Array[Unit] = []
	for cell in AbilityResolver.affected_cells(ability, centre):
		var target := _unit_at(cell)
		if target != null and AbilityResolver.is_valid_target(f.unit, ability, target):
			hits.append(target)
	f.cooldowns[slot] = SkirmishRules.cooldown(ability)
	f.casts += 1
	f.attack_timer = maxf(f.attack_timer, 0.4)
	if f.order == Fighter.Order.CAST:
		f.clear_order()
	if hits.is_empty():
		_say("%s's %s hits nothing." % [f.unit.display_name, ability.get("display_name", "skill")])
		return
	for target in hits:
		_say(AbilityResolver.apply(f.unit, ability, target, ability_id))
		if not target.is_alive():
			_drop(fighter_of(target))


## Someone just hit zero. The party goes down and can still be reached; the
## other side is simply gone.
func _drop(f: Fighter) -> void:
	if f == null or f.fallen or f.is_downed():
		return
	f.stepping = false
	f.cast = {}
	f.aiding = 0.0
	f.clear_order()
	f.target = null
	f.unit.set_running(false)
	f.unit.position = grid.cell_to_world(f.unit.cell)
	selected.erase(f)
	if f.is_party():
		f.near_death = SkirmishRules.NEAR_DEATH
		f.unit.modulate = Color(0.75, 0.55, 0.55, 0.8)
		_say("%s is down — %d seconds to reach them." % [f.unit.display_name, int(SkirmishRules.NEAR_DEATH)])
	else:
		f.fallen = true
		f.unit.visible = false


func _fall(f: Fighter) -> void:
	f.near_death = 0.0
	f.fallen = true
	f.unit.modulate = Color(0.35, 0.35, 0.4, 0.55)
	_say("Nobody reached %s in time." % f.unit.display_name)


func _check_end() -> void:
	var party_up := fighters.any(func(f: Fighter) -> bool: return f.is_party() and f.is_standing())
	var foes_up := fighters.any(func(f: Fighter) -> bool: return not f.is_party() and f.is_standing())
	if party_up and foes_up:
		return
	over = true
	victory = party_up
	armed_slot = -1
	overlay.clear()
	for f in fighters:
		f.unit.set_running(false)
		f.cast = {}
		if f.is_downed() and victory:
			_say("%s is carried off the field." % f.unit.display_name)
	_say("The field is yours after %.0f seconds." % sim_time if victory \
			else "The company is down after %.0f seconds." % sim_time)
	hud.show_result(victory)
	# A training fight: everyone walks off whole, and the world never hears of it.
	GameState.heal_party()
	finished.emit(victory)
	if not manual:
		_leave_the_field()


func _leave_the_field() -> void:
	await get_tree().create_timer(END_SCREEN_DELAY, true, false, true).timeout
	EventBus.request_scene.emit(str(boot_payload.get("return_scene", "training")), {})


# --- orders ------------------------------------------------------------------


func order_move(f: Fighter, cell: Vector2i) -> void:
	f.give(Fighter.Order.MOVE, cell)


func order_attack(f: Fighter, foe: Unit) -> void:
	f.give(Fighter.Order.ATTACK, foe.cell, foe)


func order_cast(f: Fighter, slot: int, who: Unit, cell: Vector2i) -> void:
	f.give(Fighter.Order.CAST, cell, who, slot)


func order_aid(f: Fighter, patient: Unit) -> void:
	f.give(Fighter.Order.AID, patient.cell, patient)


## Send everyone selected to [param cell], each to their own tile around it.
func _order_group_move(cell: Vector2i) -> void:
	var taken: Array[Vector2i] = []
	for f in selected:
		var spot := _free_cell_near(cell, taken, f)
		taken.append(spot)
		order_move(f, spot)


func _free_cell_near(cell: Vector2i, taken: Array[Vector2i], mover: Fighter) -> Vector2i:
	for radius in range(0, 4):
		for candidate in pathfinder.cells_in_range(cell, radius, radius):
			if grid.is_walkable(candidate) and not taken.has(candidate) \
					and (occupant(candidate, mover) == null):
				return candidate
	return cell


# --- input -------------------------------------------------------------------


func _unhandled_input(event: InputEvent) -> void:
	if over:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if _on_key(event):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		overlay.set_cursor(grid.world_to_cell(get_global_mouse_position()))
		return
	if event is InputEventMouseButton and event.pressed:
		var cell := grid.world_to_cell(get_global_mouse_position())
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_left_click(cell, event.shift_pressed)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_on_right_click(cell)
			get_viewport().set_input_as_handled()


func _on_key(event: InputEventKey) -> bool:
	var slot := SkirmishRules.SLOT_KEYS.find(event.keycode)
	if slot >= 0:
		_arm(slot)
		return true
	match event.keycode:
		KEY_SPACE:
			set_paused(not paused)
			_say("Paused." if paused else "")
			return true
		KEY_T:
			Pace.cycle_speed()
			return true
		KEY_TAB:
			_select(party_fighters().filter(func(f: Fighter) -> bool: return f.is_standing()))
			return true
		KEY_A:
			for f in selected:
				f.auto_skill = not f.auto_skill
			return true
		KEY_H:
			for f in selected:
				f.hold = not f.hold
				if f.hold and f.order == Fighter.Order.NONE:
					f.target = null
			return true
		KEY_ESCAPE:
			if armed_slot >= 0:
				_disarm()
			else:
				EventBus.system_menu_requested.emit()
			return true
	if event.keycode >= KEY_1 and event.keycode <= KEY_9:
		var party := party_fighters()
		var index := event.keycode - KEY_1
		if index < party.size() and party[index].is_standing():
			if event.shift_pressed:
				_select(selected + [party[index]])
			else:
				_select([party[index]])
		return true
	return false


func _on_left_click(cell: Vector2i, adding: bool) -> void:
	var who := _unit_at(cell)
	if armed_slot >= 0 and not selected.is_empty():
		var caster := selected[0]
		var ability := caster.slot_ability(armed_slot)
		var aimed_at_someone := who != null and AbilityResolver.is_valid_target(caster.unit, ability, who)
		var aimed_at_ground := who == null and int(ability.get("splash", 0)) > 0 and grid.in_bounds(cell)
		if aimed_at_someone or aimed_at_ground:
			order_cast(caster, armed_slot, who if aimed_at_someone else null, cell)
			_disarm()
		return
	var clicked := fighter_of(who)
	if clicked != null and clicked.is_party() and clicked.is_standing():
		_select(selected + [clicked] if adding else [clicked])


func _on_right_click(cell: Vector2i) -> void:
	if armed_slot >= 0:
		_disarm()
		return
	if selected.is_empty():
		return
	var who := _unit_at_or_downed(cell)
	var clicked := fighter_of(who)
	if clicked != null and not clicked.is_party() and clicked.is_standing():
		for f in selected:
			order_attack(f, clicked.unit)
		return
	if clicked != null and clicked.is_party() and clicked.is_downed():
		order_aid(_nearest_of(selected, cell), clicked.unit)
		return
	if grid.is_walkable(cell):
		_order_group_move(cell)


func _on_card_clicked(index: int) -> void:
	var party := party_fighters()
	if index < party.size() and party[index].is_standing():
		_select([party[index]])


func _arm(slot: int) -> void:
	if selected.is_empty():
		return
	var caster := selected[0]
	if slot >= caster.slots.size():
		return
	var ability := caster.slot_ability(slot)
	if str(ability.get("target", "enemy")) == "self":
		order_cast(caster, slot, caster.unit, caster.unit.cell)
		return
	armed_slot = slot
	overlay.clear()
	overlay.action_cells = pathfinder.cells_in_range(
		caster.unit.cell, int(ability.get("min_range", 1)), int(ability.get("range", 1))
	)
	overlay.queue_redraw()


func _disarm() -> void:
	armed_slot = -1
	overlay.clear()


func _select(group: Array) -> void:
	var clean: Array[Fighter] = []
	for f: Fighter in group:
		if f != null and f.is_party() and f.is_standing() and not clean.has(f):
			clean.append(f)
	selected = clean
	if armed_slot >= 0:
		_disarm()


# --- queries -----------------------------------------------------------------


func party_fighters() -> Array[Fighter]:
	return fighters.filter(func(f: Fighter) -> bool: return f.is_party())


func fighter_of(unit: Unit) -> Fighter:
	if unit == null:
		return null
	for f in fighters:
		if f.unit == unit:
			return f
	return null


func is_standing(unit: Unit) -> bool:
	var f := fighter_of(unit)
	return f != null and f.is_standing()


## Whoever is on, or stepping onto, [param cell] — standing or downed, but not
## the fallen — other than [param besides].
func occupant(cell: Vector2i, besides: Fighter = null) -> Fighter:
	for f in fighters:
		if f != besides and not f.fallen and f.unit.cell == cell:
			return f
	return null


func _unit_at(cell: Vector2i) -> Unit:
	for f in fighters:
		if f.is_standing() and f.unit.cell == cell:
			return f.unit
	return null


func _unit_at_or_downed(cell: Vector2i) -> Unit:
	var f := occupant(cell)
	return f.unit if f != null else null


func _basic_reach(f: Fighter) -> int:
	return int(Database.ability(f.basic).get("range", 1))


func _nearest_of(group: Array[Fighter], cell: Vector2i) -> Fighter:
	var best: Fighter = group[0]
	for f in group:
		if Pathfinder.distance(f.unit.cell, cell) < Pathfinder.distance(best.unit.cell, cell):
			best = f
	return best


func _say(line: String) -> void:
	if line == "":
		return
	hud.log_line(line)
	EventBus.battle_log.emit(line)


func _to_cell(value: Variant) -> Vector2i:
	var pair: Array = value
	return Vector2i(int(pair[0]), int(pair[1]))
