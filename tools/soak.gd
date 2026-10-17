extends Node
## Lets the real game play itself for a while, then says what it saw.
##
##   godot --headless --path . res://tools/soak.tscn -- --seconds=300 --seed=77 [--lead=cato]
##
## Boots the whole game, starts a run led by whoever the quiz deals from the seed (D197; `--lead`
## to choose), and turns on autoplay at ×2. It says when Auto first stood at the Tower's door. Every thirty
## seconds it prints where the run has got to. A pause autoplay makes on purpose
## (somebody else's fight on the road) is waited out for three seconds and then
## walked away from, so one wagon does not end the soak. If the lead dies the run
## is over and the game waits on the player at the run summary: the soak says
## `RUN OVER at step N` and stops there, since a death is the game working, not
## stuck. At the end it saves, loads and saves again and says whether the two
## files match.
##
## What to look for: `SCRIPT ERROR` anywhere in the output, steps that stop
## rising (something is waiting on a key nobody is pressing), steps that rise
## with no fights (autoplay has nowhere to go), and a save that is not the same
## twice. It is not a suite — battles use unseeded dice, so no two soaks match —
## but it finds what no suite is looking for: the first ones turned up bounties
## that could not be posted, autoplay pacing in front of a wall, and saves that
## changed every time they were loaded.
##
## It overwrites the save in `user://`, as the suites do.
##
## Lag (D122): every frame is timed, and the five longest are printed at the end with what was
## happening (a step on the land, a fight starting, a scene changing), so the worst hitch has a
## name. Headless frames carry no drawing, so read them as where the work is, not as what a
## browser feels.

const AutoRoad := preload("res://src/world/auto_road.gd")

## Frames autoplay may sit switched off before the soak switches it back on.
const PATIENCE := 180
## Seconds of autoplay with no step taken and no line logged before the soak
## calls it stuck, says where, and stops.
const STUCK_AFTER := 30.0

var _root: Node
var _scenes: Dictionary = {}
var _lines := 0
var _off := 0
var _walked_on := 0
var _last_moved := ""
var _last_moved_at := 0
## The longest frames: `{ ms, what }`, longest first.
var _hitches: Array[Dictionary] = []
var _fights := 0
## When the party first stood at the Tower's door, or went in ([D197]: no run reached it in 15 minutes).
var _at_door := ""


func _ready() -> void:
	var seconds := 240.0
	var world_seed := 4242
	var lead := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="):
			seconds = float(arg.trim_prefix("--seconds="))
		elif arg.begins_with("--seed="):
			world_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--lead="):
			lead = arg.trim_prefix("--lead=")
	# The lead the quiz deals from the seed, as a player after the last stand gets (D197), unless
	# one is asked for: a bot that only plays Atlas plays a life nobody lives.
	if lead == "":
		lead = FirstHour.dealt_lead(world_seed)

	_root = load("res://src/main.tscn").instantiate()
	add_child(_root)
	EventBus.scene_changed.connect(func(key: String) -> void: _scenes[key] = int(_scenes.get(key, 0)) + 1)
	EventBus.battle_log.connect(func(_line: String) -> void: _lines += 1)
	EventBus.battle_started.connect(func(_id: String) -> void: _fights += 1)
	await get_tree().process_frame
	GameState.new_game(world_seed, lead)
	EventBus.request_scene.emit("world", {})
	await get_tree().create_timer(1.0, true, false, true).timeout
	Pace.auto = true
	# 2×, as it has always soaked (the steps are 1×, 2×, 3×, 5× since D189).
	Pace.cycle_speed()

	var start := Time.get_ticks_msec()
	var last_report := start
	var tick := Time.get_ticks_usec()
	var before := _moment()
	while (Time.get_ticks_msec() - start) / 1000.0 < seconds:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var after := _moment()
		_time_frame((now - tick) / 1000.0, before, after)
		tick = now
		before = after
		if Pace.auto:
			_off = 0
		else:
			_off += 1
			if _off > PATIENCE:
				_off = 0
				_walked_on += 1
				Pace.auto = true
		if _at_door == "":
			_look_for_the_door(start)
		if _run_over():
			break
		if _stuck():
			get_tree().quit(2)
			return
		if Time.get_ticks_msec() - last_report > 30000:
			last_report = Time.get_ticks_msec()
			_report(start)
	_report(start)
	var said: Array[String] = []
	for hitch: Dictionary in _hitches:
		said.append("%d ms %s" % [int(hitch["ms"]), hitch["what"]])
	print("longest frames: %s" % ", ".join(said))
	print("the Tower's door: %s" % (_at_door if _at_door != "" else "never reached"))

	GameState.save()
	var first := FileAccess.get_file_as_string(GameState.SAVE_PATH)
	GameState.load_save()
	GameState.save()
	var second := FileAccess.get_file_as_string(GameState.SAVE_PATH)
	print("save, load, save the same file: %s (%d chars)" % [first == second, first.length()])
	if first != second:
		var a := first.split("\n")
		var b := second.split("\n")
		var shown := 0
		for i in mini(a.size(), b.size()):
			if a[i] != b[i] and shown < 20:
				print("  - %s\n  + %s" % [a[i].strip_edges(), b[i].strip_edges()])
				shown += 1
	get_tree().quit(0 if first == second else 1)


## What the game is doing, to tell one frame's work from the next.
func _moment() -> Dictionary:
	var scene: Node = _root.get_node("CurrentScene").get_child(0) if _root.get_node("CurrentScene").get_child_count() > 0 else null
	return {
		"scene": str(scene.name) if scene != null else "-", "steps": GameState.world.steps if GameState.world else 0,
		"fights": _fights, "id": scene.get_instance_id() if scene != null else 0,
	}


func _time_frame(ms: float, before: Dictionary, after: Dictionary) -> void:
	if _hitches.size() >= 5 and ms <= float(_hitches[-1]["ms"]):
		return
	var what := "walking"
	if int(after["fights"]) != int(before["fights"]):
		what = "a fight starting"
	elif int(after["id"]) != int(before["id"]):
		what = "%s -> %s" % [before["scene"], after["scene"]]
	elif int(after["steps"]) != int(before["steps"]):
		what = "a step on the land (step %d)" % int(after["steps"])
	elif str(after["scene"]) != "Area":
		what = "in %s" % after["scene"]
	_hitches.append({ "ms": ms, "what": what })
	_hitches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["ms"]) > float(b["ms"]))
	if _hitches.size() > 5:
		_hitches.resize(5)


func _report(start: int) -> void:
	var world: World = GameState.world
	var lead := GameState.roster.player()
	var open_gates := world.sites.filter(
		func(site: Site) -> bool: return site.kind == Site.GATE and site.open and not site.cleared
	).size()
	print("%3ds  steps %d  %s  log %d  %s L%d  gold %d  party %d  away %d  gates open %d  tower %d  walked on %d%s" % [
		(Time.get_ticks_msec() - start) / 1000, world.steps, _scenes, _lines,
		lead.display_name if lead else "-", lead.level if lead else 0, GameState.gold,
		GameState.roster.party.size(), GameState.away.size(), open_gates, world.tower_floor, _walked_on,
		"  RUN OVER" if GameState.roster.run_is_over() else "",
	])
	print("      making for %s from %s" % [AutoRoad.objective(world).get("label", "nowhere"), world.player_cell])


## Noted once: the first moment Auto stood at the Tower's door, or the party was inside it.
func _look_for_the_door(start: int) -> void:
	var holder := _root.get_node("CurrentScene")
	var scene: Node = holder.get_child(0) if holder.get_child_count() > 0 else null
	var at_door: bool = scene != null and scene.get("_auto_at_door") == true
	if not at_door and GameState.world.tower_floor <= 0:
		return
	_at_door = "reached at %ds, step %d" % [(Time.get_ticks_msec() - start) / 1000, GameState.world.steps]
	print("THE TOWER'S DOOR %s" % _at_door)


## True, having said so, once the lead has died and the run summary is up: the
## game is waiting on the player to choose the next lead, as it should.
func _run_over() -> bool:
	if not GameState.roster.run_is_over():
		return false
	var holder := _root.get_node("CurrentScene")
	if holder.get_child_count() == 0 or str(holder.get_child(0).name) != "RunSummary":
		return false
	print("RUN OVER at step %d: the lead fell, and the soak stops at the run summary" % GameState.world.steps)
	return true


## True, having said where, once autoplay has gone [constant STUCK_AFTER]
## seconds without a step or a line.
func _stuck() -> bool:
	var moved := "%d/%d" % [GameState.world.steps, _lines]
	if moved != _last_moved or not Pace.auto:
		_last_moved = moved
		_last_moved_at = Time.get_ticks_msec()
		return false
	if Time.get_ticks_msec() - _last_moved_at < STUCK_AFTER * 1000.0:
		return false
	var scene: Node = _root.get_node("CurrentScene").get_child(0)
	if "_auto_exit_path" in scene:
		# What Auto was walking at, so a stop can be told from a wall (D197: a way kept after a fight).
		var path: Array = scene.get("_auto_exit_path")
		print("  Auto was at %s, %d of %d along its way%s" % [
			scene.get("_leader").position, int(scene.get("_auto_exit_index")), path.size(),
			", busy (talking, leaving or asking)" if scene.get("_talking") or scene.get("_leaving") or scene.get("_asking") else "",
		])
	print("STUCK for %ds at step %d in %s%s" % [
		int(STUCK_AFTER), GameState.world.steps, scene.name,
		" (phase %s)" % str(scene.get("phase")) if "phase" in scene else "",
	])
	return true
