extends CanvasLayer
## On-screen touch controller overlay for Android and mobile touchscreen play.
## Provides virtual D-pad steering and touch action buttons for party, journal,
## pace, cycle leader, and interaction.

@onready var _root: Control = $Root
@onready var _dpad: Control = %DPad
@onready var _knob: Control = %Knob
@onready var _action_cluster: Control = %ActionCluster

@onready var _interact_btn: Button = %InteractButton
@onready var _party_btn: Button = %PartyButton
@onready var _journal_btn: Button = %JournalButton
@onready var _cycle_btn: Button = %CycleButton
@onready var _menu_btn: Button = %MenuButton
@onready var _auto_btn: Button = %AutoButton
@onready var _speed_btn: Button = %SpeedButton

const DPAD_RADIUS := 64.0
const DEADZONE := 14.0

var _touch_index: int = -1
var _dpad_center: Vector2 = Vector2.ZERO
var _current_dir: Vector2i = Vector2i.ZERO
var _held_actions: Array[String] = []


func _ready() -> void:
	Pace.changed.connect(_update_state)
	EventBus.system_menu_requested.connect(_on_overlay_changed)
	EventBus.party_screen_requested.connect(_on_overlay_changed)
	EventBus.journal_requested.connect(_on_overlay_changed)
	EventBus.dialogue_finished.connect(func(_id: String) -> void: _set_cluster_visible(true))
	EventBus.dialogue_requested.connect(func(_id: String) -> void: _set_cluster_visible(false))
	EventBus.conversation_requested.connect(func(_lines: Array) -> void: _set_cluster_visible(false))

	_wire_buttons()
	_update_state()


func _wire_buttons() -> void:
	_interact_btn.pressed.connect(func() -> void: _emit_action("interact"))
	_party_btn.pressed.connect(func() -> void: EventBus.party_screen_requested.emit())
	_journal_btn.pressed.connect(func() -> void: EventBus.journal_requested.emit())
	_cycle_btn.pressed.connect(func() -> void: _emit_action("cycle_next"))
	_menu_btn.pressed.connect(func() -> void: EventBus.system_menu_requested.emit())
	_auto_btn.pressed.connect(func() -> void:
		Pace.auto = not Pace.auto
		_update_state()
	)
	_speed_btn.pressed.connect(func() -> void:
		Pace.cycle_speed()
		_update_state()
	)


func _update_state() -> void:
	var active := Pace.is_touch_enabled()
	_root.visible = active
	if not active:
		_reset_dpad()
		return
	_auto_btn.text = "Auto: On" if Pace.auto else "Auto"
	_speed_btn.text = "%dx" % int(Pace.speed())


func _on_overlay_changed() -> void:
	var overlay_open := false
	for node in get_tree().get_nodes_in_group(EventBus.MODAL_OVERLAY_GROUP):
		if node.has_method("is_open") and node.is_open():
			overlay_open = true
			break
	_root.visible = Pace.is_touch_enabled() and not overlay_open


func _set_cluster_visible(vis: bool) -> void:
	if not Pace.is_touch_enabled():
		_root.visible = false
		return
	_root.visible = vis
	if not vis:
		_reset_dpad()


func _input(event: InputEvent) -> void:
	if not _root.visible:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(touch: InputEventScreenTouch) -> void:
	var local_pos := _dpad.get_local_mouse_position()
	var center := _dpad.size * 0.5
	if touch.pressed:
		if _touch_index == -1 and local_pos.distance_to(center) <= DPAD_RADIUS * 1.5:
			_touch_index = touch.index
			_dpad_center = center
			_update_dpad_pos(local_pos)
	elif touch.index == _touch_index:
		_reset_dpad()


func _handle_drag(drag: InputEventScreenDrag) -> void:
	if drag.index == _touch_index:
		var local_pos := _dpad.get_local_mouse_position()
		_update_dpad_pos(local_pos)


func _update_dpad_pos(pos: Vector2) -> void:
	var delta := pos - _dpad_center
	var dist := delta.length()
	if dist > DPAD_RADIUS:
		delta = delta.normalized() * DPAD_RADIUS
	_knob.position = (_dpad.size * 0.5) + delta - (_knob.size * 0.5)

	if dist < DEADZONE:
		_apply_direction(Vector2i.ZERO)
		return

	# Convert 2D direction to cardinal / diagonal movement actions
	var norm := delta.normalized()
	var dir := Vector2i.ZERO
	if norm.x > 0.38:
		dir.x = 1
	elif norm.x < -0.38:
		dir.x = -1

	if norm.y > 0.38:
		dir.y = 1
	elif norm.y < -0.38:
		dir.y = -1

	_apply_direction(dir)


func _apply_direction(dir: Vector2i) -> void:
	if dir == _current_dir:
		return
	_current_dir = dir
	_release_all_movement()

	if dir.y < 0:
		_press_action("move_up")
	elif dir.y > 0:
		_press_action("move_down")

	if dir.x < 0:
		_press_action("move_left")
	elif dir.x > 0:
		_press_action("move_right")


func _press_action(action: String) -> void:
	if not _held_actions.has(action):
		_held_actions.append(action)
		Input.action_press(action)


func _release_all_movement() -> void:
	for action in _held_actions:
		Input.action_release(action)
	_held_actions.clear()


func _reset_dpad() -> void:
	_touch_index = -1
	_release_all_movement()
	_current_dir = Vector2i.ZERO
	_knob.position = (_dpad.size * 0.5) - (_knob.size * 0.5)


func _emit_action(action_name: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action_name
	ev.pressed = true
	Input.parse_input_event(ev)
	# Release next frame
	get_tree().create_timer(0.05).timeout.connect(func() -> void:
		var rel := InputEventAction.new()
		rel.action = action_name
		rel.pressed = false
		Input.parse_input_event(rel)
	)
