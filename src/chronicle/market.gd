class_name Market
extends RefCounted
## What a town is for: gear to buy, and people willing to walk with you.
##
## Parties are temporary. Everyone here is looking out for themselves, and the
## price reflects it.

## Loaded by path ([D41]): regional names (see its header).
const Names := preload("res://src/chronicle/names.gd")


static func rules() -> Dictionary:
	return Database.world_rules.get("recruit", {})


## Restock a settlement if enough time has passed since anyone last looked.
static func refresh(site: Site, world: World) -> void:
	var interval := int(rules().get("refresh_steps", 400))
	if site.data.has("stocked_at") and world.steps - int(site.data["stocked_at"]) < interval:
		return
	site.data["stocked_at"] = world.steps
	site.data["wares"] = _roll_wares(world)
	site.data["hire"] = _roll_hire(site, world)


# --- goods --------------------------------------------------------------------


static func wares(site: Site) -> Array:
	return site.data.get("wares", [])


## D146: the wares laid out at once, up to `wares_on_show`, so buying is a choice among them.
## Of those, up to `food_on_show` are food when the place has any ([D403]): wares are stocked in
## the order `equipment.json` lists them, so the first three were always arms and the bread at
## the back of the list was never laid out, and nobody could buy a meal.
static func on_show(site: Site) -> Array:
	var count := maxi(1, int(rules().get("wares_on_show", 1)))
	var all := wares(site)
	var food: Array = all.filter(func(id: String) -> bool: return Gear.taken(id) == "eat") \
		.slice(0, mini(count, int(rules().get("food_on_show", 0))))
	var rest: Array = all.filter(func(id: String) -> bool: return not food.has(id))
	return rest.slice(0, count - food.size()) + food


## The ware in hand among those laid out, or "" when there is nothing to sell.
static func in_hand(site: Site) -> String:
	var shown := on_show(site)
	if shown.is_empty():
		return ""
	return str(shown[int(site.data.get("ware_at", 0)) % shown.size()])


## Turn to the next ware laid out.
static func next_ware(site: Site) -> void:
	site.data["ware_at"] = (int(site.data.get("ware_at", 0)) + 1) % maxi(1, on_show(site).size())


static func price_of(equipment_id: String) -> int:
	var piece := Database.equipment_piece(equipment_id)
	if piece.has("price"):
		return int(piece["price"])
	var worth := 40 + 30 * int(piece.get("attack", 0)) + 30 * int(piece.get("defense", 0))
	# A charm is priced on the life it buys, not the numbers it adds.
	return worth + roundi(float(piece.get("grace", 0.0)) * 400.0)


## What this particular place will ask, once they have heard who you are.
static func asking_price(site: Site, world: World, equipment_id: String) -> int:
	return maxi(1, roundi(
		price_of(equipment_id) * Renown.price_multiplier(world, site.cell) * Difficulty.dial("price")
	))


static func buy(site: Site, equipment_id: String, buyer: Character, world: World) -> bool:
	if equipment_id not in wares(site):
		return false
	var price := asking_price(site, world, equipment_id)
	if GameState.gold < price:
		return false
	GameState.gold -= price
	site.data["wares"].erase(equipment_id)

	if Database.equipment_piece(equipment_id).get("charm", false):
		buyer.charms.append(equipment_id)
	elif Gear.is_draught(equipment_id):
		# Food and physic go in the packs, not on the person who paid for it.
		GameState.stores.append(equipment_id)
	else:
		# Worn where it goes ([D357]); what it replaces goes in the packs, not on the floor.
		var displaced := Gear.put_on(buyer, equipment_id)
		if displaced != "":
			GameState.stores.append(displaced)
	return true


static func _roll_wares(world: World) -> Array:
	var stock: Array = []
	for equipment_id: String in Database.equipment.keys():
		# A weapon made for one of the sixteen is never for sale (M15).
		if Database.equipment[equipment_id].has("signature"):
			continue
		if world.rng.randf() < 0.5:
			stock.append(equipment_id)
	return stock


# --- people -------------------------------------------------------------------


static func hire_offer(site: Site) -> Dictionary:
	return site.data.get("hire", {})


static func hire_cost(offer: Dictionary) -> int:
	return int(rules().get("cost_base", 2000)) + int(rules().get("cost_per_level", 1000)) * int(offer.get("level", 1))


## What they will take to walk with you, knowing what they know about you.
static func asking_hire_cost(site: Site, world: World, offer: Dictionary) -> int:
	# Whoever is leading does the talking, and an outward temper talks a price
	# down (see `data/tempers.json`).
	var lead := GameState.roster.player() if GameState.roster != null else null
	var haggle := lead.lean("hire_price", 1.0) if lead != null else 1.0
	return maxi(1, roundi(
		hire_cost(offer) * Renown.price_multiplier(world, site.cell) * Difficulty.dial("price") * haggle
	))


## Take on whoever is drinking here. They join the roster and the party.
static func hire(site: Site, roster: Roster, world: World) -> Character:
	var offer := hire_offer(site)
	if offer.is_empty():
		return null
	var cost := asking_hire_cost(site, world, offer)
	if GameState.gold < cost or not roster.has_room():
		return null

	GameState.gold -= cost
	var recruit := Character.create(offer["template"], offer.get("display_name", ""))
	Progression.raise_quietly(recruit, int(offer.get("level", 1)), world)
	for member: Character in roster.party_members():
		var initial := Banter.initial_bond(member, recruit)
		member.bonds[recruit.id] = initial
		recruit.bonds[member.id] = initial
	roster.add(recruit)
	roster.enlist(recruit.id)
	Ledger.add(GameState.ledger, "recruited")
	site.data["hire"] = {}
	return recruit


static func _roll_hire(site: Site, world: World) -> Dictionary:
	if site.kind == Site.HUT or world.rng.randf() < 0.35:
		return {}
	var templates: Array = rules().get("templates", ["bram"])
	var template: String = templates[world.rng.randi() % templates.size()]
	var level := maxi(1, GameState.roster.player().level + world.rng.randi_range(-1, 1))
	return {
		"template": template,
		"display_name": Names.person(world, site.cell, world.rng),
		"level": level,
	}
