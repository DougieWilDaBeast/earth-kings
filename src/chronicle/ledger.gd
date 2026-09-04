class_name Ledger
extends RefCounted
## The running tally a finished run is retold from (see the run summary screen).
##
## Only what nothing else already remembers is counted here. Gates shut, graves
## dug, floors climbed and places named are read back off the [World] itself
## when the summary is built, so this stays a short list of plain counters.

const KEYS := [
	"gold_earned", "gold_spent", "kills", "battles_won", "battles_lost",
	"errands_done", "chests_opened", "recruited", "damage_dealt", "damage_taken",
]


static func fresh() -> Dictionary:
	var ledger := { "kills_by": {}, "places": [] }
	for key: String in KEYS:
		ledger[key] = 0
	return ledger


static func add(ledger: Dictionary, key: String, amount: int = 1) -> void:
	if amount != 0 and ledger.has(key):
		ledger[key] = int(ledger[key]) + amount


## JSON gives every number back as a float, so a loaded ledger is rebuilt
## rather than used as it comes off disk.
static func restore(payload: Dictionary) -> Dictionary:
	var ledger := fresh()
	for key: String in KEYS:
		ledger[key] = int(payload.get(key, 0))
	var by: Dictionary = payload.get("kills_by", {})
	for template_id: String in by:
		ledger["kills_by"][template_id] = int(by[template_id])
	for place: String in payload.get("places", []):
		ledger["places"].append(place)
	return ledger


static func count(ledger: Dictionary, key: String) -> int:
	return int(ledger.get(key, 0))


static func record_kill(ledger: Dictionary, template_id: String) -> void:
	add(ledger, "kills")
	var by: Dictionary = ledger.get("kills_by", {})
	by[template_id] = int(by.get(template_id, 0)) + 1
	ledger["kills_by"] = by


## Somewhere the party actually stood, counted once however often they go back.
static func record_place(ledger: Dictionary, place: String) -> void:
	var places: Array = ledger.get("places", [])
	if place != "" and place not in places:
		places.append(place)
		ledger["places"] = places


## The thing they killed most of, as it would be named out loud.
static func nemesis(ledger: Dictionary) -> String:
	var by: Dictionary = ledger.get("kills_by", {})
	var best := ""
	var most := 0
	for template_id: String in by:
		if int(by[template_id]) > most:
			most = int(by[template_id])
			best = template_id
	if best == "":
		return ""
	return "%s (%d)" % [Database.unit_template(best).get("display_name", best), most]


# --- the retelling ------------------------------------------------------------


## The run in the order you would tell it: `{ title, rows: [[label, value]] }`.
static func chapters(world: World, roster: Roster, ledger: Dictionary) -> Array:
	var tower_text := "%d of %d (Conquered!)" % [world.tower_floor, world.tower_floors()] if world.tower_topped else "%d of %d" % [world.tower_floor, world.tower_floors()]
	return [
		{
			"title": "The road",
			"rows": [
				["Steps walked", str(world.steps)],
				["Places stood in", str(_places(ledger).size())],
				["Tower floors climbed", tower_text],
				["Deeds worth repeating", str(world.deeds.size())],
			],
		},
		{
			"title": "The purse",
			"rows": [
				["Gold taken", str(count(ledger, "gold_earned"))],
				["Gold spent", str(count(ledger, "gold_spent"))],
				["Left in the purse", str(GameState.gold)],
				["Chests opened", str(count(ledger, "chests_opened"))],
			],
		},
		{
			"title": "The fighting",
			"rows": [
				["Battles won", str(count(ledger, "battles_won"))],
				["Battles lost", str(count(ledger, "battles_lost"))],
				["Enemies put down", str(count(ledger, "kills"))],
				["Most often killed", nemesis(ledger) if nemesis(ledger) != "" else "nothing"],
				["Damage dealt", str(count(ledger, "damage_dealt"))],
				["Damage taken", str(count(ledger, "damage_taken"))],
			],
		},
		{
			"title": "The country",
			"rows": [
				["Gates shut", str(_deeds_of(world, Renown.GATE_SHUT))],
				["Towns held", str(_deeds_of(world, Renown.TOWN_SAVED))],
				["Towns burnt", str(_deeds_of(world, Renown.TOWN_RAIDED))],
				["Errands settled", str(count(ledger, "errands_done"))],
			],
		},
		{
			"title": "The company",
			"rows": [
				["Took the road with you", str(roster.characters.size())],
				["Hired along the way", str(count(ledger, "recruited"))],
				["Buried", str(_by_status(roster, "dead").size())],
				["Still held somewhere", str(_by_status(roster, "captured").size())],
			],
		},
	]


## The line the whole run gets summed up in.
static func epitaph(world: World, roster: Roster, ledger: Dictionary) -> String:
	var lead := roster.player()
	var who: String = lead.display_name if lead != null else "The company"
	if world != null and world.tower_topped:
		return "%s conquered the ten floors of the Tower, taking %d gold and overcoming %d foes." % [
			who, count(ledger, "gold_earned"), count(ledger, "kills")
		]
	return "%s walked %d steps, took %d gold, and put down %d of what was waiting." % [
		who, world.steps, count(ledger, "gold_earned"), count(ledger, "kills")
	]


## Everyone who did not come back, newest grave first.
static func the_fallen(world: World, roster: Roster) -> Array:
	var out: Array = []
	for site in world.sites_of_kind(Site.GRAVE):
		out.append({
			"name": site.data.get("name", "someone"),
			"level": int(site.data.get("level", 1)),
			"job": site.data.get("job", ""),
			"killer": site.data.get("killer", ""),
			"step": int(site.data.get("fell_at", 0)),
		})
	# Anyone lost without a marker still belongs on the list.
	var named := out.map(func(entry: Dictionary) -> String: return entry["name"])
	for character in _by_status(roster, "dead"):
		if character.display_name not in named:
			out.append({
				"name": character.display_name,
				"level": character.level,
				"job": character.class_name_text(),
				"killer": "",
				"step": world.steps,
			})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["step"] > b["step"])
	return out


static func _places(ledger: Dictionary) -> Array:
	return ledger.get("places", [])


static func _deeds_of(world: World, kind: String) -> int:
	return world.deeds.filter(func(d: Dictionary) -> bool: return d.get("kind", "") == kind).size()


static func _by_status(roster: Roster, status: String) -> Array:
	return roster.characters.filter(func(c: Character) -> bool: return c.status == status)
