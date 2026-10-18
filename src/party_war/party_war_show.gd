extends CanvasLayer
## The dressing on a party clash or a guild war ([D257]): what the fight looks like as a show.
##
## - a card first: the two sides, each fighter's face, level, calling, gear and stance, and
##   the pouch each side carries; then FIGHT! and the clock runs;
## - down each side of the screen, that side's roster with health, gear and stance, the
##   fallen struck through;
## - over a fighter's head, what they say: as the fight opens, at a kill, when a friend
##   falls, when they are low, when they drink, and at the end (`talk` in the data);
## - along the bottom, the fight's own log (who drinks, who is down, who answers whom);
## - the last blow in slow motion with K.O.!, then the winner's banner.
##
## The fight's own words (the moves let go, "circles", "guards Iris", "Blocked", "DOWN") are
## the skirmish's, drawn where they happen. Every timing and line is in `data/party_war.json`.

signal over

const Fighter := preload("res://src/skirmish/fighter.gd")
const SkirmishBrain := preload("res://src/skirmish/skirmish_brain.gd")

const INK := Color(0.08, 0.08, 0.1)
const PAPER := Color(1, 1, 1)
const DIM := Color(0.62, 0.62, 0.66)
const HEALTH := Color(0.36, 0.86, 0.45)
const HEALTH_MID := Color(0.97, 0.8, 0.25)
const HEALTH_LOW := Color(0.93, 0.3, 0.25)
const GOLD := Color(1.0, 0.82, 0.2)
const PANEL := 200.0
const TICKER := 64.0

enum Stage { CARD, FIGHT_WORD, FIGHTING, KO, END, DONE }

var _fight: Node2D
var _setup: Dictionary = {}
var _number: int = 1
var _count: int = 1
var _stage: Stage = Stage.CARD
var _t: float = 0.0
var _canvas: Control
var _font: Font
var _sides := {"left": [], "right": []}
## Fighter -> whether they stood last frame, and whether they have said they are low.
var _stood := {}
var _low_said := {}
## Fighter -> real seconds since they last spoke.
var _quiet := {}
## [fighter, words, real seconds left].
var _bubbles: Array = []
var _log: Array[String] = []
var _rng := RandomNumberGenerator.new()


func begin(fight: Node2D, setup: Dictionary, number: int, count: int) -> void:
	_fight = fight
	_setup = setup
	_number = number
	_count = count
	_rng.seed = int(setup["seed"])
	layer = 50
	_font = ThemeDB.fallback_font
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_show)
	add_child(_canvas)
	for f: Fighter in fight.fighters:
		if f.bound_to != null:
			continue
		_sides["left" if f.is_party() else "right"].append(f)
		_stood[f] = true
		_quiet[f] = 99.0
	EventBus.battle_log.connect(_on_log)
	_frame_the_field(true)


func _exit_tree() -> void:
	if EventBus.battle_log.is_connected(_on_log):
		EventBus.battle_log.disconnect(_on_log)


static func _rule(key: String, fallback: float) -> float:
	return float(Database.party_war.get(key, fallback))


static func _word(key: String, fill: Dictionary = {}) -> String:
	return str(Database.party_war.get("words", {}).get(key, key)).format(fill)


static func _side_colour(side: String) -> Color:
	return Color(str(Database.party_war.get("sides", {}).get(side, "#ffffff")))


func fighting() -> bool:
	return _stage == Stage.FIGHTING


func _process(delta: float) -> void:
	if _fight == null:
		return
	var real := delta / maxf(0.01, Engine.time_scale)
	_t += real
	match _stage:
		Stage.CARD:
			if _t >= _rule("card_seconds", 3.5):
				_next(Stage.FIGHT_WORD)
				Sfx.cue("charge")
		Stage.FIGHT_WORD:
			if _t >= _rule("fight_word_seconds", 0.9):
				_next(Stage.FIGHTING)
				_fight.set_paused(false)
				_open_mouths()
		Stage.FIGHTING:
			_listen()
			if _fight.over:
				Engine.time_scale = _rule("ko_slow_scale", 0.35)
				_next(Stage.KO)
			elif _fight.sim_time >= float(_setup.get("time_limit", 120.0)):
				_fight.set_paused(true)
				_next(Stage.END)
		Stage.KO:
			if _t >= _rule("ko_slow_seconds", 1.0):
				Engine.time_scale = 1.0
				_next(Stage.END)
				_last_word()
		Stage.END:
			if _t >= _rule("end_seconds", 4.0):
				_next(Stage.DONE)
				over.emit()
	for f: Fighter in _quiet:
		_quiet[f] += real
	for bubble: Array in _bubbles:
		bubble[2] -= real
	_bubbles = _bubbles.filter(func(b: Array) -> bool: return b[2] > 0.0)
	if _stage != Stage.CARD:
		_frame_the_field()
	_canvas.queue_redraw()


func _next(stage: Stage) -> void:
	_stage = stage
	_t = 0.0


func _on_log(line: String) -> void:
	if line.begins_with("The fight is"):
		return
	_log.append(line)
	if _log.size() > 3:
		_log.pop_front()


## The fight between the two rosters and above the log: everyone standing in view, as close
## as that allows (never closer than `camera_zoom_most` times the whole field), never past the
## field's edge.
func _frame_the_field(immediate: bool = false) -> void:
	var camera: Camera2D = _fight.camera
	var view := _canvas.get_viewport_rect().size
	var unit := _unit(view)
	var field := Vector2(_fight.grid.width, _fight.grid.height) * BattleGrid.CELL_SIZE
	var room := Vector2(view.x - 2.0 * PANEL * unit, view.y - TICKER * unit)
	var whole := minf(room.x / field.x, room.y / field.y) * 0.97
	var box := Rect2()
	var first := true
	for f: Fighter in _stood:
		if not f.is_standing() and _stage != Stage.CARD:
			continue
		var at: Vector2 = f.unit.position
		box = Rect2(at, Vector2.ZERO) if first else box.expand(at)
		first = false
	if first:
		box = Rect2(Vector2.ZERO, field)
	box = box.grow(BattleGrid.CELL_SIZE * _rule("camera_margin_cells", 3.0))
	var zoom := clampf(minf(room.x / box.size.x, room.y / box.size.y), whole, whole * _rule("camera_zoom_most", 2.0))
	# The middle of the room left for the field sits above the log.
	var shown := room / zoom
	var centre := box.get_center()
	centre.x = clampf(centre.x, minf(shown.x * 0.5, field.x * 0.5), maxf(field.x - shown.x * 0.5, field.x * 0.5))
	centre.y = clampf(centre.y, minf(shown.y * 0.5, field.y * 0.5), maxf(field.y - shown.y * 0.5, field.y * 0.5))
	centre += Vector2(0, TICKER * unit * 0.5 / zoom)
	if immediate:
		camera.frame(Rect2(Vector2(-100000, -100000), Vector2(200000, 200000)))
		camera.limit_left = -100000
		camera.limit_top = -100000
		camera.limit_right = 100000
		camera.limit_bottom = 100000
		camera.zoom = Vector2(zoom, zoom)
		camera.position = centre
		camera.reset_smoothing()
		return
	camera.zoom = camera.zoom.lerp(Vector2(zoom, zoom), 0.04)
	camera.position = camera.position.lerp(centre, 0.08)


# --- what they say ------------------------------------------------------------


## The words for [param f] on [param occasion]: their doctrine's own, or anyone's.
func _line(f: Fighter, occasion: String) -> String:
	var talk: Dictionary = Database.party_war.get("talk", {})
	var tactics: Dictionary = Database.skirmish.get("tactics", {})
	var doctrine := str(tactics.get("leads", {}).get(f.unit.template_id, ""))
	if doctrine == "" and f.role != "":
		doctrine = str(tactics.get("roles", {}).get(f.role, ""))
	if doctrine == "":
		doctrine = "brute"
	var own: Array = talk.get(doctrine, {}).get(occasion, [])
	var any: Array = talk.get("any", {}).get(occasion, [])
	var pool := own if not own.is_empty() and (any.is_empty() or _rng.randf() < 0.6) else any
	return str(pool[_rng.randi() % pool.size()]) if not pool.is_empty() else ""


## [param f] says something for [param occasion], unless they spoke a moment ago or the
## field is already full of words. [param about] fills {foe}.
func talk(f: Fighter, occasion: String, about: String = "", force: bool = false) -> void:
	if f == null or not _quiet.has(f):
		return
	if not force and (_quiet[f] < _rule("talk_gap", 2.5) or _bubbles.size() >= 3):
		return
	var words := _line(f, occasion).format({"name": f.unit.display_name, "foe": about})
	if words == "":
		return
	_quiet[f] = 0.0
	_bubbles = _bubbles.filter(func(b: Array) -> bool: return b[0] != f)
	_bubbles.append([f, words, _rule("talk_seconds", 2.4)])


func _open_mouths() -> void:
	for side: String in ["left", "right"]:
		var mine: Array = _sides[side]
		var theirs: Array = _sides["right" if side == "left" else "left"]
		if mine.is_empty() or theirs.is_empty():
			continue
		var speaker: Fighter = mine[_rng.randi() % mine.size()]
		var foe: Fighter = theirs[_rng.randi() % theirs.size()]
		talk(speaker, "open", foe.unit.display_name, true)


## Falls, kills and low health since last frame.
func _listen() -> void:
	for f: Fighter in _stood:
		var standing := f.is_standing()
		if _stood[f] and not standing:
			var killer: Fighter = _fight.fighter_of(f.struck_by) if is_instance_valid(f.struck_by) else null
			if killer != null and killer.is_standing():
				talk(killer, "kill", f.unit.display_name)
			var friends: Array = _sides["left" if f.is_party() else "right"].filter(
					func(o: Fighter) -> bool: return o != f and o.is_standing())
			if not friends.is_empty():
				talk(friends[_rng.randi() % friends.size()], "friend_down", f.unit.display_name)
		_stood[f] = standing
		if standing and not _low_said.has(f) and float(f.unit.hp) / maxf(1.0, f.unit.max_hp) < _rule("low_health", 0.3):
			_low_said[f] = true
			talk(f, "low")


func _last_word() -> void:
	if not _fight.over:
		return
	var winners: Array = _sides["left" if _fight.victory else "right"].filter(
			func(o: Fighter) -> bool: return o.is_standing())
	if not winners.is_empty():
		talk(winners[_rng.randi() % winners.size()], "win", "", true)


# --- drawing -----------------------------------------------------------------


static func _unit(view: Vector2) -> float:
	return view.y / 720.0 if view.x >= view.y else view.x / 720.0


func _draw_show() -> void:
	var view := _canvas.get_size()
	var unit := _unit(view)
	if _stage == Stage.CARD:
		_draw_card(view, unit)
		return
	_draw_bubbles(unit)
	_draw_rosters(view, unit)
	_draw_ticker(view, unit)
	var seconds := int(_fight.sim_time)
	_shout("%d:%02d" % [seconds / 60, seconds % 60], Vector2(view.x * 0.5, 22 * unit), 26 * unit, PAPER)
	match _stage:
		Stage.FIGHT_WORD:
			var grow := minf(1.0, _t / 0.15)
			_shout(_word("fight"), view * Vector2(0.5, 0.45), 96 * unit * (0.6 + 0.4 * grow), GOLD)
		Stage.KO:
			_shout(_word("ko"), view * Vector2(0.5, 0.42), 104 * unit, HEALTH_LOW)
		Stage.END, Stage.DONE:
			_draw_end(view, unit)


## Both sides as they walk out: face, name and level, calling, gear, stance; the pouch under.
func _draw_card(view: Vector2, unit: float) -> void:
	_canvas.draw_rect(Rect2(Vector2.ZERO, view), INK)
	var war := str(_setup.get("kind", "clash")) == "war"
	var tag := _word("war_tag" if war else "tag")
	if not war and _count > 1:
		tag += "  ·  " + _word("next", {"number": _number, "count": _count})
	_shout(tag, Vector2(view.x * 0.5, 40 * unit), 40 * unit, GOLD)
	if war:
		_shout(str(_setup.get("title", "")), Vector2(view.x * 0.5, 82 * unit), 24 * unit, PAPER)
	var slide := minf(1.0, _t / 0.3)
	for side: String in ["left", "right"]:
		var right := side == "right"
		var column := Rect2(Vector2(view.x * (0.52 if right else 0.03), 110 * unit), Vector2(view.x * 0.45, view.y - 150 * unit))
		column.position.x += (1.0 - slide) * view.x * (0.5 if right else -0.5)
		_canvas.draw_rect(column, Color(_side_colour(side), 0.85))
		_shout(str(_setup[side]["name"]).to_upper(), Vector2(column.get_center().x, column.position.y + 26 * unit), 28 * unit, PAPER)
		var mine: Array = _sides[side]
		var row_h := minf(70.0 * unit, (column.size.y - 90 * unit) / maxf(1.0, mine.size()))
		var y := column.position.y + 52 * unit
		for f: Fighter in mine:
			var face := Rect2(Vector2(column.position.x + 12 * unit, y + 3 * unit), Vector2(row_h - 6 * unit, row_h - 6 * unit))
			_face(f, face, unit)
			var x := face.end.x + 10 * unit
			var big := int(clampf(row_h * 0.34, 10 * unit, 22 * unit))
			var small := int(clampf(row_h * 0.24, 8 * unit, 15 * unit))
			_canvas.draw_string(_font, Vector2(x, y + row_h * 0.42), "%s  L%d  %s" % [f.unit.display_name, _level(f), f.unit.job],
					HORIZONTAL_ALIGNMENT_LEFT, column.end.x - x - 8 * unit, big, PAPER)
			_canvas.draw_string(_font, Vector2(x, y + row_h * 0.82), "%s  ·  %s" % [_gear_word(f), _stance_word(f)],
					HORIZONTAL_ALIGNMENT_LEFT, column.end.x - x - 8 * unit, small, Color(1, 1, 1, 0.85))
			y += row_h
		_canvas.draw_string(_font, Vector2(column.position.x + 14 * unit, column.end.y - 14 * unit), _pouch_word(side),
				HORIZONTAL_ALIGNMENT_LEFT, column.size.x - 28 * unit, int(15 * unit), GOLD)
	_canvas.draw_circle(view * Vector2(0.5, 0.55), 40 * unit, INK)
	_canvas.draw_circle(view * Vector2(0.5, 0.55), 36 * unit, PAPER)
	_shout("VS", view * Vector2(0.5, 0.55), 40 * unit, HEALTH_LOW)


## Down each edge: that side's fighters, their health, gear and stance.
func _draw_rosters(view: Vector2, unit: float) -> void:
	for side: String in ["left", "right"]:
		var right := side == "right"
		var panel := Rect2(Vector2(view.x - PANEL * unit if right else 0.0, 0.0), Vector2(PANEL * unit, view.y))
		_canvas.draw_rect(panel, Color(INK, 0.88))
		_canvas.draw_rect(Rect2(panel.position, Vector2(panel.size.x, 34 * unit)), _side_colour(side))
		var mine: Array = _sides[side]
		var up := mine.filter(func(o: Fighter) -> bool: return o.is_standing()).size()
		_canvas.draw_string(_font, Vector2(panel.position.x + 8 * unit, 16 * unit), str(_setup[side]["name"]).to_upper(),
				HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 16 * unit, int(14 * unit), PAPER)
		_canvas.draw_string(_font, Vector2(panel.position.x + 8 * unit, 30 * unit), "%d of %d standing  ·  %s" % [up, mine.size(), _pouch_word(side)],
				HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 16 * unit, int(10 * unit), PAPER)
		var row_h := minf(62.0 * unit, (view.y - 40 * unit) / maxf(1.0, mine.size()))
		var y := 40 * unit
		for f: Fighter in mine:
			var down := not f.is_standing()
			var tint := DIM if down else PAPER
			var face := Rect2(Vector2(panel.position.x + 6 * unit, y + 2 * unit), Vector2(row_h - 8 * unit, row_h - 8 * unit))
			_face(f, face, unit, down)
			var x := face.end.x + 6 * unit
			var w := panel.end.x - x - 6 * unit
			var big := int(clampf(row_h * 0.24, 8 * unit, 13 * unit))
			var small := int(clampf(row_h * 0.18, 7 * unit, 10 * unit))
			var name := "%s L%d" % [f.unit.display_name, _level(f)]
			_canvas.draw_string(_font, Vector2(x, y + row_h * 0.28), name, HORIZONTAL_ALIGNMENT_LEFT, w, big, tint)
			if down:
				var width := minf(w, _font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, big).x)
				_canvas.draw_line(Vector2(x, y + row_h * 0.22), Vector2(x + width, y + row_h * 0.22), HEALTH_LOW, 2 * unit)
			var share := clampf(float(f.unit.hp) / maxf(1.0, f.unit.max_hp), 0.0, 1.0) if not down else 0.0
			var bar := Rect2(x, y + row_h * 0.36, w, maxf(4 * unit, row_h * 0.14))
			_canvas.draw_rect(bar, Color(0.25, 0.25, 0.28))
			var fill := HEALTH if share > 0.5 else (HEALTH_MID if share > _rule("low_health", 0.3) else HEALTH_LOW)
			_canvas.draw_rect(Rect2(bar.position, Vector2(bar.size.x * share, bar.size.y)), fill)
			var doing := _doing(f)
			_canvas.draw_string(_font, Vector2(x, y + row_h * 0.7), _gear_word(f),
					HORIZONTAL_ALIGNMENT_LEFT, w, small, Color(tint, 0.85))
			_canvas.draw_string(_font, Vector2(x, y + row_h * 0.92), doing if doing != "" else _stance_word(f),
					HORIZONTAL_ALIGNMENT_LEFT, w, small, GOLD if doing != "" else Color(tint, 0.85))
			y += row_h


## The fight's own log along the bottom, newest last.
func _draw_ticker(view: Vector2, unit: float) -> void:
	var strip := Rect2(Vector2(PANEL * unit, view.y - TICKER * unit), Vector2(view.x - 2 * PANEL * unit, TICKER * unit))
	_canvas.draw_rect(strip, Color(INK, 0.78))
	var y := strip.position.y + 18 * unit
	for i in _log.size():
		var colour := PAPER if i == _log.size() - 1 else DIM
		_canvas.draw_string(_font, Vector2(strip.position.x + 12 * unit, y), _log[i], HORIZONTAL_ALIGNMENT_LEFT,
				strip.size.x - 24 * unit, int(13 * unit), colour)
		y += 18 * unit


func _draw_bubbles(unit: float) -> void:
	var size := int(13 * unit)
	for bubble: Array in _bubbles:
		var f: Fighter = bubble[0]
		if not is_instance_valid(f.unit):
			continue
		var words := str(bubble[1])
		var at: Vector2 = _fight.get_viewport().get_canvas_transform() * (f.unit.global_position + Vector2(0, -52))
		var w := minf(_font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x, 260 * unit) + 16 * unit
		var box := Rect2(at - Vector2(w * 0.5, 30 * unit), Vector2(w, 24 * unit))
		var fade := clampf(float(bubble[2]) / 0.3, 0.0, 1.0)
		var side := "left" if f.is_party() else "right"
		_canvas.draw_rect(box.grow(2 * unit), Color(_side_colour(side), fade))
		_canvas.draw_rect(box, Color(PAPER, fade))
		_canvas.draw_colored_polygon(PackedVector2Array([box.get_center() + Vector2(-6 * unit, 12 * unit),
				box.get_center() + Vector2(6 * unit, 12 * unit), at + Vector2(0, 4 * unit)]), Color(PAPER, fade))
		_canvas.draw_string(_font, box.position + Vector2(8 * unit, 17 * unit), words, HORIZONTAL_ALIGNMENT_LEFT,
				w - 16 * unit, size, Color(INK, fade))


func _draw_end(view: Vector2, unit: float) -> void:
	var banner := Rect2(PANEL * unit, view.y * 0.36, view.x - 2 * PANEL * unit, 96 * unit)
	var winner := ""
	if _fight.over:
		winner = "left" if _fight.victory else "right"
	var colour := _side_colour(winner) if winner != "" else Color(0.4, 0.4, 0.45)
	_canvas.draw_rect(banner.grow(3 * unit), INK)
	_canvas.draw_rect(banner, colour)
	var said := _word("wins", {"name": str(_setup[winner]["name"]).to_upper()}) if winner != "" else _word("draw")
	_shout(said, banner.get_center() - Vector2(0, 14 * unit), 42 * unit, PAPER)
	var count := 0
	if winner != "":
		count = (_sides[winner] as Array).filter(func(o: Fighter) -> bool: return o.is_standing()).size()
	_text(_word("standing", {"count": count, "seconds": int(_fight.sim_time)}), banner.get_center() + Vector2(0, 28 * unit), 18 * unit, PAPER)


# --- bits ----------------------------------------------------------------------


func _face(f: Fighter, box: Rect2, unit: float, down: bool = false) -> void:
	_canvas.draw_rect(box.grow(2 * unit), _side_colour("left" if f.is_party() else "right"))
	_canvas.draw_rect(box, Color(0.55, 0.7, 0.9))
	var face: Texture2D = Database.unit_face(f.unit.template_id)
	if face != null:
		_canvas.draw_texture_rect(face, box, false, Color(1, 1, 1, 0.35) if down else Color.WHITE)


static func _level(f: Fighter) -> int:
	return f.unit.character.level if f.unit.character != null else 0


static func _gear_word(f: Fighter) -> String:
	var id := f.unit.character.equipment if f.unit.character != null else ""
	if id == "" and f.unit.character != null:
		id = Gear.issued_id(f.unit.character)
	return Gear.display_name(id) if id != "" else "bare hands"


static func _stance_word(f: Fighter) -> String:
	return str(Fighter.stance_data(f.stance).get("word", f.stance))


## What they are busy with right now, if anything worth a line.
static func _doing(f: Fighter) -> String:
	if not f.is_standing():
		return "down"
	if f.is_using():
		return "drinking %s" % Gear.display_name(str(f.using.get("item", "")))
	if f.is_casting():
		return "winding up"
	return ""


func _pouch_word(side: String) -> String:
	var pouch: Dictionary = _setup.get("pouches", {}).get(side, {})
	if pouch.is_empty():
		return _word("empty_pouch")
	var parts: Array[String] = []
	for id: String in pouch:
		parts.append("%s x%d" % [Gear.display_name(id), pouch[id]])
	return _word("pouch", {"items": ", ".join(parts)})


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
