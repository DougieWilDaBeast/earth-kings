extends Node
## Static game content loaded from `res://data` (autoload: `Database`).
##
## Content is plain JSON so it can be edited without opening the editor and
## diffs stay readable in git. Everything here is read-only at runtime.

const DATA_DIR := "res://data"

var terrain: Dictionary = {}
var units: Dictionary = {}
var abilities: Dictionary = {}
var equipment: Dictionary = {}
var classes: Dictionary = {}
var doctrines: Dictionary = {}
var fate: Dictionary = {}
var encounters: Dictionary = {}
var errands: Dictionary = {}
var trivia: Dictionary = {}
var grimoires: Dictionary = {}
var memorials: Dictionary = {}
var world_rules: Dictionary = {}
## Leads a run can be started as, in the order they are offered.
var heroes: Dictionary = {}
## Terrain names and the tileset sheets that draw them (see [TileForge]).
var tilesets: Dictionary = {}
## Staged beats played before a conversation (see [AreaCutscene]).
var cutscenes: Dictionary = {}
## What the party say to each other on the road (see [Banter]).
var banter: Dictionary = {}
## Long-running story that ignites off world state (see [Skein]).
var threads: Dictionary = {}
## Scenes you come upon on the open road (see [Roadside]).
var roadside: Dictionary = {}
## Waves, cards and purses for the coliseum (see [Arena]).
var coliseum: Dictionary = {}
## Who holds what, and who you meet where (see [Faction]).
var factions: Dictionary = {}
## Which scene hears which tracks (see [Music]).
var music: Dictionary = {}

## Abilities invented at runtime by [AbilityGrammar]; restored from the save.
var _generated_abilities: Dictionary = {}
var _maps: Dictionary = {}
var _dialogues: Dictionary = {}
var _areas: Dictionary = {}
var _faces: Dictionary = {}
var _runs: Dictionary = {}


func _ready() -> void:
	terrain = _load_json("%s/terrain.json" % DATA_DIR)
	units = _load_json("%s/units.json" % DATA_DIR)
	abilities = _load_json("%s/abilities.json" % DATA_DIR)
	equipment = _load_json("%s/equipment.json" % DATA_DIR)
	classes = _load_json("%s/classes.json" % DATA_DIR)
	doctrines = _load_json("%s/doctrine.json" % DATA_DIR)
	fate = _load_json("%s/fate.json" % DATA_DIR)
	encounters = _load_json("%s/encounters.json" % DATA_DIR)
	errands = _load_json("%s/errands.json" % DATA_DIR)
	trivia = _load_json("%s/trivia.json" % DATA_DIR)
	grimoires = _load_json("%s/grimoires.json" % DATA_DIR)
	memorials = _load_json("%s/memorials.json" % DATA_DIR)
	world_rules = _load_json("%s/world_rules.json" % DATA_DIR)
	heroes = _load_json("%s/heroes.json" % DATA_DIR)
	tilesets = _load_json("%s/tilesets.json" % DATA_DIR)
	cutscenes = _load_json("%s/cutscenes.json" % DATA_DIR)
	banter = _load_json("%s/banter.json" % DATA_DIR)
	threads = _load_json("%s/threads.json" % DATA_DIR)
	roadside = _load_json("%s/roadside.json" % DATA_DIR)
	coliseum = _load_json("%s/coliseum.json" % DATA_DIR)
	factions = _load_json("%s/factions.json" % DATA_DIR)
	music = _load_json("%s/music.json" % DATA_DIR)


func terrain_type(id: String) -> Dictionary:
	return terrain.get(id, terrain.get("grass", {}))


func unit_template(id: String) -> Dictionary:
	return units.get(id, {})


## The forward-facing sprite a unit is drawn with, or null when it has no art.
## Cached, because a texture loaded part-way through a draw pass comes out white.
func unit_face(id: String) -> Texture2D:
	if _faces.has(id):
		return _faces[id]
	var sprite_dir: String = unit_template(id).get("sprite_dir", "")
	var path := "%s/south.png" % sprite_dir
	_faces[id] = load(path) if sprite_dir != "" and ResourceLoader.exists(path) else null
	return _faces[id]


## A unit's run cycle for one heading ("north" | "south" | "east" | "west"), or
## an empty array for the many units that only have a standing pose. Frames live
## at `art/units/<id>/run/<heading>/frame_000.png` and are numbered from zero.
func unit_run(id: String, heading: String) -> Array:
	var key := "%s/%s" % [id, heading]
	if _runs.has(key):
		return _runs[key]
	var frames: Array = []
	var sprite_dir: String = unit_template(id).get("sprite_dir", "")
	if sprite_dir != "":
		var folder := "%s/run/%s" % [sprite_dir.get_base_dir(), heading]
		while true:
			var path := "%s/frame_%03d.png" % [folder, frames.size()]
			if not ResourceLoader.exists(path):
				break
			frames.append(load(path))
	_runs[key] = frames
	return frames


## A lead a run can be started as (see `data/heroes.json`).
func hero(id: String) -> Dictionary:
	return heroes.get(id, {})


func ability(id: String) -> Dictionary:
	if abilities.has(id):
		return abilities[id]
	return _generated_abilities.get(id, {})


## Make a generated ability castable for the rest of the session.
func register_ability(id: String, definition: Dictionary) -> void:
	_generated_abilities[id] = definition


## Put a conversation built at runtime where [DialogueScript] can find it.
func register_dialogue(id: String, payload: Dictionary) -> void:
	_dialogues[id] = payload


func character_class(id: String) -> Dictionary:
	return classes.get(id, {})


func doctrine(id: String) -> Dictionary:
	return doctrines.get(id, {})


func doctrine_ids() -> Array:
	return doctrines.keys()


func equipment_piece(id: String) -> Dictionary:
	return equipment.get(id, {})


func map(id: String) -> Dictionary:
	if not _maps.has(id):
		_maps[id] = _load_json("%s/maps/%s.json" % [DATA_DIR, id])
	return _maps[id]


## The raw conversation file: either a flat `lines` array or branching `nodes`
## (see [DialogueScript]).
func dialogue(id: String) -> Dictionary:
	if id == "":
		return {}
	if not _dialogues.has(id):
		_dialogues[id] = _load_json("%s/dialogue/%s.json" % [DATA_DIR, id])
	return _dialogues[id]


## A walkable place drawn from tilesets (see [AreaMap]).
func area(id: String) -> Dictionary:
	if not _areas.has(id):
		_areas[id] = _load_json(_area_path(id))
	return _areas[id]


func has_area(id: String) -> bool:
	return id != "" and FileAccess.file_exists(_area_path(id))


func tileset_sheet(id: String) -> Dictionary:
	return tilesets.get("sheets", {}).get(id, {})


func area_terrain(id: String) -> Dictionary:
	return tilesets.get("terrains", {}).get(id, {})


func cutscene(id: String) -> Array:
	return cutscenes.get(id, {}).get("beats", [])


func _area_path(id: String) -> String:
	return "%s/areas/%s.json" % [DATA_DIR, id]


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
