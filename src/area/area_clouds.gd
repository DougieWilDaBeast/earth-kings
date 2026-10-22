extends Node2D
## The clouds below a mountain's top ([D287]: "from the highest places clouds show below"; [D321]):
## every cloud cell is drawn as pale sky with slow white banks drifting over it, so the drop off the
## summit reads as a long way down. Drawn over the ground and under the edges' rims. Nothing here
## changes the map; [AreaMap.is_cloud] says where the clouds are.
##
## Once the cloud sheet (art request A50) is in, the `cloud` sheet of data/tilesets.json, the clouds
## are laid from it as corner tiles ([D370]), the summit's edge running into them, with the banks
## still drifting over; until then the pale sky is drawn here.

const SKY := Color(0.74, 0.8, 0.88)
const BANK := Color(0.97, 0.98, 1.0, 0.75)
const SHADE := Color(0.62, 0.68, 0.78, 0.55)
## Pixels a second the banks drift.
const DRIFT := 5.0

var map: AreaMap = null
var _cells: Array[Vector2i] = []
var _time: float = 0.0
## The drawn clouds, when the sheet is in.
var _sheet_layer: TileMapLayer = null


func _ready() -> void:
	if map == null:
		return
	for y in map.height:
		for x in map.width:
			if map.is_cloud(Vector2i(x, y)):
				_cells.append(Vector2i(x, y))
	_lay_the_sheet()


## The cloud sheet's tiles under every corner a cloud cell touches, as [GroundPainter] lays the
## ground: each tile's code from the four cells round its corner, cloud or not.
func _lay_the_sheet() -> void:
	var sheet := Database.tileset_sheet("cloud")
	var wanted := str(sheet.get("texture_wanted", ""))
	if _cells.is_empty() or wanted == "" or not ResourceLoader.exists(wanted):
		return
	var tile_set := TileForge.tile_set_for(sheet)
	if tile_set == null:
		return
	_sheet_layer = TileMapLayer.new()
	_sheet_layer.tile_set = tile_set
	_sheet_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	var zoom := float(AreaMap.CELL) / float(sheet.get("tile_size", AreaMap.CELL))
	_sheet_layer.scale = Vector2(zoom, zoom)
	_sheet_layer.position = Vector2.ONE * (-AreaMap.CELL / 2.0)
	# Under the banks this node draws.
	_sheet_layer.show_behind_parent = true
	add_child(_sheet_layer)
	var corners := {}
	for cell in _cells:
		for dy in 2:
			for dx in 2:
				corners[cell + Vector2i(dx, dy)] = true
	for corner: Vector2i in corners:
		var code := _bit(corner + Vector2i(-1, -1)) * 8 + _bit(corner + Vector2i(0, -1)) * 4 \
				+ _bit(corner + Vector2i(-1, 0)) * 2 + _bit(corner)
		_sheet_layer.set_cell(corner, TileForge.SOURCE_ID, TileForge.atlas_coords(code))


func _bit(cell: Vector2i) -> int:
	return 1 if map.is_cloud(cell) else 0


func _process(delta: float) -> void:
	if _cells.is_empty():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var size := float(AreaMap.CELL)
	if _sheet_layer == null:
		for cell in _cells:
			draw_rect(Rect2(Vector2(cell) * size, Vector2(size, size)), SKY)
	# Three banks to a cell, each a shaded puff under a white one, sliding east and wrapping in the cell.
	for cell in _cells:
		var corner := Vector2(cell) * size
		var seed_val := absi(hash(cell))
		for i in 3:
			var along := fmod(float((seed_val >> (i * 5)) % 64) + _time * DRIFT * (1.0 + 0.3 * i), size)
			var down := float((seed_val >> (i * 3 + 2)) % int(size * 0.7)) + size * 0.15
			var radius := size * (0.16 + 0.04 * float((seed_val >> i) % 3))
			var at := corner + Vector2(along, down)
			var room := minf(radius, minf(at.x - corner.x, (corner.x + size - at.x) / 1.5))
			if room < 3.0:
				continue
			draw_circle(at + Vector2(0, room * 0.3), room, SHADE)
			draw_circle(at, room, BANK)
			draw_circle(at + Vector2(room * 0.8, room * 0.15), room * 0.7, BANK)
