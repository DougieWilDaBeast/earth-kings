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
