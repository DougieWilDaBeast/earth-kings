extends Node2D
## Something small and alive on the ground ([D168]): a bird pecking about that takes off as the party
## comes near and lands again further off, a butterfly or a bee fluttering round where it lives, a
## grasshopper that hops, a snail or a spider that creeps. It stands in the way of nothing and says
## nothing; it is there so the land is not empty (`doug-md`, play-test 3).
##
## What a picture does is its `life` in `data/props.json` (`bird`, `flutter`, `hop`, `crawl`); how far
## it shies from the party and how fast it goes are `data/world_rules.json` → `life`. One picture,
## moved by code: hops, a bob, wings beating as a squash. Loaded by path ([D41]).

## What kind of life this is.
var life: String = "bird"
var art: String = ""
## Where it lives: a flutterer circles it, a bird comes back near it.
var home: Vector2 = Vector2.ZERO
## Where the party's leader is, or [constant Vector2.INF] when there is nobody to shy from.
var watching: Callable = Callable()
## Whether a point on the ground can be stood on, for somewhere to land.
var can_land: Callable = Callable()

var _sprite: Sprite2D
var _rng := RandomNumberGenerator.new()
var _rest: float = 0.0
var _clock: float = 0.0
## In the air (a bird's flight or a hop): from, to, how long, how far through, how high it goes.
var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _span: float = 0.0
var _through: float = 1.0
var _arc: float = 0.0
var _lift: float = 0.0
var _gone: float = 0.0
var _base_y: float = 0.0
var _size: float = 1.0
var _orbit := Vector2(18, 10)


## `data/world_rules.json` → `life`.
static func rule(key: String, fallback: Variant) -> Variant:
	return Database.world_rules.get("life", {}).get(key, fallback)


## What [param art] does when it lives on the ground, or "" for a picture that only stands there.
static func life_of(art_id: String) -> String:
	return str(Database.prop_size(art_id).get("life", ""))


static func make(art_id: String, at: Vector2, seed_: int) -> Node2D:
	var critter: Node2D = (load("res://src/area/area_critter.gd") as GDScript).new()
	critter.art = art_id
	critter.life = life_of(art_id)
	critter.position = at
	critter.home = at
	critter._rng.seed = seed_
	critter._build()
	return critter


func _build() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.centered = false
	add_child(_sprite)
	var path := "%s/%s.png" % [AreaProp.ART_ROOT, art]
	if not ResourceLoader.exists(path):
		return
	var texture: Texture2D = load(path)
	_sprite.texture = texture
	_size = float(Database.prop_size(art)["scale"])
	var painted: Rect2 = AreaProp.painted_rect(art, texture)
	_sprite.scale = Vector2(_size, _size)
	_sprite.position = Vector2(-painted.get_center().x * _size, AreaProp.GROUND - painted.end.y * _size)
	_base_y = _sprite.position.y
	_sprite.flip_h = _rng.randf() < 0.5
	_rest = _rng.randf_range(0.2, 3.0)
	_clock = _rng.randf_range(0.0, 10.0)
	_orbit = Vector2(_rng.randf_range(14, 30), _rng.randf_range(8, 18))


func _process(delta: float) -> void:
	_clock += delta
	match life:
		"bird":
			_bird(delta)
		"flutter":
			_flutter(delta)
		"hop":
			_hop(delta)
		"crawl":
			_crawl(delta)
	_sprite.position.y = _base_y - _lift
	queue_redraw()


## A shadow under anything off the ground, so a flier reads as up in the air.
func _draw() -> void:
	if _lift <= 1.0 or not visible:
		return
	var width := 7.0 * _size
	draw_set_transform(Vector2(0, AreaProp.GROUND), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, width, Color(0, 0, 0, clampf(0.32 - _lift / 300.0, 0.08, 0.3)))


func _leader() -> Vector2:
	return watching.call() if watching.is_valid() else Vector2.INF


func _near(cells: float) -> bool:
	var at := _leader()
	return at != Vector2.INF and at.distance_to(position) <= cells * AreaMap.CELL


## Pecking about: a hop now and then, a turn; up and away when the party comes close, and down again
## somewhere it can stand, a few cells off.
func _bird(delta: float) -> void:
	if _gone > 0.0:
		_gone -= delta
		if _gone <= 0.0 and not _near(float(rule("shy_cells", 2.4)) * 2.0):
			position = home
			_lift = 0.0
			modulate.a = 1.0
			visible = true
		return
	if _through < 1.0:
		_fly_on(delta, true)
		return
	_sprite.scale.y = _size
	if _near(float(rule("shy_cells", 2.4))):
		_take_off()
		return
	_rest -= delta
	if _rest > 0.0:
		return
	_rest = _rng.randf_range(0.8, 3.2)
	if _rng.randf() < 0.45:
		_sprite.flip_h = not _sprite.flip_h
	else:
		var step := Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf_range(6.0, 16.0)
		_launch(position + step, 0.22, 7.0)


func _take_off() -> void:
	var leader := _leader()
	var away := (position - leader).normalized() if leader != Vector2.INF else Vector2.UP
	if away == Vector2.ZERO:
		away = Vector2.UP
	var reach := _rng.randf_range(float(rule("flee_cells", [5.0, 9.0])[0]), float(rule("flee_cells", [5.0, 9.0])[1])) * AreaMap.CELL
	var land := Vector2.INF
	for i in 8:
		var spot := position + away.rotated(_rng.randf_range(-0.7, 0.7)) * reach
		if not can_land.is_valid() or bool(can_land.call(spot)):
			land = spot
			break
	if land == Vector2.INF:
		# Nowhere to come down near: off out of sight, and back when the party has gone.
		land = position + away * reach * 1.6
		_gone = -1.0
	_launch(land, float(rule("flight_seconds", 1.4)), float(rule("flight_height", 70.0)))
	_sprite.flip_h = away.x < 0.0


func _launch(to: Vector2, seconds: float, height: float) -> void:
	_from = position
	_to = to
	_span = maxf(0.05, seconds)
	_through = 0.0
	_arc = height


func _fly_on(delta: float, flapping: bool) -> void:
	_through = minf(1.0, _through + delta / _span)
	position = _from.lerp(_to, _through)
	_lift = sin(_through * PI) * _arc
	if flapping and _arc > 20.0:
		_sprite.scale.y = _size * (0.72 + 0.28 * absf(sin(_clock * 22.0)))
	if _through >= 1.0:
		_lift = 0.0
		_sprite.scale.y = _size
		if _gone < 0.0:
			# Flown off with nowhere to land: gone a while, then back home if nobody is there.
			visible = false
			_gone = float(rule("away_seconds", 12.0))
		else:
			home = home.lerp(position, 0.5)


## Round and round where it lives, a little above the ground, wings going; it drifts off a little
## from the party rather than fleeing.
func _flutter(delta: float) -> void:
	var drift := Vector2(sin(_clock * 0.9) * _orbit.x, sin(_clock * 1.7) * _orbit.y)
	var target := home + drift
	if _near(1.2):
		var leader := _leader()
		target += (position - leader).normalized() * AreaMap.CELL * 0.8
	position = position.lerp(target, minf(1.0, delta * 2.0))
	_lift = 16.0 + sin(_clock * 3.1) * 5.0
	_sprite.scale.x = _size * (0.55 + 0.45 * absf(sin(_clock * 16.0)))
	_sprite.flip_h = cos(_clock * 0.9) < 0.0


## Still a while, then a hop; away from the party when it comes close.
func _hop(delta: float) -> void:
	if _through < 1.0:
		_fly_on(delta, false)
		return
	_rest -= delta
	var shy := _near(1.6)
	if _rest > 0.0 and not shy:
		return
	_rest = _rng.randf_range(1.5, 4.5)
	var dir := Vector2.RIGHT.rotated(_rng.randf() * TAU)
	if shy:
		dir = (position - _leader()).normalized()
	var to := position + dir * _rng.randf_range(0.6, 1.4) * AreaMap.CELL
	if can_land.is_valid() and not bool(can_land.call(to)):
		return
	_sprite.flip_h = dir.x < 0.0
	_launch(to, 0.35, 18.0)


## A slow creep about where it lives.
func _crawl(delta: float) -> void:
	_rest -= delta
	if _rest > 0.0:
		return
	if _through >= 1.0:
		_rest = _rng.randf_range(2.0, 6.0)
		var to := home + Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf_range(4.0, 20.0)
		_sprite.flip_h = to.x < position.x
		_launch(to, _rng.randf_range(4.0, 9.0), 0.0)
		return
	_rest = 0.0
	_fly_on(delta, false)
