extends RefCounted
## A journal for each land ([D239], from Necesse; Ewan's "what other games do well", #270 keep 2):
## the first time the party sets foot in one of the eighteen lands, the journal gets a page for it,
## a short list of things to do there (walk it, find what somebody left, beat its bands, stand in
## one of its places, shut one of its gates). Crossing off the last line turns up that land's
## trinket: something the whole company carries from then on, which can change how it walks as well
## as how it fights (`dougie`, [D227]: "you can cross water or walk faster, boots").
##
## Kept on the world as `lands`: land id -> `{ needs, got, walked, stood, done }`. `needs` is written when
## the page is opened and never again, so a gate shut or a land healing does not move the goalposts.
## Numbers and words are `data/land_journals.json`. Loaded by path ([D41]).

const Biome := preload("res://src/chronicle/biome.gd")

## What no walking can be done on: water has no land of its own (Biome.at calls it grassland).
const NOT_LAND := ["ocean", "lake", "water"]


static func rules() -> Dictionary:
	return Database.land_journals


## "the snowfield", "the blight": a land's name in the middle of a sentence.
static func named(land: String) -> String:
	var name_ := Biome.display_name(land)
	return name_ if name_.begins_with("the ") else "the %s" % name_


## "The Snowfield", "The Crystal Fields": a land's name as a page heading.
static func heading(land: String) -> String:
	var words := named(land).split(" ")
	for i in words.size():
		words[i] = words[i].capitalize()
	return " ".join(words)


static func _line(key: String, tokens: Dictionary = {}) -> String:
	return str(rules().get("lines", {}).get(key, "")).format(tokens)


## The land [param cell] is, or "" where there is no land to walk (water, off the map).
static func land_at(world: World, cell: Vector2i) -> String:
	if world == null or not world.in_bounds(cell) or world.terrain_id_at(cell) in NOT_LAND:
		return ""
	return Biome.at(world, cell)


static func page(world: World, land: String) -> Dictionary:
	return world.lands.get(land, {}) if world != null else {}


## What a page asks, worked out from the land as it is when the page is opened: no more stretches
## than it has, a place only where one stands, a gate only where one does.
static func _needs(world: World, land: String) -> Dictionary:
	var stretches := 0
	var places := 0
	var gates := 0
	# Only as many stretches as the page could ask for are counted: the whole map, cell by cell, was
	# a stall of a fifth of a second the first step into every land (play-test 7, the frame rate).
	var most := 0
	for entry: Dictionary in rules().get("entries", []):
		if str(entry.get("kind", "")) == "walk":
			most = maxi(most, maxi(1, int(entry.get("count", 1))))
	for y in world.size.y:
		if stretches >= most:
			break
		for x in world.size.x:
			var cell := Vector2i(x, y)
			if world.is_walkable(cell) and land_at(world, cell) == land:
				stretches += 1
	for site: Site in world.sites:
		if land_at(world, site.cell) != land:
			continue
		if site.kind == Site.GATE:
			if not site.cleared:
				gates += 1
		else:
			places += 1
	var needs := {}
	for entry: Dictionary in rules().get("entries", []):
		var kind := str(entry.get("kind", ""))
		var count := maxi(1, int(entry.get("count", 1)))
		match kind:
			"walk":
				count = mini(count, stretches)
			"place":
				count = mini(count, places)
			"gate":
				count = mini(count, gates)
		if count > 0:
			needs[kind] = count
	return needs


## Open [param land]'s page if it has none. The line to say, or "".
static func _open(world: World, land: String) -> String:
	if land == "" or world.lands.has(land):
		return ""
	world.lands[land] = { "needs": _needs(world, land), "got": {}, "walked": [], "stood": [], "done": false }
	return _line("opened", { "land": heading(land) })


## One more of [param kind] done in [param land]. The lines to say: the line crossed off, and the
## trinket if that was the last.
static func _tick(world: World, land: String, kind: String) -> Array[String]:
	var lines: Array[String] = []
	var book := page(world, land)
	if book.is_empty() or bool(book.get("done", false)):
		return lines
	var needs: Dictionary = book.get("needs", {})
	if not needs.has(kind):
		return lines
	var got: Dictionary = book.get("got", {})
	var had := int(got.get(kind, 0))
	if had >= int(needs[kind]):
		return lines
	got[kind] = had + 1
	book["got"] = got
	if had + 1 < int(needs[kind]):
		return lines
	var crossed := 0
	for each: String in needs:
		if int(got.get(each, 0)) >= int(needs[each]):
			crossed += 1
	if crossed < needs.size():
		lines.append(_line("ticked", {
			"land": heading(land), "entry": entry_text(land, kind, int(needs[kind])),
			"done": crossed, "of": needs.size(),
		}))
		return lines
	book["done"] = true
	var trinket := trinket_of(land)
	lines.append(_line("finished", {
		"land": heading(land), "trinket": str(trinket.get("name", "")), "what": describe(trinket),
	}))
	Annals.record(world, _line("annal", { "land": named(land), "trinket": str(trinket.get("name", "")) }))
	return lines


## The party walks onto [param cell]: a new page for a new land, a stretch of it walked, a place stood in.
static func on_arrive(world: World, cell: Vector2i) -> Array[String]:
	var lines: Array[String] = []
	var land := land_at(world, cell)
	if land == "":
		return lines
	var opened := _open(world, land)
	if opened != "":
		lines.append(opened)
	var book := page(world, land)
	var key := "%d,%d" % [cell.x, cell.y]
	var walked: Array = book.get("walked", [])
	if not walked.has(key) and not bool(book.get("done", false)):
		walked.append(key)
		book["walked"] = walked
		lines.append_array(_tick(world, land, "walk"))
	var site := world.site_at(cell)
	if site != null and site.kind != Site.GATE:
		var stood: Array = book.get("stood", [])
		if not stood.has(key):
			stood.append(key)
			book["stood"] = stood
			lines.append_array(_tick(world, land, "place"))
	return lines


## A band beaten at [param cell].
static func on_band_beaten(world: World, cell: Vector2i) -> Array[String]:
	return _tick(world, land_at(world, cell), "bands")


## Something somebody left (the standing stones, a cairn, a cold camp, a cache) stood at, on the
## ground of the tile [param cell].
static func on_landmark(world: World, cell: Vector2i) -> Array[String]:
	return _tick(world, land_at(world, cell), "landmark")


## [param site] is about to be shut: asked before it is, because a shut gate can heal the land
## round it into another.
static func on_gate_shut(world: World, site: Site) -> Array[String]:
	if site == null:
		return []
	return _tick(world, land_at(world, site.cell), "gate")


## The words for one line of a page.
static func entry_text(land: String, kind: String, count: int) -> String:
	for entry: Dictionary in rules().get("entries", []):
		if str(entry.get("kind", "")) == kind:
			return str(entry.get("text", kind)).format({ "count": count, "land": named(land) })
	return kind


## Every page opened, in the order they were: `{ land, heading, done, trinket, entries }`, where each
## entry is `{ text, got, of }`.
static func pages(world: World) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if world == null:
		return out
	for land: String in world.lands:
		var book: Dictionary = world.lands[land]
		var needs: Dictionary = book.get("needs", {})
		var got: Dictionary = book.get("got", {})
		var entries: Array[Dictionary] = []
		for entry: Dictionary in rules().get("entries", []):
			var kind := str(entry.get("kind", ""))
			if not needs.has(kind):
				continue
			entries.append({
				"text": entry_text(land, kind, int(needs[kind])),
				"got": mini(int(got.get(kind, 0)), int(needs[kind])), "of": int(needs[kind]),
			})
		out.append({
			"land": land, "heading": heading(land), "done": bool(book.get("done", false)),
			"trinket": trinket_of(land), "entries": entries,
		})
	return out


static func trinket_of(land: String) -> Dictionary:
	return rules().get("trinkets", {}).get(land, {})


## The lands whose trinket the company carries.
static func carried(world: World) -> Array[String]:
	var out: Array[String] = []
	if world == null:
		return out
	for land: String in world.lands:
		if bool((world.lands[land] as Dictionary).get("done", false)) and not trinket_of(land).is_empty():
			out.append(land)
	return out


## Every carried trinket's [param key] added up (`stride`, `hush`, `attack`, `defense`, `health`),
## within the most `data/land_journals.json` allows.
static func effect(world: World, key: String) -> float:
	var total := 0.0
	for land: String in carried(world):
		total += float(trinket_of(land).get("effects", {}).get(key, 0.0))
	var most: Variant = rules().get("%s_most" % key, null)
	return minf(total, float(most)) if most != null else total


## Whether any carried trinket lets the party wade the shallows.
static func wades(world: World) -> bool:
	for land: String in carried(world):
		if bool(trinket_of(land).get("effects", {}).get("wade", false)):
			return true
	return false


## Whether any carried trinket keeps [param hazard] off the whole company.
static func spares(world: World, hazard: String) -> bool:
	for land: String in carried(world):
		if (trinket_of(land).get("effects", {}).get("proof", []) as Array).has(hazard):
			return true
	return false


## What a trinket does, in a sentence.
static func describe(trinket: Dictionary) -> String:
	var effects: Dictionary = trinket.get("effects", {})
	var parts: Array[String] = []
	if effects.has("stride"):
		parts.append("walk %d%% faster" % roundi(float(effects["stride"]) * 100.0))
	if bool(effects.get("wade", false)):
		parts.append("wade through shallow water")
	if effects.has("hush"):
		parts.append("bands see you %d %s later" % [int(effects["hush"]), "step" if int(effects["hush"]) == 1 else "steps"])
	if effects.has("attack"):
		parts.append("%+d attack for everyone" % int(effects["attack"]))
	if effects.has("defense"):
		parts.append("%+d guard for everyone" % int(effects["defense"]))
	if effects.has("health"):
		parts.append("%d%% more health in a fight" % roundi(float(effects["health"]) * 100.0))
	for hazard: Variant in effects.get("proof", []):
		parts.append("no harm from %s" % str((Database.biomes.get("hazards", {}).get(str(hazard), {}) as Dictionary).get("name", hazard)))
	if parts.is_empty():
		return ""
	var said: String = ", ".join(parts.slice(0, parts.size() - 1)) + (" and " if parts.size() > 1 else "") + parts.back()
	return "For the company: %s." % said
