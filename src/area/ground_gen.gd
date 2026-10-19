## Loaded by path ([D41]): `const GroundGen := preload("res://src/area/ground_gen.gd")`.
extends RefCounted
## The ground of one tile of open country, laid out for walking in.
##
## Every tile of the continent that is not a place gets its own ground, made
## from its land ([Biome]) and the tiles around it: a way out only on the sides
## the party can walk to, a shore against the sea, a rock wall under the
## mountains; paths worn between the ways out; pools, thickets, outcrops and
## bare patches in the proportions its land has; and now and then something
## somebody left (a cold fire, a ring of stones, a cairn). It is made from the
## world's seed and the tile, so walking back into it finds it the same.
##
## Laid out as the same dictionary a hand-built area under `data/areas` is, and
## handed to the [Database] under an id of its own, so [AreaMap] and
## [AreaScene] cannot tell the difference.

const Biome := preload("res://src/chronicle/biome.gd")
const FirstRoad := preload("res://src/area/first_road.gd")
const Tracks := preload("res://src/area/tracks.gd")

const FLOOR := "."
const BARE := ","
const LIQUID := "~"
const COVER := "\""
## The First Hour's laid road ([D126]).
const ROAD := "="
## A dirt track between two places, two cells wide, and a footpath, one: every way worn across a
## tile is one or the other ([D233]).
const TRACK := ":"
const FOOT := "_"
## What a path may not be worn over, and what nothing grows on.
const WAYS := [ROAD, TRACK, FOOT]
## What stands where the ways meet (D233).
const SIGNPOST := "village/signpost"

const SIDES := {
	"north": Vector2i.UP, "south": Vector2i.DOWN, "west": Vector2i.LEFT, "east": Vector2i.RIGHT,
}
## How wide a way out is, in cells.
const GAP := 4
## How far in from a side its border runs.
const BORDER := 1
## Room left clear round where the paths meet, so arriving is never into a tree.
const HUB_CLEAR := 2

## Things somebody left, and what the party makes of them.
const LANDMARKS := [
	{ "kind": "camp", "props": ["camp/fire_ring", "village/bench"],
	  "line": "A ring of cold stones and a log to sit on. Somebody camped here, and left in a hurry." },
	{ "kind": "circle", "props": ["biome/standing_stone", "biome/standing_stone", "biome/standing_stone"],
	  "line": "Standing stones in a ring, older than any road. The middle of it is very quiet." },
	{ "kind": "cairn", "props": ["biome/cairn"],
	  "line": "A cairn over somebody nobody named. Stones have been added to it lately." },
	{ "kind": "cache", "props": ["nature/dead_tree"], "chest": true,
	  "line": "Something has been hidden here under the roots, and hidden well." },
]


## The id of the ground at [param cell], made the first time it is asked for.
static func for_cell(world: World, cell: Vector2i) -> String:
	var land := Biome.at(world, cell)
	var id := "ground_%d_%d_%s" % [cell.x, cell.y, land]
	if not Database.has_area(id):
		Database.register_area(id, build(world, cell, land))
	return id


## One tile of the land as it is laid out side by side with its neighbours ([D84]): the open
## country of it, or the place standing in it with its own ground round it, or the sea or a
## mountain filling it. In the tile's own cells, (0, 0) at its top left; [Land] puts it where it
## goes. The same world and tile always give the same slot, while what stands there is the same.
##
## `{ id, kind, land, size, terrain (one name per cell, row by row), patches ({ layers, rect }:
## the sheets that paint each part, bottom first), props, chests, spots, buildings, people, wards,
## fires, spawn, entries, place ({ id, rect } or empty), tint, hint, opening }`.
static func slot(world: World, tile: Vector2i) -> Dictionary:
	# A place bigger than a tile (a great city, [D247]) is laid out whole and cut a tile at a time.
	var big := _big_place(world, tile)
	if not big.is_empty():
		var piece: Vector2i = big["piece"]
		var big_key := "%d|%d,%d|big|%s|%d,%d" % [world.shape_seed(), tile.x, tile.y, big["id"], piece.x, piece.y]
		if not _slots.has(big_key):
			if _slots.size() > 400:
				_slots.clear()
			_slots[big_key] = _piece_of(world, tile, big)
		return _slots[big_key]
	var place_id := _place_in(world, tile)
	var land := Biome.at(world, tile) if world.in_bounds(tile) else "grassland"
	var kind := "ground"
	if not world.in_bounds(tile) or world.terrain_id_at(tile) in ["ocean", "lake"]:
		kind = "sea"
	elif not world.is_walkable(tile):
		kind = "rock"
	elif place_id != "":
		kind = "place"
	var shut := place_id != "" and _shut_gate(world, tile)
	var key := "%d|%d,%d|%s|%s|%s|%s" % [world.shape_seed(), tile.x, tile.y, land, kind, place_id, shut]
	if _slots.has(key):
		return _slots[key]
	var made: Dictionary
	match kind:
		"sea", "rock":
			made = _barrier(world, tile, kind, land)
		"place":
			made = _around_place(world, tile, land, place_id)
			if shut:
				_break_the_gate(made)
		_:
			made = _as_slot(_lay_out(world, tile, land, true, Vector2i(-1, -1), Rect2i()))
			made["id"] = "land_%d_%d_%s" % [tile.x, tile.y, land]
			_blend_edges(world, tile, land, made)
	made["kind"] = kind
	made["land"] = land
	if _slots.size() > 400:
		_slots.clear()
	_slots[key] = made
	return made


## Where the land next door is another land, its floor runs a few cells into this one, thinning
## as it comes, so the two meet in a ragged band and not on the tile's ruler-straight edge (D128;
## Ewan's "biomes in squares"). The next tile does the same the other way, so the band spans the
## seam. Only open floor and cover give way: paths, water and the road stay as they were.
static func _blend_edges(world: World, tile: Vector2i, land: String, made: Dictionary) -> void:
	var size: Array = made.get("size", [0, 0])
	var w := int(size[0])
	var h := int(size[1])
	var terrain: PackedStringArray = made.get("terrain", PackedStringArray())
	var own: Dictionary = Biome.data(land).get("ground", {})
	var gives_way := [str(own.get("floor", "")), str(own.get("cover", ""))]
	var band := int(Database.biomes.get("edge_band", 3))
	var added: Array = []
	for side: String in SIDES:
		var dir: Vector2i = SIDES[side]
		var next := tile + dir
		if not world.in_bounds(next) or not world.is_walkable(next):
			continue
		var theirs := str(Biome.data(Biome.at(world, next)).get("ground", {}).get("floor", ""))
		if theirs == "" or gives_way.has(theirs) or Database.tileset_sheet("edge_" + theirs).is_empty():
			continue
		for depth in band:
			# Three in four cells at the seam, one in four at the band's inner edge.
			var share := float(band - depth) / float(band + 1)
			for along in (w if dir.y != 0 else h):
				var at := _edge_cell(side, along, w, h) - dir * depth
				var i := at.y * w + at.x
				if i < 0 or i >= terrain.size() or not gives_way.has(terrain[i]):
					continue
				if absf(float(hash([world.shape_seed(), tile.x, tile.y, at.x, at.y]) % 1000)) / 1000.0 < share:
					terrain[i] = theirs
		if not added.has("edge_" + theirs):
			added.append("edge_" + theirs)
	if added.is_empty():
		return
	made["terrain"] = terrain
	# Under the ways, so a worn edge never laps over a path or the cobbles.
	var patch: Dictionary = (made["patches"] as Array)[0]
	var layers: Array = (patch.get("layers", []) as Array).duplicate()
	var at_road := -1
	for way: String in ["footpath", "track", "road"]:
		if at_road < 0:
			at_road = layers.find(way)
	for sheet: String in added:
		if at_road >= 0:
			layers.insert(at_road, sheet)
			at_road += 1
		else:
			layers.append(sheet)
	patch["layers"] = layers


## Slots already laid out, by world, tile and what stands there.
static var _slots: Dictionary = {}
## World shape seed -> tile -> `{ id, piece, anchor_tile, block }` for every tile a place bigger than
## one tile stands on ([D247]).
static var _bigs: Dictionary = {}
## World shape seed and place id -> that place laid out whole, before it is cut into tiles.
static var _blocks: Dictionary = {}


## The place bigger than a tile standing on [param tile], if any ([D247]): an area with `covers`
## ([w, h], how many tiles of the land it covers) stands with the tile `anchor` ([x, y] within it,
## [0, 0] when absent) on its site, and every tile it covers is a piece of it. `{ id, piece, block }`,
## `block` being the first tile it covers; empty when no such place stands there.
static func _big_place(world: World, tile: Vector2i) -> Dictionary:
	var key := world.shape_seed()
	if not _bigs.has(key):
		if _bigs.size() > 4:
			_bigs.clear()
		var found: Dictionary = {}
		for site: Site in world.sites:
			var area_id := str(site.data.get("area", site.kind))
			if not Database.has_area(area_id):
				continue
			var area := Database.area(area_id)
			var tiles: Array = area.get("covers", [])
			if tiles.size() < 2:
				continue
			var anchor: Array = area.get("anchor", [0, 0])
			var block := site.cell - Vector2i(int(anchor[0]), int(anchor[1]))
			for dy in int(tiles[1]):
				for dx in int(tiles[0]):
					found[block + Vector2i(dx, dy)] = {
						"id": area_id, "piece": Vector2i(dx, dy), "block": block, "site": site.cell,
					}
		_bigs[key] = found
	return (_bigs[key] as Dictionary).get(tile, {})


## Whether [param tile] is covered by a place bigger than a tile ([D247]).
static func in_big_place(world: World, tile: Vector2i) -> bool:
	return not _big_place(world, tile).is_empty()


## The whole of a place bigger than a tile, laid out as one ground the size of every tile it covers
## ([D247]): its own ground in the middle, the land's floor round it, and its walls (when it has
## them) with the lane outside them that the land's paths come in by.
static func _block_of(world: World, big: Dictionary) -> Dictionary:
	var key := "%d|%s" % [world.shape_seed(), big["id"]]
	if _blocks.has(key):
		return _blocks[key]
	var place := Database.area(str(big["id"]))
	var tiles: Array = place.get("covers", [1, 1])
	var size: Array = Database.biomes.get("size", [32, 22])
	var w := int(size[0]) * int(tiles[0])
	var h := int(size[1]) * int(tiles[1])
	var site_cell: Vector2i = big["site"]
	var land := Biome.at(world, site_cell)
	var biome := Biome.data(land)
	var rows: Array = place.get("rows", [])
	var legend: Dictionary = place.get("legend", {})
	var pw := 0
	for row: String in rows:
		pw = maxi(pw, row.length())
	var ph := rows.size()
	var offset := Vector2i((w - pw) / 2, (h - ph) / 2)
	var rect := Rect2i(offset, Vector2i(pw, ph))
	var terrain := PackedStringArray()
	terrain.resize(w * h)
	terrain.fill(str(biome.get("ground", {}).get("floor", "grass")))
	for y in ph:
		var row: String = rows[y]
		for x in pw:
			var symbol := row.substr(x, 1) if x < row.length() else "."
			terrain[(offset.y + y) * w + offset.x + x] = str(legend.get(symbol, "grass"))
	var made := {
		"size": [w, h], "terrain": terrain,
		"patches": [
			{ "layers": (biome.get("layers", ["dirt"]) as Array).duplicate(), "rect": [0, 0, w, h] },
			{ "layers": place.get("layers", ["dirt"]), "rect": [offset.x, offset.y, pw, ph] },
		],
		"props": [], "chests": [], "spots": [], "buildings": [], "people": [], "wards": [], "fires": [],
		"place": { "id": big["id"], "rect": [offset.x, offset.y, pw, ph] },
		"tint": str(place.get("tint", biome.get("tint", ""))),
		"hint": str(place.get("hint", "")),
		"opening": str(place.get("opening", "")),
	}
	for entry: Dictionary in place.get("props", []) + place.get("dressing", []):
		(made["props"] as Array).append(_moved(entry, offset))
	for key_: String in ["chests", "spots", "buildings", "people", "wards"]:
		for entry: Dictionary in place.get(key_, []):
			(made[key_] as Array).append(_moved(entry, offset))
	if place.has("fire"):
		made["fires"] = [[int(place["fire"][0]) + offset.x, int(place["fire"][1]) + offset.y]]
	var spawn: Array = place.get("spawn", [pw / 2, ph / 2])
	made["spawn"] = [int(spawn[0]) + offset.x, int(spawn[1]) + offset.y]
	if place.has("walls"):
		_raise_walls(made, rect, place, land, w, h)
	if _blocks.size() > 8:
		_blocks.clear()
	_blocks[key] = made
	return made


## One tile's piece of a place bigger than a tile ([D247]): its share of the ground, of everything
## standing on it (in the tile's own cells), and the ways in from the land round it, which come in
## where the land's paths meet the edge and walk the lane outside the walls to a gate.
static func _piece_of(world: World, tile: Vector2i, big: Dictionary) -> Dictionary:
	var whole := _block_of(world, big)
	var size: Array = Database.biomes.get("size", [32, 22])
	var w := int(size[0])
	var h := int(size[1])
	var piece: Vector2i = big["piece"]
	var origin := piece * Vector2i(w, h)
	var bounds := Rect2i(origin, Vector2i(w, h))
	var whole_w := int(whole["size"][0])
	var whole_terrain: PackedStringArray = whole["terrain"]
	var terrain := PackedStringArray()
	terrain.resize(w * h)
	for y in h:
		for x in w:
			terrain[y * w + x] = whole_terrain[(origin.y + y) * whole_w + origin.x + x]
	var made := {
		"id": big["id"], "size": [w, h], "terrain": terrain, "patches": [],
		"tint": whole["tint"], "hint": whole["hint"],
		# Said once, coming into the tile the place's site stands on.
		"opening": whole["opening"] if tile == big["site"] else "",
	}
	for patch: Dictionary in whole["patches"]:
		var r: Array = patch["rect"]
		var cut := Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])).intersection(bounds)
		if cut.size.x > 0 and cut.size.y > 0:
			made["patches"].append({ "layers": patch["layers"], "rect": [cut.position.x - origin.x, cut.position.y - origin.y, cut.size.x, cut.size.y] })
	for key: String in ["props", "chests", "spots", "buildings", "people", "wards"]:
		var mine: Array = []
		for entry: Dictionary in whole[key]:
			var at: Array = entry.get("cell", [0, 0])
			if bounds.has_point(Vector2i(int(at[0]), int(at[1]))):
				mine.append(_moved(entry, -origin))
		made[key] = mine
	var fires: Array = []
	for pair: Array in whole["fires"]:
		if bounds.has_point(Vector2i(int(pair[0]), int(pair[1]))):
			fires.append([int(pair[0]) - origin.x, int(pair[1]) - origin.y])
	made["fires"] = fires
	# The place's rect in this tile's cells, so a cell anywhere in it reads as the place's own.
	var r: Array = whole["place"]["rect"]
	made["place"] = { "id": big["id"], "rect": [int(r[0]) - origin.x, int(r[1]) - origin.y, int(r[2]), int(r[3])] }
	var spawn: Array = whole["spawn"]
	var at_spawn := Vector2i(int(spawn[0]), int(spawn[1])) - origin
	if not Rect2i(Vector2i.ZERO, Vector2i(w, h)).has_point(at_spawn) or not _open(terrain, at_spawn, w):
		at_spawn = _nearest_open(terrain, Vector2i(w / 2, h / 2), w, h)
	made["spawn"] = [at_spawn.x, at_spawn.y]
	var entries := {}
	for side: String in SIDES:
		var dir: Vector2i = SIDES[side]
		var next := tile + dir
		if _big_place(world, next).get("id", "") == big["id"] or not world.in_bounds(next) or not world.is_walkable(next):
			entries[side] = [at_spawn.x, at_spawn.y]
			continue
		# Where the land's path from next door meets this edge: on the lane outside the walls.
		var along := _gap_start(world, tile, next, w if dir.y != 0 else h)
		var meet := _edge_cell(side, along + GAP / 2, w, h)
		entries[side] = [meet.x, meet.y]
	made["entries"] = entries
	made["kind"] = "place"
	made["land"] = Biome.at(world, tile) if world.in_bounds(tile) else "grassland"
	return made


static func _open(terrain: PackedStringArray, at: Vector2i, w: int) -> bool:
	return bool(Database.area_terrain(terrain[at.y * w + at.x]).get("walkable", true))


static func _nearest_open(terrain: PackedStringArray, from: Vector2i, w: int, h: int) -> Vector2i:
	for radius in maxi(w, h):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var at := from + Vector2i(dx, dy)
				if at.x >= 0 and at.y >= 0 and at.x < w and at.y < h and _open(terrain, at, w):
					return at
	return from


## The place whose inside stands on [param tile] in the land: one with an area of its own, and not
## sealed shut ([Ward]). Anything else is the land's own ground.
static func _place_in(world: World, tile: Vector2i) -> String:
	if not world.in_bounds(tile):
		return ""
	var site := world.site_at(tile)
	if site == null:
		return ""
	var area_id := str(site.data.get("area", site.kind))
	if not Database.has_area(area_id):
		return ""
	if site.data.has("ward") and not Ward.is_site_open(site):
		return ""
	return area_id


## Whether [param tile] holds a gate that has been shut.
static func _shut_gate(world: World, tile: Vector2i) -> bool:
	var site := world.site_at(tile)
	return site != null and site.kind == Site.GATE and site.cleared


## A shut gate's mouth (play-test 7, D261): the gate lying broken where it stood, and folk come to
## look at it and cheer (`gate.shut` in `data/world_rules.json`).
static func _break_the_gate(made: Dictionary) -> void:
	var shut: Dictionary = Database.world_rules.get("gate", {}).get("shut", {})
	if shut.is_empty():
		return
	var place: Dictionary = made.get("place", {})
	var rect: Array = place.get("rect", [0, 0, 0, 0])
	var offset := Vector2i(int(rect[0]), int(rect[1]))
	var inside := Rect2i(offset, Vector2i(int(rect[2]), int(rect[3])))
	var props: Array = []
	for prop: Dictionary in made.get("props", []):
		# The gate is the landmark in its own mouth (each kind has its own picture).
		var at: Array = prop.get("cell", [-1, -1])
		if str(prop.get("art", "")).begins_with("landmark/") and inside.has_point(Vector2i(int(at[0]), int(at[1]))):
			props.append({ "art": str(shut.get("art", "")), "cell": prop.get("cell", [0, 0]) })
		else:
			props.append(prop)
	made["props"] = props
	var people: Array = (made.get("people", []) as Array).duplicate()
	for person: Dictionary in shut.get("people", []):
		people.append(_moved(person, offset))
	made["people"] = people


## A laid-out ground (rows and a legend) as a slot: a name per cell, one patch over all of it.
static func _as_slot(area: Dictionary) -> Dictionary:
	var rows: Array = area.get("rows", [])
	var legend: Dictionary = area.get("legend", {})
	var w := 0
	for row: String in rows:
		w = maxi(w, row.length())
	var terrain := PackedStringArray()
	for row: String in rows:
		for x in w:
			terrain.append(str(legend.get(row.substr(x, 1) if x < row.length() else FLOOR, "grass")))
	return {
		"size": [w, rows.size()],
		"terrain": terrain,
		"patches": [{ "layers": area.get("layers", ["dirt"]), "rect": [0, 0, w, rows.size()] }],
		"props": area.get("props", []),
		"chests": area.get("chests", []),
		"spots": area.get("spots", []),
		"buildings": [], "people": [], "wards": [], "fires": [],
		"spawn": area.get("spawn", [w / 2, rows.size() / 2]),
		"entries": area.get("entries", {}),
		"place": {},
		"tint": str(area.get("tint", "")),
		"hint": str(area.get("hint", "")),
		"opening": "",
	}


## The sea, a lake or a mountain, filling the whole tile: nobody walks it, but it is there to see.
static func _barrier(world: World, tile: Vector2i, kind: String, land: String) -> Dictionary:
	var size: Array = Database.biomes.get("size", [32, 22])
	var w := int(size[0])
	var h := int(size[1])
	var terrain := PackedStringArray()
	terrain.resize(w * h)
	terrain.fill("water" if kind == "sea" else "crag")
	var props: Array = []
	if kind == "rock":
		# A few boulders on the slopes, so a mountain is not a flat grey sheet.
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([world.shape_seed(), tile.x, tile.y, "rock"])
		var rocks: Array = Biome.data(land).get("props", {}).get("rocks", [])
		if rocks.is_empty():
			rocks = ["biome/boulder"]
		for i in rng.randi_range(6, 12):
			var at := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(0, h - 1))
			props.append({ "art": str(rocks[rng.randi() % rocks.size()]), "cell": [at.x, at.y], "solid": true })
	return {
		"id": "%s_%d_%d" % [kind, tile.x, tile.y],
		"size": [w, h],
		"terrain": terrain,
		"patches": [{ "layers": ["water" if kind == "sea" else "crag"], "rect": [0, 0, w, h] }],
		"props": props, "chests": [], "spots": [], "buildings": [], "people": [], "wards": [], "fires": [],
		"spawn": [w / 2, h / 2], "entries": {}, "place": {},
		"tint": str(Biome.data(land).get("tint", "")), "hint": "", "opening": "",
	}


## A place standing in its tile: its own ground in the middle, the land's round it, the paths of
## the land meeting at its way in, and nothing growing hard up against its edge. Everything in it
## keeps its own cells inside the place (moved by where it stands), so a chest opened there is the
## same chest it always was.
static func _around_place(world: World, tile: Vector2i, land: String, place_id: String) -> Dictionary:
	var place := Database.area(place_id)
	var rows: Array = place.get("rows", [])
	var legend: Dictionary = place.get("legend", {})
	var pw := 0
	for row: String in rows:
		pw = maxi(pw, row.length())
	var ph := rows.size()
	var size: Array = Database.biomes.get("size", [32, 22])
	var w := int(size[0])
	var h := int(size[1])
	if pw > w - 2 or ph > h - 2:
		push_warning("GroundGen: %s is too big for a tile of the land" % place_id)
		var plain := _as_slot(_lay_out(world, tile, land, true, Vector2i(-1, -1), Rect2i()))
		plain["id"] = "land_%d_%d_%s" % [tile.x, tile.y, land]
		return plain
	var offset := Vector2i((w - pw) / 2, (h - ph) / 2)
	var rect := Rect2i(offset, Vector2i(pw, ph))
	# The paths meet just outside the place's way in.
	var door := Vector2i(pw / 2, ph - 1)
	var exits: Array = place.get("exits", [])
	if not exits.is_empty():
		door = Vector2i(int(exits[0][0]), int(exits[0][1]))
	var outward := _outward(door, Vector2i(pw, ph))
	var hub := (offset + door + outward * 2).clamp(Vector2i.ONE, Vector2i(w - 2, h - 2))
	var made := _as_slot(_lay_out(world, tile, land, true, hub, rect))
	made["id"] = place_id
	var terrain: PackedStringArray = made["terrain"]
	for y in ph:
		var row: String = rows[y]
		for x in pw:
			var symbol := row.substr(x, 1) if x < row.length() else "."
			terrain[(offset.y + y) * w + offset.x + x] = str(legend.get(symbol, "grass"))
	made["terrain"] = terrain
	# The land's growth stays out of the place and the ring round it.
	var ring := rect.grow(1)
	made["props"] = (made["props"] as Array).filter(func(prop: Dictionary) -> bool:
		return not ring.has_point(Vector2i(int(prop["cell"][0]), int(prop["cell"][1]))))
	made["chests"] = []
	made["spots"] = []
	for entry: Dictionary in place.get("props", []) + place.get("dressing", []):
		(made["props"] as Array).append(_moved(entry, offset))
	for key: String in ["chests", "spots", "buildings", "people", "wards"]:
		var moved: Array = made.get(key, [])
		for entry: Dictionary in place.get(key, []):
			moved.append(_moved(entry, offset))
		made[key] = moved
	if place.has("walls"):
		_raise_walls(made, rect, place, land, w, h)
	if place.has("fire"):
		made["fires"] = [[int(place["fire"][0]) + offset.x, int(place["fire"][1]) + offset.y]]
	(made["patches"] as Array).append({ "layers": place.get("layers", ["dirt"]), "rect": [offset.x, offset.y, pw, ph] })
	var spawn: Array = place.get("spawn", [door.x, door.y])
	made["spawn"] = [int(spawn[0]) + offset.x, int(spawn[1]) + offset.y]
	made["place"] = { "id": place_id, "rect": [offset.x, offset.y, pw, ph] }
	made["tint"] = str(place.get("tint", made.get("tint", "")))
	made["hint"] = str(place.get("hint", ""))
	made["opening"] = str(place.get("opening", ""))
	return made


## A town's walls ([D85]): `walls` on a place names their build (`stone`, `timber`, `adobe`), and
## they stand on the ring of cells round it, with a tower at each corner and either side of every
## way in, and a gap in front of each of the place's exits. Round the outside a lane is kept clear
## of growth and standing water, so a path coming in from any side of the tile can walk round to the gate.
static func _raise_walls(made: Dictionary, rect: Rect2i, place: Dictionary, land: String, w: int,
		h: int) -> void:
	var build := str(place["walls"])
	var ring := rect.grow(1)
	var lane := rect.grow(2)
	if lane.position.x < 0 or lane.position.y < 0 or lane.end.x > w or lane.end.y > h:
		push_warning("GroundGen: no room for walls round %s" % str(made.get("id", "")))
		return
	var gaps: Dictionary = {}
	for exit: Array in place.get("exits", []):
		var at := Vector2i(int(exit[0]), int(exit[1]))
		gaps[rect.position + at + _outward(at, rect.size)] = true
	var ground: Dictionary = Biome.data(land).get("ground", {})
	var liquid := str(ground.get("liquid", "water"))
	var terrain: PackedStringArray = made["terrain"]
	var on_lane := func(at: Vector2i) -> bool:
		return lane.has_point(at) and not ring.has_point(at)
	made["props"] = (made["props"] as Array).filter(func(prop: Dictionary) -> bool:
		return not on_lane.call(Vector2i(int(prop["cell"][0]), int(prop["cell"][1]))))
	for y in range(lane.position.y, lane.end.y):
		for x in range(lane.position.x, lane.end.x):
			if on_lane.call(Vector2i(x, y)) and terrain[y * w + x] == liquid:
				terrain[y * w + x] = str(ground.get("floor", "grass"))
	made["terrain"] = terrain
	var last := ring.end - Vector2i.ONE
	for y in range(ring.position.y, ring.end.y):
		for x in range(ring.position.x, ring.end.x):
			var at := Vector2i(x, y)
			if rect.has_point(at) or gaps.has(at):
				continue
			var corner := (x == ring.position.x or x == last.x) and (y == ring.position.y or y == last.y)
			var by_gate := false
			for dir: Vector2i in SIDES.values():
				by_gate = by_gate or gaps.has(at + dir)
			var piece := "tower" if corner or by_gate \
				else ("run" if y == ring.position.y or y == last.y else "side")
			var wall := { "art": "walls/%s_%s" % [build, piece], "cell": [x, y], "solid": true }
			# A wall still to be built stands only once it is ([D251]: the crater's).
			if place.has("walls_requires"):
				wall["requires"] = place["walls_requires"]
			(made["props"] as Array).append(wall)


## Which way is out of a place from [param at], one of its edge cells: down unless it is on another edge.
static func _outward(at: Vector2i, size: Vector2i) -> Vector2i:
	if at.y == 0:
		return Vector2i.UP
	if at.x == 0:
		return Vector2i.LEFT
	if at.x == size.x - 1:
		return Vector2i.RIGHT
	return Vector2i.DOWN


## An entry of a place moved to where the place stands: its cell, and a building's door.
static func _moved(entry: Dictionary, offset: Vector2i) -> Dictionary:
	var out := entry.duplicate(true)
	for key: String in ["cell", "door"]:
		var at: Variant = entry.get(key, null)
		if at is Array and (at as Array).size() >= 2:
			out[key] = [int(at[0]) + offset.x, int(at[1]) + offset.y]
	if entry.has("rounds"):
		var stops: Array = []
		for stop: Dictionary in entry["rounds"]:
			stops.append(_moved(stop, offset))
		out["rounds"] = stops
	return out


## Where the party comes in from [param side] (north, south, east, west): just
## inside the way out on that side, or the middle if there is none.
static func entry(area: Dictionary, side: String) -> Vector2i:
	var at: Array = area.get("entries", {}).get(side, area.get("spawn", [0, 0]))
	return Vector2i(int(at[0]), int(at[1]))


static func side_of(dir: Vector2i) -> String:
	for side: String in SIDES:
		if SIDES[side] == dir:
			return side
	return ""


static func build(world: World, cell: Vector2i, land: String) -> Dictionary:
	return _lay_out(world, cell, land, false, Vector2i(-1, -1), Rect2i())


## Lay a tile's ground out. [param open_land]: the land runs on into the next tile ([D84]), so a
## side towards walkable country is left open, with its path running right to the edge at the
## same point the next tile's path does; only a side towards the sea or a mountain is closed.
## [param hub_at] is where the paths meet, when it is not for the ground to choose; nothing grows
## in [param reserved] (where a place will stand) or the ring round it.
static func _lay_out(world: World, cell: Vector2i, land: String, open_land: bool, hub_at: Vector2i,
		reserved: Rect2i) -> Dictionary:
	var biome := Biome.data(land)
	var size: Array = Database.biomes.get("size", [32, 22])
	var w := int(size[0])
	var h := int(size[1])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.shape_seed(), cell.x, cell.y, "ground"])

	var grid: Array[PackedStringArray] = []
	for y in h:
		var row := PackedStringArray()
		row.resize(w)
		row.fill(FLOOR)
		grid.append(row)
	# Cells nothing may be put on: the paths, the ways out and the meeting of them.
	var kept: Dictionary = {}
	var blocked: Dictionary = {}
	var props: Array = []
	var hub := Vector2i(w / 2 + rng.randi_range(-3, 3), h / 2 + rng.randi_range(-2, 2))
	if hub_at.x >= 0:
		hub = hub_at
	if reserved.size != Vector2i.ZERO:
		var ring := reserved.grow(1)
		for y in range(ring.position.y, ring.end.y):
			for x in range(ring.position.x, ring.end.x):
				kept[Vector2i(x, y)] = true

	# The ways out, and the edges that have none.
	var exits: Array = []
	var entries := {}
	var road: Array = FirstRoad.sides(world, cell) if open_land else []
	var tracks: Array = Tracks.sides(world, cell) if open_land else []
	for side: String in SIDES:
		var dir: Vector2i = SIDES[side]
		var next := cell + dir
		var open := world.in_bounds(next) and world.is_walkable(next)
		var along := _gap_start(world, cell, next, w if dir.y != 0 else h)
		if open_land and open:
			# No edge at all: the path runs out to where the next tile's comes in.
			var meet := _edge_cell(side, along + GAP / 2, w, h)
			entries[side] = [(meet - dir * 2).x, (meet - dir * 2).y]
			_wear_path(grid, kept, meet, hub, rng, w, h, true,
				ROAD if road.has(side) else (TRACK if tracks.has(side) else FOOT))
			continue
		for i in (w if dir.y != 0 else h):
			var at := _edge_cell(side, i, w, h)
			var in_gap := open and i >= along and i < along + GAP
			if in_gap:
				exits.append([at.x, at.y])
				kept[at] = true
				continue
			_close_edge(world, next, at, dir, grid, blocked, props, biome, rng)
		if open:
			var mid := _edge_cell(side, along + GAP / 2, w, h) - dir * (BORDER + 1)
			entries[side] = [mid.x, mid.y]
			_wear_path(grid, kept, mid + dir * BORDER, hub, rng, w, h)

	for dy in range(-HUB_CLEAR, HUB_CLEAR + 1):
		for dx in range(-HUB_CLEAR, HUB_CLEAR + 1):
			kept[hub + Vector2i(dx, dy)] = true

	# Patches, in the proportions the land has them.
	var features: Dictionary = biome.get("features", {})
	for i in _count(float(features.get("bare", 1.0)), rng):
		_blob(grid, kept, BARE, _anywhere(rng, w, h), rng.randi_range(2, 4), rng, w, h, false)
	for i in _count(float(features.get("cover", 1.0)), rng):
		_blob(grid, kept, COVER, _anywhere(rng, w, h), rng.randi_range(2, 4), rng, w, h, false)
	for i in _count(float(features.get("pools", 1.0)), rng):
		_blob(grid, kept, LIQUID, _anywhere(rng, w, h), rng.randi_range(1, 3), rng, w, h, true)
	var pool: Dictionary = biome.get("props", {})
	for i in _count(float(features.get("outcrops", 1.0)), rng):
		_outcrop(grid, kept, blocked, props, pool.get("rocks", []), _anywhere(rng, w, h), rng, w, h)

	# Something somebody left (never in the ground round a place: the place is what is there).
	var spots: Array = []
	var chests: Array = []
	if reserved.size == Vector2i.ZERO and rng.randf() < float(Database.biomes.get("landmark_chance", 0.2)):
		_landmark(grid, kept, blocked, props, spots, chests, rng, w, h, cell)

	# What grows and lies about, placed by rule rather than evenly at random (D130): trees stand in
	# groves that carry on across tiles, never hard beside a path; bushes line the paths; flowers
	# and grass gather on the meadow and at the water; stones lie on the bare ground. Each land's
	# density stays its average. Open land grows right up to its edges, so a wood carries on into
	# the next tile rather than stopping in a line.
	var density: Dictionary = biome.get("density", {})
	var rules: Dictionary = Database.biomes.get("scenery", {})
	var origin := cell * Vector2i(w, h)
	var inset := 0 if open_land else BORDER
	var grove_size := float(rules.get("grove_size", 6.0))
	# The grove field's corners, worked out once a tile rather than four times a cell (D178, lag).
	var lattice := {}
	var shape := world.shape_seed()
	# Everything the rules say about each kind, read once a tile, in the order kinds are tried.
	var kinds: Array[String] = ["trees", "rocks", "bushes", "small"]
	var kind_choices: Array = []
	var kind_density: Array[float] = []
	for kind: String in kinds:
		kind_choices.append(pool.get(kind, []))
		kind_density.append(float(density.get(kind, 0.0)))
	var grove_weight := float(rules.get("grove_weight", 2.8))
	var path_bushes := float(rules.get("path_bushes", 2.5))
	var bushes_elsewhere := float(rules.get("bushes_elsewhere", 0.7))
	var small_on_cover := float(rules.get("small_on_cover", 2.5))
	var small_elsewhere := float(rules.get("small_elsewhere", 0.6))
	var rocks_on_bare := float(rules.get("rocks_on_bare", 2.5))
	var rocks_elsewhere := float(rules.get("rocks_elsewhere", 0.6))
	for y in range(inset, h - inset):
		var line: PackedStringArray = grid[y]
		for x in range(inset, w - inset):
			var at := Vector2i(x, y)
			var on: String = line[x]
			if on == LIQUID or kept.has(at) or blocked.has(at):
				continue
			var by_path := _beside_path(grid, kept, at, w, h)
			for k in 4:
				var choices: Array = kind_choices[k]
				if choices.is_empty():
					continue
				var weight := 1.0
				match k:
					0:
						if by_path:
							weight = 0.0
						else:
							# Smoothstep of the grove field, scaled so the land's average holds.
							var t := clampf((_grove_at(shape, origin + at, grove_size, lattice) - 0.35) / 0.4, 0.0, 1.0)
							weight = t * t * (3.0 - 2.0 * t) * grove_weight
					1:
						weight = rocks_on_bare if on == BARE else rocks_elsewhere
					2:
						weight = path_bushes if by_path else bushes_elsewhere
					3:
						weight = small_on_cover if on == COVER or _touches(grid, at, LIQUID, w, h) else small_elsewhere
				if rng.randf() >= kind_density[k] * weight:
					continue
				var art := str(choices[rng.randi() % choices.size()])
				# A tree always stands in the way; a rock only when props.json says it is
				# one you cannot step past (loose stones and pebbles are walked over).
				var solid := k == 0 or (k == 1 and AreaProp.is_solid({ "art": art }))
				props.append({ "art": art, "cell": [x, y], "solid": solid })
				if solid:
					blocked[at] = true
				break

	# Where three or more ways leave open ground, a signpost by where they meet (D233).
	if open_land and reserved.size == Vector2i.ZERO:
		var says := Tracks.signpost(world, cell)
		if says != "":
			# The nearest open cell just clear of the meeting of the paths, beside a way.
			var near: Array[Vector2i] = []
			for dy in range(-HUB_CLEAR - 3, HUB_CLEAR + 4):
				for dx in range(-HUB_CLEAR - 3, HUB_CLEAR + 4):
					if maxi(absi(dx), absi(dy)) > HUB_CLEAR:
						near.append(Vector2i(dx, dy))
			near.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
				return a.length_squared() < b.length_squared() or (a.length_squared() == b.length_squared() and a.y < b.y))
			for offset: Vector2i in near:
				var post := hub + offset
				if post.x < 2 or post.y < 2 or post.x >= w - 2 or post.y >= h - 2:
					continue
				if blocked.has(post) or WAYS.has(grid[post.y][post.x]) or grid[post.y][post.x] == LIQUID:
					continue
				props = props.filter(func(prop: Dictionary) -> bool:
					return Vector2i(int(prop["cell"][0]), int(prop["cell"][1])) != post)
				props.append({ "art": SIGNPOST, "cell": [post.x, post.y], "solid": true, "line": says })
				blocked[post] = true
				break

	var rows: Array = []
	for row in grid:
		rows.append("".join(row))
	var ground: Dictionary = biome.get("ground", {})
	var layers: Array = (biome.get("layers", ["dirt"]) as Array).duplicate()
	# The ways over the land's own ground: footpaths under tracks under the road.
	layers.append("footpath")
	if not tracks.is_empty():
		layers.append("track")
	if not road.is_empty():
		layers.append("road")
	return {
		"display_name": str(biome.get("name", land)),
		"biome": land,
		"layers": layers,
		"legend": {
			FLOOR: str(ground.get("floor", "grass")), BARE: str(ground.get("bare", "dirt")),
			LIQUID: str(ground.get("liquid", "water")), COVER: str(ground.get("cover", "meadow")),
			ROAD: "road", TRACK: "track", FOOT: "footpath",
		},
		"tint": str(biome.get("tint", "")),
		"hint": "WASD to walk" if open_land else "WASD to walk  ·  the ways out follow the land",
		"rows": rows,
		"spawn": [hub.x, hub.y],
		"entries": entries,
		"exits": exits,
		"props": props,
		"spots": spots,
		"chests": chests,
	}


## Where along a side its way out starts. Worked out from the edge between the
## two tiles rather than either one, so leaving north out of one ground and
## arriving south into the next come through the same gap.
static func _gap_start(world: World, a: Vector2i, b: Vector2i, length: int) -> int:
	var lo := a if (a.x < b.x or (a.x == b.x and a.y < b.y)) else b
	var hi := b if lo == a else a
	var span := maxi(1, length - GAP - 8)
	return 4 + absi(hash([world.shape_seed(), lo.x, lo.y, hi.x, hi.y])) % span


static func _edge_cell(side: String, i: int, w: int, h: int) -> Vector2i:
	match side:
		"north":
			return Vector2i(i, 0)
		"south":
			return Vector2i(i, h - 1)
		"west":
			return Vector2i(0, i)
	return Vector2i(w - 1, i)


## A side with no way out is closed by what is beyond it: the sea or a lake
## comes in as water, a mountain as rock, and open country you cannot reach
## from here as a hedge of whatever grows in this land.
static func _close_edge(world: World, next: Vector2i, at: Vector2i, dir: Vector2i, grid: Array,
		blocked: Dictionary, props: Array, biome: Dictionary, rng: RandomNumberGenerator) -> void:
	var beyond := world.terrain_id_at(next) if world.in_bounds(next) else "ocean"
	# A land whose pools are not water (lava, blood, ooze) meets the sea at a
	# cliff instead of a shore.
	if beyond in ["ocean", "lake", "water"] and bool(biome.get("sea_shore", true)):
		for depth in 2:
			var c: Vector2i = at - dir * depth
			grid[c.y][c.x] = LIQUID
		return
	var pool: Dictionary = biome.get("props", {})
	var choices: Array = []
	if beyond in ["wall", "crag", "ocean", "lake", "water"]:
		choices = pool.get("rocks", [])
	if choices.is_empty():
		choices = pool.get("trees", [])
	if choices.is_empty():
		choices = pool.get("rocks", [])
	if choices.is_empty():
		choices = ["biome/boulder"]
	props.append({ "art": str(choices[rng.randi() % choices.size()]), "cell": [at.x, at.y], "solid": true })
	blocked[at] = true


## A path worn from a way out to where the paths meet, wandering a little: a footpath, one cell
## wide. The road ([constant ROAD]) and a track ([constant TRACK]) are laid two cells wide, the road
## over a track, and neither is worn over by a footpath.
static func _wear_path(grid: Array, kept: Dictionary, from: Vector2i, to: Vector2i,
		rng: RandomNumberGenerator, w: int, h: int, to_the_edge: bool = false, symbol: String = FOOT) -> void:
	var at := from
	var guard := 0
	while at != to and guard < 200:
		guard += 1
		kept[at] = true
		if to_the_edge or (at.x >= 1 and at.y >= 1 and at.x < w - 1 and at.y < h - 1):
			if symbol == ROAD or symbol == TRACK:
				for wide: Vector2i in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.ONE]:
					var c := at + wide
					# The road is laid over a track, never the other way.
					if c.x < w and c.y < h and (symbol == ROAD or grid[c.y][c.x] != ROAD):
						grid[c.y][c.x] = symbol
						kept[c] = true
			elif not WAYS.has(grid[at.y][at.x]) or grid[at.y][at.x] == FOOT:
				grid[at.y][at.x] = symbol
		var step := Vector2i(signi(to.x - at.x), 0) if (rng.randf() < 0.5 and at.x != to.x) or at.y == to.y \
			else Vector2i(0, signi(to.y - at.y))
		at += step
	kept[to] = true


static func _blob(grid: Array, kept: Dictionary, symbol: String, centre: Vector2i, radius: int,
		rng: RandomNumberGenerator, w: int, h: int, keep_clear: bool) -> void:
	var rx := float(radius) + rng.randf() * 1.5
	var ry := float(radius) + rng.randf() * 1.0
	for y in range(centre.y - radius - 2, centre.y + radius + 3):
		for x in range(centre.x - radius - 2, centre.x + radius + 3):
			if x < 2 or y < 2 or x >= w - 2 or y >= h - 2:
				continue
			var at := Vector2i(x, y)
			var d := pow((x - centre.x) / rx, 2.0) + pow((y - centre.y) / ry, 2.0)
			if d > 1.0 + rng.randf() * 0.35:
				continue
			# Water never cuts a path, and nothing is grown over the ways out.
			if kept.has(at) and (keep_clear or symbol == COVER):
				continue
			if kept.has(at) and (grid[y][x] == BARE or WAYS.has(grid[y][x])):
				continue
			grid[y][x] = symbol


static func _outcrop(grid: Array, kept: Dictionary, blocked: Dictionary, props: Array, rocks: Array,
		centre: Vector2i, rng: RandomNumberGenerator, w: int, h: int) -> void:
	if rocks.is_empty():
		return
	for i in rng.randi_range(3, 6):
		var at := centre + Vector2i(rng.randi_range(-2, 2), rng.randi_range(-2, 2))
		if at.x < 2 or at.y < 2 or at.x >= w - 2 or at.y >= h - 2:
			continue
		if kept.has(at) or blocked.has(at) or grid[at.y][at.x] == LIQUID:
			continue
		props.append({ "art": str(rocks[rng.randi() % rocks.size()]), "cell": [at.x, at.y], "solid": true })
		blocked[at] = true


static func _landmark(grid: Array, kept: Dictionary, blocked: Dictionary, props: Array, spots: Array,
		chests: Array, rng: RandomNumberGenerator, w: int, h: int, cell: Vector2i) -> void:
	var mark: Dictionary = LANDMARKS[rng.randi() % LANDMARKS.size()]
	var at := _anywhere(rng, w, h)
	for _try in 12:
		if not kept.has(at) and grid[at.y][at.x] != LIQUID:
			break
		at = _anywhere(rng, w, h)
	var art: Array = mark["props"]
	var ring := [Vector2i(0, -2), Vector2i(2, 1), Vector2i(-2, 1)]
	for i in art.size():
		var spot: Vector2i = at + (ring[i] if art.size() > 1 else Vector2i(0, -1))
		if spot.x < 2 or spot.y < 2 or spot.x >= w - 2 or spot.y >= h - 2 or kept.has(spot):
			continue
		props.append({ "art": str(art[i]), "cell": [spot.x, spot.y], "solid": true })
		blocked[spot] = true
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var c := at + Vector2i(dx, dy)
			if c.x > 0 and c.y > 0 and c.x < w - 1 and c.y < h - 1 and grid[c.y][c.x] == LIQUID:
				grid[c.y][c.x] = BARE
			kept[c] = true
	spots.append({ "cell": [at.x, at.y], "line": str(mark["line"]) })
	if bool(mark.get("chest", false)):
		chests.append({
			"cell": [at.x, at.y], "art": "chest_broken",
			"gold": 500 * (1 + absi(hash([cell.x, cell.y])) % 3),
			"line": "Under the roots: a box gone soft with damp, and coin inside it.",
		})


## Whether [param at] is next to a worn path or the road.
static func _beside_path(grid: Array, kept: Dictionary, at: Vector2i, w: int, h: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var c := at + Vector2i(dx, dy)
			if c.x < 0 or c.y < 0 or c.x >= w or c.y >= h or not kept.has(c):
				continue
			if grid[c.y][c.x] == BARE or WAYS.has(grid[c.y][c.x]):
				return true
	return false


static func _touches(grid: Array, at: Vector2i, symbol: String, w: int, h: int) -> bool:
	for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var c := at + side
		if c.x >= 0 and c.y >= 0 and c.x < w and c.y < h and grid[c.y][c.x] == symbol:
			return true
	return false


## One corner of the grove field.
static func _lattice_of(shape: int, x: int, y: int) -> float:
	return float(absi(hash([shape, x, y, "grove"])) % 10000) / 10000.0


## A smooth 0-to-1 field over the whole continent's ground, [param size] cells to a bump, so groves
## run on from one tile into the next. [param known] keeps the field's corners, a tile at a time.
static func _grove_at(shape: int, at: Vector2i, size: float, known: Dictionary) -> float:
	var fx := float(at.x) / size
	var fy := float(at.y) / size
	var x0 := floori(fx)
	var y0 := floori(fy)
	var tx := fx - x0
	var ty := fy - y0
	tx = tx * tx * (3.0 - 2.0 * tx)
	ty = ty * ty * (3.0 - 2.0 * ty)
	var corners: Array[float] = []
	for corner: Vector2i in [Vector2i(x0, y0), Vector2i(x0 + 1, y0), Vector2i(x0, y0 + 1), Vector2i(x0 + 1, y0 + 1)]:
		if not known.has(corner):
			known[corner] = _lattice_of(shape, corner.x, corner.y)
		corners.append(known[corner])
	return lerpf(lerpf(corners[0], corners[1], tx), lerpf(corners[2], corners[3], tx), ty)


static func _anywhere(rng: RandomNumberGenerator, w: int, h: int) -> Vector2i:
	return Vector2i(rng.randi_range(3, w - 4), rng.randi_range(3, h - 4))


## A whole number of patches near [param mean]: the whole part always, the rest
## by chance.
static func _count(mean: float, rng: RandomNumberGenerator) -> int:
	var whole := int(floor(mean))
	return whole + (1 if rng.randf() < mean - float(whole) else 0)
