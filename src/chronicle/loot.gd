class_name Loot
extends RefCounted
## Picking things up: what a chest holds, and who ends up carrying it.
##
## There is no bag. A piece of gear goes to whoever it actually improves, and
## anything nobody in the party wants is sold on the spot rather than becoming
## a line on a screen that never gets read.


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

	var taker := _best_taker(equipment_id, roster)
	if taker == null:
		var worth := roundi(float(Market.price_of(equipment_id)) * float(rules().get("resale", 0.5)))
		GameState.gold += worth
		return "Nobody has a use for the %s. It goes for %d gold." % [name_, worth]

	taker.equipment = equipment_id
	return "%s takes up the %s." % [taker.display_name, name_]


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
	var item: String = haul.get("item", "")
	if item != "":
		var line := take(item, roster)
		if line != "":
			lines.append(line)
	return lines


## Whoever gains the most attack and defence from wearing it, or nobody.
static func _best_taker(equipment_id: String, roster: Roster) -> Character:
	var piece := Database.equipment_piece(equipment_id)
	var worth := int(piece.get("attack", 0)) + int(piece.get("defense", 0))
	var best: Character = null
	var best_gain := 0
	for character in roster.party_members():
		if not character.is_alive():
			continue
		var held := Database.equipment_piece(character.equipment)
		var gain := worth - (int(held.get("attack", 0)) + int(held.get("defense", 0)))
		if gain > best_gain:
			best_gain = gain
			best = character
	return best


static func _findable() -> Array:
	var pool: Array = []
	for equipment_id: String in Database.equipment:
		pool.append(equipment_id)
	return pool
