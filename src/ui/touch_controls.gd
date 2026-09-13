class_name TouchControls
extends CanvasLayer
## On-screen controls for Android and anything else played with a thumb.
##
## The overlay lays itself out from the scene that is up, because what belongs
## under a thumb on the road is in the way in a fight: the stick and the action
## cluster are for walking, and a battle is tapped on the board with its own
## commands down the side. While anything modal is open the whole thing steps
## aside, so it can never sit on top of a screen the player has to answer.

## How far the touch overlay pushes a scene's top-right corner down, so its own
## bar and the scene's own buttons are not fighting over the same strip.
const BAR_DROP := 70.0

## Scenes that are walked through, and so want the stick and the cluster.
const WALK_SCENES := ["world", "area", "training", "coliseum"]
## Scenes that want the bar at all. Everything else — the title, the character
## picker, the summary — is buttons already, and a stick over them is a trap.
const PLAY_SCENES := ["world", "area", "training", "coliseum", "battle"]

## How far the knob travels from the middle of the stick.
const STEER_RADIUS := 78.0
## Slop around the middle, so resting a thumb is not a step.
const DEADZONE := 18.0
## Clearance kept inside the screen's safe area, for rounded corners.
const EDGE_PAD := 14.0
## Past this much of a lean the axis counts, which leaves the corners as
## diagonals rather than making them a fight between two directions.
const LEAN := 0.38

@onready var _root: Control = %Root
@onready var _safe: Control = %Safe
@onready var _steer: Control = %Steer
@onready var _knob: Control = %Knob
@onready var _cluster: Control = %Cluster
@onready var _top_bar: HBoxContainer = %TopBar

@onready var _interact_btn: Button = %InteractButton
@onready var _back_btn: Button = %BackButton
@onready var _cycle_btn: Button = %CycleButton
@onready var _party_btn: Button = %PartyButton
@onready var _journal_btn: Button = %JournalButton
@onready var _menu_btn: Button = %MenuButton
@onready var _auto_btn: Button = %AutoButton
@onready var _speed_btn: Button = %SpeedButton

## The finger steering, if one is. Anything else on the glass is somebody
## else's — a second thumb on a button, or two fingers pinching the map.
var _finger: int = -1
var _current_dir: Vector2i = Vector2i.ZERO
var _held_actions: Array[String] = []
var _scene_key: String = "cinematic"


func _ready() -> void:
	_wire_buttons()
	Pace.changed.connect(_restate)
	EventBus.scene_changed.connect(_on_scene_changed)

	# Both edges of every overlay. Opening alone was never enough: the controls
	# went away when a screen was asked for and never came back when it shut.
	for opening: Signal in [
		EventBus.system_menu_requested, EventBus.party_screen_requested,
		EventBus.journal_requested, EventBus.stash_requested,
	]:
		opening.connect(_restate)
	EventBus.overlay_closed.connect(_restate)
	EventBus.dialogue_requested.connect(func(_id: String) -> void: _restate())
	EventBus.dialogue_finished.connect(func(_id: String) -> void: _restate())
	EventBus.conversation_requested.connect(func(_lines: Array) -> void: _restate())

	get_viewport().size_changed.connect(_fit_safe_area)
	_fit_safe_area()
	_restate()


func _wire_buttons() -> void:
	_interact_btn.pressed.connect(func() -> void: tap_action("interact"))
	_cycle_btn.pressed.connect(func() -> void: tap_action("cycle_next"))
	# Back is Escape, which every screen and every half-made battle order
	# already answers. Nothing had to learn a second key for it.
	_back_btn.pressed.connect(func() -> void: tap_action("ui_cancel"))
	_party_btn.pressed.connect(func() -> void: EventBus.party_screen_requested.emit())
	_journal_btn.pressed.connect(func() -> void: EventBus.journal_requested.emit())
	_menu_btn.pressed.connect(func() -> void: EventBus.system_menu_requested.emit())
	_auto_btn.pressed.connect(func() -> void:
		Pace.auto = not Pace.auto
		_restate()
	)
	_speed_btn.pressed.connect(func() -> void:
		Pace.cycle_speed()
		_restate()
	)
	for button: Button in [
		_interact_btn, _back_btn, _cycle_btn,
		_party_btn, _journal_btn, _menu_btn, _auto_btn, _speed_btn,
	]:
		Sfx.attend(button)


func _on_scene_changed(scene_key: String) -> void:
	_scene_key = scene_key
	_restate()


# --- what is shown, and where ------------------------------------------------


## Worked out again from scratch every time anything moves, rather than toggled
## from each place that might have changed it. Deferred because an overlay is
## only actually open a frame after it says it wants to be.
func _restate() -> void:
	_lay_out.call_deferred()


func _lay_out() -> void:
	if not is_inside_tree():
		return
	var playing := Pace.is_touch_enabled() and PLAY_SCENES.has(_scene_key) and not _overlay_open()
	var walking := playing and WALK_SCENES.has(_scene_key)

	_root.visible = playing
	_steer.visible = walking
	_cluster.visible = walking
	# A fight has its own auto and speed down the side of the board; two sets
	# of them on one screen is worse than none.
	_auto_btn.visible = walking
	_speed_btn.visible = walking
	_party_btn.visible = walking

	if not walking:
		_release_steering()
	_auto_btn.text = "Auto: On" if Pace.auto else "Auto"
	_speed_btn.text = "%dx" % int(Pace.speed())


func _overlay_open() -> bool:
	for node in get_tree().get_nodes_in_group(EventBus.MODAL_OVERLAY_GROUP):
		if node.has_method("is_open") and node.is_open():
			return true
	return false


## Phones keep a notch at one end and a gesture bar at the other, and a button
## under either cannot be pressed. The safe area is given in screen pixels, so
## it is scaled into the viewport the rest of the game is laid out in.
func _fit_safe_area() -> void:
	var left := EDGE_PAD
	var top := EDGE_PAD
	var right := EDGE_PAD
	var bottom := EDGE_PAD

	if OS.has_feature("android") or OS.has_feature("mobile"):
		var window := Vector2(DisplayServer.window_get_size())
		var view := get_viewport().get_visible_rect().size
		if window.x > 0.0 and window.y > 0.0:
			var safe := DisplayServer.get_display_safe_area()
			var scale := view / window
			left += maxf(0.0, float(safe.position.x)) * scale.x
			top += maxf(0.0, float(safe.position.y)) * scale.y
			right += maxf(0.0, window.x - float(safe.end.x)) * scale.x
			bottom += maxf(0.0, window.y - float(safe.end.y)) * scale.y

	_safe.offset_left = left
	_safe.offset_top = top
	_safe.offset_right = -right
	_safe.offset_bottom = -bottom


# --- the stick ----------------------------------------------------------------


func _input(event: InputEvent) -> void:
	if not _root.visible:
		return
	if event is InputEventScreenTouch:
		_on_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_on_drag(event as InputEventScreenDrag)


## Touches are taken at the position they carry rather than from the mouse the
## engine fakes out of them: the fake mouse only ever follows one finger, so
## steering with one thumb and pressing with the other threw the stick across
## the screen.
func _on_touch(touch: InputEventScreenTouch) -> void:
	if not touch.pressed:
		if touch.index == _finger:
			_release_steering()
			get_viewport().set_input_as_handled()
		return

	if _steer.visible and _finger == -1 and _steer.get_global_rect().has_point(touch.position):
		_finger = touch.index
		_steer_towards(touch.position)
		get_viewport().set_input_as_handled()
		return
	# A press on one of our own buttons is ours, and marking it so keeps the
	# camera from taking the same touch as a drag across the map.
	if _covers(touch.position):
		get_viewport().set_input_as_handled()


func _on_drag(drag: InputEventScreenDrag) -> void:
	if drag.index != _finger:
		return
	_steer_towards(drag.position)
	get_viewport().set_input_as_handled()


## Whether one of the overlay's own buttons is under [param point].
func _covers(point: Vector2) -> bool:
	for button: Button in [
		_interact_btn, _back_btn, _cycle_btn,
		_party_btn, _journal_btn, _menu_btn, _auto_btn, _speed_btn,
	]:
		if button.visible and button.is_visible_in_tree() \
				and button.get_global_rect().has_point(point):
			return true
	return false


func _steer_towards(point: Vector2) -> void:
	var centre := _steer.global_position + _steer.size * 0.5
	var lean := point - centre
	var reach := lean.length()
	if reach > STEER_RADIUS:
		lean = lean.normalized() * STEER_RADIUS
	_knob.position = (_steer.size * 0.5) + lean - (_knob.size * 0.5)

	if reach < DEADZONE:
		_face(Vector2i.ZERO)
		return

	var norm := lean.normalized()
	var dir := Vector2i.ZERO
	if norm.x > LEAN:
		dir.x = 1
	elif norm.x < -LEAN:
		dir.x = -1
	if norm.y > LEAN:
		dir.y = 1
	elif norm.y < -LEAN:
		dir.y = -1
	_face(dir)


func _face(dir: Vector2i) -> void:
	if dir == _current_dir:
		return
	_current_dir = dir
	_drop_held()

	if dir.y < 0:
		_hold("move_up")
	elif dir.y > 0:
		_hold("move_down")
	if dir.x < 0:
		_hold("move_left")
	elif dir.x > 0:
		_hold("move_right")


func _hold(action: String) -> void:
	if not _held_actions.has(action):
		_held_actions.append(action)
		Input.action_press(action)


func _drop_held() -> void:
	for action in _held_actions:
		Input.action_release(action)
	_held_actions.clear()


func _release_steering() -> void:
	_finger = -1
	_drop_held()
	_current_dir = Vector2i.ZERO
	if is_instance_valid(_knob):
		_knob.position = (_steer.size * 0.5) - (_knob.size * 0.5)


# --- pressing something -------------------------------------------------------


## A button press said the way a key press is said, so the scenes go on
## listening for one thing rather than growing a second path for touch. The
## release waits a frame: sent in the same breath it can be read as a press
## that never happened.
func tap_action(action_name: String) -> void:
	var press := InputEventAction.new()
	press.action = action_name
	press.pressed = true
	press.strength = 1.0
	Input.parse_input_event(press)
	await get_tree().process_frame
	var release := InputEventAction.new()
	release.action = action_name
	release.pressed = false
	Input.parse_input_event(release)
