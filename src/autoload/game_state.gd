extends Node
## The live game: the world, everyone in it, and the save file (autoload: `GameState`).

const SaveFile := preload("res://src/chronicle/save_file.gd")
const RunMode := preload("res://src/chronicle/run_mode.gd")
const SaveMigrations := preload("res://src/chronicle/save_migrations.gd")
const Fall := preload("res://src/chronicle/fall.gd")
const Wanderers := preload("res://src/chronicle/wanderers.gd")
const Siblings := preload("res://src/chronicle/siblings.gd")
const Sixteen := preload("res://src/chronicle/sixteen.gd")

const SAVE_PATH := "user://earth-kings.save.json"
## 3: alignment retired in favour of creeds, and the four other authored history
## pools added, so a v2 character carries ids that no longer resolve.
## Raising this needs a step in `src/chronicle/save_migrations.gd` ([D56]).
const SAVE_VERSION := 3

const DEFAULT_GOLD := 250

var world: World
var roster: Roster

## Everything the run summary is retold from (see [Ledger]).
var ledger: Dictionary = Ledger.fresh()
## Cleared while the training sandbox borrows the purse, so play money never
## reaches the ledger.
var tallying: bool = true
## The tutorial's run (D73): nothing in it is ever saved, filed in the museum or counted, and it
## never writes over the save on disk. Set by [method new_game] with `rehearsal`, cleared by any
## other new game and by loading the save.
var rehearsing: bool = false

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
const RUN_SCENES := ["world", "area", "skirmish"]


func _ready() -> void:
	EventBus.unit_died.connect(_on_unit_died)
	EventBus.unit_damaged.connect(_on_unit_damaged)
	EventBus.battle_finished.connect(_on_battle_finished)
	EventBus.safe_point_reached.connect(reached)
	EventBus.scene_changed.connect(_on_scene_changed)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)
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
	if not tallying or rehearsing or world == null or roster == null or roster.run_is_over():
		return false
	save(note)
	EventBus.game_saved.emit(point, note)
	return true


## The save goes with the lead who fell, in Iron Man ([D51]).
## Its backup goes too, or [method has_save] would find the run again there.
func forget_save() -> void:
	for path: String in [SAVE_PATH, SaveFile.backup_path(SAVE_PATH)]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	last_save_note = ""


## Whether the save on disk is this run, and not one from before it.
func save_is_this_run() -> bool:
	if not has_save() or world == null:
		return false
	var parsed: Variant = SaveFile.read(SAVE_PATH)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var saved: Dictionary = parsed.get("world", {})
	# Sibling worlds share a seed (M15); which of the sixteen it is tells them apart.
	return int(saved.get("world_seed", -1)) == world.world_seed \
		and int(saved.get("echoes", {}).get("sibling", 0)) == int(world.echoes.get("sibling", 0))


## Somebody of the sixteen agreed, in a conversation, to walk with the company.
## Settled here whichever scene the conversation was had in.
func _on_dialogue_finished(dialogue_id: String) -> void:
	if world != null and roster != null and dialogue_id.begins_with(Wanderers.DIALOGUE_PREFIX):
		Wanderers.settle(world, roster, flags)


func new_game(world_seed: int = 0, lead_id: String = "", rehearsal: bool = false) -> void:
	# A run that is being started over is a run that is finished, whatever the
	# player calls it. File it before it is written on top of (see [Museum]).
	# Neither the tutorial nor a run left for it is: the save on disk is not touched.
	var was_rehearsing := rehearsing
	rehearsing = rehearsal
	if world != null and roster != null and world.steps > 0 and tallying and not was_rehearsing and not rehearsal:
		Museum.remember(world, roster, ledger, Museum.WALKED_AWAY)
	# Every world that has ended before this one (M15). Unless a seed was asked
	# for, the next is their sibling: built on the first one's seed, a share of
	# its dice dealt again, and everyone who went before coming through into it.
	# A seed asked for is a world of its own, and nothing comes through.
	var past: Array = []
	if world_seed == 0:
		past = Sixteen.worlds()
		world_seed = Siblings.base_seed(past) if not past.is_empty() else randi()
	world = WorldGen.generate(world_seed)
	Siblings.perturb(world, past.size())
	# Into the log, so a run somebody reports can be walked again from its seed.
	print("Earth Kings: new run, seed %d, world %d of the sixteen, lead '%s', %s, %s" % [world_seed, past.size() + 1, lead_id, difficulty, RunMode.valid(mode)])
	# The purse is filled before the company is founded, because a background
	# may hand the lead something to start with (see [Gifts]).
	gold = DEFAULT_GOLD
	roster = Roster.found(lead_id)
	# The fall (M13): the lead comes down somewhere of the seed's choosing, and
	# that crater is home. The others come down too, and set off on their own.
	var reach := Fall.reachable(world)
	Fall.land(world, lead_id, reach)
	Wanderers.land(world, roster, reach)
	# And whoever led the worlds that ended: alive here, and on their way as a
	# ghost and a weapon (D33, D52).
	Siblings.arrive(world, roster, past, reach)
	var lead := roster.player()
	var lead_name: String = lead.display_name if lead != null else "The founder"
	Annals.record(world, Fall.annal(world, lead_name))
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


## Whether there is a run to continue: the save, or failing that its backup (a
## crash between the two renames in [method SaveFile.write] leaves only that).
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SaveFile.backup_path(SAVE_PATH))


## [param note] says how this save will be remembered; without one it keeps the
## last, so a save loaded and saved again is the same file.
func save(note: String = "") -> void:
	if rehearsing:
		# The tutorial's run is never written, least of all over the real one.
		return
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
	# Never over the top of the last good save: see [method SaveFile.write].
	if not SaveFile.write(SAVE_PATH, payload):
		push_error("GameState: could not write save to %s; the previous save is untouched" % SAVE_PATH)


## Puts the saved run back. False if there is none that can be played, in which
## case nothing on disk has been lost: a save that is corrupt, too old to carry
## forward, or newer than this build is left or set aside, never written over
## ([D56]). Anything the player should hear about goes out as
## [signal EventBus.save_notice].
func load_save() -> bool:
	if not has_save():
		return false
	rehearsing = false
	var read_from := SAVE_PATH
	var parsed: Variant = SaveFile.read(read_from)
	var restored := false
	if typeof(parsed) != TYPE_DICTIONARY:
		if FileAccess.file_exists(read_from):
			push_error("GameState: corrupt save at %s; trying the backup" % read_from)
		read_from = SaveFile.backup_path(SAVE_PATH)
		parsed = SaveFile.read(read_from)
		if typeof(parsed) != TYPE_DICTIONARY:
			push_error("GameState: no readable save or backup at %s" % SAVE_PATH)
			EventBus.save_notice.emit("The save could not be read, and neither could its backup.")
			return false
		restored = true

	var data: Dictionary = parsed
	var version := int(data.get("version", 1))
	if version > SAVE_VERSION:
		# Written by a newer build. Loading it would mean reading what we do not
		# understand and, at the next save, writing over what we did not read.
		push_warning("GameState: save is version %d, this build reads up to %d; leaving it alone" % [version, SAVE_VERSION])
		SaveFile.copy(read_from, SaveFile.version_backup_path(SAVE_PATH, version))
		EventBus.save_notice.emit("This save is from a newer version of Earth Kings. Update the game to continue it; it has been left untouched.")
		return false
	if version < SAVE_VERSION:
		# Set aside before anything is done to it, whether or not it comes through.
		var aside := SaveFile.version_backup_path(SAVE_PATH, version)
		SaveFile.copy(read_from, aside)
		if SaveMigrations.upgrade(data, SAVE_VERSION).is_empty():
			push_warning("GameState: save version %d cannot be carried forward; kept at %s, starting fresh" % [version, aside])
			EventBus.save_notice.emit("This save is too old to carry forward. A copy was kept; a new run begins.")
			new_game()
			return false
		print("GameState: save upgraded from version %d to %d; the original is kept at %s" % [version, SAVE_VERSION, aside])
		EventBus.save_notice.emit("Your save was upgraded from an older version of the game.")
	if restored:
		EventBus.save_notice.emit("The save was damaged; restored from the backup.")

	world = World.from_dict(data.get("world", {}))
	roster = Roster.from_dict(data.get("roster", {}))
	# Seats are earned on the Tower; a save from before they were catches up.
	Roster.Seats.sync(world, roster)
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
