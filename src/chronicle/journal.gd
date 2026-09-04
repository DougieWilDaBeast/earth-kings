class_name Journal
extends RefCounted
## What you have found out about the things you fight, by fighting them.
##
## Nothing here is granted. An entry opens the first time you stand across a
## field from something, and it opens mostly blank: you know what it looks like
## and where you saw it, and nothing else. Every other line fills in the moment
## you earn it — an ability once it has been used on you, its reach once it has
## hit you, its guard once you have hit it, its constitution once you have put
## one down.
##
## Pure logic over a dictionary on [World], so it travels in the save and can
## be checked headless. Training fights are not written down; knowing a thing
## from the sandbox would be knowing it for free.

## Unknown fields read as this rather than as a zero, which would be a lie.
const UNKNOWN := "?"

## What has to happen before each line is worth writing down.
const STRUCK := "struck"
const WOUNDED := "wounded"
const FELLED := "felled"


static func book(world: World) -> Dictionary:
	return world.journal


## Open an entry. Returns true only the first time, so the caller can say so.
static func sighted(world: World, template_id: String, place: String) -> bool:
	if template_id == "" or not Database.units.has(template_id):
		return false
	if world.journal.has(template_id):
		var seen: Dictionary = world.journal[template_id]
		seen["met"] = int(seen.get("met", 0)) + 1
		return false
	world.journal[template_id] = {
		"met": 1,
		"first_step": world.steps,
		"place": place,
		"abilities": [],
		"struck": false,
		"wounded": false,
		"felled": 0,
	}
	return true


## It used something on somebody. One ability at a time, in the order seen.
static func note_ability(world: World, template_id: String, ability_id: String) -> void:
	var entry := _entry(world, template_id)
	if entry.is_empty() or ability_id == "":
		return
	var seen: Array = entry.get("abilities", [])
	if not seen.has(ability_id):
		seen.append(ability_id)
		entry["abilities"] = seen


## It landed a blow, so you know what it hits like.
static func note_struck(world: World, template_id: String) -> void:
	var entry := _entry(world, template_id)
	if not entry.is_empty():
		entry["struck"] = true


## You landed one, so you know what it is wearing.
static func note_wounded(world: World, template_id: String) -> void:
	var entry := _entry(world, template_id)
	if not entry.is_empty():
		entry["wounded"] = true


## You put one down, so you know how much of it there was.
static func note_felled(world: World, template_id: String) -> void:
	var entry := _entry(world, template_id)
	if not entry.is_empty():
		entry["felled"] = int(entry.get("felled", 0)) + 1


static func is_struck(world: World, template_id: String) -> bool:
	if world == null:
		return false
	return bool(_entry(world, template_id).get("struck", false))


static func is_wounded(world: World, template_id: String) -> bool:
	if world == null:
		return false
	return bool(_entry(world, template_id).get("wounded", false))


static func is_felled(world: World, template_id: String) -> bool:
	if world == null:
		return false
	return int(_entry(world, template_id).get("felled", 0)) > 0


static func known_abilities(world: World, template_id: String) -> Array:
	if world == null:
		return []
	return _entry(world, template_id).get("abilities", [])


static func knows(world: World, template_id: String) -> bool:
	return world.journal.has(template_id)


## Everything met, in the order it was met.
static func met(world: World) -> Array[String]:
	var out: Array[String] = []
	for template_id: String in world.journal:
		out.append(template_id)
	out.sort_custom(func(a: String, b: String) -> bool:
		return int(world.journal[a].get("first_step", 0)) < int(world.journal[b].get("first_step", 0))
	)
	return out


## How much of the world's bestiary is written up. Only things that can turn up
## in a fight count, or the total is padded by the party's own templates.
static func fullness(world: World) -> Array:
	return [world.journal.size(), _worth_meeting().size()]


## Label/value rows for one entry, with [constant UNKNOWN] wherever the answer
## has not been earned yet.
static func page(world: World, template_id: String) -> Array:
	var entry := _entry(world, template_id)
	if entry.is_empty():
		return []
	var template := Database.unit_template(template_id)
	var felled := int(entry.get("felled", 0))
	return [
		["Kind", str(template.get("kind", "person"))],
		["Calling", str(template.get("job", UNKNOWN))],
		["First seen", str(entry.get("place", UNKNOWN))],
		["Met", "%d time%s" % [int(entry.get("met", 1)), "" if int(entry.get("met", 1)) == 1 else "s"]],
		["Put down", str(felled) if felled > 0 else "not yet"],
		["Constitution", str(template.get("max_hp", 0)) if felled > 0 else UNKNOWN],
		["Reach", str(template.get("attack", 0)) if bool(entry.get("struck", false)) else UNKNOWN],
		["Guard", str(template.get("defense", 0)) if bool(entry.get("wounded", false)) else UNKNOWN],
	]


## Ability names it has been seen using, then a question mark for each one it
## has that you have not watched it use.
static func abilities(world: World, template_id: String) -> Array[String]:
	var entry := _entry(world, template_id)
	var seen: Array = entry.get("abilities", [])
	var out: Array[String] = []
	for ability_id: String in seen:
		out.append(str(Database.ability(ability_id).get("display_name", ability_id)))
	var total: int = Database.unit_template(template_id).get("abilities", []).size()
	for _i in maxi(0, total - out.size()):
		out.append(UNKNOWN)
	return out


static func _entry(world: World, template_id: String) -> Dictionary:
	return world.journal.get(template_id, {})


## Everything the world could actually field against you: the encounter pools,
## flattened. Party templates are not in them, so they do not pad the total.
static func _worth_meeting() -> Array:
	var out: Array = []
	for key: String in ["wild", "gate"]:
		for pool: Array in Database.encounters.get(key, {}).values():
			_gather(pool, out)
	for key: String in ["tower", "captors", "siege", "guard"]:
		_gather(Database.encounters.get(key, []), out)
	return out


static func _gather(pool: Array, out: Array) -> void:
	for template_id: String in pool:
		if not out.has(template_id):
			out.append(template_id)
