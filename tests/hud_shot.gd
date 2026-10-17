extends Node
## Photograph a fight's party cards along the bottom of the screen with a full party of six and
## a pouch of draughts, at several window sizes, so a card running off the edge is seen.
## Needs a display (xvfb-run).
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/hud_shot.tscn -- --out=DIR
##
## Shots: hud_<w>x<h>.png in DIR (default .art_stage). Prints each card's rectangle and whether
## it is inside the window.

const Company := preload("res://tests/company.gd")
const SIZES := [Vector2i(1920, 1080), Vector2i(1600, 900), Vector2i(1366, 768), Vector2i(1280, 720)]

var _out := "res://.art_stage"


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	var size_arg := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--party="):
			size_arg = arg.trim_prefix("--party=")
	var party := int(size_arg) if size_arg != "" else 6
	var joined: Array = ["vesta", "iris", "juno", "cato", "ares"].slice(0, party - 1)
	var bad := 0
	for window: Vector2i in SIZES:
		get_window().size = window
		await _frames(4)
		GameState.difficulty = "gentle"
		GameState.roster = Company.found("atlas", joined)
		var map: Dictionary = Database.map("verdant_pass").duplicate(true)
		var fight: Node2D = load("res://src/skirmish/skirmish.tscn").instantiate()
		fight.boot_payload = {"encounter": {"map": map}, "sandbox": true, "touch": false, "paused": true}
		add_child(fight)
		await _frames(30)
		var view := get_viewport().get_visible_rect()
		var cards := fight.find_children("*", "PanelContainer", true, false).filter(
			func(c: Control) -> bool: return c.custom_minimum_size.y >= 100.0 and c.is_visible_in_tree())
		for card: Control in cards:
			var rect := card.get_global_rect()
			var inside := view.encloses(rect)
			if not inside:
				bad += 1
			print("%dx%d card %s inside=%s" % [window.x, window.y, rect, inside])
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/hud_%dx%d.png" % [_out, window.x, window.y])
		fight.queue_free()
		await _frames(4)
	print("cards outside the window: %d" % bad)
	get_tree().quit(0 if bad == 0 else 1)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
