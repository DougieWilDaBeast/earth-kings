class_name BattleHUD
extends CanvasLayer
## Battle UI: turn order, the active unit's command menu, an inspector for the
## hovered tile, and the combat log. Emits intent only — the controller decides.

signal move_requested
signal ability_requested(ability_id: String)
signal wait_requested

const LOG_LINES := 4

@onready var _turn_label: Label = %TurnLabel
@onready var _order_label: Label = %TurnOrderLabel
@onready var _inspect_label: Label = %InspectLabel
@onready var _log_label: Label = %LogLabel
@onready var _commands: VBoxContainer = %Commands
@onready var _abilities: VBoxContainer = %Abilities
@onready var _move_button: Button = %MoveButton
@onready var _wait_button: Button = %WaitButton
@onready var _result_label: Label = %ResultLabel

var _log: Array[String] = []


func _ready() -> void:
	_move_button.pressed.connect(func() -> void: move_requested.emit())
	_wait_button.pressed.connect(func() -> void: wait_requested.emit())
	_commands.hide()
	_result_label.hide()
	EventBus.battle_log.connect(_append_log)


func show_commands(unit: Unit) -> void:
	_turn_label.text = "%s's turn  ·  %s  ·  HP %d/%d" % [
		unit.display_name, unit.job, unit.hp, unit.max_hp
	]
	_move_button.disabled = unit.has_moved
	_rebuild_ability_buttons(unit)
	_commands.show()


func hide_commands() -> void:
	_commands.hide()


func set_turn_order(order: Array[Unit]) -> void:
	var names := order.map(func(u: Unit) -> String: return u.display_name)
	_order_label.text = "Next: " + " → ".join(names)


func set_inspected(unit: Unit, terrain: Dictionary) -> void:
	if unit != null:
		_inspect_label.text = "%s (%s)  HP %d/%d  ATK %d  DEF %d  MOV %d  JMP %d%s" % [
			unit.display_name, unit.job, unit.hp, unit.max_hp,
			unit.attack, unit.defense, unit.move_points, unit.jump,
			"" if unit.weapon.is_empty() else "  ·  " + str(unit.weapon.get("display_name", ""))
		]
	elif not terrain.is_empty():
		_inspect_label.text = "%s  ·  move cost %d  ·  height %d" % [
			terrain.get("name", "Terrain"),
			int(terrain.get("move_cost", 1)),
			int(terrain.get("height", 0)),
		]
	else:
		_inspect_label.text = ""


func show_result(victory: bool) -> void:
	_result_label.text = "Victory" if victory else "Defeat"
	_result_label.show()


func _rebuild_ability_buttons(unit: Unit) -> void:
	for child in _abilities.get_children():
		child.queue_free()
	for ability_id: String in unit.abilities:
		var ability := Database.ability(ability_id)
		var button := Button.new()
		button.text = ability.get("display_name", ability_id)
		button.tooltip_text = ability.get("description", "")
		button.disabled = unit.has_acted
		button.pressed.connect(func() -> void: ability_requested.emit(ability_id))
		_abilities.add_child(button)


func _append_log(line: String) -> void:
	_log.append(line)
	if _log.size() > LOG_LINES:
		_log = _log.slice(_log.size() - LOG_LINES)
	_log_label.text = "\n".join(_log)
