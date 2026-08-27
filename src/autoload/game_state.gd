extends Node
## The live game: the world, everyone in it, and the save file (autoload: `GameState`).

const SAVE_PATH := "user://earth-kings.save.json"
const SAVE_VERSION := 2

const DEFAULT_GOLD := 250
const DEFAULT_LOCATION := "hollow_ford"

var world: World
var roster: Roster

var gold: int = DEFAULT_GOLD
var current_location: String = DEFAULT_LOCATION
## Where to fall back to after a lost battle.
var previous_location: String = DEFAULT_LOCATION
var cleared_battles: Array = []
var flags: Dictionary = {}


func _ready() -> void:
	if world == null:
		new_game()


func new_game(world_seed: int = 0) -> void:
	if world_seed == 0:
		world_seed = randi()
	world = WorldGen.generate(world_seed)
	roster = Roster.found()
	gold = DEFAULT_GOLD
	current_location = DEFAULT_LOCATION
	previous_location = DEFAULT_LOCATION
	cleared_battles = []
	flags = {}


# --- the party ----------------------------------------------------------------


func party_characters() -> Array[Character]:
	return roster.fit_to_fight()


func heal_party() -> void:
	roster.rest()


func party_is_wounded() -> bool:
	return roster.is_wounded()


# --- flags and progress -------------------------------------------------------


func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value


func has_flag(key: String) -> bool:
	return flags.get(key, false) == true


func mark_battle_cleared(map_id: String) -> void:
	if map_id not in cleared_battles:
		cleared_battles.append(map_id)


func is_battle_cleared(map_id: String) -> bool:
	return map_id in cleared_battles


# --- persistence --------------------------------------------------------------


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save() -> void:
	var payload := {
		"version": SAVE_VERSION,
		"world": world.to_dict(),
		"roster": roster.to_dict(),
		"gold": gold,
		"current_location": current_location,
		"previous_location": previous_location,
		"cleared_battles": cleared_battles,
		"flags": flags,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameState: could not write save to %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(payload, "\t"))


func load_save() -> bool:
	if not has_save():
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("GameState: corrupt save at %s" % SAVE_PATH)
		return false

	var data: Dictionary = parsed
	if int(data.get("version", 1)) < SAVE_VERSION:
		push_warning("GameState: save predates the world; starting fresh")
		new_game()
		return false

	world = World.from_dict(data.get("world", {}))
	roster = Roster.from_dict(data.get("roster", {}))
	gold = int(data.get("gold", DEFAULT_GOLD))
	current_location = data.get("current_location", DEFAULT_LOCATION)
	previous_location = data.get("previous_location", DEFAULT_LOCATION)
	cleared_battles = data.get("cleared_battles", [])
	flags = data.get("flags", {})
	return true
