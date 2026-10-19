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

const Coins := preload("res://src/chronicle/coins.gd")
const Atlas := preload("res://src/chronicle/atlas.gd")

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
## a corridor. Returns the event id, or an empty string. [param forced] is the road's clock calling
## for one ([D286]): no rest and no dice, the rest of the rules the same.
static func look(world: World, cell: Vector2i, forced: bool = false) -> String:
	# Hidden in the First Hour until its people and cart are drawn (D121): a box that stops you with
	# nothing on screen, said the same way each time.
	if FirstHour.hides("roadside"):
		return ""
	if escorting(world):
		return ""
	if not forced and world.steps - world.roadside_at < int(rules().get("rest_steps", 40)):
		return ""
	# Near a town it is the town's Watch beset ([D215], `near_town` scenes); out in the open
	# country, everyone else's.
	# Never at a place's own door (it is the place's business), near a town or not.
	if _near_a_site(world, cell):
		return ""
	var by_town := near_town(world, cell)
	var chance := float(rules().get("near_town_chance", 0.0)) if by_town else float(rules().get("chance", 0.05))
	if not forced and world.rng.randf() >= chance:
		return ""
	var ids: Array = events().keys().filter(func(id) -> bool:
		return bool(event(str(id)).get("near_town", false)) == by_town)
	if ids.is_empty():
		return ""
	world.roadside_at = world.steps
	# A scene is the clock's happening too, so the next one waits its turn after it.
	world.happening_at = world.steps
	return str(ids[world.rng.randi() % ids.size()])


## Whether [param cell] is within `town_reach` of a town that is standing ([D215]): where its Watch
## goes out after whatever comes up off the open country. (Within `clear_of_sites` of any place there
## is no scene at all: a ring of road round each town, out past its gate.)
static func near_town(world: World, cell: Vector2i) -> bool:
	var reach := int(rules().get("town_reach", 0))
	if reach <= 0:
		return false
	for site: Site in world.sites:
		if Town.is_settlement(site) and not Town.is_ruined(site) \
				and absi(site.cell.x - cell.x) <= reach and absi(site.cell.y - cell.y) <= reach:
			return true
	return false


static func _near_a_site(world: World, cell: Vector2i, clear: int = -1) -> bool:
	if clear < 0:
		clear = int(rules().get("clear_of_sites", 3))
	for site: Site in world.sites:
		if absi(site.cell.x - cell.x) <= clear and absi(site.cell.y - cell.y) <= clear:
			return true
	return false


# --- the road's clock ---------------------------------------------------------
#
# Is it fun ([D286]): seven minutes from the crater to the gate with nothing in them, because a scene
# rests 40 steps and then comes on one step in twenty, and the walk from the crater to the gate is 25
# to 30 steps.
# So the road keeps a clock as well as its dice: every `every` steps (the first after `first_after`)
# something is on it, one of `kinds` by weight and never the same kind twice running. A `band` is
# stood on the road ahead to be fought on the ground ([D272]); a `scene` is one of the scenes above,
# called up; a `traveller` passes with a line (`travellers`), and one naming a gate puts it on the
# map; a `find` is something left by the road (`finds`). `clock` in `data/roadside.json`.


static func clock() -> Dictionary:
	return rules().get("clock", {})


## What the road's clock has put on [param cell], if anything is due: "band", "scene", "traveller",
## "find", or an empty string. Never at a place's door (`clock.clear_of_sites`), nor while walking
## somebody home; a step that is due but too near a place waits for the next.
static func due(world: World, cell: Vector2i) -> String:
	var paced := clock()
	var kinds: Dictionary = paced.get("kinds", {})
	if kinds.is_empty() or escorting(world):
		return ""
	if world.steps - world.happening_at < gap(world):
		return ""
	if _near_a_site(world, cell, int(paced.get("clear_of_sites", 2))):
		return ""
	var kind := _pick_kind(world, kinds)
	world.happening_at = world.steps
	world.happening_last = kind
	return kind


## Steps from the last happening to the next: `first_after` from a new world's first step, then
## somewhere in `every` ([min, max]), read off the seed and the step so the dice fall as they did.
static func gap(world: World) -> int:
	var paced := clock()
	if world.happening_at <= 0:
		return int(paced.get("first_after", 6))
	var every: Array = paced.get("every", [10, 14])
	var low := int(every[0]) if every.size() > 0 else 10
	var high := maxi(low, int(every[1]) if every.size() > 1 else low)
	return low + absi(hash([world.world_seed, world.happening_at, "road_clock"])) % (high - low + 1)


static func _pick_kind(world: World, kinds: Dictionary) -> String:
	var pool: Array = kinds.keys().filter(func(k) -> bool: return str(k) != world.happening_last)
	if pool.is_empty():
		pool = kinds.keys()
	pool.sort()
	var total := 0
	for k in pool:
		total += maxi(0, int(kinds[k]))
	if total <= 0:
		return str(pool[0])
	var roll := absi(hash([world.world_seed, world.steps, "road_kind"])) % total
	for k in pool:
		roll -= maxi(0, int(kinds[k]))
		if roll < 0:
			return str(k)
	return str(pool[-1])


## Somebody passing the other way, and what they say: a list of lines, empty when nobody fits.
## `{town}` is the nearest standing town, `{gate}` the nearest open gate and `{gate_way}` how far
## and which way it lies; a traveller who names a gate puts it on the map.
static func traveller(world: World, cell: Vector2i) -> Array:
	var town := _nearest(world, cell, func(s: Site) -> bool:
		return Town.is_settlement(s) and not Town.is_ruined(s))
	var gate := _nearest(world, cell, func(s: Site) -> bool:
		return s.kind == Site.GATE and s.open and not s.cleared)
	var fits: Array = Database.roadside.get("travellers", []).filter(func(t: Dictionary) -> bool:
		var said := " ".join(t.get("lines", []))
		return (town != null or not said.contains("{town}")) and (gate != null or not said.contains("{gate"))
	)
	if fits.is_empty():
		return []
	var one: Dictionary = fits[absi(hash([world.world_seed, world.steps, "traveller"])) % fits.size()]
	var fill := {
		"town": town.display_name if town != null else "",
		"gate": gate.display_name if gate != null else "",
		"gate_way": bearing(cell, gate.cell) if gate != null else "",
	}
	var lines: Array = [str(one.get("who", "Somebody passes you on the road."))]
	for line: String in one.get("lines", []):
		lines.append(line.format(fill))
	if gate != null and " ".join(one.get("lines", [])).contains("{gate") and Atlas.mark(world, gate):
		lines.append("You put %s on the map where they said." % gate.display_name)
	return lines


## The line said over something left by the road (`finds.lines`), and how rich it is.
static func find_line(world: World) -> String:
	var lines: Array = Database.roadside.get("finds", {}).get("lines", [])
	if lines.is_empty():
		return "Something has been left by the road."
	return str(lines[absi(hash([world.world_seed, world.steps, "find"])) % lines.size()])


static func find_richness() -> float:
	return float(Database.roadside.get("finds", {}).get("richness", 0.8))


## What is said as a band is seen on the road ahead (`band_lines`).
static func band_line(world: World) -> String:
	var lines: Array = Database.roadside.get("band_lines", [])
	if lines.is_empty():
		return "Something is moving on the road ahead."
	return str(lines[absi(hash([world.world_seed, world.steps, "band"])) % lines.size()])


static func _nearest(world: World, cell: Vector2i, keep: Callable) -> Site:
	var best: Site = null
	var best_d := 1 << 20
	for site: Site in world.sites:
		if not keep.call(site):
			continue
		var d := Pathfinder.distance(site.cell, cell)
		if d < best_d:
			best_d = d
			best = site
	return best


## What you see when you come over the rise.
static func seen(event_id: String) -> Array:
	return event(event_id).get("seen", [])


static func title(event_id: String) -> String:
	return str(event(event_id).get("title", "Something is happening on the road."))


## The fight, if you take it. Levelled off the party, so a scene found late is
## still worth stopping for. Whoever the scene's `allies` are (the Watch beset, [D215]) fight beside
## the party, at its level.
static func meeting(world: World, cell: Vector2i, event_id: String, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	var enemies: Array = []
	var level := Encounter.party_level(party)
	for unit_id: String in event(event_id).get("pack", []):
		enemies.append({ "unit": unit_id, "level": maxi(1, level + rng.randi_range(-1, 1)) })
	var met := Encounter.for_roadside(world, cell, enemies, rng, title(event_id))
	var allies: Array = []
	for each: Dictionary in event(event_id).get("stage", {}).get("allies", []):
		allies.append({ "unit": str(each.get("unit", "")), "level": maxi(1, level), "name": str(each.get("name", "")) })
	if not allies.is_empty() and met.has("map"):
		BattleMapGen.add_allies(met["map"], allies)
	return met


## What it costs to keep walking. Nobody sees you do it, but you know, and the
## country has a way of finding out what sort you are.
static func walk_by(world: World, cell: Vector2i, event_id: String) -> Array:
	var lines: Array = event(event_id).get("walked_by", []).duplicate()
	var what := "stood by while %s" % title(event_id).to_lower().trim_suffix(".")
	Renown.record(world, "thread", cell, int(rules().get("renown_walked_by", -2)), what, what)
	return lines


# --- after the fight ----------------------------------------------------------


## A band led to the Watch on the road and beaten with them ([D236]): the Watch's bounty, counted
## off the company's level, and the country hears of it. `life.road_watch` in `world_rules.json`.
static func watch_thanks(world: World, cell: Vector2i, party: Array) -> Array:
	var watch: Dictionary = Database.world_rules.get("life", {}).get("road_watch", {})
	var lines: Array = watch.get("thanks", []).duplicate()
	var purse := int(watch.get("purse_base", 650)) + int(watch.get("purse_per_level", 250)) * Encounter.party_level(party)
	GameState.gold += purse
	lines.append(str(watch.get("purse_line", "%s: the Watch's bounty.")) % Coins.text(purse))
	var what := "fought a band off the road beside the Watch"
	Renown.record(world, "thread", cell, int(watch.get("renown", 2)), what, what)
	return lines


## They are alive because you stopped. Pays the purse, sets the reputation, and
## hands back whether there is an escort on offer.
static func saved(world: World, cell: Vector2i, event_id: String, party: Array) -> Array:
	var data := event(event_id)
	var lines: Array = data.get("saved", []).duplicate()

	var purse := int(rules().get("purse_base", 1400)) \
		+ int(rules().get("purse_per_level", 550)) * Encounter.party_level(party)
	GameState.gold += purse
	lines.append(str(data.get("purse_line", "There is %s in it, counted out on the boards.")) % Coins.text(purse))

	var what := "pulled somebody off the road at %s" % _place(world, cell)
	Renown.record(world, "thread", cell, int(rules().get("renown_saved", 3)), what, what)

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
	var guide := bearing(world.player_cell, to.cell)
	return "Guiding somebody to %s (%s) — %d steps of patience left." % [
		to.display_name, guide, maxi(0, left)
	]


## Compass direction and distance between two points.
static func bearing(from: Vector2i, to: Vector2i) -> String:
	var delta := to - from
	var dist := roundi(sqrt(delta.x * delta.x + delta.y * delta.y))
	var angle := rad_to_deg(atan2(delta.y, delta.x))
	var dir := "E"
	if angle >= -22.5 and angle < 22.5:
		dir = "E"
	elif angle >= 22.5 and angle < 67.5:
		dir = "SE"
	elif angle >= 67.5 and angle < 112.5:
		dir = "S"
	elif angle >= 112.5 and angle < 157.5:
		dir = "SW"
	elif angle >= -67.5 and angle < -22.5:
		dir = "NE"
	elif angle >= -112.5 and angle < -67.5:
		dir = "N"
	elif angle >= -157.5 and angle < -112.5:
		dir = "NW"
	else:
		dir = "W"
	return "%d leagues %s" % [dist, dir]


## Called on arriving anywhere. Pays out if this is the place, and gives up on
## you if it took too long.
static func on_arrive(world: World, site: Site, party: Array) -> Array:
	if not escorting(world) or site == null:
		return _check_patience(world)
	var to := destination(world)
	if to == null or to.cell != site.cell:
		return _check_patience(world)

	var paid := int(rules().get("delivery_base", 2250)) \
		+ int(rules().get("delivery_per_level", 750)) * Encounter.party_level(party)
	GameState.gold += paid

	var from_pair: Array = world.escort.get("from", [site.cell.x, site.cell.y])
	var from := Vector2i(int(from_pair[0]), int(from_pair[1]))
	world.escort = {}

	var lines: Array = [
		"%s takes them in, and they are somebody's problem but yours now." % site.display_name,
		"They pay you %s, and mean the rest of it." % Coins.text(paid),
	]
	lines.append_array(_open_route(world, from, site))
	var what := "saw somebody safely into %s" % site.display_name
	Renown.record(world, "thread", site.cell, int(rules().get("renown_delivered", 2)), what, what, site.display_name)
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
	var pay := int(rules().get("route_pay", 450))
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
	Annals.record(world, "A commercial road opened to %s (%s per upkeep)." % [to.display_name, Coins.text(pay)])
	var lines: Array = [
		"A road you can send goods down. %s pays %s a season, so long as it lasts." % [
			to.display_name, Coins.text(pay)
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
		lines.append("%s comes in off the roads." % Coins.text(takings))
	return lines


## The routes as lines, for a readout.
static func summary(world: World) -> Array:
	var lines: Array = []
	for route: Dictionary in world.routes:
		lines.append("%s  —  %s a season" % [route.get("name", ""), Coins.text(int(route.get("pay", 0)))])
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
