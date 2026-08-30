class_name Prowler
extends RefCounted
## A band standing out in the country with its eyes on the ground around it.
##
## Nothing jumps you out of nowhere. Every fight in the open starts because you
## walked into somebody's line of sight, and the map paints that ground red
## before you set foot on it.

## What a band can see across flat, open country.
const BASE_SIGHT := 2
## Brush breaks up a silhouette, so a band never watches a tile of it.
const COVER := "brush"
## How far from where they settled they are willing to drift.
const LEASH := 5
## Odds of shuffling a tile on any given world step.
const RESTLESSNESS := 0.3

const STEPS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var cell: Vector2i = Vector2i.ZERO
var home: Vector2i = Vector2i.ZERO
## Unit ids, in the order they line up on the battlefield.
var pack: Array = []
## What they see before the ground they are standing on has its say.
var sight: int = BASE_SIGHT
## Whose people these are (see [Faction]), for the banner the map paints them in.
var faction: String = Faction.FALLBACK


static func create(cell_: Vector2i, pack_: Array, sight_: int = BASE_SIGHT) -> Prowler:
	var band := Prowler.new()
	band.cell = cell_
	band.home = cell_
	band.pack = pack_
	band.sight = sight_
	return band


## High ground sees further; a river bed sees less.
func reach(world: World) -> int:
	return maxi(1, sight + clampi(int(world.terrain_at(cell).get("height", 0)), -1, 2))


func sees(world: World, at: Vector2i) -> bool:
	if at == cell:
		return true
	if not world.is_walkable(at) or Pathfinder.distance(cell, at) > reach(world):
		return false
	if world.terrain_id_at(at) == COVER:
		return false
	return _clear_line(world, at)


## Every tile this band is watching, for the map to paint red.
func watched(world: World) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var span := reach(world)
	for dy in range(-span, span + 1):
		for dx in range(-span, span + 1):
			var at := cell + Vector2i(dx, dy)
			if sees(world, at):
				out.append(at)
	return out


## A rock face blocks a line of sight. Nothing else does.
func _clear_line(world: World, at: Vector2i) -> bool:
	var span := maxi(absi(at.x - cell.x), absi(at.y - cell.y))
	for i in range(1, span):
		var point := Vector2(cell).lerp(Vector2(at), float(i) / float(span)).round()
		if not world.is_walkable(Vector2i(point)):
			return false
	return true


## Bands drift. Where they stood when you last came through is not where they
## are standing now.
func wander(world: World, rng: RandomNumberGenerator) -> void:
	if rng.randf() > RESTLESSNESS:
		return
	var target: Vector2i = cell + STEPS[rng.randi() % STEPS.size()]
	if not world.is_walkable(target) or Pathfinder.distance(target, home) > LEASH:
		return
	# They keep off doorsteps; there is nothing at a hearth for them but trouble.
	if world.site_at(target) != null or world.distance_to_haven(target) <= 1:
		return
	cell = target


func label() -> String:
	if pack.is_empty():
		return "Something"
	var lead: String = Database.unit_template(pack[0]).get("display_name", pack[0])
	if pack.size() == 1:
		return lead
	return "%s and %d others" % [lead, pack.size() - 1]


func to_dict() -> Dictionary:
	return {
		"cell": [cell.x, cell.y],
		"home": [home.x, home.y],
		"pack": pack,
		"sight": sight,
		"faction": faction,
	}


static func from_dict(payload: Dictionary) -> Prowler:
	var band := Prowler.new()
	var at: Array = payload.get("cell", [0, 0])
	band.cell = Vector2i(int(at[0]), int(at[1]))
	var settled: Array = payload.get("home", at)
	band.home = Vector2i(int(settled[0]), int(settled[1]))
	band.pack = payload.get("pack", [])
	band.sight = int(payload.get("sight", BASE_SIGHT))
	band.faction = str(payload.get("faction", Faction.FALLBACK))
	return band
