extends RefCounted
## Reading back what the game wrote down as JSON: the save, the museum, the
## arena board.
##
## JSON has one kind of number, so every whole number the game wrote comes back
## a float. Most readers wrap what they read in `int()` and never notice, but a
## float is not an int to `Array.has`, `in`, `match`, array equality or a
## dictionary key, and `str()` prints it as "3.0". So a whole number read back
## is turned back into an int here, once, rather than at every reader. Nothing
## the game saves is a float that has to stay whole and a float: every reader of
## a fractional value (a power, a share) already asks for `float()`.
##
## Loaded by path, not by `class_name` ([D41]).

## Past this a double cannot hold every whole number, so nothing is converted.
const EXACT_UP_TO := 9007199254740992.0


## The parsed contents of [param path], whole numbers as ints, or null if there
## is no such file or it is not JSON.
static func read(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return whole(JSON.parse_string(FileAccess.get_file_as_string(path)))


## [param value] with every whole float inside it, however deep, made an int.
## Dictionaries and arrays are changed in place and returned.
static func whole(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			var number: float = value
			if is_finite(number) and number == floorf(number) and absf(number) < EXACT_UP_TO:
				return int(number)
			return number
		TYPE_DICTIONARY:
			var table: Dictionary = value
			for key: Variant in table.keys():
				table[key] = whole(table[key])
			return table
		TYPE_ARRAY:
			var list: Array = value
			for i in list.size():
				list[i] = whole(list[i])
			return list
	return value


# --- writing ------------------------------------------------------------------
#
# A save is never written over in place. It is written whole to a temporary file
# beside it, the save already there steps aside as the one rolling backup, and
# the temporary file is renamed into its place. A crash at any point leaves
# either the old save, or the backup and the new one: never half a file under
# the real name ([D56]).


## Where the one rolling backup of [param path] is kept:
## `earth-kings.save.json` -> `earth-kings.save.bak.json`.
static func backup_path(path: String) -> String:
	return "%s.bak.%s" % [path.get_basename(), path.get_extension()]


## Where a save of an older (or newer) [param version] is set aside before
## anything is done to it: `earth-kings.save.v2.bak.json`. Never rotated.
static func version_backup_path(path: String, version: int) -> String:
	return "%s.v%d.bak.%s" % [path.get_basename(), version, path.get_extension()]


## [param value] written to [param path] as tab-indented JSON, whole numbers as
## whole numbers, with the previous file kept at [method backup_path]. False,
## with the old save untouched, if the new one could not be written.
static func write(path: String, value: Variant) -> bool:
	# Whole numbers written as whole numbers, whatever they were carried as (a
	# number taken straight from the data is a float), so a file loaded and
	# saved again is the same file.
	var text := JSON.stringify(whole(value.duplicate(true) if value is Dictionary or value is Array else value), "\t")
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	var stored := file.store_string(text)
	file.flush()
	var error := file.get_error()
	file.close()
	if not stored or error != OK:
		DirAccess.remove_absolute(temp)
		return false
	if FileAccess.file_exists(path):
		var backup := backup_path(path)
		if FileAccess.file_exists(backup):
			DirAccess.remove_absolute(backup)
		if DirAccess.rename_absolute(path, backup) != OK:
			DirAccess.remove_absolute(temp)
			return false
	return DirAccess.rename_absolute(temp, path) == OK


## A byte-for-byte copy of [param from] at [param to]. False if it could not be made.
static func copy(from: String, to: String) -> bool:
	return FileAccess.file_exists(from) and DirAccess.copy_absolute(from, to) == OK
