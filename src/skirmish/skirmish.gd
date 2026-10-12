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
const SkirmishPassives := preload("res://src/skirmish/skirmish_passives.gd")
const SkirmishFx := preload("res://src/skirmish/skirmish_fx.gd")

signal finished(victory: bool)

const DEFAULT_MAP := "verdant_pass"
const END_SCREEN_DELAY := 2.0
## How much of the screen height the party cards take.
const HUD_SHARE := 0.24
## When the fight stops itself: never, when a party member goes down, or also
## when a skill comes back for someone the player is playing by hand.
enum AutoPause { OFF, ON_FALL, ON_FALL_AND_READY }
const AUTO_PAUSE_LABELS := ["off", "when someone goes down", "when someone goes down or a manual skill is ready"]
## Kept for the whole session, so it is set once rather than every fight.
static var auto_pause: AutoPause = AutoPause.ON_FALL

## What pops up over someone a grace has just saved, by [Fate] reason.
const GRACE_WORDS := {
	"charm": "The charm holds!", "rescue": "Pulled clear!", "lore": "Remembered!",
	"ground": "Crawls clear!", "luck": "Sheer luck!",
}

## Most fixed ticks a single frame may run, so a hitch cannot snowball.
const MAX_TICKS_PER_FRAME := 16
## A held stick walks the pad's cursor: one tile, then a run (real seconds).
const PAD_FIRST_REPEAT := 0.3
const PAD_REPEAT := 0.09

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
## Played with a thumb. There is no right button, so a tap that is not picking
## somebody gives the order a right-click would, and the keys become buttons
## down the side of the screen. Follows the touch setting unless the boot
## payload says otherwise.
var touch: bool = false

var _accumulator: float = 0.0
## Where a pad is pointing. There is no mouse on a pad, so orders are given
## at this tile instead of under a click.
var pad_cell: Vector2i = Vector2i(-1, -1)
var _pad_held: Vector2i = Vector2i.ZERO
var _pad_repeat: float = 0.0

## Numbers, flashes and rings over the field (see [SkirmishFx]).
var fx: SkirmishFx
## Rolls the graces in the near-death window. Seeded from the global seed, so a
## test that seeds the fight seeds its graces too.
var grace_rng := RandomNumberGenerator.new()
## How the next number that pops off a unit should look: "", "crit" or "thorns".
var _hit_style: String = ""
## Real seconds the clock stands still after a big hit.
var _hitstop: float = 0.0
## How hard the camera is shaking, in pixels; dies away by itself.
var _shake: float = 0.0


func _ready() -> void:
	map_id = str(boot_payload.get("map_id", DEFAULT_MAP))
	encounter = boot_payload.get("encounter", {})
	# Nothing done in here belongs in the run's ledger.
	GameState.tallying = false
	paused = bool(boot_payload.get("paused", true))
	touch = bool(boot_payload.get("touch", Pace.is_touch_enabled()))
	grace_rng.seed = randi()
	fx = SkirmishFx.new()
	fx.z_index = 20
	add_child(fx)
	_build_battlefield()
	marks.skirmish = self
	EventBus.unit_damaged.connect(_on_unit_damaged)
	EventBus.unit_healed.connect(_on_unit_healed)
	hud.setup(self)
	hud.card_clicked.connect(_on_card_clicked)
	hud.action_pressed.connect(act)
	hud.slot_clicked.connect(_on_slot_clicked)
	var party := party_fighters()
	if not party.is_empty():
		_select([party[0]])
	var begin := "tap Pause" if touch else (Pad.key("command_wait") if Pad.using_pad else "Space")
	_say("A real-time skirmish. The fight is paused — %s to begin." % begin if paused \
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
	var taken: Array[Vector2i] = []
	for entry: Dictionary in map.get("enemies", []):
		taken.append(_to_cell(entry.get("cell", [0, 0])))
	var cells := grid.muster_cells(spawns, members.size(), taken)
	for i in mini(members.size(), cells.size()):
		_enlist(Unit.from_character(members[i], Unit.Team.PLAYER, cells[i]))
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
	_feel(delta)
	if not manual and not paused and not over and _hitstop <= 0.0:
		# Engine.time_scale already folds the game speed into delta.
		_accumulator += delta
		var ticks := 0
		while _accumulator >= SkirmishRules.TICK and ticks < MAX_TICKS_PER_FRAME and not paused:
			tick()
			_accumulator -= SkirmishRules.TICK
			ticks += 1
		if ticks == MAX_TICKS_PER_FRAME:
			_accumulator = 0.0
	_place_steppers()
	_steer_pad_cursor(delta)
	marks.queue_redraw()
	hud.refresh()


## The camera shake, the hit-stop and the lunges, all on real time so a big hit
## feels the same at any game speed.
func _feel(delta: float) -> void:
	var real := delta / maxf(0.01, Engine.time_scale)
	_hitstop = maxf(0.0, _hitstop - real)
	if _shake > 0.05:
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
		_shake = lerpf(_shake, 0.0, minf(1.0, real * 9.0))
	elif camera.offset != Vector2.ZERO:
		_shake = 0.0
		camera.offset = Vector2.ZERO
	if paused or _hitstop > 0.0:
		return
	for f in fighters:
		if f.bump > 0.0:
			f.bump = maxf(0.0, f.bump - delta * 7.0)


func shake(strength: float) -> void:
	_shake = maxf(_shake, strength)


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
			if f.bump > 0.0 and not f.fallen:
				f.unit.position = grid.cell_to_world(f.unit.cell) + f.bump_dir * sin(f.bump * PI) * 9.0
			continue
		var left := maxf(0.0, f.step_left - _accumulator)
		var t := 1.0 - left / maxf(0.001, f.step_total)
		f.unit.position = f.step_from.lerp(f.step_to, clampf(t, 0.0, 1.0))


func _tick_fighter(f: Fighter) -> void:
	if f.fallen:
		return
	for i in f.cooldowns.size():
		var was := f.cooldowns[i]
		f.cooldowns[i] = maxf(0.0, was - SkirmishRules.TICK)
		if was > 0.0 and f.cooldowns[i] <= 0.0 and f.is_party() and not f.auto_skill \
				and f.is_standing() and auto_pause == AutoPause.ON_FALL_AND_READY:
			_auto_pause("%s's %s is ready." % [f.unit.display_name, f.slot_ability(i).get("display_name", "skill")])
	if f.is_downed():
		f.near_death -= SkirmishRules.TICK
		if f.near_death <= 0.0 and not _grace(f):
			_fall(f)
		return
	f.attack_timer = maxf(0.0, f.attack_timer - SkirmishRules.TICK)
	f.since_hit += SkirmishRules.TICK
	f.retreat_wait = maxf(0.0, f.retreat_wait - SkirmishRules.TICK)
	_regenerate(f)

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
	if may_walk and _keep_away(f, ability, foe):
		return
	if AbilityResolver.in_range(ability, f.unit.cell, foe.cell):
		if f.attack_timer <= 0.0:
			_swing(f, foe, ability)
		else:
			f.unit.face_towards(foe.cell)
	elif may_walk:
		# A charger sprints at anyone far enough off to build up speed.
		var role := f.role_data()
		if role.has("charge_from") and not f.charging \
				and Pathfinder.distance(f.unit.cell, foe.cell) >= int(role["charge_from"]):
			f.charging = true
			fx.popup("Charge!", f.unit.position, SkirmishFx.HURT, 15)
		_step_towards(f, func(c: Vector2i) -> bool:
			return AbilityResolver.in_range(ability, c, foe.cell))


## A skirmisher or mender with someone too close backs off a tile or two, now
## and then — not every tick, or nothing could ever pin one down. Returns true
## when it stepped away instead of fighting.
func _keep_away(f: Fighter, ability: Dictionary, foe: Unit) -> bool:
	var role := f.role_data()
	var gap := int(role.get("keep_away", 0))
	if gap <= 0 or f.retreat_wait > 0.0 or f.is_party():
		return false
	if _nearest_hostile_distance(f, f.unit.cell) >= gap:
		return false
	var reach := int(ability.get("range", 1))
	var safe := func(c: Vector2i) -> bool:
		return _nearest_hostile_distance(f, c) >= gap \
				and Pathfinder.distance(c, foe.cell) <= maxi(reach, gap + 1)
	f.retreat_wait = float(role.get("retreat_every", 3.0))
	if _step_towards(f, safe):
		fx.popup("falls back", f.unit.position, SkirmishFx.WORD, 12)
		return true
	return false


func _nearest_hostile_distance(f: Fighter, cell: Vector2i) -> int:
	var best := 999
	for other in fighters:
		if other.is_standing() and other.unit.is_hostile_to(f.unit):
			best = mini(best, Pathfinder.distance(cell, other.unit.cell))
	return best


func _swing(f: Fighter, foe: Unit, ability: Dictionary) -> void:
	f.unit.face_towards(foe.cell)
	_strike(f, foe, ability, f.basic)
	f.swings += 1
	f.attack_timer = SkirmishRules.attack_interval(f.unit) * (1.0 - minf(0.5, _aura(f, "haste")))
	# Echo Blade: now and then the same swing comes round again.
	var echo := f.effect("echo")
	if echo > 0.0 and f.is_standing() and is_standing(foe) and randf() < echo:
		fx.popup("Again!", f.unit.position, SkirmishFx.WORD, 13)
		_strike(f, foe, ability, f.basic)


## One blow or one heal from [param f] onto [param target], with everything the
## passives add around [method AbilityResolver.apply]: criticals, flank and
## last-stand bonuses, a charge, guard auras, lifesteal and thorns.
func _strike(f: Fighter, target: Unit, ability: Dictionary, ability_id: String) -> void:
	if bool(ability.get("heal", false)):
		_say(AbilityResolver.apply(f.unit, ability, target, ability_id))
		return
	var victim := fighter_of(target)
	var multiplier := 1.0
	var tags: Array[String] = []
	var crit := randf() < SkirmishPassives.rule("base_crit", 0.05) + f.effect("crit")
	if crit:
		multiplier *= SkirmishPassives.rule("crit_multiplier", 1.6)
		tags.append("critical")
	var flank_bonus := f.effect("flank_bonus")
	if flank_bonus > 0.0 and AbilityResolver.flank_of(f.unit.cell, target) != AbilityResolver.Flank.FRONT:
		multiplier *= 1.0 + flank_bonus
	for p: Dictionary in f.passives:
		if str(p.get("effect", "")) == "last_stand" \
				and float(f.unit.hp) <= float(f.unit.max_hp) * float(p.get("threshold", 0.35)):
			multiplier *= 1.0 + float(p.get("value", 0.0))
			tags.append("last stand")
	if f.charging:
		f.charging = false
		multiplier *= 1.0 + float(f.role_data().get("charge_bonus", 0.0))
		tags.append("charge")
	if victim != null:
		multiplier *= 1.0 - minf(SkirmishPassives.rule("guard_cap", 0.5), _aura(victim, "guard"))
	# The resolver prices a blow off the attacker's attack, so the passives
	# lean on that for the one call and put it back.
	var own_attack := f.unit.attack
	f.unit.attack = maxi(1, roundi(float(own_attack) * multiplier))
	var before := target.hp
	_hit_style = "crit" if crit else ""
	var line := AbilityResolver.apply(f.unit, ability, target, ability_id)
	_hit_style = ""
	f.unit.attack = own_attack
	var dealt := before - target.hp
	if not tags.is_empty():
		line = "%s! %s" % [", ".join(tags).capitalize(), line]
	_say(line)
	f.since_hit = 0.0
	f.bump = 1.0
	f.bump_dir = (target.position - f.unit.position).normalized()
	if crit or dealt >= roundi(float(target.max_hp) * SkirmishPassives.rule("big_hit_share", 0.2)):
		_hitstop = maxf(_hitstop, SkirmishPassives.rule("hit_stop", 0.07))
		if crit:
			shake(SkirmishPassives.rule("shake_on_crit", 2.5))
	var steal := f.effect("lifesteal")
	if steal > 0.0 and dealt > 0 and f.unit.hp < f.unit.max_hp:
		f.unit.heal(maxi(1, roundi(float(dealt) * steal)))
	if not target.is_alive():
		_drop(victim)
	# Barbed Guard: a blow from the next tile comes partly back.
	if victim != null and dealt > 0 and Pathfinder.distance(f.unit.cell, target.cell) <= 1:
		var thorns := victim.effect("thorns")
		if thorns > 0.0 and f.unit.is_alive() and not f.is_downed():
			_hit_style = "thorns"
			f.unit.take_damage(maxi(1, roundi(float(dealt) * thorns)))
			_hit_style = ""
			if not f.unit.is_alive():
				_say("%s is cut down on %s's guard." % [f.unit.display_name, target.display_name])
				_drop(f)


## The strongest of [param stat] that any aura over [param f] grants. Auras of
## one kind do not stack, so two shieldwalls are one shieldwall.
func _aura(f: Fighter, stat: String) -> float:
	var best := 0.0
	for other in fighters:
		if not other.is_standing() or other.unit.is_hostile_to(f.unit):
			continue
		for p: Dictionary in other.passives:
			if str(p.get("effect", "")) != "aura":
				continue
			if Pathfinder.distance(other.unit.cell, f.unit.cell) > int(p.get("radius", 2)):
				continue
			best = maxf(best, float(p.get("grants", {}).get(stat, 0.0)))
	return best


## Health that comes back on its own: Catch Breath out of the fighting, and a
## Hearthglow over you at any time. Paid out a few points at a time.
func _regenerate(f: Fighter) -> void:
	if f.unit.hp >= f.unit.max_hp:
		f.regen_pool = 0.0
		return
	var rate := _aura(f, "regen")
	if f.since_hit >= SkirmishPassives.rule("out_of_combat_after", 4.0):
		rate += f.effect("regen")
	if rate <= 0.0:
		return
	f.regen_pool += rate * float(f.unit.max_hp) * SkirmishRules.TICK
	var chunk := maxf(1.0, float(f.unit.max_hp) * 0.03)
	if f.regen_pool >= chunk:
		var amount := int(f.regen_pool)
		f.regen_pool -= float(amount)
		f.unit.heal(amount)


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
	fx.ring(patient.unit.position, SkirmishFx.HEAL, 50.0)
	fx.popup("Back up!", patient.unit.position, SkirmishFx.HEAL, 16, 1.2)
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
	if f.charging:
		f.step_total /= float(f.role_data().get("pace", 1.0))
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
	fx.popup(str(ability.get("display_name", "skill")), f.unit.position + Vector2(0, -14), SkirmishFx.WORD, 13)
	for target in hits:
		if not f.is_standing():
			break
		_strike(f, target, ability, ability_id)


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
	f.charging = false
	f.bump = 0.0
	fx.ring(f.unit.position, SkirmishFx.HURT if f.is_party() else SkirmishFx.DAMAGE, 46.0)
	_mourn(f)
	if f.is_party():
		f.near_death = SkirmishRules.NEAR_DEATH
		f.unit.modulate = Color(0.75, 0.55, 0.55, 0.8)
		shake(SkirmishPassives.rule("shake_on_down", 9.0))
		fx.popup("DOWN", f.unit.position, SkirmishFx.HURT, 20, 1.4)
		_say("%s is down — %d seconds to reach them." % [f.unit.display_name, int(SkirmishRules.NEAR_DEATH)])
		if auto_pause != AutoPause.OFF:
			_auto_pause("")
	else:
		f.fallen = true
		shake(SkirmishPassives.rule("shake_on_kill", 4.0))
		# A beat to see them go, then gone.
		var unit := f.unit
		var fade := unit.create_tween()
		fade.tween_property(unit, "modulate:a", 0.0, 0.35)
		fade.tween_callback(func() -> void: unit.visible = false)


## Mourner's Haste: whoever goes down, their friends who carry it get every
## skill back at once.
func _mourn(f: Fighter) -> void:
	for other in fighters:
		if other == f or not other.is_standing() or other.unit.is_hostile_to(f.unit):
			continue
		if not other.has_effect("reset_on_ally_down"):
			continue
		for i in other.cooldowns.size():
			other.cooldowns[i] = 0.0
		fx.popup("Mourner's Haste", other.unit.position, SkirmishFx.GRACE, 13)
		_say("%s answers %s's fall: every skill is ready again." % [other.unit.display_name, f.unit.display_name])


## The near-death window has run out with nobody there. Before they are gone,
## the same graces the turn-based [Fate] rolls get their turn — a charm carried,
## a companion standing, a book read, the ground — through [method Fate.roll],
## with nothing written back: a training fight spends no charm and takes no
## prisoners. Returns true if one landed and the fighter is back up.
func _grace(f: Fighter) -> bool:
	var who := f.unit.character
	if who == null:
		return false
	var grace := Fate.roll(who, grace_context(f), grace_rng, false)
	if grace.is_empty():
		return false
	f.near_death = 0.0
	f.graces += 1
	f.unit.hp = maxi(1, roundi(float(f.unit.max_hp) * float(Database.fate.get("escape_recovery", 0.25))))
	f.unit.modulate = Color.WHITE
	f.unit.queue_redraw()
	f.attack_timer = 1.0
	f.since_hit = 0.0
	fx.ring(f.unit.position, SkirmishFx.GRACE, 60.0)
	fx.popup(GRACE_WORDS.get(grace["reason"], "Grace"), f.unit.position, SkirmishFx.GRACE, 18, 1.8)
	_say(Fate.escape_line(who, grace))
	return true


## What [Fate] needs to know about a downed fighter: who is still standing with
## them, and where in the world the fight is.
func grace_context(f: Fighter) -> Dictionary:
	var allies: Array = []
	for other in fighters:
		if other != f and other.is_party() and other.is_standing() and other.unit.character != null:
			allies.append(other.unit.character)
	var context := {"allies": allies}
	if GameState.world != null:
		context["world"] = GameState.world
		context["cell"] = GameState.world.player_cell
	return context


## The chance a grace saves [param f] if nobody reaches them, for the card.
func grace_odds(f: Fighter) -> float:
	if f.unit.character == null:
		return 0.0
	return Fate.odds(f.unit.character, grace_context(f))


## Stop the clock on the player's behalf. Tests drive the fight themselves and
## are never stopped.
func _auto_pause(why: String) -> void:
	if manual or over or paused:
		return
	paused = true
	_accumulator = 0.0
	_say("Paused. %s" % why if why != "" else "Paused.")


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
	if event is InputEventJoypadButton and event.pressed:
		if _on_pad(event):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if _on_key(event):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		var cell := grid.world_to_cell(get_global_mouse_position())
		overlay.set_cursor(cell)
		hud.inspect(fighter_of(_unit_at_or_downed(cell)))
		return
	if event is InputEventMouseButton and event.pressed:
		var cell := grid.world_to_cell(get_global_mouse_position())
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_left_click(cell, event.shift_pressed)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_on_right_click(cell)
			get_viewport().set_input_as_handled()


## Keys, said as the actions the touch buttons also send.
const KEY_ACTIONS := {
	KEY_SPACE: "pause", KEY_T: "speed", KEY_Z: "auto_pause", KEY_TAB: "all",
	KEY_A: "auto_skill", KEY_H: "hold",
}


func _on_key(event: InputEventKey) -> bool:
	var slot := SkirmishRules.SLOT_KEYS.find(event.keycode)
	if slot >= 0:
		act("slot%d" % slot)
		return true
	if KEY_ACTIONS.has(event.keycode):
		act(KEY_ACTIONS[event.keycode])
		return true
	if event.keycode == KEY_ESCAPE:
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


## A pad's buttons, said as the same orders the keys and clicks give. The
## menu (Start) is the game's own; everything else is here.
func _on_pad(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel"):
		if armed_slot >= 0:
			_disarm()
		else:
			EventBus.system_menu_requested.emit()
		return true
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_pad_confirm()
		return true
	if event.is_action_pressed("command_wait"):
		act("pause")
		return true
	if event.is_action_pressed("open_actions"):
		_pad_next_skill()
		hud.refresh()
		return true
	if event.is_action_pressed("cycle_next"):
		_pad_next_fighter()
		return true
	if event.is_action_pressed("battle_speed"):
		act("speed")
		return true
	if event.is_action_pressed("open_party"):
		act("all")
		return true
	return false


## A: what a click would have done at the cursor. A skill aimed at its own
## caster goes off at once; anything else armed is aimed at the cursor; a
## party member under it is picked; anywhere else is an order.
func _pad_confirm() -> void:
	if not grid.in_bounds(pad_cell):
		return
	if armed_slot >= 0 and not selected.is_empty():
		var caster := selected[0]
		if str(caster.slot_ability(armed_slot).get("target", "enemy")) == "self":
			order_cast(caster, armed_slot, caster.unit, caster.unit.cell)
			_disarm()
		else:
			_on_left_click(pad_cell, false)
		return
	var under := fighter_of(_unit_at(pad_cell))
	if under != null and under.is_party() and under.is_standing():
		_select([under])
		return
	_on_right_click(pad_cell)


## Y: the first picked fighter's next skill, and past the last, none. Unlike
## the keys, a skill aimed at its own caster is only armed here; A sends it.
func _pad_next_skill() -> void:
	if selected.is_empty():
		return
	var caster := selected[0]
	var slot := armed_slot + 1
	if slot >= caster.slots.size():
		_disarm()
		return
	armed_slot = slot
	var ability := caster.slot_ability(slot)
	overlay.clear()
	overlay.action_cells = pathfinder.cells_in_range(
		caster.unit.cell, int(ability.get("min_range", 1)), int(ability.get("range", 1))
	)
	overlay.queue_redraw()
	_say("%s readies %s." % [caster.unit.display_name, ability.get("display_name", "?")])


## RB: the next standing party member, alone, with the cursor on them.
func _pad_next_fighter() -> void:
	var standing := party_fighters().filter(func(f: Fighter) -> bool: return f.is_standing())
	if standing.is_empty():
		return
	var at := standing.find(selected[0]) if not selected.is_empty() else -1
	var next: Fighter = standing[posmod(at + 1, standing.size())]
	_select([next])
	_aim_at(next.unit.cell)


func _steer_pad_cursor(delta: float) -> void:
	if not Pad.using_pad or over or Pad.focus_root() != null:
		_pad_held = Vector2i.ZERO
		return
	if not grid.in_bounds(pad_cell):
		var party := party_fighters()
		if not party.is_empty():
			_aim_at(selected[0].unit.cell if not selected.is_empty() else party[0].unit.cell)
	var direction := Vector2i(
		int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left")),
		int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
	)
	if direction == Vector2i.ZERO:
		_pad_held = Vector2i.ZERO
		return
	if direction != _pad_held:
		_pad_held = direction
		_pad_repeat = PAD_FIRST_REPEAT
		_nudge_cursor(direction)
		return
	_pad_repeat -= delta / maxf(Engine.time_scale, 0.01)
	if _pad_repeat <= 0.0:
		_pad_repeat = PAD_REPEAT
		_nudge_cursor(direction)


func _nudge_cursor(direction: Vector2i) -> void:
	var next := pad_cell + direction
	if not grid.in_bounds(next):
		next = pad_cell + Vector2i(direction.x, 0)
	if not grid.in_bounds(next):
		next = pad_cell + Vector2i(0, direction.y)
	if grid.in_bounds(next):
		_aim_at(next)


func _aim_at(cell: Vector2i) -> void:
	pad_cell = cell
	overlay.set_cursor(cell)
	camera.focus_on(grid.cell_to_world(cell))


## One thing the player asked for, by name, from a key or a touch button.
func act(action: String) -> void:
	if action.begins_with("slot"):
		_arm(int(action.trim_prefix("slot")))
		hud.refresh()
		return
	match action:
		"pause":
			set_paused(not paused)
			_say("Paused." if paused else "")
		"speed":
			Pace.cycle_speed()
		"auto_pause":
			auto_pause = ((int(auto_pause) + 1) % AutoPause.size()) as AutoPause
			_say("Auto-pause: %s." % AUTO_PAUSE_LABELS[auto_pause])
		"all":
			_select(party_fighters().filter(func(f: Fighter) -> bool: return f.is_standing()))
		"auto_skill":
			for f in selected:
				f.auto_skill = not f.auto_skill
		"hold":
			for f in selected:
				f.hold = not f.hold
				if f.hold and f.order == Fighter.Order.NONE:
					f.target = null
	hud.refresh()


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
		return
	# No right button under a thumb: a tap on anything else is the order.
	if touch:
		_on_right_click(cell)


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


## A skill tile on a card: pick whoever it belongs to and ready it.
func _on_slot_clicked(index: int, slot: int) -> void:
	var party := party_fighters()
	if index >= party.size() or not party[index].is_standing():
		return
	if selected.is_empty() or selected[0] != party[index]:
		_select([party[index]])
	_arm(slot)
	hud.refresh()


func _arm(slot: int) -> void:
	if selected.is_empty():
		return
	# The same skill asked for twice is changing your mind.
	if armed_slot == slot:
		_disarm()
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


## Every number that pops off a unit in this fight comes through here, whatever
## dealt it, so nothing is missed and nothing is counted twice.
func _on_unit_damaged(unit: Node, amount: int) -> void:
	var f := fighter_of(unit as Unit)
	if f == null or amount <= 0:
		return
	f.since_hit = 0.0
	fx.flash(f.unit)
	var at := f.unit.position
	match _hit_style:
		"crit":
			fx.popup("%d!" % amount, at, SkirmishFx.CRIT, 26, 1.1)
			fx.popup("CRITICAL", at + Vector2(0, -20), SkirmishFx.CRIT, 13, 1.0)
		"thorns":
			fx.popup(str(amount), at, SkirmishFx.THORNS, 16)
		_:
			fx.popup(str(amount), at, SkirmishFx.HURT if f.is_party() else SkirmishFx.DAMAGE, 18)


func _on_unit_healed(unit: Node, amount: int) -> void:
	var f := fighter_of(unit as Unit)
	if f == null or amount <= 0:
		return
	fx.popup("+%d" % amount, f.unit.position, SkirmishFx.HEAL, 15)


func _say(line: String) -> void:
	if line == "":
		return
	hud.log_line(line)
	EventBus.battle_log.emit(line)


func _to_cell(value: Variant) -> Vector2i:
	var pair: Array = value
	return Vector2i(int(pair[0]), int(pair[1]))
