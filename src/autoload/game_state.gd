extends Node
## Mutable run state: the party, progress flags, where you are (autoload: `GameState`).

const SAVE_PATH := "user://earth-kings.save.json"

## Unit template ids from `data/units.json` that make up the player's party.
var party: Array = ["bram", "sera", "toln"]
var gold: int = 250
var current_location: String = "hollow_ford"
## Where to fall back to after a lost battle.
var previous_location: String = "hollow_ford"
var cleared_battles: Array = []
var flags: Dictionary = {}


func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value


func has_flag(key: String) -> bool:
	return flags.get(key, false) == true


func mark_battle_cleared(map_id: String) -> void:
	if map_id not in cleared_battles:
		cleared_battles.append(map_id)


func is_battle_cleared(map_id: String) -> bool:
	return map_id in cleared_battles


func save() -> void:
	var payload := {
		"party": party,
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
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("GameState: corrupt save at %s" % SAVE_PATH)
		return false
	var data: Dictionary = parsed
	party = data.get("party", party)
	gold = int(data.get("gold", gold))
	current_location = data.get("current_location", current_location)
	previous_location = data.get("previous_location", previous_location)
	cleared_battles = data.get("cleared_battles", cleared_battles)
	flags = data.get("flags", flags)
	return true
