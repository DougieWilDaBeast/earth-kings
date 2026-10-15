extends Control
## The Tower seen from far off (D108): the Tower's picture (art/ui/far_tower.png, drawn in house by
## tools/draw_tower.py until art request A9) standing on the edge of the screen the Tower lies past,
## taller the nearer it is, so it is in sight from the crater on, its door a cold light at its foot.
## It is told where the Tower lies (`look_towards`); it works nothing out for itself. Gone once the
## Tower itself is on the ground being walked.
##
## Loaded by path, not by `class_name` ([D41]).

const PICTURE := preload("res://art/ui/far_tower.png")
## How tall it stands at the far edge of the world and when it is nearly here, in pixels: the
## picture's own size, then twice it, so its pixels stay whole.
const LOW := 320.0
const HIGH := 640.0
const MARGIN := 34.0

var _bearing := Vector2.ZERO
var _near := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	var wide := tall * float(PICTURE.get_width()) / float(PICTURE.get_height())
	# Standing on the bottom edge it rises into view; anywhere else it hangs down from its top.
	foot.y = clampf(foot.y + tall * 0.5, tall * 0.55, size.y - MARGIN * 0.5)
	# Whole on the screen, not cut by its edge.
	foot.x = clampf(foot.x, wide / 2.0 + MARGIN * 0.25, size.x - wide / 2.0 - MARGIN * 0.25)
	var top := foot.y - tall
	draw_texture_rect(PICTURE, Rect2(Vector2(foot.x - wide / 2.0, top), Vector2(wide, tall)), false)
