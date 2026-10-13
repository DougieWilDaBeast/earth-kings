extends Node
## Photograph the tutorial from the game's own start: the title's offer, the card in the village,
## a conversation, and the sparring fight. Needs a display (xvfb-run), not --headless.
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/tutorial_shot.tscn
##
## Shots land in .art_stage/tutorial_*.png.

var _game: Node


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	_game = load("res://src/main.tscn").instantiate()
	add_child(_game)
	await _wait_for("title", 600)
	await _frames(60)
	# Past the title card to the menu, where the tour is offered the first time.
	var title := _active()
	if title != null and title.has_method("_show_menu"):
		title.call("_show_menu", false)
	await _frames(30)
	await _shoot("title")
	EventBus.tutorial_requested.emit()
	await _wait_for("area", 300)
	await _frames(60)
	await _shoot("welcome")
	var guide := _game.get_node("TutorialGuide")
	guide.call("_on_main_pressed")
	await get_tree().create_timer(1.6).timeout
	await _shoot("walk")
	var area := _active()
	var people: Array = area.get("map").people
	for index in people.size():
		if str(people[index].get("name", "")) == "Maren the Guide":
			area.call("_speak_to", index)
	await _frames(120)
	await _shoot("talk")
	var box := _game.find_children("*", "", true, false).filter(func(n: Node) -> bool: return n.has_method("_choose"))
	if not box.is_empty():
		box[0].call("_advance")
		await _frames(30)
		box[0].call("_choose", 0)
		await _frames(40)
		await _shoot("answer")
		box[0].call("_finish")
	await get_tree().create_timer(1.6).timeout
	# The fight step: the sparring pair comes out into the east field.
	area = _active()
	area.set("_talking", false)
	area.set("_leaving", false)
	GameState.set_flag("tut:spar_ready")
	area.call("_post_practice_bands")
	var watches: Array = area.get("_watches")
	if watches.is_empty():
		print("never: no sparring pair")
		get_tree().quit(1)
		return
	var camera = area.get_node("Camera2D")
	camera.focus_on((watches[0].figures[0] as Node2D).position + Vector2(-160, 40), true)
	await _frames(40)
	await _shoot("spar_ground")
	var map: AreaMap = area.get("map")
	var at: Vector2i = map.cell_at(area._leader.position)
	var cells: Array = watches[0].watched.keys()
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return (a - at).length_squared() < (b - at).length_squared())
	area.call("_check_the_watch", at)
	area._leader.position = map.centre_of(cells[0])
	area.call("_check_the_watch", cells[0])
	await _wait_for("skirmish", 300)
	await _frames(90)
	await _shoot("fight")
	get_tree().quit(0)


func _active() -> Node:
	return get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)


func _wait_for(scene_key: String, frames: int) -> void:
	for i in frames:
		var scene := _active()
		if scene != null and scene.scene_file_path.contains(scene_key):
			return
		if scene_key == "area" and scene != null and scene.scene_file_path.contains("area_scene"):
			return
		await get_tree().process_frame
	print("never reached %s" % scene_key)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shoot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://.art_stage/tutorial_%s.png" % label
	get_viewport().get_texture().get_image().save_png(path)
	print("saved %s" % path)
