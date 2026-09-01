extends Node
## Headless check on the thread engine: ignition off world state, stage advance,
## deadlines routing somewhere worse, tags, and a save/load round trip.
##
##   godot --headless --path . res://tests/skein_smoke_test.tscn
##
## Runs as a scene rather than with `-s`, because `--script` runs before the
## autoloads (EventBus / Database / GameState) exist.

const SEED := 20260829

var _failures: Array[String] = []


func _ready() -> void:
	var world := WorldGen.generate(SEED)
	_check_content()
	_check_ignition(world)
	_check_advance(world)
	_check_no_runaway(world)
	_check_round_trip(world)

	print("")
	if _failures.is_empty():
		print("skein smoke test: PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			print("  FAIL  %s" % failure)
		print("skein smoke test: %d failure(s)" % _failures.size())
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


# --- content ------------------------------------------------------------------


## Every condition and effect a thread names has to be one the engine knows,
## or the thread silently never fires and nobody finds out for a month.
func _check_content() -> void:
	var known_when := [
		"steps_since_stage", "steps_since_start", "deed", "count", "arrive_kind",
		"battle_won", "character_dead", "standing_below", "standing_above",
		"tag", "remembers", "thread_done",
	]
	var known_then := ["rumour", "at", "weight", "hint", "remember", "tag", "untag", "errand", "site"]

	_expect(not Skein.definitions().is_empty(), "no threads loaded from data/threads.json")
	for thread_id: String in Skein.definitions():
		var definition: Dictionary = Skein.definitions()[thread_id]
		var stages: Array = definition.get("stages", [])
		_expect(not stages.is_empty(), "%s has no stages" % thread_id)
		for key: String in definition.get("ignite", {}):
			_expect(known_when.has(key), "%s ignites on unknown condition '%s'" % [thread_id, key])
		for stage: Dictionary in stages:
			for key: String in stage.get("when", {}):
				_expect(known_when.has(key), "%s/%s: unknown condition '%s'" % [thread_id, stage.get("id", "?"), key])
			for effect: Dictionary in stage.get("then", []):
				for key: String in effect:
					_expect(known_then.has(key), "%s/%s: unknown effect '%s'" % [thread_id, stage.get("id", "?"), key])
			var goto := String(stage.get("goto", ""))
			if goto != "":
				var found := stages.any(func(s: Dictionary) -> bool: return String(s.get("id", "")) == goto)
				_expect(found, "%s/%s points at missing stage '%s'" % [thread_id, stage.get("id", "?"), goto])


# --- behaviour ----------------------------------------------------------------


func _check_ignition(world: World) -> void:
	world.threads.clear()
	Skein.on_step(world)
	_expect(not world.threads.has("the_gatewarden"), "the_gatewarden ignited with no gates shut")

	Renown.record(world, Renown.GATE_SHUT, world.player_cell, 4, "a gate was shut")
	Renown.record(world, Renown.GATE_SHUT, world.player_cell, 4, "another gate was shut")
	Skein.on_step(world)
	_expect(world.threads.has("the_gatewarden"), "the_gatewarden did not ignite on two shut gates")
	_expect(Skein.is_live(world, "the_gatewarden"), "the_gatewarden ignited already finished")


func _check_advance(world: World) -> void:
	var before := world.deeds.size()
	world.steps += 60
	Skein.on_step(world)
	_expect(
		int(world.threads["the_gatewarden"].get("stage", 0)) >= 1,
		"the_gatewarden did not leave its first stage after 60 steps"
	)
	_expect(world.deeds.size() > before, "advancing wrote no rumour")
	_expect(Skein.has_tag(world, "watched"), "the 'watched' tag was not set")


## A stage that fires every tick would empty the whole thread in one step.
func _check_no_runaway(world: World) -> void:
	var stage := int(world.threads["the_gatewarden"].get("stage", 0))
	Skein.on_step(world)
	Skein.on_step(world)
	_expect(
		int(world.threads["the_gatewarden"].get("stage", 0)) == stage,
		"a stage advanced with no time passing and no occasion"
	)


func _check_round_trip(world: World) -> void:
	var text := JSON.stringify(world.to_dict())
	var restored := World.from_dict(JSON.parse_string(text))
	_expect(restored.threads.size() == world.threads.size(), "threads lost across a save/load")
	_expect(
		int(restored.threads.get("the_gatewarden", {}).get("stage", -1))
			== int(world.threads["the_gatewarden"].get("stage", 0)),
		"thread stage did not survive a save/load"
	)
	_expect(
		Skein.has_tag(restored, "watched"),
		"thread tags did not survive a save/load"
	)
