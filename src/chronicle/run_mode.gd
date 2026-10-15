extends RefCounted
## Classic or Iron Man — how a run is saved, and what a fallen lead is offered
## ([D51], replacing the free save and load of [D21]).
##
## Classic keeps saves the player can go back to: when the lead dies the game
## offers the last save, or ascending and choosing the next lead. Iron Man has
## one life: the game saves for itself, never by hand, and a lead who dies takes
## the save with them.
##
## Everything a mode means is in `data/world_rules.json` → `modes`: whether the
## menu saves by hand, whether a death offers a reload, and the points at which
## the game saves itself. Those points are a build choice, **Inferred** (agenda
## item 40). The mode is picked with the lead, kept in the save, and never
## changed mid-run.
##
## Loaded by path, not by `class_name` ([D41]).

const CLASSIC := "classic"
const IRON_MAN := "iron_man"
const DEFAULT := CLASSIC

## The points the game can save itself at. Which ones a mode uses is data.
## A new run has just been founded.
const START := "start"
## The party slept: an inn, a hut, a home.
const REST := "rest"
## A Tower chapter has turned.
const CHAPTER := "chapter"
## The First Hour's way-stations, which the gamers asked to be saved at (meeting 3, step 2):
## walking into a town or the great city,
const TOWN := "town"
## opening the Guild's register,
const GUILD := "guild"
## and a gate shut.
const GATE := "gate"
## Back on the map from anywhere: a fight, a place, the fire.
const ROAD := "road"
## The player is leaving the run: to the title, or closing the game.
const LEAVE := "leave"


static func rules() -> Dictionary:
	return Database.world_rules.get("modes", {})


static func settings() -> Dictionary:
	return rules().get("settings", {})


## A mode that is not in the data reads as the default, so a save from before
## the modes existed opens as Classic — which is how it was being played.
static func valid(mode: String) -> String:
	if settings().has(mode):
		return mode
	var written := str(rules().get("setting", DEFAULT))
	return written if settings().has(written) else DEFAULT


static func current() -> String:
	return valid(GameState.mode)


static func display_name(mode: String = "") -> String:
	return str(_of(mode).get("display_name", "Classic"))


static func blurb(mode: String = "") -> String:
	return str(_of(mode).get("blurb", ""))


static func is_iron_man(mode: String = "") -> bool:
	return (mode if mode != "" else current()) == IRON_MAN


## Whether the system menu saves and loads by hand.
static func saves_by_hand(mode: String = "") -> bool:
	return bool(_of(mode).get("manual_save", true))


## Whether a fallen lead is offered the last save.
static func offers_reload(mode: String = "") -> bool:
	return bool(_of(mode).get("reload_on_death", true))


## Whether the game saves itself at [param point] (one of the constants above).
static func saves_at(point: String, mode: String = "") -> bool:
	return (_of(mode).get("autosave", []) as Array).has(point)


static func cycle(mode: String) -> String:
	var keys: Array = settings().keys()
	if keys.is_empty():
		return DEFAULT
	var idx := keys.find(valid(mode))
	return str(keys[(idx + 1) % keys.size()])


static func _of(mode: String) -> Dictionary:
	return settings().get(valid(mode) if mode != "" else current(), {})
