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

var _sprite: Sprite2D
var _rotations: Dictionary = {}
var _facing: Vector2 = Vector2.DOWN
var _tint: Color = Color.WHITE
var _hovered: bool = false
var _roam_home: Vector2 = Vector2.ZERO
var _roam_reach: float = 0.0
var _roam_goal: Vector2 = Vector2.ZERO
var _roam_wait: float = 0.0
var _roam_held: bool = false
## Answers whether a point is ground somebody could be standing on.
var _can_stand: Callable


static func for_character(character: Character) -> AreaActor:
	return _from_template(character.display_name, character.template_id)


## Somebody who lives here rather than travels with you.
static func for_person(person: Dictionary) -> AreaActor:
	return _from_template(person.get("name", "Someone"), person.get("unit", ""))


static func _from_template(name: String, template_id: String) -> AreaActor:
	var actor := AreaActor.new()
	actor.display_name = name
	var template := Database.unit_template(template_id)
	actor._rotations = _load_rotations(template.get("sprite_dir", ""))
	actor._build_sprite(Color(template.get("color", "#cccccc")))
	return actor


func face(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	var snapped := Vector2(signf(direction.x), signf(direction.y))
	if absf(direction.x) > absf(direction.y) * 2.0:
		snapped.y = 0.0
	elif absf(direction.y) > absf(direction.x) * 2.0:
		snapped.x = 0.0
	if snapped == _facing:
		return
	_facing = snapped
	_apply_texture()


## The patch of the world the mouse has to be over to have picked them out.
func contains_point(point: Vector2) -> bool:
	var local := to_local(point)
	return Rect2(-SPRITE_SIZE / 2.0, -FOOT_OFFSET, SPRITE_SIZE, SPRITE_SIZE).has_point(local)


## Let them walk a few cells around where they live, so a town looks lived in
## rather than staffed by statues.
func roam(reach_cells: float, can_stand: Callable) -> void:
	_roam_home = position
	_roam_goal = position
	_roam_reach = reach_cells * AreaMap.CELL
	_can_stand = can_stand
	_roam_wait = randf_range(0.0, ROAM_PAUSE.y)
	set_physics_process(true)


## Nobody wanders off mid-conversation.
func hold_still(on: bool) -> void:
	_roam_held = on


func _ready() -> void:
	set_physics_process(_roam_reach > 0.0)


func _physics_process(delta: float) -> void:
	if _roam_held:
		return
	if _roam_wait > 0.0:
		_roam_wait -= delta
		if _roam_wait <= 0.0:
			_roam_goal = _somewhere_to_be()
		return

	var step := _roam_goal - position
	if step.length() <= ROAM_SPEED * delta:
		position = _roam_goal
		_roam_wait = randf_range(ROAM_PAUSE.x, ROAM_PAUSE.y)
		if not chatter.is_empty() and randf() < CHATTER_ODDS:
			say(chatter.pick_random())
		return
	var heading := step.normalized()
	position += heading * ROAM_SPEED * delta
	face(heading)


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
	_sprite.centered = false
	_sprite.position = Vector2(-SPRITE_SIZE / 2.0, -FOOT_OFFSET)
	add_child(_sprite)
	if _rotations.is_empty():
		# No art for this template: a plain token still shows where they are.
		var token := PlaceholderTexture2D.new()
		token.size = Vector2(SPRITE_SIZE, SPRITE_SIZE)
		_sprite.texture = token
		_tint = fallback
		_sprite.modulate = fallback
		return
	_apply_texture()


func _apply_texture() -> void:
	if _rotations.has(_facing):
		_sprite.texture = _rotations[_facing]


static func _load_rotations(sprite_dir: String) -> Dictionary:
	var out := {}
	if sprite_dir == "":
		return out
	for direction: Vector2 in ROTATIONS:
		var path := "%s/%s.png" % [sprite_dir, ROTATIONS[direction]]
		if ResourceLoader.exists(path):
			out[direction] = load(path)
	return out
