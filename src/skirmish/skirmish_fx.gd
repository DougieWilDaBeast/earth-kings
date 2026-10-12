extends Node2D
## The fight's feel, drawn with nothing but shapes and text: numbers that jump
## off whoever was hit, a white flash on the hit, a ring where someone fell, and
## a word over the head when something special happens (a critical, a grace).
## Purely for show — nothing here touches the fight.

const RISE := 38.0
const LIFE := 0.9
const FLASH_TIME := 0.12
const RING_TIME := 0.45

const DAMAGE := Color(1.0, 0.97, 0.9)
const HURT := Color(1.0, 0.45, 0.38)
const HEAL := Color(0.5, 1.0, 0.55)
const CRIT := Color(1.0, 0.8, 0.2)
const THORNS := Color(0.85, 0.6, 1.0)
const GRACE := Color(1.0, 0.92, 0.55)
const WORD := Color(0.75, 0.88, 1.0)

## {text, at, colour, size, age, life, drift}
var _popups: Array[Dictionary] = []
## {at, colour, age, radius}
var _rings: Array[Dictionary] = []
## Unit -> seconds of flash left.
var _flashes: Dictionary = {}


func popup(text: String, at: Vector2, colour: Color, size: int = 18, life: float = LIFE) -> void:
	# Several numbers on one unit at once fan out instead of stacking.
	var drift := randf_range(-10.0, 10.0)
	_popups.append({"text": text, "at": at + Vector2(0, -26), "colour": colour, "size": size,
			"age": 0.0, "life": life, "drift": drift})


func flash(unit: Node2D) -> void:
	_flashes[unit] = FLASH_TIME


func ring(at: Vector2, colour: Color, radius: float = 40.0) -> void:
	_rings.append({"at": at, "colour": colour, "age": 0.0, "radius": radius})


func _process(delta: float) -> void:
	for p in _popups:
		p["age"] = float(p["age"]) + delta
	_popups = _popups.filter(func(p: Dictionary) -> bool: return float(p["age"]) < float(p["life"]))
	for r in _rings:
		r["age"] = float(r["age"]) + delta
	_rings = _rings.filter(func(r: Dictionary) -> bool: return float(r["age"]) < RING_TIME)
	for unit: Variant in _flashes.keys():
		if not is_instance_valid(unit):
			_flashes.erase(unit)
			continue
		var left := float(_flashes[unit]) - delta
		var node := unit as Node2D
		if left <= 0.0:
			_flashes.erase(unit)
			node.self_modulate = Color.WHITE
		else:
			_flashes[unit] = left
			var glow := 1.0 + 1.6 * (left / FLASH_TIME)
			node.self_modulate = Color(glow, glow, glow)
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for r in _rings:
		var t := float(r["age"]) / RING_TIME
		var colour: Color = r["colour"]
		draw_arc(r["at"], float(r["radius"]) * (0.3 + t), 0.0, TAU, 32, Color(colour, 1.0 - t), 4.0 * (1.0 - t) + 1.0, true)
	for p in _popups:
		var t := float(p["age"]) / float(p["life"])
		# Pops up fast, then hangs, then fades.
		var lift := RISE * (1.0 - pow(1.0 - minf(t * 1.6, 1.0), 3.0))
		var size := int(p["size"])
		# A critical lands big and settles.
		var punch := 1.0 + 0.5 * maxf(0.0, 1.0 - t * 6.0)
		var drawn := int(round(size * punch))
		var text := str(p["text"])
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, drawn).x
		var at: Vector2 = p["at"] + Vector2(float(p["drift"]) * t - width * 0.5, -lift)
		var alpha := clampf((1.0 - t) * 2.5, 0.0, 1.0)
		var colour: Color = p["colour"]
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, drawn, 4, Color(0, 0, 0, 0.8 * alpha))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, drawn, Color(colour, alpha))
