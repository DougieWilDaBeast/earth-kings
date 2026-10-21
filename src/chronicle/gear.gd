class_name Gear
extends RefCounted
## What a piece of equipment is actually worth to the person holding it.
##
## A sword in the wrong hands is still a sword, but it is not the same sword.
## Every piece names the callings it `suits`; anyone else carries it at a
## penalty, so picking up the best numbers on the field is not automatically
## the right answer. A piece that names nobody suits everybody.
##
## Pure logic over `data/equipment.json`. Nothing here reads [GameState].

## How much of a piece's bonus survives being carried by the wrong person.
const MISFIT_SHARE := 0.4
## And what it costs on top, for a piece badly out of its calling.
const MISFIT_PENALTY := 2

const Hunger := preload("res://src/chronicle/hunger.gd")

static var _icons: Dictionary = {}


static func piece(equipment_id: String) -> Dictionary:
	return Database.equipment_piece(equipment_id)


static func display_name(equipment_id: String) -> String:
	return str(piece(equipment_id).get("display_name", equipment_id))


static func is_charm(equipment_id: String) -> bool:
	return bool(piece(equipment_id).get("charm", false))


## Something drunk or eaten rather than carried about: it is spent when used.
static func is_draught(equipment_id: String) -> bool:
	return kind(equipment_id) == "draught"


## Food is eaten and a draught drunk (`taken` in the data, "drink" when it is not said):
## Ewan's play-test 8 was offered a meat pie to drink.
static func taken(equipment_id: String) -> String:
	return str(piece(equipment_id).get("taken", "drink"))


## "eats" or "drinks", for a line about somebody taking it.
static func takes(equipment_id: String) -> String:
	return "eats" if taken(equipment_id) == "eat" else "drinks"


static func mends(equipment_id: String) -> int:
	return int(piece(equipment_id).get("mends", 0))


## Drink it. Returns the line worth showing, or an empty string if there was no
## point — nothing is spent on somebody who is already whole.
static func drink(character: Character, equipment_id: String) -> String:
	if not is_draught(equipment_id) or not GameState.stores.has(equipment_id):
		return ""
	# Food is worth eating whole when hungry ([D331]).
	var feeds := Hunger.feeds(equipment_id) if Hunger.on() else 0.0
	if character.current_hp() >= character.max_hp() and (feeds <= 0.0 or not Hunger.is_hungry(character)):
		return ""
	GameState.stores.erase(equipment_id)
	var before := character.current_hp()
	character.hp = mini(before + mends(equipment_id), character.max_hp())
	character.fed = minf(1.0, character.fed + feeds)
	if character.current_hp() == before:
		return "%s %s the %s." % [character.display_name, takes(equipment_id), display_name(equipment_id)]
	return "%s %s the %s and comes back %d." % [
		character.display_name, takes(equipment_id), display_name(equipment_id), character.current_hp() - before
	]


## Draughts in the packs, weakest first, so the small one is spent on a scratch.
static func draughts() -> Array:
	var out: Array = []
	for equipment_id: String in GameState.stores:
		if is_draught(equipment_id) and not out.has(equipment_id):
			out.append(equipment_id)
	out.sort_custom(func(a: String, b: String) -> bool: return mends(a) < mends(b))
	return out


## What kind of thing it is: blade, bow, staff, armour, charm. Used for grouping
## and for saying what somebody is short of.
static func kind(equipment_id: String) -> String:
	return str(piece(equipment_id).get("kind", "gear"))


## The picture of it, or null. Cached, because a texture first loaded part-way
## through a draw pass comes out white.
static func icon(equipment_id: String) -> Texture2D:
	if _icons.has(equipment_id):
		return _icons[equipment_id]
	var name_ := str(piece(equipment_id).get("icon", ""))
	var path := "res://art/items/%s.png" % name_
	_icons[equipment_id] = load(path) if name_ != "" and ResourceLoader.exists(path) else null
	return _icons[equipment_id]


## Does this piece belong in this person's hands? A piece with no `suits` list
## is plain enough that anybody can use it. Somebody who has not chosen a
## calling yet is judged on the ones they could still take, so a level-one
## swordsman is not penalised for carrying a sword.
##
## A weapon made for one of the sixteen (`signature`) suits nobody, not even
## the copy of the one it was made for: god-tier, and nobody is proficient with
## it (M15, [D33]).
static func suits(equipment_id: String, character: Character) -> bool:
	if piece(equipment_id).has("signature"):
		return false
	var callings: Array = piece(equipment_id).get("suits", [])
	if callings.is_empty():
		return true
	if callings.has(character.template_id):
		return true
	if character.class_id != "":
		return callings.has(character.class_id)
	for possible: String in Database.unit_template(character.template_id).get("classes", []):
		if callings.has(possible):
			return true
	return false


## Attack and defence this piece gives [param character], fit already applied.
static func bonus(equipment_id: String, character: Character) -> Dictionary:
	var data := piece(equipment_id)
	if data.is_empty() or bool(data.get("charm", false)) or is_draught(equipment_id):
		return { "attack": 0, "defense": 0 }
	var attack := int(data.get("attack", 0))
	var defense := int(data.get("defense", 0))
	# A smith's notches on this weapon, for whoever had it honed (D280).
	if attack > 0 and character != null:
		attack += int(character.honed.get(equipment_id, 0))
	if suits(equipment_id, character):
		return { "attack": attack, "defense": defense }
	return {
		"attack": _misfit(attack),
		"defense": _misfit(defense),
	}


## Armour is worn as well as a weapon is held ([D357]): a coat, a shirt of scales, a helm.
const ARMOUR := "armour"
## The two places a piece goes on somebody ([D357]).
const WEAPON_SLOT := "weapon"
const ARMOUR_SLOT := "armour"


static func is_armour(equipment_id: String) -> bool:
	return kind(equipment_id) == ARMOUR


## Which of the two places [param equipment_id] goes: on the body, or in the hand.
static func slot_of(equipment_id: String) -> String:
	return ARMOUR_SLOT if is_armour(equipment_id) else WEAPON_SLOT


## What [param character] has in [param slot] now ("" for nothing handed out).
static func worn_in(character: Character, slot: String) -> String:
	return character.armour if slot == ARMOUR_SLOT else character.equipment


## Put [param equipment_id] where it goes on [param character], and say what was there before ("" for
## nothing), so the caller can put it in the packs.
static func put_on(character: Character, equipment_id: String) -> String:
	var displaced := worn_in(character, slot_of(equipment_id))
	if slot_of(equipment_id) == ARMOUR_SLOT:
		character.armour = equipment_id
	else:
		character.equipment = equipment_id
	return displaced


## The one number used to compare two pieces for one person.
static func worth(equipment_id: String, character: Character) -> int:
	var gain := bonus(equipment_id, character)
	return int(gain["attack"]) + int(gain["defense"])


## What swapping to this piece would do, measured against whatever they are
## fighting with now rather than against an empty hand.
static func swing(equipment_id: String, character: Character) -> int:
	if slot_of(equipment_id) == ARMOUR_SLOT:
		return worth(equipment_id, character) - (worth(character.armour, character) if character.armour != "" else 0)
	return worth(equipment_id, character) - _in_hand_worth(character)


## What the weapon in their hand is worth, the one they came with when none has been handed out.
static func _in_hand_worth(character: Character) -> int:
	var gain := bonus(character.equipment, character) if character.equipment != "" else _issued(character)
	return int(gain["attack"]) + int(gain["defense"])


## What [param character] already fights with: the piece handed out, or the one
## their template came issued with when nothing has been. The lead walks out of
## the first scene holding a bone sword nobody gave him, and a swap measured
## against an empty hand reads better than it fights.
static func carried(character: Character) -> Dictionary:
	var gain := bonus(character.equipment, character) if character.equipment != "" else _issued(character)
	if character.armour != "":
		var worn := bonus(character.armour, character)
		return { "attack": int(gain["attack"]) + int(worn["attack"]), "defense": int(gain["defense"]) + int(worn["defense"]) }
	return gain


## The one number that stands for whatever they are fighting with now.
static func carried_worth(character: Character) -> int:
	var gain := carried(character)
	return int(gain["attack"]) + int(gain["defense"])


## The numbers [param character] would actually take onto the field carrying
## [param equipment_id] — the same sum [method Unit.from_character] makes, so
## the equip menu shows the figures the fight will use rather than a guess.
## Pass an empty id to ask what they are worth carrying nothing.
##
## The piece goes where it goes ([D357]): armour on the body with the weapon they hold kept, a weapon
## in the hand with what they wear kept.
static func fielded(character: Character, equipment_id: String) -> Dictionary:
	var in_hand := equipment_id if equipment_id != "" and slot_of(equipment_id) == WEAPON_SLOT else (
			character.equipment if equipment_id != "" else "")
	var worn := equipment_id if equipment_id != "" and slot_of(equipment_id) == ARMOUR_SLOT else character.armour
	var hand := bonus(in_hand, character) if in_hand != "" else _issued(character)
	var body := bonus(worn, character) if worn != "" else { "attack": 0, "defense": 0 }
	return {
		"attack": character.attack() + int(hand.get("attack", 0)) + int(body.get("attack", 0)),
		"defense": character.defense() + int(hand.get("defense", 0)) + int(body.get("defense", 0)),
	}


## The numbers [param character] takes onto the field as they stand now, weapon and armour.
static func fielded_now(character: Character) -> Dictionary:
	var gain := carried(character)
	return {
		"attack": character.attack() + int(gain.get("attack", 0)),
		"defense": character.defense() + int(gain.get("defense", 0)),
	}


## The best piece in the packs for [param character], or an empty string when
## nothing in there would be an improvement. One press, one answer — the menu
## still shows the whole list for anybody who disagrees with it.
static func best_offer(character: Character) -> String:
	var ranked := offers(character)
	if ranked.is_empty():
		return ""
	var best: String = ranked[0]
	return best if swing(best, character) > 0 else ""


## Hand somebody the best thing in the packs. False when nothing in there beats
## what they are already fighting with.
##
## The best for the hand and the best for the body, each against what is there now ([D357]).
static func optimise(character: Character) -> bool:
	var took := false
	for slot: String in [WEAPON_SLOT, ARMOUR_SLOT]:
		var ranked := offers(character, slot)
		if not ranked.is_empty() and swing(ranked[0], character) > 0:
			took = equip(character, ranked[0]) or took
	return took


## A short line for the party screen: what it gives, and whether it fits.
static func summary(equipment_id: String, character: Character) -> String:
	if is_draught(equipment_id):
		return "mends %d  —  %s" % [
			mends(equipment_id), piece(equipment_id).get("text", "")
		]
	if is_charm(equipment_id):
		return str(piece(equipment_id).get("text", "Carried, not worn."))
	var gain := bonus(equipment_id, character)
	var parts: Array[String] = []
	if int(gain["attack"]) != 0:
		parts.append("%+d attack" % int(gain["attack"]))
	if int(gain["defense"]) != 0:
		parts.append("%+d guard" % int(gain["defense"]))
	if parts.is_empty():
		parts.append("no help at all")
	if not suits(equipment_id, character):
		parts.append("wrong hands")
	return ", ".join(parts)


## Hand a piece out of the party's stores to somebody. Whatever they were
## carrying goes back in, so nothing is ever thrown away by equipping.
static func equip(character: Character, equipment_id: String) -> bool:
	if not GameState.stores.has(equipment_id) or is_charm(equipment_id) or is_draught(equipment_id):
		return false
	GameState.stores.erase(equipment_id)
	var displaced := put_on(character, equipment_id)
	if displaced != "":
		GameState.stores.append(displaced)
	return true


## Take what somebody is carrying (or, with [param slot] `armour`, wearing) off them and put it in the
## packs.
static func unequip(character: Character, slot: String = WEAPON_SLOT) -> bool:
	var had := worn_in(character, slot)
	if had == "":
		return false
	GameState.stores.append(had)
	if slot == ARMOUR_SLOT:
		character.armour = ""
	else:
		character.equipment = ""
	return true


## What is in the packs that would suit [param character] better than what they
## already have, best first; with [param slot], only what goes there ([D357]).
static func offers(character: Character, slot: String = "") -> Array:
	var out: Array = []
	for equipment_id: String in GameState.stores:
		if is_charm(equipment_id) or is_draught(equipment_id) or kind(equipment_id) == "making" or out.has(equipment_id):
			continue
		if slot == "" or slot_of(equipment_id) == slot:
			out.append(equipment_id)
	out.sort_custom(func(a: String, b: String) -> bool:
		return swing(a, character) > swing(b, character)
	)
	return out


## What a template comes issued with — a blade the unit was drawn holding, and
## fights with until something better is handed out. It is not in the packs and
## cannot be stowed: it can only be outclassed.
static func issued_id(character: Character) -> String:
	return str(Database.unit_template(character.template_id).get("weapon", ""))


## The same piece as numbers. The field counts it, so the menu counts it too.
static func _issued(character: Character) -> Dictionary:
	var weapon := issued_id(character)
	if weapon == "":
		return { "attack": 0, "defense": 0 }
	var data := piece(weapon)
	return {
		"attack": int(data.get("attack", 0)),
		"defense": int(data.get("defense", 0)),
	}


static func _misfit(value: int) -> int:
	if value <= 0:
		return value
	return roundi(value * MISFIT_SHARE) - MISFIT_PENALTY
