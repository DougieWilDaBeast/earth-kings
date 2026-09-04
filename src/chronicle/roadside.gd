class_name Roadside
extends RefCounted
## Things happening on the road that would have happened whether you came or not.
##
## The world's other fights are usually yours: something saw you, or you walked
## into it. A roadside scene is neither. Somebody else is losing, in front of
## you, and the only question is whether you get involved — which means walking
## away has to be a real option and has to cost something.
##
## Stepping in leads somewhere. The trader you pull out from under his cart
## pays you, then asks to be walked to the next town, and if you walk him there
## he keeps paying: a [b]route[/b] on [member World.routes] that pays a little
## at every upkeep for as long as it lasts. So a fight you did not have to take
## becomes an income you did not have before.
##
## Pure logic over `data/roadside.json`. Everything is kept on [World] so it
## saves and reloads with the country it happened in.

## How far a route pays for, in steps, before the arrangement lapses.
const ROUTE_LIFE := 900


static func rules() -> Dictionary:
	return Database.roadside.get("rules", {})


static func events() -> Dictionary:
	return Database.roadside.get("events", {})


static func event(event_id: String) -> Dictionary:
	return events().get(event_id, {})


# --- coming upon one ----------------------------------------------------------


## Is there a scene on this tile? Open country only: a fight in earshot of a
## town is the town's business, and one on top of the last is not a road, it is
## a corridor. Returns the event id, or an empty string.
static func look(world: World, cell: Vector2i) -> String:
	if escorting(world):
		return ""
	if world.steps - world.roadside_at < int(rules().get("rest_steps", 40)):
		return ""
	if _near_a_site(world, cell):
		return ""
	if world.rng.randf() >= float(rules().get("chance", 0.05)):
		return ""
	var ids: Array = events().keys()
	if ids.is_empty():
		return ""
	world.roadside_at = world.steps
	return str(ids[world.rng.randi() % ids.size()])


static func _near_a_site(world: World, cell: Vector2i) -> bool:
	var clear := int(rules().get("clear_of_sites", 3))
	for site: Site in world.sites:
		if absi(site.cell.x - cell.x) <= clear and absi(site.cell.y - cell.y) <= clear:
			return true
	return false


## What you see when you come over the rise.
static func seen(event_id: String) -> Array:
	return event(event_id).get("seen", [])


static func title(event_id: String) -> String:
	return str(event(event_id).get("title", "Something is happening on the road."))


## The fight, if you take it. Levelled off the party, so a scene found late is
## still worth stopping for.
static func meeting(world: World, cell: Vector2i, event_id: String, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	var enemies: Array = []
	var level := Encounter.party_level(party)
	for unit_id: String in event(event_id).get("pack", []):
		enemies.append({ "unit": unit_id, "level": maxi(1, level + rng.randi_range(-1, 1)) })
	return Encounter.for_roadside(world, cell, enemies, rng, title(event_id))


## What it costs to keep walking. Nobody sees you do it, but you know, and the
## country has a way of finding out what sort you are.
static func walk_by(world: World, cell: Vector2i, event_id: String) -> Array:
	var lines: Array = event(event_id).get("walked_by", []).duplicate()
	Renown.record(
		world, "thread", cell, int(rules().get("renown_walked_by", -2)),
		"stood by while %s" % title(event_id).to_lower().trim_suffix(".")
	)
	return lines


# --- after the fight ----------------------------------------------------------


## They are alive because you stopped. Pays the purse, sets the reputation, and
## hands back whether there is an escort on offer.
static func saved(world: World, cell: Vector2i, event_id: String, party: Array) -> Array:
	var data := event(event_id)
	var lines: Array = data.get("saved", []).duplicate()

	var purse := int(rules().get("purse_base", 55)) \
		+ int(rules().get("purse_per_level", 22)) * Encounter.party_level(party)
	GameState.gold += purse
	lines.append("There is %d gold in it, counted out on the boards." % purse)

	Renown.record(
		world, "thread", cell, int(rules().get("renown_saved", 3)),
		"pulled somebody off the road at %s" % _place(world, cell)
	)

	if bool(data.get("escort", false)):
		var to := _somewhere_to_take_them(world, cell)
		if to != null:
			world.escort = {
				"event": event_id,
				"to": [to.cell.x, to.cell.y],
				"from": [cell.x, cell.y],
				"since": world.steps,
			}
			for line: String in data.get("asks", []):
				lines.append(line % to.display_name if line.contains("%s") else line)
			lines.append("[Guiding them to %s. Get there before they give up on you.]" % to.display_name)
	return lines


## The nearest settlement that is not the one you are standing on top of.
static func _somewhere_to_take_them(world: World, cell: Vector2i) -> Site:
	var span := int(rules().get("escort_span", 26))
	var best: Site = null
	var best_far := span * span
	for site: Site in world.sites:
		if not Town.is_settlement(site) or Town.is_ruined(site):
			continue
		var far: int = (site.cell - cell).length_squared()
		if far > 4 and far < best_far:
			best = site
			best_far = far
	return best


# --- walking them home --------------------------------------------------------


static func escorting(world: World) -> bool:
	return world.escort.has("to")


## Where they are trying to get to, or null.
static func destination(world: World) -> Site:
	if not escorting(world):
		return null
	var to: Array = world.escort["to"]
	return world.site_at(Vector2i(int(to[0]), int(to[1])))


## The line for the hint bar while somebody is walking behind you.
static func escort_prompt(world: World) -> String:
	var to := destination(world)
	if to == null:
		return ""
	var left := int(rules().get("escort_patience", 260)) - (world.steps - int(world.escort.get("since", 0)))
	return "Guiding somebody to %s — %d steps of patience left." % [to.display_name, maxi(0, left)]


## Called on arriving anywhere. Pays out if this is the place, and gives up on
## you if it took too long.
static func on_arrive(world: World, site: Site, party: Array) -> Array:
	if not escorting(world) or site == null:
		return _check_patience(world)
	var to := destination(world)
	if to == null or to.cell != site.cell:
		return _check_patience(world)

	var paid := int(rules().get("delivery_base", 90)) \
		+ int(rules().get("delivery_per_level", 30)) * Encounter.party_level(party)
	GameState.gold += paid

	var from_pair: Array = world.escort.get("from", [site.cell.x, site.cell.y])
	var from := Vector2i(int(from_pair[0]), int(from_pair[1]))
	world.escort = {}

	var lines: Array = [
		"%s takes them in, and they are somebody's problem but yours now." % site.display_name,
		"They pay you %d gold, and mean the rest of it." % paid,
	]
	lines.append_array(_open_route(world, from, site))
	Renown.record(
		world, "thread", site.cell, int(rules().get("renown_delivered", 2)),
		"saw somebody safely into %s" % site.display_name
	)
	return lines


## Somebody who has been left walking too long stops walking.
static func _check_patience(world: World) -> Array:
	if not escorting(world):
		return []
	var patience := int(rules().get("escort_patience", 260))
	if world.steps - int(world.escort.get("since", 0)) < patience:
		return []
	world.escort = {}
	return ["Whoever was walking with you has stopped walking with you."]


# --- routes -------------------------------------------------------------------


## An arrangement between two places, paying a little at every upkeep. The
## oldest is dropped when there are too many: goodwill does not stack forever.
static func _open_route(world: World, from: Vector2i, to: Site) -> Array:
	var pay := int(rules().get("route_pay", 18))
	world.routes.append({
		"to": [to.cell.x, to.cell.y],
		"from": [from.x, from.y],
		"name": to.display_name,
		"pay": pay,
		"since": world.steps,
	})
	var cap := int(rules().get("route_cap", 5))
	var dropped := ""
	while world.routes.size() > cap:
		dropped = str(world.routes[0].get("name", ""))
		world.routes.pop_front()
	Annals.record(world, "A commercial road opened to %s (%d gold per upkeep)." % [to.display_name, pay])
	var lines: Array = [
		"A road you can send goods down. %s pays %d a season, so long as it lasts." % [
			to.display_name, pay
		]
	]
	if dropped != "":
		lines.append("The arrangement with %s lapses to make room for it." % dropped)
	return lines


## Every route pays, and the old ones quietly stop.
static func upkeep(world: World) -> Array:
	if world.routes.is_empty():
		return []
	var lines: Array = []
	var takings := 0
	var lapsed: Array = []
	for route: Dictionary in world.routes:
		if world.steps - int(route.get("since", 0)) > ROUTE_LIFE:
			lapsed.append(route)
			continue
		takings += int(route.get("pay", 0))
	for route: Dictionary in lapsed:
		world.routes.erase(route)
		lines.append("The %s road stops paying. These things run their course." % route.get("name", ""))
	if takings > 0:
		GameState.gold += takings
		lines.append("%d gold comes in off the roads." % takings)
	return lines


## The routes as lines, for a readout.
static func summary(world: World) -> Array:
	var lines: Array = []
	for route: Dictionary in world.routes:
		lines.append("%s  —  %d a season" % [route.get("name", ""), int(route.get("pay", 0))])
	return lines


static func _place(world: World, cell: Vector2i) -> String:
	var near := ""
	var best := 999999
	for site: Site in world.sites:
		var far: int = (site.cell - cell).length_squared()
		if far < best:
			best = far
			near = site.display_name
	return near if near != "" else "the open road"
