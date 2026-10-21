class_name Nemesis
extends RefCounted
## Enemies who survived defeat, carried word of you, and return with a score to settle; and people
## the company did right by, who remember it too ([D330], call BX; Ewan's play-test 8: "Characters
## will remember that, and people might hold a grudge... People might come out and try to attack me").
##
## - When a company of foes is broken, there is a chance one wounded survivor crawls into the
##   brush. Word of their defeat spreads outward as a deed; they take up an epithet and remember
##   where you met.
## - They come back in a band on the road, a little stronger each time (`level_per_return`), and
##   say so. Beaten again they are finished for good, and that is told too.
## - Somebody whose errand the company settled may remember it: once, somewhere on the road, they
##   come the other way with their thanks and something for it (`thanks`).
##
## Words and numbers are `world_rules.json` → `nemesis`.

const Coins := preload("res://src/chronicle/coins.gd")


static func rules() -> Dictionary:
	return Database.world_rules.get("nemesis", {})


static func on_battle_won(world: World, enemies: Array, cell: Vector2i) -> String:
	# Hidden while `nemesis` is in the First Hour's cut list (D97): nobody gets away to remember you.
	if FirstHour.hides("nemesis"):
		return ""
	var finished := _finish(world, enemies, cell)
	if finished != "":
		return finished
	var candidates: Array = []
	var dumb: Array = rules().get("non_sentient", [])
	for entry in enemies:
		var unit_id: String = entry.get("unit", "") if entry is Dictionary else str(entry)
		if unit_id != "" and unit_id not in dumb:
			candidates.append(unit_id)
	if candidates.is_empty():
		return ""
	var dice := _dice(world, "survive")
	if dice.randf() > float(rules().get("survive_chance", 0.2)):
		return ""

	var chosen: String = candidates[dice.randi() % candidates.size()]
	var template := Database.unit_template(chosen)
	var base_name: String = template.get("display_name", chosen.capitalize())
	var epithets: Array = rules().get("epithets", ["the Scarred"])
	var full_name := "%s %s" % [base_name, epithets[dice.randi() % epithets.size()]]
	var place := _place_name(world, cell)

	world.survivors.append({
		"unit": chosen,
		"name": full_name,
		"cell": [cell.x, cell.y],
		"place": place,
		"steps": world.steps,
		"encounters": 1,
	})

	var lead := GameState.roster.player()
	var lead_name := lead.display_name if lead != null else "your company"
	Renown.record(
		world, "thread", cell, 2,
		"%s crawled alive from the clash near %s, speaking with dread of %s" % [
			full_name, place, lead_name
		]
	)
	Annals.record(world, "%s survived the carnage near %s and fled into the hills." % [full_name, place])
	return str(rules().get("escaped_line", "{name} crawls off into the brush. They will not forget this.")).format({"name": full_name})


## A survivor in the band just beaten is finished: off the world's list, and the deed told.
static func _finish(world: World, enemies: Array, cell: Vector2i) -> String:
	for entry in enemies:
		if not (entry is Dictionary) or not bool(entry.get("survivor", false)):
			continue
		var name_ := str(entry.get("name", ""))
		for survivor: Dictionary in world.survivors.duplicate():
			if str(survivor.get("name", "")) == name_:
				world.survivors.erase(survivor)
		var what := "put an end to %s" % name_
		Renown.record(world, "nemesis_finished", cell, 3, what, what)
		Annals.record(world, "%s came back for the company one time too many, near %s." % [name_, _place_name(world, cell)])
		return str(rules().get("finished_line", "{name} will not crawl away this time.")).format({"name": name_})
	return ""


static func check_confrontation(world: World, meeting: Dictionary) -> String:
	for enemy in meeting.get("enemies", []):
		if bool(enemy.get("survivor", false)):
			var lines: Array = rules().get("confront_lines", [])
			var times := int(enemy.get("returns", 1))
			var line := str(lines[mini(times, lines.size()) - 1]) if not lines.is_empty() \
					else "{name}: 'I survived your blades at {place}.'"
			return line.format({"name": str(enemy.get("name", "A scarred warrior")), "place": str(enemy.get("place", "the road"))})
	return ""


## Now and then a survivor leads a band met on the road: their kind, their name, and a level more
## for every time they have come back.
static func inject_survivor(world: World, enemies: Array) -> void:
	if world.survivors.is_empty() or enemies.is_empty():
		return
	var dice := _dice(world, "return")
	if dice.randf() > float(rules().get("return_chance", 0.45)):
		return
	var survivor: Dictionary = world.survivors[dice.randi() % world.survivors.size()]
	var returns := int(survivor.get("encounters", 1))
	survivor["encounters"] = returns + 1
	enemies[0]["unit"] = survivor.get("unit", enemies[0].get("unit", "brigand"))
	enemies[0]["survivor"] = true
	enemies[0]["returns"] = returns
	enemies[0]["name"] = survivor.get("name", "The Survivor")
	enemies[0]["place"] = survivor.get("place", "an old battleground")
	enemies[0]["level"] = int(enemies[0].get("level", 1)) + int(rules().get("level_per_return", 1)) * returns


# --- thanks ---------------------------------------------------------------------


## An errand settled: its giver may remember it, kept on the world until they find the company.
static func remember_thanks(world: World, errand: Dictionary) -> void:
	if FirstHour.hides("nemesis"):
		return
	var giver := str(errand.get("giver", ""))
	if giver == "" or _dice(world, giver).randf() > float(rules().get("thanks", {}).get("chance", 0.5)):
		return
	world.thankful.append({"giver": giver, "title": str(errand.get("title", "the errand")),
			"place": str(errand.get("from_name", "")), "gold": int(errand.get("gold", 0))})


## Whether the next traveller on the road should be somebody who owes the company thanks.
static func thanks_due(world: World) -> bool:
	return not world.thankful.is_empty() and not FirstHour.hides("nemesis") \
			and absi(hash([world.world_seed, world.steps, "thanks"])) % 100 < roundi(100.0 * float(rules().get("thanks", {}).get("meet_share", 0.5)))


## The one who owes thanks comes the other way: the lines, and their gift paid into the purse.
static func thanks_met(world: World) -> Array:
	if world.thankful.is_empty():
		return []
	var one: Dictionary = world.thankful.pop_front()
	var thanks: Dictionary = rules().get("thanks", {})
	var gift := maxi(1, roundi(float(one.get("gold", 0)) * float(thanks.get("gift_share", 0.5))))
	GameState.gold += gift
	var fill := {"giver": str(one.get("giver", "Somebody")), "title": str(one.get("title", "")),
			"place": str(one.get("place", "")), "gift": Coins.text(gift)}
	var lines: Array = []
	for line: String in thanks.get("lines", ["{giver} stops you on the road to thank you again, and presses {gift} on you."]):
		lines.append(line.format(fill))
	Annals.record(world, "%s came out on the road to thank the company for \"%s\"." % [fill["giver"], fill["title"]])
	return lines


static func _place_name(world: World, cell: Vector2i) -> String:
	var site := world.site_at(cell)
	if site != null:
		return site.display_name
	return world.region_at(cell)


## The nemesis's own dice, from the world's seed and step, so a grudge kept or let go never shifts
## what the world's own dice deal next.
static func _dice(world: World, salt: String) -> RandomNumberGenerator:
	var dice := RandomNumberGenerator.new()
	dice.seed = hash([world.world_seed, world.steps, salt, world.survivors.size(), world.thankful.size()])
	return dice
