extends Node
## Headless check on the world model: generation, progression, generated power
## trees, doctrine, and a save/load round trip.
##
##   godot --headless --path . res://tests/world_smoke_test.tscn
##
## Runs as a scene rather than with `-s`, because `--script` runs before the
## autoloads (EventBus / Database / GameState) exist.

const SEED := 20260827

const CheckFilter := preload("res://tests/check_filter.gd")
const Company := preload("res://tests/company.gd")
## Every check, in the order a full run takes them. `--check=` picks from these.
const CHECKS := [
	"world", "progression", "doctrine", "class_choice", "fate", "roster", "encounters",
	"errands", "trivia", "grimoires", "memorials", "dialogue", "walking", "lands", "land_journals", "remembered", "arcs", "road", "edges", "scenery", "round_trip", "one_world", "tiers",
	"road_clock", "fallen_gates", "wilds",
]

const Biome := preload("res://src/chronicle/biome.gd")
const Wilds := preload("res://src/chronicle/wilds.gd")
const Atlas := preload("res://src/chronicle/atlas.gd")
const RumourJobs := preload("res://src/chronicle/rumour_jobs.gd")
const Dispatch := preload("res://src/chronicle/dispatch.gd")
const FirstRoad := preload("res://src/area/first_road.gd")
const Route := preload("res://src/world/route.gd")
const GroundGen := preload("res://src/area/ground_gen.gd")
const Caravans := preload("res://src/chronicle/caravans.gd")

var _failures: Array[String] = []


func _ready() -> void:
	# This suite checks the continent's systems themselves, the ones hidden for the
	# First Hour (D97) included, so it sees them all.
	(Database.world_rules["first_hour"] as Dictionary)["hidden"] = []
	var world := WorldGen.generate(SEED)
	_report_world(world)
	# Grown after the world check, as a full run always has, so the seeded world
	# that check reads is the one it was written against.
	var hero: Character = null

	var unknown: Array = []
	var chosen := CheckFilter.wanted(CHECKS, unknown)
	for name: String in unknown:
		_failures.append("no check called '%s' (there are: %s)" % [name, ", ".join(CHECKS)])
	if chosen.size() < CHECKS.size():
		print("running only: %s" % ", ".join(chosen))
	for name: String in chosen:
		if name != "world" and hero == null:
			hero = _grow_a_hero(world)
		match name:
			"world": _check_world(world)
			"one_world": _check_one_world()
			"fallen_gates": _check_fallen_gates(world)
			"wilds": _check_wilds(world)
			"progression": _check_progression(hero, world)
			"doctrine": _check_doctrine(hero, world)
			"class_choice": _check_class_choice(world)
			"fate": _check_fate(world)
			"roster": _check_roster(world)
			"encounters": _check_encounters(world)
			"errands": _check_errands(world)
			"trivia": _check_trivia(world)
			"grimoires": _check_grimoires(world)
			"memorials": _check_memorials(world)
			"dialogue": _check_dialogue()
			"walking": _check_walking(world)
			"lands": _check_lands(world)
			"land_journals": _check_land_journals(world)
			"remembered": _check_remembered(world)
			"arcs": _check_arcs(world)
			"road": _check_road(world)
			"road_clock": _check_road_clock()
			"edges": _check_edges(world)
			"scenery": _check_scenery(world)
			"round_trip": _check_round_trip(world, hero)
			"tiers": _check_tiers()

	print("")
	if _failures.is_empty():
		print("world smoke test: PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			print("FAIL: %s" % failure)
		get_tree().quit(1)


# --- world --------------------------------------------------------------------


func _report_world(world: World) -> void:
	print("world %d  %dx%d  start %s" % [world.world_seed, world.size.x, world.size.y, world.player_cell])
	var terrain_mix: Dictionary = {}
	for y in world.size.y:
		for x in world.size.x:
			var id := world.terrain_id_at(Vector2i(x, y))
			terrain_mix[id] = int(terrain_mix.get(id, 0)) + 1
	print("terrain %s" % terrain_mix)
	for site in world.sites:
		print("  %-8s %-14s %s" % [site.kind, site.label(), site.cell])


## D91, D92: every run is played on the one world in data/world_map.json. Two
## seeds, the same land, the same lands on it and the same places; the Tower in
## the middle; and a run never writes back into the map.
func _check_one_world() -> void:
	var a := WorldGen.generate(SEED)
	var b := WorldGen.generate(SEED + 4242)
	_expect(a.tiles == b.tiles, "two seeds gave two different lands")
	_expect(a.sites.size() == b.sites.size() and a.sites.size() == (Database.world_map.get("sites", []) as Array).size(),
			"the places are not the map's places")
	for i in mini(a.sites.size(), b.sites.size()):
		_expect(a.sites[i].cell == b.sites[i].cell and a.sites[i].display_name == b.sites[i].display_name,
				"%s is not where the map puts it" % a.sites[i].display_name)
	for cell: Vector2i in [Vector2i(30, 30), Vector2i(64, 100), Vector2i(90, 50)]:
		_expect(Biome.at(a, cell) == Biome.at(b, cell), "two seeds put two lands at %s" % cell)
	var tower := a.tower()
	_expect(tower != null and Pathfinder.distance(tower.cell, a.size / 2) <= 2, "the Tower is not in the middle of the world")
	a.sites[0].display_name = "changed by a run"
	a.tiles[0] = "changed"
	var c := WorldGen.generate(SEED)
	_expect(c.sites[0].display_name != "changed by a run" and c.tiles[0] != "changed", "a run wrote back into the map")


## Caravans ([D331]): wild places that walk. Each rolls on towards the next town of its round an upkeep
## at a time, by the way a party would walk, stands outside a town a while, never rolls onto another
## place or while the party is close, keeps its mark on the map as it goes, and has no guard, so no job.
func _check_caravans(world: World) -> void:
	var caravans := Caravans.all(world)
	_expect(caravans.size() >= 2, "the map has %d caravans" % caravans.size())
	if caravans.is_empty():
		return
	var kept_cell := world.player_cell
	var kept: Array = caravans.map(func(c: Site) -> Dictionary: return { "cell": c.cell, "data": c.data.duplicate(true) })
	var wagons: Site = caravans[0]
	_expect(not Wilds.guarded(wagons) and RumourJobs.found_at_the_wild(world, wagons) == "", "a caravan is kept by a guard, or has a job to clear it")
	# The party beside it: it does not move.
	world.player_cell = wagons.cell + Vector2i(1, 0)
	var before := wagons.cell
	wagons.data["caravan"]["rest"] = 0
	Caravans.roll(world, wagons)
	_expect(wagons.cell == before, "a caravan rolled off from beside the party")
	# The party far off: over some upkeeps it goes the round, town to town, and stays on the map.
	world.player_cell = Vector2i(2, 2)
	world.marked[Atlas._key(wagons.cell)] = true
	var legs := {}
	var moved := 0
	var worst := 99
	for i in 160:
		var from := wagons.cell
		if Caravans.roll(world, wagons):
			moved += 1
			_expect(Pathfinder.distance(from, wagons.cell) <= 2 * int(Caravans.rules().get("tiles_per_upkeep", 3)), "a caravan jumped from %s to %s" % [from, wagons.cell])
		legs[int(wagons.data["caravan"]["leg"])] = true
		for other: Site in world.sites:
			if other != wagons:
				worst = mini(worst, maxi(absi(other.cell.x - wagons.cell.x), absi(other.cell.y - wagons.cell.y)))
	_expect(moved >= 10 and legs.size() >= 3, "a caravan moved %d times and went %d legs of its round" % [moved, legs.size()])
	_expect(worst > int(Caravans.rules().get("clear_of_sites", 2)), "a caravan rolled within %d of another place" % worst)
	_expect(Atlas.knows(world, wagons), "a caravan on the map fell off it as it rolled")
	print("caravans: %d on the map; %s rolled %d times over %d legs, to %s" % [caravans.size(), wagons.display_name, moved, legs.size(), wagons.cell])
	for i in caravans.size():
		world.marked.erase(Atlas._key(caravans[i].cell))
		caravans[i].cell = kept[i]["cell"]
		caravans[i].data = kept[i]["data"]
	world.player_cell = kept_cell


## Places worth going to ([D287], [D309]): a dozen wild places on the map, each on its own kind of ground
## with an inside and a lure, unknown until found or heard of at rest; the host's word marks the nearest.
func _check_wilds(world: World) -> void:
	print("")
	var wilds := Wilds.all(world)
	_expect(wilds.size() >= 10, "the map has %d wild places" % wilds.size())
	var kinds := {}
	for place: Site in wilds:
		_expect(world.is_walkable(place.cell), "%s stands on unwalkable ground" % place.display_name)
		var area := str(place.data.get("area", ""))
		_expect(Database.has_area(area) and str(Database.area(area).get("lure", "")) != "", "%s has no inside or no lure (%s)" % [place.display_name, area])
		kinds[area] = true
		# A caravan stands off the road outside a town (D331); everything else keeps its distance.
		var apart := 3 if place.data.has("caravan") else 5
		for other: Site in world.sites:
			if other != place and other.kind != Site.WILD:
				_expect(Pathfinder.distance(place.cell, other.cell) >= apart, "%s is on top of %s" % [place.display_name, other.display_name])
		_expect(not Atlas.knows(world, place), "%s is known before anyone found it" % place.display_name)
	_expect(kinds.size() >= 4, "the wild places are only %d kinds" % kinds.size())
	# Hamlets (D330): a few crofts each, with folk who sell, one with a job, a trouble to clear (the
	# guard, under the hamlet's own name for it), drawn on the map as houses, not as a stone.
	for area: String in ["hamlet_fold", "hamlet_mill", "hamlet_salt"]:
		_expect(kinds.has(area), "no %s on the map" % area)
		var inside := Database.area(area)
		var sells := (inside.get("people", []) as Array).filter(func(p: Dictionary) -> bool: return p.get("talk", {}).has("sells"))
		var jobs := (inside.get("people", []) as Array).filter(func(p: Dictionary) -> bool: return p.get("talk", {}).has("job"))
		_expect(not sells.is_empty() and not jobs.is_empty(), "%s has nobody selling or nobody with a job" % area)
		_expect(str(inside.get("found_line", "")) != "" and str(inside.get("guard_label", "")).contains("{what}"), "%s has no found line or no name for its trouble" % area)
		_expect(ResourceLoader.exists(str(inside.get("map_art", ""))), "%s is drawn with no picture on the map" % area)
	_check_caravans(world)
	# Heard of at rest: the nearest unknown is marked and named with its lure.
	var village: Site = world.sites_of_kind(Site.VILLAGE)[0]
	var nearest := Wilds.nearest_unknown(world, village.cell, 200)
	_expect(nearest != null, "no wild place is unknown to %s" % village.display_name)
	var said := Wilds.rumour(world, village)
	_expect(said != "" and nearest != null and said.contains(nearest.display_name) and said.contains(Wilds.lure_of(nearest)),
			"the host's word does not name the nearest wild and what it holds: %s" % said)
	_expect(nearest != null and Atlas.knows(world, nearest), "the wild spoken of is not on the map")
	var again := Wilds.rumour(world, village)
	_expect(again == "" or not again.contains(nearest.display_name), "the host spoke of the same wild twice")
	# Found: a line once, a page in the annals, kept in the save.
	var annals_before := world.annals.size()
	var first := Wilds.found(world, nearest)
	_expect(first != "" and world.annals.size() == annals_before + 1 and bool(nearest.data.get("found", false)), "finding a wild place said nothing or wrote nothing")
	_expect(Wilds.found(world, nearest) == "", "a wild place was found twice")
	# Its quest is found at the wild itself ([D316]): walking in takes clearing it, for the nearest settlement known.
	var errands_before: Array = GameState.errands.duplicate()
	var posted_before := GameState.flags.duplicate()
	GameState.errands = []
	var taken := RumourJobs.found_at_the_wild(world, nearest)
	var quest: Dictionary = GameState.errands[0] if GameState.errands.size() == 1 else {}
	_expect(taken != "" and str(quest.get("kind", "")) == Errand.WILD and str(quest.get("flag", "")) == Wilds.guard_flag(nearest)
			and int(quest.get("gold", 0)) > 0, "walking into a wild did not take its quest: %s / %s" % [taken, quest])
	var payer := world.site_at(Errand._cell_of(quest.get("from", [])))
	_expect(payer != null and Errand._is_settlement(payer) and Atlas.knows(world, payer) and str(quest.get("giver", "")).contains(payer.display_name),
			"the wild's quest is paid nowhere, or nowhere on the map: %s" % [quest.get("from")])
	_expect(RumourJobs.found_at_the_wild(world, nearest) == "" and GameState.errands.size() == 1, "the wild's quest was taken twice")
	_expect(GameState.has_flag(RumourJobs.POSTED_FLAG + "wild:%s" % nearest.display_name), "the board may still post a quest the company already has")
	GameState.errands = errands_before
	GameState.flags = posted_before
	var saved := World.from_dict(world.to_dict())
	_expect(bool(saved.site_at(nearest.cell).data.get("found", false)) and Atlas.knows(saved, saved.site_at(nearest.cell)), "the found wild was lost in the save")
	# The land's own creatures guard the far chest of every wild.
	var inside := AreaMap.load_area(str(nearest.data.get("area", "")))
	var stocked := Wilds.stock(inside, world, nearest.cell, GameState.party_characters(), inside.bands)
	_expect(stocked.size() == inside.bands.size() + 1, "%s has no guard" % nearest.display_name)
	if stocked.size() == inside.bands.size() + 1:
		var guard: Dictionary = stocked.back()
		var at := Vector2i(int(guard["at"][0]), int(guard["at"][1]))
		_expect((guard.get("pack", []) as Array).size() == int(Wilds.rules().get("guard_size", 3)) and inside.is_walkable(at)
				and bool(guard.get("held", false)) and str(guard.get("done_flag", "")).begins_with("done:wild_guard_"),
				"the guard is not a held band of three on open ground: %s" % [guard])
		_expect(stocked == Wilds.stock(inside, world, nearest.cell, GameState.party_characters(), inside.bands), "the guard is dealt differently each time")
		print("wilds: %s is guarded by %s" % [nearest.display_name, guard.get("label", "")])
	# A quest in a wild place ([D310]): once heard of, the board can post clearing it.
	var board_before: Variant = village.data.get("errand")
	village.data.erase("errand")
	var flags_before := GameState.flags.duplicate()
	var job := {}
	for i in 12:
		job = RumourJobs.compose(world, village)
		if str(job.get("kind", "")) == Errand.WILD:
			break
	_expect(str(job.get("kind", "")) == Errand.WILD and Atlas.knows(world, world.site_at(Errand._cell_of(job.get("to", [])))),
			"the board did not post clearing a wild the party has heard of: %s" % [job])
	if str(job.get("kind", "")) == Errand.WILD:
		_expect(str(job.get("title", "")).contains("What keeps") and int(job.get("gold", 0)) > 0 and str(job.get("flag", "")).begins_with("done:wild_guard_"),
				"the wild job is not worded or paid: %s" % [job])
		_expect(not Errand.is_complete(job) and Errand.progress(job).begins_with("clear"), "the wild job is done before the guard is")
		GameState.set_flag(str(job["flag"]))
		_expect(Errand.is_complete(job) and Errand.progress(job) == "cleared", "beating the guard did not finish the job")
		_expect(Dispatch.open_errands([job]).is_empty(), "a wild job can be sent a companion on")
	GameState.flags = flags_before
	if board_before != null:
		village.data["errand"] = board_before
	else:
		village.data.erase("errand")
	print("wilds: %d places of %d kinds; %s" % [wilds.size(), kinds.size(), said])
	# Tidy: nothing of this is kept for the checks after.
	nearest.data.erase("found")
	world.annals.resize(annals_before)


## A fallen lead's demon king holds some gates of the world after, and the Gate Key tears a gate
## where it is turned ([D293], [D304]).
func _check_fallen_gates(world: World) -> void:
	print("")
	var kept_echoes := world.echoes
	var kept_keys := GameState.keys.duplicate()
	var kept_flags := GameState.flags.duplicate()
	var kept_sites := world.sites.size()
	var past: Array = [{ "hero": "iris", "name": "Iris", "level": 9 }]
	world.echoes = { "sibling": 1, "past": past }

	# No fall, no demon king; and never below rank C.
	var quiet := Site.create(Site.GATE, Vector2i(1, 1), "Quiet")
	quiet.rank = "B"
	_expect(quiet.demon_king([]) == "", "a gate held a demon king before anyone fell")
	var held := 0
	for i in 1000:
		var gate := Site.create(Site.GATE, Vector2i(i % 100, i / 100), "G%d" % i)
		gate.rank = "B"
		if gate.demon_king(past) != "":
			held += 1
	_expect(held > 120 and held < 280, "%d of 1000 B gates held a demon king with one world fallen, not about one in five" % held)
	var low := 0
	for i in 200:
		var gate := Site.create(Site.GATE, Vector2i(i % 100, i / 100), "E%d" % i)
		gate.rank = "E"
		if gate.demon_king(past) != "":
			low += 1
	_expect(low == 0, "%d E gates held a demon king" % low)
	print("demon kings: %d of 1000 B gates with one world fallen" % held)

	# The keeper is the fallen lead, named, and never under the level they fell at.
	var ashen := Site.create(Site.GATE, Vector2i(5, 5), "Ashen")
	ashen.rank = "C"
	ashen.data["demon"] = "iris"
	var party := Company.found().party_members()
	var met := Encounter.for_gate(world, ashen, 0, true, party, world.rng)
	var bosses: Array = met.get("enemies", []).filter(func(f: Dictionary) -> bool: return bool(f.get("boss", false)))
	_expect(bosses.size() == 1 and str(bosses[0].get("unit", "")) == "iris", "the demon king's gate was not kept by Iris (%s)" % [bosses])
	_expect(not bosses.is_empty() and int(bosses[0].get("level", 0)) >= 9, "Demon King Iris stood under the level she fell at")
	_expect(str(met.get("title", "")).contains("Demon King Iris"), "the keeper's title does not name the demon king: %s" % met.get("title", ""))
	var said := ashen.gone_into(1, past)
	_expect(ashen.label().contains("Demon King Iris"), "the map label does not name the demon king: %s" % ashen.label())
	_expect(said.any(func(l: String) -> bool: return l.contains("Demon King Iris")), "going in did not say who holds it")
	_expect(ashen.gone_into(1, past).is_empty(), "the demon king was announced twice")
	var words := ashen.demon_words("iris")
	_expect(str(words.get("their", "")) == "her" and str(words.get("Their", "")) == "Her", "Iris's words are not hers: %s" % [words])
	_expect(Site.from_dict(ashen.to_dict()).label() == ashen.label(), "the demon king was lost in the save")

	# The Gate Key: a shut double gate always gives it, once, with the gate's rank; then it tears a gate.
	GameState.keys = []
	GameState.flags.erase("gate_key:rank")
	_expect(Site.key_rank() == "", "a key was in hand before any was found")
	var twice := Site.create(Site.GATE, Vector2i(7, 7), "Twice")
	twice.rank = "C"
	twice.data["double"] = true
	var found := Spoils.gate_key(world, twice)
	_expect(GameState.keys.has("gate_key") and not found.is_empty(), "a shut double gate gave no Gate Key")
	_expect(Site.key_rank() == "C", "the key did not keep its gate's rank (%s)" % Site.key_rank())
	_expect(Spoils.gate_key(world, twice).is_empty(), "a second key came while one was held")
	var from := world.player_cell
	var torn := Site.tear(world, from, Site.key_rank())
	_expect(torn != null, "the Gate Key tore nothing")
	if torn != null:
		_expect(torn.kind == Site.GATE and torn.open and torn.rank == "C" and not torn.cleared, "the torn gate is not an open C gate")
		_expect(world.site_at(torn.cell) == torn and Pathfinder.distance(torn.cell, from) <= 2, "the torn gate is not where the key was turned")
		_expect(world.is_walkable(torn.cell), "the torn gate stands on unwalkable ground")
		_expect(str(torn.data.get("faction", "")) != "" and torn.floors() >= 1, "the torn gate has no holder or no floors")
		_expect(not torn.misread() or torn.reading() == torn.rank, "a torn gate's rank is not what the key said")
		var again := World.from_dict(world.to_dict()).site_at(torn.cell)
		_expect(again != null and bool(again.data.get("instant", false)) and again.open, "the torn gate was lost in the save")
		var second := Site.tear(world, from, "D")
		_expect(second != null and second.display_name != torn.display_name and second.cell != torn.cell, "two torn gates share a name or a cell")
		print("torn gates: %s at %s, then %s at %s" % [torn.display_name, torn.cell, second.display_name if second != null else "", second.cell if second != null else Vector2i.ZERO])

	world.sites.resize(kept_sites)
	world.echoes = kept_echoes
	GameState.keys = kept_keys
	GameState.flags = kept_flags


## A gate's rank is a reading, and a double gate climbs once gone into ([D293], [D302]).
func _check_readings() -> void:
	var misread := 0
	var doubled := 0
	var lying: Site = null
	for i in 1000:
		var gate := Site.create(Site.GATE, Vector2i(i % 40, i / 40), "Gate %d" % i)
		gate.rank = "B"
		if gate.misread():
			misread += 1
			lying = gate
		if gate.is_double(0):
			doubled += 1
		var low := Site.create(Site.GATE, gate.cell, "Low")
		low.rank = "D"
		_expect(not low.misread(), "a D-rank gate read wrong")
	_expect(misread > 50 and misread < 150, "%d of 1000 B-rank gates read wrong, not about one in ten" % misread)
	_expect(doubled > 50 and doubled < 150, "%d of 1000 gates were double, not about one in ten" % doubled)
	if lying != null:
		_expect(lying.reading() == "C" and lying.label().contains("C-rank"), "a misread B gate reads %s" % lying.reading())
		var said := lying.gone_into(0)
		_expect(lying.reading() == "B" and said.size() >= 1, "going into a misread gate did not show what it is")
	var double := Site.create(Site.GATE, Vector2i(3, 3), "Twice")
	double.rank = "E"
	double.data["double"] = true
	var floors := double.floors()
	var lines := double.gone_into(0)
	_expect(double.rank == "D" and double.sealed_in(), "a double gate did not climb and shut its way out (%s)" % double.rank)
	_expect(lines.any(func(l: String) -> bool: return l.contains("double")), "nobody said it was a double gate")
	double.gone_into(0)
	_expect(double.rank == "D", "a double gate climbed twice")
	_expect(double.floors() >= floors, "a double gate got shallower")
	double.cleared = true
	_expect(not double.sealed_in(), "a shut double gate kept its way out shut")
	var more := 0
	for i in 400:
		var gate := Site.create(Site.GATE, Vector2i(i, 7), "G")
		gate.rank = "C"
		if gate.is_double(3):
			more += 1
	_expect(more > 400 * 0.3, "three fallen worlds did not make double gates commoner (%d of 400)" % more)


func _check_world(world: World) -> void:
	_check_readings()
	_expect(world.tiles.size() == world.size.y, "world has %d rows" % world.tiles.size())
	for row: String in world.tiles:
		if row.length() != world.size.x:
			_expect(false, "a row is %d wide, expected %d" % [row.length(), world.size.x])
			break
	_expect(world.tower() != null, "world has no Tower")
	_expect(world.is_walkable(world.player_cell), "player starts on unwalkable ground")

	var gates := world.sites_of_kind(Site.GATE)
	_expect(not gates.is_empty(), "world has no gates")
	var ranks: Array = []
	for gate in gates:
		_expect(gate.rank in Site.RANKS, "gate rank '%s' is not a rank" % gate.rank)
		_expect(world.is_walkable(gate.cell), "gate %s sits on unwalkable ground" % gate.display_name)
		if gate.rank not in ranks:
			ranks.append(gate.rank)
	# A world with no gentle gate is a world you cannot start playing.
	_expect("E" in ranks, "no E-rank gate — nowhere is survivable at level 1")
	_expect(ranks.size() >= 4, "gate ranks only span %d steps of the ladder" % ranks.size())

	var names: Array = []
	for site in world.sites:
		_expect(site.display_name not in names, "two places are both called %s" % site.display_name)
		names.append(site.display_name)

	var libraries := world.sites_of_kind(Site.LIBRARY)
	_expect(not libraries.is_empty(), "world has no libraries")
	_expect(
		libraries.any(func(s: Site) -> bool: return s.data.get("doctrine", "") == "the_open_palm"),
		"no library holds the first doctrine"
	)


# --- characters ---------------------------------------------------------------


func _grow_a_hero(world: World) -> Character:
	var hero := Character.create("atlas", "", true)
	Progression.raise_to(hero, 12, world)
	print("")
	print("%s — level %d %s, hp %d, atk %d, def %d, spd %d" % [
		hero.display_name, hero.level, hero.class_name_text(),
		hero.max_hp(), hero.attack(), hero.defense(), hero.speed()
	])
	for tree_id: String in hero.trees:
		var tree := world.tree(tree_id)
		print("  tree %s (%s)" % [tree.get("display_name", tree_id), tree.get("theme", "?")])
	for ability_id: String in hero.abilities():
		var ability := Database.ability(ability_id)
		print("  - %-22s range %s-%s splash %s power %s" % [
			ability.get("display_name", ability_id),
			ability.get("min_range", 1), ability.get("range", 1),
			ability.get("splash", 0), ability.get("power", 1.0)
		])
	return hero


## A player who takes every power as it comes always has one to take when they
## are told they do: once their paths are walked to the end, another opens.
func _check_powers_never_run_dry(world: World) -> void:
	var kept_state := world.rng.state
	var lead := Character.create("atlas", "", true)
	lead.class_id = Database.own_class("atlas") if Database.own_class("atlas") != "" else "sworn_blade"
	var taken := 0
	for level in range(2, 21):
		Progression._level_up(lead, world)
		lead.pending_class_choice = false
		while lead.rungs > 0:
			var offered := Progression.rung_options(lead, world)
			if offered.is_empty():
				_expect(false, "level %d: %d power(s) owed and none to take" % [lead.level, lead.rungs])
				break
			_expect(Progression.spend_rung(lead, offered[0], world), "could not take an offered power")
			taken += 1
	_expect(taken >= 14, "took only %d powers from level 2 to 20" % taken)
	world.rng.state = kept_state


func _check_progression(hero: Character, world: World) -> void:
	_expect(hero.class_id != "", "level 12 character never took a class")
	_expect(hero.trees.size() == 2, "expected 2 trees by level 12, got %d" % hero.trees.size())
	_expect(not hero.learned.is_empty() or hero.rungs > 0, "character learned nothing from its trees")
	for ability_id: String in hero.abilities():
		_expect(not Database.ability(ability_id).is_empty(), "ability '%s' resolves to nothing" % ability_id)
	_check_powers_never_run_dry(world)

	# The Yoke trades power for growth.
	var plain := hero.attack()
	hero.yoke = true
	_expect(hero.attack() < plain, "the Training Yoke did not reduce attack")
	hero.yoke = false

	_expect(world.codex_understanding() > 0.0, "codex catalogued nothing")


func _check_doctrine(hero: Character, world: World) -> void:
	var before := hero.attack()
	Doctrine.learn(hero, "keen_edge", world.steps)
	_expect(hero.attack() > before, "doctrine gave no bonus")

	var student := Character.create("juno")
	_expect(Doctrine.teach(hero, student, "keen_edge", world.steps), "teaching failed")
	_expect(student.knows("keen_edge"), "student did not retain the doctrine")
	_expect(not Doctrine.teach(hero, student, "keen_edge", world.steps), "taught the same thing twice")

	var forgotten := Doctrine.decay(student, world.steps + Doctrine.FADE_AFTER_STEPS)
	_expect("keen_edge" in forgotten, "unused doctrine never faded")
	_expect(not student.knows("keen_edge"), "forgotten doctrine is still known")


# --- fate ---------------------------------------------------------------------


func _check_class_choice(world: World) -> void:
	# The XP curve is what is under test, not the difficulty dial on top of it.
	var setting := GameState.difficulty
	GameState.difficulty = "even"

	# A party member is asked; the world waits for the answer. One of the sixteen
	# starts in their own class, so the one asked is a hire with none (market.gd).
	var mine := Character.create("bram", "", true)
	Progression.award(mine, Progression.xp_to_next(1), world)
	_expect(mine.level == 2, "one level's worth of XP did not level anyone")
	_expect(mine.pending_class_choice, "a player character was not offered a class choice")
	_expect(mine.class_id == "", "a player character was assigned a class without asking")
	_expect(not Progression.settle_class(mine, "hedge_priest"), "accepted a class outside the options")
	_expect(Progression.settle_class(mine, "magic_swordsman"), "rejected a valid class choice")
	_expect(not mine.pending_class_choice, "the choice stayed pending after being made")

	# Anyone who is not the player settles into a class on their own.
	var theirs := Character.create("brigand")
	Progression.award(theirs, Progression.xp_to_next(1), world)
	_expect(theirs.class_id != "", "an NPC never settled into a class")
	_expect(not theirs.pending_class_choice, "an NPC is waiting on the player")
	GameState.difficulty = setting


func _check_fate(world: World) -> void:
	print("")
	# The baseline death odds under the rules are what is under test, not the difficulty dial.
	var setting := GameState.difficulty
	GameState.difficulty = "even"
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242

	# Alone, unarmed, unread, in the middle of nowhere: death is the default.
	var doomed := Character.create("juno")
	var graces := Fate.graces_for(doomed, {"enemy_kind": "beast"})
	var bare_odds := 0.0
	for grace: Dictionary in graces:
		bare_odds += float(grace["chance"])
	print("bare survival odds: %d%%" % roundi(bare_odds * 100.0))
	_expect(bare_odds < 0.2, "dying alone is too survivable at %d%%" % roundi(bare_odds * 100.0))

	var deaths := 0
	for i in 200:
		var victim := Character.create("juno")
		if Fate.resolve(victim, {"enemy_kind": "beast"}, rng)["outcome"] == Fate.DEAD:
			deaths += 1
	print("fell alone 200 times, died %d" % deaths)
	_expect(deaths > 150, "only %d of 200 lone deaths stuck" % deaths)

	# A charm is spent to buy one life, and is gone afterwards.
	var carried := Character.create("atlas")
	carried.charms.append("grave_token")
	var saved_by_charm := 0
	for i in 200:
		var victim := Character.create("atlas")
		victim.charms.append("grave_token")
		var outcome := Fate.resolve(victim, {"enemy_kind": "beast"}, rng)
		if outcome["reason"] == Fate.BY_CHARM:
			saved_by_charm += 1
			_expect(victim.charms.is_empty(), "the charm was not spent")
			_expect(victim.is_alive(), "the charm saved a corpse")
	print("grave token caught %d of 200" % saved_by_charm)
	_expect(saved_by_charm > 60, "the charm fired only %d times in 200" % saved_by_charm)

	# Raiders take prisoners; captives leave the party but not the world.
	var captures := 0
	for i in 200:
		var victim := Character.create("cato")
		var outcome := Fate.resolve(victim, {"enemy_kind": "raider", "world": world, "cell": world.player_cell}, rng)
		if outcome["outcome"] == Fate.CAPTURED:
			captures += 1
			_expect(victim.captured_at != "", "a captive is being held nowhere")
			_expect(not victim.is_alive() and victim.is_lost(), "a captive is still in the party")
	print("taken alive by raiders %d of 200" % captures)
	_expect(captures > 30, "raiders captured only %d in 200" % captures)

	# Standing allies and read books both buy real odds.
	var alone := Character.create("atlas")
	var lone_odds := _total_odds(alone, {"enemy_kind": "beast"})
	var helped := Character.create("atlas")
	var friends: Array = [Character.create("juno"), Character.create("cato")]
	var helped_odds := _total_odds(helped, {"enemy_kind": "beast", "allies": friends})
	_expect(helped_odds > lone_odds, "allies did not improve the odds")

	var read := Character.create("atlas")
	Doctrine.learn(read, "the_vigil", 0)
	_expect(_total_odds(read, {"enemy_kind": "beast"}) > lone_odds, "doctrine did not improve the odds")
	print("odds alone %d%%, with two allies %d%%, having read one book %d%%" % [
		roundi(lone_odds * 100.0), roundi(helped_odds * 100.0),
		roundi(_total_odds(read, {"enemy_kind": "beast"}) * 100.0)
	])
	GameState.difficulty = setting


func _total_odds(character: Character, context: Dictionary) -> float:
	var total := 0.0
	for grace: Dictionary in Fate.graces_for(character, context):
		total += float(grace["chance"])
	return total


# --- errands ------------------------------------------------------------------


func _check_errands(world: World) -> void:
	var villages: Array = world.sites.filter(func(s: Site) -> bool: return s.kind == Site.VILLAGE)
	_expect(not villages.is_empty(), "the world has nowhere to post an errand")
	if villages.is_empty():
		return
	var site: Site = villages[0]

	var kinds: Dictionary = {}
	for i in 200:
		var rolled := _reroll_board(site, world)
		var kind: String = rolled.get("kind", "")
		kinds[kind] = int(kinds.get(kind, 0)) + 1
		_expect(not str(rolled.get("text", "")).contains("{"), "a %s errand left a placeholder in its text" % kind)
		_expect(int(rolled.get("gold", 0)) > 0, "a %s errand pays nothing" % kind)
		if kind != Errand.CULL:
			_expect(rolled.get("to", []).size() == 2, "a %s errand points nowhere" % kind)
	print("")
	print("errand kinds over 200 rolls: %s" % kinds)
	_expect(kinds.size() == 4, "only %d of the 4 errand kinds ever came up" % kinds.size())

	var accepted: Array = []

	# A cull is settled where it was posted, once enough of them are down.
	var cull := _take_errand_of(site, world, Errand.CULL, accepted)
	if not cull.is_empty():
		_expect(not Errand.is_complete(cull), "a fresh cull is already finished")
		for i in int(cull["count"]):
			Errand.record_kill(accepted, cull["target"])
		_expect(Errand.is_complete(cull), "killing enough of them did not finish the cull")
		var purse := GameState.gold
		_expect(not Errand.turn_in(accepted, cull, world).is_empty(), "settling a cull said nothing")
		_expect(GameState.gold == purse + int(cull["gold"]), "the cull did not pay out")
		_expect(accepted.is_empty(), "a settled errand is still on the books")

	# A look finishes where it points, with nothing to carry home.
	var look := _take_errand_of(site, world, Errand.LOOK, accepted)
	if not look.is_empty():
		var purse := GameState.gold
		var lines := Errand.on_arrive(accepted, _errand_target(look), world)
		_expect(lines.size() >= 2, "arriving where a look errand points said nothing")
		_expect(GameState.gold == purse + int(look["gold"]), "the look errand did not pay out")
		_expect(accepted.is_empty(), "the look errand is still on the books")

	# A fetch is two journeys: out to the thing, and back to whoever wants it.
	var fetch := _take_errand_of(site, world, Errand.FETCH, accepted)
	if not fetch.is_empty():
		_expect(
			Errand.completable_at(accepted, site.cell).is_empty(),
			"a fetch could be handed in before anything was fetched"
		)
		Errand.on_arrive(accepted, _errand_target(fetch), world)
		_expect(Errand.is_complete(fetch), "reaching the place did not finish the fetching")
		_expect(
			not Errand.completable_at(accepted, site.cell).is_empty(),
			"the fetch cannot be handed back where it was posted"
		)
		Errand.turn_in(accepted, fetch, world)
		_expect(accepted.is_empty(), "the fetch is still on the books")

	# You can only carry so many favours at once.
	var held: Array = []
	for i in Errand.max_accepted() + 2:
		_reroll_board(site, world)
		Errand.accept(site, held, world)
	_expect(
		held.size() == Errand.max_accepted(),
		"took %d errands, the cap is %d" % [held.size(), Errand.max_accepted()]
	)


func _reroll_board(site: Site, world: World) -> Dictionary:
	site.data["errand"] = {}
	Errand.refresh(site, world)
	return Errand.board(site)


## Keep shaking the board until it offers [param kind], then take that one.
func _take_errand_of(site: Site, world: World, kind: String, accepted: Array) -> Dictionary:
	for i in 400:
		if _reroll_board(site, world).get("kind", "") == kind:
			return Errand.accept(site, accepted, world)
	_expect(false, "the board never once offered a %s errand" % kind)
	return {}


func _errand_target(errand: Dictionary) -> Vector2i:
	var pair: Array = errand.get("to", [0, 0])
	return Vector2i(int(pair[0]), int(pair[1]))


# --- trivia, grimoires and graves ---------------------------------------------


func _check_trivia(world: World) -> void:
	world.trivia.clear()
	_expect(Trivia.total() > 0, "the world has no trivial spells to find")
	_expect(world.trivia.is_empty(), "a fresh world has already collected trivia")

	var before := world.codex_understanding()
	var seen: Dictionary = {}
	for i in Trivia.total():
		var entry := Trivia.discover(world)
		_expect(not entry.is_empty(), "ran out of trivial spells after %d of %d" % [i, Trivia.total()])
		if entry.is_empty():
			break
		_expect(not seen.has(entry["id"]), "trivial spell %d was found twice" % int(entry["id"]))
		seen[entry["id"]] = true
		_expect(str(entry.get("note", "")) != "", "a trivial spell came with no marginal note")

	_expect(Trivia.discover(world).is_empty(), "the catalogue handed out more than it holds")
	_expect(is_equal_approx(Trivia.share_found(world), 1.0), "a full catalogue is not counted as full")
	var after := world.codex_understanding()
	_expect(after > before, "collecting useless magic taught the Codex nothing")
	print("")
	print("codex understanding: %.2f with no trivia, %.2f with all %d" % [before, after, Trivia.total()])

	# Understanding is what makes generated powers come out stronger.
	var weak := AbilityGrammar.generate_tree("edge", world.rng, before)
	var strong := AbilityGrammar.generate_tree("edge", world.rng, after)
	_expect(
		_top_power(strong) > _top_power(weak),
		"understanding the grammar did not strengthen what it generates"
	)


func _top_power(tree: Dictionary) -> float:
	var best := 0.0
	var definitions: Dictionary = tree["definitions"]
	for ability_id: String in definitions:
		best = maxf(best, float(definitions[ability_id].get("power", 0.0)))
	return best


func _check_grimoires(world: World) -> void:
	var villages: Array = world.sites.filter(func(s: Site) -> bool: return s.kind == Site.VILLAGE)
	if villages.is_empty():
		return
	var site: Site = villages[0]
	var reader := Character.create("atlas")

	Grimoire.stock(site, world)
	_expect(not Grimoire.offer(site).is_empty(), "no grimoire went on the shelf")
	_expect(Grimoire.price(site) > 0, "a grimoire is being given away")

	# You cannot afford what you cannot afford, and the shelf keeps the book.
	var purse := GameState.gold
	GameState.gold = 0
	_expect(not Grimoire.buy_and_read(site, reader, world).is_empty(), "a refused sale said nothing")
	_expect(not Grimoire.offer(site).is_empty(), "the shelf lost a book that was never paid for")

	GameState.gold = 2000000
	var outcomes: Dictionary = {}
	for i in 300:
		site.data["grimoire"] = {}
		Grimoire.stock(site, world)
		var cost := Grimoire.price(site)
		var before := GameState.gold
		var lines := Grimoire.buy_and_read(site, reader, world)
		_expect(lines.size() >= 2, "opening a grimoire produced no story")
		_expect(GameState.gold == before - cost, "a grimoire charged the wrong price")
		_expect(Grimoire.offer(site).is_empty(), "a bought grimoire is still on the shelf")
		outcomes[_grimoire_outcome(lines)] = int(outcomes.get(_grimoire_outcome(lines), 0)) + 1
	GameState.gold = purse
	print("300 grimoires opened: %s" % outcomes)
	_expect(int(outcomes.get("dud", 0)) > 0, "no grimoire was ever a dud, which is not the deal")


func _grimoire_outcome(lines: Array) -> String:
	var body: String = str(lines[1])
	if body.begins_with("It is the real thing") or body.begins_with("It is sound work"):
		return "doctrine"
	if body.begins_with("Not doctrine") or body.begins_with("A small useless spell"):
		return "trivia"
	return "dud"


func _check_memorials(world: World) -> void:
	var fallen := Character.create("juno")
	Doctrine.learn(fallen, "the_vigil", world.steps)
	var sites_before := world.sites.size()

	var grave := Memorial.raise(world, fallen, world.player_cell, "raider")
	_expect(world.sites.size() == sites_before + 1, "the grave never reached the map")
	_expect(Memorial.is_grave(grave), "the grave is not a grave")
	_expect(world.site_at(grave.cell) == grave, "the grave cannot be walked to")

	# Graves give way to the living: one never lands on an existing place.
	var village: Array = world.sites.filter(func(s: Site) -> bool: return s.kind == Site.VILLAGE)
	if not village.is_empty():
		var crowded := Memorial.raise(world, fallen, village[0].cell, "raider")
		_expect(crowded.cell != village[0].cell, "a grave was dug on top of a village")

	world.steps += 500
	var mourner := Character.create("atlas")
	var lines := Memorial.visit(grave, world, [mourner])
	_expect(lines.size() >= 3, "standing at a grave said almost nothing")
	_expect(str(lines[0]).contains(fallen.display_name), "the epitaph does not name them")
	_expect(str(lines[0]).contains("500"), "the epitaph does not say how long it has been")
	_expect(bool(grave.data["visited"]), "the grave does not remember being visited")

	# Remembering somebody counts as using what you know.
	_expect(
		int(mourner.doctrine_seen.get("the_vigil", -1)) == world.steps,
		"the visit did not reinforce what the party carries"
	)
	_expect(mourner.knows("the_vigil"), "the grave did not hand on what the dead knew")
	_expect(bool(grave.data["passed_on"]), "the grave will hand its knowledge on twice")

	var again := Memorial.visit(grave, world, [mourner])
	_expect(not again.is_empty(), "coming back to a grave said nothing at all")
	print("")
	print("at the grave, 500 steps on:")
	for line: String in lines:
		print("  %s" % line)


# --- persistence --------------------------------------------------------------


func _check_roster(world: World) -> void:
	# A run starts with its lead alone, one of the sixteen.
	var alone := Roster.found()
	_expect(alone.characters.size() == 1 and alone.party.size() == 1, "a fresh roster is not the lead alone")
	_expect(alone.player() != null and alone.player().template_id == Roster.FIRST_LEAD, "a run with no pick is not led by %s" % Roster.FIRST_LEAD)
	_expect(not Database.hero(alone.player().template_id).is_empty(), "the lead is not one of the sixteen")

	var roster := Company.found()
	_expect(roster.player() != null and roster.player().is_player, "nobody on the roster is the player")
	_expect(roster.fit_to_fight().size() == 3, "the company of three cannot fight")
	_expect(not roster.run_is_over(), "a fresh roster has already ended the run")

	# The dead and the taken come off the marching order but stay on the books.
	var fallen: Character = roster.party_members()[1]
	fallen.status = Fate.DEAD
	var taken: Character = roster.party_members()[2]
	taken.status = Fate.CAPTURED
	taken.captured_at = "Hollowbarrow"

	var lost := roster.drop_the_lost()
	_expect(lost.size() == 2, "lost %d characters, expected 2" % lost.size())
	_expect(roster.party.size() == 1, "the party did not shrink")
	_expect(roster.characters.size() == 3, "a lost character was deleted instead of remembered")
	_expect(roster.by_id(taken.id) != null, "the captive is gone from the world entirely")
	_expect(not roster.run_is_over(), "one survivor should still be a run")

	roster.party_members()[0].status = Fate.DEAD
	roster.drop_the_lost()
	_expect(roster.run_is_over(), "losing everyone did not end the run")


# --- encounters ---------------------------------------------------------------


## D262 (play-test 7): five tiers of each monster, dealt by the fight's level. A low fight meets the
## lesser and the plain, a high one the hob and the top; never more than one top a fight; a keeper and a
## monster with no tiers are dealt as they were named; each tier stronger than the one below.
func _check_tiers() -> void:
	print("")
	var families: Array = Tiers.rules().get("families", {}).keys()
	_expect(families.has("goblin") and families.has("wolf"), "tiers: families are only %s" % [families])
	for family: String in families:
		_check_a_family(family)


func _check_a_family(family: String) -> void:
	var line := Tiers.kinds(family)
	_expect(line.size() == 5 and line[4] is Array and str(line[1]) == family,
		"tiers: %s is not lesser, %s, high, hob and a top of one or more" % [line, family])
	var health := -1
	for kind: Variant in line:
		var first := str(kind[0]) if kind is Array else str(kind)
		var unit := Database.unit_template(first)
		_expect(str(unit.get("family", "")) == family, "tiers: %s is not a %s in data/units.json" % [first, family])
		_expect(int(unit.get("max_hp", 0)) > health, "tiers: %s is no stronger than the tier below" % first)
		health = int(unit.get("max_hp", 0))
	var tops: Array = line[4]
	var rng := RandomNumberGenerator.new()
	rng.seed = 262
	var seen := { 1: {}, 24: {} }
	for level: int in seen:
		for i in 200:
			rng.randi()
			var fight: Array = [{ "unit": family }, { "unit": family }, { "unit": family }, { "unit": "brigand" },
				{ "unit": family, "boss": true }]
			Tiers.deal(fight, level, rng)
			var at_top := fight.filter(func(e: Dictionary) -> bool: return tops.has(str(e["unit"])))
			_expect(at_top.size() <= 1, "tiers: a level %d fight dealt %d %s" % [level, at_top.size(), tops])
			_expect(str(fight[3]["unit"]) == "brigand" and str(fight[4]["unit"]) == family,
				"tiers: a brigand or a keeper was dealt as something else (%s)" % [fight])
			for entry: Dictionary in fight.slice(0, 3):
				seen[level][str(entry["unit"])] = true
	_expect((seen[1] as Dictionary).keys().all(func(k: String) -> bool: return k == str(line[0]) or k == family),
		"tiers: a level 1 fight met %s" % [(seen[1] as Dictionary).keys()])
	_expect(seen[24].has(str(line[3])) and tops.all(func(k: String) -> bool: return seen[24].has(k))
		and not seen[24].has(str(line[0])), "tiers: a level 24 fight met %s" % [(seen[24] as Dictionary).keys()])
	print("tiers: %s at level 1 met %s; at 24 %s" % [family, (seen[1] as Dictionary).keys(), (seen[24] as Dictionary).keys()])


func _check_encounters(world: World) -> void:
	print("")
	var party := Company.found().party_members()
	# Composition is what is under test; the difficulty dials thin every band.
	var setting := GameState.difficulty
	GameState.difficulty = "even"

	# Danger is a property of place: loud near an open gate, quiet by a hearth.
	var open_gates := world.sites_of_kind(Site.GATE).filter(func(s: Site) -> bool: return s.open)
	_expect(not open_gates.is_empty(), "no gate is open, so nothing is dangerous")
	if not open_gates.is_empty():
		var at_gate := Encounter.chance_at(world, open_gates[0].cell)
		var at_home := Encounter.chance_at(world, world.player_cell)
		print("danger at an open gate %d%%, at the starting village %d%%" % [
			roundi(at_gate * 100.0), roundi(at_home * 100.0)
		])
		_expect(at_gate > at_home, "standing in a gate's mouth is no worse than standing at home")
		_expect(at_gate <= 0.45, "encounter chance %f is out of bounds" % at_gate)

	_check_field(Encounter.wild(world, world.player_cell, party, world.rng), "wild")

	var gate: Site = world.sites_of_kind(Site.GATE)[0]
	# A keeper's prize (D219): certain by the third keeper of a faction, and the count starts again.
	var faction := str(gate.data.get("faction", Faction.FALLBACK))
	var prize := str(Database.world_rules.get("keepers", {}).get("prizes", {}).get(faction, ""))
	_expect(prize != "", "the %s keeper carries no prize" % faction)
	world.keepers.erase(faction)
	var tries := 0
	var won := false
	while not won and tries < 5:
		tries += 1
		var said := Spoils.keeper_prize(world, gate)
		won = int(world.keepers.get(faction, 0)) == 0
		_expect(not said.is_empty() and str(said[0]).contains(Gear.display_name(prize)),
			"the keeper's line does not name its prize (%s)" % [said])
	_expect(won and tries <= 3, "the %s keeper's prize took %d keepers, not three at most" % [faction, tries])
	world.keepers[faction] = 2
	_expect(int(World.from_dict(world.to_dict()).keepers.get(faction, -1)) == 2, "the keepers' count was lost in the save")
	world.keepers.erase(faction)
	print("keepers: the %s keeper's %s came on keeper %d" % [faction, prize, tries])
	_check_treasure(world)
	var delve := Encounter.for_gate(world, gate, 0, true, party, world.rng)
	_check_field(delve, "gate")
	_expect(delve["enemies"].size() >= 3, "a guarded gate fielded only %d" % delve["enemies"].size())

	var climb := Encounter.for_tower(world, world.tower(), 6, party, world.rng)
	_check_field(climb, "tower")
	var shallow := Encounter.for_tower(world, world.tower(), 1, party, world.rng)
	_expect(
		_top_level(climb) > _top_level(shallow),
		"the Tower is no harder at floor 6 than at floor 1"
	)
	print("tower floor 1 fields level %d, floor 6 fields level %d" % [_top_level(shallow), _top_level(climb)])
	# Play-test 4 (D189): a company of five at level 8 walked through floors 6 to 20 in three-second
	# fights. A fought floor meets the party's level and brings more foes for more members.
	var company: Array = []
	for id: String in ["janus", "atlas", "caesar", "ultor", "vesta"]:
		var member := Character.create(id)
		member.level = 8
		company.append(member)
	var eleventh := Encounter.for_tower(world, world.tower(), 11, company, world.rng)
	var lowest := 999
	for foe: Dictionary in eleventh["enemies"]:
		lowest = mini(lowest, int(foe["level"]))
	_expect(eleventh["enemies"].size() >= 5, "floor 11 fielded only %d against a company of five" % eleventh["enemies"].size())
	_expect(lowest >= 7, "floor 11 fielded a level %d foe against a company at level 8" % lowest)
	_expect(_top_level(climb) >= 5, "floor 6 fields level %d, below the walked floors' bands" % _top_level(climb))

	var top := world.tower_floors()
	var apex := Encounter.for_tower(world, world.tower(), top, party, world.rng)
	_expect(str(apex.get("title", "")).begins_with("The Spire Apex"), "floor %d is not the apex fight" % top)
	_expect(_top_level(apex) < 60, "the top of the Tower fields level %d" % _top_level(apex))
	var cohorts: Array = Database.world_rules.get("tower", {}).get("cohorts", [])
	if cohorts.size() > 1:
		var edge := int(cohorts[0]["to"])
		var below := Encounter.for_tower(world, world.tower(), edge, party, world.rng)
		var above := Encounter.for_tower(world, world.tower(), edge + 1, party, world.rng)
		_expect(
			str(below["title"]).get_slice("Cohort of ", 1) != str(above["title"]).get_slice("Cohort of ", 1),
			"floors %d and %d field the same cohort" % [edge, edge + 1]
		)
	print("tower floor %d fields level %d" % [top, _top_level(apex)])

	# D211: a band on the road is dealt by the setting's level dial like any fight, all of it;
	# the First Hour once met them at their full level, so fresh leads fell in their first fights.
	var band := Prowler.create(world.player_cell, ["wolf", "wolf", "wolf"])
	var even_dice := RandomNumberGenerator.new()
	even_dice.seed = 211
	var at_even := Encounter.for_band(world, band, party, even_dice)
	GameState.difficulty = "first_hour"
	var kind_dice := RandomNumberGenerator.new()
	kind_dice.seed = 211
	var at_first := Encounter.for_band(world, band, party, kind_dice)
	_expect(at_first["enemies"].size() == maxi(3, Encounter.answering(party.size())),
		"a band of three fields %d on the First Hour" % at_first["enemies"].size())
	# D272: a band answers the company with as many as it is, the rest out of cover, and all of it
	# hits harder than its level and gets some of every blow past armour.
	var lone := Prowler.create(world.player_cell, ["wolf"])
	var answered := Encounter.for_band(world, lone, party, kind_dice)
	_expect(answered["enemies"].size() == Encounter.answering(party.size()),
		"a lone wolf met a company of %d with %d" % [party.size(), answered["enemies"].size()])
	_expect(answered["enemies"].size() == 1 or str(answered.get("more", "")).contains("more"),
		"the rest of a band came out of cover unsaid")
	_expect(Encounter.answering(4) == 4 and Encounter.company_level(1) == 0 and Encounter.company_level(3) > 0,
		"a band of the land does not answer a company of four, or stands higher against a lead alone")
	_expect((answered["enemies"] as Array).all(func(e: Dictionary) -> bool:
		return float(e.get("graze", 0.0)) > 0.0 and float(e.get("bite", 1.0)) > 1.0),
		"a band of the land neither bites nor grazes: %s" % [answered["enemies"]])
	_expect(_top_level(at_first) <= maxi(1, _top_level(at_even) + roundi(Difficulty.dial("enemy_level"))),
		"a First Hour band stands at level %d against %d on Even" % [_top_level(at_first), _top_level(at_even)])
	# And a gate's keeper, which met a lone fresh lead two levels over its floor.
	var kept := Encounter.for_gate(world, gate, 0, true, party, kind_dice)
	var keeper: Dictionary = kept["enemies"].filter(func(e: Dictionary) -> bool: return e.get("boss", false))[0]
	var keeper_level := Difficulty.levelled(maxi(Encounter.party_level(party), gate.expected_level()) \
			+ int(Encounter._by_rank("level", Site.rank_index(gate.rank), 0)) + 2)
	_expect(int(keeper["level"]) == keeper_level,
		"a First Hour gate's keeper stands at level %d, not %d" % [int(keeper["level"]), keeper_level])
	# A big gate's bands stand lower and climb slower ([D273]); E to C as they were.
	_expect(Encounter._by_rank("level", 0, 99) == 0.0 and Encounter._by_rank("per_floor", 2, 0) == 1.0,
		"a small gate's bands were moved by the big gates' pitch")
	_expect(Encounter._by_rank("level", 3, 0) < 0.0 and Encounter._by_rank("level", 5, 0) <= Encounter._by_rank("level", 3, 0) \
			and Encounter._by_rank("per_floor", 4, 1.0) < 1.0,
		"a big gate's bands are not pitched lower: B %s, S %s" % [Encounter._by_rank("level", 3, 0), Encounter._by_rank("level", 5, 0)])
	# A lesser gate is kept by the strongest of its floor, not the faction's champion.
	for lesser: Site in world.sites_of_kind(Site.GATE):
		if Site.rank_index(lesser.rank) >= Site.rank_index(str(Database.encounters.get("champion_from", "E"))):
			continue
		var met := Encounter.for_gate(world, lesser, 0, true, party, kind_dice)
		var held: Dictionary = met["enemies"].filter(func(e: Dictionary) -> bool: return e.get("boss", false))[0]
		_expect(str(held["unit"]) != Faction.champion(str(lesser.data.get("faction", Faction.FALLBACK))) \
				or Faction.pool(str(lesser.data.get("faction", Faction.FALLBACK)), 1).has(held["unit"]),
			"%s (rank %s) is kept by its faction's champion, %s" % [lesser.display_name, lesser.rank, held["unit"]])
		break
	GameState.difficulty = setting


## Treasure maps (D220): scraps from beaten bands; the last makes an X a few days off, which the
## quest list follows, the save keeps, and standing on digs up a find with something to carry.
func _check_treasure(world: World) -> void:
	var Treasure := preload("res://src/chronicle/treasure.gd")
	var steps_were := world.steps
	var need := int(Database.world_rules.get("treasure", {}).get("pieces", 3))
	world.treasure = { "pieces": need - 1 }
	var said: Array[String] = []
	for i in 400:
		world.steps = steps_were + i
		said = Treasure.on_band_beaten(world, world.player_cell)
		if Treasure.at(world).x >= 0:
			break
	var x := Treasure.at(world)
	_expect(x.x >= 0, "treasure: the last scrap made no X in 400 bands")
	if x.x < 0:
		world.steps = steps_were
		world.treasure = {}
		return
	_expect(not said.is_empty() and str(said[0]).contains("X"), "treasure: the X was not said (%s)" % [said])
	_expect(world.site_at(x) == null and world.is_walkable(x), "treasure: the X is on a place or in the water")
	_expect(Treasure.pieces(world) == 0, "treasure: scraps left over after the X")
	for i in 50:
		world.steps += 1
		Treasure.on_band_beaten(world, world.player_cell)
	_expect(Treasure.pieces(world) == 0, "treasure: scraps turned up while an X was waiting")
	_expect(Treasure.at(World.from_dict(world.to_dict())) == x, "treasure: the X was lost in the save")
	var listed := (preload("res://src/world/quests.gd")).all(world, {}).filter(func(e: Dictionary) -> bool: return str(e.get("id", "")) == "treasure")
	_expect(listed.size() == 1 and listed[0]["cell"] == x, "treasure: the quest list does not follow the X")
	_expect(Treasure.dig(world, x + Vector2i(1, 0)).is_empty(), "treasure: dug up next to the X")
	var haul := Treasure.dig(world, x)
	_expect(str(haul.get("item", "")) != "" and int(haul.get("gold", 0)) > 0, "treasure: the X held %s" % [haul])
	_expect(Treasure.at(world).x < 0, "treasure: the X stayed after it was dug")
	world.steps = steps_were
	world.treasure = {}
	print("treasure: %d scraps make an X %s off; dug, it holds %s and %d gold" % [need, Roadside.bearing(world.player_cell, x), haul.get("item", ""), int(haul.get("gold", 0))])


## Every generated battlefield has to be one a fight can actually happen on.
func _check_field(meeting: Dictionary, label: String) -> void:
	var map: Dictionary = meeting.get("map", {})
	var rows: Array = map.get("tiles", [])
	_expect(not rows.is_empty(), "%s encounter generated no ground" % label)
	_expect(rows.size() == BattleMapGen.SIZE.y, "%s field is %d rows" % [label, rows.size()])
	for row: String in rows:
		if row.length() != BattleMapGen.SIZE.x:
			_expect(false, "%s field has a ragged row" % label)
			break

	_expect(not meeting["enemies"].is_empty(), "%s encounter has nobody in it" % label)
	_expect(
		map["player_spawns"].size() >= Company.JOINED.size() + 1,
		"%s field has room for only %d of the party" % [label, map["player_spawns"].size()]
	)

	var legend: Dictionary = map["legend"]
	for spawn: Array in map["player_spawns"]:
		_expect(_walkable(rows, legend, spawn), "%s field spawns the party in a wall" % label)
	for entry: Dictionary in map["enemies"]:
		_expect(entry.has("cell"), "%s encounter left an enemy unplaced" % label)
		_expect(int(entry.get("level", 0)) > 0, "%s encounter fielded a level-zero foe" % label)
		_expect(_walkable(rows, legend, entry["cell"]), "%s field spawns a foe in a wall" % label)


func _walkable(rows: Array, legend: Dictionary, cell: Array) -> bool:
	var symbol: String = rows[int(cell[1])][int(cell[0])]
	return Database.terrain_type(legend.get(symbol, "grass")).get("walkable", true)


func _top_level(meeting: Dictionary) -> int:
	var best := 0
	for entry: Dictionary in meeting["enemies"]:
		best = maxi(best, int(entry.get("level", 0)))
	return best


# --- conversations ------------------------------------------------------------


## Every reply has somewhere to go, and a check the party can actually roll.
func _check_dialogue() -> void:
	print("")
	for dialogue_id: String in ["prologue", "ambush", "respite", "the_chief"]:
		var nodes := DialogueScript.nodes(dialogue_id)
		_expect(not nodes.is_empty(), "dialogue '%s' has no nodes" % dialogue_id)
		_expect(
			nodes.has(DialogueScript.start_id(dialogue_id)),
			"dialogue '%s' starts nowhere" % dialogue_id
		)
		var choices := 0
		for node_id: String in nodes:
			var node: Dictionary = nodes[node_id]
			var targets: Array = [node.get("next", DialogueScript.END)]
			for option: Dictionary in node.get("options", []):
				choices += 1
				targets.append(option.get("goto", DialogueScript.END))
				var check: Dictionary = option.get("check", {})
				if check.is_empty():
					continue
				_expect(
					DialogueScript.SKILLS.has(check.get("skill", "")),
					"%s/%s rolls an unknown skill" % [dialogue_id, node_id]
				)
				targets.append(check.get("success", DialogueScript.END))
				targets.append(check.get("failure", DialogueScript.END))
			for target: String in targets:
				_expect(
					target == DialogueScript.END or nodes.has(target),
					"%s/%s leads to missing node '%s'" % [dialogue_id, node_id, target]
				)
		print("dialogue %-10s %d nodes, %d replies" % [dialogue_id, nodes.size(), choices])

	var result := DialogueScript.roll({"skill": "might", "dc": 10})
	_expect(int(result["die"]) >= 1 and int(result["die"]) <= 20, "the check die is not a d20")
	_expect(int(result["bonus"]) >= 0, "the party rolls a negative bonus")


## Walk a long way and make sure the loop survives it.
func _check_walking(world: World) -> void:
	print("")
	var party := Company.found().party_members()
	var walker := world.player_cell
	var fights := 0
	var notices := 0
	var steps := 800

	for i in steps:
		var options: Array[Vector2i] = []
		for offset: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if world.is_walkable(walker + offset):
				options.append(walker + offset)
		_expect(not options.is_empty(), "walked into a dead end at %s" % walker)
		if options.is_empty():
			break

		walker = options[world.rng.randi() % options.size()]
		world.player_cell = walker
		notices += world.step().size()
		if not Encounter.roll(world, walker, party, world.rng).is_empty():
			fights += 1

	_expect(world.steps >= steps, "the clock did not keep up with the walking")
	_expect(fights > 0, "walked %d steps without meeting anything" % steps)
	_expect(fights < steps / 2, "met something on %d of %d steps" % [fights, steps])
	print("walked %d steps: %d encounters, %d world notices" % [steps, fights, notices])

	var open_now := world.sites_of_kind(Site.GATE).filter(func(s: Site) -> bool: return s.open).size()
	print("gates open after the walk: %d" % open_now)


# --- persistence --------------------------------------------------------------

## The lands do something (`doug-md`, 2026-10-13): a band camped in a land is
## mostly made of what lives there, the strange lands are rare, the right gear
## keeps a hazard off, and every land named in the data is a real one.
func _check_lands(world: World) -> void:
	var counts := {}
	var walkable := 0
	var local_bands := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for y in world.size.y:
		for x in world.size.x:
			var cell := Vector2i(x, y)
			if not world.is_walkable(cell):
				continue
			walkable += 1
			var land := Biome.at(world, cell)
			counts[land] = int(counts.get(land, 0)) + 1
			var locals := Encounter._land_foes(world, cell)
			if locals.is_empty() or local_bands >= 40:
				continue
			local_bands += 1
			var band := Encounter._band_at(world, cell, rng)
			for unit_id: String in band.pack:
				# A goblin that lives there may come as any of its five tiers (D262).
				var family := str(Database.unit_template(unit_id).get("family", unit_id))
				_expect(locals.has(unit_id) or locals.has(family), "a band in the %s fields %s, who does not live there" % [land, unit_id])
				# D211: the great beasts wait for the party to grow.
				var grown := Encounter.party_level(GameState.party_characters())
				_expect(int(Database.biomes.get("foe_levels", {}).get(unit_id, 0)) <= grown,
					"a band in the %s fields %s against a party at level %d" % [land, unit_id, grown])
	_expect(local_bands > 0, "no band anywhere is made of what lives in its land")
	var strange := 0
	for land: String in ["slime", "crystal", "fungal", "mist"]:
		strange += int(counts.get(land, 0))
	_expect(float(strange) / float(maxi(1, walkable)) < 0.08,
		"the strange lands cover %d of %d tiles, which is not rare" % [strange, walkable])
	_expect(counts.size() >= 12, "only %d lands on the whole continent" % counts.size())
	for land: String in Database.biomes.get("biomes", {}):
		for unit_id: String in Biome.data(land).get("foes", []):
			_expect(not Database.unit_template(unit_id).is_empty(), "the %s fields %s, who does not exist" % [land, unit_id])
	var traveller := Character.create("atlas")
	traveller.equipment = ""
	traveller.charms = []
	_expect(not Biome.spared(traveller, "cold") or Gear.piece(Gear.issued_id(traveller)).get("proof", []).has("cold"),
		"nothing at all keeps the cold off, and still Atlas is spared")
	traveller.charms = ["salt_pouch"]
	_expect(Biome.spared(traveller, "ooze"), "a salt pouch does not keep the ooze off")
	_expect(float(Biome.effects("bog")["slow"]) < 1.0, "the bog does not drag at the feet")
	_expect(int(Biome.effects("mist")["sight"]) < 0, "the mist does not shorten anybody's sight")
	print("lands: %d on the continent, %d bands checked against what lives there" % [counts.size(), local_bands])


## D126: a laid road runs from the crater through each stop, and a tile it crosses is drawn with it.
func _check_road(world: World) -> void:
	var stops := FirstRoad.stops(world)
	if stops.size() < 2:
		print("road: this world has %d stops, nothing to lay" % stops.size())
		return
	for stop: Vector2i in stops:
		_expect(not FirstRoad.sides(world, stop).is_empty(), "the road does not reach the stop at %s" % stop)
	var crossed := 0
	var between := Route.between(world, stops[0], stops[1])
	for tile: Vector2i in between.slice(1, between.size() - 1):
		var slot := GroundGen.slot(world, tile)
		if str(slot.get("kind", "")) != "ground":
			continue
		if (slot.get("terrain", []) as Array).has("road"):
			crossed += 1
	_expect(crossed > 0, "no open ground between the crater and the city shows the road")
	print("road: %d stops, %d tiles on the way to the city show it underfoot" % [stops.size(), crossed])


## D286: the road keeps a clock. Nothing before `first_after` steps, then something every `every`
## steps in open country, never the same kind twice running, every kind in time; a traveller's words
## come filled in; a band stands ahead of the way the party walks; the clock keeps through a save.
func _check_road_clock() -> void:
	var world := WorldGen.generate(SEED)
	var paced := Roadside.clock()
	var open := Vector2i(-1, -1)
	for y in world.size.y:
		for x in world.size.x:
			var c := Vector2i(x, y)
			if open.x < 0 and world.is_walkable(c) and not Roadside._near_a_site(world, c, int(paced.get("clear_of_sites", 2)) + 4):
				open = c
	_expect(open.x >= 0, "road clock: no open country to walk in")
	if open.x < 0:
		return
	world.steps = int(paced.get("first_after", 6)) - 1
	_expect(Roadside.due(world, open) == "", "road clock: something came before first_after")
	world.steps += 1
	var first := Roadside.due(world, open)
	_expect(first != "", "road clock: nothing came at first_after")
	var seen := { first: true }
	var last := first
	var gaps: Array = []
	for i in 40:
		var wait := Roadside.gap(world)
		var every: Array = paced.get("every", [10, 14])
		gaps.append(wait)
		_expect(wait >= int(every[0]) and wait <= int(every[1]), "road clock: a gap of %d is outside %s" % [wait, every])
		world.steps += wait - 1
		_expect(Roadside.due(world, open) == "", "road clock: something came a step early")
		world.steps += 1
		var kind := Roadside.due(world, open)
		_expect(kind != "" and kind != last, "road clock: '%s' came after '%s'" % [kind, last])
		seen[kind] = true
		last = kind
	for kind: String in paced.get("kinds", {}):
		_expect(seen.has(kind), "road clock: no %s in forty happenings" % kind)
	var site: Site = world.sites[0]
	world.steps += 100
	_expect(Roadside.due(world, site.cell) == "", "road clock: something came on a place's doorstep")
	# A traveller: every brace filled, and one naming a gate puts it on the map.
	for i in 30:
		world.steps += 1
		for line: String in Roadside.traveller(world, open):
			_expect(not line.contains("{"), "road clock: a traveller's line came out unfilled: %s" % line)
	# A band stands ahead of the way the party walks.
	world.player_cell = open
	var before := world.prowlers.size()
	var band := Encounter.band_ahead(world, Vector2i.RIGHT, paced.get("band_ahead", [3, 4]), world.rng)
	_expect(band != null and world.prowlers.size() == before + 1, "road clock: no band stood on the road")
	if band != null:
		_expect(band.cell.x > open.x, "road clock: the band stood behind the party (%s from %s)" % [band.cell, open])
	var back := World.from_dict(JSON.parse_string(JSON.stringify(world.to_dict())))
	_expect(back.happening_at == world.happening_at and back.happening_last == world.happening_last, "road clock: lost in the save")
	print("road clock: first at step %d, then every %s steps; kinds seen %s" % [int(paced.get("first_after", 6)), gaps.slice(0, 8), seen.keys()])


## D128: where one land meets another, the next land's floor runs a few cells in, and no deeper.
func _check_edges(world: World) -> void:
	var band := int(Database.biomes.get("edge_band", 3))
	var seams := 0
	for y in world.size.y:
		for x in world.size.x - 1:
			var tile := Vector2i(x, y)
			var next := tile + Vector2i.RIGHT
			if seams >= 6 or not world.is_walkable(tile) or not world.is_walkable(next):
				continue
			var theirs := str(Biome.data(Biome.at(world, next)).get("ground", {}).get("floor", ""))
			var slot := GroundGen.slot(world, tile)
			var own := str(Biome.data(str(slot.get("land", ""))).get("ground", {}).get("floor", ""))
			if str(slot.get("kind", "")) != "ground" or theirs == own:
				continue
			seams += 1
			var w := int(slot["size"][0])
			var h := int(slot["size"][1])
			var terrain: PackedStringArray = slot["terrain"]
			var near := 0
			var deep := 0
			for i in terrain.size():
				if terrain[i] != theirs:
					continue
				var cx := i % w
				var cy := i / w
				if cx >= w - band:
					near += 1
				elif cx >= band and cx < w - band and cy >= band and cy < h - band:
					deep += 1
			_expect(near > 0, "the %s does not run into the tile at %s from the east" % [theirs, tile])
			_expect(deep == 0, "the %s runs deeper than the band at %s" % [theirs, tile])
			_expect(((slot["patches"] as Array)[0]["layers"] as Array).has("edge_" + theirs),
				"the tile at %s has %s in it with no sheet to draw it" % [tile, theirs])
	_expect(seams > 0, "no two lands meet anywhere on the continent")
	print("edges: %d seams between lands checked" % seams)


## D130: trees stand in groves and never beside the road.
func _check_scenery(world: World) -> void:
	var trees := 0
	var with_company := 0
	var by_road := 0
	for tile: Vector2i in Route.between(world, FirstRoad.stops(world)[0], FirstRoad.stops(world)[1]) if FirstRoad.stops(world).size() >= 2 else []:
		var slot := GroundGen.slot(world, tile)
		if str(slot.get("kind", "")) != "ground":
			continue
		var w := int(slot["size"][0])
		var h := int(slot["size"][1])
		var terrain: PackedStringArray = slot["terrain"]
		var pool: Array = Biome.data(str(slot["land"])).get("props", {}).get("trees", [])
		var cells: Array[Vector2i] = []
		for prop: Dictionary in slot["props"]:
			if pool.has(str(prop.get("art", ""))):
				cells.append(Vector2i(int(prop["cell"][0]), int(prop["cell"][1])))
		for c: Vector2i in cells:
			trees += 1
			for other: Vector2i in cells:
				if other != c and absi(other.x - c.x) <= 3 and absi(other.y - c.y) <= 3:
					with_company += 1
					break
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var n := c + Vector2i(dx, dy)
					if n.x >= 0 and n.y >= 0 and n.x < w and n.y < h and terrain[n.y * w + n.x] == "road":
						by_road += 1
	_expect(trees > 0, "no trees at all along the road to the city")
	_expect(by_road == 0, "%d trees stand hard beside the road" % by_road)
	_expect(float(with_company) >= float(trees) * 0.6, "trees stand alone, not in groves (%d of %d have another near)" % [with_company, trees])
	print("scenery: %d trees along the road, %d in company, %d beside it" % [trees, with_company, by_road])


func _check_round_trip(world: World, hero: Character) -> void:
	var payload: Dictionary = JSON.parse_string(JSON.stringify(world.to_dict()))
	var restored := World.from_dict(payload)
	_expect(restored.world_seed == world.world_seed, "seed lost in the round trip")
	_expect(restored.sites.size() == world.sites.size(), "sites lost in the round trip")
	_expect(restored.tiles == world.tiles, "ground changed in the round trip")
	_expect(restored.trees.size() == world.trees.size(), "generated trees lost in the round trip")

	var hero_payload: Dictionary = JSON.parse_string(JSON.stringify(hero.to_dict()))
	var hero_again := Character.from_dict(hero_payload)
	_expect(hero_again.level == hero.level, "character level lost in the round trip")
	_expect(hero_again.abilities() == hero.abilities(), "character abilities lost in the round trip")
	for ability_id: String in hero_again.abilities():
		_expect(
			not Database.ability(ability_id).is_empty(),
			"generated ability '%s' did not survive the round trip" % ability_id
		)


## A journal for each land (D239): a page opens on first setting foot in a land, its lines cross off
## as they are done, the last turns up the land's trinket, and the trinket does what it says, kept
## in the save.
## The world remembers (D249): somebody who has heard of a deed brings it up once, by name; a place
## that has heard the worst turns the company away; a faction that keeps losing bands holds a grudge;
## and a later world has dreamt what an earlier lead did.
func _check_remembered(world: World) -> void:
	var Remembered := preload("res://src/chronicle/remembered.gd")
	var Talk := preload("res://src/dialogue/talk.gd")
	var saved := { "deeds": world.deeds.duplicate(true), "grudges": world.grudges.duplicate(true),
		"echoes": world.echoes.duplicate(true), "flags": GameState.flags.duplicate(true), "cell": world.player_cell }
	world.deeds = []
	world.grudges = {}
	var here := world.player_cell
	_expect(Remembered.recall(world, "test:watch") == "", "remembered: brought up a deed before there was one")
	Renown.record(world, Renown.GATE_SHUT, here, 4, "the E-rank gate at Testhollow was shut", "", "Testhollow")
	var said := Remembered.recall(world, "test:watch")
	_expect(said.contains("Testhollow"), "remembered: the shut gate was not brought up by name (%s)" % said)
	_expect(Remembered.recall(world, "test:watch") == "", "remembered: the same deed brought up twice")
	_expect(Remembered.recall(world, "test:innkeeper").contains("Testhollow"), "remembered: a second person had not heard")
	_expect(Remembered.aside(world, 0.0).contains("Testhollow"), "remembered: a townsperson never says it")
	_expect(Remembered.aside(world, 1.0) == "", "remembered: a townsperson always says it")
	# Word walks: somebody far off has not heard yet.
	var far := here + Vector2i(30, 0)
	world.player_cell = far
	_expect(Remembered.recall(world, "test:far") == "", "remembered: word of it got thirty tiles in no time")
	world.player_cell = here
	_expect(not Remembered.is_cold(world, here), "remembered: cold after a gate was shut")
	Renown.record(world, Renown.TOWN_RAIDED, here, -7, "Testford was put to the torch", "", "Testford")
	_expect(Remembered.is_cold(world, here), "remembered: not cold where a town was burned")
	var recall := Remembered.recall(world, "test:watch")
	_expect(recall.contains("Testford"), "remembered: the burning was not brought up (%s)" % recall)
	var talk := { "hello": "Hello.", "refuse": Remembered.cold_refusal() }
	var nodes: Dictionary = Talk.build("Wat", talk, false, 0.0, "met:test", recall)
	_expect(nodes.has("door") and nodes.has("recall") and nodes["recall"]["next"] == "door",
		"remembered: a cold place lets the company straight in (%s)" % [nodes.keys()])
	_expect((nodes["door"]["options"] as Array).size() >= 3, "remembered: no way round the cold shoulder")
	_expect(not Talk.build("Wat", { "hello": "Hello." }, false, 0.0, "met:test").has("recall"),
		"remembered: something brought up with nothing to say")
	# A grudge: three bands of the Heart Empire beaten, and none for beasts.
	var legion := ["legion_copper", "legion_copper"]
	_expect(Remembered.faction_of(legion) == "heart_empire", "remembered: legion_copper is not the Heart Empire's")
	_expect(Remembered.on_band_beaten(world, legion) == "" and Remembered.on_band_beaten(world, legion) == "",
		"remembered: a grudge after one band")
	_expect(not Remembered.holds_grudge(world, "heart_empire"), "remembered: a grudge too soon")
	_expect(Remembered.on_band_beaten(world, legion) != "", "remembered: no word of the grudge starting")
	_expect(Remembered.holds_grudge(world, "heart_empire") and Remembered.grudge_sight(world, legion) > 0.0,
		"remembered: the grudge does not sharpen their eyes")
	_expect(Remembered.shout(world, legion, 0) != "There!", "remembered: a band with a grudge just shouts There!")
	var beasts := ["wolf"]
	for i in 5:
		Remembered.on_band_beaten(world, beasts)
	_expect(Remembered.shout(world, beasts, 0) == "There!", "remembered: the wild holds a grudge")
	var round_trip := World.from_dict(world.to_dict())
	_expect(int(round_trip.grudges.get("heart_empire", 0)) == 3, "remembered: grudges are not kept in the save")
	# A later world: somebody here dreamt it, once.
	var kept := Remembered.keep(world)
	_expect(kept.size() == 2 and str(kept[0].get("told", "")).contains("Testford"),
		"remembered: an ending world keeps %s" % [kept])
	world.echoes = { "past": [{ "name": "Pluto", "deeds": kept }] }
	var dreamt := Remembered.dream(world, here, "test:dreamer")
	_expect(dreamt.contains("Pluto"), "remembered: no dream of the earlier lead (%s)" % dreamt)
	Remembered.dream(world, here, "test:dreamer")
	_expect(Remembered.dream(world, here, "test:dreamer") == "", "remembered: the same dream told again")
	_expect(Remembered.dream(world, far, "test:far") == "", "remembered: dreamt thirty tiles away")
	world.deeds = saved["deeds"]
	world.grudges = saved["grudges"]
	world.echoes = saved["echoes"]
	world.player_cell = saved["cell"]
	GameState.flags = saved["flags"]


## Companions whose arcs react (D250): Bellona's opens at the fire once the company has stood on
## floor 5, moves on only for what it asks, takes what the company did before into account, ends
## with what it did on the way, and pays for good; as a lead, hers opens with her chapter one.
func _check_arcs(world: World) -> void:
	var Arcs := preload("res://src/chronicle/arcs.gd")
	for hero_id: String in Database.arcs.get("arcs", {}):
		_expect(not Database.hero(hero_id).is_empty(), "arcs: %s is not one of the sixteen" % hero_id)
		for stage: Dictionary in Arcs.arc(hero_id).get("stages", []):
			var until: Dictionary = stage.get("until", {})
			_expect(str(stage.get("ask", "")) != "" and not until.is_empty(), "arcs: a stage of %s's asks nothing" % hero_id)
			for need: Dictionary in [until, stage.get("skip_if", {})]:
				for key: String in need:
					_expect(key in ["count", "deeds", "ledger", "floor", "flag", "met_count"], "arcs: %s's asks for %s" % [hero_id, key])
				for key: String in need.get("ledger", {}):
					_expect(key in Ledger.KEYS or key in ["places", "one_kind"], "arcs: %s's counts %s" % [hero_id, key])
		var data := Arcs.arc(hero_id)
		for variant: Dictionary in data.get("opened", []) + data.get("finished", []):
			for key: String in variant.get("when", {}):
				_expect(key in ["deed", "met", "with", "fallen", "fallen_count", "flag", "not"], "arcs: %s's says a line when %s" % [hero_id, key])
		_expect(not data.get("finished", []).is_empty() and not (data["finished"][-1] as Dictionary).has("when"),
			"arcs: %s's has no ending for when nothing else holds" % hero_id)
	# Will kept Bellona's shape and the other fifteen were written the same way (D256).
	_expect(Database.arcs.get("arcs", {}).size() == 16, "arcs: %d of the sixteen have one" % Database.arcs.get("arcs", {}).size())
	var saved := { "deeds": world.deeds.duplicate(true), "arcs": world.arcs.duplicate(true), "floor": world.tower_floor,
		"wanderers": world.wanderers.duplicate(true), "steps": world.steps, "flags": GameState.flags.duplicate(true) }
	world.deeds = []
	world.arcs = {}
	world.wanderers = []
	var roster := Company.found("juno", ["bellona"])
	var juno := roster.player()
	var bellona: Character = null
	for character: Character in roster.characters:
		if character.template_id == "bellona":
			bellona = character
	world.tower_floor = 0
	_expect(Arcs.at_the_fire(world, roster, juno, bellona).is_empty(), "arcs: Bellona's opened before floor 5")
	world.tower_floor = 5
	var opened := Arcs.at_the_fire(world, roster, juno, bellona)
	_expect(not opened.is_empty() and str(opened[0].get("speaker", "")) == bellona.display_name,
		"arcs: Bellona's did not open at the fire (%s)" % [opened])
	_expect(Arcs.at_the_fire(world, roster, juno, bellona).is_empty(), "arcs: a stage moved on with nothing done")
	var pages := Arcs.pages(world)
	_expect(pages.size() == 1 and (pages[0]["entries"] as Array).size() == 1 and not pages[0]["entries"][0]["done"],
		"arcs: the journal shows %s" % [pages])
	world.steps += 1
	Renown.record(world, "thread", world.player_cell, 3, "pulled somebody off the road at Test Cross", "pulled somebody off the road at Test Cross")
	_expect(Arcs.pages(world)[0]["entries"][0]["done"], "arcs: the journal does not tick a stage done")
	_expect(not Arcs.at_the_fire(world, roster, juno, bellona).is_empty(), "arcs: nothing said when the road was given its twenty")
	_expect(int(world.arcs["bellona"]["stage"]) == 1, "arcs: still on the first stage")
	var guard := bellona.defense()
	world.steps += 1
	Renown.record(world, Renown.GATE_SHUT, world.player_cell, 2, "the E-rank gate at Test was shut", "", "Test")
	var ended := Arcs.at_the_fire(world, roster, juno, bellona)
	_expect(not ended.is_empty() and bool(world.arcs["bellona"]["done"]), "arcs: Bellona's did not finish")
	_expect(bellona.defense() == guard + 2, "arcs: the reward did not take (%d, was %d)" % [bellona.defense(), guard])
	_expect(int(Character.from_dict(bellona.to_dict()).marks.get("defense", 0)) == 2, "arcs: the reward is not kept in the save")
	_expect(Arcs.at_the_fire(world, roster, juno, bellona).is_empty(), "arcs: said again after it ended")
	_expect(int(World.from_dict(world.to_dict()).arcs.get("bellona", {}).get("stage", 0)) == 2, "arcs: not kept in the save")
	# What the company did before: a road already given its twenty is done at once, and Ultor met
	# changes how it ends.
	world.arcs = {}
	world.wanderers = [{ "id": "ultor", "met": 1, "joined": false }]
	world.steps += 1
	Arcs.at_the_fire(world, roster, juno, bellona)
	_expect(int(world.arcs["bellona"]["stage"]) == 1, "arcs: the twenty already given was asked for again")
	world.steps += 1
	Renown.record(world, Renown.GATE_SHUT, world.player_cell, 2, "the E-rank gate at Test was shut", "", "Test")
	var with_ultor := Arcs.at_the_fire(world, roster, juno, bellona)
	_expect(with_ultor.any(func(l: Dictionary) -> bool: return str(l.get("text", "")).contains("Ultor")),
		"arcs: meeting Ultor changed nothing (%s)" % [with_ultor])
	# What else a stage can ask (D256): Pluto's ten of one kind count only what is put down after it
	# opened, and the floor after; Cato's people met; Saturn's house, a flag.
	world.arcs = {}
	var saved_ledger: Dictionary = GameState.ledger.duplicate(true)
	GameState.ledger = Ledger.fresh()
	for i in 4:
		Ledger.record_kill(GameState.ledger, "slime")
	var climbed := Company.found("juno", ["pluto", "cato", "saturn"])
	var pluto: Character = climbed.characters[1]
	var cato: Character = climbed.characters[2]
	var saturn: Character = climbed.characters[3]
	world.tower_floor = 5
	_expect(not Arcs.at_the_fire(world, climbed, juno, pluto).is_empty(), "arcs: Pluto's did not open")
	for i in 9:
		Ledger.record_kill(GameState.ledger, "slime")
	_expect(Arcs.at_the_fire(world, climbed, juno, pluto).is_empty(), "arcs: Pluto's counted what was put down before it opened")
	Ledger.record_kill(GameState.ledger, "slime")
	_expect(not Arcs.at_the_fire(world, climbed, juno, pluto).is_empty() and int(world.arcs["pluto"]["stage"]) == 1,
		"arcs: Pluto's ten of one kind did not count")
	_expect(Arcs.at_the_fire(world, climbed, juno, pluto).is_empty(), "arcs: Pluto's floor 7 done on floor 5")
	world.tower_floor = 7
	var counted := Arcs.at_the_fire(world, climbed, juno, pluto)
	_expect(bool(world.arcs["pluto"]["done"]) and pluto.marks.get("attack", 0) == 1, "arcs: Pluto's did not finish on floor 7 (%s)" % [counted])
	Arcs.at_the_fire(world, climbed, juno, cato)
	GameState.ledger["errands_done"] = 2
	Arcs.at_the_fire(world, climbed, juno, cato)
	world.wanderers = [{ "id": "ultor", "met": 1, "joined": false }]
	_expect(Arcs.at_the_fire(world, climbed, juno, cato).is_empty(), "arcs: Cato's two met with one met")
	world.wanderers.append({ "id": "iris", "met": 1, "joined": false })
	_expect(not Arcs.at_the_fire(world, climbed, juno, cato).is_empty() and bool(world.arcs["cato"]["done"]), "arcs: Cato's did not finish with two met")
	Arcs.at_the_fire(world, climbed, juno, saturn)
	Ledger.add(GameState.ledger, "recruited")
	Arcs.at_the_fire(world, climbed, juno, saturn)
	_expect(Arcs.at_the_fire(world, climbed, juno, saturn).is_empty(), "arcs: Saturn's house done with no house")
	GameState.set_flag("home:house")
	_expect(not Arcs.at_the_fire(world, climbed, juno, saturn).is_empty() and bool(world.arcs["saturn"]["done"]), "arcs: Saturn's did not finish with the house")
	GameState.ledger = saved_ledger
	# As the lead: hers opens with her chapter one, said to whoever sits with her (below floor 5,
	# so the one with her does not open theirs first).
	world.arcs = {}
	world.tower_floor = 0
	var led := Company.found("bellona", ["juno"])
	var her := led.player()
	var other: Character = led.characters[1]
	_expect(Arcs.at_the_fire(world, led, her, other).is_empty(), "arcs: the lead's opened before her chapter one")
	GameState.set_flag("memory:bellona_1")
	var hers := Arcs.at_the_fire(world, led, her, other)
	_expect(not hers.is_empty() and str(hers[0].get("speaker", "")) == her.display_name, "arcs: the lead's did not open with her chapter one")
	world.deeds = saved["deeds"]
	world.arcs = saved["arcs"]
	world.tower_floor = saved["floor"]
	world.wanderers = saved["wanderers"]
	world.steps = saved["steps"]
	GameState.flags = saved["flags"]


func _check_land_journals(world: World) -> void:
	var LandJournals := preload("res://src/chronicle/land_journals.gd")
	var trinkets: Dictionary = Database.land_journals.get("trinkets", {})
	for land: String in Database.biomes.get("biomes", {}):
		_expect(trinkets.has(land), "land journals: %s has no trinket" % land)
	for land: String in trinkets:
		_expect(LandJournals.describe(trinkets[land]) != "", "land journals: the %s trinket does nothing" % land)
	var saved_lands := world.lands.duplicate(true)
	world.lands = {}
	# Every walkable tile of one land, and that land.
	var land := ""
	var cells: Array[Vector2i] = []
	for y in world.size.y:
		for x in world.size.x:
			var cell := Vector2i(x, y)
			var here := LandJournals.land_at(world, cell)
			if here == "" or not world.is_walkable(cell) or world.site_at(cell) != null:
				continue
			if land == "":
				land = here
			if here == land:
				cells.append(cell)
	_expect(land != "" and cells.size() >= 5, "land journals: no land to walk")
	var said := LandJournals.on_arrive(world, cells[0])
	_expect(not said.is_empty() and str(said[0]).contains(LandJournals.heading(land)), "land journals: no page opened (%s)" % [said])
	_expect(LandJournals.on_arrive(world, cells[0]).is_empty(), "land journals: the same page opened twice")
	var needs: Dictionary = LandJournals.page(world, land).get("needs", {})
	_expect(needs.has("walk") and needs.has("landmark") and needs.has("bands"), "land journals: %s's page asks only %s" % [land, needs])
	_expect(LandJournals.carried(world).is_empty(), "land journals: a trinket before anything was done")
	for cell in cells.slice(1, int(needs.get("walk", 1))):
		LandJournals.on_arrive(world, cell)
	for i in int(needs.get("bands", 0)):
		LandJournals.on_band_beaten(world, cells[0])
	if needs.has("place"):
		for site: Site in world.sites:
			if site.kind != Site.GATE and LandJournals.land_at(world, site.cell) == land:
				LandJournals.on_arrive(world, site.cell)
				break
	if needs.has("gate"):
		for site: Site in world.sites:
			if site.kind == Site.GATE and LandJournals.land_at(world, site.cell) == land:
				LandJournals.on_gate_shut(world, site)
				break
	_expect(LandJournals.carried(world).is_empty(), "land journals: the trinket came before the last line")
	var last := LandJournals.on_landmark(world, cells[0])
	_expect(LandJournals.carried(world).size() == 1 and LandJournals.carried(world)[0] == land, "land journals: finishing %s's page gave no trinket (%s)" % [land, LandJournals.page(world, land)])
	var trinket: Dictionary = trinkets.get(land, {})
	_expect(not last.is_empty() and str(last.back()).contains(str(trinket.get("name", "?"))), "land journals: the trinket was not named (%s)" % [last])
	_expect(LandJournals.on_landmark(world, cells[0]).is_empty(), "land journals: a finished page said more")
	_expect(World.from_dict(world.to_dict()).to_dict()["lands"] == world.to_dict()["lands"], "land journals: the pages were lost in the save")
	# What every kind of trinket does, carried at once.
	for each: String in trinkets:
		world.lands[each] = { "needs": {}, "got": {}, "walked": [], "stood": [], "done": true }
	_expect(LandJournals.wades(world) and LandJournals.spares(world, "cold") and LandJournals.spares(world, "ooze"),
		"land journals: no wading or hazard proofs carried")
	_expect(LandJournals.effect(world, "stride") <= float(Database.land_journals.get("stride_most", 1.0)) + 0.001,
		"land journals: walking speed past its most")
	var held_world: World = GameState.world
	GameState.world = world
	var hero := Character.create("atlas")
	var carrying := Unit.from_character(hero, Unit.Team.PLAYER, Vector2i.ZERO)
	var all_lands := world.lands
	world.lands = {}
	var bare := Unit.from_character(hero, Unit.Team.PLAYER, Vector2i.ZERO)
	world.lands = all_lands
	_expect(carrying.attack > bare.attack and carrying.defense > bare.defense and carrying.max_hp > bare.max_hp,
		"land journals: the trinkets did nothing in a fight (attack %d/%d, guard %d/%d, health %d/%d)" % [
			carrying.attack, bare.attack, carrying.defense, bare.defense, carrying.max_hp, bare.max_hp])
	carrying.free()
	bare.free()
	# A pool on the ground of one of the land's tiles: walked round without the stilts, through with them.
	var waded := false
	for cell in cells.slice(0, 40):
		var land_map = (preload("res://src/area/land.gd")).around(world, cell, 0)
		var rect: Rect2i = land_map.slot_rect(cell)
		var pool := Vector2i(-1, -1)
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var t: String = land_map.terrain_at(Vector2i(x, y))
				if pool.x < 0 and (t == "water" or t.ends_with("_liquid")) and land_map.building_at(Vector2i(x, y)).is_empty():
					pool = Vector2i(x, y)
		if pool.x < 0:
			continue
		_expect(not land_map.is_walkable(pool), "land journals: a pool walked without the stilts")
		land_map.wading = true
		_expect(land_map.is_walkable(pool), "land journals: the stilts did not wade the pool at %s" % pool)
		waded = true
		break
	_expect(waded, "land journals: no pool found to wade")
	GameState.world = held_world
	world.lands = saved_lands
	print("land journals: %s's page (%s) gave the %s" % [land, needs, trinket.get("name", "")])


func _expect(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)
