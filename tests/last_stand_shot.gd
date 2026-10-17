extends Node
## Photograph Atlas's last stand (D191) from the game's own start: the last card, the band out of the
## broken gate, the fight played out for real until the company is down, the fall told, and the quiz
## after it. Uses its own copies of the record of the fallen and the settings. Needs a display
## (xvfb-run), not --headless.
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/last_stand_shot.tscn
##
## Shots land in .art_stage/last_stand_*.png.

const Sixteen := preload("res://src/chronicle/sixteen.gd")
const TutorialGuide := preload("res://src/ui/tutorial_guide.gd")

var _game: Node


func _ready() -> void:
	Sixteen.path = "user://earth-kings.sixteen.shot.json"
	TutorialGuide.settings_path = "user://settings.shot.cfg"
	for each in [Sixteen.path, TutorialGuide.settings_path]:
		if FileAccess.file_exists(each):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(each))
	get_window().size = Vector2i(1600, 900)
	_game = load("res://src/main.tscn").instantiate()
	add_child(_game)
	await _wait_for("title", 600)
	await _frames(60)
	EventBus.player_did.connect(func(what: String) -> void:
		print("player_did %s at %d ms" % [what, Time.get_ticks_msec()]))
	EventBus.tutorial_requested.emit()
	await _wait_for("area", 300)
	await _frames(60)
	var guide := _game.get_node("TutorialGuide")
	var steps: Array = guide.get("_steps")
	GameState.set_flag("tut:sparred")
	guide.call("_show", steps.size() - 1)
	var area := _active()
	area.call("_post_practice_bands")
	var watches: Array = area.get("_watches")
	var doomed: Array = watches.filter(func(w) -> bool: return bool(w.band.get("doomed", false)))
	if doomed.is_empty():
		print("never: no doomed band")
		get_tree().quit(1)
		return
	var camera = area.get_node("Camera2D")
	camera.focus_on((doomed[0].figures[0] as Node2D).position + Vector2(220, 60), true)
	await _frames(40)
	await _shoot("doom")
	var map: AreaMap = area.get("map")
	var cells: Array = doomed[0].watched.keys()
	var at: Vector2i = map.cell_at(area._leader.position)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return (a - at).length_squared() < (b - at).length_squared())
	area._leader.position = map.centre_of(cells[0])
	print("into the red at %d ms" % Time.get_ticks_msec())
	area.call("_check_the_watch", cells[0])
	await _frames(90)
	await _shoot("fight")
	var fight: Node = area.get("_fight")
	if fight != null and fight.has_method("set_paused"):
		fight.call("set_paused", false)
	Engine.time_scale = 4.0
	var waited := 0.0
	var sim := 0.0
	while not guide.call("is_telling_the_fall") and waited < 120.0:
		await get_tree().create_timer(0.5, true, false, true).timeout
		waited += 0.5
		if is_instance_valid(fight):
			sim = float(fight.get("sim_time"))
		if waited == 6.0:
			await _shoot("fight_on")
	Engine.time_scale = 1.0
	print("the fight ended after %.1f s (%.1f s of fight); fallen: %s" % [waited, sim, Sixteen.fallen_heroes()])
	await get_tree().create_timer(7.0).timeout
	await _shoot("fall")
	guide.call("_after_the_fall")
	await _wait_for("temper_quiz", 300)
	await _frames(60)
	await _shoot("quiz")
	for each in [Sixteen.path, TutorialGuide.settings_path]:
		if FileAccess.file_exists(each):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(each))
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
	var path := "res://.art_stage/last_stand_%s.png" % label
	get_viewport().get_texture().get_image().save_png(path)
	print("saved %s" % path)
