class_name Encounter
extends RefCounted
## What finds you while you walk, and what waits behind a gate.
##
## Danger is a property of *place*: near an open gate the wild is thick with
## things that came out of it, and near a hearth it goes quiet.

const WILD := "wild"
const GATE := "gate"
const TOWER := "tower"

const Chapters := preload("res://src/chronicle/chapters.gd")
const Biome := preload("res://src/chronicle/biome.gd")
const FirstRoad := preload("res://src/area/first_road.gd")

## No band ever appears within this many tiles of the party. They are found,
## not sprung.
const SPAWN_CLEARANCE := 10
## Give up looking for somewhere to put a band after this many tries.
const SPAWN_ATTEMPTS := 600
## How far off the opening band is put: near enough that the first fight is a
## short walk, far enough that it is still walked into rather than sprung.
const OPENING_NEAR := 4
const OPENING_FAR := 6


## Odds of meeting something on this tile, 0.0–1.0.
static func chance_at(world: World, cell: Vector2i) -> float:
	var rules := Database.encounters
	var chance := float(rules.get("base_chance", 0.07))

	var gate_range := int(rules.get("gate_range", 8))
	var to_gate := world.distance_to_open_gate(cell)
	if to_gate <= gate_range:
		var closeness := 1.0 - float(to_gate) / float(gate_range)
		chance += float(rules.get("gate_pressure", 0.3)) * closeness

	# A broken gate is not spilling any more, it is pouring.
	for broken in world.broken_gates():
		if Pathfinder.distance(cell, broken.cell) <= gate_range * 2:
			chance += float(Database.world_rules.get("gate", {}).get("break_danger", 0.25))
			break

	if world.distance_to_haven(cell) <= int(rules.get("haven_range", 4)):
		chance -= float(rules.get("haven_relief", 0.06))

	chance *= Difficulty.dial("encounter_chance")
	return clampf(chance, float(rules.get("min_chance", 0.01)), float(rules.get("max_chance", 0.45)))


## Roll for a wild encounter. Returns an empty dict when the road stays quiet.
static func roll(world: World, cell: Vector2i, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	if rng.randf() >= chance_at(world, cell):
		return {}
	return wild(world, cell, party, rng)


static func wild(world: World, cell: Vector2i, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	var level := _party_level(party)
	var danger := _danger_at(world, cell)
	var count := clampi(1 + danger, 1, 4)
	var terrain := world.terrain_id_at(cell)

	# Things that came out of a broken gate are not local wildlife.
	var near_break := world.broken_gates().any(
		func(s: Site) -> bool: return Pathfinder.distance(cell, s.cell) <= 16
	)
	if near_break:
		level += int(Database.world_rules.get("gate", {}).get("break_level_bonus", 3))
		count = clampi(count + 1, 1, 4)

	var faction := Faction.pick_on(terrain, rng)
	var pool := _pool_on(faction, terrain, level)
	var title := "%s of %s are on the %s." % [
		"Something" if count < 2 else "A band",
		Faction.display_name(faction),
		world.terrain_at(cell).get("name", "open").to_lower(),
	]
	return _build(world, cell, WILD, _pick(pool, count, level, rng), rng, title)


## Who a piece of ground fields. The faction that walks it comes first; the old
## terrain table is the floor under it, so ground nobody claims still fights.
static func _pool_on(faction: String, terrain: String, level: int) -> Array:
	var pool := Faction.pool(faction, level)
	if pool.is_empty():
		pool = Database.encounters.get("wild", {}).get(terrain, ["wolf"])
	return pool


## One floor of a gate delve. [param depth] is 0-based; the last is the guardian.
static func for_gate(world: World, site: Site, depth: int, final: bool, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	var level := maxi(_party_level(party), site.expected_level()) + depth
	# A gate belongs to whoever came through it (see [WorldGen]).
	var faction: String = site.data.get("faction", Faction.FALLBACK)
	var pool := _pool_on(faction, world.terrain_id_at(site.cell), level)

	var enemies: Array
	var title: String
	if final:
		# A lesser gate is kept by the strongest its floor fields, not the faction's champion ([D211]).
		var guardian := Faction.champion(faction)
		if Site.rank_index(site.rank) < Site.rank_index(str(Database.encounters.get("champion_from", "E"))):
			guardian = str(pool[-1])
		enemies = _pick(pool, 2, level, rng)
		# The keeper takes the setting's level dial like its floor ([D211]): on the First Hour a lone
		# lead at level 2 met the wild's Ogre at 4 at the first gate.
		enemies.append({ "unit": guardian, "level": Difficulty.levelled(level + 2), "boss": true })
		title = "%s keeps the far side of %s." % [
			Database.unit_template(guardian).get("display_name", "Something"), site.display_name
		]
	else:
		enemies = _pick(pool, clampi(2 + Site.rank_index(site.rank) / 2, 2, 4), level, rng)
		title = "%s, floor %d (%s)." % [
			site.display_name, depth + 1, Faction.display_name(faction)
		]

	var meeting := _build(world, site.cell, GATE, enemies, rng, title)
	meeting["objective"] = site.floor_objective()
	if meeting["objective"] == Site.OBJECTIVE_HEART:
		BattleMapGen.mark_heart(meeting["map"])
	return meeting


## The people holding one of yours. They are not a gate garrison, they are a
## band that took a prisoner and expected to be paid for it.
static func for_captors(world: World, site: Site, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	var pool: Array = Database.encounters.get("captors", ["brigand", "brigand_archer"])
	var level := _party_level(party) + 1
	return _build(
		world, site.cell if site != null else world.player_cell, GATE,
		_pick(pool, 3, level, rng), rng, "The ones holding your friend."
	)


## Whoever is currently sacking a town. Beating them lifts the siege.
static func for_siege(world: World, site: Site, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	var pool: Array = Database.encounters.get("siege", ["brigand", "goblin"])
	var level := _party_level(party) + 1
	return _build(
		world, site.cell, WILD, _pick(pool, 4, level, rng), rng,
		"They are already inside %s." % site.display_name
	)


## The town turning out to defend itself, because you are the one raiding it.
static func for_town_guard(world: World, site: Site, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	var pool: Array = Database.encounters.get("guard", ["brigand", "village_idiot"])
	var level := _party_level(party) + (2 if site.kind == Site.KEEP else 0)
	var count := 4 if site.kind == Site.KEEP else 3
	return _build(
		world, site.cell, WILD, _pick(pool, count, level, rng), rng,
		"%s turns out to defend itself." % site.display_name
	)


# --- bands in the open --------------------------------------------------------


## Top the country back up to its share of wandering bands. They only ever
## appear out of sight, in country the danger rating says can hold them.
static func restock(world: World, rng: RandomNumberGenerator) -> void:
	var target := int(Database.encounters.get("bands", 12))
	var tries := 0
	while world.prowlers.size() < target and tries < SPAWN_ATTEMPTS:
		tries += 1
		var cell := Vector2i(rng.randi() % world.size.x, rng.randi() % world.size.y)
		if not _can_camp_at(world, cell):
			continue
		# Thick country takes bands, quiet country mostly refuses them.
		if rng.randf() > chance_at(world, cell) / float(Database.encounters.get("max_chance", 0.45)):
			continue
		world.prowlers.append(_band_at(world, cell, rng))
	_restock_the_road(world, rng)


## The First Hour's road is walked by every new climber, and the danger rating leaves it empty: it
## runs past the city and the havens, and quiet country refuses bands. So a few always camp near it
## ([D215], play-test 4: "I still haven't encountered a single person I can fight"): `near_the_road`
## in `encounters.json`, `bands` of them `from` to `to` tiles off the road (never on it: the Watch
## keeps the cobbles) and at least `clear_of_places` tiles from any place, some of them people
## (`people_share` of `people`) rather than what lives there.
static func _restock_the_road(world: World, rng: RandomNumberGenerator) -> void:
	var rules: Dictionary = Database.encounters.get("near_the_road", {})
	var wanted := int(rules.get("bands", 0))
	if wanted <= 0:
		return
	var road := FirstRoad.tiles(world)
	if road.is_empty():
		return
	var near := int(rules.get("from", 2))
	var far := maxi(near, int(rules.get("to", 4)))
	var off_road := func(cell: Vector2i) -> int:
		var best := 1 << 20
		for tile: Vector2i in road:
			best = mini(best, Pathfinder.distance(cell, tile))
		return best
	var there := 0
	for band: Prowler in world.prowlers:
		var apart: int = off_road.call(band.cell)
		if apart >= near and apart <= far:
			there += 1
	var people: Array = rules.get("people", [])
	var clear := int(rules.get("clear_of_places", 4))
	var tries := 0
	while there < wanted and tries < SPAWN_ATTEMPTS:
		tries += 1
		var on: Vector2i = road[rng.randi() % road.size()]
		var cell := on + Vector2i(rng.randi_range(-far, far), rng.randi_range(-far, far))
		if not world.in_bounds(cell) or not _can_camp_at(world, cell) \
				or world.prowlers.any(func(b: Prowler) -> bool: return b.cell == cell):
			continue
		var apart: int = off_road.call(cell)
		if apart < near or apart > far:
			continue
		# On the open stretches between places, not at a town's gate or the Tower's foot, where the
		# way in has to stay walkable (Auto keeps out of the red).
		if world.sites.any(func(site: Site) -> bool: return Pathfinder.distance(cell, site.cell) < clear):
			continue
		if not people.is_empty() and rng.randf() < float(rules.get("people_share", 0.5)):
			var pack: Array = []
			for i in rng.randi_range(2, 3):
				pack.append(str(people[rng.randi() % people.size()]))
			world.prowlers.append(Prowler.create(cell, pack))
		else:
			world.prowlers.append(_band_at(world, cell, rng))
		there += 1


## The fight that starts when a band finally sees you, all of it, as it was seen. Every road fight
## is a band, so the setting's level dial applies here as it does in [method _pick] ([D211]):
## before, a fresh lead met bands at their full level on the First Hour.
static func for_band(world: World, band: Prowler, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	var level := _party_level(party) + _danger_at(world, band.cell)
	var enemies: Array = []
	for unit_id: String in band.pack:
		enemies.append({"unit": unit_id, "level": Difficulty.levelled(level + rng.randi_range(-1, 1))})
	Nemesis.inject_survivor(world, enemies)
	return _build(world, band.cell, WILD, enemies, rng, "%s %s seen you." % [band.label(), "has" if band.pack.size() <= 1 else "have"])


## A run that opens on an empty country teaches nothing about the country. One
## band is put down inside the normal clearance so the road out has something
## on it from the first minute.
static func first_blood(world: World, rng: RandomNumberGenerator) -> void:
	var candidates: Array[Vector2i] = []
	for y in range(-OPENING_FAR, OPENING_FAR + 1):
		for x in range(-OPENING_FAR, OPENING_FAR + 1):
			var cell := world.player_cell + Vector2i(x, y)
			var reach := Pathfinder.distance(cell, world.player_cell)
			if reach < OPENING_NEAR or reach > OPENING_FAR:
				continue
			if not world.is_walkable(cell) or world.site_at(cell) != null:
				continue
			if world.distance_to_haven(cell) <= 2:
				continue
			candidates.append(cell)
	if candidates.is_empty():
		return
	world.prowlers.append(_band_at(world, candidates[rng.randi() % candidates.size()], rng))


static func _can_camp_at(world: World, cell: Vector2i) -> bool:
	if not world.is_walkable(cell) or world.site_at(cell) != null:
		return false
	if Pathfinder.distance(cell, world.player_cell) < SPAWN_CLEARANCE:
		return false
	# Nobody camps on a doorstep.
	return world.distance_to_haven(cell) > 2


static func _band_at(world: World, cell: Vector2i, rng: RandomNumberGenerator) -> Prowler:
	var terrain := world.terrain_id_at(cell)
	var faction := Faction.pick_on(terrain, rng)
	var level := _danger_at(world, cell) * 3 + 1
	var pool := _pool_on(faction, terrain, level)
	# Most bands are whatever lives in that land: ice wolves on the snow, slimes
	# in the fen (`doug-md`, 2026-10-13). Decided from the cell, not the dice, so
	# the run's dice fall the same as before.
	var locals := _land_foes(world, cell)
	if not locals.is_empty():
		pool = locals
	var pack: Array = []
	# The setting's count dial is taken when the band is made, so it fights as many as are seen ([D211]).
	for i in clampi(Difficulty.counted(1 + _danger_at(world, cell)), 1, 4):
		pack.append(pool[rng.randi() % pool.size()])
	# Seen as what it is: a goblin band shows its hobgoblin before the fight (D262).
	pack = Tiers.deal_pack(pack, level, rng)
	var band := Prowler.create(cell, pack, int(Database.encounters.get("sight", Prowler.BASE_SIGHT)))
	band.faction = faction
	return band


## Who camps in the land at [param cell] (`data/biomes.json` → `foes`), or none
## when this band is one of the faction's own instead.
static func _land_foes(world: World, cell: Vector2i) -> Array:
	var foes: Array = Biome.data(Biome.at(world, cell)).get("foes", [])
	if foes.is_empty():
		return []
	var share := float(Database.biomes.get("land_foe_share", 0.7))
	var roll := float(absi(hash([world.world_seed, cell.x, cell.y, "foes"])) % 1000) / 1000.0
	if roll >= share:
		return []
	# The great beasts wait for the party to grow (`foe_levels`, [D211]).
	var level := party_level(GameState.party_characters()) if GameState.roster != null else 1
	var gates: Dictionary = Database.biomes.get("foe_levels", {})
	var ready := foes.filter(func(id: String) -> bool: return int(gates.get(id, 0)) <= level)
	return ready


## One floor of the Tower. Floors are 1-based and never scale down to meet you; they do scale up
## ([D189]): never below the party's own level, and more of them for a bigger party, so a company
## of five that has outgrown the floor's number still has a fight on its hands (play-test 4).
## Each stretch of floors fields one faction cohort (`world_rules.tower.cohorts`)
## rather than random mobs.
static func for_tower(world: World, site: Site, floor_number: int, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	var rules: Dictionary = Database.world_rules.get("tower", {})
	var level := roundi(float(rules.get("level_base", 2)) + float(floor_number) * float(rules.get("levels_per_floor", 0.3)))
	if bool(rules.get("meet_the_party", false)) and not party.is_empty():
		level = maxi(level, party_level(party))
	var foes_min := int(rules.get("foes_min", 2))
	var crowd := maxi(0, party.size() - int(rules.get("foes_per_member_past", party.size())))
	var count := clampi(
		foes_min + (Chapters.chapter_of(floor_number) - 1) / maxi(1, int(rules.get("chapters_per_extra_foe", 4))) + crowd,
		foes_min, int(rules.get("foes_max", 4))
	)

	var faction_tier := _tower_cohort(rules.get("cohorts", []), floor_number)
	var pool := Faction.pool(faction_tier, level)
	if pool.is_empty():
		pool = Database.encounters.get("tower", ["goblin"])

	var bite := upper_bite(floor_number)
	if floor_number >= world.tower_floors():
		var apex_bosses: Array = rules.get("apex", ["dirte"])
		var boss_id: String = apex_bosses[rng.randi() % apex_bosses.size()]
		var enemies: Array = [{ "unit": boss_id, "level": Difficulty.levelled(level + 2), "boss": true }]
		var minions: Array = _pick(pool, 3, level, rng)
		enemies.append_array(minions)
		_bite(enemies, bite)
		return _build(
			world, site.cell, TOWER, enemies, rng,
			"The Spire Apex — Floor %d (Final Battle)" % floor_number
		)

	var enemies := _pick(pool, count, level, rng)
	_bite(enemies, bite)
	var faction_name := Faction.display_name(faction_tier)
	return _build(
		world, site.cell, TOWER, enemies, rng,
		"Floor %d — Cohort of %s." % [floor_number, faction_name]
	)


## The faction holding [param floor_number]: the first cohort whose `to` reaches it,
## rotating through its factions floor by floor. Past the last, the last holds.
static func _tower_cohort(cohorts: Array, floor_number: int) -> String:
	if cohorts.is_empty():
		return Faction.FALLBACK
	var start := 1
	for cohort: Dictionary in cohorts:
		var factions: Array = cohort.get("factions", [])
		if floor_number <= int(cohort.get("to", 0)) and not factions.is_empty():
			return str(factions[(floor_number - start) % factions.size()])
		start = int(cohort.get("to", 0)) + 1
	var last: Array = cohorts[-1].get("factions", [Faction.FALLBACK])
	return str(last[maxi(0, floor_number - start) % last.size()])


## A fight somebody else started, that you have chosen to join (see [Roadside]).
## The enemies come from the scene rather than from the country, so the same
## ambush reads the same wherever you find it.
static func for_roadside(
	world: World, cell: Vector2i, enemies: Array,
	rng: RandomNumberGenerator, title: String
) -> Dictionary:
	var counted: Array = []
	for entry: Dictionary in enemies:
		counted.append({
			"unit": entry["unit"],
			"level": Difficulty.levelled(int(entry["level"])),
		})
	return _build(world, cell, WILD, counted, rng, title)


# --- internals ----------------------------------------------------------------


static func _build(
	world: World, cell: Vector2i, kind: String, enemies: Array,
	rng: RandomNumberGenerator, title: String
) -> Dictionary:
	return {
		"kind": kind,
		"title": title,
		"enemies": enemies,
		"map": BattleMapGen.generate(world, cell, enemies, rng),
	}


static func _pick(pool: Array, count: int, level: int, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	# Every fight in the game is built here, so the difficulty dials only have to
	# be applied once (see [Difficulty]).
	for i in Difficulty.counted(count):
		out.append({
			"unit": pool[rng.randi() % pool.size()],
			"level": Difficulty.levelled(level + rng.randi_range(-1, 1)),
		})
	# A family's plain kind comes as one of its five tiers (D262).
	Tiers.deal(out, level, rng)
	return out


## How much harder than their level the foes of [param floor_number] hit (D222, `doug-md` on his
## play log of 2026-10-17: the upper floors were long enough but nobody came out of them hurt).
## 1.0 on the walked floors; from `world_rules.tower.upper_bite.from_floor` it starts at `base` and
## climbs `per_floor`, to `most` at most.
static func upper_bite(floor_number: int) -> float:
	var rules: Dictionary = Database.world_rules.get("tower", {}).get("upper_bite", {})
	var from := int(rules.get("from_floor", 0))
	if rules.is_empty() or from <= 0 or floor_number < from:
		return 1.0
	var bite := float(rules.get("base", 1.0)) + float(rules.get("per_floor", 0.0)) * float(floor_number - from)
	return minf(bite, float(rules.get("most", bite)))


static func _bite(enemies: Array, bite: float) -> void:
	if is_equal_approx(bite, 1.0):
		return
	for entry: Dictionary in enemies:
		entry["bite"] = bite


static func party_level(party: Array) -> int:
	if party.is_empty():
		return 1
	var total := 0
	for character: Character in party:
		total += character.level
	return maxi(1, total / party.size())


static func _party_level(party: Array) -> int:
	return party_level(party)


## 0 in safe country, rising the closer an open gate gets.
static func _danger_at(world: World, cell: Vector2i) -> int:
	var to_gate := world.distance_to_open_gate(cell)
	if to_gate > 12:
		return 0
	if to_gate > 6:
		return 1
	return 2
