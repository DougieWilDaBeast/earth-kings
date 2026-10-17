extends RefCounted
## The player's own marks on the map ([D220], `doug-md`, play-tests 3 and 4): a place right-clicked
## on the map and marked ("Waypoint marker"), or one picked to go to ("Go to location").
##
## A marker is a quest like any other ([D190]): it is in the quest list, the compass and the corner
## map point at it when it is followed, and Auto walks to it and hands the party back on arriving.
## A place picked to go to is a marker of its own, one at a time, gone once the party stands there;
## a marker placed stays until it is taken off again.
##
## Kept in the run's flags as `[x, y, go]` triples, so a save carries them.
##
## Loaded by path, not by `class_name` ([D41]).

## The quest list's own flag for what is followed (`src/world/quests.gd`, FOLLOWED); named here
## rather than loaded, since the quest list loads this file.
const FOLLOWED := "quest:followed"

const Atlas := preload("res://src/chronicle/atlas.gd")

const FLAG := "map:markers"
## Markers placed at once; the oldest goes when one more is put down.
const MOST := 9
const PREFIX := "marker:"


## Every marker, oldest first: `{ cell, go }`.
static func all() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var kept: Variant = GameState.flags.get(FLAG, [])
	if not kept is Array:
		return out
	for each: Variant in kept:
		if each is Array and (each as Array).size() >= 2:
			out.append({
				"cell": Vector2i(int(each[0]), int(each[1])),
				"go": (each as Array).size() > 2 and bool(each[2]),
			})
	return out


static func at(cell: Vector2i) -> Dictionary:
	for each: Dictionary in all():
		if each["cell"] == cell:
			return each
	return {}


static func id_of(cell: Vector2i) -> String:
	return "%s%d,%d" % [PREFIX, cell.x, cell.y]


## Put a marker down on [param cell] (one already there stays as it is). Says what happened.
static func place(world: World, cell: Vector2i) -> String:
	if world == null or not world.in_bounds(cell):
		return ""
	var kept := all()
	for each: Dictionary in kept:
		if each["cell"] == cell:
			each["go"] = false
			_keep(kept)
			return "A marker is already there."
	kept.append({ "cell": cell, "go": false })
	var placed := kept.filter(func(m: Dictionary) -> bool: return not m["go"])
	if placed.size() > MOST:
		kept.erase(placed[0])
	_keep(kept)
	return "Marker %d placed on the map." % _number(cell)


## Take the marker off [param cell], and stop following it.
static func remove(cell: Vector2i) -> void:
	var kept := all().filter(func(m: Dictionary) -> bool: return m["cell"] != cell)
	_keep(kept)
	if str(GameState.flags.get(FOLLOWED, "")) == id_of(cell):
		GameState.flags.erase(FOLLOWED)


## Head for [param cell]: it becomes the place to go to (in place of the last one picked), the
## compass follows it, and the party walks itself there. Says what happened, or why not.
static func go_to(world: World, cell: Vector2i) -> String:
	if world == null or not world.in_bounds(cell):
		return ""
	if not world.is_walkable(cell):
		return "There is no walking there."
	if cell == world.player_cell:
		return "You are standing there."
	var kept := all().filter(func(m: Dictionary) -> bool: return not m["go"] or m["cell"] == cell)
	var marked := false
	for each: Dictionary in kept:
		if each["cell"] == cell:
			marked = true
	if not marked:
		kept.append({ "cell": cell, "go": true })
	_keep(kept)
	GameState.set_flag(FOLLOWED, id_of(cell))
	Pace.auto = true
	var tiles := Pathfinder.distance(world.player_cell, cell)
	return "The party sets off for %s, %d %s off." % [label_of(cell), tiles, "tile" if tiles == 1 else "tiles"]


## A place picked to go to is let go of once the party stands on it.
static func on_arrive(cell: Vector2i) -> void:
	var here := at(cell)
	if not here.is_empty() and bool(here["go"]):
		remove(cell)


## What the compass calls the marker on [param cell].
static func label_of(cell: Vector2i) -> String:
	var here := at(cell)
	if here.is_empty():
		return "the place"
	if bool(here["go"]):
		return _place_name(cell)
	return "Marker %d" % _number(cell)


## A place picked to go to goes by what is there: the place standing on it, or the country.
static func _place_name(cell: Vector2i) -> String:
	var world: World = GameState.world
	if world == null:
		return "the place you picked"
	var site := world.site_at(cell)
	if site != null and Atlas.knows(world, site):
		return site.display_name
	return world.region_at(cell)


## The quest list's entries for the markers ([D190]), oldest first.
static func entries(world: World) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if world == null:
		return out
	for each: Dictionary in all():
		var cell: Vector2i = each["cell"]
		var go := bool(each["go"])
		out.append({
			"id": id_of(cell),
			"kind": "marker",
			"cell": cell,
			"label": label_of(cell),
			"stop": true,
			"detail": "Picked on the map to walk to." if go else "A place you marked on the map.",
		})
	return out


static func _number(cell: Vector2i) -> int:
	var n := 0
	for each: Dictionary in all():
		if bool(each["go"]):
			continue
		n += 1
		if each["cell"] == cell:
			return n
	return n


static func _keep(kept: Array) -> void:
	var raw: Array = []
	for each: Dictionary in kept:
		var cell: Vector2i = each["cell"]
		raw.append([cell.x, cell.y, 1 if bool(each["go"]) else 0])
	if raw.is_empty():
		GameState.flags.erase(FLAG)
	else:
		GameState.set_flag(FLAG, raw)
