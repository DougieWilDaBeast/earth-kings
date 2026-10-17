extends RefCounted
## Treasure maps torn in pieces ([D220], from Necesse's map fragments): a band beaten on the land
## sometimes carries a piece; when the party holds enough, they fit together into an X on the
## map, a few days' walk off. Standing on the X digs up a find better than any cache. One X at a
## time: no more pieces turn up until it is dug.
##
## Kept on the world as `treasure`: `{ pieces, at }` (`at` is `[x, y]`, or absent with no X).
## Numbers and words are `data/world_rules.json` → `treasure`. Rolled from a hash, not the dice,
## so a seeded run finds what it always did. Loaded by path ([D41]).

const Atlas := preload("res://src/chronicle/atlas.gd")


static func rules() -> Dictionary:
	return Database.world_rules.get("treasure", {})


static func _line(key: String, tokens: Dictionary = {}) -> String:
	return str(rules().get("lines", {}).get(key, "")).format(tokens)


static func pieces(world: World) -> int:
	return int(world.treasure.get("pieces", 0))


## Where the X is, or (-1, -1) when there is none.
static func at(world: World) -> Vector2i:
	var cell: Array = world.treasure.get("at", [])
	return Vector2i(int(cell[0]), int(cell[1])) if cell.size() >= 2 else Vector2i(-1, -1)


static func _roll(world: World, salt: Variant) -> float:
	return float(absi(hash([world.world_seed, world.steps, salt, "treasure"])) % 1000) / 1000.0


## A band beaten at [param cell]: maybe a piece, and with the last piece, the X. The lines to say.
static func on_band_beaten(world: World, cell: Vector2i) -> Array[String]:
	var lines: Array[String] = []
	if world == null or at(world).x >= 0:
		return lines
	if _roll(world, [cell.x, cell.y]) >= float(rules().get("piece_chance", 0.25)):
		return lines
	var need := maxi(1, int(rules().get("pieces", 3)))
	var held := pieces(world) + 1
	if held < need:
		world.treasure["pieces"] = held
		lines.append(_line("piece", { "held": held, "need": need }))
		return lines
	var spot := _spot(world, cell)
	if spot.x < 0:
		# Nowhere it could lead: keep the pieces for when there is.
		world.treasure["pieces"] = need - 1
		return lines
	world.treasure = { "pieces": 0, "at": [spot.x, spot.y] }
	Atlas.chart_around(world, spot, int(rules().get("chart_radius", 2)))
	lines.append(_line("whole", {
		"need": need, "bearing": Roadside.bearing(world.player_cell, spot), "region": world.region_at(spot),
	}))
	return lines


## A walkable cell with no place on it, between `near` and `far` steps of walking from
## [param from], picked by the hash. (-1, -1) when there is none.
static func _spot(world: World, from: Vector2i) -> Vector2i:
	var near := int(rules().get("near", 6))
	var far := int(rules().get("far", 14))
	var seen: Dictionary = { from: 0 }
	var queue: Array[Vector2i] = [from]
	var head := 0
	var fits: Array[Vector2i] = []
	while head < queue.size():
		var cell := queue[head]
		head += 1
		var steps := int(seen[cell])
		if steps >= near and world.site_at(cell) == null:
			fits.append(cell)
		if steps >= far:
			continue
		for offset: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next := cell + offset
			if seen.has(next) or not world.is_walkable(next):
				continue
			seen[next] = steps + 1
			queue.append(next)
	if fits.is_empty():
		return Vector2i(-1, -1)
	return fits[int(_roll(world, [from.x, from.y, "spot"]) * 1000.0) % fits.size()]


## The party stands on [param cell]: the haul if this is the X (and the X is gone), else empty.
static func dig(world: World, cell: Vector2i) -> Dictionary:
	if world == null or at(world) != cell:
		return {}
	world.treasure.erase("at")
	var haul := Loot.roll(world, float(rules().get("richness", 2.5)))
	if str(haul.get("item", "")) == "":
		var pool := Loot.findable()
		if not pool.is_empty():
			haul["item"] = pool[int(_roll(world, [cell.x, cell.y, "item"]) * 1000.0) % pool.size()]
	haul["line"] = _line("dug")
	return haul


## What the quest list follows while there is an X ([D190]).
static func quest(world: World) -> Dictionary:
	var spot := at(world)
	if spot.x < 0:
		return {}
	return {
		"id": "treasure", "kind": "treasure", "cell": spot, "stop": true,
		"label": _line("label"),
		"detail": _line("detail", { "region": world.region_at(spot) }),
	}
