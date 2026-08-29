class_name Trivia
extends RefCounted
## Small magic that does nothing.
##
## Spells for taking a stain out of cloth, or making a field bloom for one
## afternoon. None of them will ever win a fight. They are collected because
## collecting them is how the world's grammar gets understood at all — and an
## understood grammar makes the powers that *do* matter come out stronger
## (see [World.codex_understanding]).
##
## They are the world's, not a character's. Nobody guards these, and nobody
## forgets them.


static func rules() -> Dictionary:
	return Database.trivia


static func catalogue() -> Array:
	return rules().get("spells", [])


static func total() -> int:
	return catalogue().size()


static func known(world: World) -> Array:
	return world.trivia


static func share_found(world: World) -> float:
	if total() == 0:
		return 0.0
	return clampf(float(world.trivia.size()) / float(total()), 0.0, 1.0)


static func has(world: World, index: int) -> bool:
	return world.trivia.any(func(entry: Dictionary) -> bool: return int(entry.get("id", -1)) == index)


## Find one nobody has written down yet. Empty once the world has them all.
static func discover(world: World) -> Dictionary:
	var unfound: Array = []
	for i in total():
		if not has(world, i):
			unfound.append(i)
	if unfound.is_empty():
		return {}

	var index: int = unfound[world.rng.randi() % unfound.size()]
	var spell: Dictionary = catalogue()[index]
	var notes: Array = rules().get("notes", [""])
	var entry := {
		"id": index,
		"name": spell.get("name", "A small spell"),
		"text": spell.get("text", ""),
		"note": notes[world.rng.randi() % notes.size()],
		"found_at": world.steps,
	}
	world.trivia.append(entry)
	return entry


## Roll for one against a chance from `data/trivia.json`, and say so if it lands.
static func maybe_discover(world: World, chance_key: String) -> Array[String]:
	if world.rng.randf() >= float(rules().get(chance_key, 0.0)):
		return []
	var entry := discover(world)
	if entry.is_empty():
		return []
	var found: Array = rules().get("found", ["You write it down."])
	return [line(entry), found[world.rng.randi() % found.size()]]


static func line(entry: Dictionary) -> String:
	return "%s — a spell %s. %s" % [
		entry.get("name", ""), entry.get("text", ""), entry.get("note", "")
	]
