class_name Town
extends RefCounted
## What can happen to a settlement: it can be defended, and it can be robbed.
##
## A town near a gate that has been standing open too long comes under threat.
## Walk in while it is threatened and you can drive the besiegers off; leave it
## long enough and the town falls on its own and stops being a town. Either way
## the country talks about it afterwards (see [Renown]).

const THREATENED := "threatened"
const SAVED := "saved"
const SACKED := "sacked"
const RAIDED := "raided"


static func rules() -> Dictionary:
	return Database.world_rules.get("town", {})


static func is_settlement(site: Site) -> bool:
	return site != null and site.kind in [Site.VILLAGE, Site.KEEP, Site.HUT]


## A town that has been robbed or has fallen has nothing left to offer.
static func is_ruined(site: Site) -> bool:
	return bool(site.data.get(SACKED, false)) or bool(site.data.get(RAIDED, false))


static func is_threatened(site: Site) -> bool:
	return site.data.has("threatened_at") and not is_ruined(site)


## What is in the strongbox. Keeps hold more than huts do.
static func purse(site: Site) -> int:
	var base := int(rules().get("purse_base", 120))
	var per_rank := int(rules().get("purse_per_rank", 90))
	var standing := 2 if site.kind == Site.KEEP else (1 if site.kind == Site.VILLAGE else 0)
	return base + per_rank * standing


# --- the siege clock ----------------------------------------------------------


## Run on world upkeep: gates left open put the nearest settlement under threat,
## and a threat nobody answers eventually takes the town. Returns notices.
static func upkeep(world: World) -> Array:
	var notices: Array = []
	var patience := int(rules().get("threat_after_steps", 240))

	for gate in world.sites_of_kind(Site.GATE):
		if not gate.open or world.steps - gate.opened_at < patience:
			continue
		var victim := _nearest_settlement(world, gate.cell)
		if victim == null or is_ruined(victim) or is_threatened(victim):
			continue
		victim.data["threatened_at"] = world.steps
		victim.data["threatened_by"] = gate.display_name
		notices.append("%s is being raided by whatever came out of %s." % [
			victim.display_name, gate.display_name
		])

	var doom := int(rules().get("falls_after_steps", 900))
	for site in world.sites:
		if not is_threatened(site):
			continue
		if world.steps - int(site.data["threatened_at"]) < doom:
			continue
		site.data.erase("threatened_at")
		site.data[SACKED] = true
		site.data["wares"] = []
		site.data["hire"] = {}
		notices.append("%s has fallen. Nobody was coming." % site.display_name)
	return notices


# --- the two things you can do about it ---------------------------------------


## Drive the besiegers off. Call after the fight is won.
static func save(site: Site, world: World) -> Array[String]:
	site.data.erase("threatened_at")
	site.data.erase("threatened_by")
	site.data[SAVED] = true

	var reward := int(rules().get("defence_reward", 160))
	GameState.gold += reward
	var line := "%s was held against a raid" % site.display_name
	Renown.record(
		world, Renown.TOWN_SAVED, site.cell,
		int(Renown.rules().get("town_saved", 5)), line
	)
	return [
		"%s holds. They give you %d gold and every name they know." % [site.display_name, reward],
		"Word of this will get about.",
	]


## Take the place apart. Call after the fight is won.
static func raid(site: Site, world: World, roster: Roster) -> Array[String]:
	var haul := purse(site)
	GameState.gold += haul
	site.data[RAIDED] = true
	site.data["wares"] = []
	site.data["hire"] = {}
	site.data.erase("threatened_at")

	var lines: Array[String] = ["You take %d gold out of %s." % [haul, site.display_name]]
	if world.rng.randf() < 0.5:
		var found := Loot.roll(world, 1.0)
		found["gold"] = 0
		lines.append_array(Loot.claim(found, roster))

	var line := "%s was put to the torch" % site.display_name
	Renown.record(
		world, Renown.TOWN_RAIDED, site.cell,
		int(Renown.rules().get("town_raided", -7)), line
	)
	lines.append("There were witnesses. There always are.")
	return lines


static func _nearest_settlement(world: World, cell: Vector2i) -> Site:
	var best: Site = null
	var closest := 9999
	for site in world.sites:
		if not is_settlement(site):
			continue
		var apart := Pathfinder.distance(site.cell, cell)
		if apart < closest:
			closest = apart
			best = site
	return best
