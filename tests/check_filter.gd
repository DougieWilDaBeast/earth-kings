extends RefCounted
## Run one check of a big suite instead of all of them.
##
##   godot --headless --path . res://tests/walk_smoke_test.tscn -- --check=gate
##   godot --headless --path . res://tests/world_smoke_test.tscn -- --check=fate,roster
##
## A suite lists its checks by name; with no `--check` every one runs, in order.
## A name the suite does not have is an error rather than a silent pass, so a
## typo cannot look like a green run. Checks still share the suite's one seeded
## world, so a check run alone sees that world as it was built, not as the
## checks before it left it.
##
## Loaded by path, not by `class_name` ([D41]).


## The names from [param all] to run, in suite order. Fills [param unknown] with
## any asked for that the suite does not have.
static func wanted(all: Array, unknown: Array) -> Array:
	var asked: Array = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--check="):
			asked.append_array(arg.trim_prefix("--check=").split(",", false))
	if asked.is_empty():
		return all.duplicate()
	for name: String in asked:
		if not all.has(name):
			unknown.append(name)
	return all.filter(func(name: String) -> bool: return asked.has(name))
