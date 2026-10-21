extends Node2D
## The clouds below a mountain's top ([D287]: "from the highest places clouds show below"; [D321]):
## every cloud cell is drawn as pale sky with slow white banks drifting over it, so the drop off the
## summit reads as a long way down. Drawn over the ground and under the edges' rims. Nothing here
## changes the map; [AreaMap.is_cloud] says where the clouds are.

const SKY := Color(0.74, 0.8, 0.88)
const BANK := Color(0.97, 0.98, 1.0, 0.75)
const SHADE := Color(0.62, 0.68, 0.78, 0.55)
## Pixels a second the banks drift.
const DRIFT := 5.0

var map: AreaMap = null
var _cells: Array[Vector2i] = []
var _time: float = 0.0


func _ready() -> void:
	if map == null:
		return
	for y in map.height:
		for x in map.width:
			if map.is_cloud(Vector2i(x, y)):
				_cells.append(Vector2i(x, y))


func _process(delta: float) -> void:
	if _cells.is_empty():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var size := float(AreaMap.CELL)
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
