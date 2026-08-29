class_name AreaMark
extends Label
## The mark that floats over anybody — or anything — in an area worth stopping
## for. It bobs on its own, so whoever it hangs over never has to think about it.

## How far above the feet it floats, how far it bobs, and how fast.
const HEIGHT := 86.0
const BOB := 5.0
const SPEED := 3.4
## Dim while it is only worth noticing, bright once you are close enough.
const FAR := Color(0.86, 0.78, 0.5, 0.7)
const NEAR := Color(1.0, 0.85, 0.3)

var _bob: float = 0.0
var _height: float = HEIGHT


static func create(glyph: String, width: float, height: float = HEIGHT) -> AreaMark:
	var mark := AreaMark.new()
	mark.text = glyph
	mark._height = height
	mark.size = Vector2(width, 32)
	mark.position = Vector2(-width / 2.0, -height)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.modulate = FAR
	mark.add_theme_font_size_override("font_size", 30)
	mark.add_theme_constant_override("outline_size", 8)
	mark.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08))
	mark.add_theme_color_override("font_color", Color.WHITE)
	return mark


## Brighten the mark once the leader is close enough to act on it.
func set_ready(ready: bool) -> void:
	modulate = NEAR if ready else FAR


func _process(delta: float) -> void:
	_bob += delta * SPEED
	position.y = -_height + sin(_bob) * BOB
