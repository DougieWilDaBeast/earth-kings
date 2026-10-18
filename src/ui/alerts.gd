extends RefCounted
## What wants the player's attention right now ([D245], after RimWorld's alerts: "Colonist needs
## rescue", "Need meal source" and the rest, a short list down the side of the screen): a path or a
## power owed, someone badly hurt, no draughts in the packs while someone is, one of the company
## held for ransom, an X on the map, a town under attack. Each is `{ id, text, detail, act, follow }`:
## `act` is "party" (the party screen opens), "follow" (the compass follows `follow`, a quest list
## id) or "". Most urgent first; the words are `data/world_rules.json` → `play_hud.alerts`.
##
## Static and stateless, so a suite can read it without a screen. Loaded by path ([D41]).

const Treasure := preload("res://src/chronicle/treasure.gd")
const Atlas := preload("res://src/chronicle/atlas.gd")


static func rules() -> Dictionary:
	return Database.world_rules.get("play_hud", {}).get("alerts", {})


static func _say(key: String, tokens: Dictionary) -> Dictionary:
	var said: Dictionary = rules().get(key, {})
	return {
		"text": str(said.get("text", key)).format(tokens),
		"detail": str(said.get("detail", "")).format(tokens),
	}


static func _entry(id: String, key: String, tokens: Dictionary, act: String, follow: String = "") -> Dictionary:
	var out := _say(key, tokens)
	out["id"] = id
	out["act"] = act
	out["follow"] = follow
	return out


## Everything worth saying now, most urgent first.
static func gather() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var roster := GameState.roster
	var world: World = GameState.world
	if roster == null:
		return out
	var low := float(rules().get("hurt_below", 0.5))
	var anyone_hurt := false
	for character: Character in roster.party_members():
		if not character.is_alive():
			continue
		var share := float(character.current_hp()) / float(maxi(1, character.max_hp()))
		if share < low:
			anyone_hurt = true
			out.append(_entry("hurt:" + character.id, "hurt", { "name": character.display_name,
				"hp": character.current_hp(), "max": character.max_hp() }, "party"))
	if anyone_hurt and draughts() == 0:
		out.append(_entry("no_draughts", "no_draughts", {}, ""))
	for character: Character in roster.characters:
		if character.status != Fate.CAPTURED or world == null:
			continue
		out.append(_entry("held:" + character.id, "held", { "name": character.display_name,
			"ransom": int(character.captive.get("ransom", 0)), "steps": Captivity.steps_left(character, world) },
			"follow", "captive:%s" % character.template_id))
	if world != null:
		for site: Site in world.sites:
			if Town.is_settlement(site) and Town.is_threatened(site) and Atlas.knows(world, site):
				out.append(_entry("siege:%d,%d" % [site.cell.x, site.cell.y], "siege", { "place": site.display_name }, ""))
	for character: Character in roster.party_members():
		if character.pending_class_choice:
			out.append(_entry("path:" + character.id, "path", { "name": character.display_name }, "party"))
		elif character.rungs > 0:
			out.append(_entry("power:" + character.id, "power", { "name": character.display_name,
				"count": character.rungs }, "party"))
	if world != null and Treasure.at(world).x >= 0:
		out.append(_entry("treasure", "treasure", {}, "follow", "treasure"))
	return out


## How many draughts and bits of food are in the packs.
static func draughts() -> int:
	var count := 0
	for item: Variant in GameState.stores:
		if str(Database.equipment_piece(str(item)).get("kind", "")) == "draught":
			count += 1
	return count
