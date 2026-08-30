class_name Faction
extends RefCounted
## Who holds what, and who you meet where (see `data/factions.json`).
##
## Membership is the faction's `ranks` list, weakest first, so a band raised for
## a level takes the rungs that suit it instead of a flat random pick — a valley
## at level two meets copper legionnaires, the same valley at twelve meets gold.

const FALLBACK := "the_wild"
## How many levels a rung of a faction's ladder is worth.
const LEVELS_PER_RANK := 3

## Cached unit id -> faction id, since membership only lives in the JSON.
static var _belongs: Dictionary = {}


static func rules(faction_id: String) -> Dictionary:
	return Database.factions.get(faction_id, {})


static func display_name(faction_id: String) -> String:
	return rules(faction_id).get("display_name", "nobody in particular")


static func banner(faction_id: String) -> Color:
	return Color(rules(faction_id).get("banner", "#8f8a7c"))


## The keep or castle drawn for this faction's seat on the world map.
static func hold_art(faction_id: String) -> String:
	return rules(faction_id).get("hold", "")


static func champion(faction_id: String) -> String:
	var ranks: Array = rules(faction_id).get("ranks", [])
	return str(rules(faction_id).get("champion", ranks[-1] if not ranks.is_empty() else "goblin"))


## Whose country this is. A unit nobody claims answers to the wild.
static func of(unit_id: String) -> String:
	if _belongs.is_empty():
		for faction_id: String in Database.factions:
			for member: String in rules(faction_id).get("ranks", []):
				_belongs[member] = faction_id
			_belongs[champion(faction_id)] = faction_id
	return str(_belongs.get(unit_id, FALLBACK))


## The factions that walk a given kind of ground.
static func on(terrain_id: String) -> Array:
	var found: Array = []
	for faction_id: String in Database.factions:
		if terrain_id in rules(faction_id).get("ground", []):
			found.append(faction_id)
	return found


## One of them, weighted by nothing in particular — the country does not owe
## you a pattern.
static func pick_on(terrain_id: String, rng: RandomNumberGenerator) -> String:
	var found := on(terrain_id)
	if found.is_empty():
		return FALLBACK
	return str(found[rng.randi() % found.size()])


## The rungs of a faction worth fielding against [param level]: the one that
## matches, and its neighbours either side, so a band is never all identical.
static func pool(faction_id: String, level: int) -> Array:
	var ranks: Array = rules(faction_id).get("ranks", [])
	if ranks.is_empty():
		return []
	var rung := clampi(int(float(level) / LEVELS_PER_RANK), 0, ranks.size() - 1)
	var low := maxi(0, rung - 1)
	var high := mini(ranks.size() - 1, rung + 1)
	return ranks.slice(low, high + 1)


## Everyone a faction can field, for a fight that is not about level.
static func roster(faction_id: String) -> Array:
	return rules(faction_id).get("ranks", []).duplicate()


static func is_hostile(faction_id: String) -> bool:
	return bool(rules(faction_id).get("hostile", true))


## The factions that garrison a kind of place, so a gate or a keep can be dealt
## an owner at world generation.
static func seated_at(kind: String) -> Array:
	var found: Array = []
	for faction_id: String in Database.factions:
		if rules(faction_id).get("seat", "") == kind and is_hostile(faction_id):
			found.append(faction_id)
	return found
