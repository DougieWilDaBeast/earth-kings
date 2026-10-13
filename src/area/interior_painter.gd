## Loaded by path ([D41]): `const InteriorPainter := preload("res://src/area/interior_painter.gd")`.
extends RefCounted
## The inside of a building: a floor, walls round it, rugs, and the light of the fire.
##
## An area with an `interior` block (`data/areas/*.json`, [D81]) is drawn by this instead of
## from tilesets. Its rows say where the walls stand (`wall` terrain) and where the floor is;
## the block says what they are made of:
##
##   "interior": { "floor": "oak", "wall": "timber",
##                 "rugs": [ { "rect": [x, y, w, h], "colour": "#7a2e2a", "trim": "#c9a45f" } ],
##                 "glows": [ { "cell": [x, y], "radius": 3, "colour": "#ffb060" } ] }
##
## The back wall (the top row) is drawn standing up, its face towards you, so a room reads as a
## room and not a yard; the side and front walls are drawn from above. Pictures are in
## `art/interior/` (stand-ins from tools/draw_interiors.py).

const ROOT := "res://art/interior"
## How tall the back wall's picture is, against the cell it stands on.
const WALL_HEIGHT := 112
## How dark and how deep the shadow the back wall throws on the floor.
const SHADOW := Color(0, 0, 0, 0.32)
const SHADOW_DEPTH := 26.0


static func is_interior(area_id: String) -> bool:
	return Database.area(area_id).has("interior")


static func paint(map: AreaMap, into: Node2D) -> void:
	var spec: Dictionary = Database.area(map.id).get("interior", {})
	var cell := float(AreaMap.CELL)
	var floor_tex := _texture("floor_%s" % str(spec.get("floor", "oak")))
	if floor_tex != null:
		var floor := Sprite2D.new()
		floor.name = "Floor"
		floor.texture = floor_tex
		floor.centered = false
		floor.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		floor.region_enabled = true
		floor.region_rect = Rect2(0, 0, map.width * cell, map.height * cell)
		into.add_child(floor)

	var dressing := Node2D.new()
	dressing.name = "Rugs"
	dressing.draw.connect(_draw_rugs.bind(dressing, spec, map))
	into.add_child(dressing)

	var style := str(spec.get("wall", "timber"))
	var face := _texture("wall_%s" % style)
	var cap := _texture("cap_%s" % style)
	for y in map.height:
		for x in map.width:
			var at := Vector2i(x, y)
			if map.terrain_at(at) != "wall":
				continue
			var piece := Sprite2D.new()
			piece.centered = false
			piece.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			if y == 0 and face != null:
				piece.texture = face
				piece.position = Vector2(x * cell, cell - WALL_HEIGHT)
			elif cap != null:
				piece.texture = cap
				piece.position = Vector2(x * cell, y * cell)
			else:
				continue
			into.add_child(piece)

	var light := Node2D.new()
	light.name = "Glows"
	var glow := _texture("glow")
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for each: Dictionary in spec.get("glows", []):
		if glow == null:
			break
		var at := AreaMap.to_cell(each.get("cell", [0, 0]))
		var spot := Sprite2D.new()
		spot.texture = glow
		spot.material = add
		var reach := float(each.get("radius", 3)) * cell * 2.0 / float(glow.get_width())
		spot.scale = Vector2(reach, reach)
		spot.position = map.centre_of(at)
		var colour := Color(str(each.get("colour", "#ffb060")))
		colour.a = float(each.get("strength", 0.35))
		spot.modulate = colour
		light.add_child(spot)
	into.add_child(light)


## Rugs, the doormat, and the shadow along the foot of the back wall.
static func _draw_rugs(on: Node2D, spec: Dictionary, map: AreaMap) -> void:
	var cell := float(AreaMap.CELL)
	for rug: Dictionary in spec.get("rugs", []):
		var r: Array = rug.get("rect", [0, 0, 1, 1])
		var area := Rect2(float(r[0]) * cell + 6, float(r[1]) * cell + 6,
				float(r[2]) * cell - 12, float(r[3]) * cell - 12)
		var colour := Color(str(rug.get("colour", "#7a2e2a")))
		var trim := Color(str(rug.get("trim", "#c9a45f")))
		on.draw_rect(area.grow(2), Color(0, 0, 0, 0.35))
		on.draw_rect(area, colour)
		on.draw_rect(area.grow(-5), trim, false, 3.0)
		on.draw_rect(area.grow(-11), colour.darkened(0.25), false, 2.0)
		# A row of small lozenges down the middle, the long way, kept inside the border.
		var inner := area.grow(-16)
		var long := inner.size.x >= inner.size.y
		var s := clampf(minf(inner.size.x, inner.size.y) * 0.22, 5.0, 12.0)
		var count := maxi(1, int((inner.size.x if long else inner.size.y) / (s * 3.2)))
		for i in count:
			var t := (float(i) + 0.5) / float(count)
			var c := inner.position + Vector2(inner.size.x * (t if long else 0.5), inner.size.y * (0.5 if long else t))
			on.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)]), trim.darkened(0.1))
			on.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.45), c + Vector2(s * 0.45, 0), c + Vector2(0, s * 0.45), c + Vector2(-s * 0.45, 0)]), colour.darkened(0.3))
		# Fringe at the two short ends.
		for i in range(0, int(area.size.y if long else area.size.x), 5):
			if long:
				on.draw_line(Vector2(area.position.x, area.position.y + i), Vector2(area.position.x - 5, area.position.y + i), trim, 1.0)
				on.draw_line(Vector2(area.end.x, area.position.y + i), Vector2(area.end.x + 5, area.position.y + i), trim, 1.0)
			else:
				on.draw_line(Vector2(area.position.x + i, area.position.y), Vector2(area.position.x + i, area.position.y - 5), trim, 1.0)
				on.draw_line(Vector2(area.position.x + i, area.end.y), Vector2(area.position.x + i, area.end.y + 5), trim, 1.0)
	for exit_cell: Vector2i in map.exits:
		var mat := Rect2(exit_cell.x * cell + 8, exit_cell.y * cell + 14, cell - 16, cell - 22)
		on.draw_rect(mat, Color("#5a4632"))
		on.draw_rect(mat.grow(-4), Color("#3e3024"), false, 2.0)
	on.draw_rect(Rect2(0, cell, map.width * cell, SHADOW_DEPTH), SHADOW)
	on.draw_rect(Rect2(0, cell, map.width * cell, SHADOW_DEPTH * 0.45), SHADOW)


static func _texture(name: String) -> Texture2D:
	var path := "%s/%s.png" % [ROOT, name]
	return load(path) if ResourceLoader.exists(path) else null
