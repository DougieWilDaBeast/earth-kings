extends Node
## How fast the game is running and whether it is playing itself (autoload: `Pace`).
##
## Both survive scene swaps, so a soak started on the road carries through the
## fight it walks into and comes out the other side still running. Speed is
## [member Engine.time_scale], so anything driven by delta follows it for free.

signal changed

## 1×, 2×, 3× and 5× ([D189], `doug-md`, play-test 4; was 1×, 1.5×, 2×, D59).
const SPEEDS := [1.0, 2.0, 3.0, 5.0]
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
## The walking speed a fight eased down from, or -1 ([method ease_to]).
var _eased_from: int = -1

## How a party walking itself meets bands ([D216], `doug-md`): "aggressive" turns aside for any band
## near and walks into its red; "mixed" keeps to its way and fights what sees it; "passive" walks
## round red ground where it can. Names and blurbs are `auto_styles` in `data/world_rules.json`.
const AUTO_STYLES := ["aggressive", "mixed", "passive"]
var auto_style: String = "mixed":
	set(value):
		if not AUTO_STYLES.has(value) or auto_style == value:
			return
		auto_style = value
		_save()
		changed.emit()


## The next of the three ways a party walking itself meets bands.
func cycle_auto_style() -> void:
	auto_style = AUTO_STYLES[(AUTO_STYLES.find(auto_style) + 1) % AUTO_STYLES.size()]


## What the style is called ("Aggressive"), from the data.
func auto_style_name(style: String = "") -> String:
	var key := style if style != "" else auto_style
	return str(Database.world_rules.get("auto_styles", {}).get("names", {}).get(key, key.capitalize()))


## A line on what the style does, from the data.
func auto_style_blurb(style: String = "") -> String:
	var key := style if style != "" else auto_style
	return str(Database.world_rules.get("auto_styles", {}).get("blurbs", {}).get(key, ""))

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
		auto_style = str(config.get_value("ui", "auto_style", "mixed"))
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
	config.set_value("ui", "auto_style", auto_style)
	config.set_value("display", "fullscreen", fullscreen)
	config.save(SETTINGS_PATH)


func speed() -> float:
	return SPEEDS[_step]


func cycle_speed() -> void:
	_step = (_step + 1) % SPEEDS.size()
	_eased_from = -1
	Engine.time_scale = speed()
	changed.emit()


## A fight played by hand starts no faster than [param most] ([D329], Ewan's play-test 8: a
## company walked at 5x into four wolves and was gone before he could answer); the walking speed
## comes back with [method ease_back], unless the player has picked another speed meanwhile.
func ease_to(most: float) -> void:
	if speed() <= most:
		return
	var to := 0
	for i in SPEEDS.size():
		if float(SPEEDS[i]) <= most:
			to = i
	_eased_from = _step
	_step = to
	Engine.time_scale = speed()
	changed.emit()


func ease_back() -> void:
	if _eased_from < 0:
		return
	_step = _eased_from
	_eased_from = -1
	Engine.time_scale = speed()
	changed.emit()


## Back to walking pace and hands on the controls, for leaving a run.
func reset() -> void:
	_step = 0
	_eased_from = -1
	Engine.time_scale = 1.0
	auto = false
	avoided.clear()