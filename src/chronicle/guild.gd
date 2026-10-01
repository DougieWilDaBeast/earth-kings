extends RefCounted
## The Adventurers Guild — [D35], `DV2`, `OT8`.
##
## The Guild cares about gates, not the Tower. Every keep and village that is
## still standing keeps a hall: a register of every gate the Guild knows of,
## ranked worst first, and contracts to shut the open ones. A contract is an
## ordinary errand of kind [code]Errand.GATE[/code] in the job log; it pays the
## moment its gate is shut, wherever the party took it, and only the company
## can work it (`src/chronicle/dispatch.gd` will not send anyone on one).
##
## Loaded by path, not by `class_name` ([D41]).

const OPEN := "open"
const BROKEN := "broken"
const BREWING := "brewing"


static func rules() -> Dictionary:
	return Database.guild


static func line(key: String, tokens: Dictionary = {}) -> String:
	return str(rules().get("lines", {}).get(key, key)).format(tokens)


## Keeps and villages keep a hall while they stand. Huts are too small.
static func has_hall(site: Site) -> bool:
	return site != null and site.kind in [Site.KEEP, Site.VILLAGE] and not Town.is_ruined(site)


static func hall_at(world: World, cell: Vector2i) -> Site:
	var site := world.site_at(cell)
	return site if has_hall(site) else null


static func state_of(gate: Site) -> String:
	if gate.broken:
		return BROKEN
	return OPEN if gate.open else BREWING


## Every gate not yet shut, worst rank first and nearest first within a rank.
static func register(world: World, from: Vector2i, accepted: Array = []) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for gate: Site in world.sites_of_kind(Site.GATE):
		if gate.cleared:
			continue
		entries.append({
			"cell": gate.cell,
			"name": gate.display_name,
			"rank": gate.rank,
			"state": state_of(gate),
			"objective": gate.objective(),
			"floors": gate.floors(),
			"distance": Pathfinder.distance(from, gate.cell),
			"bearing": Roadside.bearing(from, gate.cell),
			"contracted": is_contracted(accepted, gate.cell),
			"pay": pay_for(gate),
		})
	entries.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var ra := Site.rank_index(a["rank"])
			var rb := Site.rank_index(b["rank"])
			if ra != rb:
				return ra > rb
			return int(a["distance"]) < int(b["distance"])
	)
	return entries


## One line of the register, as the clerk reads it out.
static func describe(entry: Dictionary) -> String:
	var states: Dictionary = rules().get("states", {})
	return "%s-rank  %s — %s, %d floor%s, %s. %s (%s)" % [
		entry["rank"], entry["name"], str(states.get(entry["state"], entry["state"])),
		int(entry["floors"]), "" if int(entry["floors"]) == 1 else "s",
		Site.objective_name(str(entry["objective"])), str(entry["bearing"]),
		"yours" if entry["contracted"] else "%d gold" % int(entry["pay"]),
	]


static func pay_for(gate: Site) -> int:
	var terms: Dictionary = rules().get("contract", {})
	return int(terms.get("gold_base", 60)) + int(terms.get("gold_per_rank", 90)) * Site.rank_index(gate.rank)


static func is_contracted(accepted: Array, cell: Vector2i) -> bool:
	return accepted.any(
		func(errand: Dictionary) -> bool:
			var to: Array = errand.get("to", [])
			return errand.get("kind", "") == Errand.GATE and to.size() == 2 \
				and int(to[0]) == cell.x and int(to[1]) == cell.y
	)


## Take the contract on [param gate] at [param hall]. Returns what the clerk says.
static func take(world: World, hall: Site, gate: Site, accepted: Array) -> String:
	if not has_hall(hall):
		return line("no_hall")
	if is_contracted(accepted, gate.cell):
		return line("already")
	if not gate.open or gate.cleared:
		return line("not_open", {"gate": gate.display_name})
	if accepted.size() >= Errand.max_accepted():
		return line("full")
	var gold := pay_for(gate)
	accepted.append({
		"kind": Errand.GATE,
		"title": "Shut %s" % gate.display_name,
		"text": "The Guild wants the %s-rank gate at %s shut. %s." % [
			gate.rank, gate.display_name, Site.objective_name(gate.objective())
		],
		"giver": str(rules().get("contract", {}).get("giver", "the Adventurers Guild")),
		"from": [hall.cell.x, hall.cell.y],
		"from_name": hall.display_name,
		"to": [gate.cell.x, gate.cell.y],
		"to_name": gate.display_name,
		"gold": gold,
		"posted_at": world.steps,
	})
	return line("taken", {"gate": gate.display_name, "gold": gold})


# --- musters ------------------------------------------------------------------
#
# An S-rank gate is a national threat (`OT8`): kingdoms, soldiers and every
# strong fighter gather at the nearest hall and wait until there are enough of
# them to go in. A muster lives on [code]World.musters[/code] as a plain
# dictionary. Standing with it is a [code]Errand.MUSTER[/code] errand: walked
# by the company, the muster goes into the gate beside the party; handed to a
# companion, they wait with it. **Inferred** (on the agenda): a muster nobody
# from the company is standing with goes in alone once it is strong enough and
# has waited, and is won or lost on its strength.


static func muster_rules() -> Dictionary:
	return rules().get("muster", {})


static func musters_for(rank: String) -> bool:
	return muster_rules().get("ranks", ["S"]).has(rank)


static func muster_at(world: World, gate_cell: Vector2i) -> Dictionary:
	for muster: Dictionary in world.musters:
		if _cell(muster.get("gate", [])) == gate_cell:
			return muster
	return {}


static func musters_at_hall(world: World, hall_cell: Vector2i) -> Array:
	return world.musters.filter(func(m: Dictionary) -> bool: return _cell(m.get("hall", [])) == hall_cell)


static func is_ready(muster: Dictionary) -> bool:
	return int(muster.get("strength", 0)) >= int(muster.get("needed", 1))


static func describe_muster(muster: Dictionary) -> String:
	return line("muster_line", {
		"hall": muster.get("hall_name", "the hall"), "gate": muster.get("gate_name", "the gate"),
		"strength": int(muster.get("strength", 0)), "needed": int(muster.get("needed", 1)),
		"state": line("muster_ready") if is_ready(muster) else "",
	})


## The company's own errand to stand with the muster on [param gate_cell], if any.
static func standing_with(accepted: Array, gate_cell: Vector2i) -> Dictionary:
	for errand: Dictionary in accepted:
		if errand.get("kind", "") == Errand.MUSTER and _cell(errand.get("gate", [])) == gate_cell:
			return errand
	return {}


## The company itself is standing with it, rather than somebody sent.
static func joined_in_person(accepted: Array, gate_cell: Vector2i) -> bool:
	var errand := standing_with(accepted, gate_cell)
	return not errand.is_empty() and str(errand.get("sent", "")) == ""


## Put the company's name down with [param muster]. Returns what the clerk says.
static func join(world: World, muster: Dictionary, accepted: Array) -> String:
	var gate_cell := _cell(muster.get("gate", []))
	if not standing_with(accepted, gate_cell).is_empty():
		return line("already")
	if accepted.size() >= Errand.max_accepted():
		return line("full")
	var hall := _cell(muster.get("hall", []))
	accepted.append({
		"kind": Errand.MUSTER,
		"title": "Stand with the muster at %s" % muster.get("hall_name", "the hall"),
		"text": "The Guild's muster for %s. Go in with them, or send somebody to wait with them." % muster.get("gate_name", "the gate"),
		"giver": str(rules().get("contract", {}).get("giver", "the Adventurers Guild")),
		"from": [hall.x, hall.y],
		"from_name": muster.get("hall_name", "the hall"),
		"to": [hall.x, hall.y],
		"to_name": muster.get("hall_name", "the hall"),
		"gate": [gate_cell.x, gate_cell.y],
		"gate_name": muster.get("gate_name", "the gate"),
		"gold": int(muster_rules().get("gold", 240)),
		"posted_at": world.steps,
	})
	return line("muster_joined", {"hall": muster.get("hall_name", ""), "gate": muster.get("gate_name", "")})


## Who goes into [param gate] beside the party: nobody, unless the company is
## standing with its muster in person. Entries are ready for [code]BattleMapGen.add_allies[/code].
static func allies_for(world: World, gate: Site, accepted: Array, party: Array) -> Array:
	var muster := muster_at(world, gate.cell)
	if muster.is_empty() or not joined_in_person(accepted, gate.cell):
		return []
	var terms := muster_rules()
	var count := clampi(
		1 + int(muster.get("strength", 0)) / maxi(1, int(terms.get("ally_every", 4))),
		1, int(terms.get("max_allies", 4))
	)
	var units: Array = terms.get("units", ["keep_watchman"])
	var level := Encounter.party_level(party) + int(terms.get("ally_level_bonus", 1))
	var out: Array = []
	for i in count:
		out.append({"unit": units[i % units.size()], "level": level})
	return out


## Every upkeep: raise musters for gates that warrant one, grow them, and send
## the ones nobody is waiting on into their gate.
static func upkeep(world: World, accepted: Array) -> Array[String]:
	var notices: Array[String] = []
	var terms := muster_rules()
	for gate: Site in world.sites_of_kind(Site.GATE):
		if gate.open and not gate.cleared and musters_for(gate.rank) and muster_at(world, gate.cell).is_empty():
			var raised := _raise(world, gate)
			if not raised.is_empty():
				notices.append(line("muster_raised", {"gate": gate.display_name, "hall": raised["hall_name"]}))
	for muster: Dictionary in world.musters.duplicate():
		var gate := world.site_at(_cell(muster.get("gate", [])))
		if gate == null or gate.cleared:
			world.musters.erase(muster)
			continue
		muster["strength"] = mini(
			int(muster.get("needed", 1)), int(muster.get("strength", 0)) + int(terms.get("per_upkeep", 1))
		)
		if not is_ready(muster) or joined_in_person(accepted, gate.cell):
			continue
		muster["waited"] = int(muster.get("waited", 0)) + 1
		if int(muster["waited"]) >= int(terms.get("wait_upkeeps", 4)):
			notices.append(_go_in_alone(world, muster, gate, accepted))
	return notices


## The company shut the gate: whatever muster stood for it stands down.
static func on_gate_shut(world: World, gate: Site) -> Array[String]:
	var muster := muster_at(world, gate.cell)
	if muster.is_empty():
		return []
	world.musters.erase(muster)
	var said := line("muster_shut", {"hall": muster.get("hall_name", ""), "gate": gate.display_name})
	Annals.record(world, said)
	return [said]


static func _raise(world: World, gate: Site) -> Dictionary:
	var hall: Site = null
	for site: Site in world.sites:
		if has_hall(site) and (hall == null or Pathfinder.distance(site.cell, gate.cell) < Pathfinder.distance(hall.cell, gate.cell)):
			hall = site
	if hall == null:
		return {}
	var muster := {
		"gate": [gate.cell.x, gate.cell.y],
		"gate_name": gate.display_name,
		"hall": [hall.cell.x, hall.cell.y],
		"hall_name": hall.display_name,
		"strength": int(muster_rules().get("start", 2)),
		"needed": int(muster_rules().get("needed", 12)),
		"raised_at": world.steps,
		"waited": 0,
	}
	world.musters.append(muster)
	Annals.record(world, "The Guild raised a muster at %s for the S-rank gate %s." % [hall.display_name, gate.display_name])
	return muster


## Settled on the muster's strength and a roll taken from the gate and the
## clock, never from the world's dice, so a seeded run is not shifted by it.
static func _go_in_alone(world: World, muster: Dictionary, gate: Site, accepted: Array) -> String:
	var terms := muster_rules()
	var odds := float(terms.get("win_base", 0.35)) + float(terms.get("win_per_strength", 0.03)) * float(muster.get("strength", 0))
	var roll := float(absi(hash([gate.cell, world.steps, world.world_seed])) % 1000) / 1000.0
	var won := roll < odds
	world.musters.erase(muster)
	var tokens := {"hall": muster.get("hall_name", ""), "gate": gate.display_name}
	var said := line("muster_won" if won else "muster_lost", tokens)
	if won:
		world.close_gate(gate)
		for errand: Dictionary in accepted.duplicate():
			if errand.get("kind", "") == Errand.GATE and _cell(errand.get("to", [])) == gate.cell:
				accepted.erase(errand)
				said += " " + line("contract_void", tokens)
	else:
		gate.broken = true
	for errand: Dictionary in accepted:
		if errand.get("kind", "") == Errand.MUSTER and _cell(errand.get("gate", [])) == gate.cell:
			errand["outcome"] = "won" if won else "lost"
	Annals.record(world, said)
	return said


static func _cell(pair: Variant) -> Vector2i:
	if not pair is Array or (pair as Array).size() < 2:
		return Vector2i(-1, -1)
	return Vector2i(int(pair[0]), int(pair[1]))
