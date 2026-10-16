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
## AU (D161): after the city the compass points at the first gate, not the Guild at the door.
static func gate_after_city() -> bool:
	return wants_guild_mark() and bool(Database.world_rules.get("first_hour", {}).get("gate_after_city", false))


## What Sennet says the first time the party walks into a town while no gate is shut (AU, D161),
## [param gate] the one the compass now points at; "" when the rule is off.
static func gate_line(gate: String) -> String:
	if not gate_after_city() or gate == "":
		return ""
	return str(Database.world_rules.get("first_hour", {}).get("gate_line", "")).format({"gate": gate})


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


## AK (D149): the hour's end costs somebody. The first time a lead wins the floor `light_out.floor`,
## one of the other sixteen, somewhere in a world of their own, falls while this one climbed: never
## the lead, anyone in the company, a lead already fallen, or one met at a crossing. Picked by the
## world's own seed, so a world always loses the same one. Kept in [member World.echoes], counted
## out of the census from then on (`Chapters.census`). Returns what the Tower shows, or [] when
## nothing goes out.
static func put_out_a_light(world: World, floor: int, company: Array) -> Array[String]:
	var lines: Array[String] = []
	var rules: Dictionary = Database.world_rules.get("first_hour", {}).get("light_out", {})
	if rules.is_empty() or world == null or floor != int(rules.get("floor", 5)) or world.echoes.has("light_out"):
		return lines
	var spared: Array = company.duplicate()
	spared.append_array(Sixteen.fallen_heroes())
	for echo: Dictionary in world.echoes.get("past", []):
		spared.append(str(echo.get("hero", "")))
	var codes: Array = Database.temper_types().keys()
	codes.sort()
	var left: Array[String] = []
	for code: String in codes:
		var hero := Database.temper_hero(code)
		if hero != "" and not spared.has(hero) and not GameState.has_flag("crossed:%s" % hero):
			left.append(hero)
	if left.is_empty():
		return lines
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.world_seed, int(world.echoes.get("sibling", 0)), "light_out"])
	var hero: String = left[rng.randi_range(0, left.size() - 1)]
	var name := str(Database.unit_template(hero).get("display_name", hero))
	world.echoes["light_out"] = {"hero": hero, "name": name, "floor": floor}
	for line: Variant in rules.get("lines", []):
		lines.append(str(line).format({"name": name}))
	Annals.record(world, "As the company won floor %d, %s fell in a world of their own." % [floor, name])
	return lines


## AM (D150): whether a party walking itself stops for this fight and hands it to the player: a
## gate's fight, a keeper, or a foe more than `above_level` over [param lead_level]. Auto fights
## only what is below that. [param kind] is the pending outcome's kind ("gate", "tower", ...).
static func auto_stops_for(enemies: Array, kind: String, lead_level: int) -> bool:
	var rules: Dictionary = Database.world_rules.get("first_hour", {}).get("auto_stops", {})
	if rules.is_empty():
		return false
	if bool(rules.get("gates", false)) and kind == "gate":
		return true
	for foe: Variant in enemies:
		if not foe is Dictionary:
			continue
		if bool(rules.get("keepers", false)) and bool((foe as Dictionary).get("boss", false)):
			return true
		if int((foe as Dictionary).get("level", 0)) > lead_level + int(rules.get("above_level", 0)):
			return true
	return false


## What a fight says when Auto has stopped for it (D150).
static func auto_stop_line() -> String:
	return str(Database.world_rules.get("first_hour", {}).get("auto_stops", {}).get("line", ""))
