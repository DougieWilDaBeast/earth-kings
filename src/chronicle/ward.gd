class_name Ward
extends RefCounted
## Something in the way that is not a wall.
##
## A wall is scenery. A ward is a question: the door is barred, the tree is
## across the path, the water is too deep — and somewhere in your party is the
## answer, or is not. It opens for an ability one of you knows or a key one of
## you found, and until then it is simply shut and says so.
##
## Once opened it stays opened, on a [GameState] flag, so a way you made is a
## way you keep. Pure logic over the `wards` block of an area file.

## Nothing here is generated; every ward is placed by hand in `data/areas/*.json`.
##   { "cell": [8, 4], "name": "the barred door",
##     "ability": "crush", "key": "gate_key",
##     "shut": "...", "opened": "...", "denied": "..." }


static func flag_for(area_id: String, cell: Vector2i) -> String:
	return "ward:%s:%d,%d" % [area_id, cell.x, cell.y]


static func is_open(area_id: String, cell: Vector2i) -> bool:
	return GameState.has_flag(flag_for(area_id, cell))


## Who in the party could open this, and with what. Returns an empty dictionary
## when nobody can — which is the interesting case, because it is a reason to
## come back rather than a dead end.
static func answer(ward: Dictionary, party: Array) -> Dictionary:
	var key := str(ward.get("key", ""))
	if key != "" and GameState.keys.has(key):
		return { "how": "key", "what": key }
	var ability_id := str(ward.get("ability", ""))
	if ability_id != "":
		for character: Character in party:
			if character.abilities().has(ability_id):
				return { "how": "ability", "who": character, "what": ability_id }
	return {}


## Try it. Returns the line worth showing either way; `opened` says whether the
## way is now clear.
static func force(area_id: String, ward: Dictionary, party: Array) -> Dictionary:
	var cell: Vector2i = ward.get("cell", Vector2i.ZERO)
	if is_open(area_id, cell):
		return { "opened": true, "line": "" }

	var found := answer(ward, party)
	if found.is_empty():
		return { "opened": false, "line": _denied(ward) }

	GameState.set_flag(flag_for(area_id, cell))
	return { "opened": true, "line": _opened(ward, found) }


## What it says when you cannot. Naming the thing you would need is the whole
## point — a locked door you cannot read is just a wall.
static func _denied(ward: Dictionary) -> String:
	var said := str(ward.get("denied", ""))
	if said != "":
		return said
	var wants: Array[String] = []
	var ability_id := str(ward.get("ability", ""))
	if ability_id != "":
		wants.append(str(Database.ability(ability_id).get("display_name", ability_id)))
	if str(ward.get("key", "")) != "":
		wants.append("a key you have not found")
	if wants.is_empty():
		return "%s will not move." % str(ward.get("name", "It")).capitalize()
	return "%s holds. It would take %s." % [
		str(ward.get("name", "It")).capitalize(), " or ".join(wants)
	]


static func _opened(ward: Dictionary, found: Dictionary) -> String:
	var said := str(ward.get("opened", ""))
	if said != "":
		return said
	if str(found.get("how", "")) == "key":
		return "The key turns. %s gives." % str(ward.get("name", "It")).capitalize()
	var who: Character = found["who"]
	return "%s uses %s, and %s gives." % [
		who.display_name,
		Database.ability(str(found["what"])).get("display_name", found["what"]),
		str(ward.get("name", "it")),
	]
