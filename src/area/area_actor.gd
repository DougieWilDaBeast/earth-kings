class_name AreaActor
extends AreaThing
## Somebody you can see walking around an [AreaMap]. The node sits at their
## feet so the y-sorted world can decide who is in front of whom.

## The eight rotations PixelLab exports, by the direction they look towards.
const ROTATIONS := {
	Vector2(0, 1): "south",
	Vector2(1, 1): "south-east",
	Vector2(1, 0): "east",
	Vector2(1, -1): "north-east",
	Vector2(0, -1): "north",
	Vector2(-1, -1): "north-west",
	Vector2(-1, 0): "west",
	Vector2(-1, 1): "south-west",
}

const SPRITE_SIZE := 64
## How far up the sprite is lifted so the node sits at the feet.
const FOOT_OFFSET := 54
## Frames a second for anyone who has a run cycle to step through.
const RUN_FPS := 12.0
## Below this much movement in a frame they are standing still, not walking.
const STIRRING := 0.5
## How much they light up under the mouse.
const HOVER_LIFT := 0.35
## How fast somebody who lives here strolls, and how long they stand about
## between one errand and the next.
const ROAM_SPEED := 44.0
const ROAM_PAUSE := Vector2(1.2, 5.0)
## How often a stroll ends with them saying what they are thinking.
const CHATTER_ODDS := 0.35

## Lines they mutter to nobody in particular while they go about their day.
var chatter: Array = []
## How tall they stand against an ordinary body (`body_scale` in `data/units.json`): the axe bear
## towers over the village, the fox does not. The feet stay where anyone else's are.
var body_scale: float = 1.0

var _sprite: Sprite2D
var _rotations: Dictionary = {}
## Facing -> run cycle, for the few who have one (see [Database]).
var _run: Dictionary = {}
var _run_time: float = 0.0
var _was_at: Vector2 = Vector2.INF
var _moving: bool = false
var _facing: Vector2 = Vector2.DOWN
var _tint: Color = Color.WHITE
var _hovered: bool = false
var _roam_home: Vector2 = Vector2.ZERO
var _roam_reach: float = 0.0
var _roam_goal: Vector2 = Vector2.ZERO
var _roam_wait: float = 0.0
var _roam_held: bool = false
var _roam_path: Array[Vector2] = []
var _roam_path_index: int = 0
var _find_path: Callable = Callable()
## Answers whether a point is ground somebody could be standing on.
var _can_stand: Callable
## The stops somebody works between, in turn ([D85]): `at` (a point), `stay` (seconds, or 0 for
## an ordinary pause) and `line` (what they say on getting there, or ""). Empty for a stroll.
var _rounds: Array[Dictionary] = []
var _round_index: int = -1


static func for_character(character: Character) -> AreaActor:
	return _from_template(character.display_name, ridden_template(character.template_id))


## Whose body walks the ground for [param template_id]: one carried by a bearer
## is drawn as the bearer with them in the saddle (Atlas on Sky, D93, D101).
static func ridden_template(template_id: String) -> String:
	var signature: Dictionary = Database.skirmish.get("signatures", {}).get(template_id, {})
	var bearer := str(signature.get("bearer", ""))
	return bearer if bearer != "" and not Database.unit_template(bearer).is_empty() else template_id


## Somebody who lives here rather than travels with you. One of the sixteen carried by a bearer
## is drawn in the saddle here too, so Atlas met in a town is the Atlas who joins ([D178]).
static func for_person(person: Dictionary) -> AreaActor:
	return _from_template(person.get("name", "Someone"), ridden_template(str(person.get("unit", ""))))


static func _from_template(name: String, template_id: String) -> AreaActor:
	var actor := AreaActor.new()
	actor.display_name = name
	var template := Database.unit_template(template_id)
	actor.body_scale = clampf(float(template.get("body_scale", 1.0)), 0.5, 3.0)
	actor._rotations = _load_rotations(template.get("sprite_dir", ""))
	actor._run = _load_run(template_id)
	actor._build_sprite(Color(template.get("color", "#cccccc")))
	# A tier's shade over its family's art (D262).
	if template.has("tint") and not actor._rotations.is_empty():
		actor._tint = Color(str(template["tint"]))
		actor._sprite.modulate = actor._tint
	return actor


func face(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	var angle := direction.angle()
	var octant := wrapi(int(roundf(angle / (PI / 4.0))), -4, 4)
	var snapped: Vector2
	match octant:
		0: snapped = Vector2(1, 0)
		1: snapped = Vector2(1, 1)
		2: snapped = Vector2(0, 1)
		3: snapped = Vector2(-1, 1)
		-4, 4: snapped = Vector2(-1, 0)
		-3: snapped = Vector2(-1, -1)
		-2: snapped = Vector2(0, -1)
		-1: snapped = Vector2(1, -1)
		_: snapped = Vector2(0, 1)
	if snapped == _facing:
		return
	_facing = snapped
	_apply_texture()


## The patch of the world the mouse has to be over to have picked them out.
func contains_point(point: Vector2) -> bool:
	var local := to_local(point)
	var size := SPRITE_SIZE * maxf(body_scale, 0.8)
	return Rect2(-size / 2.0, -_foot(), size, size).has_point(local)


## How far above their feet the top of the picture stands, at their size.
func _foot() -> float:
	return FOOT_OFFSET * body_scale


func _mark_height() -> float:
	return AreaMark.HEIGHT + FOOT_OFFSET * (body_scale - 1.0)


## Let them walk a few cells around where they live, so a town looks lived in
## rather than staffed by statues.
func roam(reach_cells: float, can_stand: Callable, path_finder: Callable = Callable()) -> void:
	_roam_home = position
	_roam_goal = position
	_roam_reach = reach_cells * AreaMap.CELL
	_can_stand = can_stand
	_find_path = path_finder
	_roam_path.clear()
	_roam_path_index = 0
	_roam_wait = randf_range(0.0, ROAM_PAUSE.y)
	set_physics_process(true)


## Walk between [param stops] in turn and stay a while at each, so a town's people are seen at
## their work: water drawn at the well, bread carried to the stall, a round of the walls.
func work_rounds(stops: Array[Dictionary], can_stand: Callable, path_finder: Callable) -> void:
	_rounds = stops
	_round_index = -1
	roam(1.0, can_stand, path_finder)


## Nobody wanders off mid-conversation.
func hold_still(on: bool) -> void:
	_roam_held = on


func _ready() -> void:
	set_physics_process(_roam_reach > 0.0)
	# Whoever is moving this actor — the party, a stroll, an approach — only ever
	# writes `position`, so movement is read back off it rather than announced.
	set_process(true)


func _process(delta: float) -> void:
	var moving := _was_at != Vector2.INF and position.distance_to(_was_at) > STIRRING * delta * 60.0
	_was_at = position
	if not moving:
		if _moving:
			_moving = false
			_run_time = 0.0
			if _sprite != null:
				_sprite.position.y = _middle()
			_apply_texture()
		return
	_moving = true
	_run_time += delta
	if _sprite != null and _run.is_empty():
		_sprite.position.y = _middle() + sin(_run_time * 14.0) * 2.0
	_apply_texture()


func _physics_process(delta: float) -> void:
	if _roam_held:
		return
	if _roam_wait > 0.0:
		_roam_wait -= delta
		if _roam_wait <= 0.0:
			_pick_next_roam_path()
		return

	if not _roam_path.is_empty():
		if _roam_path_index < _roam_path.size():
			var waypoint := _roam_path[_roam_path_index]
			var to_waypoint := waypoint - position
			var max_dist := ROAM_SPEED * delta
			if to_waypoint.length() <= max_dist:
				position = waypoint
				_roam_path_index += 1
				if _roam_path_index >= _roam_path.size():
					_roam_path.clear()
					_arrive()
			else:
				var heading := to_waypoint.normalized()
				var next_pos := position + heading * max_dist
				if _can_stand.is_valid() and not _can_stand.call(next_pos):
					_roam_path.clear()
					_roam_wait = randf_range(ROAM_PAUSE.x, ROAM_PAUSE.y)
				else:
					position = next_pos
					face(heading)
		else:
			_roam_path.clear()
			_roam_wait = randf_range(ROAM_PAUSE.x, ROAM_PAUSE.y)
		return

	var step := _roam_goal - position
	if step.length() <= ROAM_SPEED * delta:
		position = _roam_goal
		_arrive()
		return
	var heading := step.normalized()
	var next_pos := position + heading * ROAM_SPEED * delta
	if _can_stand.is_valid() and not _can_stand.call(next_pos):
		_roam_wait = randf_range(ROAM_PAUSE.x, ROAM_PAUSE.y)
		return
	position = next_pos
	face(heading)


## Got where they were going: stand about, and maybe say something. On rounds, the stop says
## how long and what.
func _arrive() -> void:
	_roam_wait = randf_range(ROAM_PAUSE.x, ROAM_PAUSE.y)
	if not _rounds.is_empty():
		var stop: Dictionary = _rounds[_round_index]
		if float(stop.get("stay", 0.0)) > 0.0:
			_roam_wait = float(stop["stay"]) * randf_range(0.8, 1.2)
		if str(stop.get("line", "")) != "":
			say(str(stop["line"]))
			return
	if not chatter.is_empty() and randf() < CHATTER_ODDS:
		say(chatter.pick_random())


func _pick_next_roam_path() -> void:
	_roam_path.clear()
	_roam_path_index = 0
	if not _rounds.is_empty():
		_round_index = (_round_index + 1) % _rounds.size()
		var spot: Vector2 = _rounds[_round_index]["at"]
		_roam_goal = spot
		if _find_path.is_valid():
			var p: Array[Vector2] = _find_path.call(position, spot)
			if not p.is_empty():
				_roam_path = p
				_roam_path_index = 1 if _roam_path.size() > 1 and position.distance_to(_roam_path[0]) < 16.0 else 0
		return
	for attempt in 8:
		var reach := randf_range(0.35, 1.0) * _roam_reach
		var spot := _roam_home + Vector2.from_angle(randf() * TAU) * reach
		if _can_stand.is_valid() and not _can_stand.call(spot):
			continue
		if _find_path.is_valid():
			var p: Array[Vector2] = _find_path.call(position, spot)
			if not p.is_empty():
				_roam_path = p
				_roam_goal = spot
				_roam_path_index = 1 if _roam_path.size() > 1 and position.distance_to(_roam_path[0]) < 16.0 else 0
				return
		else:
			_roam_goal = spot
			return
	_roam_wait = randf_range(ROAM_PAUSE.x, ROAM_PAUSE.y)


## Somewhere inside their patch they could actually stand, or where they
## already are if the eight tries all landed in a wall.
func _somewhere_to_be() -> Vector2:
	for attempt in 8:
		var reach := randf_range(0.35, 1.0) * _roam_reach
		var spot := _roam_home + Vector2.from_angle(randf() * TAU) * reach
		if _can_stand.call(spot):
			return spot
	return position


## Light them up while the mouse is over them, so it is plain they can be clicked.
func set_hovered(on: bool) -> void:
	if on == _hovered:
		return
	_hovered = on
	_sprite.modulate = _tint.lightened(HOVER_LIFT) if on else _tint


func _build_sprite(fallback: Color) -> void:
	_sprite = Sprite2D.new()
	_sprite.position = Vector2(0.0, _middle())
	add_child(_sprite)
	if _rotations.is_empty():
		# No art for this template: a plain token still shows where they are.
		var token := PlaceholderTexture2D.new()
		token.size = Vector2(SPRITE_SIZE, SPRITE_SIZE)
		_sprite.texture = token
		_sprite.scale = Vector2(body_scale, body_scale)
		_tint = fallback
		_sprite.modulate = fallback
		return
	_apply_texture()


func _apply_texture() -> void:
	_fit()
	if _moving:
		var frames: Array = _run.get(_facing, [])
		if frames.is_empty() and not _run.is_empty():
			var cardinal := Vector2(_facing.x, 0) if absf(_facing.x) >= absf(_facing.y) else Vector2(0, _facing.y)
			frames = _run.get(cardinal, [])
			if frames.is_empty():
				var other := Vector2(0, _facing.y) if absf(_facing.x) >= absf(_facing.y) else Vector2(_facing.x, 0)
				frames = _run.get(other, [])
		if not frames.is_empty():
			_sprite.texture = frames[int(_run_time * RUN_FPS) % frames.size()]
			return
	if _rotations.has(_facing):
		_sprite.texture = _rotations[_facing]


## Where the middle of the body's box sits: an ordinary body is SPRITE_SIZE square,
## its top FOOT_OFFSET above the feet, and `body_scale` grows both.
func _middle() -> float:
	return -_foot() + SPRITE_SIZE * body_scale * 0.5


## Whatever size of canvas the art came on, the standing pose fills the box, and a
## walk (drawn by PixelLab on a bigger canvas grown evenly round it) keeps that scale.
func _fit() -> void:
	if _sprite == null or _rotations.is_empty():
		return
	var standing: Texture2D = _rotations.get(_facing, _rotations.get(Vector2.DOWN, null))
	var height := standing.get_size().y if standing != null else float(SPRITE_SIZE)
	var pixel := SPRITE_SIZE * body_scale / maxf(height, 1.0)
	_sprite.scale = Vector2(pixel, pixel)


static func _load_rotations(sprite_dir: String) -> Dictionary:
	var out := {}
	if sprite_dir == "":
		return out
	for direction: Vector2 in ROTATIONS:
		var path := "%s/%s.png" % [sprite_dir, ROTATIONS[direction]]
		if ResourceLoader.exists(path):
			out[direction] = load(path)
	return out


## Run cycles are exported for the four cardinals only, so a diagonal keeps its
## standing pose rather than snapping to a heading it is not walking.
static func _load_run(template_id: String) -> Dictionary:
	var out := {}
	for direction: Vector2 in ROTATIONS:
		var heading: String = ROTATIONS[direction]
		if heading.contains("-"):
			continue
		var frames := Database.unit_run(template_id, heading)
		if not frames.is_empty():
			out[direction] = frames
	return out
