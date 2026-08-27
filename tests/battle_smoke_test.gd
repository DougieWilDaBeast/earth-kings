extends Node
## Headless smoke test: boots a battle and auto-passes every player turn so the
## turn loop, enemy AI, damage resolution and win/lose check all execute.
##
##   godot --headless --path . res://tests/battle_smoke_test.tscn
##
## Run as a scene rather than with `-s`, because `--script` runs before the
## autoloads (EventBus / Database / GameState) exist.

const MAX_TURNS := 300

var _battle: Node
var _turns := 0


func _ready() -> void:
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.battle_log.connect(func(line: String) -> void: print(line))
	EventBus.battle_finished.connect(_on_battle_finished)

	_battle = load("res://src/battle/battle.tscn").instantiate()
	add_child(_battle)


func _on_turn_started(unit: Node) -> void:
	_turns += 1
	if _turns > MAX_TURNS:
		push_error("Smoke test: battle did not resolve within %d turns" % MAX_TURNS)
		get_tree().quit(1)
		return
	if unit.team == Unit.Team.PLAYER:
		# Deferred so the controller finishes entering the command phase first.
		_battle.hud.wait_requested.emit.call_deferred()


func _on_battle_finished(result: Dictionary) -> void:
	print("Battle finished after %d turns - victory: %s" % [_turns, result["victory"]])
	get_tree().quit(0)
