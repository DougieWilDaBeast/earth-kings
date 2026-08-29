class_name TurnManager
extends Node
## Charge-time turn order: every tick each living unit gains CT equal to its
## speed; the first to reach 100 acts, then pays 100 back. Fast units therefore
## act more often rather than simply acting earlier.

const CT_THRESHOLD := 100

var units: Array[Unit] = []
var round_count: int = 0


func setup(all_units: Array[Unit]) -> void:
	units = all_units
	round_count = 0


func living_units() -> Array[Unit]:
	return units.filter(func(u: Unit) -> bool: return u.is_alive())


## Advance the clock until someone is ready. Returns null if the battle is over.
func advance() -> Unit:
	var alive := living_units()
	if alive.is_empty():
		return null
	if alive.all(func(u: Unit) -> bool: return u.speed <= 0):
		push_error("TurnManager: every living unit has speed <= 0, no turn can start")
		return null

	while true:
		var ready := alive.filter(func(u: Unit) -> bool: return u.ct >= CT_THRESHOLD)
		if not ready.is_empty():
			ready.sort_custom(_by_ct_desc)
			return ready[0]
		round_count += 1
		for unit in alive:
			unit.ct += unit.speed
	return null


func end_turn(unit: Unit) -> void:
	# Anyone who acted before their charge was full pays only what they had, so
	# the party's slower members never sink into permanent debt.
	unit.ct = maxi(0, unit.ct - CT_THRESHOLD)


## Who acts next. Enemies come one at a time; when a player unit is ready the
## whole living party takes the phase together, so any of them can be played in
## any order. Everyone who takes part pays the full 100 CT for it.
func advance_group() -> Array[Unit]:
	var leader := advance()
	if leader == null:
		return []
	if leader.team != Unit.Team.PLAYER:
		return [leader]
	var squad: Array[Unit] = living_units().filter(
		func(u: Unit) -> bool: return u.team == Unit.Team.PLAYER
	)
	squad.sort_custom(_by_ct_desc)
	return squad


## Non-destructive lookahead for the turn-order bar in the HUD.
func forecast(count: int) -> Array[Unit]:
	var alive := living_units()
	var simulated: Dictionary = {}
	for unit in alive:
		simulated[unit] = unit.ct

	var order: Array[Unit] = []
	var guard := 0
	while order.size() < count and guard < 10000:
		guard += 1
		var best: Unit = null
		for unit: Unit in simulated:
			if simulated[unit] >= CT_THRESHOLD:
				if best == null or simulated[unit] > simulated[best]:
					best = unit
		if best == null:
			for unit: Unit in simulated:
				simulated[unit] += unit.speed
			continue
		order.append(best)
		if best.team != Unit.Team.PLAYER:
			simulated[best] -= CT_THRESHOLD
			continue
		# The party comes up as a single phase, so the bar bills it as one.
		for unit: Unit in simulated:
			if unit.team == Unit.Team.PLAYER:
				simulated[unit] -= CT_THRESHOLD
	return order


func _by_ct_desc(a: Unit, b: Unit) -> bool:
	if a.ct == b.ct:
		return a.speed > b.speed
	return a.ct > b.ct
