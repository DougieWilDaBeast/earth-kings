class_name Memorial
extends RefCounted
## Where somebody fell, and the fact that the world keeps it.
##
## Permadeath is only a rule until it is a place. A grave is a [Site] like any
## other — it goes on the map, it can be walked back to, and walking back to it
## is worth doing: talking about someone reinforces everything the party is
## carrying, and once, exactly once, a grave will hand on something the dead
## knew.


static func rules() -> Dictionary:
	return Database.memorials


static func is_grave(site: Site) -> bool:
	return site != null and site.kind == Site.GRAVE


## Put a marker where [param character] went down. Graves never overwrite a
## place that was already there — the dead give way to the living.
static func raise(world: World, character: Character, cell: Vector2i, killer: String = "") -> Site:
	var where := _free_cell_near(world, cell)
	var site := Site.create(Site.GRAVE, where, "The grave of %s" % character.display_name)
	site.data = {
		"character_id": character.id,
		"name": character.display_name,
		"level": character.level,
		"job": character.class_name_text(),
		"killer": killer,
		"fell_at": world.steps,
		"doctrine": character.doctrine.duplicate(),
		"visited": false,
		"passed_on": false,
	}
	world.sites.append(site)
	return site


## What standing here is worth. Reinforcing is the point: knowledge fades when
## it is not used, and remembering somebody counts as using it.
static func visit(site: Site, world: World, party: Array) -> Array[String]:
	if not is_grave(site):
		return []

	var lines: Array[String] = [epitaph(site, world)]
	var first := not bool(site.data.get("visited", false))
	site.data["visited"] = true

	var pool: Array = rules().get("first_visit" if first else "return_visit", [""])
	lines.append(pool[world.rng.randi() % pool.size()])

	if party.is_empty():
		lines.append(rules().get("lonely", ""))
		return lines

	for character: Character in party:
		Doctrine.reinforce_all(character, world.steps)
	lines.append(rules().get("reinforced", ""))

	var handed := _pass_something_on(site, world, party)
	if handed != "":
		lines.append(handed)
	return lines


static func epitaph(site: Site, world: World) -> String:
	var elapsed := world.steps - int(site.data.get("fell_at", world.steps))
	var head := "%s, level %d %s. Fell %d steps ago." % [
		site.data.get("name", "Someone"),
		int(site.data.get("level", 1)),
		str(site.data.get("job", "")).to_lower(),
		elapsed,
	]
	return "%s %s" % [head, _elapsed_text(elapsed)]


static func _elapsed_text(elapsed: int) -> String:
	for band: Dictionary in rules().get("elapsed", []):
		if elapsed < int(band.get("under", 0)):
			return band.get("text", "")
	return ""


## A grave gives up what it knew once, and then it is only a grave.
static func _pass_something_on(site: Site, world: World, party: Array) -> String:
	if bool(site.data.get("passed_on", false)):
		return ""
	var carried: Array = site.data.get("doctrine", [])
	if carried.is_empty():
		return ""

	for doctrine_id: String in carried:
		for character: Character in party:
			if character.knows(doctrine_id):
				continue
			Doctrine.learn(character, doctrine_id, world.steps)
			site.data["passed_on"] = true
			var pool: Array = rules().get("inheritance", [""])
			return "%s reads %s. %s" % [
				character.display_name,
				Doctrine.title(doctrine_id),
				pool[world.rng.randi() % pool.size()],
			]
	return ""


## Somewhere walkable that nothing else has already claimed.
static func _free_cell_near(world: World, cell: Vector2i) -> Vector2i:
	if world.is_walkable(cell) and world.site_at(cell) == null:
		return cell
	for radius in range(1, 5):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var candidate := cell + Vector2i(dx, dy)
				if world.is_walkable(candidate) and world.site_at(candidate) == null:
					return candidate
	return cell
