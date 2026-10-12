class_name TitleFall
extends Control
## The sixteen, falling: bright heads with burning tails, streaking down the sky
## behind the title towards the world ([docs/17](../../docs/17-the-sixteen-worlds.md)).
##
## There are always exactly sixteen. Each one falls, flares where it meets the
## edge of the world, waits a while, and falls again from somewhere new. Near
## ones are big, fast and bright; far ones small, slow and dim.

const COUNT := 16
## Where the land starts, as a share of the height. Matches the backdrop shader.
const HORIZON := 0.80
## The way they fall: down and a little to the left, towards the world.
const HEADING := Vector2(-0.42, 1.0)
const TRAIL_STEPS := 14
const FLARE_TIME := 0.7

var _streaks: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	for i in COUNT:
		var streak := {}
		_launch(streak, true)
		_streaks.append(streak)


func _process(delta: float) -> void:
	if size.x <= 0.0:
		return
	var dir := HEADING.normalized()
	for streak: Dictionary in _streaks:
		if float(streak["wait"]) > 0.0:
			streak["wait"] = float(streak["wait"]) - delta
			continue
		if float(streak["flare"]) > 0.0:
			streak["flare"] = float(streak["flare"]) - delta
			if float(streak["flare"]) <= 0.0:
				_launch(streak, false)
			continue
		var pos: Vector2 = streak["pos"]
		pos += dir * float(streak["speed"]) * delta
		streak["pos"] = pos
		if pos.y >= _land_at(pos.x) or pos.x < -40.0:
			streak["flare"] = FLARE_TIME
	queue_redraw()


func _draw() -> void:
	var dir := HEADING.normalized()
	for streak: Dictionary in _streaks:
		if float(streak["wait"]) > 0.0:
			continue
		var pos: Vector2 = streak["pos"]
		var depth: float = streak["depth"]
		var tint: Color = streak["tint"]
		if float(streak["flare"]) > 0.0:
			_draw_flare(pos, depth, tint, float(streak["flare"]) / FLARE_TIME)
			continue
		_draw_tail(pos, dir, float(streak["length"]), depth, tint)
		_draw_head(pos, depth, tint)


## A tapering ribbon, hot near the head and fading out behind it.
func _draw_tail(head: Vector2, dir: Vector2, length: float, depth: float, tint: Color) -> void:
	var side := Vector2(-dir.y, dir.x)
	var width := lerpf(1.2, 5.0, depth)
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var back := PackedVector2Array()
	var back_colors := PackedColorArray()
	for i in TRAIL_STEPS + 1:
		var f := float(i) / float(TRAIL_STEPS)
		var at := head - dir * length * f
		var w := width * (1.0 - f) + 0.2
		var c := tint.lerp(Color(1.0, 0.35, 0.12), f)
		c.a = (1.0 - f) * lerpf(0.35, 0.95, depth)
		points.append(at + side * w)
		colors.append(c)
		back.append(at - side * w)
		back_colors.append(c)
	back.reverse()
	back_colors.reverse()
	points.append_array(back)
	colors.append_array(back_colors)
	draw_polygon(points, colors)


func _draw_head(at: Vector2, depth: float, tint: Color) -> void:
	var r := lerpf(1.5, 4.5, depth)
	for ring in 4:
		var c := tint
		c.a = 0.10 * lerpf(0.5, 1.0, depth)
		draw_circle(at, r * (3.6 - ring * 0.7), c)
	draw_circle(at, r, Color(1.0, 0.97, 0.88, 0.95))


## The moment one strikes the world: a bloom that swells and fades.
func _draw_flare(at: Vector2, depth: float, tint: Color, left: float) -> void:
	var grow := 1.0 - left
	var r := lerpf(6.0, 26.0, depth) * (0.4 + grow)
	for ring in 3:
		var c := tint
		c.a = left * 0.22 / float(ring + 1)
		draw_circle(at, r * (1.0 + ring * 0.8), c)
	var core := Color(1.0, 0.95, 0.8, left * 0.8)
	draw_circle(at, r * 0.25, core)


## Sets a streak off from somewhere above the screen. On the first frame they
## are spread through the fall already, so the sky is not empty while they come.
func _launch(streak: Dictionary, first: bool) -> void:
	var w := maxf(size.x, 1280.0)
	var h := maxf(size.y, 720.0)
	var depth := pow(_rng.randf(), 1.6)
	streak["depth"] = depth
	streak["speed"] = lerpf(70.0, 260.0, depth)
	streak["length"] = lerpf(60.0, 300.0, depth)
	# Mostly warm, the odd one paler: sixteen people, not one fire.
	var hue := _rng.randf_range(0.04, 0.13) if _rng.randf() < 0.8 else _rng.randf_range(0.52, 0.62)
	streak["tint"] = Color.from_hsv(hue, _rng.randf_range(0.35, 0.7), 1.0)
	streak["flare"] = 0.0
	# Start far enough right that the path crosses the sky before the land.
	var x := _rng.randf_range(0.15, 1.25) * w
	if first:
		streak["pos"] = Vector2(x, _rng.randf_range(-0.2, HORIZON * 0.9) * h)
		streak["wait"] = _rng.randf_range(0.0, 2.0)
	else:
		streak["pos"] = Vector2(x, -_rng.randf_range(20.0, 160.0))
		streak["wait"] = _rng.randf_range(0.6, 4.5)


func _land_at(x: float) -> float:
	var u := x / maxf(size.x, 1.0)
	return size.y * (HORIZON + 0.05 * pow(u - 0.5, 2.0) * 4.0)
