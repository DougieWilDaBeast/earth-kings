extends Node
## Who wins? Two of the sixteen fight it out with nobody's hand on either, for the
## show ([D180], `docs/18-combat-direction.md#who-wins`).
##
## The fight is the real one: the skirmish in `bout` mode, a sandbox, both sides
## played by the same brain the enemies use, on a field drawn from the seed. Only
## the dressing is the show's ([WhoWinsShow]): a VS card, FIGHT!, the two leads'
## bars along the top, the move each last let go, the K.O. in slow motion and the
## winner's banner. Its timings and words are in `data/who_wins.json`.
##
##   # watch one (a window; Esc leaves)
##   godot --path . res://src/who_wins/who_wins.tscn -- --left=ares --right=cassius --seed=7
##
##   # record one: Godot's movie maker writes every frame, so it plays the same at any speed
##   godot --path . --write-movie clip.avi --fixed-fps 30 --resolution 1920x1080 \
##       res://src/who_wins/who_wins.tscn -- --left=ares --right=cassius --seed=7 --quit
##   (or `python3 tools/who_wins.py ares cassius`, which does both shapes and the .mp4)
##
##   # just the answer, headless, in a moment
##   godot --headless --path . res://src/who_wins/who_wins.tscn -- --left=ares --right=cassius --verdict
##
##   # every lead against every other, both ways round: a balance table
##   godot --headless --path . res://src/who_wins/who_wins.tscn -- --table --seeds=3

const Skirmish := preload("res://src/skirmish/skirmish.tscn")
const WhoWinsShow := preload("res://src/who_wins/who_wins_show.gd")
const SkirmishRules := preload("res://src/skirmish/skirmish_rules.gd")

## Set by [Game] before the scene enters the tree: `{left, right, level, seed}`.
var boot_payload: Dictionary = {}

var _args: Dictionary = {}
var _fight: Node2D
var _show: WhoWinsShow


func _ready() -> void:
	_args = _parse(OS.get_cmdline_user_args())
	for key: String in boot_payload:
		_args[key] = str(boot_payload[key])
	if _args.has("table"):
		_print_table(int(_args.get("seeds", 1)), int(_args.get("level", rule("level", 5))))
		get_tree().quit(0)
		return
	var leads: Array = Database.heroes.keys()
	var seed_ := int(_args.get("seed", 0))
	if seed_ == 0:
		seed_ = randi() % 100000 + 1
	var left := str(_args.get("left", ""))
	var right := str(_args.get("right", ""))
	# Nobody named: two of the sixteen, picked by the seed.
	var pick := RandomNumberGenerator.new()
	pick.seed = seed_
	if not leads.has(left):
		left = leads[pick.randi() % leads.size()]
	while not leads.has(right) or right == left:
		right = leads[pick.randi() % leads.size()]
	var level := int(_args.get("level", rule("level", 5)))

	if _args.has("verdict"):
		var result := run_bout(self, left, right, level, seed_)
		print(verdict_line(result))
		get_tree().quit(0)
		return

	Pace.auto = true
	_fight = Skirmish.instantiate()
	_fight.boot_payload = stage(left, right, level, seed_)
	# The show holds the clock until the card has gone and FIGHT! is said.
	_fight.boot_payload["paused"] = true
	add_child(_fight)
	toughen(_fight)
	_show = WhoWinsShow.new()
	add_child(_show)
	_show.over.connect(_on_show_over)
	_show.begin(_fight, level)
	print("who wins: %s vs %s, level %d, seed %d" % [left, right, level, seed_])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_show_over()


func _on_show_over() -> void:
	Engine.time_scale = 1.0
	Pace.auto = false
	if _fight != null and _fight.over:
		print(verdict_line(_result_of(_fight)))
	if _args.has("quit") or boot_payload.is_empty():
		get_tree().quit(0)
	else:
		EventBus.request_scene.emit(str(boot_payload.get("return_scene", "title")), {})


# --- the bout ---------------------------------------------------------------


## A number from `data/who_wins.json`.
static func rule(key: String, fallback: float) -> float:
	return float(Database.who_wins.get(key, fallback))


## Everything a bout needs, set up from the seed: [param left] leads a party of
## one (the company that follows them stays home) and [param right] stands
## across the field at the same level. Both are raised the same way, quietly, and
## the skirmish payload that comes back fights them.
static func stage(left: String, right: String, level: int, seed_: int) -> Dictionary:
	seed(seed_)
	var roster := Roster.found(left)
	roster.party = [roster.characters[0].id]
	GameState.roster = roster
	Progression.raise_quietly(roster.characters[0], level, GameState.world)
	GameState.heal_party()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var terrain := str(Database.who_wins.get("terrain", "grass"))
	var map := BattleMapGen.generate_on(terrain, Database.terrain_type(terrain).get("name", terrain),
			[{"unit": right, "level": level}], rng)
	return {
		"encounter": {"map": map, "title": "Who wins?"},
		"sandbox": true,
		"bout": true,
		"paused": false,
		"seed": seed_,
	}


## One against one is over in seconds at the health a company fights with, which
## is too quick to watch: every body on the field gets `health_scale` times as much.
static func toughen(fight: Node) -> void:
	var scale := rule("health_scale", 3.0)
	for f: RefCounted in fight.fighters:
		f.unit.max_hp = roundi(f.unit.max_hp * scale)
		f.unit.hp = roundi(f.unit.hp * scale)


## Fights a bout to its end on fixed ticks, with nothing drawn: a minute of fight
## in a moment. [param host] holds the fight while it runs.
static func run_bout(host: Node, left: String, right: String, level: int, seed_: int) -> Dictionary:
	var was_auto := Pace.auto
	Pace.auto = true
	var fight: Node2D = Skirmish.instantiate()
	fight.boot_payload = stage(left, right, level, seed_)
	fight.manual = true
	host.add_child(fight)
	toughen(fight)
	var limit := rule("time_limit", 180.0)
	while not fight.over and fight.sim_time < limit:
		fight.tick()
	var result := _result_of(fight)
	host.remove_child(fight)
	fight.free()
	Pace.auto = was_auto
	result["seed"] = seed_
	result["level"] = level
	return result


## Who stood at the end, read off a finished (or timed-out) fight.
static func _result_of(fight: Node) -> Dictionary:
	var leads: Array = fight.fighters.filter(func(f: RefCounted) -> bool: return f.bound_to == null)
	var left_f: RefCounted = null
	var right_f: RefCounted = null
	for f: RefCounted in leads:
		if f.is_party():
			left_f = f
		elif right_f == null:
			right_f = f
	var winner := ""
	if fight.over:
		winner = left_f.unit.template_id if fight.victory else right_f.unit.template_id
	return {
		"left": left_f.unit.template_id if left_f != null else "",
		"right": right_f.unit.template_id if right_f != null else "",
		"winner": winner,
		"seconds": fight.sim_time,
		"left_hp": left_f.unit.hp if left_f != null else 0,
		"right_hp": right_f.unit.hp if right_f != null else 0,
	}


static func verdict_line(result: Dictionary) -> String:
	if str(result["winner"]) == "":
		return "who wins: nobody, %s and %s still standing after %.0f s" % [result["left"], result["right"], result["seconds"]]
	var loser := str(result["right"]) if result["winner"] == result["left"] else str(result["left"])
	return "who wins: %s beats %s in %.0f s" % [result["winner"], loser, result["seconds"]]


## Every lead against every other, from both sides of the field, [param seeds]
## times each: who beats whom and how often, and how long a bout runs.
func _print_table(seeds: int, level: int) -> void:
	var leads: Array = Database.heroes.keys()
	var wins := {}
	var bouts := {}
	var seconds: Array[float] = []
	var draws := 0
	for a: String in leads:
		wins[a] = 0
		bouts[a] = 0
	for a: String in leads:
		for b: String in leads:
			if a == b:
				continue
			for s in seeds:
				var result := run_bout(self, a, b, level, 1000 + s)
				bouts[a] += 1
				bouts[b] += 1
				seconds.append(float(result["seconds"]))
				if str(result["winner"]) == "":
					draws += 1
				else:
					wins[result["winner"]] += 1
	leads.sort_custom(func(x: String, y: String) -> bool:
		return float(wins[x]) / bouts[x] > float(wins[y]) / bouts[y])
	print("who wins, level %d, %d seed(s), every pairing both ways round:" % [level, seeds])
	for id: String in leads:
		print("  %-8s %3d of %3d  %3.0f%%" % [id, wins[id], bouts[id], 100.0 * wins[id] / bouts[id]])
	seconds.sort()
	print("bouts: %d, timed out: %d, seconds: shortest %.0f, middle %.0f, longest %.0f" % [
		seconds.size(), draws, seconds[0], seconds[seconds.size() / 2], seconds[-1]])


func _parse(args: PackedStringArray) -> Dictionary:
	var out := {}
	for arg in args:
		if not arg.begins_with("--"):
			continue
		var pair := arg.trim_prefix("--").split("=", true, 1)
		out[pair[0]] = pair[1] if pair.size() > 1 else ""
	return out
