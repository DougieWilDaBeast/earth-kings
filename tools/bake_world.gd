extends Node
## Makes `data/world_map.json`, the one world every run is played on (D91, D92).
##
##   godot --headless --path . res://tools/bake_world.tscn
##
## Run on 2026-10-14 to freeze Map F (seed 31337) with the Tower moved to the
## middle, as `doug-md` chose. After that the map is improved by editing the file;
## running this again throws those edits away, so it refuses while the file exists
## unless given `-- --force`.

const SEED := 31337
const OUT := "res://data/world_map.json"
## Not closer than this to the Tower, as everywhere else keeps from everywhere else.
const SPACING := 9


func _ready() -> void:
	if FileAccess.file_exists(OUT) and not OS.get_cmdline_user_args().has("--force"):
		push_error("%s exists and holds the hand-made world; pass -- --force to overwrite it" % OUT)
		get_tree().quit(1)
		return
	var world := WorldGen.generate_random(SEED)
	var moved := _tower_to_the_middle(world)
	WorldGen._rank_gates(world)
	var map := {
		"_doc": "The one world every run is played on (D91, D92, docs/27). Chosen by doug-md on 2026-10-12 and frozen on 2026-10-14 from the generator's seed 31337 (Map F), with the Tower moved to the middle. Improve it by hand: `tiles` are rows of terrain symbols (see `World.LEGEND` in src/chronicle/world.gd), `sites` the places. A run copies it and never writes back. Draw it with `tools/world_maps.tscn -- --fixed`.",
		"name": "Earth",
		"from_seed": SEED,
		"size": [world.size.x, world.size.y],
		"tiles": world.tiles,
		"sites": world.sites.map(func(s: Site) -> Dictionary: return s.to_dict()),
	}
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(map, "\t") + "\n")
	file.close()
	print("wrote %s: %d places; the Tower at %s; %s moved out of its way" % [OUT, world.sites.size(), world.tower().cell, moved])
	get_tree().quit(0)


## Put the Tower on open ground as near the middle as there is, and send anything
## crowding it to the nearest spot that keeps its distance from everything.
func _tower_to_the_middle(world: World) -> Array:
	var tower := world.tower()
	tower.cell = Vector2i(-100, -100)
	var middle := world.size / 2
	var spot := middle
	for r in 30:
		var best := Vector2i(-1, -1)
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var cell := middle + Vector2i(dx, dy)
				if world.is_walkable(cell) and world.terrain_id_at(cell) != "water" and world.site_at(cell) == null:
					best = cell
					break
			if best.x >= 0:
				break
		if best.x >= 0:
			spot = best
			break
	tower.cell = spot
	var moved: Array = []
	for site: Site in world.sites:
		if site == tower or Pathfinder.distance(site.cell, spot) >= SPACING:
			continue
		var was := site.cell
		site.cell = Vector2i(-100, -100)
		site.cell = _clear_spot_near(world, was)
		moved.append("%s %s %s→%s" % [site.kind, site.display_name, was, site.cell])
	return moved


func _clear_spot_near(world: World, around: Vector2i) -> Vector2i:
	for r in range(1, 40):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var cell := around + Vector2i(dx, dy)
				if not world.is_walkable(cell) or world.terrain_id_at(cell) == "water":
					continue
				if world.sites.all(func(s: Site) -> bool: return Pathfinder.distance(s.cell, cell) >= SPACING):
					return cell
	return around
