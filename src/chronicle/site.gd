class_name Site
extends RefCounted
## A place on the world map worth walking to.

const KEEP := "keep"
const VILLAGE := "village"
const LIBRARY := "library"
const GATE := "gate"
const TOWER := "tower"
const HUT := "hut"
## The party's own roof — safe, and the only bed they can improve (see [Home]).
const HOME := "home"
## Where somebody of yours went down (see [Memorial]).
const GRAVE := "grave"
## A wild place worth going to ([D309]): a grove, a fen, a scarp, with something in it.
const WILD := "wild"

## Gate difficulty, weakest first. A gate's rank sets its guardian and its reward.
const RANKS := ["E", "D", "C", "B", "A", "S"]

## Gate objectives (see `world_rules.gate.objectives`). Rout is what every other fight is.
const OBJECTIVE_ROUT := "rout"
const OBJECTIVE_GUARDIAN := "guardian"
const OBJECTIVE_HEART := "heart"

## How a place is drawn on a map. A faction that holds a gate or a keep
## overrides the art (see [Faction]); the colour is the fallback token for a
## kind with no art at all.
## How each kind of place is drawn on the map. A gate is a portal, picked by where it stands
## (GATE_ART); a keep is its holder's castle ([Faction.hold_art]).
const ART := {
	TOWER: "res://art/props/landmark/tower_runes.png",
	KEEP: "res://art/world/hold_grey.png",
	VILLAGE: "res://art/buildings/village_house/south.png",
	LIBRARY: "res://art/world/hold_white.png",
	GATE: "res://art/props/landmark/gate_dark.png",
	HUT: "res://art/buildings/hunting_lodge.png",
	GRAVE: "res://art/world/tomb.png",
	# Where the lead fell: a crater, not a castle ([D178]).
	HOME: "res://art/world/crater.png",
	# A standing stone marks a wild place on the map ([D309]).
	WILD: "res://art/props/landmark/rune_stone.png",
}

## A village grown into a great walled city ([D85]) is drawn as one on the map.
const CITY_ART := "res://art/world/hold_crown.png"

const GATE_ART := [
	"res://art/props/landmark/gate_dark.png",
	"res://art/props/landmark/gate_stones.png",
	"res://art/props/landmark/gate_tree.png",
	"res://art/props/landmark/gate_gold.png",
]

const COLOURS := {
	TOWER: Color(0.92, 0.85, 0.45),
	KEEP: Color(0.72, 0.74, 0.82),
	VILLAGE: Color(0.55, 0.78, 0.55),
	LIBRARY: Color(0.55, 0.7, 0.95),
	GATE: Color(0.85, 0.35, 0.35),
	HUT: Color(0.78, 0.66, 0.48),
	GRAVE: Color(0.62, 0.62, 0.66),
	HOME: Color(0.96, 0.6, 0.35),
	WILD: Color(0.5, 0.72, 0.45),
}

var kind: String = VILLAGE
var cell: Vector2i = Vector2i.ZERO
var display_name: String = ""
var rank: String = ""
## Gates only: an open gate spills monsters into the land around it.
var open: bool = false
## World step the gate last swung open, for the dungeon-break clock.
var opened_at: int = 0
## An open gate left too long stops spilling and starts pouring (see [World]).
var broken: bool = false
var cleared: bool = false
var data: Dictionary = {}


static func create(kind_: String, cell_: Vector2i, name_: String) -> Site:
	var site := Site.new()
	site.kind = kind_
	site.cell = cell_
	site.display_name = name_
	return site


static func rank_index(rank_: String) -> int:
	var index := RANKS.find(rank_)
	return maxi(0, index)


## Rough character level a delver should be to survive this rank.
func expected_level() -> int:
	return 1 + rank_index(rank) * 4


## How many fights deep a gate goes before the thing keeping it. A rank E gate
## is a doorway; an S is somewhere you have to decide how far into.
func floors() -> int:
	var rules: Dictionary = Database.world_rules.get("gate", {})
	var base := int(rules.get("floors_base", 1))
	var per_rank := float(rules.get("floors_per_rank", 0.6))
	return maxi(1, base + roundi(per_rank * float(rank_index(rank))))


## Floors of this gate already fought through. Retreating keeps the ground you
## took; losing gives it all back (see `world_scene._settle_up`).
func depth() -> int:
	return int(data.get("depth", 0))


func is_final_floor() -> bool:
	return depth() >= floors() - 1


## What winning this gate's floors takes. Fixed by where the gate stands rather
## than drawn from the world's dice, so it never shifts a seeded run.
func objective() -> String:
	if data.has("objective"):
		return str(data["objective"])
	var kinds: Array = objective_rules().keys()
	if kinds.is_empty():
		return OBJECTIVE_ROUT
	kinds.sort()
	return str(kinds[absi(hash(cell)) % kinds.size()])


## The objective on the floor about to be fought. A keeper only waits on the last.
func floor_objective() -> String:
	var id := objective()
	if bool(objective_rules().get(id, {}).get("final_only", false)) and not is_final_floor():
		return OBJECTIVE_ROUT
	return id


static func objective_rules() -> Dictionary:
	return Database.world_rules.get("gate", {}).get("objectives", {})


static func objective_name(id: String) -> String:
	return str(objective_rules().get(id, {}).get("display_name", id.capitalize()))


static func objective_brief(id: String) -> String:
	return str(objective_rules().get(id, {}).get("brief", ""))


func label() -> String:
	if kind == GATE:
		var held := ", " + demon_name(str(data["demon"])) if str(data.get("demon", "")) != "" else ""
		if broken:
			return "%s (BROKEN %s-rank gate%s)" % [display_name, reading(), held]
		return "%s (%s-rank gate%s)" % [display_name, reading(), held]
	return display_name


# --- readings and double gates ([D293], [D302]) -----------------------------------
#
# The founders: a gate's rank is a reading, its energy and the foes inside, that lets you predict
# what you will face, and it can be wrong; a double gate's rank climbs once you are in, and you
# cannot leave until it is done. Both are fixed by where the gate stands, so a seeded run reads the
# same every time.


static func reading_rules() -> Dictionary:
	return Database.world_rules.get("gate", {}).get("reading", {})


## The rank a gate reads as from outside. A misread gate (one in `wrong_one_in` from `wrong_from`
## up) reads a rank lower than it is, until the company has been in and seen.
func reading() -> String:
	if kind != GATE or rank == "" or bool(data.get("seen_true", false)) or not misread():
		return rank
	return RANKS[maxi(0, rank_index(rank) - 1)]


## Whether this gate's reading is wrong ([D302]): never below `wrong_from` (C).
func misread() -> bool:
	var rules := reading_rules()
	var one_in := int(rules.get("wrong_one_in", 0))
	if one_in <= 0 or rank_index(rank) < rank_index(str(rules.get("wrong_from", "C"))):
		return false
	return absi(hash([cell.x, cell.y, "reading"])) % one_in == 0


## The level the reading says to expect inside.
func reading_level() -> int:
	return 1 + rank_index(reading()) * 4


## Whether this is a double gate ([D302]): `double_base` in a hundred, and `double_per_fallen` more
## for every world already ended, decided the first time it is gone into and kept.
func is_double(fallen: int = 0) -> bool:
	if data.has("double"):
		return bool(data["double"])
	var rules := reading_rules()
	var chance := int(rules.get("double_base", 0)) + int(rules.get("double_per_fallen", 0)) * fallen
	return chance > 0 and rank_index(rank) < RANKS.size() - 1 and absi(hash([cell.x, cell.y, "double"])) % 100 < chance


## The company goes in. A misread gate shows what it is; a double gate, the first time, climbs a
## rank and shuts its way out until its keeper falls. Returns the lines to say.
func gone_into(fallen: int, past: Array = []) -> Array[String]:
	var lines: Array[String] = []
	var rules := reading_rules()
	if kind != GATE:
		return lines
	if misread() and not bool(data.get("seen_true", false)):
		lines.append(str(rules.get("misread_line", "")).format({"gate": display_name, "read": reading(), "rank": rank}))
	data["seen_true"] = true
	# A fallen lead's demon king, if one holds it, is seen the first time in ([D304]).
	var demon := demon_king(past)
	data["demon"] = demon
	if demon != "" and not bool(data.get("demon_seen", false)):
		data["demon_seen"] = true
		lines.append(str(fallen_rules().get("line", "")).format(demon_words(demon)))
	if not data.has("double"):
		data["double"] = is_double(fallen)
	if bool(data["double"]) and not bool(data.get("sprung", false)):
		var was := rank
		rank = RANKS[mini(RANKS.size() - 1, rank_index(rank) + 1)]
		data["sprung"] = true
		lines.append(str(rules.get("double_line", "")).format({"gate": display_name, "was": was, "rank": rank}))
	return lines


## Whether the way out is shut: a double gate once sprung, until it is shut.
func sealed_in() -> bool:
	return kind == GATE and bool(data.get("sprung", false)) and not cleared


# --- demon kings and torn gates ([D293], [D304]) -----------------------------------
#
# The founders: when a lead falls their world burns, and in the gates where that lead would have
# gone you find a demon king version of them and hostile forces coming through; the more worlds fall,
# the more gates are hostile and the harder they get. A key can open an instant gate where it is
# used, for good or ill, and a key is also a place to level your company.


static func fallen_rules() -> Dictionary:
	return Database.world_rules.get("gate", {}).get("fallen", {})


static func instant_rules() -> Dictionary:
	return Database.world_rules.get("gate", {}).get("instant", {})


## The fallen lead whose demon king holds this gate: their hero id, or "" for none. Kept once seen
## (`data.demon`); before that, decided by where the gate stands, from `from` up, `base` in a hundred
## and `per_fallen` more for every world already ended. [param past] is the record of the fallen
## (`world.echoes.past`): no fall, no demon king.
func demon_king(past: Array) -> String:
	if data.has("demon"):
		return str(data["demon"])
	if kind != GATE or past.is_empty():
		return ""
	var rules := fallen_rules()
	if rank_index(rank) < rank_index(str(rules.get("from", "C"))):
		return ""
	var chance := int(rules.get("base", 0)) + int(rules.get("per_fallen", 0)) * past.size()
	if chance <= 0 or absi(hash([cell.x, cell.y, "demon"])) % 100 >= chance:
		return ""
	var echo: Dictionary = past[absi(hash([cell.x, cell.y, "which demon"])) % past.size()]
	return str(echo.get("hero", ""))


## What a fallen lead's demon king is called: "Demon King Iris".
static func demon_name(hero: String) -> String:
	var name := str(Database.unit_template(hero).get("display_name", hero.capitalize()))
	return str(fallen_rules().get("label", "Demon King {name}")).format({"name": name})


## The words a line about this gate's demon king can use: `{name}`, `{demon}`, `{gate}`, `{they}`,
## `{their}`, `{them}`, and each capitalised.
func demon_words(hero: String) -> Dictionary:
	var they := str(Database.hero(hero).get("pronoun", "they"))
	var their := str({"she": "her", "he": "his"}.get(they, "their"))
	var them := str({"she": "her", "he": "him"}.get(they, "them"))
	return {
		"name": str(Database.unit_template(hero).get("display_name", hero.capitalize())),
		"demon": demon_name(hero), "gate": display_name,
		"they": they, "their": their, "them": them,
		"They": they.capitalize(), "Their": their.capitalize(), "Them": them.capitalize(),
	}


## The rank the Gate Key in the company's hands tears, or "" when they hold none: the rank of the
## gate it came out of, kept beside it (`GameState.flags`).
static func key_rank() -> String:
	var rules := instant_rules()
	var key := str(rules.get("key", ""))
	if key == "" or not GameState.keys.has(key):
		return ""
	var rank_ := str(GameState.flags.get(key + ":rank", rules.get("found_from", "C")))
	return rank_ if rank_ in RANKS else str(rules.get("found_from", "C"))


## The Gate Key turned at [param from]: a [param rank_] gate torn there, or on the nearest open cell
## within two when a place already stands there, open from this step and held by a faction seated at
## gates. Null when there is no ground for it.
static func tear(world: World, from: Vector2i, rank_: String) -> Site:
	var cell := _ground_for_a_gate(world, from)
	if cell == Vector2i(-1, -1):
		return null
	var gate := Site.create(GATE, cell, _torn_name(world))
	gate.rank = rank_ if rank_ in RANKS else RANKS[0]
	gate.open = true
	gate.opened_at = world.steps
	var seated: Array = Faction.seated_at(GATE)
	seated.sort()
	var holder := str(seated[absi(hash([cell.x, cell.y, world.steps, "torn"])) % seated.size()]) if not seated.is_empty() else Faction.FALLBACK
	# Its rank is what the key says it is: no reading to put right, never a double gate.
	gate.data = {"area": "gate", "faction": holder, "instant": true, "torn_at": world.steps, "seen_true": true, "double": false}
	world.sites.append(gate)
	return gate


## [param from] itself when it is open ground with nothing on it, else the nearest such cell within
## two, the same one every time; (-1, -1) when there is none.
static func _ground_for_a_gate(world: World, from: Vector2i) -> Vector2i:
	for ring in 3:
		for dy in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dy)) != ring:
					continue
				var cell := from + Vector2i(dx, dy)
				if world.in_bounds(cell) and world.is_walkable(cell) and world.site_at(cell) == null:
					return cell
	return Vector2i(-1, -1)


## The next of the torn gates' names not yet on the map, then a counted one.
static func _torn_name(world: World) -> String:
	var taken: Array = []
	for site: Site in world.sites:
		taken.append(site.display_name)
	for name: Variant in instant_rules().get("names", []):
		if not taken.has(str(name)):
			return str(name)
	var count := 1
	while taken.has("the Tear %d" % count):
		count += 1
	return "the Tear %d" % count


func to_dict() -> Dictionary:
	return {
		"kind": kind,
		"cell": [cell.x, cell.y],
		"display_name": display_name,
		"rank": rank,
		"open": open,
		"opened_at": opened_at,
		"broken": broken,
		"cleared": cleared,
		"data": data,
	}


static func from_dict(payload: Dictionary) -> Site:
	var site := Site.new()
	site.kind = payload.get("kind", VILLAGE)
	var pair: Array = payload.get("cell", [0, 0])
	site.cell = Vector2i(int(pair[0]), int(pair[1]))
	site.display_name = payload.get("display_name", "")
	site.rank = payload.get("rank", "")
	site.open = bool(payload.get("open", false))
	site.opened_at = int(payload.get("opened_at", 0))
	site.broken = bool(payload.get("broken", false))
	site.cleared = bool(payload.get("cleared", false))
	site.data = payload.get("data", {})
	return site
