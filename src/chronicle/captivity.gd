class_name Captivity
extends RefCounted
## What happens to the taken. A captive is held somewhere with a price on them
## and a clock running — buy them back, fight for them, or find out they were
## sold on to someone who does not intend to give them back.
##
## Nobody waits forever for their friends.

const SOLD := "sold"
const HELD := "held"


static func rules() -> Dictionary:
	return Database.world_rules.get("captive", {})


## Called when [Fate] decides a character is taken rather than killed.
static func take(character: Character, world: World, site: Site) -> void:
	var price := ransom_for(character)
	character.captured_at = site.display_name if site != null else "somewhere unmarked"
	character.captive = {
		"cell": [site.cell.x, site.cell.y] if site != null else [0, 0],
		"ransom": price,
		"due": world.steps + int(rules().get("deadline_steps", 900)),
	}


static func ransom_for(character: Character) -> int:
	return int(rules().get("ransom_base", 120)) + int(rules().get("ransom_per_level", 25)) * character.level


static func held_at(character: Character) -> Vector2i:
	var pair: Array = character.captive.get("cell", [0, 0])
	return Vector2i(int(pair[0]), int(pair[1]))


static func steps_left(character: Character, world: World) -> int:
	return maxi(0, int(character.captive.get("due", 0)) - world.steps)


static func is_overdue(character: Character, world: World) -> bool:
	return character.status == Fate.CAPTURED and steps_left(character, world) <= 0


## Buy someone back. Returns false if the money is not there.
static func ransom(character: Character, roster: Roster) -> bool:
	var price := int(character.captive.get("ransom", ransom_for(character)))
	if GameState.gold < price:
		return false
	GameState.gold -= price
	_release(character, roster)
	return true


## Take them back by force — the captors are already beaten by the time this runs.
static func free_by_force(character: Character, roster: Roster) -> void:
	_release(character, roster)


## The deadline passed. Sometimes they are simply moved; sometimes they are sold.
static func resolve_deadline(character: Character, world: World) -> String:
	if world.rng.randf() < float(rules().get("sold_chance", 0.5)):
		character.status = Fate.DEAD
		character.captive = {}
		return SOLD
	# Still held, but the price of waiting goes up.
	character.captive["due"] = world.steps + int(rules().get("deadline_steps", 900))
	character.captive["ransom"] = int(character.captive.get("ransom", 0)) * 2
	return HELD


static func _release(character: Character, roster: Roster) -> void:
	character.status = Fate.ALIVE
	character.captive = {}
	character.captured_at = ""
	character.hp = maxi(1, roundi(character.max_hp() * 0.4))
	roster.enlist(character.id)
