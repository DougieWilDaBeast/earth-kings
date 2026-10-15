extends Node
## Photograph the First Hour's route the way a player sees it, at 1280 x 720: the crater, the road
## short of the city, and the Tower's yard from where you walk in, half way up it and at its door.
## Used for before-and-after shots of art changes.
## Needs a display (xvfb-run).
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/route_shot.tscn -- --tag=after
##
## Shots land in .art_stage/route_<tag>_*.png.

var _tag := "now"


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="):
			_tag = arg.substr(6)
	get_window().size = Vector2i(1280, 720)
	add_child(load("res://src/main.tscn").instantiate())
	await _frames(30)
	GameState.new_game(77, "atlas")
	GameState.set_flag("seen:prologue")
	GameState.set_flag("seen:walked")
	var world: World = GameState.world
	world.prowlers.clear()
	# The stair open, as it is once the first gate is shut.
	world.tower_sealed_at = -1
	var tower := world.tower()
	# Where Atlas lands, and a few tiles short of the city, with the Tower on the screen's edge.
	EventBus.request_scene.emit("world", {})
	await _frames(150)
	await _shoot("crater")
	world.player_cell = tower.cell + Vector2i(-5, 3)
	GameState.land_cell = null
	EventBus.request_scene.emit("world", {})
	await _frames(150)
	await _shoot("road")
	# In the yard the Tower itself is the objective: the city reached, the Guild seen, a gate shut.
	GameState.set_flag("objective:town")
	GameState.set_flag("objective:guild")
	for gate: Site in world.sites_of_kind(Site.GATE):
		gate.cleared = true
		break
	for spot: Array in [["yard", Vector2i(15, 17)], ["mid_yard", Vector2i(14, 12)], ["door", Vector2i(14, 8)]]:
		world.player_cell = tower.cell
		GameState.land_cell = tower.cell * Vector2i(32, 22) + (spot[1] as Vector2i)
		EventBus.request_scene.emit("world", {})
		await _frames(150)
		await _shoot(str(spot[0]))
	get_tree().quit(0)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shoot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://.art_stage/route_%s_%s.png" % [_tag, label]
	get_viewport().get_texture().get_image().save_png(path)
	print("saved %s" % path)
