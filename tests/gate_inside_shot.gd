extends Node
## Photograph a gate gone into from the land ([D248]): its first floor as the party comes in, the
## same floor drawn whole, a band of it fought where it stands, and each kind of gate's floor seen
## whole. Needs a display (xvfb-run), not --headless.
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/gate_inside_shot.tscn
##
## Shots land in .art_stage/gate_inside_*.png.

const GateInside := preload("res://src/chronicle/gate_inside.gd")

var _game: Node


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	_game = load("res://src/main.tscn").instantiate()
	add_child(_game)
	await _frames(30)
	GameState.new_game(20260829, "janus")
	GameState.set_flag("seen:prologue")
	var world: World = GameState.world
	var gate: Site = null
	for site: Site in world.sites_of_kind(Site.GATE):
		if site.floors() >= 2 and (gate == null or site.floors() < gate.floors()):
			gate = site
	if not gate.open:
		world.open_gate(gate)
	world.prowlers.clear()
	world.player_cell = gate.cell
	EventBus.request_scene.emit("world", {})
	await _frames(150)
	var ground := _active()
	ground.call("_do_act", { "act": "_enter_gate_here" })
	await _frames(150)
	var floor := _active()
	print("inside: %s, gate cell %s, %d bands" % [floor.get("map").display_name, floor.get("_gate_cell"), (floor.get("_watches") as Array).size()])
	await _shoot("door")
	await _whole(floor, "floor1")
	var watches: Array = floor.get("_watches")
	if not watches.is_empty():
		await _walk_into(floor, watches[0])
		await get_tree().create_timer(2.5).timeout
		await _shoot("fight")
	# Each kind of gate's look, its last floor whole.
	var seen := {}
	for site: Site in world.sites_of_kind(Site.GATE):
		var look := str(site.data.get("area", ""))
		if seen.has(look):
			continue
		seen[look] = true
		var last := site.floors() - 1
		EventBus.request_scene.emit("area", {
			"area_id": GateInside.area_for(world, site, last, GameState.party_characters()), "return_scene": "world",
			"gate_cell": [site.cell.x, site.cell.y], "gate_depth": last, "gate_final": true,
			"gate_keeper": GateInside.keeper_flag(site, last),
		})
		await _frames(90)
		await _whole(_active(), look)
	get_tree().quit(0)


## The floor drawn whole: the camera pulled back over all of it.
func _whole(scene: Node, label: String) -> void:
	var map: AreaMap = scene.get("map")
	var camera = scene.get_node("Camera2D")
	var size := Vector2(map.width, map.height) * AreaMap.CELL
	camera.zoom = Vector2.ONE * minf(1600.0 / size.x, 900.0 / size.y) * 0.95
	camera.focus_on(size / 2.0, true)
	await _frames(20)
	await _shoot(label)


func _walk_into(scene: Node, watch: Node2D) -> void:
	var map: AreaMap = scene.get("map")
	var at: Vector2i = map.cell_at(scene._leader.position)
	var cells: Array = watch.watched.keys()
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return (a - at).length_squared() < (b - at).length_squared())
	var camera = scene.get_node("Camera2D")
	camera.zoom = Vector2.ONE
	scene.call("_check_the_watch", at)
	scene._leader.position = map.centre_of(cells[0])
	scene.call("_check_the_watch", cells[0])


func _active() -> Node:
	return get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shoot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://.art_stage/gate_inside_%s.png" % label
	get_viewport().get_texture().get_image().save_png(path)
	print("saved %s" % path)
