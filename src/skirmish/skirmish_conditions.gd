extends RefCounted
## What a move leaves on whoever it lands on, and how it shows ([D192]). A knockback
## slides them back a tile or more, a pull drags them in, a slow frosts their feet,
## a burn and a bleed tick numbers off them, a knockdown lays them flat, a sunder
## cracks their guard. When one is shrugged off (a keeper that will not be moved,
## a body pinned against a wall, a fire creature that will not burn) that shows too,
## as a word in silver over the head.
##
## An ability names its conditions by key in `data/abilities.json` (`knockback`,
## `pull` in tiles; `slow`, `burn`, `bleed`, `knockdown`, `expose` in seconds); how
## each works and what it says is `conditions` in `data/skirmish.json`. A stun
## stays the ability's own key and [method Skirmish._stun]'s to give.

## Loaded by path, not by `class_name`: a global class name only resolves once the
## editor has rescanned the project, and a checkout that has not been opened in
## the editor since this landed would otherwise fail to parse the whole skirmish.
const Fighter := preload("res://src/skirmish/fighter.gd")
const SkirmishRules := preload("res://src/skirmish/skirmish_rules.gd")
const SkirmishFx := preload("res://src/skirmish/skirmish_fx.gd")

## The ones that last, in the order they are tried.
const LASTING: Array[String] = ["knockdown", "slow", "burn", "bleed", "expose"]
## The ones that move a body.
const SHOVES: Array[String] = ["knockback", "pull"]
## A shrugged-off move's word.
const RESIST := Color(0.82, 0.86, 0.92)
## A burn's number, and a bleed's.
const BURN := Color(1.0, 0.6, 0.2)
const BLEED := Color(0.9, 0.18, 0.2)
## Seconds a knocked-down body takes to tip over, or to get up again.
const TIP_TIME := 0.15

## The skirmish scene. Untyped, because it loads this script itself.
var fight: Node2D


func _init(owner: Node2D) -> void:
	fight = owner


static func data() -> Dictionary:
	return Database.skirmish.get("conditions", {})


static func entry(kind: String) -> Dictionary:
	var out: Variant = data().get(kind, {})
	return out if out is Dictionary else {}


## The word `conditions` gives for [param key] ("dodged", "missed"…), or [param fallback].
static func word(key: String, fallback: String) -> String:
	var out: Variant = data().get(key, fallback)
	return str(out) if not (out is Dictionary) else fallback


## Every condition [param ability] carries, as {kind: size}.
static func carried(ability: Dictionary) -> Dictionary:
	var out := {}
	for kind: String in SHOVES + LASTING:
		if float(ability.get(kind, 0.0)) > 0.0:
			out[kind] = ability[kind]
	return out


## The lines a skill's tooltip adds for what it leaves behind.
static func tips(ability: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var found := carried(ability)
	for kind: String in found:
		var tip := str(entry(kind).get("tip", ""))
		if tip == "":
			continue
		out.append(tip % (int(found[kind]) if SHOVES.has(kind) else float(found[kind])))
	return out


## Whether [param victim] shrugs [param kind] off altogether.
static func resists(victim: Fighter, kind: String) -> bool:
	var resist: Dictionary = data().get("resists", {})
	if victim.unit.has_meta("boss") and (resist.get("boss", []) as Array).has(kind):
		return true
	var style := str(victim.signature.get("style", ""))
	if style != "" and (resist.get("by_style", {}).get(style, []) as Array).has(kind):
		return true
	return (resist.get("by_template", {}).get(victim.unit.template_id, []) as Array).has(kind)


## Tiles a shove loses on a body as big as [param victim]'s.
static func heavy_less(victim: Fighter) -> int:
	var heavy: Dictionary = data().get("resists", {}).get("heavy", {})
	if heavy.is_empty() or victim.unit.body_scale < float(heavy.get("from_body_scale", 99.0)):
		return 0
	return int(heavy.get("less", 1))


## A move shrugged off, said over [param victim] in silver.
func shrug(victim: Fighter, kind: String) -> void:
	var said := str(entry(kind).get("resisted", "Resists"))
	fight.fx.popup(said, victim.unit.position + Vector2(0, -10), RESIST, 14, 1.1)
	fight.fx.ring(victim.unit.position, RESIST, 26.0)
	fight._say("%s shrugs off the %s." % [victim.unit.display_name, kind])


# --- a blow lands --------------------------------------------------------------


## [param f]'s [param ability] has just landed on [param victim] for [param dealt].
## Called once the blow is settled and only while the victim still stands.
func landed(f: Fighter, victim: Fighter, ability: Dictionary, dealt: int) -> void:
	if victim == null or not victim.is_standing():
		return
	var found := carried(ability)
	for kind: String in SHOVES:
		if found.has(kind):
			shove(f, victim, kind, int(found[kind]))
	for kind: String in LASTING:
		if found.has(kind) and victim.is_standing():
			afflict(f, victim, kind, float(found[kind]), dealt)


## Slide [param victim] [param tiles] tiles straight away from [param f] (a knockback)
## or towards them (a pull), stopping at a wall, a ledge too high, the field's edge or
## anybody in the way. Returns the tiles moved.
func shove(f: Fighter, victim: Fighter, kind: String, tiles: int) -> int:
	var said := entry(kind)
	var from := f.unit.cell
	var away := Unit.dominant_direction(victim.unit.cell - from) if victim.unit.cell != from else f.unit.facing
	var way := away if kind == "knockback" else -away
	if resists(victim, kind):
		_jolt(victim, way)
		shrug(victim, kind)
		return 0
	tiles -= heavy_less(victim)
	if tiles <= 0:
		_jolt(victim, way)
		shrug(victim, kind)
		return 0
	var grid: BattleGrid = fight.grid
	var cell := victim.unit.cell
	var moved := 0
	for _i in tiles:
		var next := cell + way
		if kind == "pull" and next == from:
			break
		if not grid.is_walkable(next) or fight.occupant(next, victim) != null \
				or grid.height_at(next) - grid.height_at(cell) > victim.unit.jump:
			break
		cell = next
		moved += 1
	if moved == 0:
		# Nowhere to go: slammed into whatever is behind them, and it shows.
		_jolt(victim, way)
		fight.fx.popup(str(said.get("pinned", "Pinned")), victim.unit.position + Vector2(0, -10), SkirmishFx.HURT, 14, 1.1)
		fight.shake(2.0)
		return 0
	var start := victim.unit.position
	victim.stepping = true
	victim.step_from = start
	victim.step_to = grid.cell_to_world(cell)
	victim.step_total = float(said.get("slide", 0.1)) * float(moved)
	victim.step_left = victim.step_total
	victim.unit.cell = cell
	victim.unit.set_running(false)
	victim.tactic_left = 0.0
	victim.bump = 0.0
	fight.signatures.stepped(victim)
	fight.fx.ring(start, Color(0.85, 0.78, 0.6), 22.0)
	fight.fx.popup(str(said.get("word", kind.capitalize())), start + Vector2(0, -10), SkirmishFx.WORD, 14, 1.1)
	if moved < tiles and kind == "knockback":
		fight.fx.popup(str(said.get("pinned", "Pinned")), victim.step_to + Vector2(0, -24), SkirmishFx.HURT, 12, 1.1)
	fight._say("%s is %s %d tile%s." % [victim.unit.display_name,
			"knocked back" if kind == "knockback" else "dragged in", moved, "" if moved == 1 else "s"])
	return moved


## A shove that did not move them still rocks them on their feet.
func _jolt(victim: Fighter, way: Vector2i) -> void:
	victim.bump = 1.0
	victim.bump_dir = Vector2(way).normalized()


## Leave [param kind] on [param victim] for [param seconds]; a second dose tops it up
## rather than stacking. A burn or bleed's bite is a share of [param dealt] a second.
func afflict(f: Fighter, victim: Fighter, kind: String, seconds: float, dealt: int) -> void:
	if kind == "burn" and bool(f.signature.get("burns_only_dead", false)) \
			and not fight.signatures._is_dead(f, victim):
		return
	if resists(victim, kind):
		shrug(victim, kind)
		return
	var said := entry(kind)
	if kind == "knockdown":
		if not fight._stun(victim, f, seconds, str(said.get("word", "Knocked down"))):
			return
	var had: Dictionary = victim.conditions.get(kind, {})
	var bite := 0
	if kind == "burn" or kind == "bleed":
		bite = maxi(1, roundi(float(maxi(1, dealt)) * float(said.get("per_second", 0.1))))
		bite = maxi(bite, int(had.get("bite", 0)))
	victim.conditions[kind] = {"left": maxf(seconds, float(had.get("left", 0.0))), "total": seconds,
			"by": f, "bite": bite, "tick": float(had.get("tick", 1.0))}
	if kind != "knockdown" and had.is_empty():
		var colour := BURN if kind == "burn" else (BLEED if kind == "bleed" else SkirmishFx.WORD)
		# Above a shove's word, when the same blow moved them too.
		fight.fx.popup(str(said.get("word", kind.capitalize())), victim.unit.position + Vector2(0, -30), colour, 13, 1.1)


# --- every tick ----------------------------------------------------------------


## Wear [param f]'s conditions down, let the burns and bleeds bite, and tip a knocked-down
## body over and back up.
func tick(f: Fighter) -> void:
	var t := SkirmishRules.TICK
	for kind: String in f.conditions.keys():
		var c: Dictionary = f.conditions[kind]
		c["left"] = float(c["left"]) - t
		if kind == "burn" or kind == "bleed":
			c["tick"] = float(c["tick"]) - t
			if float(c["tick"]) <= 0.0:
				c["tick"] = 1.0
				_bite(f, kind, int(c["bite"]), c.get("by"))
				if not f.is_standing():
					return
		if kind == "knockdown" and not f.is_stunned():
			c["left"] = 0.0
		if float(c["left"]) <= 0.0:
			f.conditions.erase(kind)
	var down := f.conditions.has("knockdown")
	var lying := clampf(f.unit.lying + (t if down else -t) / TIP_TIME, 0.0, 1.0)
	if lying != f.unit.lying:
		f.unit.lying = lying
		f.unit.queue_redraw()


func _bite(f: Fighter, kind: String, amount: int, by: Variant) -> void:
	if amount <= 0:
		return
	fight._hit_style = kind
	f.unit.take_damage(amount)
	fight._hit_style = ""
	if f.unit.is_alive():
		return
	var killer := by as Fighter
	fight._say("%s %s." % [f.unit.display_name, "burns to death" if kind == "burn" else "bleeds out"])
	if killer != null:
		fight._award_kill(killer.unit, f.unit)
		fight.signatures.killed(killer, f)
	fight._drop(f)


## Off the field, or back up from near death: nothing carries on.
func clear(f: Fighter) -> void:
	f.conditions.clear()
	f.dodging = []
	f.unit.lying = 0.0
	f.unit.queue_redraw()


# --- what the rest of the fight asks -------------------------------------------


## How much longer a step takes for [param f].
func step_scale(f: Fighter) -> float:
	if not f.conditions.has("slow"):
		return 1.0
	return 1.0 / maxf(0.1, 1.0 - float(entry("slow").get("steps", 0.45)))


## How much longer between swings for [param f].
func swing_scale(f: Fighter) -> float:
	if not f.conditions.has("slow"):
		return 1.0
	return 1.0 + float(entry("slow").get("swings", 0.2))


## How much more [param f] takes from a blow.
func taken_scale(f: Fighter) -> float:
	if f == null or not f.conditions.has("expose"):
		return 1.0
	return 1.0 + float(entry("expose").get("more", 0.15))


## Slowed by a move, or by ground that drags (Saturn's well, Ceres's thorns).
func is_slowed(f: Fighter) -> bool:
	return f.conditions.has("slow") or fight.signatures.ground_drag(f) > 1.0


# --- dodges and misses ----------------------------------------------------------


## [param f] has stepped out of [param caster]'s wind-up.
func dodging(f: Fighter, caster: Fighter) -> void:
	f.dodging = [caster, fight.sim_time + 4.0]


## [param caster]'s skill has just come down on [param hits]: whoever stepped out of it shows it.
func came_down(caster: Fighter, hits: Array[Unit]) -> void:
	for other: Fighter in fight.fighters:
		if other.dodging.is_empty() or other.dodging[0] != caster:
			continue
		var fresh: bool = float(other.dodging[1]) >= float(fight.sim_time)
		other.dodging = []
		if fresh and other.is_standing() and not hits.has(other.unit):
			show_dodge(other)


## "Dodged!" over [param f], with a quick ring where they now stand.
func show_dodge(f: Fighter) -> void:
	fight.fx.popup(word("dodged", "Dodged!"), f.unit.position + Vector2(0, -10), RESIST, 15, 1.1)
	fight.fx.ring(f.unit.position, RESIST, 22.0)
	fight._say("%s gets out of the way." % f.unit.display_name)


## A skill come down on [param cell] with nobody there.
func show_miss(cell: Vector2i) -> void:
	var at: Vector2 = fight.grid.cell_to_world(cell)
	fight.fx.popup(word("missed", "Missed"), at, RESIST, 14, 1.0)
	fight.fx.ring(at, RESIST, 18.0)
