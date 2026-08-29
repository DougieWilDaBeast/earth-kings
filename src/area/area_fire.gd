class_name AreaFire
extends Node2D
## The campfire the party sits around: a ring of stones, two logs, and a flame
## that never settles. Drawn rather than painted, so it can flicker.
##
## The node sits on the ground at its base, like an [AreaActor], so the y-sorted
## world puts whoever is behind the fire behind it.

const PIT_RADIUS := 26.0
const STONES := 9
const STONE_RADIUS := 6.0
const STONE_COLOUR := Color(0.55, 0.55, 0.58)
const LOG_COLOUR := Color(0.29, 0.19, 0.13)
const EMBER_COLOUR := Color(1.0, 0.45, 0.12, 0.5)

## The flame, innermost last. Height is a multiple of the flicker.
const FLAMES := [
	{ "colour": Color(0.92, 0.28, 0.08, 0.85), "width": 20.0, "height": 54.0 },
	{ "colour": Color(1.0, 0.55, 0.12, 0.9), "width": 13.0, "height": 40.0 },
	{ "colour": Color(1.0, 0.85, 0.4, 0.95), "width": 6.5, "height": 24.0 },
]

## How far the flame and the light stray from their resting size.
const FLICKER := 0.18
const LIGHT_RADIUS := 220.0

var _time: float = 0.0
var _flicker: float = 1.0
var _light: PointLight2D


func _ready() -> void:
	_light = PointLight2D.new()
	_light.texture = _glow_texture()
	_light.color = Color(1.0, 0.72, 0.38)
	_light.energy = 1.5
	_light.position = Vector2(0, -18)
	add_child(_light)


func _process(delta: float) -> void:
	_time += delta
	# Two waves that never line up, so the flame never repeats itself.
	_flicker = 1.0 + FLICKER * (sin(_time * 7.3) * 0.6 + sin(_time * 11.9) * 0.4)
	_light.energy = 1.35 + 0.3 * (_flicker - 1.0) / FLICKER
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, -6), PIT_RADIUS * 0.8, Color(0.16, 0.13, 0.11))
	for i in STONES:
		var angle := TAU * float(i) / float(STONES)
		var at := Vector2(cos(angle) * PIT_RADIUS, sin(angle) * PIT_RADIUS * 0.55 - 6.0)
		draw_circle(at, STONE_RADIUS, STONE_COLOUR)

	draw_line(Vector2(-15, -4), Vector2(14, -12), LOG_COLOUR, 7.0)
	draw_line(Vector2(-13, -14), Vector2(15, -3), LOG_COLOUR, 7.0)
	draw_circle(Vector2(0, -10), 20.0 * _flicker, EMBER_COLOUR)

	for flame: Dictionary in FLAMES:
		draw_colored_polygon(_flame_shape(flame), flame["colour"])


## A teardrop: wide at the embers, pinched at the tip, and leaning with the
## flicker so the whole thing looks alive.
func _flame_shape(flame: Dictionary) -> PackedVector2Array:
	var width: float = flame["width"]
	var height: float = flame["height"] * _flicker
	var lean := sin(_time * 5.1) * width * 0.35
	var base := Vector2(0, -8)
	return PackedVector2Array([
		base + Vector2(-width, 0),
		base + Vector2(-width * 0.55, -height * 0.45),
		base + Vector2(lean, -height),
		base + Vector2(width * 0.55, -height * 0.45),
		base + Vector2(width, 0),
	])


static func _glow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = int(LIGHT_RADIUS * 2)
	texture.height = int(LIGHT_RADIUS * 2)
	return texture
