extends Node
## How fast the game is running and whether it is playing itself (autoload: `Pace`).
##
## Both survive scene swaps, so a soak started on the road carries through the
## fight it walks into and comes out the other side still running. Speed is
## [member Engine.time_scale], so anything driven by delta follows it for free.

signal changed

const SPEEDS := [1.0, 2.0, 4.0]
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


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		quiet_banter = bool(config.get_value("ui", "quiet_banter", false))


func _save() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("ui", "quiet_banter", quiet_banter)
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