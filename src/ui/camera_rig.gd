class_name CameraRig
extends Camera2D
## The camera every scene shares.
##
## A scene tells it how big the playable area is ([method frame]) and what to
## look at ([method focus_on]); the rig handles the rest — fitting the map to
## the window, smoothing the follow, and letting the player zoom and drag
## without ever being able to lose the board off the edge of the screen.

## Multiplier applied per notch of the wheel.
const ZOOM_STEP := 1.15

## How close the player may get. The far end is capped by the map itself, so
## you can zoom out until it all fits and no further.
@export var min_zoom: float = 0.6
@export var max_zoom: float = 4.0
## What the scene opens at, clamped into the range above.
@export var default_zoom: float = 1.5
## World-space breathing room left around the framed area.
@export var frame_margin: float = 64.0
## Higher follows the focus point more tightly; 0 snaps to it.
@export var follow_speed: float = 9.0
## Let the movement keys nudge the camera. Off where they drive something else.
@export var keyboard_pan: bool = false
@export var pan_speed: float = 700.0

## Where the scene wants the camera, before any panning the player has done.
var _focus: Vector2 = Vector2.ZERO
## How far the player has dragged away from [member _focus].
var _pan: Vector2 = Vector2.ZERO
var _bounds: Rect2 = Rect2()
var _dragging: bool = false
## Which zoom triggers are pulled past their deadzone.
var _triggers_held: Dictionary = {}

# Touch gesture state for mobile/pinch zoom & touch pan
var _active_touches: Dictionary = {}
var _initial_pinch_distance: float = 0.0
var _initial_pinch_zoom: float = 1.0


## Off for a scene run out of sight (the continent taking a step for the land, [D84]): its camera
## must not take the screen from the one being looked at.
var claims_the_view: bool = true
## Drawing back over the whole framed area (the world ending): the view may hold all of it, with
## nothing round it, even on a screen held upright.
var _whole: bool = false
## Further than any ground the game lays out, in pixels: a view out here has been flung off.
const LOST := 10000000.0


func _ready() -> void:
	if claims_the_view:
		make_current()
	ignore_rotation = true
	position_smoothing_enabled = follow_speed > 0.0
	position_smoothing_speed = follow_speed
	limit_smoothed = true
	zoom = Vector2(default_zoom, default_zoom)
	get_viewport().size_changed.connect(_on_viewport_resized)


## The playable area in world space. Everything the rig does clamps to it.
func frame(area: Rect2) -> void:
	_bounds = area.grow(frame_margin)
	_apply_zoom(default_zoom)


## Look at [param point], keeping whatever the player has panned so the view
## does not jump out from under them. [param immediate] also drops the pan.
func focus_on(point: Vector2, immediate: bool = false) -> void:
	_focus = point
	if immediate:
		recentre(true)
	else:
		position = _reachable(_focus + _pan)


## Rise until the whole framed area is in view, over [param seconds]: the
## overhead shot of a world ending (M15).
func pull_back(seconds: float) -> Tween:
	_pan = Vector2.ZERO
	_focus = _bounds.get_center()
	_whole = true
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_apply_zoom, zoom.x, _zoom_floor(), seconds)
	tween.tween_property(self, "position", _focus, seconds)
	return tween


## Throw away the player's panning and go back to what the scene is following.
func recentre(immediate: bool = false) -> void:
	_pan = Vector2.ZERO
	position = _reachable(_focus)
	if immediate:
		reset_smoothing()


func _process(delta: float) -> void:
	# The follow is smoothed in the player's seconds, not the game's ([D246], play-test 6): the
	# camera's own smoothing steps by the game's delta, and at 5x a step overshot, swung back
	# further each frame ("jumping the screen left and right, up and down") and at last flew off
	# for good, leaving the screen black. The speed is divided by the game's pace to cancel it.
	if follow_speed > 0.0:
		position_smoothing_speed = follow_speed / maxf(Engine.time_scale, 0.01)
	# A view that has gone somewhere no number can follow is brought straight back to its focus.
	if not position.is_finite() or not get_screen_center_position().is_finite() \
			or absf(get_screen_center_position().x) > LOST or absf(get_screen_center_position().y) > LOST:
		position = _reachable(_focus) if _focus.is_finite() else Vector2.ZERO
		reset_smoothing()
	# The right stick looks around anywhere. The movement keys only do where
	# nothing else wants them, and never on a pad, whose left stick is driving
	# a menu or a cursor wherever the keys would have panned.
	var axis := Input.get_vector("camera_pan_left", "camera_pan_right", "camera_pan_up", "camera_pan_down")
	if axis == Vector2.ZERO and keyboard_pan and not Pad.using_pad:
		axis = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if axis == Vector2.ZERO:
		return
	_pan += axis * pan_speed * delta / zoom.x
	_settle_pan()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_screen_touch(event)
	elif event is InputEventScreenDrag:
		_on_screen_drag(event)
	elif event is InputEventJoypadMotion:
		_on_trigger(event as InputEventJoypadMotion)
	elif event.is_action_pressed("camera_zoom_in", true):
		_zoom_towards(ZOOM_STEP)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("camera_zoom_out", true):
		_zoom_towards(1.0 / ZOOM_STEP)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("camera_recentre"):
		recentre()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		_set_dragging(event.pressed)
	elif event is InputEventMouseMotion and _dragging:
		_pan -= event.relative / zoom.x
		_settle_pan()
		get_viewport().set_input_as_handled()


func _on_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_active_touches[event.index] = event.position
	else:
		_active_touches.erase(event.index)

	if _active_touches.size() == 2:
		var touch_positions: Array = _active_touches.values()
		_initial_pinch_distance = (touch_positions[0] as Vector2).distance_to(touch_positions[1] as Vector2)
		_initial_pinch_zoom = zoom.x
	elif _active_touches.size() < 2:
		_initial_pinch_distance = 0.0


func _on_screen_drag(event: InputEventScreenDrag) -> void:
	_active_touches[event.index] = event.position
	if _active_touches.size() == 2 and _initial_pinch_distance > 0.0:
		var touch_positions: Array = _active_touches.values()
		var cur_dist: float = (touch_positions[0] as Vector2).distance_to(touch_positions[1] as Vector2)
		if cur_dist > 5.0 and _initial_pinch_distance > 5.0:
			var pinch_ratio := cur_dist / _initial_pinch_distance
			_apply_zoom(_initial_pinch_zoom * pinch_ratio)
			_settle_pan()
			get_viewport().set_input_as_handled()
	elif _active_touches.size() == 1 and not keyboard_pan:
		# Single finger swipe pans the camera when keyboard panning is not taking directional keys
		_pan -= event.relative / zoom.x
		_settle_pan()
		get_viewport().set_input_as_handled()


func _set_dragging(dragging: bool) -> void:
	_dragging = dragging
	# A drag should track the mouse exactly rather than trail behind it.
	position_smoothing_enabled = not dragging and follow_speed > 0.0
	Input.set_default_cursor_shape(Input.CURSOR_DRAG if dragging else Input.CURSOR_ARROW)


## A trigger is an axis, and sends a stream of motion the whole way down. One
## pull is one notch, taken as it crosses the deadzone.
func _on_trigger(event: InputEventJoypadMotion) -> void:
	for action: String in ["camera_zoom_in", "camera_zoom_out"]:
		if not event.is_action(action):
			continue
		var held := event.is_action_pressed(action)
		if held and not _triggers_held.get(action, false):
			_zoom_towards(ZOOM_STEP if action == "camera_zoom_in" else 1.0 / ZOOM_STEP)
			get_viewport().set_input_as_handled()
		_triggers_held[action] = held


## Zoom about the cursor, so whatever you are pointing at stays under it. A pad
## has no cursor, so it zooms about the middle of the screen.
func _zoom_towards(factor: float) -> void:
	var cursor := get_viewport().get_mouse_position()
	if Pad.using_pad:
		cursor = get_viewport_rect().size * 0.5
	var from_middle := cursor - get_viewport_rect().size * 0.5
	# What is under the cursor on screen now, from where the view really is
	# this frame, which may still be gliding after the party.
	var before := get_screen_center_position() + from_middle / zoom.x
	_apply_zoom(zoom.x * factor)
	_pan = before - from_middle / zoom.x - offset - _focus
	_settle_pan()
	# The zoom lands at once, so the move must too. Left to glide, the view
	# spent a few frames zoomed about the wrong point and then slid back.
	reset_smoothing()


## What is under [param screen_point], measured from where the camera can
## actually be. Measured from where it was asked to be, a zoom near an edge
## aimed past the map, and each notch put the view somewhere the limits then
## pulled it back from: the map swung side to side as it zoomed.
func _world_at(screen_point: Vector2) -> Vector2:
	return _reachable(_focus + _pan) + offset + (screen_point - get_viewport_rect().size * 0.5) / zoom.x


## Keep the player's panning to what the view can show, and move there. A pan
## past the edge would otherwise be remembered, and come back as a lurch the
## next time the zoom changed which edges hold.
func _settle_pan() -> void:
	var target := _reachable(_focus + _pan)
	_pan = target - _focus
	position = target


## The nearest centre the view can take to [param centre]: inside the framed
## area by half a screen on each side, or its middle on an axis the whole of
## it already fits across.
func _reachable(centre: Vector2) -> Vector2:
	if _bounds.size.x <= 0.0 or _bounds.size.y <= 0.0:
		return centre
	var half := get_viewport_rect().size * 0.5 / zoom.x
	var middle := _bounds.get_center()
	var out := centre
	if _bounds.size.x <= half.x * 2.0:
		out.x = middle.x
	else:
		out.x = clampf(centre.x, _bounds.position.x + half.x, _bounds.end.x - half.x)
	if _bounds.size.y <= half.y * 2.0:
		out.y = middle.y
	else:
		out.y = clampf(centre.y, _bounds.position.y + half.y, _bounds.end.y - half.y)
	return out


func _on_viewport_resized() -> void:
	_apply_zoom(zoom.x)


func _apply_zoom(level: float) -> void:
	var floor_zoom := _zoom_floor()
	var settled := clampf(level, floor_zoom, maxf(max_zoom, floor_zoom))
	zoom = Vector2(settled, settled)
	_update_limits()


## The furthest out the player may go: far enough that the whole map fits, but
## never so far that it is swimming in nothing. On a screen held upright the map fills it
## top to bottom instead and the view scrolls across it (D163): fitted, a ground as wide as it
## is tall sat in a band across the middle of a phone with black above and below.
func _zoom_floor() -> float:
	if _bounds.size.x <= 0.0 or _bounds.size.y <= 0.0:
		return min_zoom
	var view := get_viewport_rect().size
	var across := view.x / _bounds.size.x
	var down := view.y / _bounds.size.y
	if view.y > view.x and not _whole:
		return maxf(min_zoom, maxf(across, down))
	return maxf(min_zoom, minf(across, down))


## Limits are per-axis: where the map is narrower than the view there is
## nothing to scroll, so the camera is pinned to the middle of it instead.
func _update_limits() -> void:
	if _bounds.size.x <= 0.0 or _bounds.size.y <= 0.0:
		return
	var half := get_viewport_rect().size * 0.5 / zoom.x
	var centre := _bounds.get_center()

	if _bounds.size.x <= half.x * 2.0:
		limit_left = floori(centre.x - half.x)
		limit_right = ceili(centre.x + half.x)
	else:
		limit_left = floori(_bounds.position.x)
		limit_right = ceili(_bounds.end.x)

	if _bounds.size.y <= half.y * 2.0:
		limit_top = floori(centre.y - half.y)
		limit_bottom = ceili(centre.y + half.y)
	else:
		limit_top = floori(_bounds.position.y)
		limit_bottom = ceili(_bounds.end.y)
