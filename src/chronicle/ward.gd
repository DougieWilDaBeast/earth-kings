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


static func site_flag_for(site_cell: Vector2i) -> String:
	return "ward:site:%d,%d" % [site_cell.x, site_cell.y]


static func is_open(area_id: String, cell: Vector2i) -> bool:
	return GameState.has_flag(flag_for(area_id, cell))


static func is_site_open(site: Site) -> bool:
	if site == null or not site.data.has("ward"):
		return true
	return GameState.has_flag(site_flag_for(site.cell))


## Who in the party could open this, and with what. Returns an empty dictionary
## when nobody can — which is the interesting case, because it is a reason to
## come back rather than a dead end.
static func answer(ward: Dictionary, party: Array) -> Dictionary:
	var key := str(ward.get("key", ""))
	if key != "" and GameState.keys.has(key):
		return { "how": "key", "what": key }
	var keys: Array = ward.get("keys", [])
	for k in keys:
		if GameState.keys.has(str(k)):
			return { "how": "key", "what": str(k) }

	var abilities_list: Array = []
	if ward.has("abilities"):
		abilities_list = ward["abilities"]
	elif ward.has("ability"):
		abilities_list = [ward["ability"]]
	elif ward.get("kind", "") == "tree" or ward.get("tree", false) or str(ward.get("name", "")).to_lower().contains("tree") or str(ward.get("name", "")).to_lower().contains("briar"):
		abilities_list = ["cleave", "strike", "sunder", "crush", "scorch", "ember", "firebrand", "whirl"]
	elif ward.get("kind", "") == "gate" or str(ward.get("name", "")).to_lower().contains("gate"):
		abilities_list = ["crush", "earthshake", "sunder"]

	for ability_id: String in abilities_list:
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


## Try to breach or unlock a world site's ward.
static func force_site(site: Site, party: Array) -> Dictionary:
	var ward: Dictionary = site.data.get("ward", {})
	if ward.is_empty() or is_site_open(site):
		return { "opened": true, "line": "" }

	var found := answer(ward, party)
	if found.is_empty():
		return { "opened": false, "line": _denied(ward) }

	GameState.set_flag(site_flag_for(site.cell))
	return { "opened": true, "line": _opened(ward, found) }


## What it says when you cannot. Naming the thing you would need is the whole
## point — a locked door you cannot read is just a wall.
static func _denied(ward: Dictionary) -> String:
	var said := str(ward.get("denied", ""))
	if said != "":
		return said
	var wants: Array[String] = []
	var abilities_list: Array = []
	if ward.has("abilities"):
		abilities_list = ward["abilities"]
	elif ward.has("ability"):
		abilities_list = [ward["ability"]]
	for ab in abilities_list:
		var dname: String = str(Database.ability(str(ab)).get("display_name", ab))
		if dname != "" and dname not in wants:
			wants.append(dname)
	if str(ward.get("key", "")) != "":
		var key_name: String = str(ward.get("key", "")).replace("_", " ")
		wants.append("the %s" % key_name)
	for k in ward.get("keys", []):
		var kn: String = str(k).replace("_", " ")
		if kn not in wants:
			wants.append("the %s" % kn)

	if wants.is_empty():
		if ward.get("kind", "") == "tree" or str(ward.get("name", "")).to_lower().contains("tree"):
			return "A fallen tree blocks the path. It would take a sharp blade or heavy blow (Cleave, Strike, Sunder, or Ember) to cut through."
		if ward.get("kind", "") == "gate" or str(ward.get("name", "")).to_lower().contains("gate"):
			return "The gate is locked fast. It requires an iron key or Crush to force open."
		return "%s will not move." % str(ward.get("name", "It")).capitalize()
	return "%s holds. It would take %s." % [
		str(ward.get("name", "It")).capitalize(), " or ".join(wants)
	]


static func _opened(ward: Dictionary, found: Dictionary) -> String:
	var said := str(ward.get("opened", ""))
	if said != "":
		return said
	if str(found.get("how", "")) == "key":
		var key_name: String = str(found.get("what", "key")).replace("_", " ")
		return "The %s turns in the lock with a heavy click. %s swings open!" % [
			key_name, str(ward.get("name", "The gate")).capitalize()
		]
	var who: Character = found["who"]
	var ab_name: String = Database.ability(str(found["what"])).get("display_name", str(found["what"]))
	if ward.get("kind", "") == "tree" or str(ward.get("name", "")).to_lower().contains("tree") or str(ward.get("name", "")).to_lower().contains("briar"):
		return "%s uses %s to cut down the %s, clearing the path forward!" % [
			who.display_name, ab_name, str(ward.get("name", "fallen tree"))
		]
	return "%s uses %s, and %s gives way!" % [
		who.display_name,
		ab_name,
		str(ward.get("name", "it")),
	]
