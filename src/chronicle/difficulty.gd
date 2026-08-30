class_name Difficulty
extends RefCounted
## How hard the country is (see `difficulty` in `data/world_rules.json`).
##
## Every dial is a plain multiplier or offset read at the point it matters, so
## a setting can be changed mid-run and nothing has to be rebuilt. The setting
## itself lives on [GameState] so it travels with the save.

const DEFAULT := "gentle"

## Dials, and what they mean when nothing is set.
const NEUTRAL := {
	"enemy_level": 0.0,
	"enemy_count": 0.0,
	"enemy_attack": 1.0,
	"enemy_hp": 1.0,
	"party_hp": 1.0,
	"party_attack": 1.0,
	"encounter_chance": 1.0,
	"grace": 1.0,
	"xp": 1.0,
	"gold": 1.0,
	"price": 1.0,
}


static func rules() -> Dictionary:
	return Database.world_rules.get("difficulty", {})


static func settings() -> Dictionary:
	return rules().get("settings", {})


## What the world is being played at. Falls back to the value in the data file
## so a save made before difficulty existed still opens.
static func current() -> String:
	var chosen: String = GameState.difficulty
	if settings().has(chosen):
		return chosen
	var written := str(rules().get("setting", DEFAULT))
	return written if settings().has(written) else DEFAULT


static func display_name(setting: String = "") -> String:
	return str(_of(setting).get("display_name", "Even"))


static func blurb(setting: String = "") -> String:
	return str(_of(setting).get("blurb", ""))


## A dial, as a multiplier or an offset depending on what it is.
static func dial(key: String) -> float:
	return float(_of("").get(key, NEUTRAL.get(key, 1.0)))


## Levels are offsets, and never take a foe below the first rung.
static func levelled(level: int) -> int:
	return maxi(1, level + roundi(dial("enemy_level")))


## Counts are offsets, and never empty a fight.
static func counted(count: int) -> int:
	return maxi(1, count + roundi(dial("enemy_count")))


static func scaled(value: int, key: String) -> int:
	return maxi(1, roundi(float(value) * dial(key)))


static func _of(setting: String) -> Dictionary:
	var chosen := setting if setting != "" else current()
	return settings().get(chosen, {})
