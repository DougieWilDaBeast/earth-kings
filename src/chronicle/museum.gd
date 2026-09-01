class_name Museum
extends RefCounted
## Every company that ever walked out, kept after the run that made them ends.
##
## The save holds one run and is overwritten. This is the other book: a short
## record of each journey, written once when it finishes, so a company you lost
## six runs ago is still somebody you can go and look at.
##
## Kept apart from the save on purpose. Deleting a run does not delete the
## people who made it, and starting a new one does not overwrite them.

const PATH := "user://earth-kings.museum.json"
## Older journeys past this are dropped. The point is a hall, not an archive.
const KEEP := 40

const FELL := "fell"
const WALKED_AWAY := "walked away"


## Newest first.
static func journeys() -> Array:
	if not FileAccess.file_exists(PATH):
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Museum: unreadable hall at %s" % PATH)
		return []
	return parsed.get("journeys", [])


## Write this run down. Called once, when it is over — a run that is still being
## walked is read off the save instead, so it is never in here twice.
static func remember(world: World, roster: Roster, ledger: Dictionary, ending: String) -> void:
	var all := journeys()
	var record := compose(world, roster, ledger, ending)
	# The same run settled twice would file itself twice.
	for existing: Dictionary in all:
		if str(existing.get("id", "")) == str(record.get("id", "")):
			return
	all.push_front(record)
	if all.size() > KEEP:
		all = all.slice(0, KEEP)
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_error("Museum: could not write the hall to %s" % PATH)
		return
	file.store_string(JSON.stringify({ "journeys": all }, "\t"))


## What a journey looks like on the wall. Also used for the run still being
## walked, which is why it takes its pieces rather than reading [GameState].
static func compose(world: World, roster: Roster, ledger: Dictionary, ending: String) -> Dictionary:
	var lead := roster.player()
	return {
		# A world seed and a step count together name one particular journey.
		"id": "%d:%d" % [world.world_seed, world.steps],
		"ended_at": int(Time.get_unix_time_from_system()),
		"ending": ending,
		"lead": lead.display_name if lead != null else "Nobody",
		"seed": world.world_seed,
		"company": roster.characters.map(func(c: Character) -> Dictionary: return _portrait(c)),
		"steps": world.steps,
		"gold": Ledger.count(ledger, "gold_earned"),
		"kills": Ledger.count(ledger, "kills"),
		"battles_won": Ledger.count(ledger, "battles_won"),
		"battles_lost": Ledger.count(ledger, "battles_lost"),
		"errands_done": Ledger.count(ledger, "errands_done"),
		"deeds": world.deeds.size(),
		"floors": world.tower_floor,
		"journal": world.journal.size(),
		"nemesis": Ledger.nemesis(ledger),
		"epitaph": Ledger.epitaph(world, roster, ledger),
	}


## The run currently being walked, or an empty dictionary if there is not one.
## Read out of the save file rather than off [GameState], so the hall can be
## looked at from the title screen without starting anything.
static func in_progress() -> Dictionary:
	if not GameState.has_save():
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GameState.SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var world := World.from_dict(parsed.get("world", {}))
	var roster := Roster.from_dict(parsed.get("roster", {}))
	var record := compose(world, roster, Ledger.restore(parsed.get("ledger", {})), "still walking")
	record["live"] = true
	return record


## Everyone the hall has ever held, most recent first, deduplicated by name.
static func the_named() -> Array:
	var seen: Array = []
	var out: Array = []
	for journey: Dictionary in journeys():
		for person: Dictionary in journey.get("company", []):
			var key := "%s|%s" % [person.get("name", ""), journey.get("id", "")]
			if not seen.has(key):
				seen.append(key)
				out.append(person)
	return out


static func _portrait(character: Character) -> Dictionary:
	return {
		"name": character.display_name,
		"template_id": character.template_id,
		"job": character.class_name_text(),
		"level": character.level,
		"status": character.status,
		"lead": character.is_player,
		"hearth": character.hearth,
		"doctrine": character.doctrine.size(),
	}
