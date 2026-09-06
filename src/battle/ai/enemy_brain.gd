class_name EnemyBrain
extends RefCounted
## Deliberately simple opponent AI: close on the nearest foe, and strike from
## the best reachable tile if one is in range.
##
## Returns a plan the battle controller executes, so the AI never mutates state
## itself and can be swapped out (aggressive / defensive / scripted) per unit.

## Plan shape: { "move_cell": Vector2i, "ability": String, "target": Unit|null, "flash": bool }

## Blinking is loud, so it only wins when walking cannot match the same tile.
const FLASH_PENALTY := 5.0

static func plan(
	unit: Unit, grid: BattleGrid, pathfinder: Pathfinder, all_units: Array[Unit]
) -> Dictionary:
	var result := {"move_cell": unit.cell, "ability": "", "target": null, "flash": false}

	var foes := all_units.filter(
		func(u: Unit) -> bool: return u.is_alive() and u.is_hostile_to(unit)
	)
	if foes.is_empty():
		return result

	var ability_ids: Array = unit.abilities.duplicate()
	if ability_ids.is_empty():
		ability_ids.append("strike")
	result["ability"] = ability_ids[0]

	var field := pathfinder.build_move_field(
		unit.cell,
		unit.move_points,
		unit.jump,
		func(cell: Vector2i) -> bool:
			var other := _unit_at(all_units, cell)
			return other != null and other.is_hostile_to(unit)
	)

	var candidates: Array[Vector2i] = field.stoppable_cells(
		func(cell: Vector2i) -> bool: return _unit_at(all_units, cell) != null
	)
	candidates.append(unit.cell)

	var options: Array[Dictionary] = []
	for cell in candidates:
		options.append({"cell": cell, "cost": float(field.cost_to(cell)) * 0.1, "flash": false})
	for cell in pathfinder.flash_cells(
		unit.cell,
		unit.flash_step,
		func(landing: Vector2i) -> bool: return _unit_at(all_units, landing) == null
	):
		if not field.can_reach(cell):
			options.append({"cell": cell, "cost": FLASH_PENALTY, "flash": true})

	var best_score := -INF
	var friends := all_units.filter(
		func(u: Unit) -> bool: return u.is_alive() and not u.is_hostile_to(unit)
	)

	for ability_id: String in ability_ids:
		var ability := Database.ability(ability_id)
		var is_heal := bool(ability.get("heal", false)) or str(ability.get("target", "enemy")) in ["ally", "self"]
		for option in options:
			var cell: Vector2i = option["cell"]
			var target: Unit = null
			var score: float = -float(option["cost"])

			if is_heal:
				target = _best_heal_target_from(cell, ability, unit, friends)
				if target != null:
					score += 1100.0 + float(target.max_hp - target.hp) * 12.0 + float(ability.get("power", 10.0)) * 2.0
				else:
					score -= float(_distance_to_nearest(cell, foes))
			else:
				target = _best_target_from(cell, ability, unit, foes)
				if target != null:
					# Attacking beats repositioning; finish off the weakest reachable foe,
					# prefer heavier damage moves, reward AOE splash, and break ties towards softer flanks.
					score += 1000.0 - float(target.hp)
					score += AbilityResolver.flank_multiplier(cell, target) * 20.0
					score += float(ability.get("power", 1.0)) * 25.0
					var splash := int(ability.get("splash", 0))
					if splash > 0:
						var extra_hits := 0
						for other_foe in foes:
							if other_foe != target and Pathfinder.distance(target.cell, other_foe.cell) <= splash:
								extra_hits += 1
						score += float(extra_hits) * 35.0
				else:
					score -= float(_distance_to_nearest(cell, foes))

			if score > best_score:
				best_score = score
				result["move_cell"] = cell
				result["ability"] = ability_id
				result["target"] = target
				result["flash"] = option["flash"]

	return result


static func _best_heal_target_from(
	cell: Vector2i, ability: Dictionary, unit: Unit, friends: Array
) -> Unit:
	var best: Unit = null
	for friend: Unit in friends:
		if not AbilityResolver.is_valid_target(unit, ability, friend):
			continue
		if friend.hp >= friend.max_hp:
			continue
		if not AbilityResolver.in_range(ability, cell, friend.cell):
			continue
		if best == null or (friend.max_hp - friend.hp) > (best.max_hp - best.hp):
			best = friend
	return best


static func _best_target_from(
	cell: Vector2i, ability: Dictionary, unit: Unit, foes: Array
) -> Unit:
	var best: Unit = null
	for foe: Unit in foes:
		if not AbilityResolver.is_valid_target(unit, ability, foe):
			continue
		if not AbilityResolver.in_range(ability, cell, foe.cell):
			continue
		if best == null or foe.hp < best.hp:
			best = foe
	return best


static func _distance_to_nearest(cell: Vector2i, foes: Array) -> int:
	var best := 9999
	for foe: Unit in foes:
		best = mini(best, Pathfinder.distance(cell, foe.cell))
	return best


static func _unit_at(all_units: Array[Unit], cell: Vector2i) -> Unit:
	for unit in all_units:
		if unit.is_alive() and unit.cell == cell:
			return unit
	return null


## Find the most threatening opponent within 3 tiles to face at turn conclusion (Ruling 1.3).
static func threat_facing(unit: Unit, all_units: Array[Unit]) -> Vector2i:
	var threats: Array[Unit] = []
	for other in all_units:
		if other.is_alive() and other.is_hostile_to(unit) and other.cell != unit.cell:
			if Pathfinder.distance(unit.cell, other.cell) <= 3:
				threats.append(other)
	if threats.is_empty():
		return unit.facing
	var primary: Unit = null
	for foe in threats:
		if primary == null or foe.attack > primary.attack:
			primary = foe
	if primary != null:
		return Unit.dominant_direction(primary.cell - unit.cell)
	return unit.facing
