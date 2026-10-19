extends Node
## Photograph Sennet speaking from afar (play-test 7, call BR8): his ghost beside the lead on the
## land and his blue face in the talk box. Needs a display (xvfb-run).
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/sennet_shot.tscn
##
## The shot lands in .art_stage/sennet_afar.png.


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	add_child(load("res://src/main.tscn").instantiate())
	await _frames(30)
	GameState.new_game(20260829, "juno")
	GameState.set_flag("seen:prologue")
	GameState.world.prowlers.clear()
	EventBus.request_scene.emit("world", {})
	await _frames(150)
	EventBus.conversation_requested.emit([{ "speaker": "Sennet",
		"text": "Greyhollow is the nearest gate at your rank. Shut it, and I mark you for the Tower.", "afar": true }])
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.art_stage/sennet_afar.png")
	print("saved .art_stage/sennet_afar.png")
	get_tree().quit(0)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
