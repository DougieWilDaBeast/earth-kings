extends Node2D
## The fight's feel: numbers that jump off whoever was hit, a white flash on the
## hit, a ring where someone fell, a word over the head when something special
## happens (a critical, a grace), and the drawn effects in `art/effects` — a slash,
## an arrow in flight, a burst, a heal, a block. Which effect goes with what is
## `effects` in `data/skirmish.json`. Purely for show — nothing here touches the fight.

const RISE := 38.0
const LIFE := 0.9
const FLASH_TIME := 0.12
const RING_TIME := 0.45
## A level gained: the body flickers gold this many times over this long ([D77]).
const GOLD_TIME := 1.1
const GOLD_PULSES := 3

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
## Unit -> seconds of gold flicker left.
var _golds: Dictionary = {}
## Drawn effects playing: {frames, at, from, age, life}. `from` is where a shot
## set off from, or `at` itself for one that plays where it lands.
var _effects: Array[Dictionary] = []

## Effect name -> its frames, and icon name -> its texture, loaded once.
static var _frames: Dictionary = {}
static var _icons: Dictionary = {}
## Effect name -> times played, for the smoke test (as [member Sfx.counts]).
static var played: Dictionary = {}

## An arrow is drawn pointing down and to the left.
const ARROW_POINTS := Vector2(-1.0, 1.0)
## Seconds a shot takes to cross to whoever it hit.
const SHOT_TIME := 0.22


## The effect `data/skirmish.json` names for [param kind] ("swing", "shot",
## "spell", "heal", "block", "charged"), or the one named for [param ability_id]
## when it has its own. "" when there is none.
static func effect_for(kind: String, ability_id: String = "") -> String:
	var data: Dictionary = Database.skirmish.get("effects", {})
	var own := str(data.get("by_ability", {}).get(ability_id, ""))
	return own if own != "" else str(data.get(kind, ""))


## An effect's frames, `frame_000.png` onwards; empty when it is not there.
static func effect_frames(name: String) -> Array:
	if name == "":
		return []
	if _frames.has(name):
		return _frames[name]
	var folder := str(Database.skirmish.get("effects", {}).get("folder", "res://art/effects"))
	var frames: Array = []
	while true:
		var path := "%s/%s/frame_%03d.png" % [folder, name, frames.size()]
		if not ResourceLoader.exists(path):
			break
		frames.append(load(path))
	_frames[name] = frames
	return frames


## A status icon from `art/ui/status`, or null when it is not there.
static func status_icon(name: String) -> Texture2D:
	if name == "":
		return null
	if _icons.has(name):
		return _icons[name]
	var folder := str(Database.skirmish.get("status_icons", {}).get("folder", "res://art/ui/status"))
	var path := "%s/%s.png" % [folder, name]
	var icon: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_icons[name] = icon
	return icon


## Seconds a frame of an effect is shown.
static func frame_time() -> float:
	return 1.0 / maxf(1.0, float(Database.skirmish.get("effects", {}).get("fps", 18.0)))


## How big an effect is drawn, on the grid: one tile times this.
static func effect_size() -> float:
	return BattleGrid.CELL_SIZE * float(Database.skirmish.get("effects", {}).get("size", 1.1))


## Play the effect named [param name] once at [param at]. With [param from], it
## flies from there to [param at] over its frames (an arrow), turned to face the way it goes.
func effect(name: String, at: Vector2, from: Variant = null) -> void:
	var frames := effect_frames(name)
	if frames.is_empty():
		return
	played[name] = int(played.get(name, 0)) + 1
	_effects.append({"frames": frames, "at": at, "from": at if from == null else from,
			"age": 0.0, "life": frame_time() * frames.size() if from == null else SHOT_TIME})


func popup(text: String, at: Vector2, colour: Color, size: int = 18, life: float = LIFE) -> void:
	# Several numbers on one unit at once fan out instead of stacking.
	var drift := randf_range(-10.0, 10.0)
	_popups.append({"text": text, "at": at + Vector2(0, -26), "colour": colour, "size": size,
			"age": 0.0, "life": life, "drift": drift})


func flash(unit: Node2D) -> void:
	_flashes[unit] = FLASH_TIME


## The body flickers gold a few times: somebody gained a level ([D77]).
func gold(unit: Node2D) -> void:
	_golds[unit] = GOLD_TIME


func ring(at: Vector2, colour: Color, radius: float = 40.0) -> void:
	_rings.append({"at": at, "colour": colour, "age": 0.0, "radius": radius})


func _process(delta: float) -> void:
	for p in _popups:
		p["age"] = float(p["age"]) + delta
	_popups = _popups.filter(func(p: Dictionary) -> bool: return float(p["age"]) < float(p["life"]))
	for r in _rings:
		r["age"] = float(r["age"]) + delta
	_rings = _rings.filter(func(r: Dictionary) -> bool: return float(r["age"]) < RING_TIME)
	for e in _effects:
		e["age"] = float(e["age"]) + delta
	_effects = _effects.filter(func(e: Dictionary) -> bool: return float(e["age"]) < float(e["life"]))
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
	# After the hit flash, so a level gained mid-blow still shows gold.
	for unit: Variant in _golds.keys():
		if not is_instance_valid(unit):
			_golds.erase(unit)
			continue
		var left := float(_golds[unit]) - delta
		var node := unit as Node2D
		if left <= 0.0:
			_golds.erase(unit)
			if not _flashes.has(unit):
				node.self_modulate = Color.WHITE
			continue
		_golds[unit] = left
		var t := 1.0 - left / GOLD_TIME
		# GOLD_PULSES soft pulses, each fainter than the last.
		var pulse := maxf(0.0, sin(t * PI * float(GOLD_PULSES) * 2.0)) * (1.0 - t * 0.6)
		node.self_modulate = Color.WHITE.lerp(Color(1.9, 1.55, 0.55), pulse)
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var side := effect_size()
	for e in _effects:
		var frames: Array = e["frames"]
		var t := float(e["age"]) / float(e["life"])
		var texture: Texture2D = frames[mini(frames.size() - 1, int(t * frames.size()))]
		var from: Vector2 = e["from"]
		var to: Vector2 = e["at"]
		if from == to:
			draw_texture_rect(texture, Rect2(to - Vector2(side, side) * 0.5, Vector2(side, side)), false)
			continue
		# A shot: carried along the line and turned to point the way it flies.
		draw_set_transform(from.lerp(to, t), (to - from).angle() - ARROW_POINTS.angle())
		draw_texture_rect(texture, Rect2(-Vector2(side, side) * 0.5, Vector2(side, side)), false)
		draw_set_transform(Vector2.ZERO)
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
