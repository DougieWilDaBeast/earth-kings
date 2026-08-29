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


func _ready() -> void:
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
		position = _focus + _pan


## Throw away the player's panning and go back to what the scene is following.
func recentre(immediate: bool = false) -> void:
	_pan = Vector2.ZERO
	position = _focus
	if immediate:
		reset_smoothing()


func _process(delta: float) -> void:
	if not keyboard_pan:
		return
	var axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if axis == Vector2.ZERO:
		return
	_pan += axis * pan_speed * delta / zoom.x
	position = _focus + _pan


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_zoom_in", true):
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
		position = _focus + _pan
		get_viewport().set_input_as_handled()


func _set_dragging(dragging: bool) -> void:
	_dragging = dragging
	# A drag should track the mouse exactly rather than trail behind it.
	position_smoothing_enabled = not dragging and follow_speed > 0.0
	Input.set_default_cursor_shape(Input.CURSOR_DRAG if dragging else Input.CURSOR_ARROW)


## Zoom about the cursor, so whatever you are pointing at stays under it.
func _zoom_towards(factor: float) -> void:
	var cursor := get_viewport().get_mouse_position()
	var before := _world_at(cursor)
	_apply_zoom(zoom.x * factor)
	_pan += before - _world_at(cursor)
	position = _focus + _pan


func _world_at(screen_point: Vector2) -> Vector2:
	return _focus + _pan + offset + (screen_point - get_viewport_rect().size * 0.5) / zoom.x


func _on_viewport_resized() -> void:
	_apply_zoom(zoom.x)


func _apply_zoom(level: float) -> void:
	var floor_zoom := _zoom_floor()
	var settled := clampf(level, floor_zoom, maxf(max_zoom, floor_zoom))
	zoom = Vector2(settled, settled)
	_update_limits()


## The furthest out the player may go: far enough that the whole map fits, but
## never so far that it is swimming in nothing.
func _zoom_floor() -> float:
	if _bounds.size.x <= 0.0 or _bounds.size.y <= 0.0:
		return min_zoom
	var view := get_viewport_rect().size
	return maxf(min_zoom, minf(view.x / _bounds.size.x, view.y / _bounds.size.y))


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
