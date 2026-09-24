extends Node
## Lets the real game play itself for a while, then says what it saw.
##
##   godot --headless --path . res://tools/soak.tscn -- --seconds=300 --seed=77
##
## Boots the whole game, starts a run and turns on autoplay at ×4. Every thirty
## seconds it prints where the run has got to. A pause autoplay makes on purpose
## (somebody else's fight on the road) is waited out for three seconds and then
## walked away from, so one wagon does not end the soak. At the end it saves,
## loads and saves again and says whether the two files match.
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


func _ready() -> void:
	var seconds := 240.0
	var world_seed := 4242
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="):
			seconds = float(arg.trim_prefix("--seconds="))
		elif arg.begins_with("--seed="):
			world_seed = int(arg.trim_prefix("--seed="))

	_root = load("res://src/main.tscn").instantiate()
	add_child(_root)
	EventBus.scene_changed.connect(func(key: String) -> void: _scenes[key] = int(_scenes.get(key, 0)) + 1)
	EventBus.battle_log.connect(func(_line: String) -> void: _lines += 1)
	await get_tree().process_frame
	GameState.new_game(world_seed)
	EventBus.request_scene.emit("world", {})
	await get_tree().create_timer(1.0, true, false, true).timeout
	Pace.auto = true
	Pace.cycle_speed()
	Pace.cycle_speed()

	var start := Time.get_ticks_msec()
	var last_report := start
	while (Time.get_ticks_msec() - start) / 1000.0 < seconds:
		await get_tree().process_frame
		if Pace.auto:
			_off = 0
		else:
			_off += 1
			if _off > PATIENCE:
				_off = 0
				_walked_on += 1
				Pace.auto = true
		if _stuck():
			get_tree().quit(2)
			return
		if Time.get_ticks_msec() - last_report > 30000:
			last_report = Time.get_ticks_msec()
			_report(start)
	_report(start)

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
	print("STUCK for %ds at step %d in %s%s" % [
		int(STUCK_AFTER), GameState.world.steps, scene.name,
		" (phase %s)" % str(scene.get("phase")) if "phase" in scene else "",
	])
	return true
