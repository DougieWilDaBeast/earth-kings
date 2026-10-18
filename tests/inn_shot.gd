extends Node
## Photograph an inn with a night paid for ([D242]): the pin on the room's bed, the dotted line to it,
## "Your room" over it and the compass on it. Needs a display (xvfb-run).
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/inn_shot.tscn -- --area=dune_serai --out=DIR

var _out := "res://.art_stage"
var _area := "dune_serai"


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--area="):
			_area = arg.trim_prefix("--area=")
	get_window().size = Vector2i(1600, 900)
	var game: Node = load("res://src/main.tscn").instantiate()
	add_child(game)
	await _frames(20)
	GameState.new_game(77)
	GameState.set_flag("seen:prologue")
	EventBus.request_scene.emit("area", { "area_id": _area, "return_scene": "world" })
	await _frames(60)
	var room: Node = get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)
	GameState.set_flag("inn_room_paid")
	room._settle_the_room()
	await _frames(30)
	var camera = room.get_node("Camera2D")
	camera.call("_apply_zoom", 0.75)
	camera.focus_on(room.map.centre_of(room._your_bed()) + Vector2(0, 260), true)
	await _frames(20)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/inn_%s.png" % [_out, _area])
	print("shot inn_%s" % _area)
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
