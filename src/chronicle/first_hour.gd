class_name FirstHour
extends RefCounted
## What the First Hour leaves out (D95, D97), and who it starts as (D106).
##
## Scope is frozen on the First Hour until it plays from the crater to floor 5.
## Everything on the producer's cut list stays built but out of reach, behind one
## block of switches in `data/world_rules.json` → `first_hour.hidden`. Taking a
## name out of that list brings its system back; nothing is deleted.

const Sixteen := preload("res://src/chronicle/sixteen.gd")


## Whether [param feature] is hidden for now. Names: coliseum, training, museum,
## trivia, grimoires, ferries, captivity, nemesis, dispatch, seasons.
static func hides(feature: String) -> bool:
	return (Database.world_rules.get("first_hour", {}).get("hidden", []) as Array).has(feature)


## D101: whether a run starts with the Tower's stair sealed until a gate is shut.
static func wants_guild_mark() -> bool:
	return bool(Database.world_rules.get("first_hour", {}).get("guild_mark", false))


## What the Tower's doorkeeper says while the stair waits for the Guild's mark.
static func mark_line() -> String:
	return str(Database.world_rules.get("first_hour", {}).get("mark_line", ""))


## D106: the lead every new player starts as, while no world has ended yet; after
## a death the quiz picks the next lead. Empty when the quiz should ask now.
static func first_life() -> String:
	var lead := str(Database.world_rules.get("first_hour", {}).get("first_life", ""))
	if lead == "" or not Sixteen.worlds().is_empty() or Sixteen.fallen_heroes().has(lead):
		return ""
	return lead


## AQ: while some of the sixteen have no chapter one yet, the quiz deals only those who do, so a
## second life does not climb to an empty alcove on floor 5. The tempers to hold back, on top of the
## [param fallen]; none once every living lead has a chapter one, or when holding them back would
## leave nobody to deal. Switched by `first_hour.deal_only_written` in `data/world_rules.json`.
static func unwritten_tempers(fallen: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	if not bool(Database.world_rules.get("first_hour", {}).get("deal_only_written", false)):
		return out
	var written := 0
	for code: String in Database.temper_types():
		if fallen.has(code):
			continue
		var hero := Database.temper_hero(code)
		if hero != "" and not (Database.memories.get(hero, []) as Array).is_empty():
			written += 1
		else:
			out.append(code)
	return out if written > 0 else PackedStringArray()
