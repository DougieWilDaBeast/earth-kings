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
		if broken:
			return "%s (BROKEN %s-rank gate)" % [display_name, reading()]
		return "%s (%s-rank gate)" % [display_name, reading()]
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
func gone_into(fallen: int) -> Array[String]:
	var lines: Array[String] = []
	var rules := reading_rules()
	if kind != GATE:
		return lines
	if misread() and not bool(data.get("seen_true", false)):
		lines.append(str(rules.get("misread_line", "")).format({"gate": display_name, "read": reading(), "rank": rank}))
	data["seen_true"] = true
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
