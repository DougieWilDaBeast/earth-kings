extends Node
## Throwaway: boot a world, walk a little, and photograph the map.

func _ready() -> void:
	await get_tree().process_frame
	GameState.new_game(20260827, "bram")
	var scene: Node = load("res://src/world/world_scene.tscn").instantiate()
	add_child(scene)
	for i in 40:
		await get_tree().process_frame
	var face := Database.unit_face("bram")
	print("face=%s size=%s" % [face, face.get_size() if face else "-"])
	print("bubbles=%d panels=%d" % [
		get_tree().get_nodes_in_group("speech").size(),
		scene.find_children("*", "PanelContainer", true, false).size(),
	])
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	shot.save_png("res://.art_stage/world_shot.png")
	print("saved world_shot.png %dx%d" % [shot.get_width(), shot.get_height()])
	get_tree().quit(0)
