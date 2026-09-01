extends Node2D
## What you see before the menu: a slow pass over a country that does not exist
## yet, with people already walking about in it.
##
## Nothing here is the real run. A world is generated from a throwaway seed and
## thrown away again the moment the title screen opens — it is a look at the
## kind of place this is, not at the place you are going to.
##
## Any key or click cuts to the title. Nobody should have to sit through this
## twice, so it is short and it never blocks.

const CELL := 24
## How long the camera holds on each place before setting off for the next.
const HOLD := 2.6
const PLACES := 4
## Steps a walker takes a second, in cells.
const WALK_SPEED := 1.5
const FACE := 26.0
## The whole thing, after which it hands over on its own.
const RUN_TIME := 12.0

## Set by [Game] before the scene enters the tree; unused here.
var boot_payload: Dictionary = {}

@onready var _map: Node2D = %Map
@onready var _camera: CameraRig = %Camera
@onready var _title: Control = %TitleBlock
@onready var _prompt: Label = %PromptLabel

var _world: World
var _stops: Array[Vector2i] = []
var _at := 0
var _hold := 0.0
var _walkers: Array[Dictionary] = []
var _art: Dictionary = {}
var _handed_over := false


func _ready() -> void:
	Pace.reset()
	_world = WorldGen.generate(randi())
	_stops = _worth_seeing()
	_walkers = _people_about()
	for kind: String in Site.ART:
		var path: String = Site.ART[kind]
		if ResourceLoader.exists(path):
			_art[kind] = load(path)

	_map.draw.connect(_draw_country)
	_camera.frame(Rect2(Vector2.ZERO, Vector2(_world.size) * CELL))
	_camera.focus_on(_centre_of(_stops[0]), true)

	_title.modulate.a = 0.0
	_prompt.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(RUN_TIME * 0.35)
	tween.tween_property(_title, "modulate:a", 1.0, 1.6)
	tween.tween_property(_prompt, "modulate:a", 1.0, 0.8)

	get_tree().create_timer(RUN_TIME).timeout.connect(_hand_over)


func _process(delta: float) -> void:
	_hold -= delta
	if _hold <= 0.0:
		_at = (_at + 1) % _stops.size()
		_hold = HOLD
		_camera.focus_on(_centre_of(_stops[_at]))
	_walk(delta)
	_map.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		_hand_over()


func _hand_over() -> void:
	if _handed_over:
		return
	_handed_over = true
	EventBus.request_scene.emit("title", {})


# --- what to look at ----------------------------------------------------------


## The places worth a pass: the Tower first, then whatever is furthest from what
## has already been picked, so the camera crosses the country instead of pacing
## around one corner of it.
func _worth_seeing() -> Array[Vector2i]:
	var candidates: Array[Site] = []
	for kind: String in [Site.TOWER, Site.KEEP, Site.VILLAGE, Site.GATE, Site.LIBRARY]:
		candidates.append_array(_world.sites_of_kind(kind))
	if candidates.is_empty():
		return [_world.player_cell] as Array[Vector2i]

	var picked: Array[Vector2i] = [candidates[0].cell]
	while picked.size() < mini(PLACES, candidates.size()):
		var best: Site = null
		var furthest := -1
		for site in candidates:
			if picked.has(site.cell):
				continue
			var nearest := 1 << 30
			for cell: Vector2i in picked:
				nearest = mini(nearest, Pathfinder.distance(cell, site.cell))
			if nearest > furthest:
				furthest = nearest
				best = site
		if best == null:
			break
		picked.append(best.cell)
	return picked


## A handful of people already going about it, each pacing between two places.
func _people_about() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var faces := _faces()
	if faces.is_empty() or _stops.size() < 2:
		return out
	for i in _stops.size():
		var from := _stops[i]
		var to := _stops[(i + 1) % _stops.size()]
		out.append({
			"face": faces[i % faces.size()],
			"from": Vector2(from) * CELL,
			"to": Vector2(to) * CELL,
			"along": _world.rng.randf(),
			"back": false,
		})
	return out


func _faces() -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	for template_id: String in Roster.FOUNDING:
		var face := Database.unit_face(template_id)
		if face != null:
			out.append(face)
	return out


func _walk(delta: float) -> void:
	for walker: Dictionary in _walkers:
		var span: float = maxf(1.0, (walker["to"] as Vector2).distance_to(walker["from"]))
		var step := WALK_SPEED * CELL * delta / span
		var along := float(walker["along"]) + (-step if bool(walker["back"]) else step)
		if along >= 1.0 or along <= 0.0:
			walker["back"] = not bool(walker["back"])
			along = clampf(along, 0.0, 1.0)
		walker["along"] = along


# --- drawing ------------------------------------------------------------------


func _draw_country() -> void:
	for y in _world.size.y:
		for x in _world.size.x:
			var cell := Vector2i(x, y)
			var shade := 0.9 + float(absi(hash(cell)) % 1000) / 1000.0 * 0.18
			_map.draw_rect(
				Rect2(Vector2(cell) * CELL, Vector2.ONE * CELL),
				Color(_world.terrain_at(cell).get("color", "#4f7d3f")) * Color(shade, shade, shade)
			)
	for site in _world.sites:
		_draw_place(site)
	for walker: Dictionary in _walkers:
		var at: Vector2 = (walker["from"] as Vector2).lerp(walker["to"], float(walker["along"]))
		_map.draw_texture_rect(
			walker["face"], Rect2(at - Vector2(FACE, FACE) * 0.5, Vector2(FACE, FACE)), false
		)


func _draw_place(site: Site) -> void:
	var origin := Vector2(site.cell) * CELL
	var centre := origin + Vector2(CELL, CELL) * 0.5
	var texture: Texture2D = _art.get(site.kind)
	if texture == null:
		_map.draw_circle(centre, CELL * 0.4, Site.COLOURS.get(site.kind, Color.WHITE))
		return
	var span := Vector2(CELL, CELL) * 1.9
	_map.draw_texture_rect(texture, Rect2(centre - span * 0.5, span), false)


func _centre_of(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL + Vector2(CELL, CELL) * 0.5
