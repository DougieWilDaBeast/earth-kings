extends Node
## Photograph the land's footpaths, dirt tracks and a signpost ([D206]), from high up and close in.
## Needs a display (xvfb-run).
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/tracks_shot.tscn -- --out=DIR
##
## Prints how many tiles the tracks cross and how many signposts stand, and the nearest signpost's
## words. Shots: tracks_above.png, tracks_close.png in DIR (default .art_stage).

const Tracks := preload("res://src/area/tracks.gd")

var _out := "res://.art_stage"


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	get_window().size = Vector2i(1600, 900)
	var game: Node = load("res://src/main.tscn").instantiate()
	add_child(game)
	await _frames(20)
	GameState.new_game(77)
	GameState.set_flag("seen:prologue")
	var world: World = GameState.world
	var crossed := 0
	var posts: Array[Vector2i] = []
	for y in world.size.y:
		for x in world.size.x:
			var tile := Vector2i(x, y)
			if not Tracks.sides(world, tile).is_empty():
				crossed += 1
			if Tracks.signpost(world, tile) != "":
				posts.append(tile)
	print("tracks cross %d tiles; %d signposts; %d places joined" % [crossed, posts.size(), Tracks.places(world).size()])
	var home := world.player_cell
	posts.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a - home).length_squared() < (b - home).length_squared())
	if posts.is_empty():
		get_tree().quit(1)
		return
	var post := posts[0]
	print("nearest signpost at %s: %s" % [post, Tracks.signpost(world, post)])
	world.player_cell = post
	EventBus.request_scene.emit("world", {})
	await _frames(150)
	var ground: Node = get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)
	var camera = ground.get_node("Camera2D")
	camera.call("_apply_zoom", 0.45)
	camera.focus_on(ground._leader.position, true)
	await _frames(30)
	await _shot("tracks_above")
	camera.call("_apply_zoom", 1.1)
	camera.focus_on(ground._leader.position, true)
	await _frames(20)
	await _shot("tracks_close")
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, name])
	print("shot %s" % name)
