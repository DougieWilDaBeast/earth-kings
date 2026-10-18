extends RefCounted
## The Tower's floors above the walked ones ([D207]): walked too, on a borrowed plan.
##
## Floors 1 to `walked_floors` have ground of their own (D102). Every floor above borrows one of their
## plans in turn (`tower.borrowed_plans` in `data/world_rules.json`, [method Chapters.walked_floor_area]),
## and this restocks the plan's bands with the floor's own foes: each band is the floor as a fought
## floor would have it ([method Encounter.for_tower]: its level, its cohort, how many), its keys and
## flags its own so a band beaten on floor 1 does not stand down on floor 6, and never fewer foes
## than the plan's band had (filled out with more of the same). On the top floor the
## first band is the Spire Apex's keeper and the rest stand down. The same floor of the same world is
## always stocked the same way.
##
## Floors 6 to 10 (the Second Hour, [D254]) have ground of their own, but from `tower.own_bands_from`
## up their bands are restocked the same way, all but the floor's keeper, so they climb as the floors
## above them were tuned to.
##
## Loaded by path, not by `class_name` ([D41]).

const Chapters := preload("res://src/chronicle/chapters.gd")


## Whether [param floor] has ground of its own whose bands are still the floor's foes ([D254]).
static func own_bands_restocked(floor: int) -> bool:
	var from := int(Chapters.rules().get("own_bands_from", 0))
	return from > 0 and floor >= from and not Chapters.borrows_a_plan(floor) \
		and Chapters.walked_floor_area(floor) != ""


## [param bands] (a plan's, as its area has them) restocked for [param floor] of [param world], met by
## [param party] (Characters). Floors with their own ground come back as they are. On the top floor
## the keeper stands before the first of [param stairs], as floor 5's does.
static func restock(bands: Array, world: World, floor: int, party: Array, stairs: Array = []) -> Array:
	if world == null or not (Chapters.borrows_a_plan(floor) or own_bands_restocked(floor)):
		return bands
	var tower := world.tower()
	if tower == null:
		return bands
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.world_seed, "tower floor", floor])
	var top := floor >= world.tower_floors()
	var out: Array = []
	for i in bands.size():
		if top and i > 0:
			break
		var band: Dictionary = (bands[i] as Dictionary).duplicate(true)
		# A floor's own keeper keeps its own shape ([D254]: the Keeper of the Tenth), never below the
		# floor's foes.
		if bool(band.get("boss", false)) and not Chapters.borrows_a_plan(floor):
			var level_here := 1
			for foe: Dictionary in Encounter.for_tower(world, tower, floor, party, rng).get("enemies", []):
				level_here = maxi(level_here, int(foe.get("level", 1)))
			band["level"] = maxi(int(band.get("level", 1)), level_here + 1)
			out.append(band)
			continue
		var met := Encounter.for_tower(world, tower, floor, party, rng)
		var pack: Array = []
		var level := 1
		for foe: Dictionary in met.get("enemies", []):
			pack.append(str(foe.get("unit", "")))
			level = maxi(level, int(foe.get("level", 1)))
		if pack.is_empty():
			continue
		# Never fewer than the plan put there: the walked floors below hold two or three a band, and
		# a floor above them is not to be easier (play-test 4, D189).
		var at_least := (bands[i] as Dictionary).get("pack", []).size() as int
		var first := pack.size()
		while pack.size() < at_least:
			pack.append(pack[pack.size() % first])
		var key := "tower%d_%s" % [floor, char(97 + i)]
		band["key"] = key
		band["pack"] = pack
		band["level"] = level
		band["label"] = str(met.get("title", "Floor %d" % floor))
		band["boss"] = top
		if top and not stairs.is_empty():
			var stair: Vector2i = stairs[0]
			band["at"] = [stair.x, stair.y + 4]
			band["reach"] = maxi(int(band.get("reach", 2)), 3)
		band["held"] = true
		band.erase("requires")
		band["requires_not"] = "done:%s" % key
		band["done_flag"] = "done:%s" % key
		out.append(band)
	return out
