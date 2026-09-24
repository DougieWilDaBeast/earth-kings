extends Node
## Headless check on the four things added from the wishlist: the journal
## filling in only what was earned, the museum surviving a write and a read,
## the arena stashing and restoring the run's own roster, and the cinematic
## finding somewhere to look.
##
##   godot --headless --path . res://tests/wishlist_smoke_test.tscn

const SEED := 20260901

var _failures: Array[String] = []


func _ready() -> void:
	_check_content()
	_check_animation()
	_check_journal()
	_check_museum()
	_check_arena()
	_check_cinematic()
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
		"power", "heal", "bonus", "cooldown", "cast",
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
		for ability_id: String in Database.classes[class_id].get("grants", []):
			_expect(
				Database.abilities.has(ability_id),
				"class %s grants missing ability '%s'" % [class_id, ability_id]
			)

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
	var wearer := Character.create("bram")
	wearer.class_id = "sworn_blade"
	for equipment_id: String in Database.equipment:
		var piece: Dictionary = Database.equipment[equipment_id]
		if bool(piece.get("charm", false)):
			_expect(piece.has("grace"), "charm %s buys no grace" % equipment_id)
			continue
		if Gear.is_draught(equipment_id):
			_expect(Gear.mends(equipment_id) > 0, "draught %s mends nothing" % equipment_id)
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
	var frames := Database.unit_run("bram", "east")
	_expect(frames.size() > 1, "the sworn blade's run cycle is %d frames" % frames.size())
	for heading: String in ["north", "south", "east", "west"]:
		_expect(
			not Database.unit_run("bram", heading).is_empty(),
			"the sworn blade cannot run %s" % heading
		)
	_expect(Database.unit_run("goblin", "east").is_empty(), "a goblin grew a run cycle")

	var runner := Unit.create("bram", Unit.Team.PLAYER, Vector2i.ZERO)
	_expect(not runner.run_frames.is_empty(), "a unit with art loaded no run cycle")
	_expect(runner.current_sprite() != null, "a standing unit is drawn as nothing")
	var still := Unit.create("goblin", Unit.Team.ENEMY, Vector2i.ZERO)
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


# --- W1 -----------------------------------------------------------------------


## The cinematic needs somewhere to point the camera on any seed it is given.
func _check_cinematic() -> void:
	for offset in 4:
		var world := WorldGen.generate(SEED + offset)
		var places := 0
		for kind: String in [Site.TOWER, Site.KEEP, Site.VILLAGE, Site.GATE, Site.LIBRARY]:
			places += world.sites_of_kind(kind).size()
		_expect(places >= 2, "seed %d gave the opening pass nothing to look at" % (SEED + offset))
	for kind: String in Site.ART:
		_expect(
			ResourceLoader.exists(str(Site.ART[kind])),
			"a %s has no art at %s" % [kind, Site.ART[kind]]
		)


# --- W20 ----------------------------------------------------------------------


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
	_expect(quiz.size() == 4, "the quiz asks %d questions, not 4" % quiz.size())
	var asked: Array = []
	for question: Dictionary in quiz:
		var axis: String = question.get("axis", "")
		_expect(axis in ["EI", "SN", "TF", "JP"], "quiz asks about unknown axis '%s'" % axis)
		_expect(axis not in asked, "quiz asks about %s twice" % axis)
		asked.append(axis)
		var options: Array = question.get("options", [])
		_expect(options.size() == 2, "quiz question on %s offers %d answers, not 2" % [axis, options.size()])
		for option: Dictionary in options:
			var key: String = option.get("key", "")
			_expect(key in axis, "quiz answer '%s' does not belong to axis %s" % [key, axis])
			_expect(str(option.get("text", "")) != "", "quiz answer %s on %s has no text" % [key, axis])

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
	var quiz: TemperQuiz = load("res://src/ui/temper_quiz.tscn").instantiate()
	add_child(quiz)

	# Four questions, two answers each, asked one at a time.
	var quiz_length: int = quiz.questions().size()
	for i in quiz_length:
		var buttons := quiz.get_node("%Options").get_children()
		_expect(
			buttons.size() == 2,
			"question %d of the quiz offered %d answers on screen" % [i + 1, buttons.size()]
		)
		if buttons.is_empty():
			break
		# Take the first answer every time: E, then S, then T, then J.
		(buttons[0] as Button).pressed.emit()

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
	quiz.queue_free()
