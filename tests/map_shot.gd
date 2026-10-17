extends Node
## Photograph the ground with the party on it, then the map opened over it.
##
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 res://tests/map_shot.tscn -- --out=DIR
##
## Shots: ground.png, map.png (and map_menu.png once a place is right-clicked) in DIR.

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
	EventBus.request_scene.emit("world", {})
	await _frames(120)
	await _shot("ground")
	EventBus.map_requested.emit()
	await _frames(60)
	await _shot("map")
	# A marker placed, a place picked to go to, and the party walking there under the open map.
	var ground: Node = get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)
	var screen: CanvasLayer = ground.get("_map_screen")
	var world: World = GameState.world
	var Markers := preload("res://src/world/markers.gd")
	var walkable: Array[Vector2i] = []
	for d: Vector2i in [Vector2i(3, -2), Vector2i(-4, 1), Vector2i(2, 4), Vector2i(5, 0), Vector2i(-2, -3)]:
		if world.is_walkable(world.player_cell + d):
			walkable.append(world.player_cell + d)
	if walkable.size() >= 2:
		print(Markers.place(world, walkable[0]))
		print(Markers.go_to(world, walkable[1]))
	var steps := world.steps
	await _frames(30)
	await _shot("map_marked")
	var map: Control = screen.get("map")
	map.open_menu(walkable[0] if not walkable.is_empty() else world.player_cell, Vector2(800, 400))
	await _frames(5)
	await _shot("map_menu")
	map.get("_menu").hide()
	for i in 600:
		await get_tree().process_frame
	print("steps while the map was open: %d -> %d, at %s" % [steps, world.steps, world.player_cell])
	await _shot("map_walked")
	screen.close()
	await _frames(30)
	await _shot("ground_after")
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [_out, name])
	print("shot %s" % name)
