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
