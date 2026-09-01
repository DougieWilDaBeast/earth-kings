extends Node
## Throwaway: photograph the opening cinematic part-way through its pass.

func _ready() -> void:
	await get_tree().process_frame
	for kind: String in Site.ART:
		var path: String = Site.ART[kind]
		var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
		print("%s -> %s %s" % [kind, path, texture.get_size() if texture != null else "MISSING"])
	var scene: Node = load("res://src/ui/cinematic.tscn").instantiate()
	add_child(scene)
	for i in 330:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.art_stage/cinematic_shot.png")
	print("saved")
	get_tree().quit(0)
