## Loaded by path ([D41]): `const GroundPainter := preload("res://src/area/ground_painter.gd")`.
extends RefCounted
## Lays an [AreaMap]'s tiles down as [TileMapLayer]s, one per sheet, bottom
## first. The area scene walks on them; a fight started on the ground is fought
## on the very same tiles ([D66]).


## Paint [param map] into [param into]. Sheets drawn at a smaller tile size are
## scaled up so every layer shares the area's cell size.
static func paint(map: AreaMap, into: Node2D) -> void:
	paint_patches(map, map.patches(), into)


## Paint [param patches] (see [method AreaMap.patches]) of [param map]: one part of the land at a
## time, each with its own sheets, each only over its own tiles.
static func paint_patches(map: AreaMap, patches: Array, into: Node2D) -> void:
	for patch: Dictionary in patches:
		var sheets: Array = patch.get("layers", [])
		for index in sheets.size():
			var sheet := Database.tileset_sheet(str(sheets[index]))
			if sheet.is_empty():
				push_warning("GroundPainter: %s has no sheet '%s'" % [map.id, sheets[index]])
				continue
			var tile_set := TileForge.tile_set_for(sheet)
			if tile_set == null:
				continue
			var layer := TileMapLayer.new()
			layer.tile_set = tile_set
			var zoom := float(AreaMap.CELL) / float(sheet.get("tile_size", AreaMap.CELL))
			layer.scale = Vector2(zoom, zoom)
			# Half a cell up and left, so tile corners land on cell centres.
			layer.position = Vector2.ONE * (-AreaMap.CELL / 2.0)
			into.add_child(layer)
			_fill(map, layer, sheet, index > 0, patch.get("tiles", Rect2i(0, 0, map.width + 1, map.height + 1)))


static func _fill(map: AreaMap, layer: TileMapLayer, sheet: Dictionary, is_overlay: bool, tiles: Rect2i) -> void:
	var feature: String = sheet.get("feature", sheet.get("lower", ""))
	var feature_bit := 1 if feature == sheet.get("upper", "") else 0
	# The code a tile gets when the sheet's own terrain is nowhere near it.
	var blank := (1 - feature_bit) * 0b1111
	for y in range(tiles.position.y, tiles.end.y):
		for x in range(tiles.position.x, tiles.end.x):
			var code := map.corner_code(Vector2i(x, y), feature, feature_bit)
			# An upper layer with nothing of its own here lets the one below show.
			if is_overlay and code == blank:
				continue
			layer.set_cell(Vector2i(x, y), TileForge.SOURCE_ID, TileForge.atlas_coords(code))


## The things standing on the ground (trees, rocks, a cold fire), drawn and
## nothing else: for a fight, where they are in the way but say nothing.
static func dress(map: AreaMap, into: Node2D) -> void:
	for entry: Dictionary in map.props:
		if not AreaProp.has_art(str(entry.get("art", ""))):
			continue
		var prop := AreaProp.create(str(entry.get("art", "")))
		prop.position = map.centre_of(entry.get("cell", Vector2i.ZERO))
		into.add_child(prop)
