extends Node
## Static reachability coverage for GDScript, since Godot ships no line profiler.
##
##   godot --headless --path . res://tools/coverage.tscn
##
## Builds a call graph across src/ and tests/, then walks it from the test
## entry points. A function is COVERED if a test can reach it, LIVE if only the
## engine or a scene reaches it, and DEAD if nothing references it at all.
##
## This measures *reach*, not assertion strength — a covered function was run,
## not necessarily checked. Assertion counts per system are reported separately.

const SOURCE_ROOT := "res://src"
const TEST_ROOT := "res://tests"

## Called by the engine, never by name; roots for the LIVE pass.
const ENGINE_HOOKS := [
	"_ready", "_process", "_physics_process", "_draw", "_input",
	"_unhandled_input", "_init", "_enter_tree", "_exit_tree", "_notification",
]

var _defs: Dictionary = {}        ## "file::name" -> { file, name, line, klass }
var _by_name: Dictionary = {}     ## name -> [keys]
var _by_class: Dictionary = {}    ## class_name -> file
var _file_class: Dictionary = {}  ## file -> class_name
var _refs: Dictionary = {}        ## file -> { name: [qualifier] }
var _words: Dictionary = {}       ## file -> { bare identifier: true }
var _scene_scripts: Dictionary = {}  ## scene path -> [script paths]
var _files: Array[String] = []
var _test_files: Array[String] = []


func _ready() -> void:
	_collect(SOURCE_ROOT, false)
	_collect(TEST_ROOT, true)
	_index_scenes(SOURCE_ROOT)
	_index_scenes(TEST_ROOT)
	_index_references()

	var covered := _walk(_test_roots())
	var live := _walk(_engine_roots())

	_report(covered, live)
	get_tree().quit(0)


# --- parsing ------------------------------------------------------------------


func _collect(root: String, is_test: bool) -> void:
	for path in _scripts_under(root):
		_files.append(path)
		if is_test:
			_test_files.append(path)
		_parse(path)


func _scripts_under(root: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(root)
	if dir == null:
		return found
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var path := "%s/%s" % [root, entry]
		if dir.current_is_dir():
			found.append_array(_scripts_under(path))
		elif entry.ends_with(".gd"):
			found.append(path)
		entry = dir.get_next()
	return found


func _parse(path: String) -> void:
	var lines := FileAccess.get_file_as_string(path).split("\n")
	for i in lines.size():
		var line: String = lines[i]
		var trimmed := line.strip_edges()

		if trimmed.begins_with("class_name "):
			var klass := trimmed.substr(11).split(" ")[0].strip_edges()
			_by_class[klass] = path
			_file_class[path] = klass
			continue

		if not trimmed.begins_with("func ") and not trimmed.begins_with("static func "):
			continue
		var after := trimmed.substr(trimmed.find("func ") + 5)
		var name := after.split("(")[0].strip_edges()
		var key := "%s::%s" % [path, name]
		_defs[key] = { "file": path, "name": name, "line": i + 1 }
		if not _by_name.has(name):
			_by_name[name] = []
		_by_name[name].append(key)


## Scenes hide the call graph: a test that instantiates battle.tscn never names
## a single function in battle.gd. Map scenes to their scripts so those count.
func _index_scenes(root: String) -> void:
	var pattern := RegEx.new()
	pattern.compile("path=\"(res://[^\"]+\\.gd)\"")
	for path in _scenes_under(root):
		var scripts: Array[String] = []
		for m in pattern.search_all(FileAccess.get_file_as_string(path)):
			scripts.append(m.get_string(1))
		_scene_scripts[path] = scripts


func _scenes_under(root: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(root)
	if dir == null:
		return found
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var path := "%s/%s" % [root, entry]
		if dir.current_is_dir():
			found.append_array(_scenes_under(path))
		elif entry.ends_with(".tscn"):
			found.append(path)
		entry = dir.get_next()
	return found


## Record every `name(` and `Thing.name(` call site, keyed by the calling file.
func _index_references() -> void:
	var call_pattern := RegEx.new()
	call_pattern.compile("(?:([A-Za-z_][A-Za-z0-9_]*)\\s*\\.\\s*)?([a-zA-Z_][a-zA-Z0-9_]*)\\s*\\(")
	# Signal wiring and deferred calls pass the function by name, not by call.
	var indirect := RegEx.new()
	indirect.compile("(?:connect|call_deferred|callv|bind|sort_custom|map|filter|any|all)\\s*\\(\\s*[\"']?([a-zA-Z_][a-zA-Z0-9_]*)")
	# `_swap.call_deferred(...)` names the function *before* the dot.
	var deferred := RegEx.new()
	deferred.compile("([a-zA-Z_][a-zA-Z0-9_]*)\\s*\\.\\s*(?:call_deferred|bind|callv)\\s*\\(")
	# Any bare identifier, used only to judge whether something is truly dead.
	var word := RegEx.new()
	word.compile("[a-zA-Z_][a-zA-Z0-9_]*")

	for path in _files:
		var refs: Dictionary = {}
		var words: Dictionary = {}
		for raw in FileAccess.get_file_as_string(path).split("\n"):
			var line: String = raw.strip_edges()
			if line.begins_with("#") or line.begins_with("##"):
				continue
			var is_signature := line.begins_with("func ") or line.begins_with("static func ")
			if not is_signature:
				for m in call_pattern.search_all(line):
					var name := m.get_string(2)
					var qualifier := m.get_string(1)
					if not refs.has(name):
						refs[name] = []
					if qualifier != "" and qualifier not in refs[name]:
						refs[name].append(qualifier)
				for m in indirect.search_all(line):
					if not refs.has(m.get_string(1)):
						refs[m.get_string(1)] = []
				for m in deferred.search_all(line):
					if not refs.has(m.get_string(1)):
						refs[m.get_string(1)] = []
			for m in word.search_all(line):
				words[m.get_string(0)] = true
		_refs[path] = refs
		_words[path] = words


# --- graph walking ------------------------------------------------------------


func _test_roots() -> Array[String]:
	var roots: Array[String] = []
	for path in _test_files:
		for key: String in _defs:
			if _defs[key]["file"] == path:
				roots.append(key)
		roots.append_array(_scene_entry_points(path))
	return roots


## A test that loads a scene runs everything that scene's scripts hook into.
func _scene_entry_points(test_path: String) -> Array[String]:
	var roots: Array[String] = []
	var pattern := RegEx.new()
	pattern.compile("res://[^\"']+\\.tscn")
	for m in pattern.search_all(FileAccess.get_file_as_string(test_path)):
		for script: String in _scene_scripts.get(m.get_string(0), []):
			for key: String in _defs:
				if _defs[key]["file"] == script:
					roots.append(key)
	return roots


func _engine_roots() -> Array[String]:
	var roots: Array[String] = []
	for key: String in _defs:
		if _defs[key]["name"] in ENGINE_HOOKS:
			roots.append(key)
	return roots


func _walk(roots: Array[String]) -> Dictionary:
	var seen: Dictionary = {}
	var queue: Array[String] = roots.duplicate()
	for key in roots:
		seen[key] = true

	while not queue.is_empty():
		var key: String = queue.pop_back()
		var file: String = _defs[key]["file"]
		for name: String in _refs.get(file, {}):
			for target in _resolve(name, _refs[file][name], file):
				if not seen.has(target):
					seen[target] = true
					queue.append(target)
	return seen


## Map a call site to the definitions it could mean, preferring a qualified
## class, then the calling file itself, then anything with that name.
func _resolve(name: String, qualifiers: Array, from_file: String) -> Array[String]:
	if not _by_name.has(name):
		return []

	var out: Array[String] = []
	for qualifier: String in qualifiers:
		if _by_class.has(qualifier):
			var key := "%s::%s" % [_by_class[qualifier], name]
			if _defs.has(key) and key not in out:
				out.append(key)
	if not out.is_empty():
		return out

	var local := "%s::%s" % [from_file, name]
	if _defs.has(local):
		return [local]

	for key: String in _by_name[name]:
		out.append(key)
	return out


## Truly dead means the name appears nowhere but its own definition.
func _is_mentioned(name: String, own_file: String) -> bool:
	for path: String in _words:
		if path == own_file:
			continue
		if _words[path].has(name):
			return true
	return false


# --- reporting ----------------------------------------------------------------


func _report(covered: Dictionary, live: Dictionary) -> void:
	print("COVERAGE — reachability from the headless tests\n")
	print("%-44s %6s %8s %6s" % ["file", "funcs", "covered", "dead"])
	print("-".repeat(70))

	var totals := { "funcs": 0, "covered": 0, "dead": 0 }
	var uncovered_by_file: Dictionary = {}
	var dead_list: Array[String] = []

	for path in _files:
		if path in _test_files:
			continue
		var names: Array[String] = []
		for key: String in _defs:
			if _defs[key]["file"] == path:
				names.append(key)
		if names.is_empty():
			continue

		var hit := 0
		var dead := 0
		var missing: Array[String] = []
		for key in names:
			if covered.has(key):
				hit += 1
			else:
				missing.append(_defs[key]["name"])
				if not live.has(key) and not _is_mentioned(_defs[key]["name"], path):
					dead += 1
					dead_list.append("%s:%d  %s()" % [
						path.replace("res://", ""), _defs[key]["line"], _defs[key]["name"]
					])

		totals["funcs"] += names.size()
		totals["covered"] += hit
		totals["dead"] += dead
		if not missing.is_empty():
			uncovered_by_file[path] = missing

		print("%-44s %6d %7d%% %6d" % [
			path.replace("res://src/", ""), names.size(),
			roundi(float(hit) / float(names.size()) * 100.0), dead
		])

	print("-".repeat(70))
	print("%-44s %6d %7d%% %6d" % [
		"TOTAL", totals["funcs"],
		roundi(float(totals["covered"]) / float(totals["funcs"]) * 100.0), totals["dead"]
	])

	print("\nNOT REACHED BY ANY TEST")
	for path: String in uncovered_by_file:
		print("  %s" % path.replace("res://src/", ""))
		print("    %s" % ", ".join(uncovered_by_file[path]))

	if not dead_list.is_empty():
		print("\nDEAD — nothing references these at all")
		for entry in dead_list:
			print("  %s" % entry)

	_report_assertions()


## Reach is not proof. Count what each test actually checks.
func _report_assertions() -> void:
	print("\nASSERTIONS BY TEST")
	var pattern := RegEx.new()
	pattern.compile("_expect\\s*\\(")
	for path in _test_files:
		var body := FileAccess.get_file_as_string(path)
		var count := pattern.search_all(body).size()
		if count > 0:
			print("  %-40s %d checks" % [path.replace("res://tests/", ""), count])
