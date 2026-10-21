extends Node
## Photograph the three hamlets ([D329]): Ewe's Hollow, Millrace and Saltcote, each from the middle.
## Needs a display (xvfb-run).
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/hamlet_shot.tscn
##
## Shots land in .art_stage/hamlet_*.png.

var _game: Node


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	_game = load("res://src/main.tscn").instantiate()
	add_child(_game)
	await _frames(30)
	GameState.new_game(20260829, "atlas")
	GameState.set_flag("seen:prologue")
	GameState.world.prowlers.clear()
	for area_id: String in ["hamlet_fold", "hamlet_mill", "hamlet_salt"]:
		EventBus.request_scene.emit("area", { "area_id": area_id, "return_scene": "world" })
		await _frames(30)
		var ground := _active()
		ground.get_node("Camera2D").focus_on(ground.map.centre_of(Vector2i(13, 6)), true)
		await _frames(10)
		await _shoot(area_id.trim_prefix("hamlet_"))
	get_tree().quit()


func _active() -> Node:
	return get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shoot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://.art_stage/hamlet_%s.png" % label
	get_viewport().get_texture().get_image().save_png(path)
	print("saved %s" % path)
