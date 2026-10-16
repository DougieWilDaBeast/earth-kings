extends Node2D
## The Tower, standing in for its art (D108): a shaft of stacked wall stones rising off its foot,
## stepping in every few storeys, lit windows up it, and fading into the sky because it does not
## end. Built from the town walls' stone (`art/props/walls`) until art request A9 is made.
##
## An area places it with a prop entry carrying `spire`: `{ width, storeys, build, step }`, where
## the prop's `cell` is the middle of the Tower's foot. With `art` (a picture under `art/props/`),
## that picture is the shaft instead, standing on the foot at its bottom middle (D158: the huge
## Tower drawn in house by tools/draw_great_tower.py); the corner towers still stand. Everything is drawn here; nothing is solid,
## because the rock it stands on already is.
##
## Loaded by path, not by `class_name` ([D41]).

const CELL := 64.0
const WINDOW := Color("#f0c268")
const WINDOW_DARK := Color("#2a2233")
const SHADOW := Color(0, 0, 0, 0.35)
## How much darker the stone gets towards the top, and where it starts to go into the sky.
const DUSK := 0.45
const FADE_FROM := 0.7

var width: int = 8
var storeys: int = 18
## Every this many storeys the shaft steps in by half a cell each side.
var step: int = 5
var _run: Texture2D
var _tower: Texture2D
var _art: Texture2D


static func from_entry(entry: Dictionary) -> Node2D:
	var node: Node2D = (load("res://src/area/area_spire.gd") as GDScript).new()
	var spire: Dictionary = entry.get("spire", {})
	node.width = int(spire.get("width", 8))
	node.storeys = int(spire.get("storeys", 18))
	node.step = maxi(1, int(spire.get("step", 5)))
	var build := str(spire.get("build", "stone"))
	node._run = load("res://art/props/walls/%s_run.png" % build)
	node._tower = load("res://art/props/walls/%s_tower.png" % build)
	var art := str(spire.get("art", ""))
	if art != "":
		node._art = load("res://art/props/%s.png" % art)
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return node


func _draw() -> void:
	if _run == null:
		return
	# Its foot: the shaft stands on the top edge of the cell its door is in.
	var foot := -CELL / 2.0
	draw_rect(Rect2(-width * CELL / 2.0 - 12.0, foot - 10.0, width * CELL + 24.0, 22.0), SHADOW)
	if _art != null:
		var size := Vector2(_art.get_width(), _art.get_height())
		draw_texture(_art, Vector2(-size.x / 2.0, foot - size.y + 8.0))
		_draw_corner_towers(foot)
		return
	# The wall stone without its battlements, laid course on course.
	var brick := Rect2(0.0, 30.0, float(_run.get_width()), 64.0)
	for storey in storeys:
		var inset := float(storey / step) * CELL * 0.5
		var left := -width * CELL / 2.0 + inset
		var across := int(round((width * CELL - inset * 2.0) / CELL))
		var top := foot - (storey + 1) * CELL
		var high := float(storey) / float(maxi(1, storeys - 1))
		var shade := Color(1.0 - DUSK * high, 1.0 - DUSK * high, 1.0 - DUSK * 0.8 * high, _fade(high))
		for x in across:
			draw_texture_rect_region(_run, Rect2(left + x * CELL, top, CELL, CELL), brick, shade)
		# A ledge where the shaft steps in, from the battlements of the wall.
		if storey % step == step - 1 and storey < storeys - 1:
			for x in across:
				draw_texture_rect_region(_run, Rect2(left + x * CELL, top - 18.0, CELL, 30.0),
					Rect2(0.0, 0.0, float(_run.get_width()), 30.0), shade)
		# Windows, staggered, lit low down and dark higher up.
		if storey % 2 == 1:
			for x in range(1, across - 1, 2):
				var at := Vector2(left + x * CELL + CELL * (0.5 if storey % 4 == 1 else 0.0) + CELL * 0.35, top + CELL * 0.3)
				var lit := WINDOW if high < 0.45 else WINDOW_DARK
				draw_rect(Rect2(at, Vector2(CELL * 0.3, CELL * 0.4)), Color(lit, _fade(high)))
	_draw_corner_towers(foot)


## Two towers of the wall's own build stand at the corners of its foot.
func _draw_corner_towers(foot: float) -> void:
	if _tower != null:
		var size := Vector2(_tower.get_width(), _tower.get_height()) * 1.6
		for side: float in [-1.0, 1.0]:
			var x := side * (width * CELL / 2.0) - size.x / 2.0
			draw_texture_rect(_tower, Rect2(Vector2(x, foot - size.y + 8.0), size), false)


## Nearly whole up to [constant FADE_FROM] of the way up, then gone into the sky by the top.
func _fade(high: float) -> float:
	if high <= FADE_FROM:
		return 1.0
	return clampf(1.0 - (high - FADE_FROM) / (1.0 - FADE_FROM), 0.0, 1.0)
