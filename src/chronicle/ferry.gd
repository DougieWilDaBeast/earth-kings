class_name Ferry
extends RefCounted
## Passage by cutter or skiff between coastal havens across the continent.
##
## On a 128x128 map bounded by oceans and severed by inland lakes, walking around
## deep bays and sounds costs hundreds of steps. A coastal settlement with access
## to deep water offers passage to other ports for a modest fare.

const BASE_FARE := 25
const FARE_PER_TILE := 0.6
const PASSAGE_STEPS_RATIO := 0.4


static func is_port(world: World, cell: Vector2i) -> bool:
	var site := world.site_at(cell)
	if site == null or not Town.is_settlement(site) or Town.is_ruined(site):
		if site == null or site.data.get("area", "") != "village_shore":
			return false
	return _touches_water(world, cell)


static func ports(world: World) -> Array[Site]:
	var out: Array[Site] = []
	for site in world.sites:
		if is_port(world, site.cell):
			out.append(site)
	return out


static func next_port(world: World, from_cell: Vector2i) -> Site:
	var all_ports := ports(world)
	if all_ports.size() <= 1:
		return null
	var current := world.site_at(from_cell)
	var best: Site = null
	var best_dist := 999999
	for port in all_ports:
		if current != null and port.cell == current.cell:
			continue
		var dist: int = (port.cell - from_cell).length_squared()
		if dist > 9 and dist < best_dist:
			best_dist = dist
			best = port
	return best


static func fare(world: World, from: Site, to: Site) -> int:
	if from == null or to == null:
		return BASE_FARE
	var dist := Pathfinder.distance(from.cell, to.cell)
	return roundi(BASE_FARE + dist * FARE_PER_TILE)


static func passage_steps(from: Site, to: Site) -> int:
	if from == null or to == null:
		return 15
	var dist := Pathfinder.distance(from.cell, to.cell)
	return maxi(8, roundi(dist * PASSAGE_STEPS_RATIO))


static func sail(world: World, from: Site, to: Site) -> Dictionary:
	if from == null or to == null:
		return { "success": false, "line": "Nowhere to cast off for." }
	var cost := fare(world, from, to)
	if GameState.gold < cost:
		return { "success": false, "line": "The boatman wants %d gold for passage, and you are short." % cost }
	GameState.gold -= cost
	var elapsed := passage_steps(from, to)
	world.steps += elapsed
	world.player_cell = to.cell
	return {
		"success": true,
		"steps": elapsed,
		"cost": cost,
		"line": "The cutter cuts through the grey swell. After %d leagues at sea, you come ashore at %s." % [
			elapsed, to.display_name
		]
	}


static func _touches_water(world: World, cell: Vector2i) -> bool:
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var check := cell + Vector2i(dx, dy)
			if not world.in_bounds(check):
				return true
			var t := world.terrain_id_at(check)
			if t == "water" or t == "ocean" or t == "lake":
				return true
	return false
