class_name Unit
extends Node2D
## A combatant on the battle grid. Stats are hydrated from a `data/units.json`
## template; the node itself draws a placeholder token until art exists.

signal died

enum Team { PLAYER, ENEMY }

const WALK_TIME_PER_TILE := 0.14
## Sprite height as a multiple of a tile.
const SPRITE_HEIGHT_CELLS := 1.15
## Facing -> the rotation file PixelLab exports for it.
const SPRITE_ROTATIONS := {
	Vector2i.DOWN: "south",
	Vector2i.UP: "north",
	Vector2i.RIGHT: "east",
	Vector2i.LEFT: "west",
}

var template_id: String = ""
var display_name: String = "Unit"
var job: String = ""
var team: Team = Team.PLAYER
var cell: Vector2i = Vector2i.ZERO
## Cardinal direction the unit is looking at; attacks from the sides or the
## back hit harder (see [AbilityResolver]).
var facing: Vector2i = Vector2i.DOWN

var max_hp: int = 1
var hp: int = 1
var attack: int = 1
var defense: int = 0
var move_points: int = 3
var jump: int = 1
var speed: int = 8
var abilities: Array = []
var colour: Color = Color.WHITE
## Facing -> [Texture2D] from the template's `sprite_dir`; empty falls back to a token.
var sprites: Dictionary = {}

## Charge time — see [TurnManager]. At 100 the unit acts.
var ct: int = 0

var has_moved: bool = false
var has_acted: bool = false


static func create(template_id_: String, unit_team: Team, start_cell: Vector2i) -> Unit:
	var unit := Unit.new()
	var data := Database.unit_template(template_id_)
	unit.template_id = template_id_
	unit.display_name = data.get("display_name", template_id_)
	unit.job = data.get("job", "")
	unit.max_hp = int(data.get("max_hp", 20))
	unit.hp = unit.max_hp
	unit.attack = int(data.get("attack", 5))
	unit.defense = int(data.get("defense", 0))
	unit.move_points = int(data.get("move", 3))
	unit.jump = int(data.get("jump", 1))
	unit.speed = int(data.get("speed", 8))
	unit.abilities = data.get("abilities", ["strike"])
	unit.colour = Color(data.get("color", "#cccccc"))
	unit.sprites = _load_sprites(data.get("sprite_dir", ""), template_id_)
	unit.team = unit_team
	unit.cell = start_cell
	unit.ct = randi_range(0, 40)
	return unit


## Snap an arbitrary offset to the cardinal direction it leans towards.
static func dominant_direction(delta: Vector2i) -> Vector2i:
	if delta == Vector2i.ZERO:
		return Vector2i.DOWN
	if absi(delta.x) >= absi(delta.y):
		return Vector2i(signi(delta.x), 0)
	return Vector2i(0, signi(delta.y))


static func _load_sprites(dir_path: String, template_id_: String) -> Dictionary:
	var out := {}
	if dir_path == "":
		return out
	for facing_dir: Vector2i in SPRITE_ROTATIONS:
		var path := "%s/%s.png" % [dir_path, SPRITE_ROTATIONS[facing_dir]]
		if ResourceLoader.exists(path):
			out[facing_dir] = load(path)
		else:
			push_warning("Unit: %s is missing the rotation %s" % [template_id_, path])
	return out


func is_alive() -> bool:
	return hp > 0


func is_hostile_to(other: Unit) -> bool:
	return team != other.team


func begin_turn() -> void:
	has_moved = false
	has_acted = false


func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	EventBus.unit_damaged.emit(self, amount)
	queue_redraw()
	if hp == 0:
		died.emit()
		EventBus.unit_died.emit(self)


func heal(amount: int) -> void:
	var healed := mini(amount, max_hp - hp)
	hp += healed
	EventBus.unit_healed.emit(self, healed)
	queue_redraw()


func face_towards(target_cell: Vector2i) -> void:
	if target_cell == cell:
		return
	facing = dominant_direction(target_cell - cell)
	queue_redraw()


func snap_to_cell(grid: BattleGrid) -> void:
	position = grid.cell_to_world(cell)


## Animate along [param path]; awaitable so the controller can sequence turns.
func walk_path(grid: BattleGrid, path: Array[Vector2i]) -> void:
	if path.is_empty():
		return
	var tween := create_tween()
	for step in path:
		tween.tween_property(self, "position", grid.cell_to_world(step), WALK_TIME_PER_TILE)
	await tween.finished
	var penultimate: Vector2i = path[-2] if path.size() > 1 else cell
	cell = path[-1]
	facing = dominant_direction(cell - penultimate)
	has_moved = true
	queue_redraw()


func _draw() -> void:
	var radius := BattleGrid.CELL_SIZE * 0.34
	var outline := Color.WHITE if team == Team.PLAYER else Color(0.2, 0.05, 0.05)
	var sprite := current_sprite()
	draw_circle(Vector2(2, 3), radius, Color(0, 0, 0, 0.3))
	if sprite == null:
		draw_circle(Vector2.ZERO, radius, colour)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, outline, 2.0, true)
	_draw_facing(radius, outline)
	if sprite != null:
		draw_texture_rect(sprite, _sprite_rect(sprite), false)
	_draw_hp_bar(sprite)


func current_sprite() -> Texture2D:
	return sprites.get(facing, sprites.get(Vector2i.DOWN, null))


## Top-down art sits centred on its tile, lifted slightly so the ring reads as ground.
func _sprite_rect(sprite: Texture2D) -> Rect2:
	var source := sprite.get_size()
	var drawn := source * (BattleGrid.CELL_SIZE * SPRITE_HEIGHT_CELLS / source.y)
	return Rect2(
		Vector2(-drawn.x * 0.5, -drawn.y * 0.5 - BattleGrid.CELL_SIZE * 0.12), drawn
	)


func _draw_facing(radius: float, outline: Color) -> void:
	var forward := Vector2(facing)
	var side := forward.orthogonal()
	var tip := forward * (radius + 7.0)
	var base := forward * (radius + 1.0)
	draw_colored_polygon(
		PackedVector2Array([tip, base + side * 5.0, base - side * 5.0]), outline
	)


func _draw_hp_bar(sprite: Texture2D) -> void:
	var width := float(BattleGrid.CELL_SIZE) * 0.7
	var top := -BattleGrid.CELL_SIZE * 0.45
	if sprite != null:
		top = _sprite_rect(sprite).position.y - 8.0
	var origin := Vector2(-width * 0.5, top)
	var ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(origin, Vector2(width, 4)), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(origin, Vector2(width * ratio, 4)), Color(0.3, 0.85, 0.4))
