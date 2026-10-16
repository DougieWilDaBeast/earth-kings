extends Node
## Root node: owns the active scene and the always-present dialogue overlay.
## Scene changes go through [EventBus] so no scene needs to know about another.

const SaveToast := preload("res://src/ui/save_toast.gd")
const LevelUpBanner := preload("res://src/ui/level_up_banner.gd")
const TutorialGuide := preload("res://src/ui/tutorial_guide.gd")

const SCENES := {
	"title": "res://src/ui/title_screen.tscn",
	"opening": "res://src/ui/opening.tscn",
	"temper_quiz": "res://src/ui/temper_quiz.tscn",
	"character_select": "res://src/ui/character_select.tscn",
	"world": "res://src/world/world_scene.tscn",
	"area": "res://src/area/area_scene.tscn",
	"skirmish": "res://src/skirmish/skirmish.tscn",
	"training": "res://src/training/training_ground.tscn",
	"coliseum": "res://src/coliseum/coliseum.tscn",
	"museum": "res://src/ui/museum.tscn",
	"credits": "res://src/ui/credits_screen.tscn",
	"summary": "res://src/ui/run_summary.tscn",
}

## Where "back" runs out of places to go. Backing out of the title screen is
## leaving the game, which is what the key is for on a phone.
const ROOT_SCENES := ["title"]

@onready var _container: Node = $CurrentScene

var _scene_key: String = "title"
## The continent, run out of sight for the land while it takes a step ([D84]); gone once it
## has answered, or when the screen changes.
var _continent: Node = null


func _ready() -> void:
	EventBus.request_scene.connect(_change_scene)
	EventBus.continent_requested.connect(func(payload: Dictionary) -> void: _run_the_continent.call_deferred(payload))
	# Says so when a save is upgraded or restored from its backup ([D56]).
	add_child(SaveToast.new())
	add_child(LevelUpBanner.new())
	# The tutorial's card outlasts the scenes it guides through (D73).
	var guide := TutorialGuide.new()
	guide.name = "TutorialGuide"
	add_child(guide)
	# A phone has one key on it, and Android hands it over as "go back". Left
	# alone it closes the game from inside any screen, which is no way to shut a
	# menu, so it is caught here and passed on as the cancel it means.
	get_tree().set_quit_on_go_back(false)
	get_tree().root.size_changed.connect(_fit_to_screen)
	_fit_to_screen()
	# Straight onto the title card, the fall ([D87]).
	_change_scene("title", {"from": "boot"})


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


## The screen the game is laid out for, on its short side: a laptop's window is 720 tall. A phone
## is far smaller than that, so on one the game is laid out for [constant SMALLEST_SHORT_SIDE]
## instead, which keeps a line of text big enough to read on it (D162).
const LAID_OUT_SHORT_SIDE := 720
const SMALLEST_SHORT_SIDE := 540
## How many of the game's pixels one of the screen's own points (CSS pixels on a browser) may
## carry before the text on it is too small to read.
const MOST_PER_POINT := 1.32


## Laid out for the screen as it is held, turned either way. Upright, the game is laid out tall
## rather than wide: before this a phone held upright showed a laptop's wide screen shrunk to its
## width, the ground in a band across the middle and the text at five points (five strangers,
## finding 6). Each way round, the short side is the same number of the game's pixels.
func _fit_to_screen() -> void:
	var window := get_tree().root
	var size := Vector2(window.size)
	if size.x <= 0.0 or size.y <= 0.0:
		return
	# A phone's screen packs two or three of its pixels into each point; what can be read is
	# measured in points.
	var points := minf(size.x, size.y) / maxf(1.0, DisplayServer.screen_get_scale())
	var short := clampi(roundi(points * MOST_PER_POINT), SMALLEST_SHORT_SIDE, LAID_OUT_SHORT_SIDE)
	var long := roundi(short * 16.0 / 9.0)
	var wanted := Vector2i(short, long) if size.y > size.x else Vector2i(long, short)
	if window.content_scale_size != wanted:
		window.content_scale_size = wanted


## Scenes where Start brings up the menu. Everywhere else is a menu already.
const MENU_FROM_SCENES := ["world", "area", "skirmish", "training", "coliseum"]
## Scenes where the pad's journal button opens the journal. In a fight the same
## button is Wait.
const JOURNAL_FROM_SCENES := ["world", "area"]


## The pad's own buttons for things the keyboard reaches some other way: Start
## is the menu (a keyboard has Escape, which is also Back), the journal (N on a
## keyboard) and Back on a screen that only had a button for it. Taken here,
## last, so any scene or overlay that wants the press has had it first.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("open_menu") and MENU_FROM_SCENES.has(_scene_key) \
			and not _something_is_open():
		get_viewport().set_input_as_handled()
		EventBus.system_menu_requested.emit()
	elif event.is_action_pressed("open_journal") and JOURNAL_FROM_SCENES.has(_scene_key) \
			and not _something_is_open():
		get_viewport().set_input_as_handled()
		EventBus.journal_requested.emit()
	elif event.is_action_pressed("ui_cancel") and not _something_is_open():
		# A menu scene whose only way out was a Back button on the screen.
		var back := _container.find_child("BackButton", true, false) as BaseButton
		if back != null and back.is_visible_in_tree() and not back.disabled:
			get_viewport().set_input_as_handled()
			back.pressed.emit()


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


## The continent's scene, with nothing of it on screen, doing what the land asked; it answers on
## [signal EventBus.continent_answered] and goes, or asks for another scene and is swept away.
func _run_the_continent(payload: Dictionary) -> void:
	if is_instance_valid(_continent):
		_continent.queue_free()
	var continent: Node = load(SCENES["world"]).instantiate()
	continent.set("boot_payload", payload)
	_continent = continent
	add_child(continent)


func _swap(scene_key: String, payload: Dictionary) -> void:
	if is_instance_valid(_continent):
		_continent.queue_free()
		_continent = null
	for child in _container.get_children():
		_container.remove_child(child)
		child.queue_free()
	var scene: Node = load(SCENES[scene_key]).instantiate()
	scene.set("boot_payload", payload)
	scene.add_to_group(EventBus.ACTIVE_SCENE_GROUP)
	_container.add_child(scene)
	_scene_key = scene_key
	EventBus.scene_changed.emit(scene_key)
