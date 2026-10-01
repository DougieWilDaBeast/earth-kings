extends RefCounted
## Who of the sixteen has fallen, across every world — M15, [D43], [D47].
##
## A lead who dies ends their world, and nobody can be answered into that life
## again. The record outlives the save and the museum: it is kept in its own
## file until every life the game can offer has fallen, and only then can it be
## wiped to begin a new sixteen.
##
## The leads that exist today are the interim heroes in `data/heroes.json`; no
## temper has a character written for it yet. Both are kept: a hero who fell
## leaves the picker, and their temper (once they have one) leaves the quiz.
##
## Loaded by path, not by `class_name` ([D41]).

const SaveFile := preload("res://src/chronicle/save_file.gd")

const DEFAULT_PATH := "user://earth-kings.sixteen.json"

## Tests point this somewhere else so a real record is never touched.
static var path := DEFAULT_PATH


static func fallen_heroes() -> Array:
	return _read().get("fallen_heroes", [])


static func fallen_tempers() -> Array:
	return _read().get("fallen_tempers", [])


## Write a dead lead down. Their temper goes too, if they have one.
static func fall(hero_id: String) -> void:
	if hero_id == "":
		return
	var record := _read()
	var heroes: Array = record.get("fallen_heroes", [])
	var tempers: Array = record.get("fallen_tempers", [])
	if not heroes.has(hero_id):
		heroes.append(hero_id)
	var code := Database.hero_temper(hero_id)
	if code != "" and not tempers.has(code):
		tempers.append(code)
	_write({"fallen_heroes": heroes, "fallen_tempers": tempers})


## Whether there is any life left to start: a hero not fallen, or a written
## temper not fallen.
static func anyone_left() -> bool:
	var heroes := fallen_heroes()
	for hero_id: String in Database.heroes:
		if not heroes.has(hero_id):
			return true
	return false


## Only once nobody is left. Returns whether it was wiped.
static func wipe() -> bool:
	if anyone_left():
		return false
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return true


static func _read() -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = SaveFile.read(path)
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func _write(record: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Sixteen: could not write the fallen to %s" % path)
		return
	file.store_string(JSON.stringify(record, "\t"))
