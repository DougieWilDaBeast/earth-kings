extends Control
## The opening cinematic: what a new game shows once you have chosen who you are
## (docs/25; remade by call BZ, [D328]). The words, the cast and each shot's camera
## are `data/opening.json`; each kind of picture (a `shot`) is drawn here, from the
## game's own sprites and shapes, so it plays without any art made for it (art made
## later, such as each lead's chapter-one object, is drawn when it exists).
##
## Click, Space or Enter moves on a shot; Esc skips to the end. When it ends the
## run begins in the world, on the landing, as it would have without it.

## Every kind of picture [method _draw] knows. A shot in the data naming
## anything else draws only the night sky.
const SHOTS := ["void", "sixteen", "worlds", "ending", "fall", "impact", "tower", "land", "gate", "inside", "company",
		"stair", "end", "title", "living", "road", "fight", "foe"]
## How long a line takes to fade in and out.
const FADE := 0.45
const NIGHT := Color(0.035, 0.04, 0.07)
const DUSK := Color(0.09, 0.08, 0.13)
const GROUND := Color(0.07, 0.075, 0.08)
const STAR := Color(0.85, 0.88, 1.0)
const GOLD := Color(1.0, 0.82, 0.42)
const EMBER := Color(1.0, 0.5, 0.2)
const BLOOD := Color(0.86, 0.22, 0.2)
const GHOST := Color(0.62, 0.78, 1.0)
const STAR_COUNT := 160
## How many, in words, as the narration writes them.
const WORDS := ["none", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
		"eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen"]

const Sixteen := preload("res://src/chronicle/sixteen.gd")

## Set by [Game]: `lead`, the hero just picked, who is the one seen falling.
## A test may also hand it `fallen_heroes` and `last_world`, which otherwise come
## from the record of the sixteen.
var boot_payload: Dictionary = {}

var shots: Array = []
var index := 0
## Seconds into the current shot.
var elapsed := 0.0
## Seconds since the cinematic began, for anything that should keep moving.
var clock := 0.0
var finished := false

var _data: Dictionary = {}
## Who lands: the lead just picked, or `opening.json`'s stand-in when there is none.
var _lead := ""
## Whose world is seen ending (D99, D101): `opening.json`'s `ending`, or the next
## of the sixteen when that is the lead.
var _other := ""
## Those of the sixteen who have fallen, oldest first. Empty on the first life,
## which plays the whole opening as written; any later life plays it again with
## them gone (`opening.json` → `replay`, `by_left`).
var _fallen: Array = []
## The world that ended last, as [method Sixteen.worlds] keeps it.
var _dead_world: Dictionary = {}
var _stars: Array = []
var _sprites: Dictionary = {}
var _caption: Label
var _title: Label
var _hint: Label
var _rng := RandomNumberGenerator.new()
## The camera over the shot being drawn ([method _camera]); every picture is drawn through it.
var _cam := Transform2D.IDENTITY
## Where the lead stands in the shot being drawn, as a share of the screen, for a camera that
## looks at "lead".
var _lead_at := Vector2(0.5, 0.5)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_data = Database.opening
	_lead = str(boot_payload.get("lead", _data.get("lead", "")))
	shots = _data.get("shots", [])
	_other = _ended(str(_data.get("ending", "")))
	_remember_the_fallen()
	_rng.seed = 1616
	for _i in STAR_COUNT:
		_stars.append([Vector2(_rng.randf(), _rng.randf()), _rng.randf_range(0.6, 2.0), _rng.randf() * TAU])
	_load_cast()
	_build_labels()
	if shots.is_empty():
		finish()


func _load_cast() -> void:
	for hero: String in _data.get("sixteen", []):
		_sprites["sixteen:" + hero] = _texture("res://art/sixteen/%s/idle/south.png" % hero)
	for template: String in (_data.get("party", []) as Array) + [str(_data.get("foe", ""))]:
		var dir := str(Database.unit_template(template).get("sprite_dir", ""))
		_sprites["unit:" + template] = _texture("%s/south.png" % dir) if dir != "" else null
		_sprites["unit_east:" + template] = _texture("%s/east.png" % dir) if dir != "" else null
	for key: String in ["tower", "town", "keep", "gate"]:
		var kind: String = {"tower": Site.TOWER, "town": Site.VILLAGE, "keep": Site.KEEP, "gate": Site.GATE}[key]
		_sprites[key] = _texture(str(Site.ART.get(kind, "")))
	if not _sprites.has("sixteen:" + _other):
		_sprites["sixteen:" + _other] = _texture("res://art/sixteen/%s/idle/south.png" % _other)
	if not _sprites.has("sixteen:" + _lead):
		_sprites["sixteen:" + _lead] = _texture("res://art/sixteen/%s/idle/south.png" % _lead)
	_sprites["fire"] = _texture("res://art/props/camp/campfire.png")
	var helper := str(_data.get("helper", ""))
	if helper != "":
		var dir := str(Database.unit_template(helper).get("sprite_dir", ""))
		_sprites["helper"] = _texture("%s/west.png" % dir) if dir != "" else null
	_sprites["object"] = _texture(str(object_of(_lead).get("art", "")))
	# Art asked for the film (docs/24), drawn over the shapes that stand in once it exists.
	for key: String in (_data.get("art", {}) as Dictionary):
		_sprites["art:" + key] = _texture(str(_data["art"][key]))


## On a life after the first, the opening is played again for who is left: only the
## `replay` shots, their lines swapped for the stage the sixteen are at, and the
## world seen ending is the one that has just ended.
func _remember_the_fallen() -> void:
	var sixteen: Array = _data.get("sixteen", [])
	var fallen: Array = boot_payload.get("fallen_heroes", Sixteen.fallen_heroes())
	_fallen = fallen.filter(func(hero) -> bool: return sixteen.has(str(hero)) and str(hero) != _lead)
	if _fallen.is_empty():
		return
	var worlds: Array = Sixteen.worlds()
	_dead_world = boot_payload.get("last_world", worlds.back() if not worlds.is_empty() else {})
	var dead := str(_dead_world.get("hero", ""))
	_other = dead if _fallen.has(dead) else str(_fallen.back())
	# A new player's first life (D191): the only world that has ended is the one they just
	# played, Atlas's last stand. They have never seen the opening, so it plays whole, with his
	# world seen ending and his ghost at the fire, rather than the replay for who is left.
	if _fallen.size() == 1 and bool(_dead_world.get("last_stand", false)):
		var told: Dictionary = _data.get("last_stand", {})
		# A copy: the shots are the game's own data, shared with every opening after this one.
		shots = shots.duplicate(true)
		for shot: Dictionary in shots:
			if told.has(str(shot.get("shot", ""))):
				shot["lines"] = (told[str(shot["shot"])] as Array).duplicate()
		return
	var replay: Array = _data.get("replay", [])
	var swaps: Dictionary = _data.get("by_left", {}).get(stage(), {})
	var kept: Array = []
	for shot: Dictionary in shots:
		var id := str(shot.get("shot", ""))
		if not replay.is_empty() and not replay.has(id):
			continue
		var again := shot.duplicate(true)
		again["time"] = float(again.get("time", 6.0)) * float(_data.get("replay_pace", 1.0))
		if swaps.has(id):
			again["lines"] = (swaps[id] as Array).duplicate()
		if id == "impact" and pair_line() != "":
			again["lines"] = (again.get("lines", []) as Array) + [pair_line()]
		kept.append(again)
	shots = kept


## The impact shot's extra line when the new lead is the other half of a tie with
## the one who just died (D153, `opening.json` → `pairs`); empty otherwise.
func pair_line() -> String:
	if _fallen.is_empty():
		return ""
	return str((_data.get("pairs", {}) as Dictionary).get("%s>%s" % [_other, _lead], ""))


## How many of the sixteen are still alive, the new lead among them.
func left() -> int:
	return maxi(1, (_data.get("sixteen", []) as Array).size() - _fallen.size())


## Where the sixteen are: `first` (nobody has fallen), `many`, `two` or `last`.
func stage() -> String:
	if _fallen.is_empty():
		return "first"
	match left():
		1: return "last"
		2: return "two"
	return "many"


## How the lead who just died fell, from their world's record.
func how_they_fell() -> String:
	var how: Dictionary = _data.get("how", {})
	var floor_reached := int(_dead_world.get("floor", 0))
	var killer := str(_dead_world.get("killer", "")).strip_edges().to_lower()
	if floor_reached > 0:
		return str(how.get("floor", "on floor {floor} of the Tower")).format({"floor": floor_reached})
	if killer != "":
		var a_killer := ("an " if killer.left(1) in ["a", "e", "i", "o", "u"] else "a ") + killer
		return str(how.get("killer", "on the road, to {a_killer}")).format({"a_killer": a_killer, "killer": killer})
	return str(how.get("none", "before they ever reached the Tower"))


## Everything a line can name.
func fill() -> Dictionary:
	var count := left()
	var gone := _fallen.size()
	var they := str(Database.hero(_other).get("pronoun", "they"))
	var said := {
		"other": other_name(), "dead": other_name(), "how": how_they_fell(),
		"left": _word(count), "Left": _word(count).capitalize(),
		"fallen": _word(gone), "Fallen": _word(gone).capitalize(),
		"left_after": _word(count - 1),
		"they": they, "They": they.capitalize(),
		"remembered": str((_data.get("remembered", {}) as Dictionary).get(_other, "")),
	}
	# D153: what the lead who just died had remembered, or that they never found out.
	var fell: Dictionary = _data.get("fell", {})
	var found := str(_dead_world.get("hero", "")) == _other and bool(_dead_world.get("remembered", false)) \
			and str(said["remembered"]) != ""
	said["fell"] = str(fell.get("found" if found else "not_found", "{dead} fell {how}.")).format(said)
	return said


static func _word(count: int) -> String:
	return WORDS[count] if count >= 0 and count < WORDS.size() else str(count)


func _ended(wanted: String) -> String:
	var sixteen: Array = _data.get("sixteen", [])
	if wanted != _lead and sixteen.has(wanted):
		return wanted
	for hero: String in sixteen:
		if hero != _lead:
			return hero
	return wanted


## The thing [param hero]'s chapter one turns on ([D328]: it falls with them and is found on floor 5).
func object_of(hero: String) -> Dictionary:
	return (_data.get("objects", {}) as Dictionary).get(hero, {})


## The lead's own colour, for the spark that stands in for their object and their light.
func _colour_of(hero: String) -> Color:
	var colour := str(Database.unit_template(hero).get("color", ""))
	return Color.html(colour) if Color.html_is_valid(colour) else GOLD


## The name a line uses for whoever's world is seen ending.
func other_name() -> String:
	var named := str(_dead_world.get("name", "")) if str(_dead_world.get("hero", "")) == _other else ""
	return named if named != "" else str(Database.unit_template(_other).get("display_name", _other.capitalize()))


static func _texture(path: String) -> Texture2D:
	return load(path) if path != "" and ResourceLoader.exists(path) else null


func _build_labels() -> void:
	_caption = Label.new()
	_caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_caption.offset_top = -150
	_caption.offset_bottom = -56
	_caption.offset_left = 48
	_caption.offset_right = -48
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_size_override("font_size", 24)
	_caption.add_theme_color_override("font_color", Color(0.93, 0.92, 0.88))
	_caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_caption.add_theme_constant_override("shadow_offset_y", 2)
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caption)

	_title = Label.new()
	_title.set_anchors_preset(Control.PRESET_CENTER)
	_title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_title.grow_vertical = Control.GROW_DIRECTION_BOTH
	_title.offset_top = -150
	_title.offset_bottom = -60
	_title.text = "EARTH KINGS"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 76)
	_title.add_theme_color_override("font_color", GOLD)
	_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_title.add_theme_constant_override("shadow_offset_y", 3)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.modulate.a = 0.0
	add_child(_title)

	_hint = Label.new()
	_hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_hint.offset_left = -360
	_hint.offset_right = -20
	_hint.offset_top = 14
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.text = "Click or Space: next    Esc: skip"
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color(0.6, 0.63, 0.7))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)


func _process(delta: float) -> void:
	step(delta)


## Move the cinematic on by [param seconds]. A test drives it with this.
func step(seconds: float) -> void:
	if finished:
		return
	clock += seconds
	elapsed += seconds
	var shot := current()
	if elapsed >= float(shot.get("time", 6.0)):
		next_shot()
		return
	_show_line()
	queue_redraw()


func current() -> Dictionary:
	return shots[index] if index < shots.size() else {}


func shot_id() -> String:
	return str(current().get("shot", ""))


## The narration line showing now, and how far through its own time it is.
func line_now() -> Array:
	var lines: Array = current().get("lines", [])
	if lines.is_empty():
		return ["", 0.0]
	var each := float(current().get("time", 6.0)) / float(lines.size())
	var at := mini(int(elapsed / each), lines.size() - 1)
	return [str(lines[at]).format(fill()), clampf((elapsed - each * at) / each, 0.0, 1.0), each]


func _show_line() -> void:
	var now := line_now()
	_caption.text = now[0]
	var each: float = now[2] if now.size() > 2 else 1.0
	var into: float = now[1] * each
	_caption.modulate.a = clampf(minf(into / FADE, (each - into) / FADE), 0.0, 1.0)
	_title.modulate.a = clampf(elapsed / 1.6, 0.0, 1.0) if shot_id() == "title" else 0.0


func next_shot() -> void:
	index += 1
	elapsed = 0.0
	if index >= shots.size():
		finish()
		return
	_show_line()
	queue_redraw()


func finish() -> void:
	if finished:
		return
	finished = true
	EventBus.request_scene.emit("world", {})


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		next_shot()
	elif event is InputEventScreenTouch and event.pressed:
		accept_event()
		next_shot()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		finish()
	elif event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		next_shot()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		next_shot()


# --- drawing -----------------------------------------------------------------


func _draw() -> void:
	var view := size
	var p := clampf(elapsed / maxf(0.01, float(current().get("time", 6.0))), 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, view), NIGHT)
	if shot_id() == "sixteen":
		_lead_at = _lead_spot(view) / view
	_cam = _camera(view, p)
	_xf()
	match shot_id():
		"void": _draw_void(view, p)
		"sixteen": _draw_sixteen(view, p)
		"worlds": _draw_worlds(view, p)
		"ending": _draw_ending(view, p)
		"fall": _draw_fall(view, p)
		"impact": _draw_impact(view, p)
		"tower": _draw_tower_shot(view, p)
		"land": _draw_land(view, p)
		"gate": _draw_gate(view, p)
		"inside": _draw_inside(view, p)
		"stair": _draw_stair(view, p)
		"living": _draw_living(view, p)
		"road": _draw_road(view, p)
		"company": _draw_company(view, p)
		"fight": _draw_fight(view, p)
		"foe": _draw_foe(view, p)
		"end": _draw_end(view, p)
		"title": _draw_title(view, p)
	# Black bars, as a film has, over the camera's moves.
	_cam = Transform2D.IDENTITY
	_xf()
	var bar := view.y * 0.06
	draw_rect(Rect2(0, 0, view.x, bar), Color.BLACK)
	draw_rect(Rect2(0, view.y - bar, view.x, bar), Color.BLACK)


## The camera for this shot at [param p] of the way through it: from the shot's `camera.from`
## to its `to` ([zoom, x, y], x and y the point looked at as a share of the screen, "lead" for x
## the lead wherever the shot last put them), eased, and kept from showing past the picture's edge.
func _camera(view: Vector2, p: float) -> Transform2D:
	var camera: Dictionary = current().get("camera", {})
	if camera.is_empty():
		return Transform2D.IDENTITY
	var eased := p * p * (3.0 - 2.0 * p)
	var from := _framing(camera.get("from", [1.0, 0.5, 0.5]))
	var to := _framing(camera.get("to", [1.0, 0.5, 0.5]))
	var zoom := maxf(1.0, lerpf(from.x, to.x, eased))
	var look := Vector2(lerpf(from.y, to.y, eased), lerpf(from.z, to.z, eased))
	var margin := 0.5 / zoom
	look = Vector2(clampf(look.x, margin, 1.0 - margin), clampf(look.y, margin, 1.0 - margin))
	return Transform2D(0.0, Vector2(zoom, zoom), 0.0, view * 0.5 - look * view * zoom)


func _framing(at: Variant) -> Vector3:
	var a: Array = at if at is Array else [1.0, 0.5, 0.5]
	var x: Variant = a[1] if a.size() > 1 else 0.5
	var y: Variant = a[2] if a.size() > 2 else 0.5
	return Vector3(float(a[0]) if a.size() > 0 else 1.0,
		_lead_at.x if str(x) == "lead" else float(x), _lead_at.y if str(y) == "lead" else float(y))


## Draw from here on at [param offset], turned by [param turn] and grown by [param grow], through
## the shot's camera.
func _xf(offset := Vector2.ZERO, turn := 0.0, grow := 1.0) -> void:
	draw_set_transform_matrix(_cam * Transform2D(turn, Vector2(grow, grow), 0.0, offset))


func _draw_stars(view: Vector2, strength: float) -> void:
	for star: Array in _stars:
		var twinkle := 0.55 + 0.45 * sin(clock * 1.7 + float(star[2]))
		draw_circle(Vector2(star[0]) * view, float(star[1]), Color(STAR, strength * twinkle * 0.8))


func _glow(at: Vector2, radius: float, colour: Color, strength: float) -> void:
	for k in 6:
		var share := 1.0 - float(k) / 6.0
		draw_circle(at, radius * (0.25 + share), Color(colour, strength * 0.12 * (1.0 - share * 0.5)))
	draw_circle(at, radius * 0.22, Color(colour.lightened(0.5), strength))


func _horizon(view: Vector2, at: float) -> float:
	var y := view.y * at
	draw_rect(Rect2(0, y, view.x, view.y - y), GROUND)
	draw_line(Vector2(0, y), Vector2(view.x, y), Color(0.25, 0.22, 0.3, 0.6), 2.0)
	return y


func _sprite(key: String, centre_feet: Vector2, height: float, tint := Color.WHITE, flip := false) -> void:
	var texture: Texture2D = _sprites.get(key)
	if texture == null:
		draw_circle(centre_feet - Vector2(0, height * 0.5), height * 0.3, tint)
		return
	var source := texture.get_size()
	var drawn := source * (height / source.y)
	var rect := Rect2(centre_feet - Vector2(drawn.x * 0.5, drawn.y), drawn)
	if flip:
		rect = Rect2(rect.position + Vector2(drawn.x, 0), Vector2(-drawn.x, drawn.y))
	draw_texture_rect(texture, rect, false, tint)


func _streak(head: Vector2, direction: Vector2, length: float, colour: Color, width: float) -> void:
	var pieces := 10
	for k in pieces:
		var a := head - direction * length * float(k) / pieces
		var b := head - direction * length * float(k + 1) / pieces
		draw_line(a, b, Color(colour, 1.0 - float(k) / pieces), width * (1.0 - float(k) / pieces * 0.7), true)
	_glow(head, width * 3.0, colour, 0.9)


func _draw_void(view: Vector2, p: float) -> void:
	_draw_stars(view, 0.3 + 0.7 * p)
	_glow(view * Vector2(0.5, 0.42), 30.0 + 90.0 * p, GOLD, 0.25 + 0.6 * p)


func _ring(view: Vector2, count: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var centre := view * Vector2(0.5, 0.44)
	var radius := minf(view.x, view.y) * 0.3
	for i in count:
		var angle := -PI * 0.5 + TAU * float(i) / float(count)
		out.append(centre + Vector2(cos(angle), sin(angle)) * Vector2(radius * 1.45, radius))
	return out




## Where the lead stands in the ring of the sixteen.
func _lead_spot(view: Vector2) -> Vector2:
	var heroes: Array = _data.get("sixteen", [])
	var at := heroes.find(_lead)
	return _ring(view, heroes.size())[at] if at >= 0 else view * Vector2(0.5, 0.44)


## The lead's chapter-one object ([D328]): its art when there is some, else a spark of their colour.
func _object(at: Vector2, height: float, alpha: float) -> void:
	if _sprites.get("object") != null:
		_glow(at, height * 0.6, _colour_of(_lead), alpha * 0.4)
		_sprite("object", at + Vector2(0, height * 0.5), height, Color(1, 1, 1, alpha))
		return
	_glow(at, height * 0.5, _colour_of(_lead), alpha * (0.75 + 0.25 * sin(clock * 7.0)))


func _draw_sixteen(view: Vector2, p: float) -> void:
	_draw_stars(view, 0.6)
	_glow(view * Vector2(0.5, 0.44), 60.0, GOLD, 0.5)
	var ring: Texture2D = _sprites.get("art:ring")
	if ring != null:
		var across := Vector2(minf(view.x, view.y) * 0.95 * 1.45, minf(view.x, view.y) * 0.95)
		draw_texture_rect(ring, Rect2(view * Vector2(0.5, 0.44) - across * 0.5, across), false, Color(1, 1, 1, 0.5))
	var heroes: Array = _data.get("sixteen", [])
	var spots := _ring(view, heroes.size())
	# The others light one after another; the lead lights last, and brightest, in their own colour.
	var others := heroes.filter(func(hero) -> bool: return str(hero) != _lead)
	var lit := int(p * float(others.size()) * 1.35)
	for i in heroes.size():
		var hero := str(heroes[i])
		# The fallen stand where they stood, grey, and never light.
		if _fallen.has(hero):
			_sprite("sixteen:" + hero, spots[i] + Vector2(0, 26), view.y * 0.11, Color(GHOST, 0.3))
			continue
		if hero == _lead:
			var mine := clampf((p - 0.72) / 0.2, 0.0, 1.0)
			_glow(spots[i] + Vector2(0, -6), 26.0 + 22.0 * mine, _colour_of(_lead), 0.06 + 0.8 * mine)
			_sprite("sixteen:" + hero, spots[i] + Vector2(0, 26), view.y * 0.11, Color(1, 1, 1, 0.18 + 0.82 * mine))
			continue
		var strength := 1.0 if others.find(hero) < lit else 0.18
		_glow(spots[i] + Vector2(0, -6), 26.0, GOLD, 0.35 * strength)
		_sprite("sixteen:" + hero, spots[i] + Vector2(0, 26), view.y * 0.11, Color(1, 1, 1, strength))


## One of the other worlds ending (D99): its lead stands on it, and it goes
## dark under them and does not come back. At the last, a gate in the dark opens
## its eyes: what is left of them waits there now ([D328]).
func _draw_ending(view: Vector2, p: float) -> void:
	_draw_stars(view, 0.5 * (1.0 - p * 0.6))
	var at := view * Vector2(0.5, 0.46)
	var radius := minf(view.x, view.y) * 0.17
	# Behind it, the worlds that went before, already dark.
	for k in maxi(0, _fallen.size() - 1):
		var angle := TAU * float(k) / 15.0 - PI * 0.5
		_globe(at + Vector2(cos(angle) * radius * 2.6, sin(angle) * radius * 1.7), radius * 0.22, 0.7, 1.0)
	var dark := clampf((p - 0.3) / 0.45, 0.0, 1.0)
	var gone := clampf((p - 0.8) / 0.2, 0.0, 1.0)
	var burning: Texture2D = _sprites.get("art:burning_world")
	if burning != null and dark > 0.0:
		# Four frames side by side, the globe cracking into ash.
		var frame := mini(3, int(dark * 4.0))
		var cell := Vector2(burning.get_width() / 4.0, burning.get_height())
		draw_texture_rect_region(burning, Rect2(at - Vector2(radius, radius), Vector2(radius, radius) * 2.0),
				Rect2(Vector2(cell.x * frame, 0), cell), Color(1, 1, 1, 1.0 - gone * 0.85))
	else:
		_globe(at, radius, 1.0 - gone * 0.85, dark)
	var feet := at + Vector2(0, -radius * 0.92)
	_glow(feet + Vector2(0, -20), 30.0, GOLD, 0.4 * (1.0 - dark))
	_sprite("sixteen:" + _other, feet, view.y * 0.12, Color(1, 1, 1, 1.0 - dark).lerp(Color(GHOST, 0.0), gone))
	# The light going out of it, a crack at a time.
	if dark > 0.0:
		for k in 5:
			var angle := TAU * float(k) / 5.0 + 0.4
			var reach := radius * 0.95 * clampf(dark * 1.4 - float(k) * 0.08, 0.0, 1.0)
			draw_line(at, at + Vector2(cos(angle), sin(angle)) * reach, Color(EMBER, 0.7 * (1.0 - gone)), 2.0, true)
	if p > 0.82:
		var eyes := clampf((p - 0.82) / 0.12, 0.0, 1.0)
		var gate := at + Vector2(0, radius * 0.35)
		if _sprites.get("art:demon_gate") != null:
			_sprite("art:demon_gate", gate + Vector2(0, radius * 0.3), radius * 0.9, Color(1, 1, 1, eyes))
			return
		_sprite("gate", gate + Vector2(0, radius * 0.3), radius * 0.9, Color(0.4, 0.3, 0.35, eyes))
		for side in [-1.0, 1.0]:
			_glow(gate + Vector2(side * radius * 0.09, -radius * 0.25), 10.0, BLOOD, eyes)


func _draw_fall(view: Vector2, p: float) -> void:
	_draw_stars(view, 0.8)
	var direction := Vector2(0.45, 1.0).normalized()
	_rng.seed = 77
	for i in 16:
		var delay := _rng.randf_range(0.0, 0.45)
		var start := Vector2(_rng.randf_range(-0.2, 0.9) * view.x, -view.y * _rng.randf_range(0.05, 0.4))
		var travel := (p - delay) * view.y * 2.1
		if travel <= 0.0:
			continue
		_streak(start + direction * travel, direction, 160.0, GOLD.lerp(EMBER, float(i) / 16.0), 4.0)
	# The lead, tumbling through the middle of it, and the thing they carried falling beside them,
	# until it slips away, towards where the Tower will be ([D328]).
	var centre := view * Vector2(0.5, lerpf(0.36, 0.64, p))
	_glow(centre, 40.0, _colour_of(_lead), 0.35)
	_xf(centre, clock * 2.2)
	_sprite("sixteen:" + _lead, Vector2(0, view.y * 0.06), view.y * 0.12)
	_xf()
	var away := clampf((p - 0.5) / 0.5, 0.0, 1.0)
	var beside := centre + Vector2(view.y * 0.1, -view.y * 0.03)
	_object(beside.lerp(view * Vector2(0.9, 0.95), away * away), view.y * 0.08, 1.0 - away * 0.6)
	if p > 0.6:
		_horizon(view, lerpf(1.1, 0.78, (p - 0.6) / 0.4))


func _globe(at: Vector2, radius: float, alpha: float, dark := 0.0) -> void:
	var sea := Color(0.16, 0.34, 0.55).lerp(Color(0.05, 0.05, 0.07), dark)
	var land := Color(0.3, 0.55, 0.32).lerp(Color(0.08, 0.08, 0.08), dark)
	draw_circle(at, radius * 1.18, Color(0.5, 0.7, 1.0, 0.12 * alpha * (1.0 - dark)))
	draw_circle(at, radius, Color(sea, alpha))
	draw_circle(at + Vector2(-radius * 0.3, -radius * 0.15), radius * 0.42, Color(land, alpha))
	draw_circle(at + Vector2(radius * 0.35, radius * 0.3), radius * 0.3, Color(land, alpha))
	# The Tower, standing out of the middle of every one.
	draw_line(at, at + Vector2(0, -radius * 1.55), Color(GOLD, alpha * (1.0 - dark)), 2.0, true)


func _draw_worlds(view: Vector2, p: float) -> void:
	_draw_stars(view, 0.7)
	var spots := _ring(view, 16)
	var shown := int(p * 16.0 * 1.6)
	for i in 16:
		if i >= shown:
			continue
		# Near the end every world but one dims: only one will be left.
		var fade := 1.0 if i == 0 else clampf(1.0 - (p - 0.62) / 0.3, 0.25, 1.0)
		# The fallen's worlds are dark from the start; the first is always the one still lit.
		var dark := 1.0 if i > 0 and i <= _fallen.size() else 0.0
		_globe(spots[i], minf(view.x, view.y) * 0.04, fade, dark)






func _draw_impact(view: Vector2, p: float) -> void:
	var hit := 0.35
	var shake := Vector2.ZERO
	if p > hit and p < hit + 0.12:
		shake = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 10.0 * (1.0 - (p - hit) / 0.12)
	_xf(shake)
	_draw_stars(view, 0.5)
	var ground := _horizon(view, 0.72)
	var spot := Vector2(view.x * 0.58, ground + 6.0)
	if p < hit:
		var direction := Vector2(0.45, 1.0).normalized()
		_streak(spot - direction * view.y * (1.0 - p / hit), direction, 220.0, EMBER, 6.0)
	else:
		var after := (p - hit) / (1.0 - hit)
		# The furrow, ploughed back the way it came, still smoking.
		draw_line(spot + Vector2(-view.x * 0.32, 0), spot, Color(0.02, 0.02, 0.02), 7.0)
		draw_line(spot + Vector2(-view.x * 0.32, 0), spot, Color(EMBER, 0.35 * (1.0 - after)), 3.0)
		for k in 7:
			var puff := spot + Vector2(-k * 34.0, -20.0 - after * 60.0 - k * 6.0)
			draw_circle(puff, 14.0 + after * 18.0, Color(0.4, 0.4, 0.45, 0.18 * (1.0 - after)))
		draw_arc(spot, after * view.x * 0.5, PI, TAU, 48, Color(GOLD, 0.6 * (1.0 - after)), 3.0, true)
		# Somebody lying at the end of it.
		var lead := "sixteen:" + _lead
		_xf(spot + shake + Vector2(18, -10), PI * 0.5)
		_sprite(lead, Vector2(0, 30), view.y * 0.09)
		_xf(shake)
		# A hand into the crater ([D328]): Bram's, and the landing's first words follow on.
		if after > 0.7:
			var reach := clampf((after - 0.7) / 0.25, 0.0, 1.0)
			var rim := spot + Vector2(view.x * 0.16, -view.y * 0.05)
			_sprite("helper", rim + Vector2(0, 8), view.y * 0.13, Color(1, 1, 1, reach))
			var arm_from := rim + Vector2(-view.y * 0.03, -view.y * 0.07)
			var arm_to := arm_from.lerp(spot + Vector2(34, -20), reach)
			draw_line(arm_from, arm_to, Color(0.72, 0.56, 0.42, reach), 6.0, true)
			draw_circle(arm_to, 6.0, Color(0.78, 0.62, 0.48, reach))
	if p > hit and p < hit + 0.08:
		draw_rect(Rect2(Vector2.ZERO, view), Color(1, 0.95, 0.85, 0.85 * (1.0 - (p - hit) / 0.08)))
	_xf()


func _tower(view: Vector2, base: Vector2, height: float, alpha: float, lit: float) -> void:
	var half := height * 0.06
	var top := base + Vector2(0, -height)
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-half, 0), base + Vector2(half, 0), top + Vector2(half * 0.25, 0), top + Vector2(-half * 0.25, 0),
	]), Color(0.02, 0.02, 0.03, alpha))
	# Twenty chapters up its side, lighting from the bottom as it is climbed.
	for k in 20:
		var y := base.y - height * (0.05 + 0.9 * float(k) / 20.0)
		var on := float(k) / 20.0 < lit
		draw_rect(Rect2(base.x - 2, y, 4, 6), Color(GOLD, alpha * (0.9 if on else 0.15)))
	_glow(top, 24.0, GOLD, alpha * 0.8)




func _draw_tower_shot(view: Vector2, p: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), DUSK)
	_draw_stars(view, 0.4)
	var ground := _horizon(view, 0.74)
	var base := Vector2(view.x * 0.58, ground)
	var height := view.y * 0.68
	_tower(view, base, height, 1.0, p * 0.6)
	_sprite("sixteen:" + _lead, Vector2(view.x * 0.24, ground + 4), view.y * 0.12)
	# Near floor 5, a window flares in the lead's colour: what fell with them is there ([D328]).
	if p > 0.55:
		var flare := clampf((p - 0.55) / 0.25, 0.0, 1.0)
		_glow(base + Vector2(0, -height * 0.1), 14.0 + 10.0 * sin(clock * 6.0), _colour_of(_lead), flare)


## Wide over the land the lead wakes in ([D328]): the city, the road with a carriage on it, a
## village, a band on red ground, a cave; the camera pans across it.
func _draw_land(view: Vector2, p: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), DUSK)
	_draw_stars(view, 0.3)
	var ground := _horizon(view, 0.52)
	_sprite("keep", Vector2(view.x * 0.12, ground + 30), view.y * 0.2)
	var road := PackedVector2Array()
	for k in 17:
		var u := float(k) / 16.0
		road.append(Vector2(lerpf(0.18, 0.48, u) * view.x, ground + view.y * (0.12 + 0.04 * sin(u * 6.0))))
	draw_polyline(road, Color(0.32, 0.27, 0.2), 14.0, true)
	var cart := road[int(fposmod(clock * 0.08, 1.0) * 16.0)]
	draw_rect(Rect2(cart + Vector2(-16, -20), Vector2(32, 14)), Color(0.36, 0.2, 0.12))
	draw_rect(Rect2(cart + Vector2(-12, -18), Vector2(8, 6)), Color(GOLD, 0.7))
	_sprite("town", Vector2(view.x * 0.52, ground + 40), view.y * 0.15)
	# Red ground, and a band on it nobody should walk into yet.
	var red := Vector2(view.x * 0.72, ground + view.y * 0.2)
	draw_circle(red, view.y * 0.1, Color(0.32, 0.08, 0.07))
	for k in 4:
		_sprite("unit:" + str(_data.get("foe", "")), red + Vector2((k - 1.5) * 24.0, 10.0 - (k % 2) * 12.0), view.y * 0.07,
				Color(0.5, 0.35, 0.35))
	var cave := Vector2(view.x * 0.9, ground + view.y * 0.12)
	draw_circle(cave, view.y * 0.09, Color(0.16, 0.15, 0.17))
	draw_circle(cave + Vector2(0, view.y * 0.03), view.y * 0.045, Color(0.01, 0.01, 0.01))
	_glow(cave + Vector2(0, view.y * 0.02), 8.0, BLOOD, 0.3 + 0.2 * sin(clock * 3.0))


## A gate, its rank over it, and the camera pushing in through it.
func _draw_gate(view: Vector2, p: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.04, 0.03, 0.05))
	var ground := _horizon(view, 0.74)
	var gate := Vector2(view.x * 0.5, ground + 6)
	_glow(gate + Vector2(0, -view.y * 0.14), 60.0 + 10.0 * sin(clock * 5.0), BLOOD, 0.5)
	_sprite("gate", gate, view.y * 0.3)
	draw_string(ThemeDB.fallback_font, gate + Vector2(-14, -view.y * 0.34), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(GOLD, 0.9))
	if p > 0.85:
		draw_rect(Rect2(Vector2.ZERO, view), Color(0, 0, 0, (p - 0.85) / 0.15))


## Inside a gate: the company in a wedge, the first strike, then the world stopped with a box drawn.
func _draw_inside(view: Vector2, p: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.08, 0.1, 0.08))
	var paused := p > 0.45 and p < 0.85
	var party: Array = _data.get("party", [])
	var height := view.y * 0.12
	var grey := Color(0.6, 0.6, 0.65) if paused else Color.WHITE
	var wedge := [Vector2(0.36, 0.5), Vector2(0.29, 0.38), Vector2(0.29, 0.62), Vector2(0.22, 0.28), Vector2(0.22, 0.72)]
	var charge := clampf(p / 0.3, 0.0, 1.0)
	for i in mini(wedge.size(), party.size()):
		var at: Vector2 = wedge[i] * view + Vector2(view.x * 0.08 * charge, 0)
		_sprite("unit_east:" + str(party[i]), at, height, grey)
	for k in 3:
		_sprite("unit:" + str(_data.get("foe", "")), Vector2(view.x * (0.68 + 0.06 * k), view.y * (0.4 + 0.15 * k)), height * 1.3, grey, true)
	if p > 0.28 and p < 0.45:
		var flash := (p - 0.28) / 0.17
		var hit := view * Vector2(0.58, 0.46)
		draw_arc(hit, 20.0 + flash * 30.0, -1.0, 1.0, 12, Color(1, 1, 1, 1.0 - flash), 4.0, true)
		draw_string(ThemeDB.fallback_font, hit + Vector2(36, -flash * 30.0), "24", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(GOLD, 1.0 - flash))
	if paused:
		draw_rect(Rect2(Vector2.ZERO, view), Color(0.1, 0.12, 0.2, 0.35))
		draw_string(ThemeDB.fallback_font, Vector2(view.x * 0.5 - 18, view.y * 0.2), "II", HORIZONTAL_ALIGNMENT_LEFT, -1, 46, Color(0.9, 0.92, 1.0))
		var drag := clampf((p - 0.5) / 0.25, 0.0, 1.0)
		var box := Rect2(Vector2(view.x * 0.17, view.y * 0.2), Vector2(view.x * 0.32, view.y * 0.6) * drag)
		draw_rect(box, Color(1.0, 0.86, 0.3, 0.12))
		draw_rect(box, Color(1.0, 0.86, 0.3, 0.9), false, 2.0)


func _draw_living(view: Vector2, p: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), DUSK)
	var ground := _horizon(view, 0.66)
	_sprite("town", Vector2(view.x * 0.16, ground + 6), view.y * 0.16)
	_sprite("keep", Vector2(view.x * 0.84, ground + 6), view.y * 0.16)
	# People and carts going between the two, all day, whether you watch or not.
	for k in 6:
		var x := fposmod(clock * 0.06 + float(k) / 6.0, 1.0)
		draw_circle(Vector2(lerpf(view.x * 0.22, view.x * 0.78, x), ground + 18 + (k % 3) * 9), 3.0, Color(0.8, 0.78, 0.7, 0.8))
	# The gate in the middle, left alone, until it breaks.
	var gate := Vector2(view.x * 0.5, ground + 36)
	var pressure := clampf(p / 0.6, 0.0, 1.0)
	_glow(gate + Vector2(0, -30), 40.0 + 20.0 * sin(clock * 6.0) * pressure, BLOOD, 0.3 + 0.5 * pressure)
	_sprite("gate", gate, view.y * 0.14)
	if p > 0.6:
		var burst := (p - 0.6) / 0.4
		draw_arc(gate + Vector2(0, -30), burst * view.x * 0.3, 0.0, TAU, 48, Color(BLOOD, 0.7 * (1.0 - burst)), 4.0, true)
		_rng.seed = 5
		for k in 14:
			var away := Vector2(_rng.randf_range(-1, 1), _rng.randf_range(0.1, 0.6)).normalized()
			draw_circle(gate + away * burst * view.x * 0.22, 5.0, Color(0.12, 0.05, 0.05))


func _draw_road(view: Vector2, p: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), DUSK)
	var ground := _horizon(view, 0.55)
	var road := PackedVector2Array()
	for k in 33:
		var u := float(k) / 32.0
		road.append(Vector2(u * view.x, ground + view.y * (0.08 + 0.22 * u) + sin(u * 5.0) * 18.0))
	draw_polyline(road, Color(0.32, 0.27, 0.2), 26.0, true)
	var stop := 0.62
	var t := minf(p, stop) / stop * 0.6 + 0.1
	var at := road[int(t * 32.0)]
	# The carriage, rolling until the road decides otherwise.
	draw_rect(Rect2(at + Vector2(-34, -40), Vector2(68, 30)), Color(0.36, 0.2, 0.12))
	draw_rect(Rect2(at + Vector2(-26, -36), Vector2(16, 12)), Color(GOLD, 0.7))
	for wheel in [-22.0, 22.0]:
		draw_arc(at + Vector2(wheel, -8), 9.0, 0.0, TAU, 16, Color(0.12, 0.1, 0.08), 3.0, true)
	if p > stop:
		var ambush := (p - stop) / (1.0 - stop)
		for k in 4:
			var from := at + Vector2(140 + k * 40, -10 - k * 6)
			_sprite("unit_east:" + str(_data.get("foe", "")), from.lerp(at + Vector2(60 + k * 18, 0), ambush), view.y * 0.08,
					Color(0.35, 0.3, 0.32), true)
		draw_string(ThemeDB.fallback_font, at + Vector2(-8, -60), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(BLOOD, ambush))




func _draw_fight(view: Vector2, p: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.08, 0.1, 0.08))
	var paused := p > 0.3 and p < 0.68
	var party: Array = _data.get("party", [])
	var height := view.y * 0.12
	var spots: Array[Vector2] = []
	for i in mini(4, party.size()):
		spots.append(Vector2(view.x * (0.24 + 0.06 * (i % 2)), view.y * (0.32 + 0.14 * i)))
	var grey := Color(0.6, 0.6, 0.65) if paused else Color.WHITE
	for i in spots.size():
		_sprite("unit_east:" + str(party[i]), spots[i], height, grey)
	for k in 3:
		_sprite("unit:" + str(_data.get("foe", "")), Vector2(view.x * (0.68 + 0.05 * k), view.y * (0.38 + 0.16 * k)), height * 1.5, grey, true)
	if paused:
		# Everything stops: look, pick your people with a box, choose.
		draw_rect(Rect2(Vector2.ZERO, view), Color(0.1, 0.12, 0.2, 0.35))
		draw_string(ThemeDB.fallback_font, Vector2(view.x * 0.5 - 18, view.y * 0.2), "II", HORIZONTAL_ALIGNMENT_LEFT, -1, 46, Color(0.9, 0.92, 1.0))
		var drag := clampf((p - 0.34) / 0.22, 0.0, 1.0)
		var box := Rect2(Vector2(view.x * 0.17, view.y * 0.18), Vector2(view.x * 0.2, view.y * 0.62) * drag)
		draw_rect(box, Color(1.0, 0.86, 0.3, 0.12))
		draw_rect(box, Color(1.0, 0.86, 0.3, 0.9), false, 2.0)
	elif p >= 0.68:
		for k in 5:
			var at := Vector2(view.x * (0.5 + 0.04 * sin(k * 2.3)), view.y * (0.32 + 0.1 * k))
			var flash := fposmod(clock * 2.0 + k * 0.37, 1.0)
			draw_arc(at, 20.0 + flash * 24.0, -1.0, 1.0, 12, Color(1, 1, 1, 1.0 - flash), 3.0, true)
			draw_string(ThemeDB.fallback_font, at + Vector2(40, -flash * 30.0), str(12 + k * 7), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(GOLD, 1.0 - flash))


func _draw_foe(view: Vector2, p: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.03, 0.02, 0.03))
	var rise := clampf(p / 0.5, 0.0, 1.0)
	var feet := Vector2(view.x * 0.5, view.y * 0.86)
	var height := view.y * 0.56
	_glow(feet + Vector2(0, -height * 0.78), 50.0, BLOOD, 0.3 * rise)
	_sprite("unit:" + str(_data.get("foe", "")), feet, height, Color(rise, rise * 0.9, rise * 0.9, 1.0))
	if p > 0.55:
		# The scar you gave it.
		var scar := clampf((p - 0.55) / 0.2, 0.0, 1.0)
		var from := feet + Vector2(-height * 0.12, -height * 0.86)
		draw_line(from, from.lerp(from + Vector2(height * 0.22, height * 0.12), scar), Color(BLOOD, 0.95), 4.0, true)




## The company ([D328]): six join one by one; one goes down and is lifted; another goes down and
## stays; five walk on.
func _draw_company(view: Vector2, p: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), DUSK)
	var ground := _horizon(view, 0.74)
	var party: Array = _data.get("party", [])
	var joined := clampi(1 + int(p / 0.4 * float(party.size())), 1, party.size())
	var walk := clampf((p - 0.75) / 0.25, 0.0, 1.0) * view.x * 0.12
	for i in joined:
		var feet := Vector2(view.x * (0.24 + 0.09 * float(i)), ground + 6)
		var key := "unit_east:" + str(party[i])
		if i == 1 and p > 0.45 and p < 0.62:
			# Down, and lifted again by the one beside them.
			var up := clampf((p - 0.53) / 0.09, 0.0, 1.0)
			_xf(feet + Vector2(0, -view.y * 0.03), lerpf(PI * 0.5, 0.0, up))
			_sprite(key, Vector2(0, view.y * 0.06), view.y * 0.13)
			_xf()
			continue
		if i == 4 and p > 0.62:
			# Down, and this one stays where they fell.
			var fade := clampf((p - 0.68) / 0.2, 0.0, 1.0)
			_xf(feet + Vector2(0, -view.y * 0.03), PI * 0.5)
			_sprite(key, Vector2(0, view.y * 0.06), view.y * 0.13, Color(1, 1, 1, 1.0).lerp(Color(GHOST, 0.35), fade))
			_xf()
			continue
		_sprite(key, feet + Vector2(walk, 0), view.y * 0.13)
	_tower(view, Vector2(view.x * 0.92, ground), view.y * 0.5, 0.6, 0.0)


## The stair ([D328]): the lead climbs; at an alcove on floor 5 they find what fell with them,
## pick it up, and the screen goes white.
func _draw_stair(view: Vector2, p: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.05, 0.05, 0.08))
	var steps := 9
	var rise := view.y * 0.065
	var tread := view.x * 0.06
	var start := Vector2(view.x * 0.16, view.y * 0.84)
	for k in steps:
		var at := start + Vector2(tread * k, -rise * k)
		draw_rect(Rect2(at, Vector2(tread + 2, rise * (k + 1) + view.y * 0.2)), Color(0.13, 0.12, 0.15))
		draw_line(at, at + Vector2(tread, 0), Color(0.3, 0.28, 0.33), 2.0)
	var landing := start + Vector2(tread * steps, -rise * (steps - 1))
	draw_rect(Rect2(landing, Vector2(view.x * 0.3, view.y * 0.5)), Color(0.13, 0.12, 0.15))
	var alcove := landing + Vector2(view.x * 0.12, -view.y * 0.16)
	draw_rect(Rect2(alcove + Vector2(-view.y * 0.07, -view.y * 0.02), Vector2(view.y * 0.14, view.y * 0.18)), Color(0.02, 0.02, 0.03))
	draw_string(ThemeDB.fallback_font, alcove + Vector2(-view.y * 0.06, -view.y * 0.04), "5", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(GOLD, 0.6))
	var climb := clampf(p / 0.6, 0.0, 1.0)
	var feet := start.lerp(landing + Vector2(view.x * 0.06, 0), climb) + Vector2(tread * 0.5, 0)
	var taken := p > 0.75
	if not taken:
		_object(alcove + Vector2(0, view.y * 0.1), view.y * 0.05, 1.0)
	_sprite("sixteen:" + _lead, feet, view.y * 0.13)
	if taken:
		_object(feet + Vector2(view.y * 0.04, -view.y * 0.07), view.y * 0.04, 1.0)
	if p > 0.8:
		draw_rect(Rect2(Vector2.ZERO, view), Color(1, 1, 1, clampf((p - 0.8) / 0.15, 0.0, 1.0)))


## A world ending with its lead ([D328]): it goes dark; their weapon streaks into the next world;
## it lands in a scorched ring a monster comes towards; and a ghost waits at a fire.
func _draw_end(view: Vector2, p: float) -> void:
	_draw_stars(view, 0.6)
	if stage() == "last":
		_draw_last_fire(view, p)
		return
	var mine := view * Vector2(0.3, 0.42)
	var theirs := view * Vector2(0.74, 0.42)
	var radius := minf(view.x, view.y) * 0.12
	if p < 0.5:
		_globe(mine, radius, clampf(1.6 - p * 3.2, 0.0, 1.0), clampf(p / 0.22, 0.0, 1.0))
		_globe(theirs, radius * 0.8, clampf(p * 3.0, 0.0, 1.0))
		if p > 0.22:
			var t := (p - 0.22) / 0.28
			var head := mine.lerp(theirs, t) + Vector2(0, -sin(t * PI) * radius * 1.4)
			_streak(head, (theirs - mine).normalized(), 120.0, EMBER, 5.0)
		return
	var ground := _horizon(view, 0.8)
	if p < 0.76:
		# Where it came down: a scorched ring, the weapon standing in it, and something coming.
		var landed := Vector2(view.x * 0.45, ground + 8)
		draw_arc(landed, view.x * 0.06, PI, TAU, 24, Color(0.03, 0.02, 0.02), 10.0, true)
		draw_arc(landed, view.x * 0.06, PI, TAU, 24, Color(EMBER, 0.5), 2.0, true)
		draw_line(landed + Vector2(0, 6), landed + Vector2(6, -view.y * 0.12), Color(0.75, 0.75, 0.8), 4.0, true)
		_glow(landed + Vector2(4, -view.y * 0.1), 10.0, EMBER, 0.6)
		var near := (p - 0.5) / 0.26
		_sprite("unit:" + str(_data.get("foe", "")), Vector2(lerpf(view.x * 0.95, view.x * 0.66, near), ground + 10),
				view.y * 0.16, Color(0.45, 0.38, 0.4), true)
		return
	var fire := Vector2(view.x * 0.56, ground + 8)
	_glow(fire + Vector2(0, -14), 40.0, EMBER, 0.6 + 0.2 * sin(clock * 9.0))
	_sprite("fire", fire, view.y * 0.08)
	# On the first life it is you who would wait there; after, the one who just fell does.
	var ghost := _lead if _fallen.is_empty() else _other
	_sprite("sixteen:" + ghost, fire + Vector2(-60, 0), view.y * 0.12, Color(GHOST, 0.55 * clampf((p - 0.76) / 0.1, 0.0, 1.0)))


## The last of the sixteen: no world after this one, and every one of the
## fallen at the fire.
func _draw_last_fire(view: Vector2, p: float) -> void:
	var fire := Vector2(view.x * 0.5, view.y * 0.66)
	_glow(fire + Vector2(0, -14), 60.0, EMBER, 0.6 + 0.2 * sin(clock * 9.0))
	_sprite("fire", fire, view.y * 0.1)
	var shown := clampf(p * 1.6, 0.0, 1.0)
	for k in _fallen.size():
		var angle := PI + PI * float(k) / maxf(1.0, float(_fallen.size() - 1))
		var at := fire + Vector2(cos(angle) * view.x * 0.3, sin(angle) * view.y * 0.22 + 10.0)
		var alpha := 0.55 * clampf(shown * float(_fallen.size()) - float(k), 0.0, 1.0)
		_sprite("sixteen:" + str(_fallen[k]), at, view.y * 0.1, Color(GHOST, alpha))


func _draw_title(view: Vector2, p: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), DUSK)
	_draw_stars(view, 0.7)
	var ground := _horizon(view, 0.8)
	_tower(view, Vector2(view.x * 0.5, ground), view.y * 0.72, 0.5 + 0.3 * p, 0.0)
