extends Node
## The live game: the world, everyone in it, and the save file (autoload: `GameState`).

const SaveFile := preload("res://src/chronicle/save_file.gd")
const RunMode := preload("res://src/chronicle/run_mode.gd")

const SAVE_PATH := "user://earth-kings.save.json"
## 3: alignment retired in favour of creeds, and the four other authored history
## pools added, so a v2 character carries ids that no longer resolve.
const SAVE_VERSION := 3

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
## Companions sent away on one of those errands (see `src/chronicle/dispatch.gd`).
var away: Array = []
## The gate the party is inside, as [x, y], or empty. Once a floor is won there
## is no walking out until the gate is beaten or the party is ([D35]).
var delving: Array = []
## Equipment the party is carrying and nobody is wearing (see [Loot], [Gear]).
var stores: Array = []
## Surplus equipment and supplies deposited at the campfire strongbox.
var camp_stash: Array = []
## Keys found and kept. Not equipment — they weigh nothing and open one thing
## each (see [Ward]).
var keys: Array = []
## What the fight being walked into will settle on the way back, if it is won.
## Deliberately not saved: a battle abandoned mid-fight is simply never settled.
var pending_outcome: Dictionary = {}
## Live coliseum state (see [Arena]). Never saved — the sand is not the run.
var arena: Dictionary = {}
## How hard the country is (see [Difficulty]).
var difficulty: String = Difficulty.DEFAULT
## Classic or Iron Man ([D51], see `src/chronicle/run_mode.gd`). Picked with the
## lead and kept in the save; like the difficulty it carries over to the next
## new game until it is changed.
var mode: String = RunMode.DEFAULT
## How the last save is remembered ("you rested at Oakham"), and the step it was
## made on, so a fallen lead can be told what a reload goes back to.
var last_save_note: String = ""
var last_save_steps: int = 0
## Whether a run is being played right now (the map, a place, a fight), as
## opposed to the title or a menu with yesterday's world still in memory. Only
## then is leaving the game a point to save at.
var _in_run: bool = false

## Scenes that are the run itself.
const RUN_SCENES := ["world", "area", "battle", "skirmish"]


func _ready() -> void:
	EventBus.unit_died.connect(_on_unit_died)
	EventBus.unit_damaged.connect(_on_unit_damaged)
	EventBus.battle_finished.connect(_on_battle_finished)
	EventBus.safe_point_reached.connect(reached)
	EventBus.scene_changed.connect(_on_scene_changed)
	if world == null:
		new_game()


func _on_unit_damaged(unit: Node, amount: int) -> void:
	if tallying and unit.team != Unit.Team.ALLY:
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


func _on_scene_changed(scene_key: String) -> void:
	_in_run = RUN_SCENES.has(scene_key)
	# Every return to the map is a point Iron Man saves at, so closing the game
	# never hands back a fight that has been lost.
	if scene_key == "world":
		reached(RunMode.ROAD, "you were on the road")


## Closing the window is leaving the run, which Iron Man saves at.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		reached(RunMode.LEAVE, "you stepped away")


## The run has got somewhere the game may save itself. Whether it does is the
## mode's to say. Returns whether it saved.
func reached(point: String, note: String = "") -> bool:
	if not RunMode.saves_at(point, mode):
		return false
	if point == RunMode.LEAVE and not _in_run:
		return false
	# Never in the training yard or on the sand, and never over a run that has
	# already ended: that save is the one a fallen lead is offered back.
	if not tallying or world == null or roster == null or roster.run_is_over():
		return false
	save(note)
	EventBus.game_saved.emit(point, note)
	return true


## The save goes with the lead who fell, in Iron Man ([D51]).
func forget_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	last_save_note = ""


## Whether the save on disk is this run, and not one from before it.
func save_is_this_run() -> bool:
	if not has_save() or world == null:
		return false
	var parsed: Variant = SaveFile.read(SAVE_PATH)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	return int(parsed.get("world", {}).get("world_seed", -1)) == world.world_seed


func new_game(world_seed: int = 0, lead_id: String = "") -> void:
	# A run that is being started over is a run that is finished, whatever the
	# player calls it. File it before it is written on top of (see [Museum]).
	if world != null and roster != null and world.steps > 0 and tallying:
		Museum.remember(world, roster, ledger, Museum.WALKED_AWAY)
	if world_seed == 0:
		world_seed = randi()
	world = WorldGen.generate(world_seed)
	# Into the log, so a run somebody reports can be walked again from its seed.
	print("Earth Kings: new run, seed %d, lead '%s', %s, %s" % [world_seed, lead_id, difficulty, RunMode.valid(mode)])
	# The purse is filled before the company is founded, because a background
	# may hand the lead something to start with (see [Gifts]).
	gold = DEFAULT_GOLD
	roster = Roster.found(lead_id)
	world.player_cell = WorldGen.starting_cell_for_hero(world, lead_id)
	var lead := roster.player()
	var lead_name: String = lead.display_name if lead != null else "The founder"
	Annals.record(world, "%s founded the company and stepped out into %s." % [lead_name, world.region_at(world.player_cell)])
	ledger = Ledger.fresh()
	cleared_battles = []
	flags = {}
	talks = {}
	errands = []
	away = []
	delving = []
	stores = []
	camp_stash = []
	keys = []
	last_save_note = ""
	last_save_steps = 0


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


## [param note] says how this save will be remembered; without one it keeps the
## last, so a save loaded and saved again is the same file.
func save(note: String = "") -> void:
	if note != "":
		last_save_note = note
	last_save_steps = world.steps
	var payload := {
		"version": SAVE_VERSION,
		"world": world.to_dict(),
		"roster": roster.to_dict(),
		"gold": gold,
		"difficulty": difficulty,
		"mode": RunMode.valid(mode),
		"saved_at": last_save_note,
		"cleared_battles": cleared_battles,
		"flags": flags,
		"talks": talks,
		"errands": errands,
		"away": away,
		"delving": delving,
		"stores": stores,
		"camp_stash": camp_stash,
		"keys": keys,
		"ledger": ledger,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameState: could not write save to %s" % SAVE_PATH)
		return
	# Whole numbers written as whole numbers, whatever they were carried as (a
	# number taken straight from the data is a float), so a save loaded and saved
	# again is the same file.
	file.store_string(JSON.stringify(SaveFile.whole(payload.duplicate(true)), "\t"))


func load_save() -> bool:
	if not has_save():
		return false
	var parsed: Variant = SaveFile.read(SAVE_PATH)
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
	# A save from before the modes is a Classic run: it was saved by hand.
	mode = RunMode.valid(str(data.get("mode", RunMode.CLASSIC)))
	last_save_note = str(data.get("saved_at", ""))
	last_save_steps = world.steps
	cleared_battles = data.get("cleared_battles", [])
	flags = data.get("flags", {})
	talks = data.get("talks", {})
	errands = data.get("errands", [])
	away = data.get("away", [])
	delving = data.get("delving", [])
	stores = data.get("stores", [])
	camp_stash = data.get("camp_stash", [])
	keys = data.get("keys", [])
	return true


func stash_deposit(equipment_id: String) -> bool:
	var idx := stores.find(equipment_id)
	if idx >= 0:
		stores.remove_at(idx)
		camp_stash.append(equipment_id)
		return true
	return false


func stash_withdraw(equipment_id: String) -> bool:
	var idx := camp_stash.find(equipment_id)
	if idx >= 0:
		camp_stash.remove_at(idx)
		stores.append(equipment_id)
		return true
	return false
