extends Node
## How long a gate takes, by rank (play-test 7, D261: "an S tier gate will take a long time, maybe 10
## minutes and 10, 15 minutes and the boss fight is tough ... 5 to 7 1/2 minutes").
##
##   godot --headless --path . res://tools/gate_clock.tscn -- --rank=S [--speed=5] [--seed=77]
##       [--lead=juno] [--with=pluto,vesta,atlas] [--above=0] [--rested]
##
## Boots the whole game, puts a party of four (play-test 7's) at the level the gate's rank asks for
## (Site.expected_level, plus `--above`) at a gate of that rank, goes in and lets Auto walk it at
## `--speed`. Says, in the player's seconds at 1× (the clock times the speed), how long the gate took
## from the doorway to shut, how long its keeper's fight ran, how many fights, and whether anyone fell.
## `--rested` puts the party back to full health after every won fight, as a player who drinks and
## rests between fights would: it times a gate's length, not whether the party lasts it.
## Headless, like the soak: read the numbers as the game's own clock, not a browser's.

const STUCK_AFTER := 60.0

var _fights: Array = []
var _lost := false
var _rested := false
var _fight_began := 0
var _scenes := 0


func _ready() -> void:
	var rank := "E"
	var speed := 5.0
	var world_seed := 77
	var lead := "juno"
	var joined := ["pluto", "vesta", "atlas"]
	var above := 0
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--rank="):
			rank = arg.trim_prefix("--rank=").to_upper()
		elif arg.begins_with("--speed="):
			speed = float(arg.trim_prefix("--speed="))
		elif arg.begins_with("--seed="):
			world_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--lead="):
			lead = arg.trim_prefix("--lead=")
		elif arg == "--rested":
			_rested = true
		elif arg.begins_with("--with="):
			joined = Array(arg.trim_prefix("--with=").split(","))
		elif arg.begins_with("--above="):
			above = int(arg.trim_prefix("--above="))
	var root: Node = load("res://src/main.tscn").instantiate()
	add_child(root)
	EventBus.battle_started.connect(func(_id: String) -> void: _fight_began = Time.get_ticks_msec())
	EventBus.battle_finished.connect(func(result: Dictionary) -> void:
		_fights.append((Time.get_ticks_msec() - _fight_began) / 1000.0)
		_lost = _lost or not bool(result.get("victory", false))
		if _rested and not _lost:
			for hero: Character in GameState.party_characters():
				hero.hp = hero.max_hp())
	EventBus.scene_changed.connect(func(_key: String) -> void: _scenes += 1)
	await get_tree().process_frame
	GameState.new_game(world_seed, lead)
	GameState.set_flag("seen:prologue")
	var world: World = GameState.world
	for id: String in joined:
		var character := GameState.roster.add(Character.create(id))
		GameState.roster.party.append(character.id)
	var gate: Site = world.sites_of_kind(Site.GATE)[0]
	gate.rank = rank
	if not gate.open:
		world.open_gate(gate)
	world.prowlers.clear()
	world.player_cell = gate.cell
	var level := gate.expected_level() + above
	for hero: Character in GameState.party_characters():
		Progression.raise_quietly(hero, level, world)
		hero.hp = hero.max_hp()
	EventBus.request_scene.emit("world", {})
	await get_tree().create_timer(2.0, true, false, true).timeout
	for i in Pace.SPEEDS.size():
		if is_equal_approx(Pace.speed(), speed):
			break
		Pace.cycle_speed()
	var front := get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)
	front.call("_do_act", { "act": "_enter_gate_here" })
	var start := Time.get_ticks_msec()
	Pace.auto = true
	var last_change := start
	var seen := [_scenes, _fights.size()]
	var outcome := "stuck"
	while true:
		await get_tree().process_frame
		Pace.auto = true
		if gate.cleared:
			outcome = "shut"
			break
		if GameState.roster.run_is_over():
			outcome = "the lead fell"
			break
		if _lost:
			outcome = "a fight lost"
			break
		if [_scenes, _fights.size()] != seen:
			seen = [_scenes, _fights.size()]
			last_change = Time.get_ticks_msec()
		if (Time.get_ticks_msec() - last_change) / 1000.0 > STUCK_AFTER:
			_say_where_stuck()
			break
	var took := (Time.get_ticks_msec() - start) / 1000.0 * speed
	var fallen := 0
	for hero: Character in GameState.party_characters():
		fallen += 1 if hero.hp <= 0 else 0
	var longest := 0.0
	for each: float in _fights:
		longest = maxf(longest, each)
	print("GATE %s (%d floors) at level %d, %s: %s at 1x, %d fights, the last %s, the longest %s; %d of the party down" % [
		rank, gate.floors(), level, outcome, _clock(took), _fights.size(),
		_clock(float(_fights.back()) * speed if not _fights.is_empty() else 0.0), _clock(longest * speed), fallen])
	get_tree().quit(0 if outcome == "shut" else 1)


func _clock(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]


## Where the walk stopped: the floor, the lead's cell and the bands still standing, for whoever reads the log.
func _say_where_stuck() -> void:
	var front := get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)
	if front == null or not ("map" in front):
		print("STUCK outside a floor: %s" % [front])
		return
	var bands: Array = front.call("_standing_bands") if front.has_method("_standing_bands") else []
	print("STUCK on %s, last cell %s, Auto aiming at %s; bands standing %s; way down %s" % [
		front.get("map").get("key") if front.get("map") is Object and "key" in front.get("map") else "?",
		front.get("_last_cell"), front.get("_auto_band_target"),
		bands.map(func(band: Dictionary) -> String: return "%s@%s" % [band.get("key"), band.get("at")]),
		front.call("_way_down_open") if front.has_method("_way_down_open") else "?"])
	print("STUCK state: awaiting fight %s, fight %s, talking %s, leaving %s, exit path %d, band path %d, auto %s, party hp %s" % [
		front.get("_awaiting_fight"), front.get("_fight"), front.get("_talking"), front.get("_leaving"),
		(front.get("_auto_exit_path") as Array).size(), (front.get("_auto_band_path") as Array).size(), Pace.auto,
		GameState.party_characters().map(func(hero: Character) -> String: return "%s %d" % [hero.id, hero.hp])])
