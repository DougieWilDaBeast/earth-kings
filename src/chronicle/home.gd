class_name Home
extends RefCounted
## The one place in the world that is yours.
##
## Nothing camps within sight of it, sleeping there always patches the party up,
## and the bed you put in it is the only thing you own that makes people
## permanently tougher. Beds go up in tiers and never come back down.

static func rules() -> Dictionary:
	return Database.world_rules.get("home", {})


static func beds() -> Array:
	return rules().get("beds", [])


## Index of the bed currently installed, clamped to what the data actually has.
static func tier(site: Site) -> int:
	return clampi(int(site.data.get("bed", 0)), 0, maxi(0, beds().size() - 1))


static func bed(site: Site) -> Dictionary:
	var all := beds()
	if all.is_empty():
		return {}
	return all[tier(site)]


static func bed_name(site: Site) -> String:
	return bed(site).get("display_name", "a bed")


## The next rung up, or empty when there is nothing better to be had.
static func next_bed(site: Site) -> Dictionary:
	var all := beds()
	var next := tier(site) + 1
	return all[next] if next < all.size() else {}


static func upgrade_cost(site: Site) -> int:
	return int(next_bed(site).get("cost", 0))


## Buy the next bed up. The gold goes whether or not anyone sleeps on it.
static func upgrade(site: Site) -> Array[String]:
	var better := next_bed(site)
	if better.is_empty():
		return ["There is nothing better than %s to sleep on." % bed_name(site)]

	var cost := int(better.get("cost", 0))
	if GameState.gold < cost:
		return ["%s costs %d gold, and you do not have it." % [better.get("display_name", "A bed"), cost]]

	GameState.gold -= cost
	site.data["bed"] = tier(site) + 1
	return ["%s goes into %s for %d gold." % [better.get("display_name", "A bed"), site.display_name, cost]]


## A night at home: everyone is patched up, and whoever slept there carries the
## comfort of the bed around with them as extra health.
static func sleep(site: Site, roster: Roster) -> Array[String]:
	var vigour := int(bed(site).get("vigour", 0))
	var lines: Array[String] = ["You sleep at %s on %s." % [site.display_name, bed_name(site)]]

	var toughened: Array[String] = []
	for character in roster.party_members():
		if not character.is_alive():
			continue
		if character.hearth < vigour:
			character.hearth = vigour
			toughened.append(character.display_name)
	roster.rest()

	if not toughened.is_empty() and vigour > 0:
		lines.append("%s wake up the better for it (+%d HP)." % [" and ".join(toughened), vigour])
	return lines
