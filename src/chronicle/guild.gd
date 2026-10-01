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
