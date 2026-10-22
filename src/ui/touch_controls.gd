class_name TouchControls
extends CanvasLayer
## On-screen controls for Android and anything else played with a thumb.
##
## The overlay lays itself out from the scene that is up, because what belongs
## under a thumb on the road is in the way in a fight: the stick and the action
## cluster are for walking, and a battle is tapped on the board with its own
## commands down the side. While anything modal is open the whole thing steps
## aside, so it can never sit on top of a screen the player has to answer.

## Held upright (D163) the bar runs the whole width, so it is dropped below the scene's own top
## lines (where you are, and the compass), and the stick and the buttons are lifted clear of its
## bottom lines (what is happening, and what to press). Lying down there is room beside them.
const UPRIGHT_DROP := 74.0
const UPRIGHT_LIFT := 112.0

## How far the touch overlay pushes a scene's top-right corner down, so its own
## bar and the scene's own buttons are not fighting over the same strip.
const BAR_DROP := 70.0

## Scenes that are walked through, and so want the stick and the cluster.
const WALK_SCENES := ["world", "area"]
## Scenes that want the bar at all. Everything else — the title, the character
## picker, the training yard, the arena, the summary — is buttons already, and
## a stick laid over them only covers them up.
const PLAY_SCENES := ["world", "area", "skirmish"]

## How far the knob travels from the middle of the stick.
const STEER_RADIUS := 78.0
## Slop around the middle, so resting a thumb is not a step.
const DEADZONE := 18.0
## Clearance kept inside the screen's safe area, for rounded corners.
const EDGE_PAD := 14.0
## How tall the Act, Back and Next cluster stands in the bottom corner (its scene's offsets), so a
## fight's own buttons can keep above it.
const CLUSTER_HEIGHT := 212.0
## A finger held still this long asks what a thing is instead of pressing it ([D388]): a phone
## has no hover, so a long press is where a computer's tooltips and hover cards are read.
const HOLD_TIME := 0.45
## How far a held finger may wander and still be holding still.
const HOLD_STILL := 14.0
## How long the tip stays up once the finger lifts.
const TIP_LINGER := 2.5
## Where the engine is sent the mouse release a hold ate, so whatever button the finger was on
## lets go of it without being pressed.
const NOWHERE := Vector2(-10000, -10000)

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
@onready var _more_btn: Button = %MoreButton

## The finger steering, if one is. Anything else on the glass is somebody
## else's — a second thumb on a button, or two fingers pinching the map.
var _finger: int = -1
var _current_dir: Vector2i = Vector2i.ZERO
var _held_actions: Array[String] = []
var _scene_key: String = "title"
## A fight on the ground is on ([D376]): nothing is walked, so the stick steps aside and the
## fighter's card under it can be pressed. Act, Back and Next stay; the fight answers them.
var _fighting := false
## The finger being held still, if one is, where it went down and when (real milliseconds).
var _hold_finger: int = -1
var _hold_at := Vector2.ZERO
var _hold_since: int = 0
## The hold came to something: its release is not a press.
var _held := false
var _eat_release := false
var _tip_layer: CanvasLayer
var _tip: PanelContainer
var _tip_text: Label
var _tip_left: float = 0.0


func _ready() -> void:
	_wire_buttons()
	Pace.changed.connect(_restate)
	EventBus.scene_changed.connect(_on_scene_changed)
	EventBus.battle_started.connect(func(_map_id: String) -> void:
		_fighting = true
		_restate()
	)
	EventBus.battle_finished.connect(func(_result: Dictionary) -> void:
		_fighting = false
		_restate()
	)

	# Both edges of every overlay. Opening alone was never enough: the controls
	# went away when a screen was asked for and never came back when it shut.
	for opening: Signal in [
		EventBus.system_menu_requested, EventBus.party_screen_requested,
		EventBus.journal_requested, EventBus.stash_requested, EventBus.guild_requested,
		EventBus.how_to_play_requested,
	]:
		opening.connect(_restate)
	EventBus.overlay_closed.connect(_restate)
	EventBus.map_requested.connect(_restate)
	EventBus.dialogue_requested.connect(func(_id: String) -> void: _restate())
	EventBus.dialogue_finished.connect(func(_id: String) -> void: _restate())
	EventBus.conversation_requested.connect(func(_lines: Array) -> void: _restate())

	get_viewport().size_changed.connect(_fit_safe_area)
	_fit_safe_area()
	_build_tip()
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
	# The quick wheel without a middle button ([D376]).
	_more_btn.pressed.connect(func() -> void: EventBus.quick_wheel_requested.emit())
	for button: Button in [
		_interact_btn, _back_btn, _cycle_btn,
		_party_btn, _journal_btn, _menu_btn, _auto_btn, _speed_btn, _more_btn,
	]:
		Sfx.attend(button)


func _on_scene_changed(scene_key: String) -> void:
	_scene_key = scene_key
	_fighting = false
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
	var playing := Pace.is_touch_enabled() and PLAY_SCENES.has(_scene_key) and not _overlay_open() \
			and not _big_map_up()
	var walking := playing and WALK_SCENES.has(_scene_key)

	_root.visible = playing
	_top_bar.visible = not _book_beside()
	_steer.visible = walking and not _fighting
	_cluster.visible = walking
	# A fight has its own auto and speed down the side of the board; two sets
	# of them on one screen is worse than none.
	_auto_btn.visible = walking
	_speed_btn.visible = walking
	_party_btn.visible = walking
	_more_btn.visible = walking and bool(Database.world_rules.get("quick_wheel", {}).get("on", false))

	if not walking or _fighting:
		_release_steering()
	# On, it says which way it walks (D216); the menu picks the way.
	_auto_btn.text = "Auto: %s" % Pace.auto_style_name() if Pace.auto else "Auto"
	_speed_btn.text = "%dx" % int(Pace.speed())


## The large map has its own +, -, Party and Close on a phone ([D377]).
func _big_map_up() -> bool:
	for node in get_tree().get_nodes_in_group(EventBus.BIG_MAP_GROUP):
		if node.has_method("is_open") and node.is_open():
			return true
	return false


func _book_beside() -> bool:
	for node in get_tree().get_nodes_in_group(EventBus.MODAL_OVERLAY_GROUP):
		if node.has_method("is_open_beside") and node.is_open_beside():
			return true
	return false


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

	var view_now := get_viewport().get_visible_rect().size
	if view_now.y > view_now.x:
		top += UPRIGHT_DROP
		bottom += UPRIGHT_LIFT

	_safe.offset_left = left
	_safe.offset_top = top
	_safe.offset_right = -right
	_safe.offset_bottom = -bottom


# --- the stick ----------------------------------------------------------------


func _input(event: InputEvent) -> void:
	if _hold_input(event):
		return
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


# --- holding a finger still: what is this? ([D388]) ---------------------------


## Watches every finger for a hold, wherever it is, and eats the mouse release the engine makes of
## a hold's lifting. Whether [param event] was used up.
func _hold_input(event: InputEvent) -> bool:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.position == NOWHERE:
		return false
	if _eat_release and mouse != null and mouse.button_index == MOUSE_BUTTON_LEFT and not mouse.pressed:
		_eat_release = false
		get_viewport().set_input_as_handled()
		# A button the finger went down on still holds the mouse: let go of it somewhere else.
		var away := InputEventMouseButton.new()
		away.button_index = MOUSE_BUTTON_LEFT
		away.pressed = false
		away.position = NOWHERE
		away.global_position = NOWHERE
		Input.parse_input_event(away)
		return true
	if not Pace.is_touch_enabled():
		return false
	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed:
			_hide_tip()
			var steering := _steer.visible and _steer.get_global_rect().has_point(touch.position)
			if _hold_finger == -1 and not steering:
				_hold_finger = touch.index
				_hold_at = touch.position
				_hold_since = Time.get_ticks_msec()
				_held = false
			elif _hold_finger != -1 and touch.index != _hold_finger:
				# A second finger is a pinch, not a question.
				_hold_finger = -1
		elif touch.index == _hold_finger:
			_hold_finger = -1
			if _held:
				_held = false
				_eat_release = true
				_tip_left = TIP_LINGER
		return false
	var drag := event as InputEventScreenDrag
	if drag != null and drag.index == _hold_finger and not _held \
			and drag.position.distance_to(_hold_at) > HOLD_STILL:
		_hold_finger = -1
	return false


func _process(delta: float) -> void:
	if _hold_finger != -1 and not _held and Time.get_ticks_msec() - _hold_since >= HOLD_TIME * 1000.0:
		_held = true
		_show_tip(_hold_at)
		EventBus.touch_held.emit(_hold_at)
	if _tip_left > 0.0:
		# Real time, whatever the game's speed.
		_tip_left -= delta / maxf(0.01, Engine.time_scale)
		if _tip_left <= 0.0:
			_hide_tip()


## What a computer shows on hover over [param point]: the tooltip of the control under it, or of
## the nearest one above it that has one.
func tip_at(point: Vector2) -> String:
	var control := get_viewport().gui_get_hovered_control()
	while control != null:
		if control.get_global_rect().has_point(point):
			var text := control.get_tooltip(control.get_global_transform().affine_inverse() * point)
			if text.strip_edges() != "":
				return text.strip_edges()
		control = control.get_parent_control()
	return ""


func _show_tip(point: Vector2) -> void:
	var text := tip_at(point)
	if text == "":
		return
	_tip_text.text = text
	_tip.reset_size()
	_tip.visible = true
	# Above the finger, so the finger does not cover it, and inside the screen.
	var view := get_viewport().get_visible_rect().size
	var at := point + Vector2(-_tip.size.x * 0.5, -_tip.size.y - 48.0)
	if at.y < EDGE_PAD:
		at.y = point.y + 48.0
	_tip.position = at.clamp(Vector2(EDGE_PAD, EDGE_PAD), (view - _tip.size - Vector2(EDGE_PAD, EDGE_PAD)).max(Vector2.ZERO))


func _hide_tip() -> void:
	_tip_left = 0.0
	if _tip != null:
		_tip.visible = false


## Whether a tip is up, and what it says (for the suites).
func tip_shown() -> String:
	return _tip_text.text if _tip != null and _tip.visible else ""


func _build_tip() -> void:
	_tip_layer = CanvasLayer.new()
	_tip_layer.layer = 120
	add_child(_tip_layer)
	_tip = PanelContainer.new()
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.12, 0.94)
	style.border_color = Color(0.95, 0.86, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	_tip.add_theme_stylebox_override("panel", style)
	_tip_text = Label.new()
	_tip_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_text.custom_minimum_size = Vector2(300, 0)
	_tip_text.add_theme_font_size_override("font_size", 17)
	_tip.add_child(_tip_text)
	_tip.visible = false
	_tip_layer.add_child(_tip)


## Whether one of the overlay's own buttons is under [param point].
func _covers(point: Vector2) -> bool:
	for button: Button in [
		_interact_btn, _back_btn, _cycle_btn,
		_party_btn, _journal_btn, _menu_btn, _auto_btn, _speed_btn, _more_btn,
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
