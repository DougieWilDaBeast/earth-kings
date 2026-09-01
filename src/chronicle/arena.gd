class_name Arena
extends RefCounted
## The coliseum: waves, a purse, and a crowd. Nothing to do with the run.
##
## The storyline is a country you walk across once. This is the other thing —
## you pick somebody, you go out, and you keep going out until you cannot. It
## borrows [Battle] and nothing else: the roster you take in is built here and
## thrown away here, the real one is stashed while you are on the sand, and
## nobody who falls in front of a crowd actually dies.
##
## Live state hangs off [GameState] rather than a node, because the scene is
## destroyed and rebuilt every time a wave starts.

## Written down between sessions: how far anyone has ever got.
const PATH := "user://earth-kings.arena.json"
## Battle sets this rather than `last_victory`, so a wave never looks like a
## fight the world should settle.
const VICTORY_FLAG := "arena_victory"


static func rules() -> Dictionary:
	return Database.coliseum.get("rules", {})


static func cards() -> Dictionary:
	return Database.coliseum.get("cards", {})


static func grounds() -> Array:
	return Database.coliseum.get("grounds", [])


# --- the state ----------------------------------------------------------------


static func state() -> Dictionary:
	return GameState.arena


static func is_open() -> bool:
	return not GameState.arena.is_empty()


static func round_number() -> int:
	return int(state().get("round", 1))


static func purse() -> int:
	return int(state().get("purse", 0))


## Take somebody out onto the sand. The run's own roster is put aside until
## [method close] — anything that happens here happens to a copy.
static func open(hero_id: String, card_id: String) -> void:
	close()
	GameState.arena = {
		"hero": hero_id,
		"card": card_id,
		"round": 1,
		"purse": 0,
		"kept_roster": GameState.roster,
		"kept_tallying": GameState.tallying,
	}
	GameState.roster = Roster.found(hero_id)
	# Nothing on the sand belongs in the run's ledger.
	GameState.tallying = false


## Give the run its own people back. Safe to call when nothing is open.
static func close() -> void:
	if not is_open():
		return
	var kept: Dictionary = GameState.arena
	if kept.get("kept_roster") != null:
		GameState.roster = kept["kept_roster"]
	GameState.tallying = bool(kept.get("kept_tallying", true))
	GameState.arena = {}


## The battle payload for the round about to be fought.
static func wave(rng: RandomNumberGenerator) -> Dictionary:
	var number := round_number()
	var card: Dictionary = cards().get(str(state().get("card", "")), {})
	var foes: Array = card.get("foes", ["goblin"])
	var ground: Dictionary = grounds()[(number - 1) % maxi(1, grounds().size())]

	var enemies: Array = []
	for i in _count(number):
		enemies.append({
			"unit": foes[rng.randi() % foes.size()],
			"level": _level(number),
		})
	var map := BattleMapGen.generate_on(
		str(ground.get("terrain", "grass")), str(ground.get("name", "The Sand")), enemies, rng
	)
	map["id"] = "arena_%d" % number
	return {
		"encounter": { "map": map, "title": "%s — round %d" % [card.get("title", "The Sand"), number] },
		"return_scene": "coliseum",
		"sandbox": true,
		# The crowd does not put you back together between rounds.
		"heal": false,
	}


## The round was won. Pays out and moves the card on.
static func won() -> int:
	var paid := reward(round_number())
	state()["purse"] = purse() + paid
	state()["round"] = round_number() + 1
	_patch_up()
	return paid


## The round was lost. The purse is kept — you did earn it — and it is over.
static func lost() -> void:
	record(round_number() - 1, purse())


static func reward(number: int) -> int:
	var base := float(rules().get("purse_per_round", 60))
	return roundi(base * pow(float(rules().get("purse_growth", 1.35)), float(number - 1)))


## Retire between rounds and keep the purse. The only way to bank a run of them.
static func retire() -> void:
	record(round_number() - 1, purse())


# --- the board ----------------------------------------------------------------


static func board() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func best(card_id: String) -> Dictionary:
	return board().get(card_id, {})


## Only an improvement is written down. A worse night does not erase a better one.
static func record(rounds: int, won_purse: int) -> void:
	if rounds <= 0:
		return
	var card_id := str(state().get("card", ""))
	var all := board()
	var previous: Dictionary = all.get(card_id, {})
	if int(previous.get("rounds", 0)) > rounds:
		return
	all[card_id] = {
		"rounds": rounds,
		"purse": won_purse,
		"hero": str(state().get("hero", "")),
	}
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_error("Arena: could not write the board to %s" % PATH)
		return
	file.store_string(JSON.stringify(all, "\t"))


# --- the shape of a round -----------------------------------------------------


static func _count(number: int) -> int:
	var grown := float(rules().get("base_count", 2)) + float(rules().get("count_per_round", 0.45)) * float(number - 1)
	return clampi(roundi(grown), 1, int(rules().get("max_count", 6)))


static func _level(number: int) -> int:
	return maxi(1, roundi(float(rules().get("level_per_round", 1.4)) * float(number)))


## A fraction back between rounds, so a long night is survived rather than reset.
static func _patch_up() -> void:
	var share := float(rules().get("heal_between_rounds", 0.45))
	for character in GameState.roster.characters:
		character.status = Fate.ALIVE
		if character.current_hp() <= 0:
			# Falling in front of a crowd is not dying. They get dragged up.
			character.hp = maxi(1, roundi(character.max_hp() * 0.25))
			continue
		character.hp = clampi(
			character.current_hp() + roundi(character.max_hp() * share), 1, character.max_hp()
		)
