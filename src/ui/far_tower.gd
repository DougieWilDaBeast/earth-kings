extends Control
## The Tower seen from far off (D108): a dark shaft standing on the edge of the screen the
## Tower lies past, taller the nearer it is, so it is in sight from the crater on. It is told
## where the Tower lies (`look_towards`); it works nothing out for itself. Gone once the Tower
## itself is on the ground being walked.
##
## Loaded by path, not by `class_name` ([D41]).

const STONE := Color(0.3, 0.28, 0.4, 0.9)
const EDGE := Color(0.85, 0.8, 1.0, 0.8)
const LIGHT := Color("#f0c268")
## How tall it stands at the far edge of the world and when it is nearly here, in pixels.
const LOW := 130.0
const HIGH := 280.0
const MARGIN := 34.0

var _bearing := Vector2.ZERO
var _near := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Stand it on the edge of the screen [param bearing] points past (x east, y south), [param tiles]
## tiles away. Nothing, or no way, hides it.
func look_towards(bearing: Vector2, tiles: int) -> void:
	_bearing = bearing
	_near = clampf(1.0 - float(tiles) / 20.0, 0.0, 1.0)
	visible = bearing.length() > 0.01 and tiles > 1
	queue_redraw()


func _draw() -> void:
	if _bearing.length() < 0.01:
		return
	var half := size / 2.0
	var way := _bearing.normalized()
	# Where a line from the middle of the screen along the bearing leaves it.
	var reach := INF
	if absf(way.x) > 0.001:
		reach = minf(reach, (half.x - MARGIN) / absf(way.x))
	if absf(way.y) > 0.001:
		reach = minf(reach, (half.y - MARGIN) / absf(way.y))
	var foot := half + way * reach
	var tall := lerpf(LOW, HIGH, _near)
	var wide := tall * 0.24
	# Standing on the bottom edge it rises into view; anywhere else it hangs down from its top.
	foot.y = clampf(foot.y + tall * 0.5, tall, size.y - MARGIN * 0.5)
	var top := foot.y - tall
	var shaft := PackedVector2Array([
		Vector2(foot.x - wide / 2.0, foot.y), Vector2(foot.x + wide / 2.0, foot.y),
		Vector2(foot.x + wide * 0.32, top), Vector2(foot.x - wide * 0.32, top),
	])
	var colours := PackedColorArray([STONE, STONE, Color(STONE, 0.0), Color(STONE, 0.0)])
	draw_polygon(shaft, colours)
	draw_polyline(PackedVector2Array([shaft[3], shaft[0], shaft[1], shaft[2]]), EDGE, 2.0, true)
	for i in 4:
		var at := Vector2(foot.x + (wide * 0.12 if i % 2 == 0 else -wide * 0.12), foot.y - tall * (0.15 + 0.12 * i))
		draw_rect(Rect2(at - Vector2(2.0, 3.0), Vector2(4.0, 6.0)), Color(LIGHT, 0.8 - 0.18 * i))
