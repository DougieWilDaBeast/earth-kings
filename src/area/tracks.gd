extends RefCounted
## Dirt tracks between the places people live, and signposts where the ways meet ([D221]).
##
## `doug-md`, play-test 4: "Loving the designs of the open plains... Just needs a lot more...
## Maybe set up some signposting and... a lot more... dirt [roads], paths"; of the kinds of way he
## was offered he picked footpaths and dirt tracks. The footpaths are every tile's worn paths
## ([code]ground_gen.gd[/code]); the tracks are laid here: each village, keep, hut and library
## joined to its nearest neighbours (`tracks` in `data/world_rules.json`: how many, how far), by the
## way a party would walk it ([code]src/world/route.gd[/code]). The First Hour's road
## ([code]first_road.gd[/code]) is laid over them where they share a tile.
##
## Worked out once per world, like the road; a tile on a track knows which of its sides the track
## leaves by. Where three or more ways leave an open tile, a signpost stands by where its paths
## meet, naming the nearest place each way.
##
## Loaded by path, not by `class_name` ([D41]).

const Route := preload("res://src/world/route.gd")
const FirstRoad := preload("res://src/area/first_road.gd")
const SIDE_OF := {
	Vector2i.UP: "north", Vector2i.DOWN: "south", Vector2i.LEFT: "west", Vector2i.RIGHT: "east",
}
const STEP_OF := {
	"north": Vector2i.UP, "south": Vector2i.DOWN, "west": Vector2i.LEFT, "east": Vector2i.RIGHT,
}
const ORDER := ["north", "east", "south", "west"]

## World shape seed -> tile -> the sides the tracks leave it by.
static var _laid: Dictionary = {}


static func rules() -> Dictionary:
	return Database.world_rules.get("tracks", {})


## The sides of [param tile] a track leaves by, or none.
static func sides(world: World, tile: Vector2i) -> Array:
	var key := world.shape_seed()
	if not _laid.has(key):
		if _laid.size() > 4:
			_laid.clear()
		_laid[key] = _lay(world)
	return (_laid[key] as Dictionary).get(tile, [])


## Every way leaving [param tile]: the road's and the tracks', each side once.
static func ways(world: World, tile: Vector2i) -> Array:
	var out: Array = []
	for side: String in ORDER:
		if FirstRoad.sides(world, tile).has(side) or sides(world, tile).has(side):
			out.append(side)
	return out


## The places the tracks join, in the order the world lists them.
static func places(world: World) -> Array[Site]:
	var out: Array[Site] = []
	for site: Site in world.sites:
		if _joins(site):
			out.append(site)
	return out


static func _joins(site: Site) -> bool:
	var kinds: Array = rules().get("kinds", ["village", "keep", "hut", "library"])
	return kinds.has(site.kind) or bool(site.data.get("city", false))


static func _lay(world: World) -> Dictionary:
	var laid: Dictionary = {}
	var links := int(rules().get("links", 2))
	var reach := int(rules().get("reach", 22))
	var at := places(world)
	var joined: Dictionary = {}
	for site: Site in at:
		var nearest: Array = []
		for other: Site in at:
			if other == site:
				continue
			var apart := absi(other.cell.x - site.cell.x) + absi(other.cell.y - site.cell.y)
			if apart <= reach:
				nearest.append([apart, other])
		nearest.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
		for pair: Array in nearest.slice(0, links):
			var other: Site = pair[1]
			var key := [mini(site.cell.x * 1000 + site.cell.y, other.cell.x * 1000 + other.cell.y),
				maxi(site.cell.x * 1000 + site.cell.y, other.cell.x * 1000 + other.cell.y)]
			if joined.has(key):
				continue
			joined[key] = true
			var from := site.cell
			for next: Vector2i in Route.between(world, site.cell, other.cell, reach * 2):
				var step := next - from
				if SIDE_OF.has(step):
					_add(laid, from, SIDE_OF[step])
					_add(laid, next, SIDE_OF[-step])
				from = next
	return laid


static func _add(laid: Dictionary, tile: Vector2i, side: String) -> void:
	var on: Array = laid.get(tile, [])
	if not on.has(side):
		on.append(side)
	laid[tile] = on


## What the signpost on [param tile] says, or nothing when there is none: a signpost stands on open
## ground (no place on the tile) where three or more ways leave it, and names, for each way, the
## nearest place along it and how far.
static func signpost(world: World, tile: Vector2i) -> String:
	if world.site_at(tile) != null:
		return ""
	var leaving := ways(world, tile)
	if leaving.size() < int(rules().get("signpost_ways", 3)):
		return ""
	var said: Array[String] = []
	for side: String in leaving:
		var found := _along(world, tile, side)
		if found.is_empty():
			continue
		var tiles := int(found["tiles"])
		said.append("%s: %s, %d %s" % [side.capitalize(), found["name"], tiles, "tile" if tiles == 1 else "tiles"])
	if said.is_empty():
		return ""
	return "A signpost. " + "  ·  ".join(said) + "."


## The nearest place reached by walking the ways out of [param tile] by [param side]: `{ name,
## tiles }`, or nothing.
static func _along(world: World, tile: Vector2i, side: String) -> Dictionary:
	var first: Vector2i = tile + STEP_OF[side]
	var seen: Dictionary = { tile: true, first: true }
	var frontier: Array = [[first, 1]]
	var head := 0
	while head < frontier.size() and head < 4000:
		var entry: Array = frontier[head]
		head += 1
		var at: Vector2i = entry[0]
		var far: int = entry[1]
		# A signpost names where people live, and the Tower; not a gate, a grave or the crater.
		var site := world.site_at(at)
		if site != null and (site.kind == Site.TOWER or _joins(site)):
			return { "name": site.display_name, "tiles": far }
		for way: String in ways(world, at):
			var next: Vector2i = at + STEP_OF[way]
			if seen.has(next) or not world.in_bounds(next):
				continue
			seen[next] = true
			frontier.append([next, far + 1])
	return {}
