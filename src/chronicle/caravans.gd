extends RefCounted
## Caravans ([D287]: "places worth going to (... hamlets, caravans)"; [D330]): wild places that walk.
## A caravan is a site of kind `wild` whose `data.caravan` is its round, `route` (the towns it goes
## between, as cells), the `leg` it is on and how long it `rest`s. Every upkeep it rolls a few tiles on
## towards the next town by the way a party would walk (`Route.between`), stands off the road outside it
## for a while, then sets off for the one after. It never rolls while the party is close, nor onto
## another place, so it is never pulled out from under anyone; heard of at rest or seen, it stays on the
## map where it has got to. Rules in `world_rules.json` → `caravans`. Loaded by path ([D41]). Pure
## logic: no nodes.

const Route := preload("res://src/world/route.gd")


static func rules() -> Dictionary:
	return Database.world_rules.get("caravans", {})


## Every caravan on [param world]'s map.
static func all(world: World) -> Array[Site]:
	return world.sites.filter(func(s: Site) -> bool: return s.kind == Site.WILD and s.data.has("caravan"))


## The rounds as whole numbers, as a save gives them back: the map's file reads every number as a
## float, a loaded save as an int.
static func settle(world: World) -> void:
	for site: Site in all(world):
		var round: Dictionary = site.data["caravan"]
		var route: Array = []
		for stop: Array in round.get("route", []):
			route.append([int(stop[0]), int(stop[1])])
		round["route"] = route
		round["leg"] = int(round.get("leg", 0))
		round["rest"] = int(round.get("rest", 0))


## Each caravan's roll for this upkeep. Returns nothing to say: a caravan is come upon, not announced.
static func upkeep(world: World) -> Array:
	for site: Site in all(world):
		roll(world, site)
	return []


## Move [param site] on for one upkeep; true when it moved.
static func roll(world: World, site: Site) -> bool:
	var r := rules()
	var round: Dictionary = site.data["caravan"]
	var route: Array = round.get("route", [])
	if route.is_empty():
		return false
	var clear := int(r.get("party_clear", 2))
	if _near(site.cell, world.player_cell, clear):
		return false
	if int(round.get("rest", 0)) > 0:
		round["rest"] = int(round["rest"]) - 1
		return false
	var leg := int(round.get("leg", 0)) % route.size()
	var town := Vector2i(int(route[leg][0]), int(route[leg][1]))
	if _near(site.cell, town, int(r.get("stand_off", 2))):
		round["leg"] = (leg + 1) % route.size()
		round["rest"] = int(r.get("rest_upkeeps", 2))
		return false
	var way := Route.between(world, site.cell, town, int(r.get("longest", 240)))
	# The farthest it may stand of the next few tiles; past a town on the way, the first beyond it.
	var tiles := int(r.get("tiles_per_upkeep", 3))
	var go := Vector2i(-1, -1)
	for i in mini(tiles * 2, way.size()):
		var cell: Vector2i = way[i]
		if (i < tiles or go.x < 0) and _fit(world, site, cell, clear):
			go = cell
			if i >= tiles:
				break
	if go.x < 0:
		return false
	var known := world.marked.has(_key(site.cell))
	world.marked.erase(_key(site.cell))
	site.cell = go
	if known:
		world.marked[_key(go)] = true
	return true


## Whether [param site] may stand at [param cell]: on open ground, off every other place and the ring
## round it, and out of the party's sight.
static func _fit(world: World, site: Site, cell: Vector2i, clear: int) -> bool:
	if not world.is_walkable(cell) or _near(cell, world.player_cell, clear):
		return false
	var apart := int(rules().get("clear_of_sites", 2))
	for other: Site in world.sites:
		if other != site and _near(cell, other.cell, apart):
			return false
	return true


static func _near(a: Vector2i, b: Vector2i, within: int) -> bool:
	return maxi(absi(a.x - b.x), absi(a.y - b.y)) <= within


static func _key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]
