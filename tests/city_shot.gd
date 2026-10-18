extends Node
## Photograph the great city ([D85], walked outside since [D247]): Stormreach laid out on the land
## over four tiles, from high up with the Tower at its north gate; the south gate, the high street,
## the market a little later, the north gate with the Tower beyond; and the Gilded Flagon. Needs a
## display (xvfb-run).
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
	GameState.new_game(20260829, "atlas")
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
	await _frames(120)
	var ground := _active()
	var camera = ground.get_node("Camera2D")
	var land: AreaMap = ground.map
	var slot := Vector2i(32, 22)
	# The city's own cells (its streets start two in from the block's corner) as land cells.
	var at := func(x: int, y: int) -> Vector2: return land.centre_of(city.cell * slot + Vector2i(2 + x, 2 + y))
	camera.call("_apply_zoom", 0.42)
	camera.focus_on(at.call(30, 8), true)
	await _frames(30)
	await _shoot("from_above")
	camera.call("_apply_zoom", 0.55)
	camera.focus_on(at.call(30, 34), true)
	await _frames(20)
	await _shoot("south_gate")
	camera.focus_on(at.call(30, 20), true)
	await _frames(10)
	await _shoot("high_street")
	await get_tree().create_timer(10.0).timeout
	camera.focus_on(at.call(14, 26), true)
	await _frames(10)
	await _shoot("market_row")
	camera.call("_apply_zoom", 0.4)
	camera.focus_on(at.call(32, -6), true)
	await _frames(20)
	await _shoot("north_gate")

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
