class_name Proficiency
extends RefCounted
## Getting better at a thing by doing it, rather than by being told you may.
##
## Levels are handed out; this is not. Every time somebody actually lands a
## move, it is counted, and at a few thresholds the move starts hitting harder
## for that person specifically. Two swordsmen of the same level who have spent
## their fights differently are not the same swordsman.
##
## Counted on [Character], so it travels in the save and is per-person, not
## per-class. Scratch enemies have no [Character] and so never improve.

## What each rung is called, weakest first. Rank 0 has no name — you are simply
## doing it, and nobody remarks on that.
const NAMES := ["", "practised", "seasoned", "expert", "masterful"]


static func rules() -> Dictionary:
	return Database.world_rules.get("proficiency", {})


## Uses needed for each rung above nothing.
static func steps() -> Array:
	return rules().get("steps", [12, 40, 100, 220])


## Count one use. Only ever called for somebody who actually landed it, so
## swinging at empty air teaches nothing.
static func record(character: Character, ability_id: String) -> String:
	if character == null or ability_id == "":
		return ""
	var before := rank(character, ability_id)
	character.practice[ability_id] = uses(character, ability_id) + 1
	var after := rank(character, ability_id)
	if after <= before:
		return ""
	return "%s is %s with %s now." % [
		character.display_name, name_of(after),
		Database.ability(ability_id).get("display_name", ability_id)
	]


static func uses(character: Character, ability_id: String) -> int:
	return int(character.practice.get(ability_id, 0))


static func rank(character: Character, ability_id: String) -> int:
	var count := uses(character, ability_id)
	var earned := 0
	for needed: int in steps():
		if count < int(needed):
			break
		earned += 1
	return earned


static func name_of(rung: int) -> String:
	return NAMES[clampi(rung, 0, NAMES.size() - 1)]


## What a move is worth in these particular hands: 1.0 for somebody who has
## barely used it, more for somebody who has used it for a hundred fights.
static func multiplier(character: Character, ability_id: String) -> float:
	if character == null:
		return 1.0
	return 1.0 + float(rules().get("per_rank", 0.06)) * float(rank(character, ability_id))


## How close they are to the next rung, for the party screen. Empty once there
## is nothing left to get better at.
static func summary(character: Character, ability_id: String) -> String:
	var rung := rank(character, ability_id)
	var count := uses(character, ability_id)
	if count == 0:
		return "never used"
	var ladder := steps()
	if rung >= ladder.size():
		return "%s, %d uses" % [name_of(rung), count]
	var named := name_of(rung)
	var toward := "%d of %d toward %s" % [count, int(ladder[rung]), name_of(rung + 1)]
	return toward if named == "" else "%s  ·  %s" % [named, toward]
