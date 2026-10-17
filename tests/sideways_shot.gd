extends Node
## Photograph the screens a phone shows when it is turned on its side, and list every button that
## falls off the screen. itch.io's full-screen button turns a phone to landscape (the page is
## embedded 1280 x 720), and the game is then laid out 540 of its pixels tall. Needs a display
## (xvfb-run), not --headless.
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/sideways_shot.tscn -- --size=844x390
##
## Shots land in .art_stage/sideways_<w>x<h>_<screen>.png. Exits 1 if any button is cut off.

var _game: Node
var _size := Vector2i(844, 390)
var _cut := 0


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--size="):
			var parts := arg.trim_prefix("--size=").split("x")
			_size = Vector2i(int(parts[0]), int(parts[1]))
	get_window().size = _size
	Pace.touch_mode = "on"
	_game = load("res://src/main.tscn").instantiate()
	add_child(_game)
	await _frames(40)
	var title := _active()
	title.call("_show_menu", false)
	await _frames(20)
	await _look("title")

	GameState.new_game(20260829, "atlas")
	GameState.set_flag("seen:prologue")
	EventBus.request_scene.emit("world", {})
	await _frames(150)
	await _look("world")
	for screen: Array in [
		["party", EventBus.party_screen_requested], ["journal", EventBus.journal_requested],
		["map", EventBus.map_requested], ["menu", EventBus.system_menu_requested],
		["how_to_play", EventBus.how_to_play_requested],
	]:
		(screen[1] as Signal).emit()
		await _frames(30)
		await _look(screen[0])
		_close_overlays()
		await _frames(10)

	# A roadside fight on the ground, as the First Hour's fights are fought ([D207]).
	var world: World = GameState.world
	var here := Vector2i(-1, -1)
	for y in range(4, world.size.y - 4):
		for x in range(4, world.size.x - 4):
			var c := Vector2i(x, y)
			if here.x < 0 and world.terrain_id_at(c) == "grass" and world.site_at(c) == null and world.distance_to_haven(c) > 3:
				here = c
	world.prowlers.clear()
	world.player_cell = here
	EventBus.request_scene.emit("world", {})
	await _frames(150)
	var ground := _active()
	(ground.get("_held") as Dictionary)["roadside"] = "trader_ambush"
	ground.call("_stage_roadside", "trader_ambush")
	await _frames(20)
	ground.call("_do_act", { "act": "_step_into_the_road" })
	await get_tree().create_timer(2.5).timeout
	await _look("fight")
	print("sideways %dx%d: %d button(s) cut off" % [_size.x, _size.y, _cut])
	get_tree().quit(1 if _cut > 0 else 0)


## Every button showing must sit wholly on the screen, or a thumb cannot reach it.
func _look(label: String) -> void:
	await RenderingServer.frame_post_draw
	var view := get_viewport().get_visible_rect()
	var pad: Array[Control] = []
	var rest: Array[Control] = []
	for button: Node in get_tree().root.find_children("*", "BaseButton", true, false):
		var control := button as Control
		if not control.is_visible_in_tree() or control.size == Vector2.ZERO:
			continue
		var rect := control.get_global_rect()
		if not view.grow(1.0).encloses(rect) and _on_canvas_top(control):
			_cut += 1
			print("CUT %s: %s '%s' at %s (screen %s)" % [label, control.name, _text(control), rect, view.size])
		if _under(control, "TouchControls"):
			pad.append(control)
		else:
			rest.append(control)
	# The walking pad stays up through a fight on the ground; nothing of the fight's may hide under it.
	for mine: Control in pad:
		for theirs: Control in rest:
			if mine.get_global_rect().grow(-1.0).intersects(theirs.get_global_rect()):
				_cut += 1
				print("UNDER %s: %s '%s' lies under the pad's %s" % [label, theirs.name, _text(theirs), mine.name])
	var path := "res://.art_stage/sideways_%dx%d_%s.png" % [_size.x, _size.y, label]
	get_viewport().get_texture().get_image().save_png(path)
	print("saved %s" % path)


func _text(control: Control) -> String:
	var said = control.get("text")
	return said if said != null else ""


func _under(control: Node, script_class: String) -> bool:
	var node := control.get_parent()
	while node != null:
		if node.get_script() != null and (node.get_script() as Script).get_global_name() == script_class:
			return true
		node = node.get_parent()
	return false


## Buttons inside a scroll box are reached by scrolling; only the box itself must fit.
func _on_canvas_top(control: Control) -> bool:
	var node := control.get_parent()
	while node != null:
		if node is ScrollContainer:
			return false
		node = node.get_parent()
	return true


func _close_overlays() -> void:
	for i in 3:
		var press := InputEventKey.new()
		press.keycode = KEY_ESCAPE
		press.pressed = true
		Input.parse_input_event(press)
		var release := press.duplicate()
		release.pressed = false
		Input.parse_input_event(release)


func _active() -> Node:
	return get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
