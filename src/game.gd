extends Node
## Root node: owns the active scene and the always-present dialogue overlay.
## Scene changes go through [EventBus] so no scene needs to know about another.

const SCENES := {
	"cinematic": "res://src/ui/cinematic.tscn",
	"title": "res://src/ui/title_screen.tscn",
	"character_select": "res://src/ui/character_select.tscn",
	"world": "res://src/world/world_scene.tscn",
	"area": "res://src/area/area_scene.tscn",
	"battle": "res://src/battle/battle.tscn",
	"training": "res://src/training/training_ground.tscn",
	"coliseum": "res://src/coliseum/coliseum.tscn",
	"museum": "res://src/ui/museum.tscn",
	"summary": "res://src/ui/run_summary.tscn",
}

@onready var _container: Node = $CurrentScene


func _ready() -> void:
	EventBus.request_scene.connect(_change_scene)
	_change_scene("cinematic", {})


func _change_scene(scene_key: String, payload: Dictionary) -> void:
	if not SCENES.has(scene_key):
		push_error("Game: unknown scene key '%s'" % scene_key)
		return
	Music.for_scene(scene_key)
	# Deferred so a scene can request its own replacement mid-callback.
	_swap.call_deferred(scene_key, payload)


func _swap(scene_key: String, payload: Dictionary) -> void:
	for child in _container.get_children():
		_container.remove_child(child)
		child.queue_free()
	var scene: Node = load(SCENES[scene_key]).instantiate()
	scene.set("boot_payload", payload)
	_container.add_child(scene)
