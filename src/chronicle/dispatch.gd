extends RefCounted
## Sending a companion away on a job — M16, [D38].
##
## An errand the party has taken can be handed to somebody in it instead of
## walked by everyone. They leave the marching order and travel on the same
## clock as everything else: a tile a step, out and back, while the party walks
## wherever it walks. Somewhere on the road they may run into trouble, and a
## fight nobody else is at goes the way any fall goes (see [Fate]) — which is
## why it matters who you send.
##
## A job is a plain dictionary in [code]GameState.away[/code], so it saves with
## everything else; the errand it is working carries the id of whoever took it.
##
## Loaded by path rather than by `class_name`, so a checkout the editor has not
## rescanned still parses (the skirmish's lesson).

const Guild := preload("res://src/chronicle/guild.gd")
const Atlas := preload("res://src/chronicle/atlas.gd")

## Who took an errand, written on the errand itself.
const TAKEN_BY := "sent"


static func rules() -> Dictionary:
	return Database.world_rules.get("dispatch", {})


# --- sending ------------------------------------------------------------------


## Somebody who could be sent: in the party, on their feet, not the lead, not
## already away, and not the last one left with the lead.
static func can_send(character: Character, roster: Roster, away: Array) -> bool:
	if character == null or character.is_player or not character.is_available():
		return false
	if not roster.party.has(character.id) or job_for(away, character.id) != {}:
		return false
	return roster.party_members().size() > 1


## Accepted errands nobody has been sent on yet. Gate contracts are the company's own.
static func open_errands(accepted: Array) -> Array:
	return accepted.filter(
		func(errand: Dictionary) -> bool:
			return str(errand.get(TAKEN_BY, "")) == "" and str(errand.get("kind", "")) != Errand.GATE
	)


## Send [param character] to do [param errand]. Returns the line to show, or ""
## if they cannot go.
static func send(
	world: World, roster: Roster, away: Array, character: Character, errand: Dictionary
) -> String:
	if not can_send(character, roster, away) or str(errand.get(TAKEN_BY, "")) != "":
		return ""
	var target := _target_of(errand, world)
	var tiles := maxi(1, Pathfinder.distance(world.player_cell, target))
	var kind := str(errand.get("kind", ""))
	if kind == Errand.CULL or kind == Errand.BOUNTY:
		# Hunting means going out into the country and finding them.
		tiles = maxi(tiles, int(rules().get("hunt_distance", 8)))
	var pace := float(rules().get("steps_per_tile", 1.0))
	var out_steps := maxi(1, roundi(tiles * pace))
	roster.party.erase(character.id)
	errand[TAKEN_BY] = character.id
	away.append({
		"id": character.id,
		"to": [target.x, target.y],
		"to_name": str(errand.get("to_name", errand.get("from_name", "the country"))),
		"from": [world.player_cell.x, world.player_cell.y],
		"sent_at": world.steps,
		"out_at": world.steps + out_steps,
		"back_at": world.steps + out_steps * 2,
		"arrived": false,
		# Somebody standing with a muster waits for it to go in (see `guild.gd`).
		"waits": kind == Errand.MUSTER,
	})
	return "%s sets off to see to \"%s\". Back in about %d steps." % [
		character.display_name, errand.get("title", "the errand"), out_steps * 2,
	]


# --- the road -----------------------------------------------------------------


## Move every job on to where the clock says it is. Safe to call any number of
## times a step: each job acts only when its step has come, and only once.
static func walk(world: World, roster: Roster, away: Array, accepted: Array) -> Array[String]:
	var lines: Array[String] = []
	for job: Dictionary in away.duplicate():
		if job.has("gate"):
			lines.append_array(_walk_band(world, roster, away, accepted, job))
			continue
		var character := roster.by_id(str(job.get("id", "")))
		if character == null:
			away.erase(job)
			continue
		var errand := errand_for(accepted, character.id)
		if not bool(job.get("arrived", false)) and world.steps >= int(job.get("out_at", 0)):
			job["arrived"] = true
			lines.append_array(_arrive(world, roster, away, accepted, job, character, errand))
			if not away.has(job):
				continue
		if bool(job.get("arrived", false)) and world.steps >= int(job.get("back_at", 0)) \
				and not _still_waiting(job, errand):
			if str(errand.get("outcome", "")) == "lost":
				lines.append_array(_fell_with_the_muster(world, away, accepted, job, character, errand))
				if not away.has(job):
					continue
			lines.append_array(_come_back(world, roster, away, accepted, job, character, errand))
	return lines


static func _still_waiting(job: Dictionary, errand: Dictionary) -> bool:
	return bool(job.get("waits", false)) and not errand.is_empty() and not errand.has("outcome")


## The muster they waited with went in and lost. Whoever stood with it rolls
## for their life like anyone who falls with nobody of their own beside them.
static func _fell_with_the_muster(
	world: World, away: Array, accepted: Array,
	job: Dictionary, character: Character, errand: Dictionary
) -> Array[String]:
	var where := _cell(errand.get("gate", job.get("to", [])))
	var outcome := Fate.resolve(
		character, {"allies": [], "enemy_kind": "default", "world": world, "cell": where}, world.rng
	)
	var lines: Array[String] = [
		"%s went into %s with the muster." % [character.display_name, errand.get("gate_name", "the gate")],
		str(outcome["line"]),
	]
	accepted.erase(errand)
	if outcome["outcome"] == Fate.ALIVE:
		return lines
	away.erase(job)
	if outcome["outcome"] == Fate.DEAD:
		Memorial.raise(world, character, where, "default")
	return lines


## They reach the place. Trouble on the way is settled here, then the errand.
static func _arrive(
	world: World, roster: Roster, away: Array, accepted: Array,
	job: Dictionary, character: Character, errand: Dictionary
) -> Array[String]:
	var lines: Array[String] = []
	var target := _cell(job.get("to", []))
	var kind := str(errand.get("kind", Errand.FETCH))
	var hunting := kind == Errand.CULL or kind == Errand.BOUNTY
	if hunting or world.rng.randf() < trouble_chance(world, _cell(job.get("from", [])), target):
		var foe := str(errand.get("target", "")) if hunting else _local_foe(world, target)
		var fought := _fight(world, roster, away, job, character, errand, foe, target)
		lines.append_array(fought)
		if not away.has(job):
			return lines
	match kind:
		Errand.FETCH:
			errand["reached"] = true
		Errand.CULL, Errand.BOUNTY:
			errand["done"] = int(errand.get("count", 1))
		Errand.LOOK, Errand.DELIVER:
			lines.append("Word comes back from %s: %s saw to it." % [job.get("to_name", "the road"), character.display_name])
			lines.append_array(Errand._settle(accepted, errand, world))
		Errand.MUSTER:
			lines.append("%s reaches %s and waits with the muster." % [character.display_name, job.get("to_name", "the hall")])
	return lines


static func _come_back(
	world: World, roster: Roster, away: Array, accepted: Array,
	job: Dictionary, character: Character, errand: Dictionary
) -> Array[String]:
	var lines: Array[String] = []
	away.erase(job)
	if not errand.is_empty():
		errand.erase(TAKEN_BY)
		if Errand.is_complete(errand):
			lines.append("\"%s\" is settled." % errand.get("title", "The errand"))
			lines.append_array(Errand._settle(accepted, errand, world))
	if roster.enlist(character.id):
		lines.append("%s is back with the company." % character.display_name)
	else:
		lines.append("%s is back, but there is no room in the company. They will wait to be asked." % character.display_name)
	return lines


## A fight with nobody else there. Winning costs blood; losing is a fall like
## any other, with no ally standing to pull them out.
static func _fight(
	world: World, roster: Roster, away: Array, job: Dictionary,
	character: Character, errand: Dictionary, foe: String, where: Vector2i
) -> Array[String]:
	var lines: Array[String] = []
	var foe_name := str(Database.unit_template(foe).get("display_name", foe))
	var foe_level := maxi(1, Encounter.party_level(roster.party_members() + [character])
			+ roundi(Encounter.chance_at(world, where) * float(rules().get("danger_levels", 10))) - 1)
	if world.rng.randf() < win_chance(character, foe_level):
		var lost := world.rng.randf_range(0.2, 0.5)
		character.hp = maxi(1, character.current_hp() - roundi(float(character.max_hp()) * lost))
		lines.append("%s ran into a %s near %s and came through it." % [
			character.display_name, foe_name, job.get("to_name", "the road"),
		])
		for line in Progression.award_kill(character, foe, foe_level, [], false, world):
			lines.append(str(line))
		return lines

	var outcome := Fate.resolve(
		character,
		{"allies": [], "enemy_kind": Database.unit_template(foe).get("kind", "default"), "world": world, "cell": where},
		world.rng
	)
	lines.append("%s met a %s near %s, alone." % [character.display_name, foe_name, job.get("to_name", "the road")])
	lines.append(str(outcome["line"]))
	if outcome["outcome"] == Fate.ALIVE:
		return lines
	# Taken or dead: the job ends here and the errand is back on the list.
	away.erase(job)
	errand.erase(TAKEN_BY)
	if outcome["outcome"] == Fate.DEAD:
		Memorial.raise(world, character, where, foe)
	return lines


# --- a band of your own into a gate ([D278]) -----------------------------------
#
# Ewan's play-test 7: "send your own characters to do quests so they go on auto mode ... and travel
# across into a dungeon gate". A band walks to a gate the company knows of on the same clock as
# everything else, goes in on its own, and shuts it on the odds: its level against the gate's rank,
# and every extra pair of hands. Lost, each of them rolls for their life as in any fall.


## Gates a band could be sent to: open, never shut, and known to the company.
static func open_gates(world: World) -> Array[Site]:
	var out: Array[Site] = []
	for site: Site in world.sites:
		if site.kind == Site.GATE and site.open and not site.cleared and Atlas.knows(world, site):
			out.append(site)
	return out


## Whether sending somebody away is open yet: once the company has shut a gate of its own (the
## Guild's mark), its people may be sent out on their own ([D278]).
static func unlocked(world: World) -> bool:
	if world == null:
		return false
	for site: Site in world.sites:
		if site.kind == Site.GATE and site.cleared:
			return true
	return false


## The band on the road to [param gate] that has not got there yet, which more can catch up with.
static func band_for(away: Array, gate: Site) -> Dictionary:
	for job: Dictionary in away:
		if job.has("gate") and _cell(job["gate"]) == gate.cell and not bool(job.get("arrived", false)):
			return job
	return {}


## Send [param character] to shut [param gate], with whoever is already on the road to it.
## Returns the line to show, or "" if they cannot go.
static func send_to_gate(world: World, roster: Roster, away: Array, character: Character, gate: Site) -> String:
	if not can_send(character, roster, away) or gate == null or not gate.open or gate.cleared:
		return ""
	roster.party.erase(character.id)
	var band := band_for(away, gate)
	if not band.is_empty():
		(band["band"] as Array).append(character.id)
		return "%s goes after the others to %s." % [character.display_name, gate.display_name]
	var tiles := maxi(1, Pathfinder.distance(world.player_cell, gate.cell))
	var out_steps := maxi(1, roundi(tiles * float(rules().get("steps_per_tile", 1.0))))
	var inside := gate.floors() * int(rules().get("steps_per_floor", 4))
	away.append({
		"id": character.id,
		"band": [character.id],
		"gate": [gate.cell.x, gate.cell.y],
		"to": [gate.cell.x, gate.cell.y],
		"to_name": gate.display_name,
		"from": [world.player_cell.x, world.player_cell.y],
		"sent_at": world.steps,
		"out_at": world.steps + out_steps + inside,
		"back_at": world.steps + out_steps * 2 + inside,
		"arrived": false,
	})
	return "%s sets off to shut %s (%s-rank). Back in about %d steps." % [
		character.display_name, gate.display_name, gate.rank, out_steps * 2 + inside,
	]


## The chance a band shuts [param gate]: its average level against what the rank expects, and a
## little more for every pair of hands past the first.
static func gate_chance(band: Array, gate: Site) -> float:
	if band.is_empty():
		return 0.0
	var levels := 0.0
	for character: Character in band:
		levels += character.level
	var r := rules()
	var odds := float(r.get("gate_win_base", 0.5)) \
		+ float(r.get("gate_per_level", 0.06)) * (levels / band.size() - gate.expected_level()) \
		+ float(r.get("gate_per_hand", 0.1)) * (band.size() - 1)
	return clampf(odds, float(r.get("gate_min", 0.05)), float(r.get("gate_max", 0.95)))


static func members(roster: Roster, job: Dictionary) -> Array:
	var out: Array = []
	for id: Variant in job.get("band", []):
		var character := roster.by_id(str(id))
		if character != null:
			out.append(character)
	return out


static func _walk_band(world: World, roster: Roster, away: Array, accepted: Array, job: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var band := members(roster, job)
	if band.is_empty():
		away.erase(job)
		return lines
	if not bool(job.get("arrived", false)) and world.steps >= int(job.get("out_at", 0)):
		job["arrived"] = true
		lines.append_array(_storm(world, roster, away, accepted, job, band))
	if away.has(job) and bool(job.get("arrived", false)) and world.steps >= int(job.get("back_at", 0)):
		away.erase(job)
		for character: Character in members(roster, job):
			if roster.enlist(character.id):
				lines.append("%s is back with the company." % character.display_name)
			else:
				lines.append("%s is back, but there is no room in the company. They will wait to be asked." % character.display_name)
	return lines


## The band goes in. Won, the gate is shut as if the company had shut it; lost, it stays open and
## every one of them rolls for their life, the others standing by them.
static func _storm(world: World, roster: Roster, away: Array, accepted: Array, job: Dictionary, band: Array) -> Array[String]:
	var lines: Array[String] = []
	var gate := world.site_at(_cell(job.get("gate", [])))
	var names := ", ".join(band.map(func(c: Character) -> String: return c.display_name))
	if gate == null or not gate.open or gate.cleared:
		lines.append("%s found %s already shut, and turned for home." % [names, job.get("to_name", "the gate")])
		return lines
	var foe := _local_foe(world, gate.cell)
	if world.rng.randf() < gate_chance(band, gate):
		for character: Character in band:
			var lost := world.rng.randf_range(0.3, 0.6)
			character.hp = maxi(1, character.current_hp() - roundi(float(character.max_hp()) * lost))
			for line in Progression.award_kill(character, foe, gate.expected_level() + gate.floors(), [], true, world):
				lines.append(str(line))
		world.close_gate(gate)
		lines.push_front("%s went into %s on their own and shut it." % [names, gate.display_name])
		Annals.record(world, "The %s-rank gate at %s was shut by %s, sent out by the company." % [gate.rank, gate.display_name, names])
		for line in Spoils.for_gate(world, gate, band):
			lines.append(str(line))
		lines.append_array(Errand.on_gate_shut(accepted, gate.cell, world))
		lines.append_array(Guild.on_gate_shut(world, gate))
		return lines
	lines.append("%s went into %s and could not shut it." % [names, gate.display_name])
	var kind := str(Database.unit_template(foe).get("kind", "default"))
	for character: Character in band:
		var others := band.filter(func(c: Character) -> bool: return c != character)
		var outcome := Fate.resolve(character, {"allies": others, "enemy_kind": kind, "world": world, "cell": gate.cell}, world.rng)
		lines.append(str(outcome["line"]))
		if outcome["outcome"] == Fate.ALIVE:
			character.hp = maxi(1, character.max_hp() / 5)
			continue
		(job["band"] as Array).erase(character.id)
		if outcome["outcome"] == Fate.DEAD:
			Memorial.raise(world, character, gate.cell, foe)
	if (job["band"] as Array).is_empty():
		away.erase(job)
	return lines


# --- odds ---------------------------------------------------------------------


## The chance of meeting something on the way, from how dangerous the road is.
static func trouble_chance(world: World, from: Vector2i, to: Vector2i) -> float:
	var total := 0.0
	var samples := 0
	var tiles := maxi(1, Pathfinder.distance(from, to))
	for i in range(0, tiles + 1, maxi(1, tiles / 8)):
		var t := float(i) / float(tiles)
		var cell := Vector2i(Vector2(from).lerp(Vector2(to), t).round())
		total += Encounter.chance_at(world, cell)
		samples += 1
	var average := total / float(maxi(1, samples))
	return clampf(average * float(rules().get("trouble_scale", 1.5)),
			float(rules().get("trouble_min", 0.05)), float(rules().get("trouble_max", 0.7)))


static func win_chance(character: Character, foe_level: int) -> float:
	var base := float(rules().get("win_base", 0.6))
	var per_level := float(rules().get("win_per_level", 0.08))
	return clampf(base + per_level * float(character.level - foe_level), 0.15, 0.95)


# --- reading them -------------------------------------------------------------


static func job_for(away: Array, character_id: String) -> Dictionary:
	for job: Dictionary in away:
		if str(job.get("id", "")) == character_id or (job.get("band", []) as Array).has(character_id):
			return job
	return {}


static func errand_for(accepted: Array, character_id: String) -> Dictionary:
	for errand: Dictionary in accepted:
		if str(errand.get(TAKEN_BY, "")) == character_id:
			return errand
	return {}


## One line for the party screen: who, where, how long.
static func summary(job: Dictionary, roster: Roster, world: World) -> String:
	var character := roster.by_id(str(job.get("id", "")))
	var who := character.display_name if character != null else "Somebody"
	if job.has("gate"):
		var names: Array = members(roster, job).map(func(c: Character) -> String: return c.display_name)
		who = ", ".join(names) if not names.is_empty() else who
		if not bool(job.get("arrived", false)):
			return "%s — on the road to shut %s, about %d steps from it" % [
				who, job.get("to_name", "the gate"), maxi(0, int(job.get("out_at", 0)) - world.steps),
			]
	if bool(job.get("arrived", false)):
		if bool(job.get("waits", false)) and world.steps >= int(job.get("back_at", 0)):
			return "%s — waiting with the muster at %s" % [who, job.get("to_name", "the hall")]
		return "%s — on the way back from %s, about %d steps out" % [
			who, job.get("to_name", "the road"), maxi(0, int(job.get("back_at", 0)) - world.steps),
		]
	return "%s — on the road to %s, about %d steps from it" % [
		who, job.get("to_name", "the road"), maxi(0, int(job.get("out_at", 0)) - world.steps),
	]


# --- where things are ---------------------------------------------------------


## Where a job has to get to. Hunting jobs have no place on them, so they go to
## the board they were posted on and hunt the country around it.
static func _target_of(errand: Dictionary, world: World) -> Vector2i:
	if errand.has("to"):
		return _cell(errand["to"])
	var home := _cell(errand.get("from", []))
	return home if home != Vector2i(-1, -1) else world.player_cell


## Something that lives around [param cell], for a meeting on the road.
static func _local_foe(world: World, cell: Vector2i) -> String:
	var pool: Array = Database.encounters.get("wild", {}).get(world.terrain_id_at(cell), ["wolf"])
	return str(pool[world.rng.randi() % pool.size()]) if not pool.is_empty() else "wolf"


static func _cell(value: Variant) -> Vector2i:
	if value is Array and (value as Array).size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i(-1, -1)
