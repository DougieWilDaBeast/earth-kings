extends Node
## Static game content loaded from `res://data` (autoload: `Database`).
##
## Content is plain JSON so it can be edited without opening the editor and
## diffs stay readable in git. Everything here is read-only at runtime.

const DATA_DIR := "res://data"

## The five authored history pools, loaded from `res://data/lore/<pool>.json`.
## Every one of them shares a schema, a casting mechanism and one validator.
const LORE_POOLS := ["backgrounds", "grudges", "hearths", "creeds", "oaths"]

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
## Regional personal names, strong forms and their stems (D39, see `src/chronicle/names.gd`).
var names: Dictionary = {}
## Leads a run can be started as, in the order they are offered.
var heroes: Dictionary = {}
## The original twelve, met in the world as story people rather than played (D79).
var story_npcs: Dictionary = {}
## The sixteen tempers: axes, the quiz asked before a run, and the lean each
## letter carries (see docs/13-heroes-and-tempers.md).
var tempers: Dictionary = {}
## Authored history, cast onto characters late (see docs/14-lore-pools.md).
## Pool name -> id -> entry. Pools: backgrounds, grudges, hearths, creeds, oaths.
var lore: Dictionary = {}
## Which piece of which pool is marked for, and cast on, which character.
var casting: Dictionary = {}
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
## What each moment in a fight sounds like (`data/sfx.json`, [D76]).
var sfx: Dictionary = {}
## Gate contracts and the hall's words (see `src/chronicle/guild.gd`).
var guild: Dictionary = {}
## Passives, enemy roles and feel for the real-time skirmish (see `src/skirmish/`).
var skirmish: Dictionary = {}
## The lands of the continent and how each one's ground is laid out (`biomes.json`).
var biomes: Dictionary = {}
## The fall: crash sites, the landing, the standing quest, and the others living
## their own lives (see `src/chronicle/fall.gd`, `src/chronicle/wanderers.gd`).
var fall: Dictionary = {}
## The opening cinematic after New Game: its cast and narration (see `src/ui/opening.gd`).
var opening: Dictionary = {}
## How big each prop picture is drawn and whether it stands in the way (`data/props.json`).
var props: Dictionary = {}

## Abilities invented at runtime by [AbilityGrammar]; restored from the save.
var _generated_abilities: Dictionary = {}
var _maps: Dictionary = {}
var _dialogues: Dictionary = {}
var _areas: Dictionary = {}
var _faces: Dictionary = {}
var _runs: Dictionary = {}


func _ready() -> void:
	terrain = _load_json("%s/terrain.json" % DATA_DIR)
	biomes = _load_json("%s/biomes.json" % DATA_DIR)
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
	names = _load_json("%s/names.json" % DATA_DIR)
	heroes = _load_json("%s/heroes.json" % DATA_DIR)
	story_npcs = _load_json("%s/story_npcs.json" % DATA_DIR)
	story_npcs.erase("_about")
	tempers = _load_json("%s/tempers.json" % DATA_DIR)
	casting = _load_json("%s/casting.json" % DATA_DIR)
	for pool: String in LORE_POOLS:
		lore[pool] = _load_json("%s/lore/%s.json" % [DATA_DIR, pool])
	tilesets = _load_json("%s/tilesets.json" % DATA_DIR)
	cutscenes = _load_json("%s/cutscenes.json" % DATA_DIR)
	banter = _load_json("%s/banter.json" % DATA_DIR)
	threads = _load_json("%s/threads.json" % DATA_DIR)
	roadside = _load_json("%s/roadside.json" % DATA_DIR)
	coliseum = _load_json("%s/coliseum.json" % DATA_DIR)
	factions = _load_json("%s/factions.json" % DATA_DIR)
	music = _load_json("%s/music.json" % DATA_DIR)
	sfx = _load_json("%s/sfx.json" % DATA_DIR)
	guild = _load_json("%s/guild.json" % DATA_DIR)
	skirmish = _load_json("%s/skirmish.json" % DATA_DIR)
	fall = _load_json("%s/fall.json" % DATA_DIR)
	opening = _load_json("%s/opening.json" % DATA_DIR)
	props = _load_json("%s/props.json" % DATA_DIR)


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
## at `art/units/<id>/run/<heading>/frame_000.png` and are numbered from zero;
## a unit with a `walk` cycle but no `run` uses its walk.
func unit_run(id: String, heading: String) -> Array:
	var frames := unit_frames(id, "run", heading)
	return frames if not frames.is_empty() else unit_frames(id, "walk", heading)


## One of a unit's moves ("run", "walk", "attack", "skill", "hit", "death") for
## one heading, as numbered frames in a folder beside its `sprite_dir`:
## `<sprite_dir>/../<state>/<heading>/frame_000.png`. Empty when it has none.
func unit_frames(id: String, state: String, heading: String) -> Array:
	var key := "%s/%s/%s" % [id, state, heading]
	if _runs.has(key):
		return _runs[key]
	var frames: Array = []
	var sprite_dir: String = unit_template(id).get("sprite_dir", "")
	if sprite_dir != "":
		var folder := "%s/%s/%s" % [sprite_dir.get_base_dir(), state, heading]
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


## One of the original twelve, as a story person: where they stand and the hook their story picks
## up from (see `data/story_npcs.json`).
func story_npc(id: String) -> Dictionary:
	return story_npcs.get(id, {})


## One of the sixteen tempers, by four-letter code.
func temper(code: String) -> Dictionary:
	return temper_types().get(code.to_upper(), {})


func temper_types() -> Dictionary:
	return tempers.get("types", {})


## The hero a temper resolves to, or "" while that slot is still unwritten.
func temper_hero(code: String) -> String:
	return str(temper(code).get("hero", ""))


## The temper a hero is written for, or "" if no slot names them yet.
func hero_temper(hero_id: String) -> String:
	if hero_id == "":
		return ""
	for code: String in temper_types():
		if str(temper_types()[code].get("hero", "")) == hero_id:
			return code
	return ""


## What one letter of a temper nudges. Codes carry four letters, so a character
## sums four leans; anything a letter is silent about falls back.
func temper_lean(code: String, key: String, fallback: float) -> float:
	var leans: Dictionary = tempers.get("leans", {})
	for i in mini(code.length(), 4):
		var letter := code[i].to_upper()
		var lean: Dictionary = leans.get(letter, {})
		if lean.has(key):
			return float(lean[key])
	return fallback


## An authored piece of history: pool is one of [constant LORE_POOLS].
func lore_piece(pool: String, id: String) -> Dictionary:
	return lore.get(pool, {}).get(id, {})


## Every real entry in a pool, skipping the `_doc`/`_schema` notes the files
## carry for whoever opens them next.
func lore_pool(pool: String) -> Dictionary:
	var out: Dictionary = {}
	for id: String in lore.get(pool, {}):
		if id.begins_with("_"):
			continue
		out[id] = lore[pool][id]
	return out


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


## The class that is one lead's own (its `lead`), or "" if they have none.
func own_class(lead_id: String) -> String:
	for id: String in classes:
		if str(classes[id].get("lead", "")) == lead_id:
			return id
	return ""


## Classes anyone can learn: every class that is not one lead's own.
func open_classes() -> Array:
	return classes.keys().filter(func(id: String) -> bool: return str(classes[id].get("lead", "")) == "")


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
	return id != "" and (_areas.has(id) and not _areas[id].is_empty() or FileAccess.file_exists(_area_path(id)))


## An area made rather than written: the generated ground of one tile of the
## continent (see [GroundGen]). Kept for the session; it is made the same way
## from the same seed, so it never needs saving.
func register_area(id: String, payload: Dictionary) -> void:
	_areas[id] = payload


func biome(id: String) -> Dictionary:
	return biomes.get("biomes", {}).get(id, {})


func tileset_sheet(id: String) -> Dictionary:
	return tilesets.get("sheets", {}).get(id, {})


func area_terrain(id: String) -> Dictionary:
	return tilesets.get("terrains", {}).get(id, {})


## How a prop picture stands in a place: `scale`, `solid`, `battle_scale` and its `kind`, from
## `data/props.json` (its kind's numbers, then its own). Unknown art is drawn as it is, and
## stands in nobody's way.
func prop_size(art_id: String) -> Dictionary:
	var out := { "scale": 1.0, "solid": false, "battle_scale": 0.0, "kind": "" }
	var entry: Variant = props.get("art", {}).get(art_id, {})
	if entry is String:
		entry = { "kind": entry }
	var kind := str((entry as Dictionary).get("kind", ""))
	out["kind"] = kind
	out.merge(props.get("kinds", {}).get(kind, {}), true)
	out.merge(entry as Dictionary, true)
	if float(out["battle_scale"]) <= 0.0:
		out["battle_scale"] = out["scale"]
	return out


## How a building picture stands in an area (`data/props.json` → `buildings`), or {} for a
## building with no picture of its own.
func building_art(art_id: String) -> Dictionary:
	var entry: Variant = props.get("buildings", {}).get(art_id, {})
	return entry if entry is Dictionary else {}


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
