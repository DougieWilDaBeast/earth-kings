extends Node
## Photograph the Tower's stand-in (D108) on the land: from the city at its foot, zoomed out so the
## shaft is seen whole, and from the crater, where it stands on the edge of the screen. Needs a
## display (xvfb-run).
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/tower_shot.tscn
##
## Shots land in .art_stage/tower_*.png.


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	add_child(load("res://src/main.tscn").instantiate())
	await _frames(30)
	GameState.new_game(77, "atlas")
	GameState.set_flag("seen:prologue")
	var world: World = GameState.world
	world.prowlers.clear()
	EventBus.request_scene.emit("world", {})
	await _frames(90)
	await _shoot("crater")
	world.player_cell = world.tower().cell + Vector2i(0, 1)
	EventBus.request_scene.emit("world", {})
	await _frames(90)
	var ground := get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)
	var camera = ground.get_node("Camera2D")
	camera.call("_apply_zoom", 0.4)
	var land = ground.map
	var foot := Vector2(world.tower().cell * land.slot + land.slot / 2) * AreaMap.CELL
	camera.focus_on(foot + Vector2(0, -300), true)
	await _frames(20)
	await _shoot("from_the_city")
	get_tree().quit(0)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shoot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://.art_stage/tower_%s.png" % label
	get_viewport().get_texture().get_image().save_png(path)
	print("saved %s" % path)
