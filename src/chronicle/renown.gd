class_name Renown
extends RefCounted
## What the country has heard about you.
##
## Every notable act is written down as a *deed* at the place it happened. Deeds
## do not teleport: word travels outward from where it started at a fixed number
## of steps per tile, so a village three days off has not heard yet, and one you
## sacked last week has heard of nothing else.
##
## Standing is therefore local. There is no single number for how famous you
## are — only how much of your name has reached the ground you are standing on.

## Deeds worth telling somebody about.
const GATE_SHUT := "gate_shut"
const TOWN_SAVED := "town_saved"
const TOWN_RAIDED := "town_raided"
const TOWER_TOPPED := "tower_topped"


static func rules() -> Dictionary:
	return Database.world_rules.get("renown", {})


## World steps it takes word to travel one tile.
static func steps_per_tile() -> int:
	return maxi(1, int(rules().get("steps_per_tile", 14)))


## Write a deed down where it happened. [param weight] is positive for things
## that make people glad to see you and negative for the other kind.
static func record(world: World, kind: String, cell: Vector2i, weight: int, line: String) -> void:
	world.deeds.append({
		"kind": kind,
		"cell": [cell.x, cell.y],
		"step": world.steps,
		"weight": weight,
		"line": line,
	})


## How far word of [param deed] has travelled by now, in tiles.
static func reach(world: World, deed: Dictionary) -> int:
	return int(world.steps - int(deed.get("step", 0))) / steps_per_tile()


static func has_reached(world: World, deed: Dictionary, cell: Vector2i) -> bool:
	var pair: Array = deed.get("cell", [0, 0])
	var from := Vector2i(int(pair[0]), int(pair[1]))
	return Pathfinder.distance(from, cell) <= reach(world, deed)


## Every deed the people at [param cell] have heard about.
static func heard_at(world: World, cell: Vector2i) -> Array:
	return world.deeds.filter(func(d: Dictionary) -> bool: return has_reached(world, d, cell))


## What your name is worth on this ground: positive is welcome, negative is not.
static func standing(world: World, cell: Vector2i) -> int:
	var total := 0
	for deed: Dictionary in heard_at(world, cell):
		total += int(deed.get("weight", 0))
	return total


## Where you are best known, whatever they think of you.
static func notoriety(world: World, cell: Vector2i) -> int:
	var total := 0
	for deed: Dictionary in heard_at(world, cell):
		total += absi(int(deed.get("weight", 0)))
	return total


## What these people would call you to your face.
static func title(world: World, cell: Vector2i) -> String:
	var known := notoriety(world, cell)
	if known < int(rules().get("known_at", 3)):
		return "a stranger"
	var mood := standing(world, cell)
	if mood <= -int(rules().get("feared_at", 6)):
		return "feared"
	if mood < 0:
		return "not welcome"
	if mood >= int(rules().get("renowned_at", 10)):
		return "renowned"
	return "spoken of"


## The line a place greets you with, or empty if nobody here knows you.
static func greeting(world: World, cell: Vector2i, who: String) -> String:
	var name_ := title(world, cell)
	if name_ == "a stranger":
		return ""
	var newest := _newest_heard(world, cell)
	if newest == "":
		return "They know %s here. You are %s." % [who, name_]
	return "They know %s here — %s. You are %s." % [who, newest, name_]


## Goods and people cost less where you are welcome and more where you are not.
## Capped either way, because nobody trades themselves out of business.
static func price_multiplier(world: World, cell: Vector2i) -> float:
	var swing := float(rules().get("price_swing", 0.03)) * float(standing(world, cell))
	var cap := float(rules().get("price_cap", 0.3))
	return 1.0 - clampf(swing, -cap, cap)


static func _newest_heard(world: World, cell: Vector2i) -> String:
	var best: Dictionary = {}
	for deed: Dictionary in heard_at(world, cell):
		if best.is_empty() or int(deed.get("step", 0)) > int(best.get("step", 0)):
			best = deed
	return best.get("line", "")
