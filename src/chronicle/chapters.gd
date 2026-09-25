extends RefCounted
## The Tower in chapters — M14, [D34].
##
## Every few floors (five: every rule joint session 1 made counts in fives) a
## chapter ends. The world moves on when it does: time passes, gates that were
## only brewing open, and the Tower shows the census — how many of the sixteen
## are still standing. Then the stair above is sealed until the company has
## answered the world: shut a gate, or saved a town, since the seal was set.
## Ignore the world and you do not climb.
##
## How many floors there are and how many make a chapter are agenda item 1, so
## both are numbers in `data/world_rules.json` → `tower`, not constants here.
##
## Loaded by path, not by `class_name` ([D41]).

## How many of the sixteen there are, and so the census's ceiling.
const SIXTEEN := 16


static func rules() -> Dictionary:
	return Database.world_rules.get("tower", {})


static func per_chapter() -> int:
	return maxi(1, int(rules().get("floors_per_chapter", 5)))


## The chapter [param floor] belongs to, from 1. Standing at the foot of the
## Tower is chapter 1 too.
static func chapter_of(floor: int) -> int:
	return maxi(1, ceili(float(floor) / float(per_chapter())))


static func chapters(world: World) -> int:
	return ceili(float(world.tower_floors()) / float(per_chapter()))


## True when winning [param floor] ends a chapter (the top counts).
static func ends_chapter(world: World, floor: int) -> bool:
	return floor > 0 and (floor % per_chapter() == 0 or floor >= world.tower_floors())


## The stair above is shut, and nothing done in the world has opened it yet.
static func sealed(world: World) -> bool:
	if world.tower_sealed_at < 0:
		return false
	if answered(world):
		world.tower_sealed_at = -1
		return false
	return true


## Something the Tower counts as answering the world, done since the seal.
static func answered(world: World) -> bool:
	var keys: Array = rules().get("chapter_keys", [Renown.GATE_SHUT, Renown.TOWN_SAVED])
	for deed: Dictionary in world.deeds:
		if keys.has(str(deed.get("kind", ""))) and int(deed.get("step", -1)) >= world.tower_sealed_at:
			return true
	return false


## How many of the sixteen still stand, across every world. Until there is
## more than one world (M15) that is all of them while the lead lives.
static func census(_world: World) -> int:
	return SIXTEEN


## A chapter won: the world moves on, the census is read, and — unless this
## was the top — the stair above is sealed. Returns what to tell the player.
static func turn(world: World, floor: int) -> Array[String]:
	var lines: Array[String] = []
	var chapter := chapter_of(floor)
	var alive := census(world)
	var census_line := "The Tower shows you the sixteen: %s still stand%s." % [
		_count(alive), "" if alive != 1 else "s"
	]
	lines.append("Chapter %d of the Tower is behind you." % chapter)
	lines.append(census_line)
	Annals.record(world, "The company finished chapter %d of the Tower. %s" % [chapter, census_line])
	if floor >= world.tower_floors():
		return lines

	# While you climbed, the world went on without you.
	for _i in int(rules().get("chapter_upkeeps", 3)):
		world.steps += World.UPKEEP_INTERVAL
		for notice: String in world._upkeep():
			if notice != "":
				lines.append(notice)
	for gate: Site in _wake_gates(world, int(rules().get("gates_woken_per_chapter", 2)), chapter):
		lines.append("%s has opened while you were in the Tower." % gate.display_name)
		Annals.record(world, "%s opened as chapter %d of the Tower closed." % [gate.display_name, chapter])

	world.tower_sealed_at = world.steps
	lines.append(seal_line())
	return lines


static func seal_line() -> String:
	return "The stair above is sealed. The Tower wants to see you answer the world first: shut a gate, or save a town."


## Open gates that were only waiting — the weakest first, so a company that has
## just climbed a chapter has something it can answer — or, if every gate is
## already open or shut, tear a new one. Always at least one, so a sealed stair
## can always be opened.
static func _wake_gates(world: World, count: int, chapter: int) -> Array[Site]:
	var woken: Array[Site] = []
	var dormant := world.sites_of_kind(Site.GATE).filter(
		func(site: Site) -> bool: return not site.open and not site.cleared
	)
	dormant.sort_custom(func(a: Site, b: Site) -> bool: return Site.rank_index(a.rank) < Site.rank_index(b.rank))
	for site: Site in dormant.slice(0, maxi(1, count)):
		world.open_gate(site)
		woken.append(site)
	if woken.is_empty():
		var rift := _tear_rift(world, chapter)
		if rift != null:
			woken.append(rift)
	return woken


## A new gate somewhere out in the country, ranked for the chapter reached.
static func _tear_rift(world: World, chapter: int) -> Site:
	var home := world.home()
	var from := home.cell if home != null else world.player_cell
	for _attempt in 80:
		var cell := Vector2i(world.rng.randi() % world.size.x, world.rng.randi() % world.size.y)
		var far := Pathfinder.distance(cell, from)
		if not world.is_walkable(cell) or world.site_at(cell) != null or far < 8 or far > 40:
			continue
		var rift := Site.create(Site.GATE, cell, "The %s Rift" % WorldGen.wild_name(world.rng))
		rift.rank = Site.RANKS[clampi(chapter, 0, Site.RANKS.size() - 1)]
		rift.data["area"] = "gate"
		rift.data["faction"] = Faction.FALLBACK
		world.sites.append(rift)
		world.open_gate(rift)
		return rift
	return null


static func _count(n: int) -> String:
	const WORDS := ["none", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
		"eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen"]
	return WORDS[n] if n >= 0 and n < WORDS.size() else str(n)
