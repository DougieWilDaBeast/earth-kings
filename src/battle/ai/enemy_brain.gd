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
	for option in options:
		var cell: Vector2i = option["cell"]
		var target := _best_target_from(cell, ability, unit, foes)
		var score: float = -float(option["cost"])
		if target != null:
			# Attacking beats repositioning; finish off the weakest reachable foe,
			# and break ties towards the tile that lands on a softer face.
			score += 1000.0 - float(target.hp)
			score += AbilityResolver.flank_multiplier(cell, target) * 20.0
		else:
			score -= float(_distance_to_nearest(cell, foes))
		if score > best_score:
			best_score = score
			result["move_cell"] = cell
			result["target"] = target
			result["flash"] = option["flash"]

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
