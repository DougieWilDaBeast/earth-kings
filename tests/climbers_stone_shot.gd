extends Node
## Photograph the climbers' stone at the Tower's door being read (play-test 7, call BR3), with two
## leads fallen before and this one on floor 4. Needs a display (xvfb-run).
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/climbers_stone_shot.tscn
##
## The shot lands in .art_stage/climbers_stone.png.

const Sixteen := preload("res://src/chronicle/sixteen.gd")


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	Sixteen.path = "user://climbers_stone_shot.sixteen.json"
	Sixteen.fall("vesta", { "name": "Vesta", "floor": 9 })
	Sixteen.fall("atlas", { "name": "Atlas", "floor": 3 })
	add_child(load("res://src/main.tscn").instantiate())
	await _frames(30)
	GameState.new_game(20260829, "juno")
	GameState.set_flag("seen:prologue")
	GameState.world.tower_floor = 4
	EventBus.request_scene.emit("area", { "area_id": "tower", "title": "the foot of the Tower", "return_scene": "world" })
	await _frames(90)
	var ground := get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)
	for thing in ground.get_node("Actors").get_children():
		if thing is AreaProp and (thing as AreaProp).reads == "climbers":
			ground._leader.position = thing.position + Vector2(40, 30)
			ground._examine(thing)
	await _frames(40)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.art_stage/climbers_stone.png")
	print("saved .art_stage/climbers_stone.png")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Sixteen.path))
	get_tree().quit(0)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
