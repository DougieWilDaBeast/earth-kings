extends RefCounted
## The others (M13, docs/17): the rest of the sixteen, living their own lives.
##
## Every hero the run did not start with crash-lands somewhere of their own and
## walks off, by temper, from one kind of place to the next: the cold-eyed and
## sky-read to libraries and the Tower, the ground-read and loose to gates and
## the arena, and so on (`data/fall.json` → `wanderers.preferences`). The
## company learns where they are by hearing it at an inn or by standing where
## they stand, and can talk to them there and, if they are willing, have them
## walk along.
##
## Loaded by path ([D41]). Pure logic: no nodes. Each wanderer is a plain
## dictionary in [member World.wanderers], so it saves with the world:
## `{ id, at: [x, y], to: [x, y] | [], arrives, stay_until, met, known: [x, y] | [],
## known_at, heard, joined }`. Moves are drawn from the world seed, the hero and
## the step, never from [member World.rng].

const Fall := preload("res://src/chronicle/fall.gd")
const Siblings := preload("res://src/chronicle/siblings.gd")

## The flag a conversation sets when somebody agrees to walk with you; settled
## by [method settle] once the conversation is over.
const JOIN_FLAG := "wanderer:join:"
## Every conversation with one of them is registered under this, plus their id.
const DIALOGUE_PREFIX := "wanderer:"
## Never somewhere to go: your own roof, and graves.
const NOWHERE := [Site.HOME, Site.GRAVE]


static func rules() -> Dictionary:
	return Database.fall.get("wanderers", {})


static func pace() -> Dictionary:
	return Database.fall.get("wanderers", {}).get("rules", {})


static func lines() -> Dictionary:
	return Database.fall.get("wanderers", {}).get("lines", {})


# --- who they are -------------------------------------------------------------


static func name_of(hero_id: String) -> String:
	return str(Database.unit_template(hero_id).get("display_name", hero_id.capitalize()))


static func title_of(hero_id: String) -> String:
	return str(Database.hero(hero_id).get("title", ""))


## Their temper. The sixteen's own slot wins when one is written; until then it
## is the inferred one in `data/fall.json`.
static func temper_of(hero_id: String) -> String:
	var written := Database.hero_temper(hero_id)
	if written != "":
		return written
	return str(rules().get("tempers", {}).get(hero_id, "ISTJ"))


## NT, NF, SJ or SP: the pair that says most about where somebody goes.
static func group_of(hero_id: String) -> String:
	var code := temper_of(hero_id)
	if code.length() < 4:
		return "SJ"
	return ("N" + code[2]) if code[1] == "N" else ("S" + code[3])


# --- landing ------------------------------------------------------------------


## Bring the others down, one crash site each, and set them walking. Everyone
## in `data/heroes.json` who is not already on the roster is one of them.
static func land(world: World, roster: Roster, reach: Dictionary = {}) -> void:
	world.wanderers = []
	if reach.is_empty():
		reach = Fall.reachable(world)
	var taken: Array = []
	for character: Character in roster.characters:
		taken.append(character.template_id)
	for hero_id: String in Database.heroes:
		if hero_id in taken:
			continue
		var cell := Fall.crash_cell(world, hero_id, reach)
		var entry := {
			"id": hero_id,
			"at": [cell.x, cell.y],
			"to": [],
			"arrives": 0,
			"stay_until": 0,
			"met": 0,
			"known": [],
			"known_at": -1,
			"heard": false,
			"joined": false,
		}
		_set_off(world, entry)
		world.wanderers.append(entry)


# --- moving -------------------------------------------------------------------


## Called from the world's upkeep: anyone who has reached where they were going
## stops there a while, and anyone who has stayed long enough sets off again.
static func upkeep(world: World) -> Array:
	for entry: Dictionary in world.wanderers:
		if bool(entry.get("joined", false)):
			continue
		var to: Array = entry.get("to", [])
		if not to.is_empty():
			if world.steps >= int(entry.get("arrives", 0)):
				entry["at"] = [int(to[0]), int(to[1])]
				entry["to"] = []
				var rng := _dice(world, entry)
				entry["stay_until"] = world.steps + rng.randi_range(
					int(pace().get("stay_min", 60)), int(pace().get("stay_max", 180))
				)
		elif world.steps >= int(entry.get("stay_until", 0)):
			_set_off(world, entry)
	return []


static func _set_off(world: World, entry: Dictionary) -> void:
	var rng := _dice(world, entry)
	var from := cell_of(entry.get("at", []))
	var next := _next_place(world, str(entry.get("id", "")), from, rng)
	if next == null:
		entry["stay_until"] = world.steps + int(pace().get("stay_min", 60))
		return
	entry["to"] = [next.cell.x, next.cell.y]
	entry["arrives"] = world.steps + maxi(1, Pathfinder.distance(from, next.cell) * int(pace().get("steps_per_tile", 2)))


## Somewhere to go next, weighted by how much this temper likes that kind of
## place and by how near it is.
static func _next_place(world: World, hero_id: String, from: Vector2i, rng: RandomNumberGenerator) -> Site:
	var likes: Dictionary = rules().get("preferences", {}).get(group_of(hero_id), {})
	var options: Array[Site] = []
	var weights: Array[float] = []
	var total := 0.0
	for site: Site in world.sites:
		if NOWHERE.has(site.kind) or site.cell == from:
			continue
		if Town.is_ruined(site) or (site.kind == Site.GATE and site.cleared):
			continue
		var liking := float(likes.get(site.kind, 0))
		if liking <= 0.0:
			continue
		var weight := liking * 10.0 / float(maxi(4, Pathfinder.distance(from, site.cell)))
		options.append(site)
		weights.append(weight)
		total += weight
	if options.is_empty():
		return null
	var roll := rng.randf() * total
	for i in options.size():
		roll -= weights[i]
		if roll <= 0.0:
			return options[i]
	return options[-1]


static func _dice(world: World, entry: Dictionary) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.world_seed, str(entry.get("id", "")), world.steps, "wander"])
	return rng


static func cell_of(pair: Variant) -> Vector2i:
	if pair is Array and (pair as Array).size() >= 2:
		return Vector2i(int(pair[0]), int(pair[1]))
	return Vector2i(-1, -1)


# --- where they are -----------------------------------------------------------


static func entry(world: World, hero_id: String) -> Dictionary:
	for each: Dictionary in world.wanderers:
		if str(each.get("id", "")) == hero_id:
			return each
	return {}


## Who is standing at [param cell] right now, not on the road and not with you.
static func here(world: World, cell: Vector2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for each: Dictionary in world.wanderers:
		if bool(each.get("joined", false)) or not (each.get("to", []) as Array).is_empty():
			continue
		if cell_of(each.get("at", [])) == cell:
			out.append(each)
	return out


## Walking onto a place where one of them stands: you see them, and the mark.
static func on_arrive(world: World, site: Site) -> Array:
	var out: Array = []
	if site == null:
		return out
	for each: Dictionary in here(world, site.cell):
		_know(world, each, site.cell, false)
		out.append(_say(str(lines().get("seen_note", "{name} is here.")), str(each["id"]), world, site))
	return out


static func _know(world: World, each: Dictionary, cell: Vector2i, heard: bool) -> void:
	each["known"] = [cell.x, cell.y]
	each["known_at"] = world.steps
	each["heard"] = heard


## Everyone the company knows anything about, freshest first, for the journal
## and the map.
static func known(world: World) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for each: Dictionary in world.wanderers:
		if bool(each.get("joined", false)) or not (each.get("known", []) as Array).is_empty():
			out.append(each)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("known_at", -1)) > int(b.get("known_at", -1))
	)
	return out


## A line for the journal: who they are and where they were last seen or heard of.
static func whereabouts(world: World, each: Dictionary) -> String:
	var hero_id := str(each.get("id", ""))
	if bool(each.get("joined", false)):
		return "%s — walks with you." % name_of(hero_id)
	var place := world.site_at(cell_of(each.get("known", [])))
	var where := place.display_name if place != null else "somewhere on the road"
	return "%s, %s — %s %s, step %d." % [
		name_of(hero_id), title_of(hero_id),
		"heard of at" if bool(each.get("heard", false)) else "seen at",
		where, int(each.get("known_at", 0)),
	]


## A rumour for whoever is asking at an inn. Points at somebody the company has
## the stalest word of, and leaves them known where the rumour says.
static func rumour(world: World) -> String:
	var pool: Array[Dictionary] = []
	for each: Dictionary in world.wanderers:
		if not bool(each.get("joined", false)):
			pool.append(each)
	if pool.is_empty():
		return ""
	pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("known_at", -1)) < int(b.get("known_at", -1))
	)
	var each: Dictionary = pool[randi() % mini(3, pool.size())]
	var hero_id := str(each["id"])
	var to: Array = each.get("to", [])
	if not to.is_empty():
		var going := world.site_at(cell_of(to))
		_know(world, each, cell_of(to), true)
		return _say(str(lines().get("rumour_road", "")), hero_id, world, going)
	var site := world.site_at(cell_of(each.get("at", [])))
	if site == null:
		return ""
	_know(world, each, site.cell, true)
	var said: Array = lines().get("rumour", [])
	if said.is_empty():
		return ""
	return _say(str(said[randi() % said.size()]), hero_id, world, site)


# --- meeting ------------------------------------------------------------------


## Build the conversation with [param hero_id], counting the meeting, and
## register it so the dialogue box can play it. Returns its dialogue id.
static func talk(world: World, roster: Roster, hero_id: String) -> String:
	var each := entry(world, hero_id)
	if each.is_empty():
		return ""
	each["met"] = int(each.get("met", 0)) + 1
	var site := world.site_at(cell_of(each.get("at", [])))
	if site != null:
		_know(world, each, site.cell, false)
	var id := DIALOGUE_PREFIX + hero_id
	Database.register_dialogue(id, conversation(world, roster, hero_id))
	return id


static func conversation(world: World, roster: Roster, hero_id: String) -> Dictionary:
	var each := entry(world, hero_id)
	var said := lines()
	var group := group_of(hero_id)
	var site := world.site_at(cell_of(each.get("at", [])))
	var who := name_of(hero_id)
	var first := int(each.get("met", 1)) <= 1
	var greeting: Array = said.get("first" if first else "again", {}).get(group, [])

	var join_to := "join"
	if roster.party.size() >= Roster.MAX_PARTY:
		join_to = "full"
	elif int(each.get("met", 0)) < meetings_to_join(hero_id):
		join_to = "not_yet"

	var nodes := {
		"greet": {
			"speaker": who,
			"text": _say(str(greeting[0]) if not greeting.is_empty() else "...", hero_id, world, site),
			"options": [
				{ "text": str(said.get("ask_heading", "Where are you headed?")), "goto": "heading" },
				{ "text": str(said.get("ask_join", "Walk with us.")), "goto": join_to },
				{ "text": str(said.get("leave", "Another time.")), "goto": "end" },
			],
		},
		"heading": {
			"speaker": who,
			"text": _say(str(said.get("heading", {}).get(_heading_kind(world, each), "")), hero_id, world, site),
			"next": "end",
		},
		"join": {
			"speaker": who,
			"text": _say(str(said.get("join_yes", "")), hero_id, world, site),
			"set_flag": JOIN_FLAG + hero_id,
			"next": "end",
		},
		"not_yet": { "speaker": who, "text": _say(str(said.get("join_not_yet", "")), hero_id, world, site), "next": "end" },
		"full": { "speaker": who, "text": _say(str(said.get("join_full", "")), hero_id, world, site), "next": "end" },
	}
	var start := "greet"
	# An earlier lead's copy (M15, [D52]): you know them, and they do not know you.
	var echo := Siblings.echo_lines(world, hero_id, group) if bool(each.get("echo", false)) else {}
	if not echo.is_empty():
		(nodes["greet"]["options"] as Array).insert(0, { "text": str(echo["ask"]), "goto": "echo" })
		nodes["echo"] = { "speaker": who, "text": str(echo["answer"]), "next": "end" }
		if first:
			nodes["echo_seen"] = { "speaker": "", "text": str(echo["seen"]), "next": "greet" }
			start = "echo_seen"
	if first:
		var recognised: Array = said.get("recognised", [])
		if not recognised.is_empty():
			nodes["mark"] = { "speaker": "", "text": _say(str(recognised[0]), hero_id, world, site), "next": start }
			start = "mark"
	return { "cast": { who: hero_id }, "start": start, "nodes": nodes }


## An outward temper walks with you on the first meeting; an inward one wants
## to have met you before.
static func meetings_to_join(hero_id: String) -> int:
	var need: Dictionary = pace().get("meetings_to_join", {})
	var letter := temper_of(hero_id).substr(0, 1)
	return int(need.get(letter, 1))


## The kind of place they will go to next: where they are walking, or the kind
## their temper likes best.
static func _heading_kind(world: World, each: Dictionary) -> String:
	var going := world.site_at(cell_of(each.get("to", [])))
	if going != null:
		return going.kind
	var likes: Dictionary = rules().get("preferences", {}).get(group_of(str(each.get("id", ""))), {})
	var best := Site.TOWER
	var most := -1.0
	for kind: String in likes:
		if float(likes[kind]) > most:
			most = float(likes[kind])
			best = kind
	return best


## Anyone who agreed, in a conversation now over, to walk with the company
## joins it. Safe to call more than once. Returns lines worth showing.
static func settle(world: World, roster: Roster, flags: Dictionary) -> Array:
	var out: Array = []
	for each: Dictionary in world.wanderers:
		var key := JOIN_FLAG + str(each.get("id", ""))
		if not flags.has(key):
			continue
		flags.erase(key)
		if bool(each.get("joined", false)):
			continue
		var recruit := join(world, roster, str(each["id"]))
		if recruit != null:
			out.append(joined_line(world, recruit.template_id))
	return out


static func joined_line(world: World, hero_id: String) -> String:
	return _say(str(lines().get("joined_note", "{name} falls in with you.")), hero_id, world, null)


## Take [param hero_id] onto the roster and into the marching order, at the
## lead's level. Null when there is no room or nobody by that name out there.
static func join(world: World, roster: Roster, hero_id: String) -> Character:
	var each := entry(world, hero_id)
	if each.is_empty() or bool(each.get("joined", false)) or roster.party.size() >= Roster.MAX_PARTY:
		return null
	var recruit := Character.create(hero_id)
	var lead := roster.player()
	Progression.raise_quietly(recruit, lead.level if lead != null else 1, world)
	if bool(each.get("echo", false)):
		Siblings.shape(world, recruit)
	for member: Character in roster.party_members():
		var initial := Banter.initial_bond(member, recruit)
		member.bonds[recruit.id] = initial
		recruit.bonds[member.id] = initial
	roster.add(recruit)
	roster.enlist(recruit.id)
	each["joined"] = true
	each["to"] = []
	if GameState.tallying:
		Ledger.add(GameState.ledger, "recruited")
	Annals.record(world, "%s, who carries the same mark, joined the company." % recruit.display_name)
	return recruit


static func _say(line: String, hero_id: String, world: World, site: Site) -> String:
	var lead := GameState.roster.player() if GameState.roster != null else null
	return line.format({
		"name": name_of(hero_id),
		"title": title_of(hero_id),
		"place": site.display_name if site != null else "the road",
		"lead": lead.display_name if lead != null else "friend",
	})
