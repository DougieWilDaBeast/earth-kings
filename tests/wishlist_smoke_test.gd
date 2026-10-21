extends Node
## Headless check on the four things added from the wishlist: the journal
## filling in only what was earned, the museum surviving a write and a read,
## the arena stashing and restoring the run's own roster, and every kind of
## place having its art.
##
##   godot --headless --path . res://tests/wishlist_smoke_test.tscn

const SEED := 20260901
const Crafting := preload("res://src/chronicle/crafting.gd")

var _failures: Array[String] = []


func _ready() -> void:
	_check_content()
	_check_animation()
	_check_journal()
	_check_museum()
	_check_arena()
	_check_site_art()
	_check_opening()
	_check_seasons()
	_check_news()
	_check_temper_quiz()

	print("")
	if _failures.is_empty():
		print("wishlist smoke test: PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			print("  FAIL  %s" % failure)
		print("wishlist smoke test: %d failure(s)" % _failures.size())
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


# --- the data tables ----------------------------------------------------------


## Every id one table uses has to exist in the table it points at. A typo here
## is a hero nobody can pick or an ability nobody can cast, and neither says so.
func _check_content() -> void:
	var known_ability_keys := [
		"display_name", "description", "target", "min_range", "range", "splash",
		"power", "heal", "bonus", "cooldown", "cast", "stun", "energy",
		# What a skill leaves on whoever it lands on (D192).
		"knockback", "pull", "slow", "burn", "bleed", "knockdown", "expose",
	]
	for ability_id: String in Database.abilities:
		var ability: Dictionary = Database.abilities[ability_id]
		for key: String in ability:
			_expect(known_ability_keys.has(key), "ability %s has unknown field '%s'" % [ability_id, key])
		_expect(
			str(ability.get("target", "enemy")) in ["enemy", "ally"],
			"ability %s targets '%s'" % [ability_id, ability.get("target", "")]
		)
		_expect(
			int(ability.get("min_range", 1)) <= int(ability.get("range", 1)),
			"ability %s cannot reach its own minimum range" % ability_id
		)
		# The real-time skirmish prices every skill in seconds (see SkirmishRules).
		for timing: String in ["cooldown", "cast"]:
			if ability.has(timing):
				_expect(
					typeof(ability[timing]) in [TYPE_INT, TYPE_FLOAT] and float(ability[timing]) >= 0.0,
					"ability %s has a %s that is not a number of seconds" % [ability_id, timing]
				)

	for class_id: String in Database.classes:
		# Every class is drawn in its own colour ([D67]).
		var colour := str(Database.classes[class_id].get("colour", ""))
		_expect(Color.html_is_valid(colour), "class %s has no colour, or not one written #rrggbb" % class_id)
		for ability_id: String in Database.classes[class_id].get("grants", []):
			_expect(
				Database.abilities.has(ability_id),
				"class %s grants missing ability '%s'" % [class_id, ability_id]
			)
		# One of the sixteen's own classes: a kit for Q W E R and a passive.
		var lead := str(Database.classes[class_id].get("lead", ""))
		if lead != "":
			_expect(Database.classes[class_id].get("grants", []).size() == 4, "%s's class %s does not start with four moves" % [lead, class_id])
			_expect(Database.own_class(lead) == class_id, "%s has more than one class of their own" % lead)
			_expect(Database.skirmish.get("by_class", {}).has(class_id), "%s's class %s has no passive" % [lead, class_id])

	for hero_id: String in Database.heroes:
		_expect(Database.units.has(hero_id), "hero '%s' has no unit template" % hero_id)
		var hero: Dictionary = Database.hero(hero_id)
		# Authored history is cast late, so blank is legal here — a *wrong* id
		# is not, and that is the whole job of this check.
		for field: String in Character.TRAIT_POOLS:
			var piece_id: String = hero.get(field, "")
			if piece_id == "":
				continue
			_expect(
				not Database.lore_piece(Character.TRAIT_POOLS[field], piece_id).is_empty(),
				"hero '%s' carries unknown %s '%s'" % [hero_id, field, piece_id]
			)
		var code: String = hero.get("temper", "")
		if code != "":
			_expect(Database.temper(code).has("hero"), "hero '%s' has unknown temper '%s'" % [hero_id, code])
			_expect(
				Database.temper_hero(code) == hero_id,
				"hero '%s' claims temper %s, which points at '%s'" % [hero_id, code, Database.temper_hero(code)]
			)
		for companion_id: String in hero.get("companions", []):
			_expect(
				Database.units.has(companion_id),
				"hero %s brings missing companion '%s'" % [hero_id, companion_id]
			)

	_check_tempers()
	_check_lore_pools()
	_check_casting()

	var tower: Dictionary = Database.world_rules.get("tower", {})
	for cohort: Dictionary in tower.get("cohorts", []):
		_expect(not cohort.get("factions", []).is_empty(), "a Tower cohort to floor %s holds nobody" % cohort.get("to"))
		for faction_id: String in cohort.get("factions", []):
			_expect(Database.factions.has(faction_id), "a Tower cohort names missing faction '%s'" % faction_id)
	for unit_id: String in tower.get("apex", []):
		_expect(Database.units.has(unit_id), "the Tower's apex names missing unit '%s'" % unit_id)

	for template_id: String in Database.units:
		for ability_id: String in Database.units[template_id].get("abilities", []):
			_expect(
				Database.abilities.has(ability_id),
				"unit %s knows missing ability '%s'" % [template_id, ability_id]
			)
		for class_id: String in Database.units[template_id].get("classes", []):
			_expect(
				Database.classes.has(class_id),
				"unit %s takes missing class '%s'" % [template_id, class_id]
			)

	# Gear only reads as a choice if the wrong hands are worse than the right ones.
	var wearer := Character.create("atlas")
	wearer.class_id = "sworn_blade"
	for equipment_id: String in Database.equipment:
		var piece: Dictionary = Database.equipment[equipment_id]
		if bool(piece.get("charm", false)):
			_expect(piece.has("grace"), "charm %s buys no grace" % equipment_id)
			continue
		if Gear.is_draught(equipment_id):
			_expect(Gear.mends(equipment_id) > 0, "draught %s mends nothing" % equipment_id)
			continue
		# A smith's makings (D346) are worth something only to a smith.
		if Gear.kind(equipment_id) == "making":
			_expect(Crafting.recipes().any(func(r: Dictionary) -> bool: return (r.get("needs", {}) as Dictionary).has(equipment_id)),
					"making %s goes into nothing" % equipment_id)
			continue
		_expect(
			int(piece.get("attack", 0)) + int(piece.get("defense", 0)) > 0,
			"equipment %s is worth nothing to anybody" % equipment_id
		)
		for calling: String in piece.get("suits", []):
			_expect(
				Database.classes.has(calling) or Database.units.has(calling),
				"equipment %s suits missing calling '%s'" % [equipment_id, calling]
			)
		if piece.get("suits", []).has("sworn_blade"):
			_expect(
				Gear.worth(equipment_id, wearer) > 0,
				"%s is no use to the calling it was made for" % equipment_id
			)


# --- W11 ----------------------------------------------------------------------


## A unit with a run cycle has to actually reach for it, and a unit without one
## has to keep standing rather than drawing nothing at all.
func _check_animation() -> void:
	var frames := Database.unit_run("atlas", "east")
	_expect(frames.size() > 1, "the sworn blade's run cycle is %d frames" % frames.size())
	for heading: String in ["north", "south", "east", "west"]:
		_expect(
			not Database.unit_run("atlas", heading).is_empty(),
			"the sworn blade cannot run %s" % heading
		)
	var plain := _unanimated()
	_expect(plain != "", "every unit has a run cycle now; this check needs another")
	_expect(Database.unit_run(plain, "east").is_empty(), "%s grew a run cycle" % plain)

	var runner := Unit.create("atlas", Unit.Team.PLAYER, Vector2i.ZERO)
	_expect(not runner.run_frames.is_empty(), "a unit with art loaded no run cycle")
	_expect(runner.current_sprite() != null, "a standing unit is drawn as nothing")
	var still := Unit.create(plain, Unit.Team.ENEMY, Vector2i.ZERO)
	_expect(still.run_frames.is_empty(), "a unit with no cycle claims one")
	_expect(still.current_sprite() != null, "a unit with no cycle lost its standing pose")
	runner.free()
	still.free()


# --- W4 -----------------------------------------------------------------------


func _check_journal() -> void:
	var world := WorldGen.generate(SEED)
	_expect(Journal.met(world).is_empty(), "the journal did not start empty")
	_expect(Journal.fullness(world)[1] > 0, "nothing in the world is worth meeting")

	_expect(Journal.sighted(world, "goblin", "a road"), "first sighting was not new")
	_expect(not Journal.sighted(world, "goblin", "a road"), "a second sighting counted as new")
	_expect(Journal.knows(world, "goblin"), "the goblin has no page")
	_expect(not Journal.sighted(world, "not_a_unit", "nowhere"), "an unknown template opened a page")

	var page := Journal.page(world, "goblin")
	_expect(_value_of(page, "Constitution") == Journal.UNKNOWN, "constitution was known before a kill")
	_expect(_value_of(page, "Reach") == Journal.UNKNOWN, "reach was known before being hit")
	_expect(_value_of(page, "Guard") == Journal.UNKNOWN, "guard was known before hitting one")
	_expect(_value_of(page, "First seen") == "a road", "where it was seen was not written down")

	Journal.note_struck(world, "goblin")
	Journal.note_wounded(world, "goblin")
	Journal.note_felled(world, "goblin")
	page = Journal.page(world, "goblin")
	_expect(_value_of(page, "Reach") != Journal.UNKNOWN, "reach stayed unknown after a blow landed")
	_expect(_value_of(page, "Guard") != Journal.UNKNOWN, "guard stayed unknown after hitting one")
	_expect(_value_of(page, "Constitution") != Journal.UNKNOWN, "constitution stayed unknown after a kill")

	var before := Journal.abilities(world, "goblin")
	_expect(before.has(Journal.UNKNOWN), "every ability was known without watching one")
	Journal.note_ability(world, "goblin", "strike")
	Journal.note_ability(world, "goblin", "strike")
	_expect(
		Journal.abilities(world, "goblin").size() == before.size(),
		"noting an ability twice grew the list"
	)

	# The page has to survive a save, or it is a page that only exists mid-fight.
	var restored := World.from_dict(JSON.parse_string(JSON.stringify(world.to_dict())))
	_expect(Journal.knows(restored, "goblin"), "the journal did not survive a save/load")


func _value_of(page: Array, label: String) -> String:
	for row: Array in page:
		if str(row[0]) == label:
			return str(row[1])
	return ""


# --- W5 -----------------------------------------------------------------------


func _check_museum() -> void:
	var world := WorldGen.generate(SEED)
	world.steps = 412
	var roster := Roster.found("")
	var record := Museum.compose(world, roster, Ledger.fresh(), Museum.FELL)

	_expect(str(record.get("lead", "")) != "", "the journey has nobody leading it")
	_expect(record.get("company", []).size() == roster.characters.size(), "the company was not recorded")
	_expect(int(record.get("steps", 0)) == 412, "the journey lost its step count")
	_expect(str(record.get("id", "")).contains(":"), "the journey has no id to deduplicate on")

	var person: Dictionary = record["company"][0]
	for key: String in ["name", "template_id", "job", "level", "status"]:
		_expect(person.has(key), "a portrait is missing '%s'" % key)


# --- W3 -----------------------------------------------------------------------


func _check_arena() -> void:
	_expect(not Arena.cards().is_empty(), "no coliseum cards loaded from data/coliseum.json")
	for card_id: String in Arena.cards():
		for foe_id: String in Arena.cards()[card_id].get("foes", []):
			_expect(Database.units.has(foe_id), "%s fields a missing unit '%s'" % [card_id, foe_id])

	var kept := GameState.roster
	var card: String = Arena.cards().keys()[0]
	Arena.open("", card)
	_expect(Arena.is_open(), "the arena did not open")
	_expect(GameState.roster != kept, "the arena fought with the run's own roster")
	_expect(not GameState.tallying, "the sand was being written into the run's ledger")

	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var wave := Arena.wave(rng)
	_expect(bool(wave.get("sandbox", false)), "a wave was not a sandbox fight")
	_expect(not bool(wave.get("heal", true)), "the crowd healed the party between rounds")
	_expect(str(wave.get("return_scene", "")) == "coliseum", "a wave did not come back to the sand")
	_expect(not wave.get("encounter", {}).get("map", {}).get("enemies", []).is_empty(), "a wave fielded nobody")

	var first := Arena.reward(1)
	Arena.won()
	_expect(Arena.round_number() == 2, "winning a round did not move the card on")
	_expect(Arena.purse() == first, "the purse did not pay out")
	_expect(Arena.reward(2) > first, "round two paid no better than round one")
	for character in GameState.roster.characters:
		_expect(character.current_hp() > 0, "%s was left down between rounds" % character.display_name)

	Arena.close()
	_expect(not Arena.is_open(), "the arena did not close")
	_expect(GameState.roster == kept, "the run did not get its own people back")
	_expect(GameState.tallying, "the ledger was left switched off")

	# Out of a run, leaving goes back to the run even when a round came back to
	# the sand without saying where from; it never lands on the title screen.
	Arena.open("", card, 1.0, true, { "scene": "area", "payload": { "area_id": "keep" } })
	_expect(str(Arena.way_back({}).get("scene")) == "area", "a round that forgot the way back left the arena for the title")
	Arena.close()
	_expect(str(Arena.way_back({ "live_run": true }).get("scene")) == "world", "a night out of a run with no way back went to the title")
	_expect(str(Arena.way_back({}).get("scene")) == "title", "the coliseum off the title screen did not go back to it")
	_expect(GameState.roster == kept, "the run did not get its own people back the second time")


# --- places -------------------------------------------------------------------


## Every kind of place the map draws has its picture.
func _check_site_art() -> void:
	for kind: String in Site.ART:
		_expect(
			ResourceLoader.exists(str(Site.ART[kind])),
			"a %s has no art at %s" % [kind, Site.ART[kind]]
		)


# --- W20 ----------------------------------------------------------------------


## The opening after the pick (docs/25): every shot is one it can draw, everyone in
## it has a sprite, the lead it was handed is the one who falls, it plays to the end
## on its own and starts the run in the world, and Esc skips straight there. The
## quiz only plays it when New Game sent it there.
func _check_opening() -> void:
	var data: Dictionary = Database.opening
	var shots: Array = data.get("shots", [])
	_expect(not shots.is_empty(), "the opening has no shots")
	var known: Array = load("res://src/ui/opening.gd").SHOTS
	for shot: Dictionary in shots:
		_expect(known.has(str(shot.get("shot", ""))), "the opening has a shot it cannot draw: '%s'" % shot.get("shot", ""))
		_expect(not (shot.get("lines", []) as Array).is_empty(), "the opening's '%s' shot says nothing" % shot.get("shot", ""))
	for hero: String in data.get("sixteen", []):
		_expect(ResourceLoader.exists("res://art/sixteen/%s/idle/south.png" % hero), "%s has no sprite for the opening" % hero)
	for template: String in (data.get("party", []) as Array) + [str(data.get("foe", ""))]:
		_expect(not Database.unit_template(template).is_empty(), "the opening casts '%s', which is not a unit" % template)

	var asked: Array = []
	var listen := func(key: String, payload: Dictionary) -> void: asked.append([key, payload])
	EventBus.request_scene.connect(listen)
	var opening: Control = load("res://src/ui/opening.tscn").instantiate()
	opening.boot_payload = {"lead": "cato", "fallen_heroes": []}
	add_child(opening)
	opening.set_process(false)
	_expect(opening._lead == "cato" and opening._sprites.get("sixteen:cato") != null,
			"the opening does not fall with the lead it was handed")
	var total := 0.0
	for shot: Dictionary in shots:
		total += float(shot.get("time", 6.0))
	var guard := 0
	while not opening.finished and guard < int(total / 0.25) + 40:
		opening.step(0.25)
		guard += 1
	_expect(opening.finished, "the opening never ended on its own")
	_expect(asked.size() == 1 and asked[0][0] == "world" and asked[0][1] == {},
			"the opening did not start the run in the world: %s" % [asked])
	opening.queue_free()

	asked.clear()
	var skipped: Control = load("res://src/ui/opening.tscn").instantiate()
	skipped.boot_payload = {"fallen_heroes": []}
	add_child(skipped)
	skipped.set_process(false)
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	skipped._unhandled_input(esc)
	_expect(skipped.finished and asked.size() == 1, "Esc did not skip the opening")
	skipped.queue_free()

	_check_opening_again(data, asked)

	# The quiz sends a New Game's lead to the opening, and any other run straight out.
	for from_new_game: bool in [true, false]:
		asked.clear()
		var quiz: Control = load("res://src/ui/temper_quiz.tscn").instantiate()
		quiz.boot_payload = {"opening": true} if from_new_game else {}
		add_child(quiz)
		quiz._chosen = "cato"
		quiz._begin()
		var want: Array = ["opening", {"lead": "cato"}] if from_new_game else ["world", {}]
		_expect(asked.size() == 1 and asked[0] == want,
				"the quiz began the run with %s, not %s" % [asked, want])
		quiz.queue_free()
	EventBus.request_scene.disconnect(listen)


## Every life after the first plays the opening again (Will, 2026-10-15): only the
## story shots (call AC), with the fallen gone from it and the lines for who is left.
func _check_opening_again(data: Dictionary, asked: Array) -> void:
	var sixteen: Array = data.get("sixteen", [])
	var second := _opening_for("cato", ["atlas"], {"hero": "atlas", "name": "Atlas", "floor": 3, "killer": "slime", "remembered": true})
	var ids: Array = second.shots.map(func(shot: Dictionary) -> String: return str(shot.get("shot", "")))
	_expect(ids == data.get("replay", []), "the second life's opening plays %s, not the replay's shots" % [ids])
	_expect(second.stage() == "many" and second.left() == 15, "the second life is not fifteen left (%s, %d)" % [second.stage(), second.left()])
	_expect(second._other == "atlas", "the second life's opening does not show Atlas's world ending (%s)" % second._other)
	var said := _opening_lines(second)
	_expect(said.has("Sixteen of them, each given a world. Fifteen are still standing."), "the ring does not count fifteen left")
	_expect(said.has("Atlas fell on floor 3 of the Tower. He had just remembered a courtyard, and a gift."),
			"the ending shot does not say how Atlas fell and what he remembered (D153): %s" % [said])
	_expect(said.has("One of the fourteen after you goes on, from the beginning."), "the end shot does not count who is after")
	asked.clear()
	var guard := 0
	while not second.finished and guard < 600:
		second.step(0.25)
		guard += 1
	_expect(second.finished and asked.size() == 1 and asked[0][0] == "world", "the second life's opening did not start the run")
	second.queue_free()

	# D191: after Atlas's last stand, a new player's first life plays the whole opening, with
	# Atlas's world the one seen ending.
	var after_stand := _opening_for("cato", ["atlas"], {"hero": "atlas", "name": "Atlas", "floor": 0, "last_stand": true})
	var all_ids: Array = (data.get("shots", []) as Array).map(func(shot: Dictionary) -> String: return str(shot.get("shot", "")))
	var stand_ids: Array = after_stand.shots.map(func(shot: Dictionary) -> String: return str(shot.get("shot", "")))
	_expect(stand_ids == all_ids, "after the last stand the opening plays %s, not all of it" % [stand_ids])
	_expect(after_stand._other == "atlas", "after the last stand the world seen ending is not Atlas's (%s)" % after_stand._other)
	var stand_said := _opening_lines(after_stand)
	_expect(stand_said.has("Atlas fell in Hearthwick, at the edge of his own village, and his world went dark with him. It never comes back."),
			"after the last stand the ending shot does not say where Atlas fell: %s" % [stand_said])
	after_stand.queue_free()

	var on_road := _opening_for("juno", ["atlas", "cato"], {"hero": "cato", "name": "Cato", "floor": 0, "killer": "Ogre"})
	_expect(_opening_lines(on_road).has("Cato fell on the road, to an ogre, and never learned what he carried down."),
			"a lead killed on the road is not said to fall there: %s" % [_opening_lines(on_road)])
	on_road.queue_free()
	# D153: the other half of a tie hears it once, on the impact shot, and nobody else does.
	var tie := _opening_for("ultor", ["bellona"], {"hero": "bellona", "name": "Bellona", "floor": 2, "killer": "", "remembered": false})
	var tie_said := _opening_lines(tie)
	_expect(tie_said.has("Somewhere a whistle stops blowing.") and tie_said.has("Bellona fell on floor 2 of the Tower, and never learned what she carried down."),
			"Ultor after Bellona does not hear the whistle stop: %s" % [tie_said])
	tie.queue_free()
	var no_tie := _opening_for("janus", ["bellona"], {"hero": "bellona", "name": "Bellona", "floor": 2})
	_expect(not _opening_lines(no_tie).has("Somewhere a whistle stops blowing."), "a lead with no tie to Bellona hears the whistle")
	no_tie.queue_free()

	var others := sixteen.filter(func(hero) -> bool: return hero != "diana")
	var pair := _opening_for("diana", others.slice(0, 14), {"hero": others[13]})
	_expect(pair.stage() == "two" and _opening_lines(pair).has("Of the two left, one is you."), "two left is not told so")
	pair.queue_free()
	var last := _opening_for("diana", others, {"hero": "juno", "name": "Juno", "floor": 0, "killer": ""})
	var last_said := _opening_lines(last)
	_expect(last.stage() == "last" and last.left() == 1, "the sixteenth life is not the last (%s)" % last.stage())
	_expect(last_said.has("There is nobody after you.") and last_said.has("The last standing quest: Ascend to heaven."),
			"the last life does not hear that nobody is after them: %s" % [last_said])
	_expect(last_said.has("Juno fell before they ever reached the Tower, and never learned what she carried down."),
			"the last life's ending shot is not Juno's")
	last.queue_free()


func _opening_for(lead: String, fallen: Array, world: Dictionary) -> Control:
	var opening: Control = load("res://src/ui/opening.tscn").instantiate()
	opening.boot_payload = {"lead": lead, "fallen_heroes": fallen, "last_world": world}
	add_child(opening)
	opening.set_process(false)
	return opening


## Every line the opening will say, filled in.
func _opening_lines(opening: Control) -> Array:
	var out: Array = []
	for shot: Dictionary in opening.shots:
		for line in shot.get("lines", []):
			out.append(str(line).format(opening.fill()))
	return out


func _check_seasons() -> void:
	var sps := Season.steps_per_season()
	var s0 := Season.for_step(0)
	_expect(s0["clover"] == "lesser_green" and s0["display_name"] == "Spring", "step 0 was not Spring (lesser green)")
	var s1 := Season.for_step(sps)
	_expect(s1["clover"] == "green" and s1["display_name"] == "Summer", "step %d was not Summer (green)" % sps)
	var s2 := Season.for_step(sps * 2)
	_expect(s2["clover"] == "brown" and s2["display_name"] == "Autumn", "step %d was not Autumn (brown)" % (sps * 2))
	var s3 := Season.for_step(sps * 3)
	_expect(s3["clover"] == "ice" and s3["display_name"] == "Winter", "step %d was not Winter (ice)" % (sps * 3))
	var s4 := Season.for_step(sps * 4)
	_expect(s4["clover"] == "lesser_green" and s4["display_name"] == "Spring", "step %d was not Year 2 Spring" % (sps * 4))
	_expect(Season.just_turned(sps) and not Season.just_turned(sps - 1), "season transition step detection failed")

	for sea: Dictionary in Season.SEASONS:
		_expect(ResourceLoader.exists(sea["texture_path"]), "missing season clover texture at %s" % sea["texture_path"])
		_expect(ResourceLoader.exists(sea["ui_texture_path"]), "missing season clover UI texture at %s" % sea["ui_texture_path"])


# --- W30 ----------------------------------------------------------------------


func _check_news() -> void:
	var world := WorldGen.generate(SEED)
	var dispatches := News.dispatches(world)
	_expect(not dispatches.is_empty(), "news dispatches were empty")
	var tidings := News.tidings_for_inn(world, "The Host")
	_expect(tidings.contains("Word travels"), "inn tidings missing lead text")


# --- the sixteen, the pools, and the casting between them ---------------------


func _check_tempers() -> void:
	var types := Database.temper_types()
	_expect(types.size() == 16, "expected 16 tempers, found %d" % types.size())
	var seen_heroes: Dictionary = {}
	for code: String in types:
		_expect(code.length() == 4, "temper '%s' is not a four-letter code" % code)
		for i in 4:
			_expect(
				code[i] in ["EI", "SN", "TF", "JP"][i],
				"temper '%s' has '%s' where a %s was expected" % [code, code[i], ["EI", "SN", "TF", "JP"][i]]
			)
		var hero_id: String = types[code].get("hero", "")
		if hero_id == "":
			continue
		_expect(Database.heroes.has(hero_id), "temper %s points at missing hero '%s'" % [code, hero_id])
		_expect(not seen_heroes.has(hero_id), "hero '%s' answers to two tempers" % hero_id)
		seen_heroes[hero_id] = code

	var quiz: Array = Database.tempers.get("quiz", [])
	# Every pair is asked the same odd number of times, so best-of never ties.
	var per_axis := {"EI": 0, "SN": 0, "TF": 0, "JP": 0}
	for question: Dictionary in quiz:
		var axis: String = question.get("axis", "")
		_expect(axis in per_axis, "quiz asks about unknown axis '%s'" % axis)
		if axis in per_axis:
			per_axis[axis] = int(per_axis[axis]) + 1
		var options: Array = question.get("options", [])
		_expect(options.size() == 2, "quiz question on %s offers %d answers, not 2" % [axis, options.size()])
		for option: Dictionary in options:
			var key: String = option.get("key", "")
			_expect(key in axis, "quiz answer '%s' does not belong to axis %s" % [key, axis])
			_expect(str(option.get("text", "")) != "", "quiz answer %s on %s has no text" % [key, axis])
		var keys: Array = options.map(func(o: Dictionary) -> String: return str(o.get("key", "")))
		_expect(keys.has(axis[0]) and keys.has(axis[1]), "quiz question on %s does not offer both letters" % axis)
	var counts := per_axis.values()
	_expect(int(counts[0]) > 0 and counts.all(func(c: int) -> bool: return c == int(counts[0])),
		"the quiz asks the pairs a different number of times: %s" % str(per_axis))
	_expect(int(counts[0]) % 2 == 1, "the quiz asks each pair %d times; an odd number cannot tie" % int(counts[0]))

	for letter: String in "EISNTFJP":
		_expect(
			Database.tempers.get("axes", {}).has(letter),
			"temper axis '%s' is undescribed" % letter
		)
		_expect(
			Database.tempers.get("leans", {}).has(letter),
			"temper letter '%s' nudges nothing" % letter
		)


func _check_lore_pools() -> void:
	for pool: String in Database.LORE_POOLS:
		var entries := Database.lore_pool(pool)
		_expect(not Database.lore.get(pool, {}).is_empty(), "lore pool '%s' did not load" % pool)
		for piece_id: String in entries:
			var piece: Dictionary = entries[piece_id]
			_expect(
				str(piece.get("display_name", "")) != "",
				"%s/%s has no display name" % [pool, piece_id]
			)
			_expect(str(piece.get("blurb", "")) != "", "%s/%s has no blurb" % [pool, piece_id])
			_check_gift(pool, piece_id, piece.get("gift", {}))
			if pool == "hearths":
				_expect(
					str(piece.get("site_kind", "")) != "",
					"hearth '%s' names no site kind to start on" % piece_id
				)
			if pool == "grudges":
				_expect(
					not piece.get("matches", {}).is_empty(),
					"grudge '%s' matches nobody, so it is worth no damage" % piece_id
				)
			if pool == "oaths" and piece.has("toward"):
				_expect(
					Database.heroes.has(str(piece["toward"])),
					"oath '%s' is sworn toward missing hero '%s'" % [piece_id, piece["toward"]]
				)


func _check_gift(pool: String, piece_id: String, gift: Dictionary) -> void:
	if gift.is_empty():
		return
	var kind: String = gift.get("kind", "")
	_expect(kind in Gifts.KINDS, "%s/%s gives unknown gift kind '%s'" % [pool, piece_id, kind])
	var value: Variant = gift.get("value", null)
	# No gift may buy survival. Charms are earned deep in gates (D24) and a
	# grace-bearing book handed out at creation would quietly move the death
	# maths the design is measured against (docs/02-design.md).
	match kind:
		"doctrine":
			_expect(
				Database.doctrines.has(str(value)),
				"%s/%s grants missing doctrine '%s'" % [pool, piece_id, value]
			)
			_expect(
				float(Database.doctrines.get(str(value), {}).get("grace", 0.0)) <= 0.0,
				"%s/%s hands out '%s', which buys a grace nobody earned" % [pool, piece_id, value]
			)
		"item":
			_expect(
				Database.equipment.has(str(value)),
				"%s/%s grants missing equipment '%s'" % [pool, piece_id, value]
			)
			_expect(
				not bool(Database.equipment_piece(str(value)).get("charm", false)),
				"%s/%s hands out the charm '%s'; charms are delved for (D24)" % [pool, piece_id, value]
			)
		"grudge":
			_expect(
				not Database.lore_piece("grudges", str(value)).is_empty(),
				"%s/%s grants missing grudge '%s'" % [pool, piece_id, value]
			)
		"hearth":
			_expect(
				not Database.lore_piece("hearths", str(value)).is_empty(),
				"%s/%s grants missing hearth '%s'" % [pool, piece_id, value]
			)
		"bond":
			_expect(value is Dictionary, "%s/%s bond gift is not a table" % [pool, piece_id])
			if value is Dictionary:
				_expect(
					Database.heroes.has(str(value.get("toward", ""))),
					"%s/%s bonds toward missing hero '%s'" % [pool, piece_id, value.get("toward", "")]
				)
				_expect(
					int(value.get("warmth", 0)) != 0,
					"%s/%s bonds toward somebody by nothing at all" % [pool, piece_id]
				)


func _check_casting() -> void:
	for field: String in Character.TRAIT_POOLS:
		var pool: String = Character.TRAIT_POOLS[field]
		var book: Dictionary = Database.casting.get(pool, {})
		_expect(not book.is_empty(), "no casting book for pool '%s'" % pool)
		var pieces: Dictionary = book.get("pieces", {})
		var cast_on: Dictionary = {}
		for piece_id: String in pieces:
			_expect(
				not Database.lore_piece(pool, piece_id).is_empty(),
				"casting names missing %s '%s'" % [pool, piece_id]
			)
			var entry: Dictionary = pieces[piece_id]
			for hero_id: String in entry.get("candidates", []):
				_expect(
					Database.heroes.has(hero_id),
					"%s/%s is marked for missing hero '%s'" % [pool, piece_id, hero_id]
				)
			var cast: String = entry.get("cast", "")
			if cast == "":
				continue
			_expect(
				cast in entry.get("candidates", []),
				"%s/%s is cast on '%s', who was never a candidate" % [pool, piece_id, cast]
			)
			_expect(
				not cast_on.has(cast),
				"'%s' is cast two %s: %s and %s" % [cast, pool, cast_on.get(cast, ""), piece_id]
			)
			cast_on[cast] = piece_id
		# Once a pool is locked every one of the sixteen must carry a piece.
		if bool(book.get("locked", false)):
			for hero_id: String in Database.heroes:
				_expect(
					str(Database.hero(hero_id).get(field, "")) != "",
					"%s is locked but '%s' carries no %s" % [pool, hero_id, field]
				)


func _check_temper_quiz() -> void:
	# The quiz's own rules, with every living temper dealt; AQ's hold-back is checked on its own.
	var rules: Dictionary = Database.world_rules.get("first_hour", {})
	var dealing := bool(rules.get("deal_only_written", false))
	rules["deal_only_written"] = false
	var quiz: TemperQuiz = load("res://src/ui/temper_quiz.tscn").instantiate()
	add_child(quiz)

	# The roster is a side door that opens only once the quiz is answered (D44).
	_expect(not quiz.get_node("%AllButton").visible, "the roster was open before the quiz was answered")
	_expect(not quiz.get_node("%AgainButton").visible, "answering again was offered before any answer")

	# Two answers each, asked one at a time; a pair is settled by majority, so
	# answering first every time asks only that majority of each pair.
	var quiz_length: int = quiz.questions().size()
	var per_pair: int = quiz.questions_on("EI").size()
	var pressed := 0
	while quiz._answers.size() < 4 and pressed < quiz_length:
		var buttons := quiz.get_node("%Options").get_children()
		_expect(
			buttons.size() == 2,
			"question %d of the quiz offered %d answers on screen" % [pressed + 1, buttons.size()]
		)
		if buttons.is_empty():
			break
		# Take the first answer every time: E, then S, then T, then J.
		(buttons[0] as Button).pressed.emit()
		pressed += 1
	_expect(
		pressed == 4 * (per_pair / 2 + 1),
		"answering first every time took %d questions, not %d" % [pressed, 4 * (per_pair / 2 + 1)]
	)

	_expect(
		"".join(quiz._answers) == "ESTJ",
		"answering first every time gave '%s', not ESTJ" % "".join(quiz._answers)
	)

	# Until that slot has a character written for it, the screen says so and
	# sends the player to the full roster rather than starting a broken run.
	var cast: String = Database.temper_hero("ESTJ")
	if cast == "":
		_expect(not quiz.get_node("%BeginButton").visible, "an uncast temper still offered to begin")
		_expect(
			quiz.get_node("%QuestionLabel").text.contains("Nobody answers"),
			"an uncast temper did not say so"
		)
	else:
		_expect(quiz.get_node("%BeginButton").visible, "a cast temper would not begin")
		_expect(
			quiz.get_node("%NameLabel").text != "",
			"the reveal named nobody for ESTJ"
		)

	_expect(quiz.get_node("%AllButton").visible, "the roster stayed shut after the quiz was answered")
	_expect(quiz.get_node("%AgainButton").visible, "answering again was not offered after the quiz")

	# Answering again starts from the first question, both answers open.
	(quiz.get_node("%AgainButton") as Button).pressed.emit()
	_expect(quiz._answers.is_empty(), "answering again kept the old answers")
	_expect(quiz.get_node("%Options").get_child_count() == 2, "answering again did not ask the first question")
	_expect(not quiz.get_node("%Reveal").visible, "answering again left the last reveal up")
	_expect(not quiz.get_node("%AllButton").visible, "answering again left the roster open mid-quiz")
	quiz.queue_free()

	# D110: four questions, two answers each, sixteen ways through, and each way is a different
	# one of the sixteen.
	_expect(quiz_length == 4, "the quiz asks %d questions, not 4 (one per pair)" % quiz_length)
	var reached: Dictionary = {}
	for way in 16:
		var asked: TemperQuiz = load("res://src/ui/temper_quiz.tscn").instantiate()
		add_child(asked)
		for i in 4:
			var choices := asked.get_node("%Options").get_children()
			if choices.size() == 2:
				(choices[(way >> (3 - i)) & 1] as Button).pressed.emit()
		var who := str(asked.get("_chosen"))
		_expect(who != "" and not reached.has(who), "answers %d led to %s, already reached or nobody" % [way, who])
		reached[who] = true
		asked.queue_free()
	_expect(reached.size() == 16 and Database.heroes.keys().all(func(id: String) -> bool: return reached.has(id)),
		"the sixteen answers reach %d of the sixteen leads" % reached.size())

	_check_fallen_quiz()
	rules["deal_only_written"] = true
	_check_life_two()
	rules["deal_only_written"] = dealing
	_check_the_fallen()
	_check_the_modes()


## A lead who dies is written down outside the save (D47): their hero leaves the
## picker, their temper leaves the quiz, and only once nobody is left can the
## record be wiped.
func _check_the_fallen() -> void:
	var Sixteen := preload("res://src/chronicle/sixteen.gd")
	Sixteen.path = "user://earth-kings.sixteen.test.json"
	if FileAccess.file_exists(Sixteen.path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Sixteen.path))

	_expect(Sixteen.fallen_heroes().is_empty(), "a fresh record of the fallen was not empty")
	Sixteen.fall("caesar")
	Sixteen.fall("caesar")
	_expect(Sixteen.fallen_heroes() == ["caesar"], "a fallen lead was written down as %s" % str(Sixteen.fallen_heroes()))
	_expect(Sixteen.anyone_left(), "one death left nobody")
	_expect(not Sixteen.wipe(), "the fallen were wiped with lives still left")

	var types: Dictionary = Database.tempers["types"]
	var kept: String = str(types["INTJ"].get("hero", ""))
	types["INTJ"]["hero"] = "ares"
	_expect(Database.hero_temper("ares") == "INTJ", "a hero written for INTJ was not found under it")
	Sixteen.fall("ares")
	_expect(Sixteen.fallen_tempers().has("INTJ"), "a fallen lead's temper did not leave the quiz")
	types["INTJ"]["hero"] = kept

	var picker: Control = load("res://src/ui/character_select.tscn").instantiate()
	picker.boot_payload = {"fallen_heroes": Sixteen.fallen_heroes()}
	add_child(picker)
	var lives := picker.get_node("%Lives").get_children()
	_expect(lives.size() == Database.heroes.size() - 2, "with two fallen the picker offered %d of %d" % [lives.size(), Database.heroes.size()])
	for life: Button in lives:
		_expect(not life.text.begins_with(Database.unit_template("caesar").get("display_name", "caesar")), "a fallen lead was offered again")
	picker.queue_free()

	for hero_id: String in Database.heroes:
		Sixteen.fall(hero_id)
	_expect(not Sixteen.anyone_left(), "with every lead fallen somebody was still left")
	var empty: Control = load("res://src/ui/character_select.tscn").instantiate()
	empty.boot_payload = {"fallen_heroes": Sixteen.fallen_heroes()}
	add_child(empty)
	var again: Button = empty.get_node_or_null("%Lives/NewSixteenButton")
	_expect(again != null, "with nobody left the picker did not offer a new sixteen")
	if again != null:
		# Called rather than pressed: a pressed button plays a sound still held at exit.
		empty._begin_again(again)
		_expect(FileAccess.file_exists(Sixteen.path), "one press wiped the fallen without asking twice")
		empty._begin_again(again)
		_expect(not FileAccess.file_exists(Sixteen.path), "a new sixteen kept the old fallen")
	empty.queue_free()

	Sixteen.path = Sixteen.DEFAULT_PATH
	print("the fallen: kept outside the save, closed in the picker and the quiz, wiped only when nobody is left")


## Classic and Iron Man (D51). Classic stops on the fall with a reload, and the
## record is written only on ascending; Iron Man writes it on the fall and lets
## the save go with the lead.
func _check_the_modes() -> void:
	var RunMode := preload("res://src/chronicle/run_mode.gd")
	var Sixteen := preload("res://src/chronicle/sixteen.gd")
	Sixteen.path = "user://earth-kings.sixteen.test.json"
	# The hall is the player's; whatever the check files is taken back out.
	var hall: Variant = FileAccess.get_file_as_string(Museum.PATH) if FileAccess.file_exists(Museum.PATH) else null
	var kept_mode := GameState.mode

	_expect(RunMode.valid("") == RunMode.CLASSIC, "a run with no mode was not Classic")
	_expect(RunMode.saves_by_hand(RunMode.CLASSIC) and RunMode.offers_reload(RunMode.CLASSIC), "Classic lost its saves")
	_expect(not RunMode.saves_by_hand(RunMode.IRON_MAN) and not RunMode.offers_reload(RunMode.IRON_MAN), "Iron Man could be saved or reloaded")

	for mode: String in [RunMode.CLASSIC, RunMode.IRON_MAN]:
		if FileAccess.file_exists(Sixteen.path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(Sixteen.path))
		GameState.mode = mode
		GameState.new_game(SEED, "atlas")
		_expect(GameState.reached(RunMode.START, "you set out"), "%s did not save on setting out" % mode)
		_expect(GameState.save_is_this_run(), "%s's first save was not this run" % mode)
		GameState.roster.player().status = Fate.DEAD
		_expect(not GameState.reached(RunMode.REST, "after"), "%s saved over a run that had ended" % mode)

		var summary: Control = load("res://src/ui/run_summary.tscn").instantiate()
		summary.boot_payload = {"ending": Museum.FELL}
		add_child(summary)
		var beat := summary.get_node_or_null("TheFall")
		if mode == RunMode.CLASSIC:
			_expect(beat != null, "Classic did not stop on the fall")
			_expect(Sixteen.fallen_heroes().is_empty(), "Classic wrote the fallen down before anyone ascended")
			_expect(GameState.has_save(), "Classic lost the save before anyone chose")
			summary._ascend()
		else:
			_expect(beat == null, "Iron Man offered a way back")
		_expect(Sixteen.fallen_heroes() == ["atlas"], "%s: the fallen after the fall read %s" % [mode, Sixteen.fallen_heroes()])
		_expect(not GameState.has_save(), "%s kept a save for a world that ended" % mode)
		summary.queue_free()

	GameState.mode = kept_mode
	Sixteen.path = Sixteen.DEFAULT_PATH
	if hall == null:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Museum.PATH))
	else:
		FileAccess.open(Museum.PATH, FileAccess.WRITE).store_string(hall)
	GameState.new_game(SEED)
	print("the modes: Classic stops on the fall and writes it on ascending, Iron Man on the fall")


## A dead lead cannot be answered into again (D43): an answer goes once every
## temper behind it has fallen, and a question left with one is still asked.
func _check_fallen_quiz() -> void:
	# Answers by position, one per pair: E/I, S/N, T/F, J/P, first option first.
	var one := _quiz_after(["INTJ"], [1, 1, 0])
	var last := one.get_node("%Options").get_children()
	_expect(last.size() == 1, "with INTJ fallen, I-N-T offered %d answers, not 1" % last.size())
	if last.size() == 1:
		(last[0] as Button).pressed.emit()
		_expect("".join(one._answers) == "INTP", "the one answer left led to '%s', not INTP" % "".join(one._answers))
	one.queue_free()

	var two := _quiz_after(["INTJ", "INTP"], [1, 1])
	var third := two.get_node("%Options").get_children()
	_expect(third.size() == 1, "with INTJ and INTP fallen, I-N offered %d answers, not 1" % third.size())
	two.queue_free()

	var untouched := _quiz_after(["INTJ"], [0, 0, 0])
	_expect(
		untouched.get_node("%Options").get_child_count() == 2,
		"INTJ's death closed an answer on the E-S-T path"
	)
	untouched.queue_free()

	var everyone := _quiz_after(Database.tempers.get("types", {}).keys(), [])
	_expect(everyone.get_node("%Options").get_child_count() == 0, "a quiz with all sixteen fallen still offered answers")
	_expect(
		everyone.get_node("%QuestionLabel").text.contains("Nobody is left"),
		"a quiz with all sixteen fallen did not say so"
	)
	everyone.queue_free()


## AQ (D145): Atlas falls, and every way through the quiz deals a lead whose chapter one lies on
## floor 5, so the second life never climbs to an empty alcove. Once every lead has a chapter one
## nobody is held back and every temper still living can be dealt.
func _check_life_two() -> void:
	var fallen := ["INTJ"]
	var dealt := {}
	for path in 16:
		var quiz: TemperQuiz = load("res://src/ui/temper_quiz.tscn").instantiate()
		quiz.boot_payload = {"fallen": fallen}
		add_child(quiz)
		var guard := 0
		while quiz._answers.size() < 4 and guard < 24:
			guard += 1
			var buttons := quiz.get_node("%Options").get_children()
			if buttons.is_empty():
				break
			var pick: int = (path >> quiz._answers.size()) & 1
			(buttons[mini(pick, buttons.size() - 1)] as Button).pressed.emit()
		var code := "".join(quiz._answers)
		var hero := Database.temper_hero(code)
		_expect(code.length() == 4 and hero != "", "life two: the quiz after Atlas's fall dealt nobody ('%s')" % code)
		_expect(not (Database.memories.get(hero, []) as Array).is_empty(),
				"life two: the quiz dealt %s, who has no chapter one on floor 5" % hero)
		dealt[hero] = true
		quiz.queue_free()
	var written := 0
	for code: String in Database.temper_types():
		var hero := Database.temper_hero(code)
		if not fallen.has(code) and not (Database.memories.get(hero, []) as Array).is_empty():
			written += 1
	_expect(dealt.size() >= mini(written, 2), "life two: the quiz only ever dealt %s" % str(dealt.keys()))


func _quiz_after(fallen: Array, picks: Array) -> TemperQuiz:
	var quiz: TemperQuiz = load("res://src/ui/temper_quiz.tscn").instantiate()
	quiz.boot_payload = {"fallen": fallen}
	add_child(quiz)
	# One pick per preference pair: the same answer until that pair is settled.
	for pick: int in picks:
		var settled: int = quiz._answers.size() + 1
		var guard := 0
		while quiz._answers.size() < settled and guard < 12:
			guard += 1
			var buttons := quiz.get_node("%Options").get_children()
			if pick >= buttons.size():
				_expect(false, "quiz with %s fallen had no answer %d to pick" % [str(fallen), pick])
				return quiz
			(buttons[pick] as Button).pressed.emit()
	return quiz


## Some unit that has a standing pose and no moves yet, whichever that is as art lands.
func _unanimated() -> String:
	for id: String in Database.units:
		if str(Database.unit_template(id).get("sprite_dir", "")) != "" \
				and Database.unit_run(id, "east").is_empty() \
				and Database.unit_frames(id, "attack", "south").is_empty():
			return id
	return ""
