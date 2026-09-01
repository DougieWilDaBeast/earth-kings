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

## How a place is drawn on a map. A faction that holds a gate or a keep
## overrides the art (see [Faction]); the colour is the fallback token for a
## kind with no art at all.
const ART := {
	TOWER: "res://art/world/hold_spire.png",
	KEEP: "res://art/world/hold_grey.png",
	VILLAGE: "res://art/world/hold_pale.png",
	LIBRARY: "res://art/world/hold_white.png",
	GATE: "res://art/world/hold_dark.png",
	HUT: "res://art/world/hold_dun.png",
	GRAVE: "res://art/world/tomb.png",
	HOME: "res://art/world/hold_red.png",
}

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


func label() -> String:
	if kind == GATE:
		if broken:
			return "%s (BROKEN %s-rank gate)" % [display_name, rank]
		return "%s (%s-rank gate)" % [display_name, rank]
	return display_name


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
