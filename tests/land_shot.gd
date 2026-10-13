extends Node
const GroundGen := preload("res://src/area/ground_gen.gd")
## Photograph the land ([D84]): several tiles of it laid side by side from high up, the party
## walking over from one tile into the next with nothing in between, a town standing in its tile,
## and a band walking the land. Needs a display (xvfb-run).
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/land_shot.tscn
##
## Shots land in .art_stage/land_*.png.

var _game: Node


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	_game = load("res://src/main.tscn").instantiate()
	add_child(_game)
	await _frames(30)
	GameState.new_game(20260829, "bram")
	GameState.set_flag("seen:prologue")
	var world: World = GameState.world
	# Open country with a village two tiles east of it, open all the way.
	var here := Vector2i(-1, -1)
	for site: Site in world.sites:
		if site.kind != Site.VILLAGE or here.x >= 0:
			continue
		var start := site.cell + Vector2i(-2, 0)
		var ok := true
		for step in 2:
			var c := start + Vector2i(step, 0)
			if not world.is_walkable(c) or world.site_at(c) != null:
				ok = false
		if ok:
			here = start
	if here.x < 0:
		print("no village with open country west of it")
		get_tree().quit(1)
		return
	world.prowlers.clear()
	world.prowlers.append(Prowler.create(here + Vector2i(0, -1), ["goblin", "goblin", "slime"]))
	world.player_cell = here
	EventBus.request_scene.emit("world", {})
	await _frames(90)
	var ground := _active()
	var camera = ground.get_node("Camera2D")
	camera.call("_apply_zoom", 0.32)
	camera.focus_on(ground._leader.position + Vector2(900, -300), true)
	await _frames(20)
	await _shoot("from_above")
	# The band on the next tile north, patrolling with its red ground; then the continent moves it a
	# tile east, and it walks there across the land.
	var watches: Array = ground.get("_watches")
	print("bands on the land: %d" % watches.size())
	if not watches.is_empty():
		var watch: Node2D = watches[0]
		camera.call("_apply_zoom", 0.6)
		camera.focus_on((watch.figures[0] as Node2D).position, true)
		await _frames(20)
		await _shoot("band")
		var band: Prowler = world.prowlers[0]
		band.cell += Vector2i(1, 0)
		ground._sync_bands([{
			"key": "%d,%d|%s" % [band.home.x, band.home.y, ",".join(band.pack)], "pack": band.pack,
			"sight": band.sight, "reach": band.reach(world), "faction": band.faction, "label": band.label(),
			"tile": [band.cell.x, band.cell.y],
		}])
		print("travelling: %s" % watch.travelling)
		for i in 6:
			await get_tree().create_timer(1.5).timeout
			camera.focus_on((watch.figures[0] as Node2D).position, false)
		await _shoot("band_walked")
		print("band now on tile %s (told %s), travelling %s" % [ground.map.tile_of(watch.anchor), band.cell, watch.travelling])
	camera.call("_apply_zoom", 1.0)
	camera.focus_on(ground._leader.position, true)
	await _frames(10)
	await _shoot("start")
	var scene_was := ground
	var steps := world.steps
	# Walk to the village's way in, two tiles east, the way a player would: along a path, on the keys.
	var land = ground.map
	var village := here + Vector2i(2, 0)
	var goals: Array[Vector2i] = []
	for tile: Vector2i in [here + Vector2i(1, 0), village]:
		goals.append(tile * land.slot + AreaMap.to_cell(GroundGen.slot(world, tile).get("spawn", [0, 0])))
	var shots := 0
	var clock := 0.0
	var pressed := ""
	var way: Array[Vector2] = []
	var goal: Vector2i = goals.pop_front()
	while clock < 70.0:
		if land.cell_at(ground._leader.position) == goal:
			if goals.is_empty():
				break
			goal = goals.pop_front()
		# Worked out again as the land ahead is laid out.
		way = land.find_cell_path(land.cell_at(ground._leader.position), goal)
		if way.size() < 2:
			if not land.in_bounds(goal):
				await get_tree().physics_frame
				clock += get_physics_process_delta_time()
				continue
			break
		var point: Vector2 = way[1]
		while ground._leader.position.distance_to(point) > 10.0 and clock < 70.0:
			_clear_boxes()
			var apart: Vector2 = point - ground._leader.position
			var want := ("move_right" if apart.x > 0 else "move_left") if absf(apart.x) > absf(apart.y) else ("move_down" if apart.y > 0 else "move_up")
			if want != pressed:
				if pressed != "":
					Input.action_release(pressed)
				Input.action_press(want)
				pressed = want
			await get_tree().physics_frame
			clock += get_physics_process_delta_time()
			if clock > shots * 4.0 + 4.0:
				shots += 1
				await _shoot("walk_%d" % shots)
				print("t=%.0fs tile %s steps %d same scene %s" % [clock, world.player_cell, world.steps, _active() == scene_was])
	if pressed != "":
		Input.action_release(pressed)
	await _frames(10)
	await _shoot("arrived")
	camera.call("_apply_zoom", 0.45)
	await _frames(20)
	await _shoot("town_from_above")
	print("steps taken %d, scene kept: %s" % [world.steps - steps, _active() == scene_was])
	get_tree().quit(0)


## Anything put up in the way (a word at the fire, a tip): read and closed, as a player would.
func _clear_boxes() -> void:
	for overlay in get_tree().get_nodes_in_group(EventBus.MODAL_OVERLAY_GROUP):
		if overlay.has_method("is_open") and overlay.is_open():
			if overlay.has_method("_advance"):
				overlay.call("_advance")
			elif overlay.has_method("close"):
				overlay.call("close")


func _active() -> Node:
	return get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shoot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://.art_stage/land_%s.png" % label
	get_viewport().get_texture().get_image().save_png(path)
	print("saved %s" % path)
