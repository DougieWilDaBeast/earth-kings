class_name Loot
extends RefCounted
## Picking things up: what a chest holds, and who ends up carrying it.
##
## A piece of gear goes straight onto whoever it actually improves, so the good
## find is never sitting unread on a screen. Anything nobody is better off in
## goes into the party's stores (`GameState.stores`) to be handed out later, and
## only a piece worth less than what everyone already carries is sold on.


static func rules() -> Dictionary:
	return Database.world_rules.get("loot", {})


## Hand [param equipment_id] to the party. Returns the line worth showing.
static func take(equipment_id: String, roster: Roster) -> String:
	var piece := Database.equipment_piece(equipment_id)
	if piece.is_empty():
		return ""
	var name_: String = piece.get("display_name", equipment_id)

	# A charm is never worn, only carried, so it always has a taker.
	if piece.get("charm", false):
		var keeper := roster.player()
		if keeper == null:
			return ""
		keeper.charms.append(equipment_id)
		return "%s pockets the %s." % [keeper.display_name, name_]

	# Food and physic go straight in the packs, to be spent later.
	if Gear.is_draught(equipment_id):
		GameState.stores.append(equipment_id)
		return "The %s goes in the packs." % name_

	var taker := _best_taker(equipment_id, roster)
	if taker == null:
		return stow(equipment_id, roster)

	var displaced := taker.equipment
	taker.equipment = equipment_id
	if displaced == "":
		return "%s takes up the %s." % [taker.display_name, name_]
	GameState.stores.append(displaced)
	return "%s takes up the %s, and the %s goes in the packs." % [
		taker.display_name, name_, Gear.display_name(displaced)
	]


## Into the packs, or sold if it is worse than everything already being carried.
static func stow(equipment_id: String, roster: Roster) -> String:
	var name_ := Gear.display_name(equipment_id)
	var worth_keeping := roster.party_members().any(
		func(c: Character) -> bool: return Gear.worth(equipment_id, c) > 0
	)
	if worth_keeping:
		GameState.stores.append(equipment_id)
		return "The %s goes in the packs." % name_
	var worth := roundi(float(Market.price_of(equipment_id)) * float(rules().get("resale", 0.5)))
	GameState.gold += worth
	return "Nobody has a use for the %s. It goes for %d gold." % [name_, worth]


## Roll what is inside a container of a given richness. Gold is always there;
## something to carry is not.
static func roll(world: World, richness: float) -> Dictionary:
	var base := int(rules().get("gold_base", 40))
	var spread := maxi(1, int(rules().get("gold_spread", 60)))
	var haul := {
		"gold": Difficulty.scaled(
			roundi((base + world.rng.randi() % spread) * maxf(0.2, richness)), "gold"
		),
		"item": "",
	}
	if world.rng.randf() < float(rules().get("item_chance", 0.35)) * richness:
		var pool := _findable()
		if not pool.is_empty():
			haul["item"] = pool[world.rng.randi() % pool.size()]
	return haul


## Pay out a haul and return the lines worth showing.
static func claim(haul: Dictionary, roster: Roster) -> Array[String]:
	var lines: Array[String] = []
	var gold := int(haul.get("gold", 0))
	if gold > 0:
		GameState.gold += gold
		lines.append("%d gold." % gold)
	var found_key: String = haul.get("key", "")
	if found_key != "" and not GameState.keys.has(found_key):
		GameState.keys.append(found_key)
		lines.append("A key. It opens something you have not reached yet.")
	var item: String = haul.get("item", "")
	if item != "":
		var line := take(item, roster)
		if line != "":
			lines.append(line)
	return lines


## Whoever gains the most from wearing it, or nobody. A piece counts for less
## in the wrong hands, so the best numbers do not always win it (see [Gear]).
static func _best_taker(equipment_id: String, roster: Roster) -> Character:
	var best: Character = null
	var best_gain := 0
	for character in roster.party_members():
		if not character.is_alive():
			continue
		var gain := Gear.swing(equipment_id, character)
		if gain > best_gain:
			best_gain = gain
			best = character
	return best


static func _findable() -> Array:
	var pool: Array = []
	for equipment_id: String in Database.equipment:
		pool.append(equipment_id)
	return pool
