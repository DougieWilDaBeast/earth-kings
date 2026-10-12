extends RefCounted
## Bringing an old save up to date, one version at a time ([D55]).
##
## Each step takes a save written at version N and returns it as version N + 1
## would have written it. [method upgrade] runs them in order until the save is
## current, so a save three versions old goes through three steps, each of which
## only ever has to know about its own change.
##
## A version with no step here could not be reconstructed from the history, and
## a save that old cannot be carried forward. [GameState] sets it aside before
## starting fresh rather than losing it.
##
## When `SAVE_VERSION` goes up, add the step that gets the last version to it
## here, in the same commit.
##
## Loaded by path, not by `class_name` ([D41]).

## The versions a step starts from; each is run by [method _step]. 1 (before
## the world was walked, 2026-08-27) is not here: the run was a single fight
## then, and there is nothing in it a walked world could start from.
const STEPS := [2]


## Whether a save written at [param from] can be brought up to [param to].
static func can_upgrade(from: int, to: int) -> bool:
	for version in range(from, to):
		if version not in STEPS:
			return false
	return true


## [param data] brought up to version [param to], changed in place and returned,
## or an empty dictionary if some version on the way has no step.
static func upgrade(data: Dictionary, to: int) -> Dictionary:
	var version := int(data.get("version", 1))
	if not can_upgrade(version, to):
		return {}
	while version < to:
		_step(version, data)
		version += 1
		data["version"] = version
	return data


# --- the steps ----------------------------------------------------------------


static func _step(from: int, data: Dictionary) -> void:
	match from:
		2:
			_from_2(data)


## 2 -> 3: alignment was retired for creeds, and a character's history became
## five ids into the pools under `data/lore/` (516cfa3). The old int `hearth`
## (extra max HP from the bed last slept in) was renamed `hearth_vigour` to free
## the name for where they are from. Backgrounds kept their ids.
##
## Everything else a v3 character has is filled the way [method Character.create]
## fills it: off their hero record, or failing that their unit template. Gifts
## are not handed out again; they were the start of a run already begun.
static func _from_2(data: Dictionary) -> void:
	var roster: Dictionary = data.get("roster", {})
	for entry: Dictionary in roster.get("characters", []):
		var vigour: Variant = entry.get("hearth", 0)
		entry["hearth_vigour"] = int(vigour) if vigour is int or vigour is float else 0
		entry.erase("hearth")
		entry.erase("alignment")
		var template_id := str(entry.get("template_id", ""))
		var hero := Database.hero(template_id)
		var source := hero if not hero.is_empty() else Database.unit_template(template_id)
		entry["temper"] = str(source.get("temper", ""))
		for field: String in ["grudge", "hearth", "creed", "oath"]:
			entry[field] = str(source.get(field, ""))
		if Database.lore_piece("backgrounds", str(entry.get("background", ""))).is_empty():
			entry["background"] = str(source.get("background", ""))
