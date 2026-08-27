class_name Fate
extends RefCounted
## What happens when a character falls.
##
## Death is the default. Everything else has to be *earned* by something you
## brought with you — a charm, an ally still standing, something you read, the
## ground you chose to fall on, or an enemy with a use for prisoners.
##
## Graces are rolled in order and the first to land claims the moment, so the
## reason a character lived is always a specific, tellable thing.

const DEAD := "dead"
const CAPTURED := "captured"
const ALIVE := "alive"

## Why a character walked away. Ordered by how good a story it makes.
const BY_CHARM := "charm"
const BY_RESCUE := "rescue"
const BY_LORE := "lore"
const BY_GROUND := "ground"
const BY_LUCK := "luck"
const BY_CAPTURE := "capture"


## Every reason this character might not die, with its chance and its story.
## [param context] may carry: allies (Array[Character]), enemy_kind (String),
## world (World), cell (Vector2i).
static func graces_for(character: Character, context: Dictionary) -> Array:
	var rules := Database.fate
	var graces: Array = []

	for charm_id: String in character.charms:
		var charm := Database.equipment_piece(charm_id)
		var chance := float(charm.get("grace", 0.0))
		if chance > 0.0:
			graces.append({
				"reason": BY_CHARM,
				"chance": chance,
				"detail": charm.get("display_name", charm_id),
				"consumes": charm_id,
			})

	var standing: Array = context.get("allies", []).filter(
		func(other: Character) -> bool: return other != character and other.is_alive()
	)
	if not standing.is_empty():
		var per_ally := float(rules.get("ally_rescue_per_ally", 0.12))
		var rescuer: Character = standing[0]
		graces.append({
			"reason": BY_RESCUE,
			"chance": minf(per_ally * standing.size(), float(rules.get("ally_rescue_cap", 0.36))),
			"detail": rescuer.display_name,
		})

	var lore := Doctrine.grace(character)
	if lore > 0.0:
		graces.append({
			"reason": BY_LORE,
			"chance": lore,
			"detail": Doctrine.title(Doctrine.most_useful_grace(character)),
		})

	var world: World = context.get("world", null)
	if world != null:
		var cell: Vector2i = context.get("cell", world.player_cell)
		if world.distance_to_haven(cell) <= int(rules.get("haven_range", 6)):
			graces.append({
				"reason": BY_GROUND,
				"chance": float(rules.get("haven_grace", 0.15)),
				"detail": "close enough to a hearth to crawl there",
			})

	graces.append({
		"reason": BY_LUCK,
		"chance": float(rules.get("base_luck", 0.07)),
		"detail": "no reason at all",
	})

	# Being taken alive is the last thing between a character and the ground.
	var capture := float(
		rules.get("capture_by", {}).get(context.get("enemy_kind", "default"), rules.get("capture_by", {}).get("default", 0.15))
	)
	if capture > 0.0:
		graces.append({ "reason": BY_CAPTURE, "chance": capture, "detail": context.get("enemy_kind", "someone") })

	return graces


## Decide a fallen character's fate and apply it. Returns the outcome plus a
## line for the log.
static func resolve(character: Character, context: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	for grace: Dictionary in graces_for(character, context):
		if rng.randf() >= float(grace["chance"]):
			continue
		if grace.has("consumes"):
			character.charms.erase(grace["consumes"])
		return _apply(character, grace, context)

	character.status = DEAD
	character.hp = 0
	return {
		"outcome": DEAD,
		"reason": "",
		"line": "%s falls, and does not get up." % character.display_name,
	}


static func _apply(character: Character, grace: Dictionary, context: Dictionary) -> Dictionary:
	var rules := Database.fate
	var reason: String = grace["reason"]

	if reason == BY_CAPTURE:
		character.status = CAPTURED
		character.hp = maxi(1, roundi(character.max_hp() * float(rules.get("capture_recovery", 0.1))))
		var world: World = context.get("world", null)
		Captivity.take(character, world, _nearest_stronghold(world, context.get("cell", Vector2i.ZERO)))
		return {
			"outcome": CAPTURED,
			"reason": reason,
			"line": "%s is taken alive, and dragged towards %s." % [character.display_name, character.captured_at],
		}

	character.status = ALIVE
	character.hp = maxi(1, roundi(character.max_hp() * float(rules.get("escape_recovery", 0.25))))
	return {
		"outcome": ALIVE,
		"reason": reason,
		"line": _escape_line(character, grace),
	}


static func _escape_line(character: Character, grace: Dictionary) -> String:
	var who := character.display_name
	var detail: String = grace.get("detail", "")
	match grace["reason"]:
		BY_CHARM:
			return "%s should have died. The %s went cold instead." % [who, detail]
		BY_RESCUE:
			return "%s goes down — and %s drags them out of it." % [who, detail]
		BY_LORE:
			return "%s lives, because they had read %s." % [who, detail]
		BY_GROUND:
			return "%s crawls off the field: %s." % [who, detail]
	return "%s lives, for %s." % [who, detail]


static func _nearest_stronghold(world: World, cell: Vector2i) -> Site:
	if world == null:
		return null
	var best: Site = null
	for site in world.sites:
		if site.kind != Site.KEEP and site.kind != Site.GATE:
			continue
		if best == null or Pathfinder.distance(site.cell, cell) < Pathfinder.distance(best.cell, cell):
			best = site
	return best
