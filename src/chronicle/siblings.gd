extends RefCounted
## Sixteen worlds (M15, docs/17, [D32], [D33], [D52]): what is kept when a
## world ends with its lead, and what comes through into the next one.
##
## A lead who dies and ascends takes their world with them. What is kept of it
## is written into the record of the fallen ([code]sixteen.gd[/code]) by
## [method remember]: who they were, how far they got, and the journal of the
## run, a page per thing they did. The next run is a **sibling world**: built on
## the first fallen world's seed, so the ground, the places and where everyone
## comes down are the same, then [method perturb] redeals a share of the
## world's dice (`data/fall.json` → `siblings.perturbation`).
##
## Into it come, for every lead who died before ([method arrive]):
## - **the copy of them that never fell** ([D52]), an ordinary person of the
##   sixteen with the personality they started with, waiting at the settlement
##   nearest where the new lead came down;
## - **their signature weapon**, which crash-lands near where the new lead fell
##   once the new lead has got as far as they did ([method upkeep]), and which
##   rumours point to;
## - **their ghost**, at the campfire from the same moment, sharing the journal
##   a page at a time as their temper and the nights at the fire allow, and all
##   of it once the weapon is found.
##
## The when, the where and the how much are all **Inferred** (agenda items 50
## to 55). Everything lives in [member World.echoes], so it saves with the
## world: `{ sibling, base_seed, past: [echo] }`, each echo
## `{ hero, name, temper, level, floor, killer, well, pages, self, arrived,
## visits, weapon: { id, cell, landed, heard, found } }`.
##
## Loaded by path ([D41]). Pure logic: no nodes.

const Fall := preload("res://src/chronicle/fall.gd")

## A ghost is spoken to under this, plus their place in the past.
const GHOST_PREFIX := "ghost:"
## The settlements an earlier lead can be waiting at.
const HAVENS := [Site.VILLAGE, Site.KEEP, Site.HUT]
## Pages of the journal kept per kind, so one long run does not drown the rest.
const MOST_PLACES := 6
const MOST_BEASTS := 4


static func rules() -> Dictionary:
	return Database.fall.get("siblings", {})


static func lines() -> Dictionary:
	return rules().get("lines", {})


## The weapon made for [param hero_id], or empty for nobody.
static func signature_of(hero_id: String) -> String:
	return str(rules().get("signatures", {}).get(hero_id, ""))


# --- the world that ends ------------------------------------------------------


## What is kept of [param world] when its lead dies: enough to build the copy of
## them, drop their weapon, and let their ghost talk.
static func remember(world: World, roster: Roster, ledger: Dictionary) -> Dictionary:
	if world == null or roster == null or roster.player() == null:
		return {}
	var lead := roster.player()
	var killer := ""
	for entry: Dictionary in Ledger.the_fallen(world, roster):
		if str(entry.get("name", "")) == lead.display_name:
			killer = str(entry.get("killer", ""))
			break
	return {
		"hero": lead.template_id,
		"name": lead.display_name,
		"temper": _temper_of(lead),
		"level": lead.level,
		"floor": world.tower_floor,
		"steps": world.steps,
		"seed": world.world_seed,
		"base_seed": int(world.echoes.get("base_seed", world.world_seed)),
		"sibling": int(world.echoes.get("sibling", 0)),
		"killer": killer,
		"weapon": signature_of(lead.template_id),
		"well": _what_went_well(world, ledger),
		"pages": journal_pages(world, ledger),
		# The personality they started with ([D52]), not what the run made of it.
		"self": {
			"class_id": lead.class_id,
			"background": lead.background,
			"creed": lead.creed,
			"grudge": lead.grudge,
			"hearth": lead.hearth,
			"oath": lead.oath,
			"temper": _temper_of(lead),
		},
	}


static func _temper_of(character: Character) -> String:
	if character.temper != "":
		return character.temper
	var written := Database.hero_temper(character.template_id)
	if written != "":
		return written
	return str(Database.fall.get("wanderers", {}).get("tempers", {}).get(character.template_id, "ISTJ"))


## The journal of the run, as the ghost will tell it: one line per thing done,
## gates first, then the people met, the places stood in and what was learned
## by fighting it.
static func journal_pages(world: World, ledger: Dictionary) -> Array:
	var pages: Array = []
	for site: Site in world.sites_of_kind(Site.GATE):
		if site.cleared:
			pages.append("I shut %s, a rank %s gate. In your world it is still open." % [site.display_name, site.rank])
	for each: Dictionary in world.wanderers:
		if int(each.get("met", 0)) <= 0:
			continue
		var who := str(Database.unit_template(str(each.get("id", ""))).get("display_name", each.get("id", "")))
		var place := world.site_at(cell_of(each.get("known", [])))
		var where := place.display_name if place != null else "on the road"
		if bool(each.get("joined", false)):
			pages.append("%s walked with me. I met them first near %s." % [who, where])
		else:
			pages.append("I met %s at %s. They carry the mark." % [who, where])
	var places: Array = ledger.get("places", [])
	for i in mini(MOST_PLACES, places.size()):
		pages.append("I stood in %s. It is there in your world too." % places[i])
	var beasts := 0
	for template_id: String in world.journal:
		if beasts >= MOST_BEASTS:
			break
		var entry: Dictionary = world.journal[template_id]
		if int(entry.get("felled", 0)) <= 0:
			continue
		var what := str(Database.unit_template(template_id).get("display_name", template_id))
		pages.append("I learned how to put down %s. Go for them before they go for you." % what)
		beasts += 1
	return pages


static func _what_went_well(world: World, ledger: Dictionary) -> String:
	var shut := 0
	for site: Site in world.sites_of_kind(Site.GATE):
		if site.cleared:
			shut += 1
	var won := Ledger.count(ledger, "battles_won")
	if shut == 0 and won == 0:
		return ""
	return "I won %d fights and shut %d gate%s. The Tower got to floor %d with me on it." % [
		won, shut, "" if shut == 1 else "s", world.tower_floor
	]


## [param pair] as a cell, or (-1, -1).
static func cell_of(pair: Variant) -> Vector2i:
	if pair is Array and (pair as Array).size() >= 2:
		return Vector2i(int(pair[0]), int(pair[1]))
	return Vector2i(-1, -1)


# --- the next world -----------------------------------------------------------


## The seed every sibling is built on: the first world's.
static func base_seed(past: Array) -> int:
	if past.is_empty():
		return 0
	var first: Dictionary = past[0]
	return int(first.get("base_seed", first.get("seed", 0)))


## Make [param world] the [param sibling]th world after the first: the same
## ground and places, with a share of what the dice dealt dealt again. Zero is
## the first world and leaves it alone.
static func perturb(world: World, sibling: int) -> void:
	world.echoes["base_seed"] = world.world_seed
	world.echoes["sibling"] = sibling
	if sibling <= 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.world_seed, "sibling", sibling])
	var share := clampf(float(rules().get("perturbation", 0.25)), 0.0, 1.0)
	for gate: Site in world.sites_of_kind(Site.GATE):
		if rng.randf() < share:
			gate.open = rng.randf() < 0.5
	# The first library always holds the first book (docs/16); the rest trade
	# shelves.
	var libraries := world.sites_of_kind(Site.LIBRARY)
	for i in range(1, libraries.size()):
		if libraries.size() < 3 or rng.randf() >= share:
			continue
		var j := 1 + rng.randi() % (libraries.size() - 1)
		var swap: Variant = libraries[i].data.get("doctrine", "")
		libraries[i].data["doctrine"] = libraries[j].data.get("doctrine", "")
		libraries[j].data["doctrine"] = swap
	# The world's own dice start somewhere else, so it does not play out
	# move for move.
	world.rng.seed = hash([world.world_seed, "sibling", sibling, "dice"])


## Bring the worlds that ended into this one: each earlier lead alive and
## waiting somewhere findable, their weapon on its way, their ghost not yet at
## the fire. Called once the lead has landed and the others are down.
static func arrive(world: World, roster: Roster, past: Array, reach: Dictionary = {}) -> void:
	world.echoes["past"] = []
	if past.is_empty():
		return
	if reach.is_empty():
		reach = Fall.reachable(world)
	var home := world.home()
	var fell_at: Vector2i = home.cell if home != null else world.player_cell
	var haven := _nearest_haven(world, fell_at)
	var on_roster: Array = []
	for character: Character in roster.characters:
		on_roster.append(character.template_id)
	for record: Dictionary in past:
		var hero := str(record.get("hero", ""))
		if hero == "":
			continue
		var weapon_id := str(record.get("weapon", signature_of(hero)))
		var cell := _weapon_cell(world, fell_at, hero, reach)
		var echo := {
			"hero": hero,
			"name": str(record.get("name", hero)),
			"temper": str(record.get("temper", "")),
			"level": int(record.get("level", 1)),
			"floor": int(record.get("floor", 0)),
			"killer": str(record.get("killer", "")),
			"well": str(record.get("well", "")),
			"pages": (record.get("pages", []) as Array).duplicate(),
			"self": (record.get("self", {}) as Dictionary).duplicate(),
			"arrived": false,
			"visits": 0,
			"weapon": {
				"id": weapon_id, "cell": [cell.x, cell.y],
				"landed": false, "heard": false, "found": false,
			},
		}
		world.echoes["past"].append(echo)
		# The copy of them in this world, unless they came down in the company.
		if on_roster.has(hero) or haven == null:
			continue
		for each: Dictionary in world.wanderers:
			if str(each.get("id", "")) != hero:
				continue
			each["echo"] = true
			each["at"] = [haven.cell.x, haven.cell.y]
			each["to"] = []
			each["stay_until"] = world.steps + int(rules().get("echo", {}).get("stay_steps", 400))
			each["known"] = [haven.cell.x, haven.cell.y]
			each["known_at"] = world.steps
			each["heard"] = true


static func _nearest_haven(world: World, from: Vector2i) -> Site:
	var best: Site = null
	var nearest := 1 << 30
	for site: Site in world.sites:
		if not HAVENS.has(site.kind) or Town.is_ruined(site):
			continue
		var apart := Pathfinder.distance(site.cell, from)
		if apart < nearest:
			nearest = apart
			best = site
	return best


## Where the weapon comes down. With `anywhere` (D60, `doug-md`'s answer to agenda
## item 12) it is any open ground the company can walk to, at least `min_distance`
## from where the lead fell, and only the rumour says which way; without it, open
## ground a short walk off (the earlier "easy to find" reading). The same for the
## same seed.
static func _weapon_cell(world: World, from: Vector2i, hero: String, reach: Dictionary) -> Vector2i:
	var said: Dictionary = rules().get("weapon", {})
	var near := int(said.get("min_distance", 5))
	var far := maxi(near, int(said.get("max_distance", 12)))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.world_seed, int(world.echoes.get("sibling", 0)), "weapon", hero])
	if bool(said.get("anywhere", false)):
		var open: Array[Vector2i] = []
		for cell: Vector2i in reach:
			if Pathfinder.distance(cell, from) >= near and world.site_at(cell) == null \
					and not Fall.NOT_GROUND.has(world.terrain_id_at(cell)):
				open.append(cell)
		if not open.is_empty():
			open.sort()
			return open[rng.randi_range(0, open.size() - 1)]
	for _i in int(said.get("attempts", 400)):
		var cell := from + Vector2i(rng.randi_range(-far, far), rng.randi_range(-far, far))
		var apart := Pathfinder.distance(cell, from)
		if apart < near or apart > far:
			continue
		if not reach.has(cell) or world.site_at(cell) != null:
			continue
		if Fall.NOT_GROUND.has(world.terrain_id_at(cell)):
			continue
		return cell
	# Somewhere cramped: the nearest open ground will do.
	for radius in range(1, far + 1):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var cell := from + Vector2i(dx, dy)
				if reach.has(cell) and world.site_at(cell) == null and not Fall.NOT_GROUND.has(world.terrain_id_at(cell)):
					return cell
	return from


## Lines for the landing beat: word of whoever is waiting nearby.
static func landing_lines(world: World) -> Array:
	var out: Array = []
	for each: Dictionary in world.wanderers:
		if not bool(each.get("echo", false)):
			continue
		var place := world.site_at(cell_of(each.get("at", [])))
		var echo := echo_of(world, str(each.get("id", "")))
		out.append({
			"speaker": "",
			"text": _say(str(lines().get("landing", "")), echo, world, place),
		})
	return out


# --- what has come through ----------------------------------------------------


static func past(world: World) -> Array:
	return world.echoes.get("past", []) if world != null else []


## Which world of the sixteen this is: 1 for the first.
static func number(world: World) -> int:
	return int(world.echoes.get("sibling", 0)) + 1


static func echo_of(world: World, hero: String) -> Dictionary:
	for echo: Dictionary in past(world):
		if str(echo.get("hero", "")) == hero:
			return echo
	return {}


## Whether the lead of [param world] has got as far as [param echo] did: their
## level, and as high up the Tower (agenda item 52, **Inferred**).
static func caught_up(world: World, echo: Dictionary) -> bool:
	var lead: Character = GameState.roster.player() if GameState.roster != null else null
	var level := lead.level if lead != null else 1
	return level >= int(echo.get("level", 1)) and world.tower_floor >= int(echo.get("floor", 0))


## Called from the world's upkeep: anyone the lead has caught up with comes
## through, and their weapon comes down.
static func upkeep(world: World) -> Array:
	var out: Array = []
	for echo: Dictionary in past(world):
		if bool(echo.get("arrived", false)) or not caught_up(world, echo):
			continue
		out.append_array(come_through(world, echo))
	return out


## The weapon falls and the ghost is at the fire from now on.
static func come_through(world: World, echo: Dictionary) -> Array:
	echo["arrived"] = true
	var weapon: Dictionary = echo.get("weapon", {})
	weapon["landed"] = true
	var cell := cell_of(weapon.get("cell", []))
	Annals.record(world, _say(str(lines().get("weapon_annal", "")), echo, world, null))
	return [_say(str(lines().get("weapon_lands", "")), echo, world, null, Fall.way(world.player_cell, cell))]


## Walking onto the crater: the weapon goes into the packs. Nobody is suited to
## it (see `Gear.suits`), which is the point.
static func on_arrive(world: World, cell: Vector2i) -> Array:
	var out: Array = []
	for echo: Dictionary in past(world):
		var weapon: Dictionary = echo.get("weapon", {})
		if not bool(weapon.get("landed", false)) or bool(weapon.get("found", false)):
			continue
		if cell_of(weapon.get("cell", [])) != cell:
			continue
		weapon["found"] = true
		weapon["heard"] = true
		GameState.stores.append(str(weapon.get("id", "")))
		Annals.record(world, _say(str(lines().get("weapon_found_annal", "")), echo, world, null))
		out.append(_say(str(lines().get("weapon_found", "")), echo, world, null))
	return out


## Word of a fallen weapon, for whoever asks at an inn or rests where people
## talk. Leaves it marked on the map. Empty when nothing has fallen unfound.
static func rumour(world: World) -> String:
	for echo: Dictionary in past(world):
		var weapon: Dictionary = echo.get("weapon", {})
		if not bool(weapon.get("landed", false)) or bool(weapon.get("found", false)):
			continue
		var cell := cell_of(weapon.get("cell", []))
		var place := _nearest_named(world, cell)
		weapon["heard"] = true
		var from: Vector2i = place.cell if place != null else world.player_cell
		return _say(str(lines().get("weapon_rumour", "")), echo, world, place, Fall.way(from, cell))
	return ""


static func _nearest_named(world: World, cell: Vector2i) -> Site:
	var best: Site = null
	var nearest := 1 << 30
	for site: Site in world.sites:
		if site.kind == Site.GRAVE:
			continue
		var apart := Pathfinder.distance(site.cell, cell)
		if apart < nearest:
			nearest = apart
			best = site
	return best


## Fallen weapons the company has word of and has not yet found, for the map:
## `[{ cell, id }]`.
static func heard_weapons(world: World) -> Array:
	var out: Array = []
	for echo: Dictionary in past(world):
		var weapon: Dictionary = echo.get("weapon", {})
		if bool(weapon.get("landed", false)) and bool(weapon.get("heard", false)) and not bool(weapon.get("found", false)):
			out.append({"cell": cell_of(weapon.get("cell", [])), "id": str(weapon.get("id", ""))})
	return out


## Shape the copy of an earlier lead who has agreed to walk with the company:
## the calling and the beliefs they started with ([D52]). Their level is the
## lead's, like anyone of the sixteen who joins; nothing of the old run's power
## comes with them ([D33]).
static func shape(world: World, recruit: Character) -> void:
	var echo := echo_of(world, recruit.template_id)
	if echo.is_empty():
		return
	var kept: Dictionary = echo.get("self", {})
	for field: String in ["background", "creed", "grudge", "hearth", "oath", "temper"]:
		var value := str(kept.get(field, ""))
		if value != "":
			recruit.set(field, value)
	var calling := str(kept.get("class_id", ""))
	if calling != "" and recruit.level >= Progression.CLASS_LEVEL:
		recruit.class_id = calling


## What an earlier lead's copy says, on top of what anyone of the sixteen says:
## the narration on first sight, and an answer to "have we met?".
static func echo_lines(world: World, hero: String, group: String) -> Dictionary:
	var echo := echo_of(world, hero)
	if echo.is_empty():
		return {}
	return {
		"seen": _say(str(lines().get("echo_seen", "")), echo, world, null),
		"ask": str(lines().get("echo_ask", "Have we met before?")),
		"answer": _say(str(lines().get("echo_answer", {}).get(group, "")), echo, world, null),
	}


# --- the ghost at the fire ----------------------------------------------------


## Indices into [method past] of everyone whose ghost is at the fire.
static func ghosts(world: World) -> Array:
	var out: Array = []
	var all := past(world)
	for i in all.size():
		if bool((all[i] as Dictionary).get("arrived", false)):
			out.append(i)
	return out


static func ghost_name(world: World, index: int) -> String:
	var all := past(world)
	if index < 0 or index >= all.size():
		return ""
	return _say(str(lines().get("ghost_name", "The ghost of {name}")), all[index], world, null)


## How many pages of the journal the ghost will share tonight: a few more for
## an Outward temper, more every night at the fire, and all of them once their
## weapon is found (agenda item 54, **Inferred**).
static func pages_shared(echo: Dictionary) -> int:
	var pages: Array = echo.get("pages", [])
	if bool(echo.get("weapon", {}).get("found", false)):
		return pages.size()
	var said: Dictionary = rules().get("ghost", {})
	var temper := str(echo.get("temper", "I"))
	var opening := int(said.get("outward", 3)) if temper.begins_with("E") else int(said.get("inward", 1))
	var visits := maxi(0, int(echo.get("visits", 1)) - 1)
	return mini(pages.size(), opening + visits * int(said.get("per_visit", 2)))


## Sit with the ghost: count the night and register the conversation. Returns
## its dialogue id, or empty when nobody is there.
static func ghost_talk(world: World, index: int) -> String:
	var all := past(world)
	if index < 0 or index >= all.size() or not bool((all[index] as Dictionary).get("arrived", false)):
		return ""
	var echo: Dictionary = all[index]
	echo["visits"] = int(echo.get("visits", 0)) + 1
	var id := GHOST_PREFIX + str(index)
	Database.register_dialogue(id, ghost_conversation(world, index))
	return id


static func ghost_conversation(world: World, index: int) -> Dictionary:
	var echo: Dictionary = past(world)[index]
	var said := lines()
	var who := ghost_name(world, index)
	var first := int(echo.get("visits", 1)) <= 1

	var floor_text := str(said.get("ghost_floor_none", ""))
	if int(echo.get("floor", 0)) > 0:
		floor_text = _say(str(said.get("ghost_floor", "")), echo, world, null)
	var killer_text := str(said.get("ghost_killer_none", ""))
	if str(echo.get("killer", "")) != "":
		killer_text = _say(str(said.get("ghost_killer", "")), echo, world, null)
	var fall_text := _say(str(said.get("ghost_fall", "")), echo, world, null).format({
		"floor_text": floor_text, "killer_text": killer_text,
	})

	var pages: Array = echo.get("pages", [])
	var shared := pages_shared(echo)
	var found_text := str(said.get("ghost_found_none", ""))
	if shared > 0:
		found_text = "\n".join(pages.slice(0, shared))
	if bool(echo.get("weapon", {}).get("found", false)):
		found_text = str(said.get("ghost_opened", "")) + ("\n" + found_text if shared > 0 else "")
	elif shared < pages.size():
		found_text += "\n" + str(said.get("ghost_withheld", ""))

	var weapon: Dictionary = echo.get("weapon", {})
	var weapon_text := str(said.get("ghost_weapon_waiting", ""))
	if bool(weapon.get("found", false)):
		weapon_text = _say(str(said.get("ghost_weapon_found", "")), echo, world, null)
	elif bool(weapon.get("landed", false)):
		var home := world.home()
		var from: Vector2i = home.cell if home != null else world.player_cell
		weapon_text = _say(str(said.get("ghost_weapon_landed", "")), echo, world, null,
			Fall.way(from, cell_of(weapon.get("cell", []))))
		# Told by the one who owned it: as good as a rumour.
		weapon["heard"] = true

	var well := str(echo.get("well", ""))
	var menu := [
		{ "text": str(said.get("ghost_ask_fall", "How did you fall?")), "goto": "fall" },
		{ "text": str(said.get("ghost_ask_well", "What did you do well?")), "goto": "well" },
		{ "text": str(said.get("ghost_ask_found", "What did you find out there?")), "goto": "found" },
		{ "text": str(said.get("ghost_ask_weapon", "Where is your weapon?")), "goto": "weapon" },
		{ "text": str(said.get("ghost_leave", "Rest now.")), "goto": "end" },
	]
	var nodes := {
		"open": {
			"speaker": "",
			"text": _say(str(said.get("ghost_first" if first else "ghost_again", "")), echo, world, null),
			"next": "menu",
		},
		"menu": { "speaker": who, "text": "...", "options": menu },
		"fall": { "speaker": who, "text": fall_text, "next": "menu" },
		"well": { "speaker": who, "text": well if well != "" else str(said.get("ghost_well_none", "")), "next": "menu" },
		"found": { "speaker": who, "text": found_text, "next": "menu" },
		"weapon": { "speaker": who, "text": weapon_text, "next": "menu" },
	}
	return { "cast": { who: str(echo.get("hero", "")) }, "start": "open", "nodes": nodes }


static func _say(line: String, echo: Dictionary, world: World, site: Site, way: String = "") -> String:
	var lead: Character = GameState.roster.player() if GameState.roster != null else null
	var weapon_id := str(echo.get("weapon", {}).get("id", "")) if echo.get("weapon") is Dictionary else ""
	return line.format({
		"name": str(echo.get("name", "someone")),
		"lead": lead.display_name if lead != null else "friend",
		"weapon": Gear.display_name(weapon_id) if weapon_id != "" else "a weapon",
		"way": way,
		"place": site.display_name if site != null else "the road",
		"level": int(echo.get("level", 1)),
		"floor": int(echo.get("floor", 0)),
		"killer": str(echo.get("killer", "")),
	})
