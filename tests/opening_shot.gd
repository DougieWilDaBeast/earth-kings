extends Node
## Photograph the opening cinematic ([D328]): every shot, part way through and near its end, for
## a lead with no art for their object yet (Atlas), on the first life. Needs a display (xvfb-run).
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/opening_shot.tscn
##
## Shots land in .art_stage/opening_<n>_<shot>_<part>.png.


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	var opening: Control = load("res://src/ui/opening.tscn").instantiate()
	opening.boot_payload = {"lead": "atlas", "fallen_heroes": []}
	add_child(opening)
	await _frames(5)
	var n := 0
	while not opening.finished and n < 30:
		n += 1
		var time := float(opening.current().get("time", 6.0))
		for part: float in [0.5, 0.92]:
			opening.elapsed = time * part
			opening.queue_redraw()
			await _frames(2)
			await _shoot("%02d_%s_%d" % [n, opening.shot_id(), int(part * 100)])
		opening.next_shot()
		await _frames(2)
	get_tree().quit(0)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shoot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://.art_stage/opening_%s.png" % label
	get_viewport().get_texture().get_image().save_png(path)
	print("saved %s" % path)
