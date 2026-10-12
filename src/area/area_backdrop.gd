extends Node2D
## A ground as it looks, with nobody on it: its tiles, houses, scenery and chests. The ground
## itself paints its tiles with [method paint_layers]; a fight met on the ground puts a whole
## backdrop under its field, so it is fought where the party stood ([D66]).
##
## Drawn in the ground's own pixels (a 64-pixel cell); whoever shows it scales and moves it.
## Loaded by path ([D41]).


## One [TileMapLayer] per sheet of [param map], bottom first, under [param parent].
static func paint_layers(map: AreaMap, parent: Node) -> void:
	for index in map.layers.size():
		var sheet := Database.tileset_sheet(map.layers[index])
		if sheet.is_empty():
			push_warning("Area: %s has no sheet '%s'" % [map.id, map.layers[index]])
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
		parent.add_child(layer)
		_fill_layer(map, layer, sheet, index > 0)


static func _fill_layer(map: AreaMap, layer: TileMapLayer, sheet: Dictionary, is_overlay: bool) -> void:
	var feature: String = sheet.get("feature", sheet.get("lower", ""))
	var feature_bit := 1 if feature == sheet.get("upper", "") else 0
	# The code a tile gets when the sheet's own terrain is nowhere near it.
	var blank := (1 - feature_bit) * 0b1111
	for y in range(0, map.height + 1):
		for x in range(0, map.width + 1):
			var code := map.corner_code(Vector2i(x, y), feature, feature_bit)
			# An upper layer with nothing of its own here lets the one below show.
			if is_overlay and code == blank:
				continue
			layer.set_cell(Vector2i(x, y), TileForge.SOURCE_ID, TileForge.atlas_coords(code))


## The whole ground of [param area_id], or null if there is no such area.
static func of(area_id: String) -> Node2D:
	var map := AreaMap.load_area(area_id)
	if map == null:
		return null
	var backdrop: Node2D = (load("res://src/area/area_backdrop.gd") as GDScript).new()
	backdrop.name = "Backdrop"
	var tiles := Node2D.new()
	backdrop.add_child(tiles)
	paint_layers(map, tiles)
	var standing := Node2D.new()
	standing.y_sort_enabled = true
	backdrop.add_child(standing)
	for building: Dictionary in map.buildings:
		standing.add_child(AreaBuilding.create(building))
	for prop: Dictionary in map.props:
		if not AreaProp.has_art(str(prop.get("art", ""))):
			continue
		var node := AreaProp.from_entry(prop)
		node.position = map.centre_of(prop["cell"])
		var nudge: Array = prop.get("offset", [])
		if nudge.size() >= 2:
			node.position += Vector2(float(nudge[0]), float(nudge[1]))
		node.set_interactive(false)
		standing.add_child(node)
	for cell: Vector2i in map.chests:
		var chest: Dictionary = map.chests[cell]
		var opened := GameState.has_flag(map.chest_flag(cell))
		var node := AreaProp.create(chest.get("opened_art", "chest_open") if opened else str(chest.get("art", "chest")))
		node.position = map.centre_of(cell)
		standing.add_child(node)
	# The light the place is seen in, on the place alone: not on the fighters or the orders.
	if map.tint != "":
		backdrop.modulate = Color(map.tint).lerp(Color.WHITE, 0.35)
	return backdrop
