extends Node
## Mutable run state: the party, progress flags, where you are (autoload: `GameState`).

const SAVE_PATH := "user://earth-kings.save.json"

const DEFAULT_PARTY := ["bram", "sera", "toln"]
const DEFAULT_GOLD := 250
const DEFAULT_LOCATION := "hollow_ford"

## Unit template ids from `data/units.json` that make up the player's party.
var party: Array = DEFAULT_PARTY.duplicate()
var gold: int = DEFAULT_GOLD
var current_location: String = DEFAULT_LOCATION
## Where to fall back to after a lost battle.
var previous_location: String = DEFAULT_LOCATION
var cleared_battles: Array = []
var flags: Dictionary = {}
## Wounds carried between battles: party template id -> hp. Absent means full.
var party_hp: Dictionary = {}


func new_game() -> void:
	party = DEFAULT_PARTY.duplicate()
	gold = DEFAULT_GOLD
	current_location = DEFAULT_LOCATION
	previous_location = DEFAULT_LOCATION
	cleared_battles = []
	flags = {}
	party_hp = {}


## Remaining HP for a party member, or -1 when they are untracked (full health).
func hp_for(template_id: String) -> int:
	return int(party_hp.get(template_id, -1))


func set_hp(template_id: String, hp: int) -> void:
	party_hp[template_id] = hp


func heal_party() -> void:
	party_hp.clear()


func party_is_wounded() -> bool:
	return not party_hp.is_empty()


func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value


func has_flag(key: String) -> bool:
	return flags.get(key, false) == true


func mark_battle_cleared(map_id: String) -> void:
	if map_id not in cleared_battles:
		cleared_battles.append(map_id)


func is_battle_cleared(map_id: String) -> bool:
	return map_id in cleared_battles


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save() -> void:
	var payload := {
		"party": party,
		"gold": gold,
		"current_location": current_location,
		"previous_location": previous_location,
		"cleared_battles": cleared_battles,
		"flags": flags,
		"party_hp": party_hp,
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
	party_hp = _to_int_values(data.get("party_hp", {}))
	return true


# JSON has no integers, so HP comes back as floats.
func _to_int_values(raw: Dictionary) -> Dictionary:
	var out := {}
	for key: String in raw:
		out[key] = int(raw[key])
	return out
