class_name Tiers
extends RefCounted
## Five tiers of each monster (D262, `doug-md`'s play-test 7: "a lesser goblin, a goblin, a high
## goblin, a hob goblin, a goblin chieftain or a goblin caster"). A fight's pool names a family's plain
## kind; the fight deals it as one of the family's five, the odds set by the fight's level
## (`encounters.tiers` in data/encounters.json). Only the dealing is here; who stands in a pool is not.


static func rules() -> Dictionary:
	return Database.encounters.get("tiers", {})


## The family [param unit] belongs to, or "" when it has no tiers.
static func family_of(unit: String) -> String:
	var family := str(Database.unit_template(unit).get("family", ""))
	return family if rules().get("families", {}).has(family) else ""


## The kinds of [param family], lesser to top; the top is a list when it is one of several.
static func kinds(family: String) -> Array:
	return rules().get("families", {}).get(family, [])


## Every kind of every family, the top's several included.
static func every_kind() -> Array:
	var out: Array = []
	for family: String in rules().get("families", {}):
		for kind: Variant in kinds(family):
			if kind is Array:
				out.append_array(kind)
			else:
				out.append(str(kind))
	return out


## The odds, lesser to top, of each tier at [param level].
static func weights_at(level: int) -> Array:
	var weights: Array = []
	for row: Dictionary in rules().get("by_level", []):
		if int(row.get("from", 1)) <= level:
			weights = row.get("weights", [])
	return weights


## Deals each foe of [param enemies] whose unit has a family as one of its tiers, in place. A keeper
## (`boss`) is never dealt down; no more than `top_a_fight` come out at the top, the rest one below.
## Seeded off [param rng] without drawing from it, so the fights the dealing does not touch come out
## as they did before tiers.
static func deal(enemies: Array, level: int, rng: RandomNumberGenerator) -> void:
	var weights := weights_at(level)
	if weights.is_empty():
		return
	var dice := RandomNumberGenerator.new()
	dice.seed = hash([rng.state, level, enemies.size()])
	var tops := 0
	var most := int(rules().get("top_a_fight", 1))
	for entry: Dictionary in enemies:
		if bool(entry.get("boss", false)):
			continue
		# Only the plain kind, named as its family, is dealt: one already dealt stays what it is.
		var family := family_of(str(entry.get("unit", "")))
		if family == "" or family != str(entry.get("unit", "")):
			continue
		var line := kinds(family)
		var tier := mini(_roll(weights, dice), line.size() - 1)
		if tier == line.size() - 1:
			if tops >= most:
				tier -= 1
			else:
				tops += 1
		var kind: Variant = line[tier]
		entry["unit"] = str(kind[dice.randi() % kind.size()]) if kind is Array else str(kind)


## [method deal] for a band's pack of unit ids, as seen on the land before it fights.
static func deal_pack(pack: Array, level: int, rng: RandomNumberGenerator) -> Array:
	var enemies: Array = pack.map(func(unit: Variant) -> Dictionary: return { "unit": str(unit) })
	deal(enemies, level, rng)
	return enemies.map(func(entry: Dictionary) -> String: return str(entry["unit"]))


static func _roll(weights: Array, dice: RandomNumberGenerator) -> int:
	var total := 0.0
	for weight: Variant in weights:
		total += float(weight)
	if total <= 0.0:
		return 0
	var roll := dice.randf() * total
	for i in weights.size():
		roll -= float(weights[i])
		if roll < 0.0:
			return i
	return weights.size() - 1
