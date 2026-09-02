class_name Gear
extends RefCounted
## What a piece of equipment is actually worth to the person holding it.
##
## A sword in the wrong hands is still a sword, but it is not the same sword.
## Every piece names the callings it `suits`; anyone else carries it at a
## penalty, so picking up the best numbers on the field is not automatically
## the right answer. A piece that names nobody suits everybody.
##
## Pure logic over `data/equipment.json`. Nothing here reads [GameState].

## How much of a piece's bonus survives being carried by the wrong person.
const MISFIT_SHARE := 0.4
## And what it costs on top, for a piece badly out of its calling.
const MISFIT_PENALTY := 2


static func piece(equipment_id: String) -> Dictionary:
	return Database.equipment_piece(equipment_id)


static func display_name(equipment_id: String) -> String:
	return str(piece(equipment_id).get("display_name", equipment_id))


static func is_charm(equipment_id: String) -> bool:
	return bool(piece(equipment_id).get("charm", false))


## What kind of thing it is: blade, bow, staff, armour, charm. Used for grouping
## and for saying what somebody is short of.
static func kind(equipment_id: String) -> String:
	return str(piece(equipment_id).get("kind", "gear"))


## Does this piece belong in this person's hands? A piece with no `suits` list
## is plain enough that anybody can use it.
static func suits(equipment_id: String, character: Character) -> bool:
	var callings: Array = piece(equipment_id).get("suits", [])
	if callings.is_empty():
		return true
	return callings.has(character.class_id) or callings.has(character.template_id)


## Attack and defence this piece gives [param character], fit already applied.
static func bonus(equipment_id: String, character: Character) -> Dictionary:
	var data := piece(equipment_id)
	if data.is_empty() or bool(data.get("charm", false)):
		return { "attack": 0, "defense": 0 }
	var attack := int(data.get("attack", 0))
	var defense := int(data.get("defense", 0))
	if suits(equipment_id, character):
		return { "attack": attack, "defense": defense }
	return {
		"attack": _misfit(attack),
		"defense": _misfit(defense),
	}


## The one number used to compare two pieces for one person.
static func worth(equipment_id: String, character: Character) -> int:
	var gain := bonus(equipment_id, character)
	return int(gain["attack"]) + int(gain["defense"])


## What swapping to this piece would do to somebody already carrying something.
static func swing(equipment_id: String, character: Character) -> int:
	return worth(equipment_id, character) - worth(character.equipment, character)


## A short line for the party screen: what it gives, and whether it fits.
static func summary(equipment_id: String, character: Character) -> String:
	if is_charm(equipment_id):
		return str(piece(equipment_id).get("text", "Carried, not worn."))
	var gain := bonus(equipment_id, character)
	var parts: Array[String] = []
	if int(gain["attack"]) != 0:
		parts.append("%+d attack" % int(gain["attack"]))
	if int(gain["defense"]) != 0:
		parts.append("%+d guard" % int(gain["defense"]))
	if parts.is_empty():
		parts.append("no help at all")
	if not suits(equipment_id, character):
		parts.append("wrong hands")
	return ", ".join(parts)


static func _misfit(value: int) -> int:
	if value <= 0:
		return value
	return roundi(value * MISFIT_SHARE) - MISFIT_PENALTY
