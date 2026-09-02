class_name AbilityResolver
extends RefCounted
## Combat maths. Kept static and side-effect-light so it can be unit tested
## without spinning up a battle scene.

## Damage/heal roll varies by +/- this fraction so identical trades aren't identical.
const VARIANCE := 0.1

## Which face of the target an attack lands on.
enum Flank { FRONT, SIDE, BACK }

const FLANK_MULTIPLIER := {
	Flank.FRONT: 1.0,
	Flank.SIDE: 1.2,
	Flank.BACK: 1.5,
}

const FLANK_LABEL := {
	Flank.FRONT: "",
	Flank.SIDE: " (flank)",
	Flank.BACK: " (from behind)",
}


## Where [param attacker_cell] sits relative to the way [param target] is looking.
static func flank_of(attacker_cell: Vector2i, target: Unit) -> Flank:
	var approach := Unit.dominant_direction(attacker_cell - target.cell)
	if attacker_cell == target.cell or approach == target.facing:
		return Flank.FRONT
	if approach == -target.facing:
		return Flank.BACK
	return Flank.SIDE


static func flank_multiplier(attacker_cell: Vector2i, target: Unit) -> float:
	return FLANK_MULTIPLIER[flank_of(attacker_cell, target)]


static func is_valid_target(user: Unit, ability: Dictionary, target: Unit) -> bool:
	if target == null or not target.is_alive():
		return false
	match ability.get("target", "enemy"):
		"enemy":
			return target.is_hostile_to(user)
		"ally":
			return not target.is_hostile_to(user)
		"any":
			return true
		"self":
			return target == user
	return false


static func in_range(ability: Dictionary, from: Vector2i, to: Vector2i) -> bool:
	var distance := Pathfinder.distance(from, to)
	var min_range := int(ability.get("min_range", 1))
	var max_range := int(ability.get("range", 1))
	return distance >= min_range and distance <= max_range


## Cells hit when the ability lands on [param centre] (splash included).
static func affected_cells(ability: Dictionary, centre: Vector2i) -> Array[Vector2i]:
	var radius := int(ability.get("splash", 0))
	var cells: Array[Vector2i] = []
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if absi(dx) + absi(dy) <= radius:
				cells.append(centre + Vector2i(dx, dy))
	return cells


## Apply [param ability] from [param user] to [param target]. Returns a log line.
## [param ability_id] is only used to look up how practised the user is with it;
## a scratch enemy has no [Character] and so is never any better at anything.
static func apply(user: Unit, ability: Dictionary, target: Unit, ability_id: String = "") -> String:
	var name: String = ability.get("display_name", "Attack")
	var skill := Proficiency.multiplier(user.character, ability_id)
	if ability.get("heal", false):
		var healing := _roll(roundi(float(ability.get("power", 10)) * skill))
		target.heal(healing)
		return "%s used %s — %s recovers %d HP." % [user.display_name, name, target.display_name, healing]

	var raw := _roll(roundi(user.attack * float(ability.get("power", 1.0)) * skill))
	var flank := flank_of(user.cell, target)
	var damage := maxi(1, roundi(raw * float(FLANK_MULTIPLIER[flank])) - target.defense)
	target.take_damage(damage)
	var line := "%s used %s — %s takes %d damage%s." % [
		user.display_name, name, target.display_name, damage, FLANK_LABEL[flank]
	]
	if not target.is_alive():
		line += " %s falls." % target.display_name
	return line


static func _roll(base: int) -> int:
	var spread := base * VARIANCE
	return maxi(1, roundi(randf_range(base - spread, base + spread)))
