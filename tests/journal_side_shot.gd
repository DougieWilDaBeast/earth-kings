extends Node
## Photograph the journal open at the side while the party walks the land (play-test 7, call BR7).
## Needs a display (xvfb-run).
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/journal_side_shot.tscn
##
## The shot lands in .art_stage/journal_side.png.


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	add_child(load("res://src/main.tscn").instantiate())
	await _frames(30)
	GameState.new_game(20260829, "juno")
	GameState.set_flag("seen:prologue")
	GameState.world.prowlers.clear()
	EventBus.request_scene.emit("world", {})
	await _frames(150)
	JournalScreen.docked = true
	EventBus.journal_requested.emit()
	Input.action_press("move_down")
	await _frames(40)
	Input.action_release("move_down")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.art_stage/journal_side.png")
	print("saved .art_stage/journal_side.png")
	get_tree().quit(0)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
