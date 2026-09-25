extends RefCounted
## Rumours that come with work attached — M16's job log, filled from what the
## country is talking about as well as from the board.
##
## When the host passes on the news, one piece of it that points at real
## trouble can post a job on this settlement's board: a bounty on somebody who
## got away from the party, a look at a gate whose wards have broken, arrows
## for a town under siege. It is an ordinary errand once it is there — taken
## from the board, kept in the job log, done by hand or by a companion sent
## away (see [Errand], `src/chronicle/dispatch.gd`). The same rumour never posts
## twice, and a board that already has something on it is left alone.
##
## Loaded by path, not by `class_name` ([D41]).

const POSTED_FLAG := "rumour_job:"


static func rules() -> Dictionary:
	return Errand.rules().get("rumours", {})


## Post a job from the news at the settlement the party is standing in, and
## return the line the host says about it, or "" if nothing was posted.
static func post(world: World) -> String:
	var site := world.site_at(world.player_cell)
	if site == null or not Errand._is_settlement(site) or not Errand.board(site).is_empty():
		return ""
	var job := compose(world, site)
	if job.is_empty():
		return ""
	var said := str(job["posted"])
	job.erase("posted")
	site.data["errand"] = job
	GameState.set_flag(POSTED_FLAG + str(job["rumour"]))
	return said


## A job from one rumour not yet posted, or empty if there is none.
static func compose(world: World, site: Site) -> Dictionary:
	var open: Array = []
	for survivor: Dictionary in world.survivors:
		if Database.units.has(str(survivor.get("unit", ""))):
			open.append({"kind": "survivor", "key": "survivor:%s" % survivor.get("name", ""), "survivor": survivor})
	for gate: Site in world.sites_of_kind(Site.GATE):
		if gate.open and gate.broken and not gate.cleared:
			open.append({"kind": "gate", "key": "gate:%s" % gate.display_name, "site": gate})
	for town: Site in world.sites:
		if town != site and Town.is_threatened(town):
			open.append({"kind": "siege", "key": "siege:%s" % town.display_name, "site": town})
	open = open.filter(func(r: Dictionary) -> bool: return not GameState.has_flag(POSTED_FLAG + str(r["key"])))
	if open.is_empty():
		return {}
	return _job(open[world.rng.randi() % open.size()], world, site)


static func _job(rumour: Dictionary, world: World, site: Site) -> Dictionary:
	var words: Dictionary = rules().get(rumour["kind"], {})
	var job := {
		"giver": "the %s at %s" % ["keeper" if site.kind == Site.KEEP else "host", site.display_name],
		"from": [site.cell.x, site.cell.y],
		"from_name": site.display_name,
		"done": 0,
		"reached": false,
		"rumour": rumour["key"],
	}
	var fill := {}
	match rumour["kind"]:
		"survivor":
			var survivor: Dictionary = rumour["survivor"]
			job["kind"] = Errand.BOUNTY
			job["target"] = str(survivor["unit"])
			job["target_name"] = str(survivor.get("name", survivor["unit"]))
			job["count"] = 1
			job["gold"] = int(Errand.rules().get("bounty_reward", 130))
			fill = {"name": job["target_name"], "place": str(survivor.get("place", "the frontier"))}
		"gate", "siege":
			var there: Site = rumour["site"]
			job["kind"] = Errand.LOOK if rumour["kind"] == "gate" else Errand.DELIVER
			Errand._point_at(job, there.cell, there.display_name, site, world)
			fill = {"place": there.display_name}
	job["gold"] = roundi(float(job["gold"]) * float(Errand.rules().get("rumour_reward_multiplier", 1.5)))
	job["title"] = str(words.get("title", "Word on the road")).format(fill)
	job["text"] = str(words.get("text", "")).format(fill)
	job["posted"] = str(words.get("posted", "")).format(fill)
	return job
