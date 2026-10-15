extends Control
## The Tower seen from far off (D108): the Tower's picture (art/ui/far_tower.png, drawn in house by
## tools/draw_tower.py until art request A9) standing on the edge of the screen the Tower lies past,
## taller the nearer it is, so it is in sight from the crater on, its door a cold light at its foot.
## It is told where the Tower lies (`look_towards`); it works nothing out for itself. Gone once the
## Tower itself is on the ground being walked.
##
## Loaded by path, not by `class_name` ([D41]).

const PICTURE := preload("res://art/ui/far_tower.png")
## How tall it stands at the far edge of the world and when it is nearly here, in pixels: half the
## picture's size, then the picture's own, so its pixels stay whole. Small, on the horizon, and never
## in front of the ground being walked (meeting 4: at Greyhollow it covered the view).
const LOW := 160.0
const HIGH := 320.0
## Where the horizon it stands on runs, as a share of the screen's height from the top.
const HORIZON := 0.3
const MARGIN := 34.0
## The top-left corner holds the place's name and the compass; the Tower keeps clear of it.
const CORNER := 300.0

var _bearing := Vector2.ZERO
var _near := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Stand it on the horizon towards [param bearing] (x east, y south), [param tiles] tiles away. It
## stays in sight until the party is on the Tower's own tile, where the Tower itself stands (meeting
## 4: it vanished two tiles out of Stormreach).
func look_towards(bearing: Vector2, tiles: int) -> void:
	_bearing = bearing
	_near = clampf(1.0 - float(tiles) / 20.0, 0.0, 1.0)
	visible = bearing.length() > 0.01 and tiles > 0
	queue_redraw()


func _draw() -> void:
	if _bearing.length() < 0.01:
		return
	var way := _bearing.normalized()
	var tall := lerpf(LOW, HIGH, _near)
	var wide := tall * float(PICTURE.get_width()) / float(PICTURE.get_height())
	# Across the horizon by how far east or west it lies; behind the party it sits at the edge it is
	# nearest, a little dimmer.
	var left := minf(CORNER, size.x * 0.3) + wide / 2.0
	var right := size.x - wide / 2.0 - MARGIN * 0.5
	var x := lerpf(left, right, (way.x + 1.0) / 2.0)
	var foot := Vector2(x, size.y * HORIZON)
	var shade := Color(1, 1, 1, 0.6 if way.y > 0.7 else 0.9)
	draw_texture_rect(PICTURE, Rect2(Vector2(foot.x - wide / 2.0, foot.y - tall), Vector2(wide, tall)), false, shade)
