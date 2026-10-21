extends Node
const GroundGen := preload("res://src/area/ground_gen.gd")
## Photograph the rises on the land ([D324]): a hill tile with higher ground on it and its slopes,
## from near and from high up. Needs a display (xvfb-run).
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/rise_shot.tscn
##
## Shots land in .art_stage/rise_*.png.


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	var game: Node = load("res://src/main.tscn").instantiate()
	add_child(game)
	await _frames(30)
	GameState.new_game(20260829, "atlas")
	GameState.set_flag("seen:prologue")
	var world: World = GameState.world
	var here := Vector2i(-1, -1)
	var most := 0
	var looked := 0
	for y in world.size.y:
		for x in world.size.x:
			var cell := Vector2i(x, y)
			if world.terrain_id_at(cell) != "hill" or not world.is_walkable(cell) or world.site_at(cell) != null:
				continue
			looked += 1
			if looked > 30:
				break
			var count := (GroundGen.slot(world, cell)["terrain"] as PackedStringArray).count("rise")
			if count > most:
				most = count
				here = cell
	if here.x < 0:
		print("no hill with a rise")
		get_tree().quit(1)
		return
	print("rises on %s: %d cells" % [here, most])
	world.prowlers.clear()
	world.player_cell = here
	EventBus.request_scene.emit("world", {})
	await _frames(90)
	var ground: Node = get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)
	var camera = ground.get_node("Camera2D")
	var ways: Dictionary = ground.map.ways_up
	print("slopes held: %d" % ways.size())
	if not ways.is_empty():
		camera.focus_on(ground.map.centre_of(ways.keys()[0]), true)
	camera.call("_apply_zoom", 0.55)
	await _frames(20)
	await _shoot("near")
	camera.call("_apply_zoom", 0.3)
	await _frames(20)
	await _shoot("above")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shoot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://.art_stage/rise_%s.png" % label
	get_viewport().get_texture().get_image().save_png(path)
	print("saved %s" % path)
