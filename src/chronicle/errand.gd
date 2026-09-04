class_name Errand
extends RefCounted
## Small jobs posted where people live.
##
## These are not quests. Nobody is saving the world with them — they are rings
## lost in reeds, letters nine years late, and a tree somebody planted once and
## would like to know is still standing. They are worth doing because walking
## somewhere is the only thing that costs anything here.
##
## Errands never expire. The people who post them are used to waiting.

const FETCH := "fetch"
const DELIVER := "deliver"
const CULL := "cull"
const LOOK := "look"
const BOUNTY := "bounty"


static func rules() -> Dictionary:
	return Database.errands


static func max_accepted() -> int:
	return int(rules().get("max_accepted", 3))


# --- the board ----------------------------------------------------------------


static func board(site: Site) -> Dictionary:
	return site.data.get("errand", {})


## Put something on the board if it is bare. Called when a settlement restocks.
static func refresh(site: Site, world: World) -> void:
	if not _is_settlement(site):
		return
	if not board(site).is_empty():
		return
	site.data["errand"] = _compose(site, world)


## Take the job. Returns the accepted errand, or empty if there was nothing to
## take or no room to take it.
static func accept(site: Site, accepted: Array, world: World) -> Dictionary:
	var offer := board(site)
	if offer.is_empty() or accepted.size() >= max_accepted():
		return {}
	site.data["errand"] = {}
	offer["posted_at"] = world.steps
	accepted.append(offer)
	return offer


# --- walking them -------------------------------------------------------------

## Notices raised by standing on [param cell]. Errands that finish where they
## are pointing finish here; the rest are only marked.
static func on_arrive(accepted: Array, cell: Vector2i, world: World) -> Array[String]:
	var lines: Array[String] = []
	for errand: Dictionary in accepted.duplicate():
		if _cell_of(errand.get("to", [])) != cell:
			continue
		match errand.get("kind", FETCH):
			FETCH:
				if errand.get("reached", false):
					continue
				errand["reached"] = true
				lines.append("You have what %s asked for." % errand.get("giver", "someone"))
			LOOK:
				lines.append(_seen_line(errand, world))
				# Going somewhere for no reason is how the useless spells get found.
				lines.append_array(Trivia.maybe_discover(world, "discovery_chance_look"))
				lines.append_array(_settle(accepted, errand, world))
			DELIVER:
				lines.append("Handed over at %s, as promised." % errand.get("to_name", "the door"))
				lines.append_array(_settle(accepted, errand, world))
	return lines


## Count a kill towards any cull or bounty that wants it.
static func record_kill(accepted: Array, template_id: String) -> void:
	for errand: Dictionary in accepted:
		var kind: String = errand.get("kind", "")
		if (kind == CULL or kind == BOUNTY) and errand.get("target", "") == template_id:
			errand["done"] = int(errand.get("done", 0)) + 1


static func is_complete(errand: Dictionary) -> bool:
	match errand.get("kind", FETCH):
		FETCH:
			return bool(errand.get("reached", false))
		CULL, BOUNTY:
			return int(errand.get("done", 0)) >= int(errand.get("count", 1))
	return false


## An errand that can be handed back where the party is standing.
static func completable_at(accepted: Array, cell: Vector2i) -> Dictionary:
	for errand: Dictionary in accepted:
		if _cell_of(errand.get("from", [])) == cell and is_complete(errand):
			return errand
	return {}


static func turn_in(accepted: Array, errand: Dictionary, world: World) -> Array[String]:
	if not is_complete(errand):
		return []
	var lines: Array[String] = ["\"%s\" is settled." % errand.get("title", "The errand")]
	lines.append_array(_settle(accepted, errand, world))
	return lines


# --- reading them -------------------------------------------------------------


static func summary(errand: Dictionary) -> String:
	if errand.is_empty():
		return ""
	return "%s — %s" % [errand.get("title", "An errand"), progress(errand)]


static func progress(errand: Dictionary) -> String:
	match errand.get("kind", FETCH):
		CULL:
			return "%d of %d" % [int(errand.get("done", 0)), int(errand.get("count", 1))]
		BOUNTY:
			return "claimed" if is_complete(errand) else "slay %s" % errand.get("target_name", "the fugitive")
		FETCH:
			if errand.get("reached", false):
				return "carry it back to %s" % errand.get("from_name", "the village")
			return "at %s" % errand.get("to_name", "somewhere")
		_:
			return "to %s" % errand.get("to_name", "somewhere")


static func detail(errand: Dictionary) -> String:
	return "%s  (%d gold)" % [errand.get("text", ""), int(errand.get("gold", 0))]


# --- composition --------------------------------------------------------------


static func _compose(site: Site, world: World) -> Dictionary:
	var kinds := [FETCH, LOOK, CULL]
	if world.sites.any(func(s: Site) -> bool: return _is_settlement(s) and s.cell != site.cell):
		kinds.append(DELIVER)
	if not world.prowlers.is_empty():
		kinds.append(BOUNTY)
	var kind: String = kinds[world.rng.randi() % kinds.size()]

	var errand := {
		"kind": kind,
		"giver": "%s %s" % [
			WorldGen.person_name(world.rng),
			rules().get("trades", ["of the village"])[world.rng.randi() % rules().get("trades", ["x"]).size()],
		],
		"from": [site.cell.x, site.cell.y],
		"from_name": site.display_name,
		"done": 0,
		"reached": false,
	}

	match kind:
		CULL:
			_compose_cull(errand, site, world)
		BOUNTY:
			_compose_bounty(errand, site, world)
		DELIVER:
			_compose_deliver(errand, site, world)
		_:
			_compose_journey(errand, kind, site, world)

	if world.rng.randf() < float(rules().get("doctrine_chance", 0.18)):
		errand["doctrine"] = Database.doctrine_ids()[world.rng.randi() % Database.doctrine_ids().size()]
	return errand


static func _compose_bounty(errand: Dictionary, site: Site, world: World) -> void:
	var band: Prowler = world.prowlers[world.rng.randi() % world.prowlers.size()]
	var target: String = band.units[band.units.size() - 1] if not band.units.is_empty() else "brigand"
	var target_name: String = str(Database.unit_template(target).get("display_name", target))
	errand["target"] = target
	errand["target_name"] = target_name
	errand["count"] = 1
	errand["title"] = "Bounty: %s" % target_name
	errand["text"] = "A dangerous %s has been prowling near %s. Slay it for the bounty." % [
		target_name, site.display_name
	]
	errand["gold"] = int(rules().get("bounty_reward", 130))


static func _compose_cull(errand: Dictionary, site: Site, world: World) -> void:
	var pool: Array = Database.encounters.get("wild", {}).get(world.terrain_id_at(site.cell), ["wolf"])
	var target: String = pool[world.rng.randi() % pool.size()]
	var count := world.rng.randi_range(2, 5)
	var flavour := _flavour(CULL, world)
	errand["target"] = target
	errand["count"] = count
	errand["title"] = flavour.get("title", "Bad neighbours")
	errand["text"] = flavour.get("text", "").format({
		"count": count,
		"target": Database.unit_template(target).get("display_name", target).to_lower(),
	})
	errand["gold"] = count * int(rules().get("cull_reward_per_head", 30))


static func _compose_deliver(errand: Dictionary, site: Site, world: World) -> void:
	var elsewhere: Array = world.sites.filter(
		func(s: Site) -> bool: return _is_settlement(s) and s.cell != site.cell
	)
	var destination: Site = elsewhere[world.rng.randi() % elsewhere.size()]
	_point_at(errand, destination.cell, destination.display_name, site, world)
	_dress(errand, DELIVER, world)


static func _compose_journey(errand: Dictionary, kind: String, site: Site, world: World) -> void:
	var cell := _somewhere_out_there(site.cell, world)
	_point_at(errand, cell, WorldGen.wild_name(world.rng), site, world)
	_dress(errand, kind, world)


static func _point_at(errand: Dictionary, cell: Vector2i, place: String, site: Site, world: World) -> void:
	errand["to"] = [cell.x, cell.y]
	errand["to_name"] = place
	var walk := Pathfinder.distance(site.cell, cell)
	# Paid for the walking, because the walking is what it costs.
	errand["gold"] = int(rules().get("reward_base", 40)) + walk * int(rules().get("reward_per_distance", 3))
	if errand.get("kind", "") == LOOK:
		errand["gold"] = roundi(float(errand["gold"]) * 0.6)


static func _dress(errand: Dictionary, kind: String, world: World) -> void:
	var flavour := _flavour(kind, world)
	var place: String = errand.get("to_name", "somewhere")
	errand["title"] = flavour.get("title", "An errand").format({"place": place})
	errand["text"] = flavour.get("text", "").format({"place": place})


static func _flavour(kind: String, world: World) -> Dictionary:
	var pool: Array = rules().get(kind, [])
	if pool.is_empty():
		return {}
	return pool[world.rng.randi() % pool.size()]


## Somewhere far enough to be a journey and empty enough to be nowhere.
static func _somewhere_out_there(from: Vector2i, world: World) -> Vector2i:
	var near := int(rules().get("min_distance", 5))
	var far := int(rules().get("max_distance", 18))
	for _attempt in 60:
		var cell := Vector2i(world.rng.randi() % world.size.x, world.rng.randi() % world.size.y)
		if not world.is_walkable(cell) or world.site_at(cell) != null:
			continue
		var walk := Pathfinder.distance(from, cell)
		if walk >= near and walk <= far:
			return cell
	return from


static func _settle(accepted: Array, errand: Dictionary, world: World) -> Array[String]:
	accepted.erase(errand)
	var lines: Array[String] = []
	var gold := int(errand.get("gold", 0))
	GameState.gold += gold
	Ledger.add(GameState.ledger, "errands_done")
	lines.append("%d gold, and the thanks of %s." % [gold, errand.get("giver", "someone")])

	if errand.get("kind", "") == BOUNTY:
		Renown.record(
			world, "bounty_claimed", world.player_cell, 3,
			"claimed the bounty on %s" % str(errand.get("target_name", "a prowler"))
		)
		lines.append("Word spreads of your deed. (+3 Renown)")

	var doctrine_id: String = errand.get("doctrine", "")
	if doctrine_id == "":
		return lines
	# The attic book nobody in the family could read.
	for character in GameState.party_characters():
		if Doctrine.learn(character, doctrine_id, world.steps):
			lines.append("They press a book on you. %s reads %s." % [
				character.display_name, Doctrine.title(doctrine_id)
			])
			break
	return lines


static func _seen_line(errand: Dictionary, world: World) -> String:
	var pool: Array = rules().get("seen", ["You stand a while at {place}."])
	var line: String = pool[world.rng.randi() % pool.size()]
	return line.format({"place": errand.get("to_name", "the place")})


static func _is_settlement(site: Site) -> bool:
	return site.kind == Site.VILLAGE or site.kind == Site.KEEP or site.kind == Site.HUT


static func _cell_of(pair: Array) -> Vector2i:
	if pair.size() < 2:
		return Vector2i(-1, -1)
	return Vector2i(int(pair[0]), int(pair[1]))
