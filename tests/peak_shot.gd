extends Node
## Photograph the cloud peak ([D287], [D321]): the three heights and the clouds below the summit, and
## a fight at the top with a foe shoved over the edge. Needs a display (xvfb-run).
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/peak_shot.tscn
##
## Shots land in .art_stage/peak_*.png.

const Fighter := preload("res://src/skirmish/fighter.gd")

var _game: Node


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	_game = load("res://src/main.tscn").instantiate()
	add_child(_game)
	await _frames(30)
	GameState.new_game(20260829, "atlas")
	GameState.set_flag("seen:prologue")
	GameState.world.prowlers.clear()
	EventBus.request_scene.emit("area", { "area_id": "wild_peak", "return_scene": "world" })
	await _frames(20)
	var ground := _active()
	ground.get_node("Camera2D").focus_on(ground.map.centre_of(Vector2i(15, 6)), true)
	await _frames(6)
	await _shoot("whole")
	await _frames(60)
	var fight_first: Node = ground.get("_fight")
	if fight_first != null:
		print("a fight opened on the way in")
	var camera = ground.get_node("Camera2D")
	ground._leader.position = ground.map.centre_of(Vector2i(15, 7))
	camera.focus_on(ground.map.centre_of(Vector2i(15, 8)), true)
	await _frames(30)
	await _shoot("heights")
	ground._leader.position = ground.map.centre_of(Vector2i(19, 3))
	camera.focus_on(ground.map.centre_of(Vector2i(17, 3)), true)
	await _frames(30)
	await _shoot("summit")
	var watches: Array = ground.get("_watches")
	print("bands on the peak: %d" % watches.size())
	var fight: Node = ground.get("_fight")
	if fight == null and not watches.is_empty():
		ground.call("_fight_here", watches[0])
		await get_tree().create_timer(1.0).timeout
		fight = ground.get("_fight")
	if true:
		print("fight on: %s, clouds in it: %d" % [fight != null, (fight.grid.clouds as Dictionary).size() if fight != null else 0])
		if fight != null:
			fight.paused = true
			await _shoot("fight")
			var party: Array = fight.fighters.filter(func(f: Fighter) -> bool: return f.is_party())
			var foes: Array = fight.fighters.filter(func(f: Fighter) -> bool: return not f.is_party())
			var edge := Vector2i(-1, -1)
			for cell: Vector2i in fight.grid.clouds:
				var inner: Vector2i = cell + Vector2i.LEFT
				var outer: Vector2i = inner + Vector2i.LEFT
				if fight.grid.is_walkable(inner) and fight.grid.is_walkable(outer) and fight.occupant(inner) == null and fight.occupant(outer) == null:
					edge = inner
					break
			if edge.x >= 0 and not party.is_empty() and not foes.is_empty():
				var foe: Fighter = foes[0]
				var who: Fighter = party[0]
				foe.unit.cell = edge
				foe.unit.position = fight.grid.cell_to_world(edge)
				who.unit.cell = edge + Vector2i.LEFT
				who.unit.position = fight.grid.cell_to_world(edge + Vector2i.LEFT)
				fight.conditions.shove(who, foe, "knockback", 2)
				fight.paused = false
				await get_tree().create_timer(0.3).timeout
				await _shoot("over")
				print("shoved at %s: fallen %s, alive %s" % [edge, foe.fallen, foe.unit.is_alive()])
	get_tree().quit(0)


func _active() -> Node:
	return get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shoot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://.art_stage/peak_%s.png" % label
	get_viewport().get_texture().get_image().save_png(path)
	print("saved %s" % path)
