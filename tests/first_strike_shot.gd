extends Node
## Photograph a first strike ([D288], [D300]): the lead out of a band's sight with it in reach, the
## wind-up, and the fight opening on the blow. Needs a display (xvfb-run).
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/first_strike_shot.tscn
##
## Shots land in .art_stage/first_strike_*.png.

var _game: Node


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	_game = load("res://src/main.tscn").instantiate()
	add_child(_game)
	await _frames(30)
	GameState.new_game(20260829, "atlas")
	GameState.set_flag("seen:prologue")
	var world: World = GameState.world
	var here := Vector2i(-1, -1)
	var there := Vector2i(-1, -1)
	for y in world.size.y:
		for x in world.size.x:
			var cell := Vector2i(x, y)
			if here.x >= 0 or world.terrain_id_at(cell) != "grass" or world.site_at(cell) != null:
				continue
			var next := cell + Vector2i.RIGHT
			if world.in_bounds(next) and world.terrain_id_at(next) == "grass" and world.site_at(next) == null:
				here = cell
				there = next
	world.prowlers.clear()
	world.prowlers.append(Prowler.create(there, ["goblin", "goblin", "slime"]))
	world.player_cell = here
	EventBus.request_scene.emit("world", {})
	await _frames(120)
	var ground := _active()
	var watches: Array = ground.get("_watches")
	if watches.is_empty():
		print("no band on the ground")
		get_tree().quit(1)
		return
	var watch: Node2D = watches[0]
	# The nearest walkable cell out of the band's sight, within reach of its figures.
	var band_at: Vector2 = (watch.figures[0] as Node2D).position
	var reach := float(Database.world_rules.get("ground_watch", {}).get("first_strike_reach", 8)) * AreaMap.CELL
	var best := Vector2i(-1, -1)
	var best_d := INF
	var centre: Vector2i = ground.map.cell_at(band_at)
	for dy in range(-10, 11):
		for dx in range(-10, 11):
			var c: Vector2i = centre + Vector2i(dx, dy)
			if not ground.map.is_walkable(c) or watch.watched.has(c):
				continue
			var d: float = ground.map.centre_of(c).distance_to(band_at)
			if d <= reach * 0.8 and d > AreaMap.CELL * 3 and d < best_d:
				best_d = d
				best = c
	if best.x < 0:
		print("nowhere out of sight in reach")
		get_tree().quit(1)
		return
	ground._leader.position = ground.map.centre_of(best)
	ground.set("_last_cell", best)
	var camera = ground.get_node("Camera2D")
	camera.focus_on(ground._leader.position.lerp(band_at, 0.5), true)
	await _frames(20)
	print("strike target: %s, hint: %s" % [ground._strike_target() != null, ground._prompt_text()])
	await _shoot("ready")
	var key := InputEventKey.new()
	key.keycode = KEY_G
	key.pressed = true
	ground._unhandled_input(key)
	await get_tree().create_timer(0.4).timeout
	await _shoot("wind_up")
	await get_tree().create_timer(1.2).timeout
	await _frames(4)
	await _shoot("strike")
	var fight: Node = ground.get("_fight")
	print("fight on: %s, first strike landed: %s, paused: %s" % [fight != null,
			fight.get("first_struck") if fight != null else false, fight.get("paused") if fight != null else "-"])
	await get_tree().create_timer(2.0).timeout
	await _shoot("fight")
	get_tree().quit(0 if fight != null and bool(fight.get("first_struck")) else 1)


func _active() -> Node:
	return get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shoot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://.art_stage/first_strike_%s.png" % label
	get_viewport().get_texture().get_image().save_png(path)
	print("saved %s" % path)
