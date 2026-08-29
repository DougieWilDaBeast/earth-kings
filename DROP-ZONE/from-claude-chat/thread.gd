class_name Thread
extends RefCounted
## Things that are not finished with you yet.
##
## An errand is one beat long: posted, walked, settled. A [Thread] is a chain of
## them that remembers itself. It ignites because of something already written
## down — gates you shut, a town you took, somebody who did not come back — and
## it advances on world state, never on a menu.
##
## There is no journal. A thread reaches the player the way everything else here
## does: as rumour at a site, a line in the hint bar, and eventually as somebody
## standing where you were going. See `docs/08-threads.md`.
##
## Pure logic. No scene nodes, no references to other systems — a thread can only
## ask the world things and call the same verbs the world already exposes.

## Why [method tick] was called. Some conditions only make sense on one of them.
const STEP := "step"
const ARRIVE := "arrive"
const BATTLE := "battle"
const FELL := "fell"

## A stage may only fire this many times in one tick. Content that chains longer
## than this is a loop, and a loop should be caught in the smoke test, not at 3am.
const MAX_ADVANCES := 4


static func rules() -> Dictionary:
	return Database.threads.get("rules", {})


static func definitions() -> Dictionary:
	return Database.threads.get("threads", {})


# --- the tick -----------------------------------------------------------------


## Ignite whatever is ready, then advance whatever holds. Returns notices worth
## putting in front of the player, in the same shape as `World.step`.
##
## [param context] carries the occasion and whatever it brought with it:
## `{ "occasion", "cell", "site_kind", "victory", "who", "tag" }`.
static func tick(world: World, context: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	lines.append_array(_ignite_ready(world, context))
	for thread_id: String in world.threads.keys():
		lines.append_array(_advance(world, thread_id, context))
	return lines


static func on_step(world: World) -> Array[String]:
	return tick(world, { "occasion": STEP, "cell": world.player_cell })


static func on_arrive(world: World, cell: Vector2i, site: Site) -> Array[String]:
	return tick(world, {
		"occasion": ARRIVE,
		"cell": cell,
		"site_kind": site.kind if site != null else "",
	})


static func on_battle(world: World, result: Dictionary) -> Array[String]:
	return tick(world, {
		"occasion": BATTLE,
		"cell": world.player_cell,
		"victory": bool(result.get("victory", false)),
	})


## Somebody went down for good. `character_dead` conditions wait on this.
static func on_character_fell(world: World, who: String) -> Array[String]:
	return tick(world, { "occasion": FELL, "cell": world.player_cell, "who": who })


# --- reading them -------------------------------------------------------------


## Tags set by every live thread. This is how a thread tells another system it is
## happening without either of them knowing about the other — [Banter] can ask
## whether "grieving" is set without knowing which thread set it.
static func tags(world: World) -> Array[String]:
	var found: Array[String] = []
	for thread_id: String in world.threads:
		for tag: String in world.threads[thread_id].get("tags", []):
			if not found.has(tag):
				found.append(tag)
	return found


static func has_tag(world: World, tag: String) -> bool:
	return tags(world).has(tag)


## A thread's own scratch memory: what it did, and what you did to it.
static func recall(world: World, thread_id: String, key: String, fallback: Variant = null) -> Variant:
	return world.threads.get(thread_id, {}).get("memory", {}).get(key, fallback)


static func remember(world: World, thread_id: String, key: String, value: Variant) -> void:
	if not world.threads.has(thread_id):
		return
	world.threads[thread_id]["memory"][key] = value


static func is_live(world: World, thread_id: String) -> bool:
	var state: Dictionary = world.threads.get(thread_id, {})
	return not state.is_empty() and not bool(state.get("done", false))


# --- ignition -----------------------------------------------------------------


static func _ignite_ready(world: World, context: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for thread_id: String in definitions():
		if world.threads.has(thread_id):
			continue
		var definition: Dictionary = definitions()[thread_id]
		if not _holds(world, {}, definition.get("ignite", {}), context):
			continue
		world.threads[thread_id] = {
			"stage": 0,
			"entered_at": world.steps,
			"memory": {},
			"tags": [],
			"done": false,
		}
		# A thread starts quietly. Whatever the player should notice is a stage's
		# job, so ignition can sit under something loud without competing with it.
	return lines


# --- advancing ----------------------------------------------------------------


static func _advance(world: World, thread_id: String, context: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var state: Dictionary = world.threads[thread_id]
	var stages: Array = definitions().get(thread_id, {}).get("stages", [])

	for _pass in MAX_ADVANCES:
		if bool(state.get("done", false)):
			break
		var index := int(state.get("stage", 0))
		if index >= stages.size():
			state["done"] = true
			break

		var stage: Dictionary = stages[index]
		var target := index + 1

		if _holds(world, state, stage.get("when", {}), context):
			lines.append_array(_apply(world, thread_id, stage.get("then", []), context))
		elif _overdue(world, state, stage):
			# Q13: a thread never cancels. It runs out of patience and goes
			# somewhere worse instead, because that is a door you cannot reopen.
			lines.append_array(_apply(world, thread_id, stage.get("instead", []), context))
			target = _stage_index(stages, String(stage.get("goto", "")), index + 1)
		else:
			break

		state["stage"] = target
		state["entered_at"] = world.steps
		if target >= stages.size():
			state["done"] = true
	return lines


static func _overdue(world: World, state: Dictionary, stage: Dictionary) -> bool:
	var deadline := int(stage.get("deadline", 0))
	if deadline <= 0:
		return false
	return world.steps - int(state.get("entered_at", 0)) >= deadline


static func _stage_index(stages: Array, stage_id: String, fallback: int) -> int:
	if stage_id == "":
		return fallback
	for i in stages.size():
		if String(stages[i].get("id", "")) == stage_id:
			return i
	push_warning("Thread: no stage named '%s'" % stage_id)
	return fallback


# --- conditions ---------------------------------------------------------------


## Every key in [param condition] must hold. Alternatives are separate stages,
## which reads longer and is worth it — a stage should be one situation.
static func _holds(world: World, state: Dictionary, condition: Dictionary, context: Dictionary) -> bool:
	if condition.is_empty():
		return true
	var occasion := String(context.get("occasion", ""))
	var cell: Vector2i = context.get("cell", world.player_cell)

	for key: String in condition:
		var want: Variant = condition[key]
		match key:
			"count":
				continue  # read alongside "deed"
			"steps_since_stage":
				if world.steps - int(state.get("entered_at", world.steps)) < int(want):
					return false
			"steps_since_start":
				if world.steps < int(want):
					return false
			"deed":
				if _deed_count(world, String(want)) < int(condition.get("count", 1)):
					return false
			"arrive_kind":
				if occasion != ARRIVE or String(context.get("site_kind", "")) != String(want):
					return false
			"battle_won":
				if occasion != BATTLE or bool(context.get("victory", false)) != bool(want):
					return false
			"character_dead":
				if occasion != FELL:
					return false
				if String(want) != "any" and String(context.get("who", "")) != String(want):
					return false
			"standing_below":
				if Renown.standing(world, cell) >= int(want):
					return false
			"standing_above":
				if Renown.standing(world, cell) <= int(want):
					return false
			"tag":
				if not has_tag(world, String(want)):
					return false
			"remembers":
				if not state.get("memory", {}).has(String(want)):
					return false
			"thread_done":
				var other: Dictionary = world.threads.get(String(want), {})
				if not bool(other.get("done", false)):
					return false
			_:
				push_warning("Thread: unknown condition '%s'" % key)
				return false
	return true


static func _deed_count(world: World, kind: String) -> int:
	var total := 0
	for deed: Dictionary in world.deeds:
		if String(deed.get("kind", "")) == kind:
			total += 1
	return total


# --- effects ------------------------------------------------------------------


## A thread cannot do anything the world could not already do. Every effect here
## is a call into something that ships; the thread only decides when.
static func _apply(world: World, thread_id: String, effects: Array, context: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var here: Vector2i = context.get("cell", world.player_cell)
	var state: Dictionary = world.threads[thread_id]

	for effect: Dictionary in effects:
		for key: String in effect:
			match key:
				"rumour":
					var at := _cell_named(world, String(effect.get("at", "here")), here)
					Renown.record(
						world, "thread", at,
						int(effect.get("weight", 0)), String(effect[key])
					)
				"hint":
					lines.append(String(effect[key]))
				"remember":
					for field: String in effect[key]:
						state["memory"][field] = effect[key][field]
				"tag":
					if not state["tags"].has(String(effect[key])):
						state["tags"].append(String(effect[key]))
				"untag":
					state["tags"].erase(String(effect[key]))
				"errand":
					var posted := _post_errand(world, thread_id, effect[key], here)
					if posted != "":
						lines.append(posted)
				"site":
					var raised := _raise_site(world, thread_id, effect[key], here)
					if raised != "":
						lines.append(raised)
				_:
					# `nemesis` and `grant` arrive with stage 3. Anything else is
					# a typo in the content, and should be loud about it.
					push_warning("Thread: unknown effect '%s' in '%s'" % [key, thread_id])
	return lines


## Where a rumour is written down. Word still has to travel from there.
static func _cell_named(world: World, name_: String, here: Vector2i) -> Vector2i:
	match name_:
		"here":
			return here
		"last_deed":
			if world.deeds.is_empty():
				return here
			var pair: Array = world.deeds[world.deeds.size() - 1].get("cell", [here.x, here.y])
			return Vector2i(int(pair[0]), int(pair[1]))
		_:
			var site := _nearest_of_kind(world, name_, here)
			return site.cell if site != null else here


static func _nearest_of_kind(world: World, kind: String, from: Vector2i) -> Site:
	var best: Site = null
	var best_distance := 1 << 30
	for site in world.sites_of_kind(kind):
		var distance := Pathfinder.distance(from, site.cell)
		if distance < best_distance:
			best_distance = distance
			best = site
	return best


## Put an authored job on a real board. It is an ordinary errand once it is
## there — [Errand] settles it without knowing a thread wrote it.
static func _post_errand(world: World, thread_id: String, spec: Dictionary, here: Vector2i) -> String:
	var site := _nearest_of_kind(world, String(spec.get("site_kind", Site.VILLAGE)), here)
	if site == null:
		return ""
	site.data["errand"] = {
		"kind": String(spec.get("kind", Errand.LOOK)),
		"title": String(spec.get("title", "A word with you")),
		"text": String(spec.get("text", "")),
		"giver": String(spec.get("giver", "somebody who has been waiting")),
		"gold": int(spec.get("gold", 0)),
		"from": [site.cell.x, site.cell.y],
		"from_name": site.display_name,
		"to": [site.cell.x, site.cell.y],
		"to_name": site.display_name,
		"thread": thread_id,
	}
	return "Somebody at %s is asking for you." % site.display_name


static func _raise_site(world: World, thread_id: String, spec: Dictionary, here: Vector2i) -> String:
	var anchor := _cell_named(world, String(spec.get("near", "here")), here)
	var cell := _free_cell_near(world, anchor)
	if cell == Vector2i(-1, -1):
		return ""
	var site := Site.create(
		String(spec.get("kind", Site.HUT)), cell, String(spec.get("name", "A camp"))
	)
	site.data["thread"] = thread_id
	world.sites.append(site)
	return String(spec.get("hint", ""))


## Walkable ground nothing else has claimed, spiralling out from [param cell].
static func _free_cell_near(world: World, cell: Vector2i) -> Vector2i:
	for radius in range(1, 8):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if absi(dx) != radius and absi(dy) != radius:
					continue
				var candidate := cell + Vector2i(dx, dy)
				if not world.in_bounds(candidate) or not world.is_walkable(candidate):
					continue
				if world.site_at(candidate) != null:
					continue
				return candidate
	return Vector2i(-1, -1)
