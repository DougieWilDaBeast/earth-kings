extends Node
## Photograph a band met on the ground ([D66]): the band and its watched cells, the moment it
## sees the party, and the fight on that same ground. Needs a display (xvfb-run).
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/band_shot.tscn -- [--pack=goblin,goblin,slime] [--here]
##
## Shots land in .art_stage/band_*.png.

var _game: Node


func _ready() -> void:
	var pack: Array = ["goblin", "goblin", "slime"]
	## --here: the band camps on the party's own tile, not the next one watching it.
	var here_too := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pack="):
			pack = Array(arg.trim_prefix("--pack=").split(",", false))
		elif arg == "--here":
			here_too = true
	get_window().size = Vector2i(1600, 900)
	_game = load("res://src/main.tscn").instantiate()
	add_child(_game)
	await _frames(30)
	GameState.new_game(20260829, "atlas")
	GameState.set_flag("seen:prologue")
	var world: World = GameState.world
	var here := Vector2i(-1, -1)
	var there := Vector2i(-1, -1)
	for y in world.size.y:
		for x in world.size.x:
			var cell := Vector2i(x, y)
			if here.x >= 0 or world.terrain_id_at(cell) != "grass" or world.site_at(cell) != null:
				continue
			var next := cell + Vector2i.RIGHT
			if world.in_bounds(next) and world.terrain_id_at(next) == "grass" and world.site_at(next) == null:
				here = cell
				there = next
	world.prowlers.clear()
	world.prowlers.append(Prowler.create(here if here_too else there, pack))
	world.player_cell = here
	EventBus.request_scene.emit("world", {})
	await _frames(120)
	var ground := _active()
	var watches: Array = ground.get("_watches")
	if watches.is_empty():
		print("no band on the ground")
		get_tree().quit(1)
		return
	var camera = ground.get_node("Camera2D")
	var band_at: Vector2 = (watches[0].figures[0] as Node2D).position
	camera.focus_on(ground._leader.position.lerp(band_at, 0.5), true)
	await _frames(30)
	await _shoot("ground")
	# The band patrols: the same ground a few seconds on.
	var was: Vector2i = watches[0].anchor
	await get_tree().create_timer(7.0).timeout
	await _shoot("ground_later")
	print("patrol: anchor %s -> %s, loop of %d stops" % [was, watches[0].anchor, watches[0]._loop.size()])
	var cells: Array = watches[0].watched.keys()
	var at: Vector2i = ground.map.cell_at(ground._leader.position)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return (a - at).length_squared() < (b - at).length_squared())
	ground._check_the_watch(at)
	ground._leader.position = ground.map.centre_of(cells[0])
	ground._check_the_watch(cells[0])
	await _frames(20)
	await _shoot("seen")
	await get_tree().create_timer(0.9).timeout
	await _frames(8)
	await _shoot("fight_opens")
	await get_tree().create_timer(2.0).timeout
	await _shoot("fight")
	# Fought where it was met (step 4 of the First Hour): the same scene throughout, and the party
	# back on its feet on that ground once it is over.
	await get_tree().create_timer(14.0).timeout
	await _shoot("after")
	print("after the fight: %s, still the ground: %s" % [_active().name, _active() == ground])
	print("leader %s visible %s, camera %s" % [ground._leader.position, ground._leader.visible, camera.get_screen_center_position()])
	get_tree().quit(0)


func _active() -> Node:
	return get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shoot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://.art_stage/band_%s.png" % label
	get_viewport().get_texture().get_image().save_png(path)
	print("saved %s" % path)
