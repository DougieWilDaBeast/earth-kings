extends RefCounted
## Places worth going to ([D287], [D309]): the wilds on the map. The founders: "places worth going to
## (loot, a quest or a story in each, walls for the reading hall, hamlets, caravans)". The ancient
## grove, the thorn thicket, the drowned fen, the quiet oasis and the wind scarp were stumbled on, one
## tile in sixteen; now `tools/place_wilds.py` puts a dozen of them on the one world's map as sites of
## kind `wild`, each on its own kind of ground, unknown until the party walks onto one or hears of it
## at rest in a settlement, which marks it on the map and says what it holds (each area's `lure`).
## Rules in `world_rules.json` → `wilds`. Loaded by path ([D41]). Pure logic: no nodes.

const Atlas := preload("res://src/chronicle/atlas.gd")
const Fall := preload("res://src/chronicle/fall.gd")


static func rules() -> Dictionary:
	return Database.world_rules.get("wilds", {})


## Every wild place on [param world]'s map.
static func all(world: World) -> Array[Site]:
	return world.sites_of_kind(Site.WILD)


## What a wild place holds, in the host's words: its area's `lure`.
static func lure_of(site: Site) -> String:
	return str(Database.area(str(site.data.get("area", ""))).get("lure", "what the wild keeps"))


## The nearest wild place within [param within] tiles of [param from] that the party does not know
## of yet, or null.
static func nearest_unknown(world: World, from: Vector2i, within: int) -> Site:
	var best: Site = null
	var best_far := within + 1
	for site: Site in all(world):
		if Atlas.knows(world, site):
			continue
		var far := Pathfinder.distance(from, site.cell)
		if far <= within and far < best_far:
			best = site
			best_far = far
	return best


## At rest in [param site], the host speaks of the nearest wild place not yet known, which is marked
## on the map; the line said, or "" when there is none in range.
static func rumour(world: World, site: Site) -> String:
	var r := rules()
	var place := nearest_unknown(world, site.cell, int(r.get("rumour_within", 36)))
	if place == null:
		return ""
	Atlas.mark(world, place)
	var steps := Pathfinder.distance(site.cell, place.cell)
	var days := maxi(1, roundi(float(steps) / float(maxi(1, int(r.get("steps_per_day", 8))))))
	return str(r.get("rumour_line", "{host} speaks of {wild}, {way} of here: {lure}.")).format({
		"host": "The host" if site.kind != Site.KEEP else "The keeper",
		"wild": place.display_name,
		"way": Fall.way(site.cell, place.cell),
		"days": "a day" if days == 1 else "%d days" % days,
		"lure": lure_of(place),
	})


## Walked into for the first time: a line, and a page in the annals. Nothing the second time.
static func found(world: World, site: Site) -> String:
	if site == null or site.kind != Site.WILD or bool(site.data.get("found", false)):
		return ""
	site.data["found"] = true
	Atlas.mark(world, site)
	Annals.record(world, "%s was found, %s." % [site.display_name.capitalize(), lure_of(site)])
	return str(rules().get("found_line", "{wild}.")).format({ "wild": site.display_name.capitalize(), "lure": lure_of(site) })
