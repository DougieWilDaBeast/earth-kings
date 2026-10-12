class_name BattleHUD
extends CanvasLayer
## Battle UI: turn order, the active unit's command menu, an inspector for the
## hovered tile, and the combat log. Emits intent only — the controller decides.

signal move_requested
signal flash_step_requested
signal ability_requested(ability_id: String)
signal draught_requested(item_id: String)
signal wait_requested
## A command is hovered but not chosen; [param kind] is move, flash or ability.
signal preview_requested(kind: String, ability_id: String)
signal preview_cleared
## The player handed the fight to the AI, or took it back.
signal auto_toggled(enabled: bool)
signal speed_cycled
## Back out of a half-given order without giving it.
signal cancel_requested

const LOG_LINES := 4
const PIP_FULL := "•"
const PIP_SPENT := "◊"
const SELECTED_COLOUR := "#ffdb57"
const SPENT_COLOUR := "#7d838f"
## Shown along the bottom whenever nothing is being hovered.
const CONTROL_HINT := "Hover a command to preview it  ·  pick another to switch  ·  wheel to zoom  ·  middle-drag to pan  ·  C to recentre"
## The same, for a pad: the commands are walked with the D-pad, and a tile is
## picked with a cursor rather than a mouse.
const PAD_HINT := "D-pad to pick a command  ·  %s to choose  ·  stick to aim, %s to confirm, %s to back out  ·  %s next fighter  ·  %s to wait  ·  %s speed  ·  LT / RT zoom  ·  right stick to look"

@onready var _turn_label: Label = %TurnLabel
@onready var _order_label: Label = %TurnOrderLabel
@onready var _squad_bar: RichTextLabel = %SquadBar
@onready var _inspect_label: Label = %InspectLabel
@onready var _log_label: Label = %LogLabel
@onready var _commands: VBoxContainer = %Commands
@onready var _abilities: VBoxContainer = %Abilities
@onready var _move_button: Button = %MoveButton
@onready var _flash_button: Button = %FlashStepButton
@onready var _wait_button: Button = %WaitButton
@onready var _cancel_button: Button = %CancelButton
@onready var _auto_button: Button = %AutoButton
@onready var _speed_button: Button = %SpeedButton
@onready var _result_label: Label = %ResultLabel

var _log: Array[String] = []


func _ready() -> void:
	_move_button.pressed.connect(func() -> void: move_requested.emit())
	_flash_button.pressed.connect(func() -> void: flash_step_requested.emit())
	_wait_button.pressed.connect(func() -> void: wait_requested.emit())
	_cancel_button.pressed.connect(func() -> void: cancel_requested.emit())
	# Escape and a right-click were the only ways out of a half-given order,
	# and a touchscreen has neither.
	_cancel_button.hide()
	_watch_hover(_move_button, "move", "")
	_watch_hover(_flash_button, "flash", "")
	_auto_button.toggled.connect(func(on: bool) -> void: auto_toggled.emit(on))
	_speed_button.pressed.connect(func() -> void: speed_cycled.emit())
	# Buttons hold no focus off a pad, or the arrow keys would walk the menu
	# instead of the camera. On a pad, focus is how a command is chosen.
	_set_focusable()
	Pad.changed.connect(_on_pad_changed)
	# The touch overlay keeps a bar of its own along the top right, so the
	# fight's own tools step down out from under it.
	if Pace.is_touch_enabled():
		var tools: Control = _auto_button.get_parent()
		tools.offset_top += TouchControls.BAR_DROP
		tools.offset_bottom += TouchControls.BAR_DROP
	_commands.hide()
	_squad_bar.text = ""
	_result_label.hide()
	EventBus.battle_log.connect(_append_log)
	if Pad.using_pad:
		_on_pad_changed.call_deferred()


func show_commands(unit: Unit) -> void:
	_turn_label.text = "%s's turn  ·  %s  ·  HP %d/%d" % [
		unit.display_name, unit.job, unit.hp, unit.max_hp
	]
	_move_button.disabled = not unit.can_move()
	_flash_button.visible = unit.flash_step > 0
	_flash_button.disabled = not unit.can_flash_step()
	_flash_button.text = "Flash Step%s  ·  %d" % [_key_suffix("command_flash_step"), unit.flash_step]
	_rebuild_ability_buttons(unit)
	_rebuild_draught_buttons(unit)
	_commands.show()
	_set_focusable()
	if Pad.using_pad:
		_focus_first_command()


func _rebuild_draught_buttons(unit: Unit) -> void:
	if unit.team != Unit.Team.PLAYER:
		return
	var draughts := Gear.draughts()
	if draughts.is_empty():
		return
	var can_drink := unit.hp < unit.max_hp and unit.can_drink_draught()
	for item_id: String in draughts:
		var button := Button.new()
		var mends := mini(Gear.mends(item_id), unit.max_hp - unit.hp)
		button.text = "Drink %s (+%d HP) [%d/%d]" % [
			Gear.display_name(item_id), mends, unit.draughts_used, Unit.COMBAT_POUCH_LIMIT
		]
		button.tooltip_text = "Spend bonus action to recover %d HP (combat pouch: %d/%d used)." % [
			mends, unit.draughts_used, Unit.COMBAT_POUCH_LIMIT
		]
		button.disabled = not can_drink
		button.focus_mode = Control.FOCUS_ALL if Pad.using_pad else Control.FOCUS_NONE
		button.pressed.connect(func() -> void: draught_requested.emit(item_id))
		_abilities.add_child(button)


## The squad taking this phase, with each member's remaining action and bonus action.
func set_squad(squad: Array[Unit], selected: Unit) -> void:
	if squad.is_empty():
		_squad_bar.text = ""
		return
	var parts: Array[String] = []
	for unit in squad:
		var pips := "%s%s" % [
			PIP_FULL if not unit.action_spent else PIP_SPENT,
			PIP_FULL if not unit.bonus_spent else PIP_SPENT,
		]
		var entry := "%s %s" % [unit.display_name, pips]
		if unit == selected:
			entry = "[color=%s]› %s[/color]" % [SELECTED_COLOUR, entry]
		elif unit.is_done():
			entry = "[color=%s]%s[/color]" % [SPENT_COLOUR, entry]
		parts.append(entry)
	var hint := ""
	if squad.size() > 1:
		hint = "   [color=%s][%s] switch[/color]" % [SPENT_COLOUR, Pad.key("cycle_next")]
	_squad_bar.text = "   ".join(parts) + hint


func hide_commands() -> void:
	_drop_focus()
	_commands.hide()
	preview_cleared.emit()


## Backing out is only offered while there is a half-given order to back out
## of; on the command menu itself there is nothing to cancel.
func set_picking(picking: bool) -> void:
	_cancel_button.visible = picking
	# While a tile is being picked the stick steers the cursor, not the menu.
	if picking:
		_drop_focus()


func set_auto(enabled: bool) -> void:
	_auto_button.set_pressed_no_signal(enabled)
	_auto_button.text = ("Auto: on%s" if enabled else "Auto%s") % _key_suffix("battle_auto")


func set_speed(scale: float) -> void:
	_speed_button.text = "Speed x%s%s" % [String.num(scale, 1).trim_suffix(".0"), _key_suffix("battle_speed")]


func set_turn_order(order: Array[Unit]) -> void:
	var names := order.map(func(u: Unit) -> String:
		return "Your party" if u.team == Unit.Team.PLAYER else u.display_name
	)
	_order_label.text = "Next: " + " › ".join(names)


func set_inspected(unit: Unit, terrain: Dictionary) -> void:
	if unit != null:
		if unit.team == Unit.Team.ENEMY and GameState.world != null:
			var world := GameState.world
			var tid := unit.template_id
			var hp_str := "%d/%d" % [unit.hp, unit.max_hp] if Journal.is_felled(world, tid) else "%d/?" % unit.hp
			var atk_str := str(unit.attack) if Journal.is_struck(world, tid) else "?"
			var def_str := str(unit.defense) if Journal.is_wounded(world, tid) else "?"
			var known_abils := Journal.known_abilities(world, tid)
			var abil_summary := ""
			if not known_abils.is_empty():
				var names: Array[String] = []
				for aid: String in known_abils:
					names.append(Database.ability(aid).get("display_name", aid))
				abil_summary = "  ·  Known: " + ", ".join(names)
			_inspect_label.text = "%s (%s)  HP %s  ATK %s  DEF %s  MOV %d  JMP %d%s%s" % [
				unit.display_name, unit.job, hp_str, atk_str, def_str,
				unit.move_points, unit.jump,
				"" if unit.weapon.is_empty() else "  ·  " + str(unit.weapon.get("display_name", "")),
				abil_summary
			]
		else:
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
		_inspect_label.text = _control_hint()


func show_result(victory: bool) -> void:
	_result_label.text = "Victory" if victory else "Defeat"
	_result_label.show()


func _rebuild_ability_buttons(unit: Unit) -> void:
	for child in _abilities.get_children():
		child.queue_free()
	for i in unit.abilities.size():
		var ability_id: String = unit.abilities[i]
		var ability := Database.ability(ability_id)
		var cost := Unit.ability_cost(ability)
		var button := Button.new()
		button.text = "%d. %s" % [i + 1, ability.get("display_name", ability_id)]
		if cost == Unit.Cost.BONUS:
			button.text += "  (bonus)"
		button.tooltip_text = ability.get("description", "")
		button.disabled = not unit.can_pay(cost)
		button.focus_mode = Control.FOCUS_ALL if Pad.using_pad else Control.FOCUS_NONE
		button.pressed.connect(func() -> void: ability_requested.emit(ability_id))
		_watch_hover(button, "ability", ability_id)
		_abilities.add_child(button)


## Hovering a command shows its range on the map; leaving it takes the range away.
func _watch_hover(button: Button, kind: String, ability_id: String) -> void:
	button.mouse_entered.connect(func() -> void: preview_requested.emit(kind, ability_id))
	button.mouse_exited.connect(func() -> void: preview_cleared.emit())
	# Landing on a command with the D-pad is a pad's hover.
	button.focus_entered.connect(func() -> void: preview_requested.emit(kind, ability_id))
	button.focus_exited.connect(func() -> void: preview_cleared.emit())


# --- the pad -----------------------------------------------------------------


## " (M)" on a keyboard, " (X)" on a pad, and nothing for a command the device
## has no button for: on a pad those are reached by focus.
func _key_suffix(action: String) -> String:
	var said := Pad.key(action)
	return "" if said == "" else " (%s)" % said


func _control_hint() -> String:
	if not Pad.using_pad:
		return CONTROL_HINT
	return PAD_HINT % [
		Pad.key("ui_accept"), Pad.key("ui_accept"), Pad.key("ui_cancel"),
		Pad.key("cycle_next"), Pad.key("command_wait"), Pad.key("battle_speed"),
	]


func _command_buttons() -> Array[Button]:
	var out: Array[Button] = [
		_move_button, _flash_button, _wait_button, _auto_button, _speed_button, _cancel_button,
	]
	for child in _abilities.get_children():
		if child is Button and not child.is_queued_for_deletion():
			out.append(child as Button)
	return out


func _set_focusable() -> void:
	for button in _command_buttons():
		button.focus_mode = Control.FOCUS_ALL if Pad.using_pad else Control.FOCUS_NONE


## Move first, as the command most turns start with; else whatever is left.
func _focus_first_command() -> void:
	var order: Array[Button] = [_move_button, _flash_button]
	for child in _abilities.get_children():
		if child is Button and not child.is_queued_for_deletion():
			order.append(child as Button)
	order.append(_wait_button)
	for button in order:
		if button.is_visible_in_tree() and not button.disabled:
			button.grab_focus()
			return


## A screen opened over the fight took the focus with it. Once it has gone,
## the command menu has it back, or the pad would have nothing to press.
func _process(_delta: float) -> void:
	if not Pad.using_pad or not _commands.visible or _cancel_button.visible:
		return
	if get_viewport().gui_get_focus_owner() == null and Pad.focus_root() == null:
		_focus_first_command()


func _drop_focus() -> void:
	var owner := get_viewport().gui_get_focus_owner()
	if owner != null and is_ancestor_of(owner):
		owner.release_focus()


func _on_pad_changed() -> void:
	_set_focusable()
	_cancel_button.text = "Cancel%s" % _key_suffix("ui_cancel")
	_move_button.text = "Move%s" % _key_suffix("command_move")
	_wait_button.text = "Wait%s" % _key_suffix("command_wait")
	set_auto(_auto_button.button_pressed)
	set_speed(Pace.speed())
	if not Pad.using_pad:
		_drop_focus()
	elif _commands.visible and not _cancel_button.visible:
		_focus_first_command()
	if _inspect_label.text == CONTROL_HINT or _inspect_label.text.begins_with("D-pad"):
		_inspect_label.text = _control_hint()


func _append_log(line: String) -> void:
	_log.append(line)
	if _log.size() > LOG_LINES:
		_log = _log.slice(_log.size() - LOG_LINES)
	_log_label.text = "\n".join(_log)
