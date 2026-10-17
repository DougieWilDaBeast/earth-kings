extends Node
## Photograph fights that used to open a screen of their own and are fought on the ground now
## ([D207]): floor 6 of the Tower walked on a borrowed plan, and a roadside fight stepped into on the
## land. Needs a display (xvfb-run), not --headless.
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/fight_screens_shot.tscn
##
## Shots land in .art_stage/screens_*.png.

const Chapters := preload("res://src/chronicle/chapters.gd")

var _game: Node
var _screens: Array[String] = []


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	_game = load("res://src/main.tscn").instantiate()
	add_child(_game)
	await _frames(30)
	EventBus.request_scene.connect(func(key: String, _payload: Dictionary) -> void: _screens.append(key))
	GameState.new_game(20260829, "janus")
	GameState.set_flag("seen:prologue")
	var world: World = GameState.world
	world.tower_floor = 5
	EventBus.request_scene.emit("area", {
		"area_id": Chapters.walked_floor_area(6), "title": "The Tower, floor 6",
		"return_scene": "world", "tower_floor": 6,
	})
	await _frames(90)
	var floor := _active()
	var watches: Array = floor.get("_watches")
	print("floor 6 bands: %s" % [watches.map(func(w) -> String: return "%s %s L%d" % [w.band["key"], w.band["pack"], w.band["level"]])])
	var camera = floor.get_node("Camera2D")
	camera.focus_on(floor._leader.position.lerp((watches[0].figures[0] as Node2D).position, 0.5), true)
	await _frames(30)
	await _shoot("floor6")
	await _walk_into(floor, watches[0])
	await get_tree().create_timer(2.5).timeout
	await _shoot("floor6_fight")
	print("screens asked for on floor 6: %s" % [_screens])

	# A roadside fight on the land.
	_screens.clear()
	var here := Vector2i(-1, -1)
	for y in range(4, world.size.y - 4):
		for x in range(4, world.size.x - 4):
			var c := Vector2i(x, y)
			if here.x < 0 and world.terrain_id_at(c) == "grass" and world.site_at(c) == null and world.distance_to_haven(c) > 3:
				here = c
	world.prowlers.clear()
	world.player_cell = here
	EventBus.request_scene.emit("world", {})
	await _frames(150)
	var ground := _active()
	(ground.get("_held") as Dictionary)["roadside"] = "trader_ambush"
	ground.call("_stage_roadside", "trader_ambush")
	await _frames(20)
	await _shoot("roadside")
	ground.call("_do_act", { "act": "_step_into_the_road" })
	await get_tree().create_timer(2.5).timeout
	await _shoot("roadside_fight")
	print("screens asked for on the road: %s" % [_screens])
	get_tree().quit(0)


func _walk_into(scene: Node, watch: Node2D) -> void:
	var map: AreaMap = scene.get("map")
	var at: Vector2i = map.cell_at(scene._leader.position)
	var cells: Array = watch.watched.keys()
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return (a - at).length_squared() < (b - at).length_squared())
	scene.call("_check_the_watch", at)
	scene._leader.position = map.centre_of(cells[0])
	scene.call("_check_the_watch", cells[0])


func _active() -> Node:
	return get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shoot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://.art_stage/screens_%s.png" % label
	get_viewport().get_texture().get_image().save_png(path)
	print("saved %s" % path)
