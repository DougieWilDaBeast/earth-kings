extends Node
## Root node: owns the active scene and the always-present dialogue overlay.
## Scene changes go through [EventBus] so no scene needs to know about another.

const SCENES := {
	"cinematic": "res://src/ui/cinematic.tscn",
	"title": "res://src/ui/title_screen.tscn",
	"temper_quiz": "res://src/ui/temper_quiz.tscn",
	"character_select": "res://src/ui/character_select.tscn",
	"world": "res://src/world/world_scene.tscn",
	"area": "res://src/area/area_scene.tscn",
	"battle": "res://src/battle/battle.tscn",
	"training": "res://src/training/training_ground.tscn",
	"coliseum": "res://src/coliseum/coliseum.tscn",
	"museum": "res://src/ui/museum.tscn",
	"summary": "res://src/ui/run_summary.tscn",
}

## Where "back" runs out of places to go. Backing out of the title screen is
## leaving the game, which is what the key is for on a phone.
const ROOT_SCENES := ["title", "cinematic"]

@onready var _container: Node = $CurrentScene

var _scene_key: String = "cinematic"


func _ready() -> void:
	EventBus.request_scene.connect(_change_scene)
	# A phone has one key on it, and Android hands it over as "go back". Left
	# alone it closes the game from inside any screen, which is no way to shut a
	# menu, so it is caught here and passed on as the cancel it means.
	get_tree().set_quit_on_go_back(false)
	_change_scene("cinematic", {})


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back_out()


## Whatever "back" means where the player is standing: the top overlay closes,
## and with nothing open the menu comes up. Everything already answers Escape,
## so back is sent as Escape rather than teaching every screen a second key.
## At the title with nothing open there is nowhere further back, and the key
## does on a phone what it is expected to do.
func back_out() -> void:
	if ROOT_SCENES.has(_scene_key) and not _something_is_open():
		get_tree().quit()
		return
	var press := InputEventAction.new()
	press.action = "ui_cancel"
	press.pressed = true
	press.strength = 1.0
	Input.parse_input_event(press)
	await get_tree().process_frame
	var release := InputEventAction.new()
	release.action = "ui_cancel"
	release.pressed = false
	Input.parse_input_event(release)


func _something_is_open() -> bool:
	for overlay in get_tree().get_nodes_in_group(EventBus.MODAL_OVERLAY_GROUP):
		if overlay.has_method("is_open") and overlay.is_open():
			return true
	return false


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
	_scene_key = scene_key
	EventBus.scene_changed.emit(scene_key)
