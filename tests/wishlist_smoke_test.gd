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
	_check_journal()
	_check_museum()
	_check_arena()
	_check_cinematic()

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
