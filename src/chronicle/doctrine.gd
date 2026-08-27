class_name Doctrine
extends RefCounted
## The Library layer: knowledge is read, taught, and — if left unused — forgotten.
##
## Nothing is inherited. A doctrine only affects a character who has personally
## read it or been taught it, which is what makes a Library worth walking to.

## World steps a doctrine survives without being read, taught or fought with.
const FADE_AFTER_STEPS := 900


static func entry(doctrine_id: String) -> Dictionary:
	return Database.doctrine(doctrine_id)


static func title(doctrine_id: String) -> String:
	return entry(doctrine_id).get("title", doctrine_id)


## Total bonus to [param stat_key] from everything this character knows.
static func bonus(character: Character, stat_key: String) -> int:
	var total := 0
	for doctrine_id: String in character.doctrine:
		total += int(entry(doctrine_id).get("bonus", {}).get(stat_key, 0))
	return total


## Returns false if they already knew it.
static func learn(character: Character, doctrine_id: String, step: int) -> bool:
	if character.knows(doctrine_id):
		reinforce(character, doctrine_id, step)
		return false
	character.doctrine.append(doctrine_id)
	character.doctrine_seen[doctrine_id] = step
	return true


static func reinforce(character: Character, doctrine_id: String, step: int) -> void:
	if character.knows(doctrine_id):
		character.doctrine_seen[doctrine_id] = step


## Reinforce everything a character carries — walking out of a fight alive
## counts as using what you know.
static func reinforce_all(character: Character, step: int) -> void:
	for doctrine_id: String in character.doctrine:
		character.doctrine_seen[doctrine_id] = step


static func teach(teacher: Character, student: Character, doctrine_id: String, step: int) -> bool:
	if not teacher.knows(doctrine_id) or student.knows(doctrine_id):
		return false
	reinforce(teacher, doctrine_id, step)
	return learn(student, doctrine_id, step)


## Doctrine the teacher holds and the student does not.
static func teachable(teacher: Character, student: Character) -> Array:
	var out: Array = []
	for doctrine_id: String in teacher.doctrine:
		if not student.knows(doctrine_id):
			out.append(doctrine_id)
	return out


## Drop anything gone stale. Returns the ids that were lost.
static func decay(character: Character, step: int) -> Array:
	var forgotten: Array = []
	for doctrine_id: String in character.doctrine.duplicate():
		var last_seen := int(character.doctrine_seen.get(doctrine_id, step))
		if step - last_seen >= FADE_AFTER_STEPS:
			character.doctrine.erase(doctrine_id)
			character.doctrine_seen.erase(doctrine_id)
			forgotten.append(doctrine_id)
	return forgotten
