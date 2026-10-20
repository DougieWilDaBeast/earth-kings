extends Node2D
## The edges of higher ground ([D287], [D308]): where a cell stands a height over its neighbour, a
## dark rim along the top of the drop and a shadow cast on the lower ground, so a shelf reads as a
## shelf before anyone walks off it. Drawn over the ground, under everyone standing on it. Nothing
## here changes the map; [AreaMap.may_step] says what can be climbed.

const RIM := Color(0.08, 0.08, 0.1, 0.8)
const RIM_WIDTH := 3.0
const SHADOW := Color(0.0, 0.0, 0.0, 0.28)
const SHADOW_DEPTH := 12.0
const LIP := Color(1.0, 1.0, 0.94, 0.22)

var map: AreaMap = null


func _draw() -> void:
	if map == null or not map.has_heights():
		return
	var size := float(AreaMap.CELL)
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			var here := map.height_at(cell)
			if here <= 0:
				continue
			var corner := Vector2(cell) * size
			# Each side that drops: a rim on the edge, a shadow on the ground below it.
			if map.in_bounds(cell + Vector2i.DOWN) and map.height_at(cell + Vector2i.DOWN) < here:
				draw_line(corner + Vector2(0, size), corner + Vector2(size, size), RIM, RIM_WIDTH)
				draw_rect(Rect2(corner + Vector2(0, size), Vector2(size, SHADOW_DEPTH)), SHADOW)
			if map.in_bounds(cell + Vector2i.UP) and map.height_at(cell + Vector2i.UP) < here:
				draw_line(corner, corner + Vector2(size, 0), RIM, RIM_WIDTH)
				draw_line(corner + Vector2(0, RIM_WIDTH), corner + Vector2(size, RIM_WIDTH), LIP, 1.0)
			if map.in_bounds(cell + Vector2i.LEFT) and map.height_at(cell + Vector2i.LEFT) < here:
				draw_line(corner, corner + Vector2(0, size), RIM, RIM_WIDTH)
				draw_rect(Rect2(corner - Vector2(SHADOW_DEPTH * 0.5, 0), Vector2(SHADOW_DEPTH * 0.5, size)), SHADOW)
			if map.in_bounds(cell + Vector2i.RIGHT) and map.height_at(cell + Vector2i.RIGHT) < here:
				draw_line(corner + Vector2(size, 0), corner + Vector2(size, size), RIM, RIM_WIDTH)
				draw_rect(Rect2(corner + Vector2(size, 0), Vector2(SHADOW_DEPTH * 0.5, size)), SHADOW)
