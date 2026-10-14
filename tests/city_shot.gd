extends Node
## Photograph the great city ([D85]): its gate ward standing walled in its tile on the land, the
## city through the great gate from high up and from the street, its people at their work a little
## later, and the Gilded Flagon. Needs a display (xvfb-run).
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/city_shot.tscn
##
## Shots land in .art_stage/city_*.png.

var _game: Node


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	_game = load("res://src/main.tscn").instantiate()
	add_child(_game)
	await _frames(30)
	GameState.new_game(20260829, "bram")
	GameState.set_flag("seen:prologue")
	var world: World = GameState.world
	var city: Site = null
	for site: Site in world.sites:
		if bool(site.data.get("city", false)):
			city = site
	if city == null:
		print("no city in this world")
		get_tree().quit(1)
		return
	print("the city: %s at %s" % [city.display_name, city.cell])
	world.prowlers.clear()
	world.player_cell = city.cell
	EventBus.request_scene.emit("world", {})
	await _frames(90)
	var ground := _active()
	var camera = ground.get_node("Camera2D")
	camera.call("_apply_zoom", 0.42)
	camera.focus_on(ground._leader.position + Vector2(0, -420), true)
	await _frames(20)
	await _shoot("ward")

	EventBus.request_scene.emit("area", { "area_id": "city_streets", "title": "the city", "return_scene": "world" })
	await _frames(60)
	ground = _active()
	camera = ground.get_node("Camera2D")
	camera.call("_apply_zoom", 0.28)
	camera.focus_on(ground.map.centre_of(Vector2i(30, 20)), true)
	await _frames(20)
	await _shoot("from_above")
	camera.call("_apply_zoom", 0.8)
	camera.focus_on(ground._leader.position + Vector2(0, -260), true)
	await _frames(20)
	await _shoot("gate_square")
	await get_tree().create_timer(12.0).timeout
	camera.focus_on(ground.map.centre_of(Vector2i(14, 24)), true)
	await _frames(10)
	await _shoot("market_row")
	camera.focus_on(ground.map.centre_of(Vector2i(46, 22)), true)
	await _frames(10)
	await _shoot("tavern_lane")
	camera.focus_on(ground.map.centre_of(Vector2i(30, 8)), true)
	await _frames(10)
	await _shoot("cathedral")

	EventBus.request_scene.emit("area", { "area_id": "city_tavern", "title": "the Gilded Flagon", "return_scene": "world" })
	await _frames(60)
	await _shoot("tavern")
	get_tree().quit(0)


func _active() -> Node:
	return get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shoot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://.art_stage/city_%s.png" % label
	get_viewport().get_texture().get_image().save_png(path)
	print("saved %s" % path)
