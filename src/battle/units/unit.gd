class_name Unit
extends Node2D
## A combatant on the battle grid. Stats are hydrated from a `data/units.json`
## template; the node itself draws a placeholder token until art exists.

signal died

enum Team { PLAYER, ENEMY }

const WALK_TIME_PER_TILE := 0.14

var template_id: String = ""
var display_name: String = "Unit"
var job: String = ""
var team: Team = Team.PLAYER
var cell: Vector2i = Vector2i.ZERO

var max_hp: int = 1
var hp: int = 1
var attack: int = 1
var defense: int = 0
var move_points: int = 3
var jump: int = 1
var speed: int = 8
var abilities: Array = []
var colour: Color = Color.WHITE

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
	unit.team = unit_team
	unit.cell = start_cell
	unit.ct = randi_range(0, 40)
	return unit


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
	cell = path[-1]
	has_moved = true


func _draw() -> void:
	var radius := BattleGrid.CELL_SIZE * 0.34
	var outline := Color.WHITE if team == Team.PLAYER else Color(0.2, 0.05, 0.05)
	draw_circle(Vector2(2, 3), radius, Color(0, 0, 0, 0.3))
	draw_circle(Vector2.ZERO, radius, colour)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, outline, 2.0, true)
	_draw_hp_bar()


func _draw_hp_bar() -> void:
	var width := float(BattleGrid.CELL_SIZE) * 0.7
	var origin := Vector2(-width * 0.5, -BattleGrid.CELL_SIZE * 0.45)
	var ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(origin, Vector2(width, 4)), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(origin, Vector2(width * ratio, 4)), Color(0.3, 0.85, 0.4))
