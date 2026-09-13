class_name Gifts
extends RefCounted
## What a character starts with because of who they were.
##
## Every authored piece of history may carry exactly one gift, drawn from a
## closed vocabulary so that an authoring session can never invent an effect the
## engine does not implement. Gifts are applied once, at [method Character.create],
## and are indistinguishable afterwards from anything else the character owns —
## a book read is just a book read.

## The only gift kinds that exist. Anything else is a typo and the validator
## says so (see `tests/wishlist_smoke_test.gd`).
const KINDS := ["doctrine", "item", "gold", "grudge", "hearth", "bond", "stat"]

## Where a `bond` gift waits between being handed out and the band existing.
const PENDING_BOND := "pending_bond"


## Settle any `bond` gift now that everyone is standing together: a gift of
## `{ "toward": "<hero id>", "warmth": 2 }` moves how those two start out, in
## both directions, because chemistry is not one-sided.
static func settle_bonds(characters: Array) -> void:
	for character: Character in characters:
		if not character.has_meta(PENDING_BOND):
			continue
		var intent: Dictionary = character.get_meta(PENDING_BOND)
		character.remove_meta(PENDING_BOND)
		var toward := str(intent.get("toward", ""))
		var warmth := int(intent.get("warmth", 0))
		if toward == "" or warmth == 0:
			continue
		for other: Character in characters:
			if other == character or other.template_id != toward:
				continue
			var settled := clampi(int(character.bonds.get(other.id, 0)) + warmth, -2, 2)
			character.bonds[other.id] = settled
			other.bonds[character.id] = settled


## Apply every gift on every piece of history this character carries.
static func endow(character: Character) -> void:
	for field: String in Character.TRAIT_POOLS:
		var gift: Dictionary = character.trait_data(field).get("gift", {})
		if not gift.is_empty():
			apply(character, gift)


## One gift. Unknown kinds are ignored rather than fatal — a half-written pool
## entry should not stop a run from starting.
static func apply(character: Character, gift: Dictionary) -> void:
	var kind := str(gift.get("kind", ""))
	var value: Variant = gift.get("value", null)
	match kind:
		"doctrine":
			var doctrine_id := str(value)
			if doctrine_id != "" and doctrine_id not in character.doctrine:
				character.doctrine.append(doctrine_id)
				character.doctrine_seen[doctrine_id] = 0
		"item":
			var item_id := str(value)
			if item_id == "":
				return
			# Charms are carried against the day they are spent; everything else
			# is gear, and gear is worn.
			if float(Database.equipment_piece(item_id).get("grace", 0.0)) > 0.0:
				if item_id not in character.charms:
					character.charms.append(item_id)
			elif character.equipment == "":
				character.equipment = item_id
		"gold":
			# Gold belongs to the run, not the person, so only the lead brings
			# it. Otherwise every hire would pay the company to take them on.
			if character.is_player:
				GameState.gold += int(value)
		"grudge":
			if character.grudge == "":
				character.grudge = str(value)
		"hearth":
			if character.hearth == "":
				character.hearth = str(value)
		"bond":
			# Somebody already owes them, or already cannot stand them. The
			# other party may not exist yet, so this is kept as an intent and
			# resolved once the whole band is standing (see [Roster]).
			if value is Dictionary:
				character.set_meta(PENDING_BOND, value)
		"stat":
			if value is Dictionary and value.has("max_hp"):
				character.hearth_vigour += int(value["max_hp"])
