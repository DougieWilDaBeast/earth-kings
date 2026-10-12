extends Node2D
## A world ending (M15, [D32]): the camera rises over the whole of it, and it
## burns out from the Tower to the sea while the lead's name is said over it.
##
## Drawn, not painted: a dark disc, a ring of fire at its edge, cracks and
## embers, and the map underneath tinted down to ash. No art of its own, so it
## works on whatever the map looks like. Any key after the first moment skips
## to the fade. [method play] returns when it is over.
##
## Loaded by path ([D41]). The words are `data/fall.json` →
## `siblings.lines.ending_*`.

const Siblings := preload("res://src/chronicle/siblings.gd")

## Seconds: a breath on the lead's last ground, the rise, the burning, the
## words left up afterwards, and the fade to black.
const HOLD := 0.8
const RISE := 2.6
const BURN := 4.4
const LINGER := 2.2
const FADE := 1.0
## Before this, a key is still the one that was being held when the lead died.
const SKIP_AFTER := 1.0
## Screen pixels the camera shakes at the worst of it.
const SHAKE := 7.0
const CRACKS := 11
const EMBERS_PER_FRAME := 7

const FIRE := Color(1.0, 0.42, 0.12, 0.95)
const FLARE := Color(1.0, 0.82, 0.36, 0.6)
const ASH := Color(0.06, 0.03, 0.03, 0.93)
const FALL_RED := Color(0.906, 0.447, 0.322)
const SOFT := Color(0.686, 0.663, 0.616)

signal finished

var _camera: CameraRig = null
var _origin := Vector2.ZERO
var _reach := 1.0
var _radius := 0.0
var _elapsed := 0.0
var _rising := false
var _done := false
var _embers: Array[Dictionary] = []
var _crack_angles: Array[float] = []
var _tint: CanvasModulate = null
var _veil: ColorRect = null
var _words: Control = null


## Watch [param world] end. [param origin_cell] is where the burning starts.
func play(camera: CameraRig, world: World, origin_cell: Vector2i, cell_size: int, lead_name: String) -> void:
	_camera = camera
	_origin = (Vector2(origin_cell) + Vector2(0.5, 0.5)) * cell_size
	# Far enough to reach every corner of the map from wherever it starts.
	_reach = Vector2(world.size).length() * cell_size
	z_index = 50
	var dice := RandomNumberGenerator.new()
	dice.seed = hash([world.world_seed, "the end"])
	for i in CRACKS:
		_crack_angles.append(TAU * float(i) / CRACKS + dice.randf_range(-0.2, 0.2))

	_tint = CanvasModulate.new()
	get_parent().add_child.call_deferred(_tint)
	_build_words(lead_name)
	await finished


## Straight to the fade.
func skip() -> void:
	_elapsed = maxf(_elapsed, _burn_start() + BURN + LINGER)


func _burn_start() -> float:
	return HOLD + RISE * 0.7


func _end() -> float:
	return _burn_start() + BURN + LINGER + FADE


func _process(delta: float) -> void:
	if _done or _camera == null:
		return
	_elapsed += delta
	if not _rising and _elapsed >= HOLD:
		_rising = true
		_camera.pull_back(RISE)

	var burn := clampf((_elapsed - _burn_start()) / BURN, 0.0, 1.0)
	_radius = ease(burn, 1.8) * _reach
	var shake := sin(burn * PI) * SHAKE / maxf(_camera.zoom.x, 0.01)
	_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake
	if is_instance_valid(_tint):
		var ember := Color(1.0, 0.62, 0.5)
		var ash := Color(0.34, 0.12, 0.1)
		_tint.color = Color.WHITE.lerp(ember, minf(burn * 2.0, 1.0)).lerp(ash, maxf(0.0, burn * 2.0 - 1.0))
	if is_instance_valid(_words):
		_words.modulate.a = clampf((_elapsed - _burn_start() - 0.8) / 1.0, 0.0, 1.0)
	if is_instance_valid(_veil):
		_veil.color.a = clampf((_elapsed - (_end() - FADE)) / FADE, 0.0, 1.0)

	_stir_embers(delta, burn)
	queue_redraw()
	if _elapsed >= _end():
		_done = true
		_camera.offset = Vector2.ZERO
		finished.emit()


func _input(event: InputEvent) -> void:
	if _done or _elapsed < SKIP_AFTER:
		return
	if (event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
		get_viewport().set_input_as_handled()
		skip()


func _stir_embers(delta: float, burn: float) -> void:
	if burn > 0.0 and burn < 1.0:
		for _i in EMBERS_PER_FRAME:
			var angle := randf() * TAU
			var outward := Vector2.from_angle(angle)
			_embers.append({
				"at": _origin + outward * _radius,
				"v": outward * randf_range(20.0, 90.0) + Vector2(0, -randf_range(30.0, 120.0)),
				"life": randf_range(0.6, 1.4),
				"size": randf_range(6.0, 18.0),
			})
	var kept: Array[Dictionary] = []
	for ember: Dictionary in _embers:
		ember["life"] = float(ember["life"]) - delta
		if float(ember["life"]) <= 0.0:
			continue
		ember["at"] = (ember["at"] as Vector2) + (ember["v"] as Vector2) * delta
		kept.append(ember)
	_embers = kept


func _draw() -> void:
	if _radius > 1.0:
		draw_circle(_origin, _radius, ASH)
		for angle: float in _crack_angles:
			var way := Vector2.from_angle(angle)
			draw_line(_origin, _origin + way * _radius, Color(FIRE, 0.45), maxf(6.0, _radius * 0.006))
		var width := maxf(24.0, _radius * 0.035)
		draw_arc(_origin, _radius, 0.0, TAU, 160, FIRE, width)
		draw_arc(_origin, _radius - width * 0.6, 0.0, TAU, 160, FLARE, width * 0.5)
	for ember: Dictionary in _embers:
		var colour := FLARE.lerp(FIRE, 1.0 - clampf(float(ember["life"]), 0.0, 1.0))
		colour.a = clampf(float(ember["life"]), 0.0, 1.0)
		draw_circle(ember["at"], float(ember["size"]), colour)


func _build_words(lead_name: String) -> void:
	var said := Siblings.lines()
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)

	_words = CenterContainer.new()
	_words.set_anchors_preset(Control.PRESET_FULL_RECT)
	_words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_words.modulate.a = 0.0
	layer.add_child(_words)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(760, 0)
	box.add_theme_constant_override("separation", 14)
	_words.add_child(box)
	box.add_child(_line(str(said.get("ending_title", "{name}'s world is ending.")).format({"name": lead_name}), 44, FALL_RED))
	box.add_child(_line(str(said.get("ending_sub", "")).format({"name": lead_name}), 19, SOFT))
	box.add_child(_line(str(said.get("ending_skip", "")), 14, Color(SOFT, 0.6)))

	_veil = ColorRect.new()
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.color = Color(0, 0, 0, 0)
	layer.add_child(_veil)


func _line(text: String, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	label.add_theme_color_override("font_outline_color", Color(0.067, 0.043, 0.039))
	label.add_theme_constant_override("outline_size", 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
