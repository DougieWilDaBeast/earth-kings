class_name EnemyBrain
extends RefCounted
## Deliberately simple opponent AI: close on the nearest foe, and strike from
## the best reachable tile if one is in range.
##
## Returns a plan the battle controller executes, so the AI never mutates state
## itself and can be swapped out (aggressive / defensive / scripted) per unit.

## Plan shape: { "move_cell": Vector2i, "ability": String, "target": Unit|null }
static func plan(
	unit: Unit, grid: BattleGrid, pathfinder: Pathfinder, all_units: Array[Unit]
) -> Dictionary:
	var result := {"move_cell": unit.cell, "ability": "", "target": null}

	var foes := all_units.filter(
		func(u: Unit) -> bool: return u.is_alive() and u.is_hostile_to(unit)
	)
	if foes.is_empty():
		return result

	var ability_id: String = unit.abilities[0] if not unit.abilities.is_empty() else "strike"
	var ability := Database.ability(ability_id)
	result["ability"] = ability_id

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

	var best_score := -INF
	for cell in candidates:
		var target := _best_target_from(cell, ability, unit, foes)
		var score := -float(field.cost_to(cell)) * 0.1
		if target != null:
			# Attacking beats repositioning; finish off the weakest reachable foe.
			score += 1000.0 - float(target.hp)
		else:
			score -= float(_distance_to_nearest(cell, foes))
		if score > best_score:
			best_score = score
			result["move_cell"] = cell
			result["target"] = target

	return result


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
