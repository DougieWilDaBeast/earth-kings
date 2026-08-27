class_name Encounter
extends RefCounted
## What finds you while you walk, and what waits behind a gate.
##
## Danger is a property of *place*: near an open gate the wild is thick with
## things that came out of it, and near a hearth it goes quiet.

const WILD := "wild"
const GATE := "gate"
const TOWER := "tower"


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
