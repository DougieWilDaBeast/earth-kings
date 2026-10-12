extends Node
## How fast the game is running and whether it is playing itself (autoload: `Pace`).
##
## Both survive scene swaps, so a soak started on the road carries through the
## fight it walks into and comes out the other side still running. Speed is
## [member Engine.time_scale], so anything driven by delta follows it for free.

signal changed

const SPEEDS := [1.0, 1.5, 2.0]
const SETTINGS_PATH := "user://settings.cfg"

## The game is playing itself: the AI takes the party's turns, the party walks
## itself across the map, and conversations answer themselves.
var auto: bool = false:
	set(value):
		if auto == value:
			return
		auto = value
		changed.emit()

var _step: int = 0

## Keep unwritten talk — banter, road chatter, what your own say at the fire —
## out of the dialogue box. It still happens and is still logged and bubbled;
## it just stops taking the screen. Authored conversations are never affected.
var quiet_banter: bool = false:
	set(value):
		if quiet_banter == value:
			return
		quiet_banter = value
		_save()
		changed.emit()

## Ground a soak has already thrown itself at. Without it, a fight lost at a
## gate is walked straight back into, for ever.
var avoided: Dictionary = {}

## Touch controls mode: "auto" (detects touch/mobile), "on" (force enabled), "off" (force disabled).
var touch_mode: String = "auto":
	set(value):
		if touch_mode == value:
			return
		touch_mode = value
		_save()
		changed.emit()


## The window fills the screen. Set from the system menu or the fullscreen key;
## the browser build only goes fullscreen from a click, so there it is never
## put back on at boot.
var fullscreen: bool = false:
	set(value):
		fullscreen = value
		_apply_fullscreen()
		_save()
		changed.emit()


func toggle_fullscreen() -> void:
	fullscreen = not _showing_fullscreen()


## What the window is really doing: the browser and the OS can take it out of
## fullscreen behind the game's back.
func _showing_fullscreen() -> bool:
	if DisplayServer.get_name() == "headless":
		return fullscreen
	return DisplayServer.window_get_mode() in [
		DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	]


func _apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless" or _showing_fullscreen() == fullscreen:
		return
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)


func is_touch_enabled() -> bool:
	match touch_mode:
		"on":
			return true
		"off":
			return false
		_:
			return OS.has_feature("android") or OS.has_feature("mobile") \
					or DisplayServer.is_touchscreen_available()


func cycle_touch_mode() -> void:
	match touch_mode:
		"auto":
			touch_mode = "on"
		"on":
			touch_mode = "off"
		_:
			touch_mode = "auto"


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		quiet_banter = bool(config.get_value("ui", "quiet_banter", false))
		touch_mode = str(config.get_value("ui", "touch_mode", "auto"))
		if not OS.has_feature("web") and bool(config.get_value("display", "fullscreen", false)):
			fullscreen = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		get_viewport().set_input_as_handled()
		toggle_fullscreen()


func _save() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("ui", "quiet_banter", quiet_banter)
	config.set_value("ui", "touch_mode", touch_mode)
	config.set_value("display", "fullscreen", fullscreen)
	config.save(SETTINGS_PATH)


func speed() -> float:
	return SPEEDS[_step]


func cycle_speed() -> void:
	_step = (_step + 1) % SPEEDS.size()
	Engine.time_scale = speed()
	changed.emit()


## Back to walking pace and hands on the controls, for leaving a run.
func reset() -> void:
	_step = 0
	Engine.time_scale = 1.0
	auto = false
	avoided.clear()