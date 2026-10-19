extends RefCounted
## Making things ([D280], Ewan's play-test 7: "combine herbs together to make potions, upgrade
## weapons ... kind of like Skyrim ... you can buy weapons or you can make them in the
## blacksmith").
##
## Two kinds: **mixing**, herbs and draughts out of the packs into a stronger draught, anywhere,
## from the party screen; and **honing**, a smith working a weapon somebody carries a notch keener
## for coin, a notch at a time up to a most, kept on that person for that weapon. Recipes and prices
## live in `world_rules.json` → `crafting`. Loaded by path ([D41]). Pure logic: no nodes.


static func rules() -> Dictionary:
	return Database.world_rules.get("crafting", {})


# --- mixing -------------------------------------------------------------------


## Every recipe: `{ makes, needs: { item: count } }`.
static func recipes() -> Array:
	return rules().get("mix", [])


## Whether [param stores] hold everything [param recipe] needs.
static func can_mix(recipe: Dictionary, stores: Array) -> bool:
	var needs: Dictionary = recipe.get("needs", {})
	if needs.is_empty() or Database.equipment_piece(str(recipe.get("makes", ""))).is_empty():
		return false
	for item: String in needs:
		if stores.count(item) < int(needs[item]):
			return false
	return true


## Mix [param recipe] out of [param stores]: what it needs comes out, what it makes goes in.
## Returns the line to show, or "" when the packs are short.
static func mix(recipe: Dictionary, stores: Array) -> String:
	if not can_mix(recipe, stores):
		return ""
	var needs: Dictionary = recipe["needs"]
	for item: String in needs:
		for i in int(needs[item]):
			stores.erase(item)
	var makes := str(recipe["makes"])
	stores.append(makes)
	return str(rules().get("mixed_line", "Mixed: {made}.")).replace("{made}", Gear.display_name(makes))


## How the recipe reads on a button: "Red Draught, from 3 Bitter Herbs".
static func recipe_text(recipe: Dictionary) -> String:
	var parts: Array = []
	var needs: Dictionary = recipe.get("needs", {})
	for item: String in needs:
		parts.append("%d %s" % [int(needs[item]), Gear.display_name(item)])
	return "%s, from %s" % [Gear.display_name(str(recipe.get("makes", ""))), " and ".join(parts)]


# --- honing -------------------------------------------------------------------


## Whether [param character]'s weapon could take another notch: they carry one that strikes, and it
## is not yet at the most.
static func can_hone(character: Character) -> bool:
	var weapon := character.equipment
	if weapon == "" or int(Gear.piece(weapon).get("attack", 0)) <= 0:
		return false
	return int(character.honed.get(weapon, 0)) < int(rules().get("hone_most", 3))


## What the next notch costs: dearer each time, and dearer for a dearer weapon.
static func hone_price(character: Character) -> int:
	var r := rules()
	var notch := int(character.honed.get(character.equipment, 0)) + 1
	var worth := int(Gear.piece(character.equipment).get("price", 2000))
	return maxi(1, roundi((float(r.get("hone_base", 800)) + float(worth) * float(r.get("hone_share", 0.25))) \
		* float(notch) * Difficulty.dial("price")))


## Hone [param character]'s weapon one notch. Returns the line to show.
static func hone(character: Character) -> String:
	if not can_hone(character):
		return ""
	var weapon := character.equipment
	character.honed[weapon] = int(character.honed.get(weapon, 0)) + 1
	return str(rules().get("honed_line", "{name}'s {weapon} comes back keener (+{notch}).")).format({
		"name": character.display_name, "weapon": Gear.display_name(weapon), "notch": character.honed[weapon],
	})
