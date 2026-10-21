extends RefCounted
## Making things ([D280], Ewan's play-test 7: "combine herbs together to make potions, upgrade
## weapons ... kind of like Skyrim ... you can buy weapons or you can make them in the
## blacksmith").
##
## Two kinds: **mixing**, herbs and draughts out of the packs into a stronger draught, anywhere,
## from the party screen, more for less by a fire, and simple gear forged by a smith out of things
## gathered on the land ([D346]); and **honing**, a smith working a weapon somebody carries a notch keener
## for coin, a notch at a time up to a most, kept on that person for that weapon. Recipes and prices
## live in `world_rules.json` → `crafting`. Loaded by path ([D41]). Pure logic: no nodes.


static func rules() -> Dictionary:
	return Database.world_rules.get("crafting", {})


# --- mixing -------------------------------------------------------------------


## Where a recipe is made ([D346]): anywhere (no `at`), by a fire, or by a smith.
const ANYWHERE := ""
const HEARTH := "hearth"
const SMITHY := "smithy"


## Every recipe: `{ makes, needs: { item: count }, at, fee }`.
static func recipes() -> Array:
	return rules().get("mix", [])


## The recipes that can be made at [param at] (ANYWHERE, HEARTH or SMITHY) and nowhere else.
static func recipes_at(at: String) -> Array:
	return recipes().filter(func(recipe: Dictionary) -> bool: return str(recipe.get("at", ANYWHERE)) == at)


## What the party screen can mix where the party stands: anywhere's, and a fire's beside one.
static func mixable_here(at_hearth: bool) -> Array:
	return recipes_at(ANYWHERE) + (recipes_at(HEARTH) if at_hearth else [])


## How many of [param item] the company has to make things with: in [param stores], and carried as
## a charm by any of the company (a rune's makings bought from a trader are pocketed as charms).
static func held(item: String, stores: Array) -> int:
	var count := stores.count(item)
	for character: Character in _company():
		count += character.charms.count(item)
	return count


static func _company() -> Array:
	return GameState.roster.party_members() if GameState.roster != null else []


## Take [param count] of [param item] out of [param stores], and what they do not hold off the
## company's charms.
static func _spend(item: String, count: int, stores: Array) -> void:
	for i in count:
		if stores.has(item):
			stores.erase(item)
			continue
		for character: Character in _company():
			if character.charms.has(item):
				character.charms.erase(item)
				break


static func _has_all(needs: Dictionary, stores: Array) -> bool:
	for item: String in needs:
		if held(item, stores) < int(needs[item]):
			return false
	return not needs.is_empty()


## Whether [param stores] hold everything [param recipe] needs.
static func can_mix(recipe: Dictionary, stores: Array) -> bool:
	if Database.equipment_piece(str(recipe.get("makes", ""))).is_empty():
		return false
	return _has_all(recipe.get("needs", {}), stores)


## Mix [param recipe] out of [param stores]: what it needs comes out, what it makes goes in.
## Returns the line to show, or "" when the packs are short.
static func mix(recipe: Dictionary, stores: Array) -> String:
	if not can_mix(recipe, stores):
		return ""
	var needs: Dictionary = recipe["needs"]
	for item: String in needs:
		_spend(item, int(needs[item]), stores)
	var makes := str(recipe["makes"])
	stores.append(makes)
	var said := "forged_line" if str(recipe.get("at", ANYWHERE)) == SMITHY else ("brewed_line" if str(recipe.get("at", ANYWHERE)) == HEARTH else "mixed_line")
	return str(rules().get(said, rules().get("mixed_line", "Mixed: {made}."))).replace("{made}", Gear.display_name(makes))


## What a smith asks for forging [param recipe] (its `fee`, through the difficulty's price dial).
static func fee(recipe: Dictionary) -> int:
	return maxi(0, roundi(float(recipe.get("fee", 0)) * Difficulty.dial("price")))


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


# --- enchanting ---------------------------------------------------------------


## Every enchantment ([D327], [D299] item 3; `crafting.enchant`): `{ id, display_name, description, effect,
## value, needs: { item: count } }`, its effect one of the fight's passive effects.
static func enchantments() -> Array:
	return rules().get("enchant", [])


static func enchantment(id: String) -> Dictionary:
	for each: Dictionary in enchantments():
		if str(each.get("id", "")) == id:
			return each
	return {}


## Whether [param character]'s weapon could take [param rune] from [param stores]: they carry one that
## strikes, it does not carry that rune already, and the packs hold what it needs.
static func can_enchant(character: Character, rune: Dictionary, stores: Array) -> bool:
	var weapon := character.equipment
	if weapon == "" or int(Gear.piece(weapon).get("attack", 0)) <= 0:
		return false
	if str(character.enchanted.get(weapon, "")) == str(rune.get("id", "")):
		return false
	return _has_all(rune.get("needs", {}), stores)


## Lay [param rune] on [param character]'s weapon, out of [param stores]: what it needs comes out, and
## any rune the weapon had is gone (one a weapon). Returns the line to show, or "" when it cannot.
static func enchant(character: Character, rune: Dictionary, stores: Array) -> String:
	if not can_enchant(character, rune, stores):
		return ""
	var needs: Dictionary = rune["needs"]
	for item: String in needs:
		_spend(item, int(needs[item]), stores)
	var weapon := character.equipment
	var had := str(character.enchanted.get(weapon, ""))
	character.enchanted[weapon] = str(rune["id"])
	var line := str(rules().get("enchanted_line", "{name}'s {weapon} takes the {rune}.")).format({
		"name": character.display_name, "weapon": Gear.display_name(weapon), "rune": str(rune.get("display_name", "")),
	})
	if had != "":
		line += " " + str(rules().get("replaced_line", "The {old} is gone from it.")).format(
				{ "old": str(enchantment(had).get("display_name", had)) })
	return line


## How the rune reads on a button: "Keen Rune (+10% to land a critical hit), from 1 Whetstone and 2 Bitter Herbs".
static func enchantment_text(rune: Dictionary) -> String:
	var parts: Array = []
	var needs: Dictionary = rune.get("needs", {})
	for item: String in needs:
		parts.append("%d %s" % [int(needs[item]), Gear.display_name(item)])
	return "%s (%s), from %s" % [str(rune.get("display_name", "")), str(rune.get("description", "")), " and ".join(parts)]


## The fight's passive the rune on [param character]'s weapon gives while they carry it, or empty.
static func rune_passive(character: Character) -> Dictionary:
	if character == null or character.equipment == "":
		return {}
	var rune := enchantment(str(character.enchanted.get(character.equipment, "")))
	if rune.is_empty():
		return {}
	return { "id": "rune_" + str(rune.get("id", "")), "display_name": rune.get("display_name", ""), "description": rune.get("description", ""),
		"effect": rune.get("effect", ""), "value": rune.get("value", 0.0), "rune": true }
