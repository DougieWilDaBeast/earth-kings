class_name Market
extends RefCounted
## What a town is for: gear to buy, and people willing to walk with you.
##
## Parties are temporary. Everyone here is looking out for themselves, and the
## price reflects it.

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


static func price_of(equipment_id: String) -> int:
	var piece := Database.equipment_piece(equipment_id)
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
	else:
		buyer.equipment = equipment_id
	return true


static func _roll_wares(world: World) -> Array:
	var stock: Array = []
	for equipment_id: String in Database.equipment.keys():
		if world.rng.randf() < 0.5:
			stock.append(equipment_id)
	return stock


# --- people -------------------------------------------------------------------


static func hire_offer(site: Site) -> Dictionary:
	return site.data.get("hire", {})


static func hire_cost(offer: Dictionary) -> int:
	return int(rules().get("cost_base", 70)) + int(rules().get("cost_per_level", 35)) * int(offer.get("level", 1))


## What they will take to walk with you, knowing what they know about you.
static func asking_hire_cost(site: Site, world: World, offer: Dictionary) -> int:
	return maxi(1, roundi(
		hire_cost(offer) * Renown.price_multiplier(world, site.cell) * Difficulty.dial("price")
	))


## Take on whoever is drinking here. They join the roster and the party.
static func hire(site: Site, roster: Roster, world: World) -> Character:
	var offer := hire_offer(site)
	if offer.is_empty():
		return null
	var cost := asking_hire_cost(site, world, offer)
	if GameState.gold < cost or roster.party.size() >= Roster.MAX_PARTY:
		return null

	GameState.gold -= cost
	var recruit := Character.create(offer["template"], offer.get("display_name", ""))
	Progression.raise_quietly(recruit, int(offer.get("level", 1)), world)
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
		"display_name": WorldGen.person_name(world.rng),
		"level": level,
	}
