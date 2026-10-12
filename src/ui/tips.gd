extends RefCounted
## First-time tips: what there is to say (`data/tips.json`), which the player has
## already been told, and whether they want telling at all.
##
## Remembered per player in `settings.cfg`, section "tips", not in the save: a
## second run does not need teaching to walk again. Other settings share the
## file, so every write loads it fresh and touches only this section.
##
## Loaded by path, not by `class_name` ([D41]).

const SaveFile := preload("res://src/chronicle/save_file.gd")

const SETTINGS_PATH := "user://settings.cfg"
const DATA_PATH := "res://data/tips.json"
const SECTION := "tips"

static var _data: Dictionary = {}
static var _loaded := false
static var _enabled := true
static var _seen: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = SaveFile.read(DATA_PATH)
		_data = parsed if typeof(parsed) == TYPE_DICTIONARY else {"tips": []}
	return _data


static func all() -> Array:
	return data().get("tips", [])


static func rule(key: String, fallback: Variant) -> Variant:
	return data().get(key, fallback)


## The tip owed for [param moment], or an empty dictionary when there is none,
## it has been shown before, or tips are off.
static func due(moment: String) -> Dictionary:
	_load()
	if not _enabled:
		return {}
	for tip: Dictionary in all():
		if str(tip.get("when", "")) == moment and not _seen.has(str(tip.get("id", ""))):
			return tip
	return {}


static func enabled() -> bool:
	_load()
	return _enabled


static func set_enabled(on: bool) -> void:
	_load()
	_enabled = on
	_write()


static func seen(id: String) -> bool:
	_load()
	return _seen.has(id)


static func mark_seen(id: String) -> void:
	_load()
	if _seen.has(id):
		return
	_seen[id] = true
	_write()


## Every tip owed again, from the start.
static func reset() -> void:
	_load()
	_seen.clear()
	_write()


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	_enabled = bool(config.get_value(SECTION, "enabled", true))
	for id: Variant in config.get_value(SECTION, "seen", []):
		_seen[str(id)] = true


static func _write() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SECTION, "enabled", _enabled)
	config.set_value(SECTION, "seen", PackedStringArray(_seen.keys()))
	config.save(SETTINGS_PATH)
