extends RefCounted
## The Tower's floors above the walked ones ([D207]): walked too, on a borrowed plan.
##
## Floors 1 to `walked_floors` have ground of their own (D102). Every floor above borrows one of their
## plans in turn (`tower.borrowed_plans` in `data/world_rules.json`, [method Chapters.walked_floor_area]),
## and this restocks the plan's bands with the floor's own foes: each band is the floor as a fought
## floor would have it ([method Encounter.for_tower]: its level, its cohort, how many), its keys and
## flags its own so a band beaten on floor 1 does not stand down on floor 6, and never fewer foes
## than the plan's band had (filled out with more of the same). On the top floor the
## first band is the Spire Apex's keeper and the rest stand down. The same floor of the same world is
## always stocked the same way.
##
## Floors 6 to 10 (the Second Hour, [D254]) have ground of their own, but from `tower.own_bands_from`
## up their bands are restocked the same way, all but the floor's keeper, so they climb as the floors
## above them were tuned to.
##
## From `tower.grown.from` up ([D290], [D307]) a floor is laid out here at the climb instead: a run of
## chambers in the Tower's own stone, the higher the bigger, with a band of the floor's own in every
## chamber but the first ([method ensure_grown]); every third floor from 12 is shared with another
## company who fight beside the party ([method company_with_you]) and wait by the way in to talk, and from
## 25 every fifth has people living by the stair.
##
## Loaded by path, not by `class_name` ([D41]).

const Chapters := preload("res://src/chronicle/chapters.gd")
const CompanyTalk := preload("res://src/chronicle/company_talk.gd")

const SLAB := "s"
const RUNNER := "f"
const WALL := "A"


## Whether [param floor] has ground of its own whose bands are still the floor's foes ([D254]).
static func own_bands_restocked(floor: int) -> bool:
	var from := int(Chapters.rules().get("own_bands_from", 0))
	return from > 0 and floor >= from and not Chapters.borrows_a_plan(floor) \
		and Chapters.walked_floor_area(floor) != ""


## [param bands] (a plan's, as its area has them) restocked for [param floor] of [param world], met by
## [param party] (Characters). Floors with their own ground come back as they are. On the top floor
## the keeper stands before the first of [param stairs], as floor 5's does.
static func restock(bands: Array, world: World, floor: int, party: Array, stairs: Array = []) -> Array:
	if world == null or not (Chapters.borrows_a_plan(floor) or own_bands_restocked(floor)):
		return bands
	var tower := world.tower()
	if tower == null:
		return bands
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.world_seed, "tower floor", floor])
	var top := floor >= world.tower_floors()
	var out: Array = []
	for i in bands.size():
		if top and i > 0:
			break
		var band: Dictionary = (bands[i] as Dictionary).duplicate(true)
		# A floor's own keeper keeps its own shape ([D254]: the Keeper of the Tenth), never below the
		# floor's foes.
		if bool(band.get("boss", false)) and not Chapters.borrows_a_plan(floor):
			var level_here := 1
			for foe: Dictionary in Encounter.for_tower(world, tower, floor, party, rng).get("enemies", []):
				level_here = maxi(level_here, int(foe.get("level", 1)))
			band["level"] = maxi(int(band.get("level", 1)), level_here + 1)
			out.append(band)
			continue
		var met := Encounter.for_tower(world, tower, floor, party, rng)
		var pack: Array = []
		var level := 1
		for foe: Dictionary in met.get("enemies", []):
			pack.append(str(foe.get("unit", "")))
			level = maxi(level, int(foe.get("level", 1)))
		if pack.is_empty():
			continue
		# Never fewer than the plan put there: the walked floors below hold two or three a band, and
		# a floor above them is not to be easier (play-test 4, D189).
		var at_least := (bands[i] as Dictionary).get("pack", []).size() as int
		var first := pack.size()
		while pack.size() < at_least:
			pack.append(pack[pack.size() % first])
		var key := "tower%d_%s" % [floor, char(97 + i)]
		band["key"] = key
		band["pack"] = pack
		band["level"] = level
		band["label"] = str(met.get("title", "Floor %d" % floor))
		band["boss"] = top
		if top and not stairs.is_empty():
			var stair: Vector2i = stairs[0]
			band["at"] = [stair.x, stair.y + 4]
			band["reach"] = maxi(int(band.get("reach", 2)), 3)
		band["held"] = true
		band.erase("requires")
		band["requires_not"] = "done:%s" % key
		band["done_flag"] = "done:%s" % key
		out.append(band)
	return out


# --- floors that grow ([D290], [D307]) ---------------------------------------------------


static func grown_rules() -> Dictionary:
	return Chapters.rules().get("grown", {})


## Whether [param floor] is laid out at the climb rather than on a borrowed plan.
static func is_grown(floor: int) -> bool:
	var from := int(grown_rules().get("from", 0))
	return from > 0 and floor >= from and floor <= int(Chapters.rules().get("floors", 100))


static func grown_area_id(floor: int) -> String:
	return str(grown_rules().get("area", "tower_floor_grown_%d")) % floor


## How wide and high [param floor] is: the base frame, grown a little every floor over the walked ones.
static func grown_size(floor: int) -> Vector2i:
	var r := grown_rules()
	var over := maxi(0, floor - int(Chapters.rules().get("walked_floors", 10)))
	var width := mini(int(r.get("widest", 60)), int(r.get("width", 26)) + roundi(float(r.get("width_per_floor", 0.6)) * float(over)))
	var height := mini(int(r.get("tallest", 44)), int(r.get("height", 18)) + roundi(float(r.get("height_per_floor", 0.4)) * float(over)))
	return Vector2i(width, height)


static func grown_chambers(floor: int) -> int:
	var r := grown_rules()
	var over := maxi(0, floor - int(Chapters.rules().get("walked_floors", 10)))
	return mini(int(r.get("most_chambers", 7)), int(r.get("chambers", 3)) + over / maxi(1, int(r.get("chambers_every", 5))))


## A shared floor: another company is climbing it too ([D290]).
static func is_shared(floor: int) -> bool:
	var r := grown_rules()
	var from := int(r.get("shared_from", 0))
	return is_grown(floor) and from > 0 and floor >= from and (floor - from) % maxi(1, int(r.get("shared_every", 3))) == 0 and not is_living(floor)


## A floor people live on ([D290]: "by floor 25 or 30 people have set up base").
static func is_living(floor: int) -> bool:
	var r := grown_rules()
	var from := int(r.get("living_from", 0))
	return is_grown(floor) and from > 0 and floor >= from and (floor - from) % maxi(1, int(r.get("living_every", 5))) == 0


## The name of the company on [param floor], the same every time for this world.
static func company_on(world: World, floor: int) -> String:
	var companies: Array = Database.world_rules.get("life", {}).get("climbers", {}).get("companies", ["another company"])
	if companies.is_empty():
		return "another company"
	return str(companies[absi(hash([world.world_seed, "tower company", floor])) % companies.size()])


## The company climbing a shared [param floor] beside the party, as a fight's allies: each
## `{ unit, level, name }`, at the party's level. Empty on a floor of the party's own.
static func company_with_you(world: World, floor: int, party: Array) -> Array:
	if not is_shared(floor):
		return []
	var r := grown_rules()
	var climbers: Dictionary = Database.world_rules.get("life", {}).get("climbers", {})
	var units: Array = climbers.get("units", ["keep_watchman"])
	var size: Array = r.get("shared_size", [2, 3])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.world_seed, "tower company", floor])
	var count := rng.randi_range(int(size[0]), int(size[1]))
	var level := Encounter.party_level(party)
	var out: Array = []
	for i in count:
		out.append({ "unit": str(units[rng.randi() % units.size()]), "level": level, "name": company_on(world, floor) })
	return out


## The line said on the way up a shared or a living floor, or "".
static func floor_line(world: World, floor: int) -> String:
	var r := grown_rules()
	if is_living(floor):
		return str(r.get("living_line", "")).format({ "company": company_on(world, floor) })
	if is_shared(floor):
		return str(r.get("shared_line", "")).format({ "company": company_on(world, floor) })
	return ""


## [param floor] of [param world] laid out and registered, ready for the area scene: returns its id.
## The same floor of the same world is always laid out the same way. Its bands are stand-ins the
## floor's own foes replace as the floor opens ([method restock]).
static func ensure_grown(world: World, floor: int) -> String:
	var id := grown_area_id(floor)
	if Database.has_area(id):
		return id
	Database.register_area(id, layout(world, floor))
	return id


## The floor itself, in an area's shape.
static func layout(world: World, floor: int) -> Dictionary:
	var r := grown_rules()
	var size := grown_size(floor)
	var width := size.x
	var height := size.y
	var count := grown_chambers(floor)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.world_seed, "tower grown", floor])
	var grid: Array = []
	for y in height:
		var row: Array = []
		row.resize(width)
		row.fill(WALL)
		grid.append(row)
	# The chambers, bottom to top, swinging from side to side so the way up winds.
	var rooms: Array[Rect2i] = []
	for i in count:
		var t := float(i) / float(maxi(1, count - 1))
		var cy := roundi(lerpf(float(height - 5), 4.0, t))
		var half_w := rng.randi_range(3, 4 + width / 12)
		var half_h := rng.randi_range(2, 2 + height / 12)
		var side := (i % 2) * 2 - 1
		var cx := width / 2 + side * rng.randi_range(0, width / 4)
		if i == 0 or i == count - 1:
			cx = width / 2 + rng.randi_range(-1, 1)
		cx = clampi(cx, half_w + 2, width - half_w - 3)
		cy = clampi(cy, half_h + 2, height - half_h - 3)
		rooms.append(Rect2i(cx - half_w, cy - half_h, half_w * 2 + 1, half_h * 2 + 1))
	for room in rooms:
		for y in range(room.position.y, room.end.y):
			for x in range(room.position.x, room.end.x):
				grid[y][x] = SLAB
	for i in range(1, rooms.size()):
		_carve_way(grid, _centre(rooms[i - 1]), _centre(rooms[i]), rng)
	# The way in below the first chamber, and the stair above the last.
	var door := Vector2i(_centre(rooms[0]).x, height - 1)
	_carve_way(grid, _centre(rooms[0]), door, rng)
	var stair := Vector2i(_centre(rooms[-1]).x, 0)
	_carve_way(grid, _centre(rooms[-1]), Vector2i(stair.x, 1), rng)
	for x in width:
		if absi(x - door.x) > 1:
			grid[height - 1][x] = WALL
		if x != stair.x and x != stair.x + 1:
			grid[0][x] = WALL
	grid[0][stair.x] = RUNNER
	grid[0][stair.x + 1] = RUNNER
	grid[1][stair.x + 1] = RUNNER
	for x in [0, width - 1]:
		for y in height:
			grid[y][x] = WALL
	var rows: Array = []
	for row: Array in grid:
		rows.append("".join(PackedStringArray(row)))
	# The stair, lit runes either side of it and along the top wall, and lamps by the way in.
	var props: Array = [
		{ "art": "tower_inside/stair_up", "cell": [stair.x, 1] },
		{ "art": "tower_inside/stair_up", "cell": [stair.x + 1, 1], "flip": true },
		{ "art": "tower_inside/rune_a", "cell": [stair.x - 1, 0] },
		{ "art": "tower_inside/rune_b", "cell": [stair.x + 2, 0] },
		{ "art": "tower_inside/rune_c", "cell": [clampi(stair.x - 6, 1, width - 2), 0] },
		{ "art": "tower_inside/rune_c", "cell": [clampi(stair.x + 7, 1, width - 2), 0] },
		{ "art": "lamp_globe", "cell": [clampi(door.x - 3, 1, width - 2), height - 3] },
		{ "art": "lamp_globe", "cell": [clampi(door.x + 3, 1, width - 2), height - 3] },
	]
	# Pillars at the back corners of each chamber wide enough for them, once their picture (A51) is
	# in; they stand in nobody's way, so no way up is ever cut.
	for room in rooms:
		if room.size.x >= 7:
			props.append({ "art": "tower_inside/pillar", "cell": [room.position.x, room.position.y], "solid": false })
			props.append({ "art": "tower_inside/pillar", "cell": [room.end.x - 1, room.position.y], "solid": false })
	# A band of the floor's own in every chamber but the first: a stand-in pack the floor's foes
	# replace ([method restock]), the keeper of the top floor among them.
	var bands: Array = []
	for i in range(1, rooms.size()):
		var at := _centre(rooms[i])
		var key := "tower%d_%s" % [floor, char(97 + i)]
		bands.append({
			"key": key, "pack": (r.get("band_pack", ["goblin", "goblin"]) as Array).duplicate(), "label": "Floor %d" % floor,
			"faction": "", "at": [at.x, at.y], "reach": 2, "level": 1, "held": true,
			"requires_not": "done:%s" % key, "done_flag": "done:%s" % key,
		})
	# People living on the floor, by the way in, who will talk ([D290]).
	var people: Array = []
	if is_living(floor):
		var sizes: Array = r.get("living_size", [3, 4])
		var units: Array = Database.world_rules.get("life", {}).get("climbers", {}).get("units", ["keep_watchman"])
		var company := company_on(world, floor)
		var spots := [Vector2i(-3, -1), Vector2i(3, -1), Vector2i(-2, -3), Vector2i(2, -3)]
		for i in rng.randi_range(int(sizes[0]), int(sizes[1])):
			var at := Vector2i(door.x, height - 3) + (spots[i % spots.size()] as Vector2i)
			if at.x <= 0 or at.x >= width - 1 or at.y <= 0 or grid[at.y][at.x] == WALL:
				continue
			# What the floor offers ([D317]): its first rests the company for coin, its second sells.
			var talk: Dictionary = r.get("living_talk", {})
			if people.size() == 0 and r.has("living_host"):
				talk = r["living_host"]
			elif people.size() == 1 and r.has("living_trader"):
				talk = (r["living_trader"] as Dictionary).duplicate(true)
				var markup := float(talk.get("markup", 1.0))
				var wares: Array = []
				for ware: Dictionary in talk.get("sells", []):
					var priced := ware.duplicate()
					if not priced.has("price"):
						priced["price"] = maxi(1, roundi(float(Market.price_of(str(priced.get("item", "")))) * markup))
					wares.append(priced)
				talk["sells"] = wares
			else:
				# The rest have more to say than the two questions ([CompanyTalk.drawn]).
				talk = talk.duplicate(true)
				var said := RandomNumberGenerator.new()
				said.seed = hash([world.world_seed, "floor folk", floor, people.size()])
				(talk["ask"] as Array).append_array(CompanyTalk.drawn(talk.get("pool", []), int(talk.get("pool_shown", 2)), said))
			people.append({
				"name": str(talk.get("name", company)), "unit": str(units[rng.randi() % units.size()]), "cell": [at.x, at.y],
				"facing": [0, 1], "_area": "floor_folk", "talk": talk,
			})
	# The company climbing a shared floor, waiting by the way in to go up with the party ([CompanyTalk]).
	if is_shared(floor) and not is_living(floor):
		var units: Array = Database.world_rules.get("life", {}).get("climbers", {}).get("units", ["keep_watchman"])
		var company := company_on(world, floor)
		var talk := CompanyTalk.block(company, CompanyTalk.SHARED, floor, world.world_seed)
		for at: Vector2i in [Vector2i(door.x - 2, height - 3), Vector2i(door.x + 2, height - 3)]:
			if at.x <= 0 or at.x >= width - 1 or grid[at.y][at.x] == WALL:
				continue
			people.append({
				"name": company, "unit": str(units[absi(hash([world.world_seed, floor, at])) % units.size()]),
				"cell": [at.x, at.y], "facing": [0, -1], "_area": "shared_company", "talk": talk,
			})
	return {
		"display_name": "floor %d of the Tower" % floor,
		"layers": ["tower_slab", "tower_runner", "tower_wall"],
		"legend": { SLAB: "tower_slab", RUNNER: "tower_runner", WALL: "tower_wall" },
		"tint": str(r.get("tint", "#8a8fa8")),
		"hint": str(r.get("hint", "")),
		"rows": rows,
		"spawn": [door.x, height - 3],
		"exits": [[door.x - 1, height - 1], [door.x, height - 1], [door.x + 1, height - 1]],
		"stairs": [[stair.x, 0], [stair.x + 1, 0]],
		"props": props,
		"bands": bands,
		"people": people,
		"spots": [],
	}


static func _centre(room: Rect2i) -> Vector2i:
	return room.position + room.size / 2


## A way from [param from] to [param to]: across, then up or down, three wide, a runner down its middle.
static func _carve_way(grid: Array, from: Vector2i, to: Vector2i, rng: RandomNumberGenerator) -> void:
	var cells: Array[Vector2i] = []
	var bend := Vector2i(to.x, from.y) if rng.randf() < 0.5 else Vector2i(from.x, to.y)
	for leg: Array in [[from, bend], [bend, to]]:
		var a: Vector2i = leg[0]
		var b: Vector2i = leg[1]
		var step := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
		var at := a
		cells.append(at)
		while at != b:
			at += step
			cells.append(at)
	var height := grid.size()
	var width := (grid[0] as Array).size()
	for cell in cells:
		for y in range(cell.y - 1, cell.y + 2):
			for x in range(cell.x - 1, cell.x + 2):
				if y >= 0 and y < height and x >= 0 and x < width and grid[y][x] == WALL:
					grid[y][x] = SLAB
	for cell in cells:
		if cell.y >= 0 and cell.y < height and cell.x >= 0 and cell.x < width:
			grid[cell.y][cell.x] = RUNNER

