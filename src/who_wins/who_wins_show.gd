extends CanvasLayer
## The dressing on a "Who wins?" bout ([D180]): what the fight looks like as a
## show rather than as a game. Read off the frames of a channel that makes these
## (`docs/investigation/10-who-wins-shows.md`) and drawn here in code, no art:
##
## - a VS card first, the two leads' faces on their colours, then FIGHT! and the clock runs;
## - along the top, each lead's face, name, class and health, and the fight's clock between;
## - under each bar, the move that lead last let go, for a moment;
## - a red edge on a lead's side of the screen when their health is low;
## - a burst of lines round anyone hit for a fifth of their health or more;
## - the camera keeps both leads in view, close in when they are close;
## - the last blow in slow motion with K.O.!, then the winner's banner and the
##   question the clip ends on.
##
## Every timing and word is in `data/who_wins.json`.

signal over

const SkirmishFx := preload("res://src/skirmish/skirmish_fx.gd")

const INK := Color(0.08, 0.08, 0.1)
const PAPER := Color(1, 1, 1)
const HEALTH := Color(0.36, 0.86, 0.45)
const HEALTH_MID := Color(0.97, 0.8, 0.25)
const HEALTH_LOW := Color(0.93, 0.3, 0.25)
const GOLD := Color(1.0, 0.82, 0.2)

enum Stage { CARD, FIGHT_WORD, FIGHTING, KO, END, DONE }

var _fight: Node2D
var _level: int = 1
var _left: RefCounted
var _right: RefCounted
var _stage: Stage = Stage.CARD
## Real seconds into the current stage.
var _t: float = 0.0
var _canvas: Control
var _font: Font
## Per side: the move on the badge, and real seconds it has left.
var _badges := {"left": ["", 0.0], "right": ["", 0.0]}
var _seen_casts := {"left": 0, "right": 0}
## Bursts of lines round a big hit: [screen position, real seconds left].
var _bursts: Array = []
var _winner: RefCounted = null


func begin(fight: Node2D, level: int) -> void:
	_fight = fight
	_level = level
	layer = 50
	_font = ThemeDB.fallback_font
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_show)
	add_child(_canvas)
	for f: RefCounted in fight.fighters:
		if f.bound_to != null:
			continue
		if f.is_party():
			_left = f
		elif _right == null:
			_right = f
	EventBus.unit_damaged.connect(_on_damaged)
	_frame_the_leads(true)


func _exit_tree() -> void:
	if EventBus.unit_damaged.is_connected(_on_damaged):
		EventBus.unit_damaged.disconnect(_on_damaged)


static func _rule(key: String, fallback: float) -> float:
	return float(Database.who_wins.get(key, fallback))


static func _word(key: String, fill: Dictionary = {}) -> String:
	return str(Database.who_wins.get("words", {}).get(key, key)).format(fill)


static func _side_colour(side: String) -> Color:
	return Color(str(Database.who_wins.get("sides", {}).get(side, "#ffffff")))


func _process(delta: float) -> void:
	if _fight == null or _left == null or _right == null:
		return
	var real := delta / maxf(0.01, Engine.time_scale)
	_t += real
	match _stage:
		Stage.CARD:
			if _t >= _rule("title_seconds", 2.6):
				_next(Stage.FIGHT_WORD)
				Sfx.cue("charge")
		Stage.FIGHT_WORD:
			if _t >= _rule("fight_word_seconds", 0.9):
				_next(Stage.FIGHTING)
				_fight.set_paused(false)
		Stage.FIGHTING:
			if _fight.over:
				_winner = _left if _fight.victory else _right
				Engine.time_scale = _rule("ko_slow_scale", 0.3)
				_next(Stage.KO)
			elif _fight.sim_time >= _rule("time_limit", 180.0):
				_fight.set_paused(true)
				_next(Stage.END)
		Stage.KO:
			if _t >= _rule("ko_slow_seconds", 1.2):
				Engine.time_scale = 1.0
				_next(Stage.END)
		Stage.END:
			if _t >= _rule("end_seconds", 5.0):
				_next(Stage.DONE)
				over.emit()
	_watch_moves(real)
	for burst: Array in _bursts:
		burst[1] -= real
	_bursts = _bursts.filter(func(b: Array) -> bool: return b[1] > 0.0)
	_frame_the_leads(false)
	_canvas.queue_redraw()


func _next(stage: Stage) -> void:
	_stage = stage
	_t = 0.0


func _watch_moves(real: float) -> void:
	for side: String in ["left", "right"]:
		var f: RefCounted = _left if side == "left" else _right
		if f.casts != _seen_casts[side]:
			_seen_casts[side] = f.casts
			_badges[side] = [f.last_move, _rule("badge_seconds", 1.6)]
		_badges[side][1] = maxf(0.0, _badges[side][1] - real)


func _on_damaged(unit: Node, amount: int) -> void:
	for f: RefCounted in [_left, _right]:
		if f != null and f.unit == unit and amount >= f.unit.max_hp * 0.2:
			_bursts.append([_on_screen(f.unit.global_position), 0.3])


func _on_screen(world: Vector2) -> Vector2:
	return _fight.get_viewport().get_canvas_transform() * world


## Both leads in view, as close as they allow, leaving room for the bar on top.
func _frame_the_leads(immediate: bool) -> void:
	var camera: Camera2D = _fight.camera
	if _left == null or _right == null or not camera.enabled:
		return
	var a: Vector2 = _left.unit.global_position
	var b: Vector2 = _right.unit.global_position
	var view := _canvas.get_viewport_rect().size if _canvas != null else Vector2(1280, 720)
	var margin := _rule("camera_margin", 150.0)
	var span := (a - b).abs() + Vector2(margin, margin) * 2.0
	var room := view - Vector2(0, view.y * 0.16)
	# Never so far out that the edge of the field shows.
	var field: Vector2 = Vector2(_fight.grid.width, _fight.grid.height) * BattleGrid.CELL_SIZE
	var least := maxf(view.x / field.x, view.y / field.y)
	var zoom := clampf(minf(room.x / span.x, room.y / span.y), least, maxf(least, _rule("camera_zoom_most", 2.4)))
	var target := Vector2(zoom, zoom)
	camera.zoom = target if immediate else camera.zoom.lerp(target, 0.06)
	# A little below the middle of the two, so the bar on top covers sky, not them.
	camera.focus_on((a + b) * 0.5 - Vector2(0, view.y * 0.06 / camera.zoom.y), immediate)


# --- drawing -----------------------------------------------------------------


func _draw_show() -> void:
	var view := _canvas.get_size()
	var unit := view.y / 720.0 if view.x >= view.y else view.x / 720.0
	match _stage:
		Stage.CARD:
			_draw_card(view, unit)
			return
	_draw_low_health(view)
	_draw_bursts(unit)
	_draw_bars(view, unit)
	_draw_badges(view, unit)
	match _stage:
		Stage.FIGHT_WORD:
			var grow := minf(1.0, _t / 0.15)
			_shout(_word("fight"), view * Vector2(0.5, 0.45), 96 * unit * (0.6 + 0.4 * grow), GOLD)
		Stage.KO:
			_shout(_word("ko"), view * Vector2(0.5, 0.42), 104 * unit, HEALTH_LOW)
		Stage.END, Stage.DONE:
			_draw_end(view, unit)


## The VS card: each lead's colour on a slanted half, their face big, their
## name over it, the circle in the middle, the question underneath.
func _draw_card(view: Vector2, unit: float) -> void:
	var slide := minf(1.0, _t / 0.25)
	var slant := view.x * 0.06
	var mid := view.x * 0.5
	var left_half := PackedVector2Array([Vector2(-slant, 0), Vector2(mid + slant, 0), Vector2(mid - slant, view.y), Vector2(-slant, view.y)])
	var right_half := PackedVector2Array([Vector2(mid + slant, 0), Vector2(view.x + slant, 0), Vector2(view.x + slant, view.y), Vector2(mid - slant, view.y)])
	var off := (1.0 - slide) * view.x * 0.5
	_canvas.draw_set_transform(Vector2(-off, 0))
	_canvas.draw_colored_polygon(left_half, _side_colour("left"))
	_canvas.draw_set_transform(Vector2(off, 0))
	_canvas.draw_colored_polygon(right_half, _side_colour("right"))
	_canvas.draw_set_transform(Vector2.ZERO)
	_canvas.draw_line(Vector2(mid + slant, 0), Vector2(mid - slant, view.y), INK, 8 * unit)
	_canvas.draw_line(Vector2(mid + slant, 0), Vector2(mid - slant, view.y), PAPER, 3 * unit)
	var upright := view.y > view.x
	for side: String in ["left", "right"]:
		var f: RefCounted = _left if side == "left" else _right
		var centre := view * (Vector2(0.25, 0.42) if side == "left" else Vector2(0.75, 0.42))
		if upright:
			centre = view * (Vector2(0.5, 0.25) if side == "left" else Vector2(0.5, 0.72))
		var size := minf(view.x * (0.3 if not upright else 0.5), view.y * 0.36)
		var box := Rect2(centre - Vector2(size, size) * 0.5, Vector2(size, size))
		_canvas.draw_rect(box.grow(8 * unit), INK)
		_canvas.draw_rect(box.grow(4 * unit), PAPER)
		_canvas.draw_rect(box, Color(0.55, 0.7, 0.9))
		var face: Texture2D = Database.unit_face(f.unit.template_id)
		if face != null:
			_canvas.draw_texture_rect(face, box, false)
		_shout(f.unit.display_name.to_upper(), centre - Vector2(0, size * 0.5 + 34 * unit), 54 * unit, PAPER)
		_shout(f.unit.job, centre + Vector2(0, size * 0.5 + 34 * unit), 26 * unit, PAPER)
	var vs_at := view * 0.5 if not upright else view * Vector2(0.5, 0.485)
	_canvas.draw_circle(vs_at, 64 * unit, INK)
	_canvas.draw_circle(vs_at, 58 * unit, PAPER)
	_shout("VS", vs_at, 64 * unit, HEALTH_LOW)
	var tag := "%s  ·  %s" % [_word("tag"), _word("level", {"level": _level})]
	var tag_at := Vector2(view.x * 0.5, view.y - 70 * unit)
	var tag_w := _font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, int(30 * unit)).x + 50 * unit
	_canvas.draw_rect(Rect2(tag_at - Vector2(tag_w * 0.5, 30 * unit), Vector2(tag_w, 60 * unit)).grow(4 * unit), INK)
	_canvas.draw_rect(Rect2(tag_at - Vector2(tag_w * 0.5, 30 * unit), Vector2(tag_w, 60 * unit)), PAPER)
	_text(tag, tag_at, 30 * unit, INK)


## The two leads along the top, the clock between them.
func _draw_bars(view: Vector2, unit: float) -> void:
	var height := 74 * unit
	_canvas.draw_rect(Rect2(0, 0, view.x, height), Color(INK, 0.85))
	for side: String in ["left", "right"]:
		var f: RefCounted = _left if side == "left" else _right
		var right := side == "right"
		var face_box := Rect2(Vector2(view.x - 10 * unit - 56 * unit if right else 10 * unit, 9 * unit), Vector2(56, 56) * unit)
		_canvas.draw_rect(face_box.grow(2 * unit), _side_colour(side))
		_canvas.draw_rect(face_box, Color(0.55, 0.7, 0.9))
		var face: Texture2D = Database.unit_face(f.unit.template_id)
		if face != null:
			_canvas.draw_texture_rect(face, face_box, false)
		var inner := 76 * unit
		var width := view.x * 0.5 - inner - 60 * unit
		var x := view.x - inner - width if right else inner
		var align := HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
		_canvas.draw_string(_font, Vector2(x, 28 * unit), f.unit.display_name.to_upper(), align, width, int(26 * unit), PAPER)
		_canvas.draw_string(_font, Vector2(x, 44 * unit), f.unit.job, align, width, int(14 * unit), _side_colour(side))
		var share := clampf(float(f.unit.hp) / maxf(1.0, f.unit.max_hp), 0.0, 1.0)
		var bar := Rect2(x, 50 * unit, width, 14 * unit)
		_canvas.draw_rect(bar.grow(2 * unit), INK)
		_canvas.draw_rect(bar, Color(0.25, 0.25, 0.28))
		var fill := HEALTH if share > 0.5 else (HEALTH_MID if share > _rule("low_health", 0.25) else HEALTH_LOW)
		var filled := Rect2(bar.position + Vector2(bar.size.x * (1.0 - share) if right else 0.0, 0), Vector2(bar.size.x * share, bar.size.y))
		_canvas.draw_rect(filled, fill)
		var hp_text := "%d/%d" % [maxi(0, f.unit.hp), f.unit.max_hp]
		_canvas.draw_string(_font, Vector2(x, 76 * unit - 14 * unit) + Vector2(0, 0), hp_text,
				HORIZONTAL_ALIGNMENT_LEFT if right else HORIZONTAL_ALIGNMENT_RIGHT, width, int(11 * unit), PAPER)
	var seconds := int(_fight.sim_time)
	_text("%d:%02d" % [seconds / 60, seconds % 60], Vector2(view.x * 0.5, 34 * unit), 24 * unit, PAPER)


## The move each lead last let go, in a pill under their bar.
func _draw_badges(view: Vector2, unit: float) -> void:
	for side: String in ["left", "right"]:
		var badge: Array = _badges[side]
		if badge[1] <= 0.0 or str(badge[0]) == "":
			continue
		var words := "%s!" % badge[0]
		var size := int(18 * unit)
		var w := _font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 24 * unit
		var x := view.x - 12 * unit - w if side == "right" else 12 * unit
		var box := Rect2(x, 84 * unit, w, 30 * unit)
		_canvas.draw_rect(box.grow(2 * unit), INK)
		_canvas.draw_rect(box, PAPER)
		_text(words, box.get_center(), 18 * unit, INK)


func _draw_low_health(view: Vector2) -> void:
	for side: String in ["left", "right"]:
		var f: RefCounted = _left if side == "left" else _right
		if f.unit.hp <= 0 or float(f.unit.hp) / maxf(1.0, f.unit.max_hp) > _rule("low_health", 0.25):
			continue
		var pulse := 0.25 + 0.15 * sin(Time.get_ticks_msec() / 160.0)
		var x := 0.0 if side == "left" else view.x * 0.85
		var edge := Color(HEALTH_LOW, pulse)
		var clear := Color(HEALTH_LOW, 0.0)
		var colours := PackedColorArray([edge, clear, clear, edge]) if side == "left" else PackedColorArray([clear, edge, edge, clear])
		_canvas.draw_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + view.x * 0.15, 0),
				Vector2(x + view.x * 0.15, view.y), Vector2(x, view.y)]), colours)


func _draw_bursts(unit: float) -> void:
	for burst: Array in _bursts:
		var at: Vector2 = burst[0]
		var life: float = burst[1] / 0.3
		for i in 14:
			var angle := TAU * i / 14.0 + 0.3
			var dir := Vector2.from_angle(angle)
			var near := (40.0 + 30.0 * (1.0 - life)) * unit
			_canvas.draw_line(at + dir * near, at + dir * (near + 70 * unit * life), Color(PAPER, life), 4 * unit)


## The winner's banner across the top, and the question the clip ends on.
func _draw_end(view: Vector2, unit: float) -> void:
	var banner := Rect2(0, view.y * 0.16, view.x, 70 * unit)
	var colour := _side_colour("left" if _winner == _left else "right") if _winner != null else Color(0.4, 0.4, 0.45)
	_canvas.draw_rect(banner.grow(3 * unit), INK)
	_canvas.draw_rect(banner, colour)
	var said := _word("wins", {"name": _winner.unit.display_name.to_upper()}) if _winner != null else _word("draw")
	_shout(said, banner.get_center(), 46 * unit, PAPER)
	if _t > 0.8:
		_shout(_word("next"), Vector2(view.x * 0.5, view.y * 0.8), 34 * unit, PAPER)
		_shout(_word("comment"), Vector2(view.x * 0.5, view.y * 0.8 + 40 * unit), 24 * unit, GOLD)


## Big words with a thick dark edge, centred on [param at].
func _shout(words: String, at: Vector2, size: float, colour: Color) -> void:
	var s := int(size)
	var w := _font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
	var base := at + Vector2(-w * 0.5, s * 0.35)
	_canvas.draw_string_outline(_font, base, words, HORIZONTAL_ALIGNMENT_LEFT, -1, s, maxi(4, s / 6), INK)
	_canvas.draw_string(_font, base, words, HORIZONTAL_ALIGNMENT_LEFT, -1, s, colour)


func _text(words: String, at: Vector2, size: float, colour: Color) -> void:
	var s := int(size)
	var w := _font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
	_canvas.draw_string(_font, at + Vector2(-w * 0.5, s * 0.35), words, HORIZONTAL_ALIGNMENT_LEFT, -1, s, colour)
