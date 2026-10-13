extends RefCounted
## The sixteen's own ways of fighting: what makes Atlas, Janus, Bellona and the
## rest play differently on top of their class's passive (docs/21, "The sixteen
## classes, as built"). Each lead's signature is an entry under `signatures` in
## `data/skirmish.json`, keyed by the lead's template and named by its `style`;
## every number is read from there. **Inferred**, all of it (agenda item 72).
##
## [Skirmish] asks this at a handful of seams — who comes into the fight with
## whom, a tick, a step, a swing's tempo, a blow's weight, a blow landed, a kill,
## a fall — and does the rest itself. A fighter without a signature passes
## through every seam untouched.

## Loaded by path, not by `class_name`: a global class name only resolves once the
## editor has rescanned the project, and a checkout that has not been opened in
## the editor since this landed would otherwise fail to parse the whole skirmish.
const Fighter := preload("res://src/skirmish/fighter.gd")
const SkirmishRules := preload("res://src/skirmish/skirmish_rules.gd")
const SkirmishFx := preload("res://src/skirmish/skirmish_fx.gd")

## The skirmish scene. Untyped, because it loads this script itself.
var fight: Node2D
## Units to bring into the fight once the tick that made them is over, so the
## list of fighters never grows while it is being walked: [unit, bound_to].
var _arriving: Array = []


func _init(owner: Node2D) -> void:
	fight = owner


static func for_unit(unit: Unit) -> Dictionary:
	return Database.skirmish.get("signatures", {}).get(unit.template_id, {})


static func style(f: Fighter) -> String:
	return str(f.signature.get("style", ""))


func _num(f: Fighter, key: String, fallback: float = 0.0) -> float:
	return float(f.signature.get(key, fallback))


# --- who comes with whom -------------------------------------------------------


## Atlas's bearer and Diana's wolf come into the fight beside them, on their side.
func muster() -> void:
	for f: Fighter in fight.fighters.duplicate():
		match style(f):
			"borne":
				var bearer := _companion(f, str(f.signature.get("bearer", "")), str(f.signature.get("bearer_name", "")))
				if bearer != null:
					f.sig["bearer"] = bearer
					# It carries; it does not wander off after a fight of its own.
					bearer.hold = true
			"beast_bond":
				var beast := _companion(f, str(f.signature.get("beast", "")), str(f.signature.get("beast_name", "")))
				if beast != null:
					f.sig["beast"] = beast


## A companion at [param owner]'s level, on the nearest free tile beside them.
func _companion(owner: Fighter, template_id: String, display_name: String) -> Fighter:
	if Database.unit_template(template_id).is_empty():
		return null
	var none: Array[Vector2i] = []
	var cell: Vector2i = fight._free_cell_near(owner.unit.cell, none, null)
	if fight.occupant(cell) != null:
		return null
	var level := owner.unit.character.level if owner.unit.character != null else 1
	var body := Character.create(template_id)
	if display_name != "":
		body.display_name = display_name
	Progression.raise_quietly(body, level, GameState.world)
	var unit := Unit.from_character(body, _side_of(owner), cell)
	if display_name != "":
		unit.display_name = display_name
	unit.face_towards(cell + (cell - owner.unit.cell))
	var companion: Fighter = fight._enlist(unit)
	companion.bound_to = owner
	return companion


## A companion of the party fights beside it rather than in it.
func _side_of(owner: Fighter) -> Unit.Team:
	return Unit.Team.ALLY if owner.unit.team == Unit.Team.PLAYER else owner.unit.team


## Shades raised during the tick come in now.
func flush() -> void:
	var arriving := _arriving
	_arriving = []
	for pair: Array in arriving:
		var unit: Unit = pair[0]
		var raiser: Fighter = pair[1]
		var shade: Fighter = fight._enlist(unit)
		shade.bound_to = raiser
		shade.sig["shade"] = true
		unit.hp = maxi(1, roundi(float(unit.max_hp) * _num(raiser, "health", 0.4)))
		unit.modulate = Color(0.72, 0.62, 1.0, 0.85)
		fight.fx.ring(unit.position, SkirmishFx.THORNS, 44.0)
		fight.fx.popup("Rises!", unit.position, SkirmishFx.THORNS, 15, 1.2)
		fight._say("%s rises again for %s." % [unit.display_name, raiser.unit.display_name])


# --- every tick ----------------------------------------------------------------


## What runs on its own for a standing fighter: boosts and marks wearing off,
## and whatever the signature does on a clock.
func tick(f: Fighter) -> void:
	var t := SkirmishRules.TICK
	for key: String in f.boosts.keys():
		var boost: Array = f.boosts[key]
		boost[1] = float(boost[1]) - t
		if float(boost[1]) <= 0.0:
			f.boosts.erase(key)
	f.marked = maxf(0.0, f.marked - t)
	if not f.stepping:
		f.still += t
	match style(f):
		"orders":
			_orders(f)
		"ward":
			_ward_someone(f)
		"growth":
			_plant(f)
		"provision":
			_throw(f)


## How fast [param f]'s skills come back: Janus's, faster the worse the odds.
func cooldown_rate(f: Fighter) -> float:
	if style(f) != "doorways" or not f.is_standing():
		return 1.0
	var mine := 0
	var theirs := 0
	for other: Fighter in fight.fighters:
		if not other.is_standing():
			continue
		if other.unit.is_hostile_to(f.unit):
			theirs += 1
		else:
			mine += 1
	var worse := maxi(0, theirs - mine)
	return minf(_num(f, "most", 2.0), 1.0 + _num(f, "per_foe", 0.25) * float(worse))


## Bellona's: Advance while her side is still walking in, Break Them once it is
## at grips. Everyone near her, herself included, gets it for a few seconds.
func _orders(f: Fighter) -> void:
	if f.target == null or not fight.is_standing(f.target):
		return
	f.sig["order_wait"] = float(f.sig.get("order_wait", 0.0)) - SkirmishRules.TICK
	if float(f.sig["order_wait"]) > 0.0:
		return
	f.sig["order_wait"] = _num(f, "every", 10.0)
	var near := _friends_within(f, int(_num(f, "radius", 3)))
	var walking := near.any(func(o: Fighter) -> bool:
		return o.target == null or Pathfinder.distance(o.unit.cell, o.target.cell) > 1)
	var order := "pace" if walking else "might"
	var value := _num(f, "advance", 0.35) if walking else _num(f, "break_them", 0.2)
	for other: Fighter in near:
		other.boosts[order] = [value, _num(f, "lasts", 5.0)]
	f.sig["orders"] = int(f.sig.get("orders", 0)) + 1
	var word := "Advance!" if walking else "Break them!"
	fight.fx.popup(word, f.unit.position + Vector2(0, -16), SkirmishFx.GRACE, 16, 1.2)
	fight.fx.ring(f.unit.position, SkirmishFx.GRACE, 30.0 * float(_num(f, "radius", 3)))
	fight._say("%s: \"%s\"" % [f.unit.display_name, word])


## How much faster Bellona's allies get their energy back.
func energy_rate(f: Fighter) -> float:
	var best := 0.0
	for other: Fighter in fight.fighters:
		if style(other) != "orders" or not other.is_standing() or other.unit.is_hostile_to(f.unit):
			continue
		if Pathfinder.distance(other.unit.cell, f.unit.cell) <= int(_num(other, "energy_radius", 2)):
			best = maxf(best, _num(other, "energy", 0.5))
	return 1.0 + best


## Vesta wards whoever near her is worst off and not already warded.
func _ward_someone(f: Fighter) -> void:
	f.sig["ward_wait"] = float(f.sig.get("ward_wait", 0.0)) - SkirmishRules.TICK
	if float(f.sig["ward_wait"]) > 0.0:
		return
	var neediest: Fighter = null
	var lowest := _num(f, "below", 0.85)
	for other: Fighter in _friends_within(f, int(_num(f, "radius", 3))):
		var share := float(other.unit.hp) / float(maxi(1, other.unit.max_hp))
		if other.ward <= 0 and share < lowest:
			lowest = share
			neediest = other
	if neediest == null:
		return
	f.sig["ward_wait"] = _num(f, "every", 12.0)
	neediest.ward = maxi(1, roundi(float(neediest.unit.max_hp) * _num(f, "ward", 0.15)))
	fight.fx.ring(neediest.unit.position, SkirmishFx.GRACE, 36.0)
	fight.fx.popup("Warded", neediest.unit.position, SkirmishFx.GRACE, 13)
	fight._say("%s wards %s." % [f.unit.display_name, neediest.unit.display_name])


## Ceres plants the ground she has stood on long enough.
func _plant(f: Fighter) -> void:
	if f.still < _num(f, "plant_after", 2.5):
		return
	var planted: Array = f.sig.get_or_add("planted", [])
	if planted.has(f.unit.cell):
		return
	planted.append(f.unit.cell)
	while planted.size() > int(_num(f, "most", 6)):
		planted.pop_front()
	fight.fx.popup("Planted", f.unit.position, SkirmishFx.HEAL, 12)


## Every cell any Ceres on [param f]'s side, or against it, has planted:
## {cell: the planter}.
func plantings() -> Dictionary:
	var out := {}
	for other: Fighter in fight.fighters:
		if style(other) != "growth" or not other.is_standing():
			continue
		for cell: Vector2i in other.sig.get("planted", []):
			out[cell] = other
	return out


## Health that comes back to [param f] from standing near a friendly planting.
func regen(f: Fighter) -> float:
	var best := 0.0
	var fields := plantings()
	for cell: Vector2i in fields:
		var planter: Fighter = fields[cell]
		if planter.unit.is_hostile_to(f.unit):
			continue
		if Pathfinder.distance(cell, f.unit.cell) <= int(_num(planter, "radius", 1)):
			best = maxf(best, _num(planter, "regen", 0.015))
	return best


## Juno throws a draught or herb from the pouch to an ally in trouble.
func _throw(f: Fighter) -> void:
	if not f.is_party() or fight.pouch.is_empty():
		return
	f.sig["throw_wait"] = float(f.sig.get("throw_wait", 0.0)) - SkirmishRules.TICK
	if float(f.sig["throw_wait"]) > 0.0:
		return
	var catcher: Fighter = null
	var lowest := _num(f, "below", 0.45)
	for other: Fighter in _friends_within(f, int(_num(f, "radius", 4))):
		if other == f or not other.is_party():
			continue
		var share := float(other.unit.hp) / float(maxi(1, other.unit.max_hp))
		if share < lowest and fight.item_refusal(other, fight.pouch_items()[0]) == "":
			lowest = share
			catcher = other
	if catcher == null:
		return
	f.sig["throw_wait"] = _num(f, "every", 8.0)
	var item_id: String = fight.pouch_items()[0]
	fight.fx.effect(SkirmishFx.effect_for("heal"), catcher.unit.position, f.unit.position)
	fight._say("%s throws %s the %s." % [f.unit.display_name, catcher.unit.display_name, Gear.display_name(item_id)])
	catcher.using = {"item": item_id, "left": 0.0, "total": 0.0}
	fight._finish_item(catcher, f)


## How much more a draught or herb mends: twice, for Juno or for one she threw.
func item_scale(f: Fighter, thrower: Fighter) -> float:
	if style(f) == "provision":
		return _num(f, "twice", 2.0)
	if thrower != null and style(thrower) == "provision":
		return _num(thrower, "twice", 2.0)
	return 1.0


# --- moving --------------------------------------------------------------------


## Atlas has no step of his own: with no bearer standing he stays put.
func can_step(f: Fighter) -> bool:
	# With no room to bring a bearer in at all, he walks rather than stands all fight.
	if style(f) != "borne" or not f.sig.has("bearer"):
		return true
	var bearer: Fighter = f.sig.get("bearer")
	if bearer.is_standing():
		return true
	if not bool(f.sig.get("stranded", false)):
		f.sig["stranded"] = true
		fight.fx.popup("Stranded", f.unit.position, SkirmishFx.HURT, 14, 1.4)
		fight._say("%s has nobody to carry him." % f.unit.display_name)
	return false


## A bearer keeps beside the one it carries before anything else. Returns true
## when it spent the tick catching up.
func keep_up(f: Fighter) -> bool:
	var rider: Fighter = f.bound_to as Fighter
	if rider == null or style(rider) != "borne" or not rider.is_standing():
		return false
	if Pathfinder.distance(f.unit.cell, rider.unit.cell) <= 1:
		return false
	var at := rider.unit.cell
	return fight._step_towards(f, func(c: Vector2i) -> bool: return Pathfinder.distance(c, at) == 1)


## How much longer a step takes: slowed by Saturn's ground and Ceres's thorns,
## hurried by Bellona's Advance.
func step_scale(f: Fighter, cell: Vector2i) -> float:
	var scale := 1.0
	for other: Fighter in fight.fighters:
		if style(other) != "gravity_well" or not other.is_standing() or not other.unit.is_hostile_to(f.unit):
			continue
		if Pathfinder.distance(other.unit.cell, f.unit.cell) <= int(_num(other, "radius", 1)):
			scale = maxf(scale, 1.0 / maxf(0.1, 1.0 - _num(other, "slow", 0.4)))
	var fields := plantings()
	for planted: Vector2i in fields:
		var planter: Fighter = fields[planted]
		if planter.unit.is_hostile_to(f.unit) and Pathfinder.distance(planted, cell) <= int(_num(planter, "radius", 1)):
			scale = maxf(scale, 1.0 / maxf(0.1, 1.0 - _num(planter, "slow", 0.5)))
	if f.boosts.has("pace"):
		scale /= 1.0 + float(f.boosts["pace"][0])
	return scale


## Moving off a tile: whatever was built up by standing on it is gone.
func stepped(f: Fighter) -> void:
	f.still = 0.0


# --- blows ---------------------------------------------------------------------


## How much harder [param f] hits [param victim]: every signature that leans on
## a blow, multiplied together.
func might(f: Fighter, victim: Fighter) -> float:
	var scale := 1.0
	if f.boosts.has("might"):
		scale *= 1.0 + float(f.boosts["might"][0])
	if victim != null and victim.marked > 0.0:
		scale *= 1.0 + float(victim.sig.get("marked_bonus", 0.0))
	match style(f):
		"learns":
			if victim != null:
				var learnt: Dictionary = f.sig.get("learnt", {})
				scale *= 1.0 + minf(_num(f, "most", 0.3), _num(f, "per_hit", 0.06) * float(learnt.get(victim.unit, 0)))
		"ward":
			if victim != null and _is_dead(f, victim):
				scale *= 1.0 + _num(f, "dead_bonus", 0.5)
		"marks":
			scale *= 1.0 + minf(_num(f, "most", 0.3), _num(f, "per_finish", 0.1) * float(f.sig.get("finished", 0)))
		"shades":
			scale *= 1.0 + minf(_num(f, "most", 0.25), _num(f, "per_kind", 0.05) * float((f.sig.get("kinds", []) as Array).size()))
		"growth":
			if (f.sig.get("planted", []) as Array).has(f.unit.cell):
				scale *= 1.0 + _num(f, "rooted_bonus", 0.15)
		"set":
			if is_set(f):
				scale *= 1.0 + _num(f, "might", 0.1)
		"one_target":
			if victim != null and f.sig.get("focus") == victim.unit:
				scale *= 1.0 + minf(_num(f, "most", 0.3), _num(f, "per_hit", 0.06) * float(f.sig.get("focus_hits", 0)))
		"beast_bond":
			var beast: Fighter = f.sig.get("beast")
			if beast != null and not beast.is_standing():
				scale *= 1.0 - _num(f, "without", 0.4)
		"opener":
			if fight.sim_time <= _num(f, "lasts", 10.0):
				scale *= 1.0 + _num(f, "might", 0.35)
			else:
				scale *= 1.0 - _num(f, "tired_might", 0.1)
		"bare_hands":
			var steps := floorf(fight.sim_time / maxf(0.1, _num(f, "every", 5.0)))
			scale *= 1.0 + minf(_num(f, "most", 0.3), _num(f, "per_step", 0.02) * steps)
	return scale


## How much less [param f] takes: Cato set, and set again with a friend beside him.
func guard(f: Fighter) -> float:
	if style(f) != "set" or not is_set(f):
		return 0.0
	var out := _num(f, "guard", 0.15)
	for other: Fighter in _friends_within(f, 1):
		if other != f:
			out += _num(f, "beside", 0.1)
			break
	return out


## Vesta's fire burns the dead: the kinds she names, and anyone's shades.
func _is_dead(f: Fighter, victim: Fighter) -> bool:
	return (f.signature.get("dead", []) as Array).has(victim.unit.template_id) or bool(victim.sig.get("shade", false))


func is_set(f: Fighter) -> bool:
	return style(f) == "set" and f.still >= _num(f, "after", 2.0)


## How much longer between swings: Ares rushes the first seconds, then tires.
func attack_scale(f: Fighter) -> float:
	if style(f) != "opener":
		return 1.0
	if fight.sim_time <= _num(f, "lasts", 10.0):
		return 1.0 - _num(f, "haste", 0.25)
	return 1.0 + _num(f, "tired_slow", 0.15)


## The Caesar beside [param victim] who will take part of a blow meant for them.
func shield_for(victim: Fighter) -> Fighter:
	if victim == null:
		return null
	for other: Fighter in fight.fighters:
		if other == victim or style(other) != "takes_the_hit" or not other.is_standing():
			continue
		if other.unit.is_hostile_to(victim.unit) or Pathfinder.distance(other.unit.cell, victim.unit.cell) > 1:
			continue
		return other
	return null


func share_of(guardian: Fighter) -> float:
	return clampf(_num(guardian, "share", 0.25), 0.0, 0.9)


## A blow of [param f]'s landed on [param victim] for [param dealt].
func landed(f: Fighter, victim: Fighter, dealt: int) -> void:
	if victim == null or dealt <= 0:
		return
	# Cassius learns whoever hit him.
	if style(victim) == "learns":
		var learnt: Dictionary = victim.sig.get_or_add("learnt", {})
		learnt[f.unit] = int(learnt.get(f.unit, 0)) + 1
	match style(f):
		"one_target":
			if f.sig.get("focus") == victim.unit:
				f.sig["focus_hits"] = int(f.sig.get("focus_hits", 0)) + 1
			else:
				f.sig["focus"] = victim.unit
				f.sig["focus_hits"] = 1
		"marks":
			if victim.marked <= 0.0:
				fight.fx.popup("Marked", victim.unit.position + Vector2(0, -12), SkirmishFx.CRIT, 12)
			victim.marked = _num(f, "lasts", 8.0)
			victim.sig["marked_bonus"] = _num(f, "marked_bonus", 0.1)
			victim.sig["marked_by"] = f


## [param killer] has just put [param victim] down.
func killed(killer: Fighter, victim: Fighter) -> void:
	if killer == null or victim == null:
		return
	if style(killer) == "marks" and victim.marked > 0.0 and victim.sig.get("marked_by") == killer:
		var before := int(killer.sig.get("finished", 0))
		killer.sig["finished"] = before + 1
		if _num(killer, "per_finish", 0.1) * float(before) < _num(killer, "most", 0.3):
			fight.fx.popup("Stronger", killer.unit.position, SkirmishFx.CRIT, 13)
	if style(killer) == "shades":
		var kinds: Array = killer.sig.get_or_add("kinds", [])
		if not kinds.has(victim.unit.template_id):
			kinds.append(victim.unit.template_id)
		_raise(killer, victim)


## What Pluto kills gets up for him, unless it was a keeper or already a shade.
func _raise(pluto: Fighter, victim: Fighter) -> void:
	if victim.is_party() or victim.unit.has_meta("boss") or bool(victim.sig.get("shade", false)):
		return
	var standing := 0
	for other: Fighter in fight.fighters:
		if other.bound_to == pluto and bool(other.sig.get("shade", false)) and other.is_standing():
			standing += 1
	for pair: Array in _arriving:
		if pair[1] == pluto:
			standing += 1
	if standing >= int(_num(pluto, "at_once", 2)):
		return
	var unit := Unit.create(victim.unit.template_id, _side_of(pluto), victim.unit.cell)
	unit.display_name = "%s's shade" % victim.unit.display_name
	_arriving.append([unit, pluto])


## Liber cannot be stunned.
func stun_proof(f: Fighter) -> bool:
	return style(f) == "bare_hands"


# --- falling -------------------------------------------------------------------


## Caesar, the first time he goes down, counts to his feet.
func downed(f: Fighter) -> void:
	if style(f) == "takes_the_hit" and not bool(f.sig.get("risen", false)):
		f.sig["rise_in"] = _num(f, "rise_after", 3.0)


## Whether a downed fighter gets up on their own this tick.
func rises(f: Fighter) -> bool:
	if not f.sig.has("rise_in"):
		return false
	f.sig["rise_in"] = float(f.sig["rise_in"]) - SkirmishRules.TICK
	if float(f.sig["rise_in"]) > 0.0:
		return false
	f.sig.erase("rise_in")
	f.sig["risen"] = true
	return true


func rise_health(f: Fighter) -> float:
	return _num(f, "rise_health", 0.3)


# --- helpers -------------------------------------------------------------------


## Everyone standing on [param f]'s side within [param radius], [param f] included.
func _friends_within(f: Fighter, radius: int) -> Array[Fighter]:
	var out: Array[Fighter] = []
	for other: Fighter in fight.fighters:
		if other.is_standing() and not other.unit.is_hostile_to(f.unit) \
				and Pathfinder.distance(other.unit.cell, f.unit.cell) <= radius:
			out.append(other)
	return out
