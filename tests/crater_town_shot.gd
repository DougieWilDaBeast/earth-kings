extends Node
## Photograph the crater before and after Muck Muck has built there ([D251]): the smithy, the
## infirmary, the settlers' houses, their people and the timber wall round it. Needs a display
## (xvfb-run).
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/crater_town_shot.tscn -- --out=DIR

var _out := "res://.art_stage"


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	get_window().size = Vector2i(1600, 900)
	add_child(load("res://src/main.tscn").instantiate())
	await _frames(30)
	for built: bool in [false, true]:
		GameState.new_game(77)
		GameState.set_flag("seen:prologue")
		if built:
			for key: String in ["carried:shut", "town:begun", "town:smithy", "town:infirmary", "town:wall"]:
				GameState.set_flag(key)
		var home: Site = GameState.world.sites_of_kind(Site.HOME)[0]
		GameState.world.player_cell = home.cell
		EventBus.request_scene.emit("world", {})
		await _frames(90)
		var ground: Node = get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)
		var camera = ground.get_node("Camera2D")
		camera.call("_apply_zoom", 0.55)
		camera.focus_on(ground._leader.position + Vector2(0, -220), true)
		await _frames(20)
		await RenderingServer.frame_post_draw
		var name_ := "crater_%s.png" % ("after" if built else "before")
		get_viewport().get_texture().get_image().save_png("%s/%s" % [_out, name_])
		print("shot %s" % name_)
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
