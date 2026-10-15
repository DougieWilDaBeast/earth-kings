extends RefCounted
## The fall (M13, docs/17): where the sixteen come down, what the lead is told
## when they wake, and the one quest every lead carries from that moment.
##
## Loaded by path ([D41]). Pure logic: no nodes.
##
## A crash site is drawn from the world seed and a salt (the hero landing
## there), never from [member World.rng], so where somebody lands does not shift
## anything else in a seeded run, and a sibling world that shares the seed
## shares the landing (docs/17, "the worlds are siblings").

const Chapters := preload("res://src/chronicle/chapters.gd")
const Biome := preload("res://src/chronicle/biome.gd")

## What the crash can never land on. Water is walkable shallows, not ground.
const NOT_GROUND := ["water", "ocean", "lake"]

const COMPASS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]


static func rules() -> Dictionary:
	return Database.fall


static func crash_rules() -> Dictionary:
	return Database.fall.get("crash", {})


static func quest_rules() -> Dictionary:
	return Database.fall.get("standing_quest", {})


# --- landing ------------------------------------------------------------------


## Bring the lead down: pick their crash site, make it the company's Home, and
## put them on it. Returns the cell they landed on.
##
## The crash site becomes the hearth (agenda item 15, **Inferred**): the bed you
## can build, the safety of home, and the place rifts are torn away from all
## work from there.
##
## In the first world ([param first]) they come down on the road to the great
## city instead (D101, [method first_crash_cell]).
static func land(world: World, lead_id: String, reach: Dictionary = {}, first := false) -> Vector2i:
	if reach.is_empty():
		reach = reachable(world)
	var cell := Vector2i(-1, -1)
	if first:
		cell = first_crash_cell(world, "lead:%s" % lead_id, reach)
	if cell.x < 0:
		cell = crash_cell(world, "lead:%s" % lead_id, reach)
	var home := world.home()
	if home == null:
		home = Site.create(Site.HOME, cell, "Home")
		home.data["area"] = "home"
		world.sites.append(home)
	home.cell = cell
	home.display_name = str(crash_rules().get("home_name", "Where You Fell"))
	home.data["crash"] = true
	world.player_cell = cell
	return cell


## A random, valid place to come down, the same for the same seed and salt.
static func crash_cell(world: World, salt: String, reach: Dictionary = {}) -> Vector2i:
	if reach.is_empty():
		reach = reachable(world)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.world_seed, "fall", salt])
	var attempts := int(crash_rules().get("attempts", 600))
	for _i in attempts:
		var cell := Vector2i(rng.randi() % world.size.x, rng.randi() % world.size.y)
		if is_valid_crash(world, cell, reach):
			return cell
	# A world too cramped to say no to: anywhere joined to the Tower at all.
	var keys := reach.keys()
	if not keys.is_empty():
		keys.sort()
		for _i in 200:
			var cell: Vector2i = keys[rng.randi() % keys.size()]
			if world.site_at(cell) == null and not NOT_GROUND.has(world.terrain_id_at(cell)):
				return cell
	return world.home().cell if world.home() != null else world.player_cell


## The great city round the Tower (D101), or null on a map without one.
static func great_city(world: World) -> Site:
	for site: Site in world.sites:
		if bool(site.data.get("city", false)):
			return site
	return null


## The first world's landing (D101): on the road to the great city, between
## `first_world.city_min` and `city_max` tiles from it. (-1, -1) when the map
## has no great city or no ground there will do.
static func first_crash_cell(world: World, salt: String, reach: Dictionary) -> Vector2i:
	var city := great_city(world)
	if city == null:
		return Vector2i(-1, -1)
	var band: Dictionary = crash_rules().get("first_world", {})
	var near := int(band.get("city_min", 12))
	var far := int(band.get("city_max", 16))
	var choices: Array[Vector2i] = []
	for y in range(city.cell.y - far, city.cell.y + far + 1):
		for x in range(city.cell.x - far, city.cell.x + far + 1):
			var cell := Vector2i(x, y)
			var apart := Pathfinder.distance(city.cell, cell)
			if apart >= near and apart <= far and is_valid_crash(world, cell, reach, true):
				choices.append(cell)
	if choices.is_empty():
		return Vector2i(-1, -1)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.world_seed, "fall", salt, "first"])
	return choices[rng.randi() % choices.size()]


## [param first]: the first world's landing, which waives the distance from the
## Tower and from a haven (D101).
static func is_valid_crash(world: World, cell: Vector2i, reach: Dictionary, first := false) -> bool:
	if not reach.has(cell) or not world.is_walkable(cell):
		return false
	if NOT_GROUND.has(world.terrain_id_at(cell)):
		return false
	var site_gap := int(crash_rules().get("min_site_gap", 3))
	var gate_gap := int(crash_rules().get("min_gate_distance", 6))
	for site: Site in world.sites:
		if site.kind == Site.HOME:
			continue
		var apart := Pathfinder.distance(site.cell, cell)
		if apart < site_gap:
			return false
		if site.kind == Site.GATE and site.open and apart < gate_gap:
			return false
	if first:
		return true
	var tower := world.tower()
	if tower != null and Pathfinder.distance(tower.cell, cell) < int(crash_rules().get("min_tower_distance", 24)):
		return false
	var nearest := 9999
	for site: Site in world.sites:
		if site.kind == Site.VILLAGE or site.kind == Site.KEEP or site.kind == Site.HUT:
			nearest = mini(nearest, Pathfinder.distance(site.cell, cell))
	return nearest <= int(crash_rules().get("max_haven_distance", 26))


## Every cell joined by walkable ground to the Tower, so nobody lands in a
## pocket of the map they can never walk out of.
static func reachable(world: World) -> Dictionary:
	var seen: Dictionary = {}
	var tower := world.tower()
	var start: Vector2i = tower.cell if tower != null else world.size / 2
	if not world.is_walkable(start):
		return seen
	var queue: Array[Vector2i] = [start]
	seen[start] = true
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := cell + step
			if seen.has(next) or not world.is_walkable(next):
				continue
			seen[next] = true
			queue.append(next)
	return seen


## Which way [param to] lies from [param from], as a word.
static func way(from: Vector2i, to: Vector2i) -> String:
	var delta := Vector2(to - from)
	if delta.length_squared() < 0.01:
		return "here"
	var octant := posmod(roundi(delta.angle() / (TAU / 8.0)), 8)
	return COMPASS[octant]


## The beat played the first time a new run opens: a conversation in the
## shape [method Database.register_dialogue] takes. A line naming a `lead` is
## said only when [param lead_id] is that one; a line with `unless` is said for
## everyone but the leads it names.
static func landing_dialogue(world: World, lead_name: String, lead_id := "") -> Dictionary:
	var tower := world.tower()
	var city := great_city(world)
	var fill := {
		"name": lead_name,
		"region": world.region_at(world.player_cell),
		"ground": ground_word(world, world.player_cell),
		"tower_way": way(world.player_cell, tower.cell) if tower != null else "north",
		"city": city.display_name if city != null else "the city",
		"city_way": way(world.player_cell, city.cell) if city != null else "north",
	}
	var lines: Array = []
	for line: Dictionary in rules().get("landing", {}).get("lines", []):
		var only := str(line.get("lead", ""))
		if only != "" and only != lead_id:
			continue
		if (line.get("unless", []) as Array).has(lead_id):
			continue
		lines.append({
			"speaker": str(line.get("speaker", "")).format(fill),
			"text": str(line.get("text", "")).format(fill),
		})
	return { "lines": lines }


## Said in the log once the landing's boxes are read: the journal and the standing quest (D122 keeps
## the boxes before the first step to five).
static func landing_note() -> String:
	return str(rules().get("landing", {}).get("note", ""))


## The land under [param cell] as the narration names it: the land the ground
## is drawn as (a snowfield, the blight), never the map's plainer terrain, so
## the words match what the player is standing on.
static func ground_word(world: World, cell: Vector2i) -> String:
	var said := Biome.display_name(Biome.at(world, cell)).to_lower()
	return said.trim_prefix("the ")


## How the annals open on a new run.
static func annal(world: World, lead_name: String) -> String:
	return "%s fell from the sky into %s, and remembered nothing." % [lead_name, world.region_at(world.player_cell)]


# --- the standing quest -------------------------------------------------------


## "Ascend to heaven" ([D53]): carried by every lead from landing, and never
## finished until there is something past the top to finish it with (M17).
static func quest_title() -> String:
	return str(quest_rules().get("title", "Ascend to heaven"))


static func quest_brief() -> String:
	return str(quest_rules().get("brief", ""))


static func quest_badge() -> String:
	return str(quest_rules().get("badge", "ASCEND"))


## Where the climb stands, in a line.
static func quest_progress(world: World) -> String:
	if world.tower_is_topped():
		return str(quest_rules().get("topped", ""))
	var line := ""
	if world.tower_floor <= 0:
		line = str(quest_rules().get("not_started", ""))
	else:
		var chapters := Chapters.chapters(world)
		line = str(quest_rules().get("progress", "")).format({
			"floor": world.tower_floor,
			"floors": world.tower_floors(),
			"chapter": mini(chapters, Chapters.chapter_of(world.tower_floor + 1)),
			"chapters": chapters,
		})
	if world.tower_sealed_at >= 0:
		line += " " + str(quest_rules().get("sealed", ""))
	return line
