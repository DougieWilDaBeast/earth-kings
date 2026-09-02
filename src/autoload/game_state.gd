extends Node
## The live game: the world, everyone in it, and the save file (autoload: `GameState`).

const SAVE_PATH := "user://earth-kings.save.json"
const SAVE_VERSION := 2

const DEFAULT_GOLD := 250

var world: World
var roster: Roster

## Everything the run summary is retold from (see [Ledger]).
var ledger: Dictionary = Ledger.fresh()
## Cleared while the training sandbox borrows the purse, so play money never
## reaches the ledger.
var tallying: bool = true

var gold: int = DEFAULT_GOLD:
	set(value):
		var delta := value - gold
		gold = value
		if tallying:
			Ledger.add(ledger, "gold_earned" if delta > 0 else "gold_spent", absi(delta))
var cleared_battles: Array = []
var flags: Dictionary = {}
## Conversation id -> how many times it has been played, so somebody you have
## already met does not greet you as a stranger.
var talks: Dictionary = {}
## Errands taken and not yet settled (see [Errand]).
var errands: Array = []
## Equipment the party is carrying and nobody is wearing (see [Loot], [Gear]).
var stores: Array = []
## What the fight being walked into will settle on the way back, if it is won.
## Deliberately not saved: a battle abandoned mid-fight is simply never settled.
var pending_outcome: Dictionary = {}
## Live coliseum state (see [Arena]). Never saved — the sand is not the run.
var arena: Dictionary = {}
## How hard the country is (see [Difficulty]).
var difficulty: String = Difficulty.DEFAULT


func _ready() -> void:
	EventBus.unit_died.connect(_on_unit_died)
	EventBus.unit_damaged.connect(_on_unit_damaged)
	EventBus.battle_finished.connect(_on_battle_finished)
	if world == null:
		new_game()


func _on_unit_damaged(unit: Node, amount: int) -> void:
	if tallying:
		Ledger.add(ledger, "damage_taken" if unit.team == Unit.Team.PLAYER else "damage_dealt", amount)


## Culls are counted wherever the fighting happens, so this listens globally.
func _on_unit_died(unit: Node) -> void:
	if unit.team == Unit.Team.ENEMY:
		Errand.record_kill(errands, unit.template_id)
		if tallying:
			Ledger.record_kill(ledger, unit.template_id)


func _on_battle_finished(result: Dictionary) -> void:
	if tallying:
		Ledger.add(ledger, "battles_won" if result.get("victory", false) else "battles_lost")


func new_game(world_seed: int = 0, lead_id: String = "") -> void:
	if world_seed == 0:
		world_seed = randi()
	world = WorldGen.generate(world_seed)
	roster = Roster.found(lead_id)
	gold = DEFAULT_GOLD
	ledger = Ledger.fresh()
	cleared_battles = []
	flags = {}
	talks = {}
	errands = []
	stores = []


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


func times_told(dialogue_id: String) -> int:
	return int(talks.get(dialogue_id, 0))


func remember_talk(dialogue_id: String) -> void:
	if dialogue_id == "":
		return
	talks[dialogue_id] = times_told(dialogue_id) + 1


# --- persistence --------------------------------------------------------------


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save() -> void:
	var payload := {
		"version": SAVE_VERSION,
		"world": world.to_dict(),
		"roster": roster.to_dict(),
		"gold": gold,
		"difficulty": difficulty,
		"cleared_battles": cleared_battles,
		"flags": flags,
		"talks": talks,
		"errands": errands,
		"stores": stores,
		"ledger": ledger,
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
	# After the purse, so restoring it does not read as income.
	ledger = Ledger.restore(data.get("ledger", {}))
	difficulty = str(data.get("difficulty", Difficulty.DEFAULT))
	cleared_battles = data.get("cleared_battles", [])
	flags = data.get("flags", {})
	talks = data.get("talks", {})
	errands = data.get("errands", [])
	stores = data.get("stores", [])
	return true
