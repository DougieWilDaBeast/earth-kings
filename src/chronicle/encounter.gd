class_name Encounter
extends RefCounted
## What finds you while you walk, and what waits behind a gate.
##
## Danger is a property of *place*: near an open gate the wild is thick with
## things that came out of it, and near a hearth it goes quiet.

const WILD := "wild"
const GATE := "gate"
const TOWER := "tower"

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
		var guardian := Faction.champion(faction)
		enemies = _pick(pool, 2, level, rng)
		enemies.append({ "unit": guardian, "level": level + 2 })
		title = "%s keeps the far side of %s." % [
			Database.unit_template(guardian).get("display_name", "Something"), site.display_name
		]
	else:
		enemies = _pick(pool, clampi(2 + Site.rank_index(site.rank) / 2, 2, 4), level, rng)
		title = "%s, deeper in." % site.display_name

	return _build(world, site.cell, GATE, enemies, rng, title)


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


## The fight that starts when a band finally sees you.
static func for_band(world: World, band: Prowler, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	var level := _party_level(party) + _danger_at(world, band.cell)
	var enemies: Array = []
	for unit_id: String in band.pack:
		enemies.append({"unit": unit_id, "level": maxi(1, level + rng.randi_range(-1, 1))})
	return _build(world, band.cell, WILD, enemies, rng, "%s has seen you." % band.label())


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
	var pool := _pool_on(faction, terrain, _danger_at(world, cell) * 3 + 1)
	var pack: Array = []
	for i in clampi(1 + _danger_at(world, cell), 1, 4):
		pack.append(pool[rng.randi() % pool.size()])
	var band := Prowler.create(cell, pack, int(Database.encounters.get("sight", Prowler.BASE_SIGHT)))
	band.faction = faction
	return band


## One floor of the Tower. Floors are 1-based and never scale down to meet you.
static func for_tower(world: World, site: Site, floor_number: int, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	var pool: Array = Database.encounters.get("tower", ["goblin"])
	var level := 2 + floor_number * 2
	var count := clampi(2 + floor_number / 3, 2, 4)
	return _build(
		world, site.cell, TOWER, _pick(pool, count, level, rng), rng,
		"Floor %d." % floor_number
	)


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
	return out


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
