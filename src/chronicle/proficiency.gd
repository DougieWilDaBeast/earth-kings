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
##
## Two things are counted ([D37]): the move, and the kind of weapon it was
## landed with. A master of one sword cut is not a master of the sword, and a
## great blade in hands that have never swung one is not yet a great blade.

## The weapon kinds skill is counted against. Anything else in hand — armour,
## a charm, nothing — is fighting bare.
const ARMS := ["blade", "bow", "staff"]
const BARE := "bare"

## What each rung is called, weakest first. Rank 0 has no name — you are simply
## doing it, and nobody remarks on that.
const NAMES := ["", "practised", "seasoned", "expert", "masterful"]


static func rules() -> Dictionary:
	return Database.world_rules.get("proficiency", {})


## Uses needed for each rung above nothing.
static func steps() -> Array:
	return rules().get("steps", [12, 40, 100, 220])


## Uses needed for each rung of skill with a kind of weapon. Every move landed
## counts toward it, so the ladder is longer.
static func arms_steps() -> Array:
	return rules().get("arms_steps", [30, 90, 200, 400])


## The kind of weapon [param character] has in hand.
static func arms_kind(character: Character) -> String:
	if character == null or character.equipment == "":
		return BARE
	var kind := str(Database.equipment_piece(character.equipment).get("kind", ""))
	return kind if ARMS.has(kind) else BARE


## Count one use. Only ever called for somebody who actually landed it, so
## swinging at empty air teaches nothing.
static func record(character: Character, ability_id: String) -> String:
	if character == null or ability_id == "":
		return ""
	var lines: Array[String] = []
	var before := rank(character, ability_id)
	character.practice[ability_id] = uses(character, ability_id) + 1
	var after := rank(character, ability_id)
	if after > before:
		lines.append("%s is %s with %s now." % [
			character.display_name, name_of(after),
			Database.ability(ability_id).get("display_name", ability_id)
		])
	var kind := arms_kind(character)
	var arms_before := arms_rank(character, kind)
	character.arms[kind] = arms_uses(character, kind) + 1
	var arms_after := arms_rank(character, kind)
	if arms_after > arms_before:
		lines.append("%s is %s %s now." % [character.display_name, name_of(arms_after), _with(kind)])
	return " ".join(lines)


static func arms_uses(character: Character, kind: String) -> int:
	return int(character.arms.get(kind, 0))


static func arms_rank(character: Character, kind: String) -> int:
	var count := roundi(arms_uses(character, kind) * character.lean("proficiency_rate", 1.0))
	var earned := 0
	for needed: int in arms_steps():
		if count < int(needed):
			break
		earned += 1
	return earned


static func _with(kind: String) -> String:
	return "fighting bare-handed" if kind == BARE else "with a %s" % kind


static func uses(character: Character, ability_id: String) -> int:
	return int(character.practice.get(ability_id, 0))


static func rank(character: Character, ability_id: String) -> int:
	# Ground-read tempers learn a weapon by carrying it, and get there sooner
	# (see `data/tempers.json`).
	var count := roundi(uses(character, ability_id) * character.lean("proficiency_rate", 1.0))
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
	var move := float(rules().get("per_rank", 0.06)) * float(rank(character, ability_id))
	var held := float(rules().get("arms_per_rank", 0.04)) * float(arms_rank(character, arms_kind(character)))
	return 1.0 + move + held


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


## Skill with a kind of weapon, for the party screen.
static func arms_summary(character: Character, kind: String) -> String:
	var count := arms_uses(character, kind)
	if count == 0:
		return "never used"
	var rung := arms_rank(character, kind)
	var ladder := arms_steps()
	if rung >= ladder.size():
		return "%s, %d blows" % [name_of(rung), count]
	var toward := "%d of %d toward %s" % [count, int(ladder[rung]), name_of(rung + 1)]
	return toward if rung == 0 else "%s  ·  %s" % [name_of(rung), toward]
