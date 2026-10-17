extends Node
## Photograph the screen while playing ([D239]): the ground with the party walking it, and the small
## bar along the top that says who is in the company, how they are, and the purse. Needs a display.
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/play_hud_shot.tscn
##
## Shots land in .art_stage/play_hud_*.png, at a wide and a tall window.

func _ready() -> void:
	for size: Vector2i in [Vector2i(1600, 900), Vector2i(720, 1280)]:
		await _shoot_at(size)
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
	# A company of three, one of them hurt and one close to falling, so the bars show all three colours.
	for id: String in ["vesta", "cato"]:
		var joined: Character = GameState.roster.add(Character.create(id))
		GameState.roster.enlist(joined.id)
	var party := GameState.party_characters()
	if party.size() >= 3:
		party[1].hp = maxi(1, party[1].max_hp() / 2)
		party[2].hp = maxi(1, party[2].max_hp() / 5)
	await _frames(20)
	await RenderingServer.frame_post_draw
	var path := "res://.art_stage/play_hud_%dx%d.png" % [size.x, size.y]
	get_viewport().get_texture().get_image().save_png(path)
	print("saved %s" % path)
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
