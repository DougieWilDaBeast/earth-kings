extends Node
## Photograph the box a line is said in while walking the land (play-test 7): Sennet's word on the
## Guild's mark, a one-line remark, and a long one, at a wide and a tall window, with a mouse and
## on a touchscreen. Needs a display.
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/talk_box_shot.tscn [-- --out=res://.art_stage]
##
## Shots land in .art_stage/talk_box_<what>_[touch_]<w>x<h>.png.

const SAID := {
	"sennet": [{ "speaker": "Sennet", "text": "New down, are you? Nobody climbs the Tower without the Guild's mark, and the mark is earned at a gate. Greyhollow is open and near. Shut it, then find me at the Tower's door." }],
	"short": [{ "speaker": "", "text": "Something left here." }],
	"long": [{ "speaker": "Cato", "text": "The road bends north past the barrow and the old wall, and every inn between here and the sea will tell you the same thing about what lies under it: nobody who went down came back the same, and most did not come back at all. I would rather walk the long way round." }],
}

var _out_dir := "res://.art_stage"


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	# With a mouse, and as a touchscreen (a laptop with one counts) sees it. The setting is saved,
	# so it is put back as it was.
	var touch_was := Pace.touch_mode
	for touch: String in ["off", "on"]:
		Pace.touch_mode = touch
		for size: Vector2i in [Vector2i(1600, 900), Vector2i(720, 1280)]:
			await _shoot_at(size)
	Pace.touch_mode = touch_was
	get_tree().quit(0)


func _shoot_at(size: Vector2i) -> void:
	get_window().size = size
	var game: Node = load("res://src/main.tscn").instantiate()
	add_child(game)
	await _frames(30)
	GameState.new_game(20260829, "atlas")
	GameState.set_flag("seen:prologue")
	EventBus.request_scene.emit("world", {})
	for i in 120:
		_clear_boxes()
		await get_tree().process_frame
	for what: String in SAID:
		EventBus.conversation_requested.emit(SAID[what])
		await _frames(20)
		await RenderingServer.frame_post_draw
		var path := "%s/talk_box_%s_%s%dx%d.png" % [_out_dir, what, "touch_" if Pace.touch_mode == "on" else "", size.x, size.y]
		get_viewport().get_texture().get_image().save_png(path)
		print("saved %s" % path)
		_clear_boxes()
		await _frames(5)
	game.queue_free()
	await _frames(5)


func _clear_boxes() -> void:
	for overlay in get_tree().get_nodes_in_group(EventBus.MODAL_OVERLAY_GROUP):
		if overlay.has_method("is_open") and overlay.is_open():
			if overlay.has_method("_advance"):
				overlay.call("_advance")
			elif overlay.has_method("close"):
				overlay.call("close")


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
