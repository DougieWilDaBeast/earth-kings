extends Node
## Draws worlds as maps, terrain and places, into PNGs (D91).
##
##   godot --headless --path . res://tools/world_maps.tscn -- --seeds=11,77,1616 --out=/tmp/maps
##   godot --headless --path . res://tools/world_maps.tscn -- --fixed     the one world, into docs/images/world/
##
## Each map is the whole continent at four pixels a tile, with every place marked in
## its colour on the world map (the Tower largest). Written to choose the one
## world all runs share; once it is fixed, the same tool draws it after each change.

const PX := 4


func _ready() -> void:
	var seeds: Array = [11, 77, 1616, 2026, 4242, 31337]
	var out := "user://world_maps"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="):
			seeds = Array(arg.trim_prefix("--seeds=").split(",")).map(func(s: String) -> int: return int(s))
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	if OS.get_cmdline_user_args().has("--fixed"):
		DirAccess.make_dir_recursive_absolute("res://docs/images/world")
		draw(WorldGen.generate(1)).save_png("res://docs/images/world/the-world.png")
		print("drew the one world into docs/images/world/the-world.png")
		get_tree().quit(0)
		return
	DirAccess.make_dir_recursive_absolute(out)
	var summary: Array = []
	for world_seed: int in seeds:
		var world := WorldGen.generate_random(world_seed)
		draw(world).save_png("%s/seed_%d.png" % [out, world_seed])
		var counts := {}
		for site: Site in world.sites:
			counts[site.kind] = int(counts.get(site.kind, 0)) + 1
		summary.append({"seed": world_seed, "size": [world.size.x, world.size.y], "places": counts})
		print("seed %d: %s" % [world_seed, counts])
	var file := FileAccess.open(out + "/maps.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(summary, " "))
	get_tree().quit(0)


static func draw(world: World) -> Image:
	var image := Image.create(world.size.x * PX, world.size.y * PX, false, Image.FORMAT_RGB8)
	for y in world.size.y:
		for x in world.size.x:
			var colour := Color(str(world.terrain_at(Vector2i(x, y)).get("color", "#000000")))
			image.fill_rect(Rect2i(x * PX, y * PX, PX, PX), colour)
	for site: Site in world.sites:
		var colour: Color = Site.COLOURS.get(site.kind, Color.WHITE)
		var r := 7 if site.kind == Site.TOWER else 3
		var at := site.cell * PX
		image.fill_rect(Rect2i(at.x - r, at.y - r, r * 2 + PX, r * 2 + PX), Color.BLACK)
		image.fill_rect(Rect2i(at.x - r + 1, at.y - r + 1, r * 2 + PX - 2, r * 2 + PX - 2), colour)
	return image
