extends RefCounted
## Where a party walking itself goes next on the continent, one tile at a time.
##
## Asked by the continent's own walk (Q on the map, the suites) and by the ground, which walks the
## party over the border into the tile named here ([D94]). The way is kept between askings, and
## between scenes, so it is worked out once per target rather than once per step.
##
## Loaded by path, not by `class_name` ([D41]).

const Route := preload("res://src/world/route.gd")
const Chapters := preload("res://src/chronicle/chapters.gd")
const Atlas := preload("res://src/chronicle/atlas.gd")
const Dispatch := preload("res://src/chronicle/dispatch.gd")
const Guild := preload("res://src/chronicle/guild.gd")
const Quests := preload("res://src/world/quests.gd")

## Set the first time the party stands in a town: the First Hour's first leg is done.
const TOWN_REACHED := "objective:town"

## How far the party will turn aside for a band while walking itself. The road
## to anywhere is thick with them, so chasing every one means never arriving.
const DETOUR := 6
const STEPS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

## The world the way below was worked out in; a new run starts it again.
static var _world: World = null
## The way the party was last walking itself, so auto does not pace on the spot.
static var _last: Vector2i = Vector2i.ZERO
## Where the party is walking itself to, and the cells between here and there.
## Worked out once per target: stepping greedily at a target gets caught behind
## the first wall between them and paces there for good.
static var _target: Vector2i = Vector2i(-1, -1)
static var _route: Array[Vector2i] = []
## Where the party is walking itself to when it knows of nowhere to go: the
## nearest ground it has never seen.
static var _explore_to: Vector2i = Vector2i(-1, -1)
static var _explored_checked_at: int = -999


## The next step for a party walking itself, or nothing at all.
static func next_step(world: World) -> Vector2i:
	var step := direction(world, errand(world))
	if step != Vector2i.ZERO:
		_last = step
	return step


## Where the party is headed, for the compass and for Auto: `cell`, `label` (what the compass
## says), and `stop` (whether a party walking itself hands back control on arriving, where nothing
## starts by itself). The quest the player chose to follow from the quest list (L on the ground, or
## Follow in the journal, [D190]) when there is one; otherwise [method default_objective].
static func objective(world: World) -> Dictionary:
	var chosen := Quests.followed(world, quests(world))
	if not chosen.is_empty():
		return chosen
	return default_objective(world)


## Everything the party is working towards, in the quest list's order ([D190]).
static func quests(world: World) -> Array[Dictionary]:
	return Quests.all(world, road_objective(world))


## Follow the next quest in the list (or the one before, with [param step] -1), and say which.
static func next_quest(world: World, step: int = 1) -> Dictionary:
	return Quests.cycle(world, quests(world), default_objective(world), step)


## Where the First Hour sends the party when nothing has been chosen (D95).
## In order: an errand taken (a Guild contract included), the great city (or,
## with none, the nearest town) until a town has been stood in, the Guild at the Tower's door until its
## register has been opened (D107), the nearest gate of the lowest rank until a gate has
## been shut, then the Tower. A gate above the lead's rank (one whose expected
## level is past the lead's) is never chosen: with none at their rank open, the
## Tower is (D97). Empty when there is nowhere left to send them.
static func default_objective(world: World) -> Dictionary:
	var goal := _nearest_errand(world)
	if not goal.is_empty():
		return goal
	return road_objective(world)


## The nearest errand taken and not sent off with a companion, or nothing.
static func _nearest_errand(world: World) -> Dictionary:
	var here := world.player_cell
	var closest := 1 << 30
	var goal := {}
	for taken: Dictionary in GameState.errands:
		if str(taken.get(Dispatch.TAKEN_BY, "")) != "":
			continue
		var back := Errand.is_complete(taken)
		var at := cell_of(taken.get("from" if back else "to", []))
		if at.x < 0:
			continue
		var reach := Pathfinder.distance(here, at)
		if reach < closest:
			closest = reach
			var named := str(taken.get("from_name" if back else "to_name", "the place"))
			var there := world.site_at(at)
			goal = {
				"cell": at, "label": ("Back to %s" if back else "%s") % named,
				"stop": back or Town.is_settlement(there),
			}
	return goal


## The road the First Hour lays out, errands aside: the town, the Guild, the first gate, the Tower.
static func road_objective(world: World) -> Dictionary:
	var here := world.player_cell
	var closest := 1 << 30
	if not GameState.has_flag(TOWN_REACHED):
		# The great city round the Tower when there is one standing (D101),
		# else the nearest town.
		var town: Site = null
		for site: Site in world.sites:
			if not Town.is_settlement(site) or site.kind == Site.HUT or Town.is_ruined(site):
				continue
			var reach := Pathfinder.distance(here, site.cell)
			if bool(site.data.get("city", false)):
				town = site
				break
			if reach < closest:
				closest = reach
				town = site
		if town != null:
			return {"cell": town.cell, "label": town.display_name, "stop": true}

	var gates: Array[Site] = world.sites_of_kind(Site.GATE)
	var tower := world.tower()
	var shut_one := gates.any(func(gate: Site) -> bool: return gate.cleared)
	# The Guild at the Tower's door, before the first gate (D107): its mark is what opens the stair.
	# AU (D161, the five strangers): with `gate_after_city` on, the compass goes straight on to the
	# gate, because the door could only say "shut a gate" and nobody found one from there.
	if FirstHour.wants_guild_mark() and not FirstHour.gate_after_city() and not shut_one \
			and not GameState.has_flag(Guild.VISITED) and Guild.has_hall(tower):
		return {"cell": tower.cell, "label": "The Guild, at the Tower's door", "stop": true}

	# A chapter closed shuts the stair again until a gate is shut (D101): the next gate, not the
	# Tower, is where the party goes then ([D197]: it paced on the Tower's tile after floor 5).
	if not shut_one or (tower != null and Chapters.sealed(world)):
		var lead := GameState.roster.player() if GameState.roster != null else null
		var lead_level := lead.level if lead != null else 1
		var first: Site = null
		for gate: Site in gates:
			if not gate.open or gate.cleared or Pace.avoided.has(gate.cell):
				continue
			if gate.expected_level() > lead_level:
				continue
			if first == null or Site.rank_index(gate.rank) < Site.rank_index(first.rank) \
					or (gate.rank == first.rank and Pathfinder.distance(here, gate.cell) < Pathfinder.distance(here, first.cell)):
				first = gate
		if first != null:
			return {"cell": first.cell, "label": "%s (rank %s)" % [first.display_name, first.rank], "stop": false}

	if tower != null and not world.tower_is_topped():
		# The first floors are walked by hand, so a party walking itself stops at the door (D102):
		# on the ground the door itself, across the tile, not the tile's edge (`door`, [D197]).
		var walked := Chapters.walked_floor_area(world.tower_floor + 1) != ""
		return {"cell": tower.cell, "label": tower.display_name, "stop": walked, "door": walked}
	return {}


static func cell_of(at: Variant) -> Vector2i:
	if at is Array and (at as Array).size() == 2:
		return Vector2i(int(at[0]), int(at[1]))
	return Vector2i(-1, -1)


## What the party walks towards when nobody is steering: a fight worth the
## detour, then the objective (D95), then the nearest gate still standing, then
## the Tower.
static func errand(world: World) -> Vector2i:
	_keep_to(world)
	var rest := rest_stop(world)
	if rest.x >= 0:
		return rest
	var target := Vector2i(-1, -1)
	var best := DETOUR + 1
	for band: Prowler in world.prowlers:
		var reach := Pathfinder.distance(band.cell, world.player_cell)
		if reach < best:
			best = reach
			target = band.cell
	if target.x >= 0:
		return target

	var goal := objective(world)
	if not goal.is_empty():
		var there: Vector2i = goal["cell"]
		if there != world.player_cell and not Pace.avoided.has(there):
			return there

	best = 1 << 30
	for site in world.sites:
		if site.kind != Site.GATE or not site.open or site.cleared:
			continue
		if Pace.avoided.has(site.cell) or not Atlas.knows(world, site):
			continue
		if site.data.has("ward") and not Ward.is_site_open(site) and Ward.answer(site.data["ward"], GameState.party_characters()).is_empty():
			continue
		var reach := Pathfinder.distance(site.cell, world.player_cell)
		if reach < best:
			best = reach
			target = site.cell
	if target.x >= 0:
		return target

	var tower := world.tower()
	if tower != null and not world.tower_is_topped() and not Pace.avoided.has(tower.cell) \
			and not Chapters.sealed(world) and Atlas.knows(world, tower):
		return tower.cell
	return _explore_target(world)


## Where a badly hurt party walking itself goes first: the nearest place that patches it up on
## arriving (a village, a keep, a hut; not the crater, whose sleep heals nobody in the First Hour, so
## Auto walked back to it for good), before any band or the objective ([D209], call BL:
## after a lost fight Auto walked into the next one at a quarter of its health, and dealt leads fell
## on the road in 6 of 8 self-played runs). Hurt is the party's health under
## `first_hour.auto_rest_below` of its whole; (-1, -1) when it is not, or there is nowhere known.
static func rest_stop(world: World) -> Vector2i:
	if GameState.roster == null:
		return Vector2i(-1, -1)
	var below := float(Database.world_rules.get("first_hour", {}).get("auto_rest_below", 0.0))
	var health := 0
	var whole := 0
	for member: Character in GameState.party_characters():
		health += member.current_hp()
		whole += member.max_hp()
	if whole <= 0 or float(health) >= float(whole) * below:
		return Vector2i(-1, -1)
	var best := 1 << 30
	var stop := Vector2i(-1, -1)
	for site: Site in world.sites:
		if not site.kind in [Site.VILLAGE, Site.KEEP, Site.HUT]:
			continue
		if Town.is_ruined(site) or Town.is_threatened(site) or Pace.avoided.has(site.cell):
			continue
		if not Atlas.knows(world, site):
			continue
		var reach := Pathfinder.distance(world.player_cell, site.cell)
		if reach > 0 and reach < best:
			best = reach
			stop = site.cell
	return stop


## Nowhere known to go, so go and see somewhere: the nearest ground the party
## has never set eyes on. Kept until it is stood on, so the way is worked out
## once per stretch rather than every step.
static func _explore_target(world: World) -> Vector2i:
	var stale := _explore_to == world.player_cell or Pace.avoided.has(_explore_to)
	# With everything seen, looking again every step is a whole-map search for nothing.
	var due := _explore_to.x < 0 and world.steps - _explored_checked_at >= 20
	if stale or due:
		_explored_checked_at = world.steps
		_explore_to = Atlas.frontier(world, world.player_cell)
	return _explore_to


## The next step along the way to [param target], or, with nowhere to go,
## anything at all rather than stand still.
static func direction(world: World, target: Vector2i) -> Vector2i:
	_keep_to(world)
	if target.x >= 0:
		var here := world.player_cell
		while not _route.is_empty() and _route[0] == here:
			_route.pop_front()
		# A new target, or the party was moved off the route (a fight, a ferry,
		# a floor): work the way out again.
		if target != _target or _route.is_empty() or Pathfinder.distance(_route[0], here) != 1:
			_target = target
			# Something close (a band) is chased only a short way round; somewhere
			# far (a gate, the Tower) is worth whatever way there is.
			var close := Pathfinder.distance(here, target) <= DETOUR
			_route = Route.between(world, here, target, DETOUR * 3 if close else 0)
			if _route.is_empty() and here != target:
				# No way there on foot. Stop choosing it, and choose again next step.
				Pace.avoided[target] = true
		if not _route.is_empty():
			return _route[0] - here
	# Nowhere to go, so wander without doubling straight back.
	var loose: Array[Vector2i] = []
	for offset: Vector2i in STEPS:
		if world.is_walkable(world.player_cell + offset) and offset != -_last:
			loose.append(offset)
	if loose.is_empty():
		return -_last if world.is_walkable(world.player_cell - _last) else Vector2i.ZERO
	return loose[world.rng.randi() % loose.size()]


## A way worked out in another world is no way in this one.
static func _keep_to(world: World) -> void:
	if world == _world:
		return
	_world = world
	_last = Vector2i.ZERO
	_target = Vector2i(-1, -1)
	_route.clear()
	_explore_to = Vector2i(-1, -1)
	_explored_checked_at = -999
