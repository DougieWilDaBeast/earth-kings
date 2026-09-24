extends Node
## Headless smoke test for the seams nothing else looks at: the places where one
## part of the game hands something to another and trusts it to arrive intact.
##
##   godot --headless --path . res://tests/seams_smoke_test.tscn
##   godot --headless --path . res://tests/seams_smoke_test.tscn -- --check=keys
##
## - **whole**: whole numbers read back out of JSON are ints again (see
##   `src/chronicle/save_file.gd`). A float is not an int to `has`, `in`, `match`
##   or array equality, which is how a gate you were inside came back as one you
##   were not.
## - **round_trip**: a lived-in run saved, loaded and saved again writes the
##   same file, and nothing in it changes type on the way through.
## - **keys**: every rules or data key the code reads by name exists in the
##   data. Every read carries a fallback, so a key missing from the data (or
##   misspelt in either place) is silent — the game quietly plays on the
##   fallback and nobody ever tunes it.
## - **members**: a variable typed as one of the game's own classes is only ever
##   asked for something that class has. Godot does not check this until the
##   line runs, so `band.units` on a band that keeps a `pack` compiled fine and
##   took every bounty on the board down with it.
## - **errands**: every kind of errand a board can post is written out whole.

const SaveFile := preload("res://src/chronicle/save_file.gd")
const Dispatch := preload("res://src/chronicle/dispatch.gd")
const CheckFilter := preload("res://tests/check_filter.gd")
const Names_ := preload("res://src/chronicle/names.gd")

const CHECKS := ["whole", "round_trip", "keys", "members", "errands"]

## Keys the code asks for that are deliberately left to the fallback, and why.
## Anything added here needs a reason a designer would accept.
const FALLBACK_ONLY := {}

var _failures: Array[String] = []


func _ready() -> void:
	var unknown: Array = []
	for check: String in CheckFilter.wanted(CHECKS, unknown):
		call("_check_" + check)
	for name: String in unknown:
		_failures.append("no such check '%s' (have: %s)" % [name, ", ".join(CHECKS)])
	_finish()


# --- whole --------------------------------------------------------------------


func _check_whole() -> void:
	var read: Variant = SaveFile.whole(JSON.parse_string(JSON.stringify({
		"cell": [3, 4],
		"deep": {"list": [{"n": 7}]},
		"share": 0.25,
		"power": 20.0,
		"huge": 1.0e20,
		"name": "3",
	})))
	_expect(read["cell"] == [3, 4], "a cell read back as %s, not [3, 4]" % str(read["cell"]))
	_expect([3, 4] in [read["cell"]], "a cell read back is not found by `in`")
	_expect(typeof(read["deep"]["list"][0]["n"]) == TYPE_INT, "a number three levels down stayed a float")
	_expect(is_equal_approx(read["share"], 0.25) and typeof(read["share"]) == TYPE_FLOAT, "a fraction lost its fraction")
	_expect(str(read["power"]) == "20", "a whole float still prints as '%s'" % str(read["power"]))
	_expect(typeof(read["huge"]) == TYPE_FLOAT, "a number past what a double holds exactly was made an int")
	_expect(typeof(read["name"]) == TYPE_STRING, "a string of digits was made a number")
	_expect(SaveFile.read("user://no-such-file.json") == null, "a missing file read as something")


# --- round_trip ---------------------------------------------------------------


## Everything that writes loose numbers into the save, done once each, so the
## file holds every shape of thing a real run leaves in it.
func _live_a_little() -> void:
	GameState.new_game(31)
	var world: World = GameState.world
	var lead := GameState.roster.player()

	world.steps = 40
	world.register_tree(AbilityGrammar.generate_tree("hunt", world.rng))
	Journal.sighted(world, "goblin", "the road")
	world.journal["goblin"]["felled"] = 3
	Renown.record(world, Renown.GATE_SHUT, world.player_cell, 3, "shut a gate")
	Annals.record(world, "Something happened on step forty.")
	world.survivors.append({
		"unit": "goblin", "name": "Goblin the Unkillable", "cell": [world.player_cell.x, world.player_cell.y],
		"place": "the road", "steps": world.steps, "encounters": 1,
	})
	world.threads["seams"] = {"stage": 1, "entered_at": 12, "memory": {"count": 2}, "tags": [], "done": false}
	# Remembered the way a thread's data says to, so the number arrives as the
	# data carries it: a float.
	Skein._apply(world, "seams", JSON.parse_string('[{"remember": {"met_at_step": 1}}]'), {})
	Doctrine.learn(lead, "heavy_mail", 12)
	GameState.remember_talk("prologue")
	var gate := world.sites_of_kind(Site.GATE)
	_expect(not gate.is_empty(), "no gate to be inside")
	if not gate.is_empty():
		GameState.delving = [gate[0].cell.x, gate[0].cell.y]

	# An errand taken and a companion sent off to do it.
	for site: Site in world.sites:
		if site.kind != Site.VILLAGE:
			continue
		Errand.refresh(site, world)
		var taken := Errand.accept(site, GameState.errands, world)
		if taken.is_empty():
			continue
		for character: Character in GameState.party_characters():
			if not character.is_player and Dispatch.send(world, GameState.roster, GameState.away, character, taken) != "":
				break
		break
	_expect(not GameState.away.is_empty(), "nobody could be sent away, so `away` goes untested")


func _snapshot() -> Dictionary:
	return {
		"world": GameState.world.to_dict(),
		"roster": GameState.roster.to_dict(),
		"flags": GameState.flags, "talks": GameState.talks, "errands": GameState.errands,
		"away": GameState.away, "delving": GameState.delving, "ledger": GameState.ledger,
		"stores": GameState.stores, "keys": GameState.keys, "cleared": GameState.cleared_battles,
		"camp_stash": GameState.camp_stash, "gold": GameState.gold,
	}.duplicate(true)


func _check_round_trip() -> void:
	_live_a_little()
	var before := _snapshot()
	var title_before := Names_.earned_title(GameState.world)
	GameState.save()
	var first := FileAccess.get_file_as_string(GameState.SAVE_PATH)
	_expect(GameState.load_save(), "the save would not load")
	var after := _snapshot()

	var drift: Dictionary = {}
	_drift(before, after, "", drift)
	for path: String in drift:
		_failures.append("%s changed type across a save (%d times)" % [path, drift[path]])

	GameState.save()
	var second := FileAccess.get_file_as_string(GameState.SAVE_PATH)
	if first != second:
		var a := first.split("\n")
		var b := second.split("\n")
		for i in mini(a.size(), b.size()):
			if a[i] != b[i]:
				_failures.append("save, load, save wrote a different file: '%s' became '%s'" % [
					a[i].strip_edges(), b[i].strip_edges()
				])
				break

	# The things that broke, or would have, on a float.
	var world: World = GameState.world
	var gate_cell := Vector2i(int(GameState.delving[0]), int(GameState.delving[1])) if not GameState.delving.is_empty() else Vector2i(-1, -1)
	_expect(GameState.delving == [gate_cell.x, gate_cell.y], "the gate being delved no longer equals its own cell")
	_expect(str(world.journal["goblin"]["felled"]) == "3", "a count prints as '%s'" % str(world.journal["goblin"]["felled"]))
	_expect(Names_.earned_title(world) == title_before, "the lead's title changed across a save")
	for job: Dictionary in GameState.away:
		_expect(job.get("back_at") is int, "an errand's return step came back a %s" % type_string(typeof(job.get("back_at"))))


func _drift(a: Variant, b: Variant, path: String, out: Dictionary) -> void:
	if typeof(a) != typeof(b):
		var where := RegEx.create_from_string("\\[\\d+\\]").sub(path, "[]", true)
		var key := "%s (%s -> %s)" % [where, type_string(typeof(a)), type_string(typeof(b))]
		out[key] = int(out.get(key, 0)) + 1
		return
	if a is Dictionary:
		for k: Variant in a:
			if not (b as Dictionary).has(k):
				out["%s.%s (lost)" % [path, str(k)]] = 1
			else:
				_drift(a[k], b[k], "%s.%s" % [path, str(k)], out)
	elif a is Array:
		for i in mini(a.size(), (b as Array).size()):
			_drift(a[i], b[i], "%s[%d]" % [path, i], out)


# --- keys ---------------------------------------------------------------------


## `static func rules() -> Dictionary: return Database.x` or `Database.x.get("y", {})`.
var _helper := RegEx.create_from_string(
	"static func (\\w+)\\(\\) -> Dictionary:\\s*\\n\\s*return Database\\.(\\w+)(?:\\.get\\(\"(\\w+)\", \\{\\}\\))?\\s*\\n"
)
var _get := RegEx.create_from_string("\\.get\\(\"(\\w+)\"(, \\{\\}\\))?")


func _check_keys() -> void:
	var files := _scripts("res://src")
	# Where each file's rules helper points, by file and by the name other files
	# call it through (`Dispatch.rules()`).
	var helpers: Dictionary = {}  # path -> {func name -> Dictionary}
	var by_class: Dictionary = {}  # "Dispatch" -> {func name -> Dictionary}
	for path: String in files:
		var source := FileAccess.get_file_as_string(path)
		for found: RegExMatch in _helper.search_all(source):
			var table: Variant = Database.get(found.get_string(2))
			if not table is Dictionary:
				_failures.append("%s: %s() returns Database.%s, which is not a table" % [path, found.get_string(1), found.get_string(2)])
				continue
			if found.get_string(3) != "":
				_expect(
					(table as Dictionary).has(found.get_string(3)),
					"%s: %s() reads Database.%s[\"%s\"], which the data does not have" % [
						path, found.get_string(1), found.get_string(2), found.get_string(3)
					]
				)
				table = (table as Dictionary).get(found.get_string(3), {})
			if not helpers.has(path):
				helpers[path] = {}
			helpers[path][found.get_string(1)] = table
			var class_name_ := path.get_file().get_basename().to_pascal_case()
			if not by_class.has(class_name_):
				by_class[class_name_] = {}
			by_class[class_name_][found.get_string(1)] = table

	var checked := 0
	for path: String in files:
		var source := FileAccess.get_file_as_string(path)
		# Database.x.get("k" ...
		for found: RegExMatch in RegEx.create_from_string("Database\\.(\\w+)(?=\\.get\\(\")").search_all(source):
			var table: Variant = Database.get(found.get_string(1))
			if table is Dictionary:
				checked += _follow(path, "Database.%s" % found.get_string(1), table, source, found.get_end())
		# rules().get("k" ... inside the file that defines it
		for helper: String in helpers.get(path, {}):
			var call_ := RegEx.create_from_string("(?<![\\w.])%s\\(\\)(?=\\.get\\(\")" % helper)
			for found: RegExMatch in call_.search_all(source):
				checked += _follow(path, "%s()" % helper, helpers[path][helper], source, found.get_end())
		# Dispatch.rules().get("k" ... from anywhere
		for owner: String in by_class:
			for helper: String in by_class[owner]:
				var call_ := RegEx.create_from_string("\\b%s\\.%s\\(\\)(?=\\.get\\(\")" % [owner, helper])
				for found: RegExMatch in call_.search_all(source):
					checked += _follow(path, "%s.%s()" % [owner, helper], by_class[owner][helper], source, found.get_end())
	print("keys: %d named reads checked across %d scripts" % [checked, files.size()])
	_expect(checked > 100, "only %d reads found; the scan has stopped matching the code" % checked)


## Walks one `.get("a", {}).get("b", …)` chain from [param at], checking each
## key against [param table]. Returns how many keys it checked.
func _follow(path: String, what: String, table: Dictionary, source: String, at: int) -> int:
	var checked := 0
	var chain := what
	while true:
		var step := _get.search(source, at)
		if step == null or step.get_start() != at:
			break
		var key := step.get_string(1)
		chain += ".%s" % key
		checked += 1
		if not table.has(key) and not FALLBACK_ONLY.has(chain):
			_failures.append("%s reads %s, which the data does not have" % [path.trim_prefix("res://"), chain])
			break
		var next: Variant = table.get(key)
		# Only a `{}` fallback means the chain goes on into another table.
		if step.get_string(2) == "" or not next is Dictionary:
			break
		table = next
		at = step.get_end()
	return checked


func _scripts(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for sub: String in dir.get_directories():
		out.append_array(_scripts(dir_path.path_join(sub)))
	for file: String in dir.get_files():
		if file.ends_with(".gd"):
			out.append(dir_path.path_join(file))
	return out


# --- members ------------------------------------------------------------------


func _check_members() -> void:
	var classes: Dictionary = {}  # "Prowler" -> Script
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		if str(entry["path"]).begins_with("res://src/"):
			classes[str(entry["class"])] = load(str(entry["path"]))
	var typed := RegEx.create_from_string("\\b(\\w+)\\s*:\\s*(\\w+)\\b")
	var inferred := RegEx.create_from_string("\\b(?:var|for)\\s+(\\w+)\\s*(?::=|in\\b)")
	var strings := RegEx.create_from_string("\"(?:[^\"\\\\\\n]|\\\\.)*\"")
	var checked := 0
	for path: String in _scripts("res://src"):
		# Out of string literals, so "%s.png" is not somebody's `.png`.
		var source := strings.sub(FileAccess.get_file_as_string(path), "\"\"", true)
		# Every name in the file typed as one of ours, and every type it is given
		# (the same local name can mean different things in different functions).
		# A name that is ever something else — a Dictionary, a preloaded script,
		# whatever `:=` makes it — is left alone rather than guessed at.
		var types_of: Dictionary = {}
		var elsewhere: Dictionary = {}
		for found: RegExMatch in typed.search_all(source):
			if not classes.has(found.get_string(2)):
				elsewhere[found.get_string(1)] = true
				continue
			if not types_of.has(found.get_string(1)):
				types_of[found.get_string(1)] = []
			if not (types_of[found.get_string(1)] as Array).has(found.get_string(2)):
				types_of[found.get_string(1)].append(found.get_string(2))
		for found: RegExMatch in inferred.search_all(source):
			elsewhere[found.get_string(1)] = true
		for name: String in elsewhere:
			types_of.erase(name)
		for name: String in types_of:
			var use := RegEx.create_from_string("(?<![\\w.])%s\\.([a-z_]\\w*)" % name)
			for found: RegExMatch in use.search_all(source):
				var member := found.get_string(1)
				checked += 1
				var anywhere := false
				for type_name: String in types_of[name]:
					if _has_member(classes[type_name], member):
						anywhere = true
						break
				if not anywhere:
					_failures.append("%s: %s.%s, but %s has no '%s'" % [
						path.trim_prefix("res://"), name, member, "/".join(types_of[name]), member
					])
	print("members: %d uses of the game's own classes checked" % checked)
	_expect(checked > 500, "only %d uses found; the scan has stopped matching the code" % checked)


func _has_member(script: Script, member: String) -> bool:
	var current := script
	while current != null:
		for list: Array in [current.get_script_property_list(), current.get_script_method_list(), current.get_script_signal_list()]:
			for entry: Dictionary in list:
				if str(entry.get("name", "")) == member:
					return true
		if current.get_script_constant_map().has(member):
			return true
		current = current.get_base_script()
	var native := script.get_instance_base_type()
	return (
		ClassDB.class_has_method(native, member)
		or ClassDB.class_has_signal(native, member)
		or ClassDB.class_get_property_list(native).any(func(p: Dictionary) -> bool: return p["name"] == member)
	)


# --- errands ------------------------------------------------------------------


func _check_errands() -> void:
	GameState.new_game(52)
	var world: World = GameState.world
	# A bounty is posted on a band that is out there, and a new country has none
	# abroad yet.
	world.prowlers.append(Prowler.create(world.player_cell + Vector2i(3, 0), ["wolf", "goblin"]))
	var seen: Dictionary = {}
	var villages := world.sites.filter(func(site: Site) -> bool: return site.kind == Site.VILLAGE)
	for i in 400:
		var site: Site = villages[i % villages.size()]
		site.data["errand"] = {}
		Errand.refresh(site, world)
		var errand := Errand.board(site)
		var kind := str(errand.get("kind", ""))
		if seen.has(kind):
			continue
		seen[kind] = true
		for field: String in ["title", "text", "giver", "from_name"]:
			_expect(str(errand.get(field, "")) != "", "a %s errand was posted with no %s" % [kind, field])
		_expect(int(errand.get("gold", 0)) > 0, "a %s errand pays nothing" % kind)
		if kind == Errand.CULL or kind == Errand.BOUNTY:
			_expect(Database.units.has(str(errand.get("target", ""))), "a %s errand hunts '%s', which is nothing" % [
				kind, str(errand.get("target", ""))
			])
	for kind: String in [Errand.FETCH, Errand.LOOK, Errand.CULL, Errand.DELIVER, Errand.BOUNTY]:
		_expect(seen.has(kind), "400 boards never posted a %s errand" % kind)


# --- plumbing -----------------------------------------------------------------



func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("seams smoke test: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		print("FAIL  %s" % failure)
	print("seams smoke test: FAIL")
	get_tree().quit(1)
