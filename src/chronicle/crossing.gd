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
## number is **Inferred** (agenda item 87). Loaded by path ([D41]). Pure logic.

const Sixteen := preload("res://src/chronicle/sixteen.gd")

const PREFIX := "crossed:"
## Set by the first crossing a run sees.
const ANY := "crossed:any"


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
	if meeting.is_empty():
		return ""
	GameState.set_flag(ANY)
	GameState.set_flag(PREFIX + str(meeting["hero"]))
	Annals.record(world, journal(meeting, site, lead.display_name))
	var dialogue_id := "crossing_%s" % str(meeting["hero"])
	Database.register_dialogue(dialogue_id, scene(meeting, site, lead.display_name))
	return dialogue_id


static func _slots(meeting: Dictionary, site: Site, lead_name: String) -> Dictionary:
	var hero_id := str(meeting.get("hero", ""))
	return {
		"gate": site.display_name,
		"name": str(meeting.get("name", "")),
		"lead": lead_name,
		"says": str((rules().get("says", {}) as Dictionary).get(hero_id, "")),
	}
