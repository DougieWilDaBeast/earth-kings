extends Node
## Photograph areas, so a change to how a place looks can be seen without opening the game.
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/area_shot.tscn -- --areas=village,wild_grove [--whole]
##
## Each lands in .art_stage/area_<id>.png. Needs a display: it does nothing under --headless.

var _out_dir := "res://.art_stage"
## With --whole, the camera pulls back until the whole place fits.
var _whole := false
## With --talk=<name>, speak to that person and photograph the conversation; --steps=a,3 clicks
## on once and then picks the fourth reply (to open the shop, say).
var _talk := ""
## Each step: "a" to click on, or the number of the reply to pick.
var _steps: PackedStringArray = []


func _ready() -> void:
	var wanted: Array = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--areas="):
			wanted = arg.trim_prefix("--areas=").split(",", false)
		elif arg.begins_with("--talk="):
			_talk = arg.trim_prefix("--talk=")
		elif arg.begins_with("--steps="):
			_steps = arg.trim_prefix("--steps=").split(",", false)
		elif arg == "--whole":
			_whole = true
		elif arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	if wanted.is_empty():
		wanted = ["village"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	get_window().size = Vector2i(1600, 900)
	await get_tree().process_frame
	GameState.new_game(20260829, "atlas")
	add_child(load("res://src/ui/cutscene_layer.tscn").instantiate())
	if _talk != "":
		add_child(load("res://src/dialogue/dialogue_box.tscn").instantiate())
	for area_id: String in wanted:
		await _shoot(area_id)
	get_tree().quit(0)


func _shoot(area_id: String) -> void:
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": area_id, "return_scene": "world" })
	add_child(scene)
	for i in 30:
		await get_tree().process_frame
	if _talk != "":
		await _open_talk(scene)
	if _whole:
		var tween: Tween = scene.get_node("Camera2D").pull_back(0.05)
		await tween.finished
		for i in 10:
			await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var path := "%s/area_%s.png" % [_out_dir, area_id]
	shot.save_png(path)
	print("saved %s %dx%d" % [path, shot.get_width(), shot.get_height()])
	scene.queue_free()
	await get_tree().process_frame


func _open_talk(scene: Node) -> void:
	var map: AreaMap = scene.get("map")
	for index in map.people.size():
		if str(map.people[index].get("name", "")) == _talk:
			scene.call("_speak_to", index)
			break
	for i in 90:
		await get_tree().process_frame
	var box := find_children("*", "", true, false).filter(func(n: Node) -> bool: return n.has_method("_choose"))
	if box.is_empty():
		return
	for step: String in _steps:
		if step == "a":
			box[0].call("_advance")
		else:
			box[0].call("_choose", int(step))
		for i in 20:
			await get_tree().process_frame
