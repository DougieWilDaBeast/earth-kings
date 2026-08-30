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
var _switching_checked := false
var _auto_started := false


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
		if Pace.auto:
			return
		if not _switching_checked:
			_switching_checked = true
			# Deferred so the controller finishes entering the command phase first.
			_check_switching.call_deferred()
			return
		if not _auto_started:
			_auto_started = true
			# The rest of the fight is handed to auto battle and must still resolve.
			_start_auto.call_deferred()
			return
		# Deferred so the controller finishes entering the command phase first.
		_battle.hud.wait_requested.emit.call_deferred()


func _start_auto() -> void:
	_battle.hud.speed_cycled.emit()
	_battle.hud.auto_toggled.emit(true)
	if not Pace.auto:
		push_error("Smoke test: auto battle would not switch on")
		get_tree().quit(1)


## The whole party takes its phase together, and stepping away from someone
## mid-turn leaves what they have not spent alone.
func _check_switching() -> void:
	var living: Array = _battle.units.filter(
		func(u: Unit) -> bool: return u.is_alive() and u.team == Unit.Team.PLAYER
	)
	if _battle.squad.size() != living.size():
		push_error("Smoke test: %d of %d party members got the phase" % [
			_battle.squad.size(), living.size()
		])
		get_tree().quit(1)
		return

	var first: Unit = _battle.active_unit
	first.pay(Unit.Cost.BONUS)
	_battle._cycle_squad(1)
	var second: Unit = _battle.active_unit
	_battle._cycle_squad(-1)

	if second == first:
		push_error("Smoke test: Tab did not move off %s" % first.display_name)
		get_tree().quit(1)
		return
	if _battle.active_unit != first or first.action_spent:
		push_error("Smoke test: %s lost their action switching away and back" % first.display_name)
		get_tree().quit(1)
		return

	print("squad: %d act as one phase; %s kept their action across a switch to %s" % [
		living.size(), first.display_name, second.display_name
	])
	_battle.hud.wait_requested.emit()


func _on_battle_finished(result: Dictionary) -> void:
	print("Battle finished after %d turns - victory: %s (auto: %s)" % [
		_turns, result["victory"], Pace.auto
	])
	get_tree().quit(0)
