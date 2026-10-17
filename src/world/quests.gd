extends RefCounted
## The quest list ([D190]): everything the party is working towards, and which of them the compass
## and Auto follow.
##
## `doug-md` asked for it in play-test 2 ("a quest list you can cycle that points the compass",
## [D118]) and put it first of his asks after the First Hour ([D186]). It is not a list of chores
## handed down: every entry is something the party has been told or taken on. The road the First
## Hour lays out (the town, the Guild, the first gate, the Tower), each errand and Guild contract
## taken, anyone of yours being held for ransom, and a fallen lead's weapon there is word of.
##
## Nothing is followed until the player picks one (L on the ground, a click on the compass, or
## Follow in the journal); until then the compass keeps the First Hour's order
## ([method AutoRoad.default_objective]). What is followed is kept in the run's flags, so it
## survives a save; an entry that is done or gone stops being followed by itself.
##
## Loaded by path, not by `class_name` ([D41]).

const Dispatch := preload("res://src/chronicle/dispatch.gd")
const Siblings := preload("res://src/chronicle/siblings.gd")
const Markers := preload("res://src/world/markers.gd")

## The flag holding the id of the entry being followed, or nothing.
const FOLLOWED := "quest:followed"


## Every entry, in order: the road first, then errands, captives, word of a weapon and the map's markers. Each is
## `{ id, label, cell, stop, kind, detail }`; `label` is what the compass says.
static func all(world: World, road: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if world == null:
		return out
	if not road.is_empty():
		var entry := road.duplicate()
		entry["id"] = "road"
		entry["kind"] = "road"
		entry["detail"] = "The way the Tower's road runs: the city, the Guild, a gate, the climb."
		out.append(entry)
	for taken: Dictionary in GameState.errands:
		if str(taken.get(Dispatch.TAKEN_BY, "")) != "":
			continue
		var back := Errand.is_complete(taken)
		var at := _cell(taken.get("from" if back else "to", []))
		if at.x < 0:
			continue
		var named := str(taken.get("from_name" if back else "to_name", "the place"))
		out.append({
			"id": "errand:%d" % absi(hash([taken.get("title", ""), taken.get("from", []), taken.get("giver", "")])),
			"kind": "errand",
			"cell": at,
			"label": ("Back to %s" if back else "%s") % named,
			"stop": back or Town.is_settlement(world.site_at(at)),
			"detail": Errand.summary(taken),
		})
	if GameState.roster != null:
		for character: Character in GameState.roster.characters:
			if character.status != Fate.CAPTURED:
				continue
			var held := Captivity.held_at(character)
			var site := world.site_at(held)
			out.append({
				"id": "captive:%s" % character.template_id,
				"kind": "captive",
				"cell": held,
				"label": "Free %s" % character.display_name,
				"stop": true,
				"detail": "%s is being held at %s for %d gold." % [
					character.display_name, site.display_name if site != null else "a camp",
					int(character.captive.get("ransom", 0)),
				],
			})
	for heard: Dictionary in Siblings.heard_weapons(world):
		var at: Vector2i = heard.get("cell", Vector2i(-1, -1))
		if at.x < 0:
			continue
		var weapon := str(heard.get("id", ""))
		out.append({
			"id": "weapon:%s" % weapon,
			"kind": "weapon",
			"cell": at,
			"label": "Where %s came down" % Gear.display_name(weapon),
			"stop": true,
			"detail": "Word is a fallen lead's weapon came down out of the sky here.",
		})
	# The player's own marks on the map, and the place picked to go to ([D232]).
	out.append_array(Markers.entries(world))
	return out


## The entry being followed, if it is still in [param entries]; otherwise nothing, and the flag is
## let go, so a finished errand hands the compass back to the road.
static func followed(world: World, entries: Array[Dictionary]) -> Dictionary:
	var id := followed_id()
	if id == "" or world == null:
		return {}
	for entry: Dictionary in entries:
		if str(entry["id"]) == id:
			return entry
	GameState.flags.erase(FOLLOWED)
	return {}


static func followed_id() -> String:
	var id: Variant = GameState.flags.get(FOLLOWED, "")
	return str(id) if id is String else ""


## Follow [param id] (one of [method all]'s), or nothing with "" (back to the First Hour's order).
static func follow(id: String) -> void:
	if id == "":
		GameState.flags.erase(FOLLOWED)
	else:
		GameState.set_flag(FOLLOWED, id)


## Step to the next entry (or the one before) after the one the compass points at now, and follow
## it. [param current] is what the compass would point at with nothing chosen, so the first press
## moves on from what the player is already looking at. Returns the entry now followed.
static func cycle(world: World, entries: Array[Dictionary], current: Dictionary, step: int = 1) -> Dictionary:
	if entries.is_empty():
		follow("")
		return {}
	var at := -1
	var id := followed_id()
	for i in entries.size():
		var entry: Dictionary = entries[i]
		if id != "" and str(entry["id"]) == id:
			at = i
			break
		if id == "" and entry.get("cell") == current.get("cell") and str(entry["label"]) == str(current.get("label", "")):
			at = i
			break
	var next: Dictionary = entries[posmod(at + step, entries.size())] if at >= 0 else entries[0]
	follow(str(next["id"]))
	return next


## Where an entry is, in words a journal line can carry: so many tiles off, or here.
static func distance_text(world: World, entry: Dictionary) -> String:
	var tiles := Pathfinder.distance(world.player_cell, entry["cell"])
	if tiles <= 0:
		return "here"
	return "%d %s off" % [tiles, "tile" if tiles == 1 else "tiles"]


static func _cell(at: Variant) -> Vector2i:
	if at is Array and (at as Array).size() == 2:
		return Vector2i(int(at[0]), int(at[1]))
	return Vector2i(-1, -1)
