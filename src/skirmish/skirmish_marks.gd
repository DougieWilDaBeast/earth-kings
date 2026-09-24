extends Node2D
## What the fight needs drawn on the ground that a [Unit] does not draw itself:
## who is selected, where they were sent, what is being wound up, and how long a
## downed ally has left.

## Loaded by path, not by `class_name`: a global class name only resolves once the
## editor has rescanned the project, and a checkout that has not been opened in
## the editor since this landed would otherwise fail to parse the whole skirmish.
const Fighter := preload("res://src/skirmish/fighter.gd")
const SkirmishRules := preload("res://src/skirmish/skirmish_rules.gd")

const SELECTED := Color(1.0, 0.86, 0.3, 0.95)
const ORDER_LINE := Color(1.0, 0.95, 0.7, 0.45)
const ATTACK_LINE := Color(1.0, 0.45, 0.35, 0.55)
const AID_LINE := Color(0.5, 1.0, 0.6, 0.6)
const CAST_BACK := Color(0, 0, 0, 0.65)
const CAST_FILL := Color(0.55, 0.75, 1.0)
const NEAR_DEATH := Color(1.0, 0.3, 0.3, 0.9)
const AID_FILL := Color(0.45, 1.0, 0.55, 0.9)

## The skirmish scene. Untyped, because it loads this script itself.
var skirmish: Node2D


func _draw() -> void:
	if skirmish == null:
		return
	var half := BattleGrid.CELL_SIZE * 0.5
	for f: Fighter in skirmish.fighters:
		if f.fallen:
			continue
		var at := f.unit.position
		if skirmish.selected.has(f):
			draw_arc(at + Vector2(0, half * 0.55), half * 0.62, 0.0, TAU, 28, SELECTED, 2.5, true)
			_draw_order(f, at)
		if f.is_downed():
			var share := f.near_death / SkirmishRules.NEAR_DEATH
			draw_arc(at, half * 0.8, -PI * 0.5, -PI * 0.5 + TAU * share, 32, NEAR_DEATH, 3.0, true)
		if f.is_casting():
			var done := 1.0 - float(f.cast["left"]) / maxf(0.001, float(f.cast["total"]))
			_draw_bar(at + Vector2(-half * 0.7, half * 0.75), half * 1.4, done, CAST_FILL)
		if f.aiding > 0.0:
			var done := 1.0 - f.aiding / SkirmishRules.AID_TIME
			_draw_bar(at + Vector2(-half * 0.7, half * 0.75), half * 1.4, done, AID_FILL)


func _draw_order(f: Fighter, at: Vector2) -> void:
	var grid: BattleGrid = skirmish.grid
	match f.order:
		Fighter.Order.MOVE:
			var to := grid.cell_to_world(f.order_cell)
			draw_line(at, to, ORDER_LINE, 1.5, true)
			draw_circle(to, 4.0, ORDER_LINE)
		Fighter.Order.ATTACK, Fighter.Order.CAST:
			if f.order_target != null:
				draw_line(at, f.order_target.position, ATTACK_LINE, 1.5, true)
			else:
				draw_line(at, grid.cell_to_world(f.order_cell), ATTACK_LINE, 1.5, true)
		Fighter.Order.AID:
			if f.order_target != null:
				draw_line(at, f.order_target.position, AID_LINE, 1.5, true)
		_:
			if f.target != null and f.target.is_alive():
				draw_line(at, f.target.position, Color(ATTACK_LINE, 0.25), 1.0, true)


func _draw_bar(origin: Vector2, width: float, share: float, colour: Color) -> void:
	draw_rect(Rect2(origin, Vector2(width, 5)), CAST_BACK)
	draw_rect(Rect2(origin, Vector2(width * clampf(share, 0.0, 1.0), 5)), colour)
