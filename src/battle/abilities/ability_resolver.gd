class_name AbilityResolver
extends RefCounted
## Combat maths. Kept static and side-effect-light so it can be unit tested
## without spinning up a battle scene.

## Damage/heal roll varies by +/- this fraction so identical trades aren't identical.
const VARIANCE := 0.1


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
static func apply(user: Unit, ability: Dictionary, target: Unit) -> String:
	var name: String = ability.get("display_name", "Attack")
	if ability.get("heal", false):
		var healing := _roll(int(ability.get("power", 10)))
		target.heal(healing)
		return "%s used %s — %s recovers %d HP." % [user.display_name, name, target.display_name, healing]

	var raw := _roll(roundi(user.attack * float(ability.get("power", 1.0))))
	var damage := maxi(1, raw - target.defense)
	target.take_damage(damage)
	var line := "%s used %s — %s takes %d damage." % [user.display_name, name, target.display_name, damage]
	if not target.is_alive():
		line += " %s falls." % target.display_name
	return line


static func _roll(base: int) -> int:
	var spread := base * VARIANCE
	return maxi(1, roundi(randf_range(base - spread, base + spread)))
