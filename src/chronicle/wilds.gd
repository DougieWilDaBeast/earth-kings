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
const Biome := preload("res://src/chronicle/biome.gd")


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
	var said := str(Database.area(str(site.data.get("area", ""))).get("found_line", rules().get("found_line", "{wild}.")))
	return said.format({ "wild": site.display_name.capitalize(), "lure": lure_of(site) })


## The flag the guard of [param site] sets when beaten: the key `stock` gives it, as a done flag.
static func guard_flag(site: Site) -> String:
	return "done:wild_guard_%s_%d_%d" % [str(site.data.get("area", "")), site.cell.x, site.cell.y]


## Whether [param site] is kept by a guard at all: a wild with no chest (a caravan, [D334]) has none,
## so no job is posted or taken to clear it.
static func guarded(site: Site) -> bool:
	return site != null and not (Database.area(str(site.data.get("area", ""))).get("chests", []) as Array).is_empty()


## Whether the guard of [param site] has been beaten this run.
static func cleared(site: Site) -> bool:
	return GameState.has_flag(guard_flag(site))


## The wild's guard ([D287]: creatures that match the land): a band of the land's own foes by the chest
## farthest from the way in, at the party's level, added to [param bands] (the area's own). Who stands
## there is the land at [param cell] on the map (`biomes.json` → `foes`, the great beasts held back by
## `foe_levels`), else the faction that walks the ground; dealt its tiers. Beaten, it stays beaten for
## the run. Nothing is added to a wild with no chest, or with formations of its own already.
static func stock(map: AreaMap, world: World, cell: Vector2i, party: Array, bands: Array) -> Array:
	var r := rules()
	if world == null or map == null or map.chests.is_empty() or int(r.get("guard_size", 0)) <= 0:
		return bands
	var far_chest := Vector2i(-1, -1)
	var best := -1
	for chest: Vector2i in map.chests:
		var far := Pathfinder.distance(map.spawn, chest)
		if far > best:
			best = far
			far_chest = chest
	var at := Vector2i(-1, -1)
	for step: Vector2i in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i(1, 1), Vector2i(-1, 1)]:
		var spot := far_chest + step
		if map.is_walkable(spot) and not map.chests.has(spot) and not map.spots.has(spot):
			at = spot
			break
	if at.x < 0:
		return bands
	var level := maxi(1, Encounter.party_level(party))
	var land := Biome.at(world, cell)
	var foes: Array = Biome.data(land).get("foes", []).duplicate()
	var gates: Dictionary = Database.biomes.get("foe_levels", {})
	foes = foes.filter(func(id: String) -> bool: return int(gates.get(id, 0)) <= level)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.world_seed, map.id, cell.x, cell.y, "wild guard"])
	if foes.is_empty():
		foes = Faction.pool(Faction.pick_on(world.terrain_id_at(cell), rng), level)
	if foes.is_empty():
		return bands
	var pack: Array = []
	for i in int(r.get("guard_size", 3)):
		pack.append(str(foes[rng.randi() % foes.size()]))
	pack = Tiers.deal_pack(pack, level, rng)
	var key := "wild_guard_%s_%d_%d" % [map.id, cell.x, cell.y]
	var first := str(Database.unit_template(str(pack[0])).get("display_name", "Something"))
	var what := first if pack.size() == 1 else "%s and %d more" % [first, pack.size() - 1]
	var out := bands.duplicate()
	out.append({
		"key": key, "pack": pack, "level": level,
		"label": str(Database.area(map.id).get("guard_label", r.get("guard_label", "{what} of {land}"))).format({ "what": what, "land": Biome.display_name(land).to_lower() }),
		"faction": "", "at": [at.x, at.y], "reach": int(r.get("guard_reach", 3)), "held": true,
		"requires_not": "done:%s" % key, "done_flag": "done:%s" % key,
	})
	return out

