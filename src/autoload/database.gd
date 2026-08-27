extends Node
## Static game content loaded from `res://data` (autoload: `Database`).
##
## Content is plain JSON so it can be edited without opening the editor and
## diffs stay readable in git. Everything here is read-only at runtime.

const DATA_DIR := "res://data"

var terrain: Dictionary = {}
var units: Dictionary = {}
var abilities: Dictionary = {}
var overworld: Dictionary = {}

var _maps: Dictionary = {}
var _dialogues: Dictionary = {}


func _ready() -> void:
	terrain = _load_json("%s/terrain.json" % DATA_DIR)
	units = _load_json("%s/units.json" % DATA_DIR)
	abilities = _load_json("%s/abilities.json" % DATA_DIR)
	overworld = _load_json("%s/overworld.json" % DATA_DIR)


func terrain_type(id: String) -> Dictionary:
	return terrain.get(id, terrain.get("grass", {}))


func unit_template(id: String) -> Dictionary:
	return units.get(id, {})


func ability(id: String) -> Dictionary:
	return abilities.get(id, {})


func map(id: String) -> Dictionary:
	if not _maps.has(id):
		_maps[id] = _load_json("%s/maps/%s.json" % [DATA_DIR, id])
	return _maps[id]


func dialogue(id: String) -> Array:
	if not _dialogues.has(id):
		var data: Dictionary = _load_json("%s/dialogue/%s.json" % [DATA_DIR, id])
		_dialogues[id] = data.get("lines", [])
	return _dialogues[id]


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Database: missing data file %s" % path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Database: %s is not a JSON object" % path)
		return {}
	return parsed
