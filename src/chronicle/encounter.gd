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
const SPAWN_ATTEMPTS := 40


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

	return clampf(chance, float(rules.get("min_chance", 0.01)), float(rules.get("max_chance", 0.45)))


## Roll for a wild encounter. Returns an empty dict when the road stays quiet.
static func roll(world: World, cell: Vector2i, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	if rng.randf() >= chance_at(world, cell):
		return {}
	return wild(world, cell, party, rng)


static func wild(world: World, cell: Vector2i, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	var pool: Array = Database.encounters.get("wild", {}).get(world.terrain_id_at(cell), ["wolf"])
	var level := _party_level(party)
	var danger := _danger_at(world, cell)
	var count := clampi(1 + danger, 1, 4)

	# Things that came out of a broken gate are not local wildlife.
	var near_break := world.broken_gates().any(
		func(s: Site) -> bool: return Pathfinder.distance(cell, s.cell) <= 16
	)
	if near_break:
		level += int(Database.world_rules.get("gate", {}).get("break_level_bonus", 3))
		count = clampi(count + 1, 1, 4)

	return _build(world, cell, WILD, _pick(pool, count, level, rng), rng,
		"Something moves in the %s." % world.terrain_at(cell).get("name", "open").to_lower())


## One floor of a gate delve. [param depth] is 0-based; the last is the guardian.
static func for_gate(world: World, site: Site, depth: int, final: bool, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	var rules := Database.encounters
	var pool: Array = rules.get("gate", {}).get(site.rank, ["goblin"])
	var level := maxi(_party_level(party), site.expected_level()) + depth

	var enemies: Array
	var title: String
	if final:
		var guardian: String = rules.get("guardian", {}).get(site.rank, "brigand_chief")
		enemies = _pick(pool, 2, level, rng)
		enemies.append({ "unit": guardian, "level": level + 2 })
		title = "The guardian of %s is waiting." % site.display_name
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


static func _can_camp_at(world: World, cell: Vector2i) -> bool:
	if not world.is_walkable(cell) or world.site_at(cell) != null:
		return false
	if Pathfinder.distance(cell, world.player_cell) < SPAWN_CLEARANCE:
		return false
	# Nobody camps on a doorstep.
	return world.distance_to_haven(cell) > 2


static func _band_at(world: World, cell: Vector2i, rng: RandomNumberGenerator) -> Prowler:
	var pool: Array = Database.encounters.get("wild", {}).get(world.terrain_id_at(cell), ["wolf"])
	var pack: Array = []
	for i in clampi(1 + _danger_at(world, cell), 1, 4):
		pack.append(pool[rng.randi() % pool.size()])
	return Prowler.create(cell, pack, int(Database.encounters.get("sight", Prowler.BASE_SIGHT)))


## One floor of the Tower. Floors are 1-based and never scale down to meet you.
static func for_tower(world: World, site: Site, floor_number: int, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	var pool: Array = Database.encounters.get("tower", ["goblin"])
	var level := 2 + floor_number * 2
	var count := clampi(2 + floor_number / 3, 2, 4)
	return _build(
		world, site.cell, TOWER, _pick(pool, count, level, rng), rng,
		"Floor %d." % floor_number
	)


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
	for i in count:
		out.append({
			"unit": pool[rng.randi() % pool.size()],
			"level": maxi(1, level + rng.randi_range(-1, 1)),
		})
	return out


static func _party_level(party: Array) -> int:
	if party.is_empty():
		return 1
	var total := 0
	for character: Character in party:
		total += character.level
	return maxi(1, total / party.size())


## 0 in safe country, rising the closer an open gate gets.
static func _danger_at(world: World, cell: Vector2i) -> int:
	var to_gate := world.distance_to_open_gate(cell)
	if to_gate > 12:
		return 0
	if to_gate > 6:
		return 1
	return 2
