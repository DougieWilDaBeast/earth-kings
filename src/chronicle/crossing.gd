extends RefCounted
## Gates as crossings between the sixteen worlds (D152).
##
## A gate is a seam between the worlds. As one shuts, its light can thin to a
## doorway onto the same gate in another of the sixteen's worlds: if that
## world's lead is alive they are standing in it, the original rather than the
## copy who walks this world (docs/17), shutting their side; if their world has
## ended, it is burning and nobody stands in it. The lead's own company never
## crosses, and nothing passes through: it is seen, said and written down.
##
## The roll is fixed by the world's seed and the gate's cell, so a reload never
## turns up someone different. Who was met is kept in the run's flags
## (`crossed:<hero>`). Everything lives in `data/crossings.json`; every word and
## number is **Inferred** (agenda item 92). Loaded by path ([D41]). Pure logic.
##
## A word carries (D172, D183): what a lead says into a gate as it shuts is
## written beside the fallen ([Sixteen], outside the save), and a later lead who
## shuts the same gate hears it, faint, through the light. At the first gate of
## a life the lead who fell last is heard instead, or, if they never shut a
## gate, word of them. One line; nothing else passes through.

const Sixteen := preload("res://src/chronicle/sixteen.gd")

const PREFIX := "crossed:"
## Set by the first crossing a run sees.
const ANY := "crossed:any"
## Set by the first gate a life shuts, so the fallen are heard there and only there.
const SHUT := "carried:shut"


static func rules() -> Dictionary:
	return Database.crossings


## Who is on the far side of [param site] as it shuts, or empty for nobody:
## `{ hero, name, ended }`. [param lead_id] and [param company] are the leads
## on this side; [param fallen] the leads whose worlds have ended;
## [param first] whether this is the first gate of the player's first life.
static func roll(world: World, site: Site, lead_id: String, company: Array, fallen: Array, first: bool) -> Dictionary:
	var r := rules()
	var chance := float((r.get("chance", {}) as Dictionary).get(site.rank, 0.0))
	if first and bool(r.get("first_certain", false)):
		chance = 1.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.world_seed, site.cell.x, site.cell.y, "crossing"])
	if rng.randf() >= chance:
		return {}
	var pool: Array = []
	var total := 0.0
	for hero_id: String in Database.heroes:
		if hero_id.begins_with("_") or hero_id == lead_id or company.has(hero_id):
			continue
		var found_at := str((Database.heroes[hero_id] as Dictionary).get("found_at", ""))
		var weight := float((r.get("weight", {}) as Dictionary).get(found_at, 1.0))
		total += weight
		pool.append([hero_id, total])
	if pool.is_empty():
		return {}
	var pick := rng.randf() * total
	var hero_id := str(pool.back()[0])
	for entry: Array in pool:
		if pick < float(entry[1]):
			hero_id = str(entry[0])
			break
	return { "hero": hero_id, "name": name_of(hero_id), "ended": fallen.has(hero_id) }


static func name_of(hero_id: String) -> String:
	return str((Database.units.get(hero_id, {}) as Dictionary).get("display_name", hero_id.capitalize()))


## The scene played for [param meeting] at [param site], in the shape
## [method Database.register_dialogue] takes.
static func scene(meeting: Dictionary, site: Site, lead_name: String) -> Dictionary:
	var kind := "ended" if bool(meeting.get("ended", false)) else "living"
	var slots := _slots(meeting, site, lead_name)
	var lines: Array = []
	for line: Dictionary in rules().get(kind, []):
		lines.append({
			"speaker": str(line.get("speaker", "")).format(slots),
			"text": str(line.get("text", "")).format(slots),
		})
	return { "lines": lines }


## The journal's line for [param meeting].
static func journal(meeting: Dictionary, site: Site, lead_name: String) -> String:
	var kind := "ended" if bool(meeting.get("ended", false)) else "living"
	return str((rules().get("journal", {}) as Dictionary).get(kind, "")).format(_slots(meeting, site, lead_name))


## [param site] has just been shut in this run: roll for a crossing and, if
## there is one, write it down and hand back the dialogue id to play, else "".
static func on_gate_shut(world: World, site: Site) -> String:
	if world == null or site == null or GameState.roster == null or GameState.roster.player() == null:
		return ""
	var lead := GameState.roster.player()
	var company: Array = []
	for character: Character in GameState.party_characters():
		company.append(character.template_id)
	var fallen := Sixteen.fallen_heroes()
	var first := Sixteen.worlds().is_empty() and not GameState.has_flag(ANY)
	var meeting := roll(world, site, lead.template_id, company, fallen, first)
	# A word carries (D183): what comes through is heard before this lead's own is left.
	var heard := carried(world, site, lead.template_id, Sixteen.words(), fallen, not GameState.has_flag(SHUT))
	GameState.set_flag(SHUT)
	if GameState.tallying and not GameState.rehearsing:
		Sixteen.leave_word(word_left(world, site, lead.template_id))
	if meeting.is_empty() and heard.is_empty():
		return ""
	var lines: Array = []
	var dialogue_id := ""
	if not meeting.is_empty():
		GameState.set_flag(ANY)
		GameState.set_flag(PREFIX + str(meeting["hero"]))
		Annals.record(world, journal(meeting, site, lead.display_name))
		dialogue_id = "crossing_%s" % str(meeting["hero"])
		lines.append_array(scene(meeting, site, lead.display_name).get("lines", []))
	if not heard.is_empty():
		Annals.record(world, carried_journal(heard, site, lead.display_name))
		if dialogue_id == "":
			dialogue_id = "carried_%s" % str(heard["hero"])
		lines.append_array(carried_scene(heard, site, lead.display_name).get("lines", []))
	Database.register_dialogue(dialogue_id, { "lines": lines })
	return dialogue_id


## The first world's seed of the sixteen [param world] belongs to: a word
## carries only between worlds built from it.
static func base_seed(world: World) -> int:
	return int(world.echoes.get("base_seed", world.world_seed))


## The word [param hero_id] leaves at [param site] as it shuts, in the shape
## [method Sixteen.leave_word] keeps; `word` is empty if they have none.
static func word_left(world: World, site: Site, hero_id: String) -> Dictionary:
	var left := (rules().get("carried", {}) as Dictionary).get("left", {}) as Dictionary
	return {
		"hero": hero_id,
		"gate": site.display_name,
		"cell": [site.cell.x, site.cell.y],
		"seed": base_seed(world),
		"word": str(left.get(hero_id, "")),
	}


## What [param lead_id] hears carried through [param site] as it shuts, or
## empty: `{ hero, name, word }`, `word` empty for word of them and no voice.
## [param words] is [method Sixteen.words]; [param fallen] the leads whose
## worlds have ended, in the order they fell; [param first_shut] whether this
## is the first gate shut in this life. The same gate carries the latest word
## another lead left there; failing that, the first gate of a life carries the
## lead who fell last: their last word, or word of them if they left none.
static func carried(world: World, site: Site, lead_id: String, words: Array, fallen: Array, first_shut: bool) -> Dictionary:
	# Only into a sibling of the worlds the words were said in: a world built
	# from a seed asked for is a world of its own, and nothing comes through.
	if int(world.echoes.get("sibling", 0)) <= 0:
		return {}
	var family := base_seed(world)
	for i in range(words.size() - 1, -1, -1):
		var said: Dictionary = words[i]
		var hero_id := str(said.get("hero", ""))
		if hero_id == lead_id or int(said.get("seed", 0)) != family:
			continue
		if Sixteen.same_cell(said.get("cell", []), [site.cell.x, site.cell.y]):
			return { "hero": hero_id, "name": name_of(hero_id), "word": str(said.get("word", "")) }
	if not first_shut:
		return {}
	for i in range(fallen.size() - 1, -1, -1):
		var hero_id := str(fallen[i])
		if hero_id == lead_id:
			continue
		var word := ""
		for said: Dictionary in words:
			if str(said.get("hero", "")) == hero_id and int(said.get("seed", 0)) == family:
				word = str(said.get("word", ""))
		return { "hero": hero_id, "name": name_of(hero_id), "word": word }
	return {}


## The lines played for a word [param heard] at [param site], in the shape
## [method Database.register_dialogue] takes: a voice if they left a word,
## else word of them.
static func carried_scene(heard: Dictionary, site: Site, lead_name: String) -> Dictionary:
	var slots := _carried_slots(heard, site, lead_name)
	var lines: Array = []
	for line: Dictionary in (rules().get("carried", {}) as Dictionary).get(_carried_kind(heard), []):
		lines.append({
			"speaker": str(line.get("speaker", "")).format(slots),
			"text": str(line.get("text", "")).format(slots),
		})
	return { "lines": lines }


## The journal's line for a word [param heard].
static func carried_journal(heard: Dictionary, site: Site, lead_name: String) -> String:
	var said := (rules().get("carried", {}) as Dictionary).get("journal", {}) as Dictionary
	return str(said.get(_carried_kind(heard), "")).format(_carried_slots(heard, site, lead_name))


static func _carried_kind(heard: Dictionary) -> String:
	return "voice" if str(heard.get("word", "")) != "" else "word_of"


static func _carried_slots(heard: Dictionary, site: Site, lead_name: String) -> Dictionary:
	return {
		"gate": site.display_name,
		"name": str(heard.get("name", "")),
		"lead": lead_name,
		"word": str(heard.get("word", "")),
	}


static func _slots(meeting: Dictionary, site: Site, lead_name: String) -> Dictionary:
	var hero_id := str(meeting.get("hero", ""))
	return {
		"gate": site.display_name,
		"name": str(meeting.get("name", "")),
		"lead": lead_name,
		"says": str((rules().get("says", {}) as Dictionary).get(hero_id, "")),
	}
