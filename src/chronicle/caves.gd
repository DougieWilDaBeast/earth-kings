extends RefCounted
## Caves on the land ([D282], Ewan's play-test 7: "a cave system, so like in Pokémon. You can go into
## a cave and it'll be a whole different area").
##
## Some hill tiles have a cave mouth, the same ones every time for a world: a hump of rock with a
## dark way in, set into the tile's ground like a house. Walked into, it is a place of its own,
## laid out the way a gate's floor is ([GateInside]) and in a gate's cave ground, but with no way
## further down: chambers held by what lives under the hill, the deepest by the strongest, and a
## cache in the last chamber. Cleared, it stays cleared; the way back out is where you went in.
## Rules in `world_rules.json` → `caves`. Loaded by path ([D41]). Pure logic: no nodes.

const GateInside := preload("res://src/chronicle/gate_inside.gd")


static func rules() -> Dictionary:
	return Database.world_rules.get("caves", {})


## The id the cave under [param tile] is registered under.
static func area_id(tile: Vector2i) -> String:
	return "cave_%d_%d" % [tile.x, tile.y]


## Whether [param tile] has a cave mouth: on the right kind of ground, on a roll that is the same
## every time for this world.
static func has_cave(world: World, tile: Vector2i) -> bool:
	if world == null or not world.in_bounds(tile) or not world.is_walkable(tile):
		return false
	if not (rules().get("terrains", ["hill"]) as Array).has(world.terrain_id_at(tile)):
		return false
	var roll := float(absi(hash([world.shape_seed(), tile.x, tile.y, "cave"])) % 1000) / 1000.0
	return roll < float(rules().get("chance", 0.3))


## The cave as a gate-shaped thing, so its floor and its bands are drawn the way a gate's are: a
## rank by the same roll, one floor, the land's own creatures.
static func site_for(world: World, tile: Vector2i) -> Site:
	var site := Site.create(Site.GATE, tile, str(rules().get("name", "the cave")))
	var ranks: Array = rules().get("ranks", ["E", "D", "C"])
	var roll := absi(hash([world.shape_seed(), tile.x, tile.y, "cave rank"]))
	site.rank = str(ranks[roll % ranks.size()]) if not ranks.is_empty() else "E"
	site.data["area"] = "gate"
	return site


## The cave under [param tile] laid out for [param party] and registered. Returns its id.
static func area_for(world: World, tile: Vector2i, party: Array) -> String:
	var id := area_id(tile)
	Database.register_area(id, layout(world, tile, party))
	return id


static func layout(world: World, tile: Vector2i, party: Array) -> Dictionary:
	var site := site_for(world, tile)
	var depth := site.floors() - 1
	var area := GateInside.layout(world, site, depth, party)
	var r := rules()
	# No way further down: the top row is rock again, and nothing in here is a gate's.
	var rows: Array = area["rows"]
	rows[0] = GateInside.WALL.repeat(str(rows[0]).length())
	area.erase("stairs")
	area.erase("gate_inside")
	area["display_name"] = str(r.get("name", "the cave"))
	area["hint"] = str(r.get("hint", "WASD to walk  ·  the way out is the way you came"))
	area["ground"] = "cave"
	var lost := str(r.get("lost", "You crawl back out into the light, and they are still down there."))
	for band: Dictionary in area.get("bands", []):
		band["lost"] = lost
		# Keyed by the cave, not by a gate that is not there.
		for key: String in ["key", "requires_not", "done_flag"]:
			band[key] = str(band[key]).replace(GateInside.area_id(site, depth), area_id(tile))
	area["chests"] = _cache(world, tile, rows, area.get("bands", []))
	return area


## Something left in the deepest chamber, beside whatever keeps it: coin and a herb that only grows
## in the dark.
static func _cache(world: World, tile: Vector2i, rows: Array, bands: Array) -> Array:
	if bands.is_empty():
		return []
	var keeper: Dictionary = bands.back()
	var at := Vector2i(int(keeper["at"][0]), int(keeper["at"][1]))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.shape_seed(), tile.x, tile.y, "cave cache"])
	for offset: Vector2i in [Vector2i(2, 1), Vector2i(-2, 1), Vector2i(2, -1), Vector2i(-2, -1), Vector2i(0, 2)]:
		var cell := at + offset
		if cell.y < 0 or cell.y >= rows.size() or cell.x < 0 or cell.x >= str(rows[cell.y]).length():
			continue
		if str(rows[cell.y])[cell.x] == GateInside.WALL:
			continue
		var finds: Array = rules().get("finds", ["redcap"])
		return [{
			"cell": [cell.x, cell.y], "art": "chest_broken",
			"gold": rng.randi_range(int(rules().get("gold_low", 400)), int(rules().get("gold_high", 1500))),
			"item": str(finds[rng.randi() % finds.size()]) if not finds.is_empty() else "",
		}]
	return []


## A cave mouth for the slot of [param tile], if it has one: a building on the ground with the cave
## behind its door. Whatever stood where it goes is cleared away.
static func add_mouth(world: World, tile: Vector2i, slot: Dictionary) -> void:
	if not has_cave(world, tile):
		return
	var size: Array = slot.get("size", [32, 22])
	var foot := Vector2i(3, 2)
	var at := Vector2i(int(size[0]) / 2 - 5, int(size[1]) / 2 - 4)
	var keep_clear := Rect2i(at - Vector2i(1, 1), foot + Vector2i(2, 3))
	slot["props"] = (slot.get("props", []) as Array).filter(func(p: Dictionary) -> bool:
		var cell: Array = p.get("cell", [0, 0])
		return not keep_clear.has_point(Vector2i(int(cell[0]), int(cell[1]))))
	(slot["buildings"] as Array).append({
		"name": str(rules().get("name", "the cave")),
		"art": str(rules().get("art", "cave_mouth")),
		"cell": [at.x, at.y],
		"size": [foot.x, foot.y],
		"lived_in": false,
		"area": area_id(tile),
		"cave": [tile.x, tile.y],
	})
