extends Control
## The play screen, arranged by the player ([D351], Ewan's play-test 8: "You need to fix or resize
## the text boxes. For user interface, I would like it so that when in-game I'm able to edit the
## size of them and choose where I want to place them on my screen"; play-test 7, item 12).
##
## The walked ground's panels (the place's name, the compass, the company, the corner map, the log,
## the hint line, and the box people talk in) are each given to [method hold] with an id. Asked to
## arrange ([signal EventBus.screen_arrange_requested], the menu's Arrange the Screen, or Arrange on
## the quick wheel), a frame is drawn round each: drag inside it to move it, drag its corner to make
## a box bigger or smaller (the log), turn the wheel over it to make it and its words bigger or
## smaller. Done keeps it in `user://settings.cfg` → `[layout]`, where it is kept as a share of the
## screen, so it stays put when the window changes size; Put It All Back forgets the lot.
##
## Words and sizes are `data/world_rules.json` → `screen_layout`. Loaded by path ([D41]).

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "layout"
## The box people talk in lives on its own layer ([DialogueBox]); it is arranged by a stand-in.
const WORDS := "words"
## Where the box people talk in stands when nobody has moved it: its bottom middle, this far up.
const WORDS_DROP := 14.0
## How big the stand-in for the box people talk in is drawn.
const WORDS_SIZE := Vector2(480.0, 110.0)

## What is kept in the settings file, read once ([method saved_all]) and again only when kept.
static var _cache: Variant = null

var _held: Dictionary = {}
## How each panel stood before anything was laid on it, to put it back.
var _first: Dictionary = {}
var _arranging := false
var _dragging := ""
var _resizing := false
var _grabbed_at := Vector2.ZERO
var _grabbed_rect := Rect2()
var _bar: PanelContainer


static func rules() -> Dictionary:
	return Database.world_rules.get("screen_layout", {})


## Everything the player has laid out, by panel id.
static func saved_all() -> Dictionary:
	if _cache is Dictionary:
		return (_cache as Dictionary).duplicate(true)
	var cfg := ConfigFile.new()
	_cache = {}
	if cfg.load(SETTINGS_PATH) != OK or not cfg.has_section(SECTION):
		return {}
	var out := {}
	for key in cfg.get_section_keys(SECTION):
		var entry: Variant = cfg.get_value(SECTION, key, {})
		if entry is Dictionary:
			out[key] = entry
	_cache = out
	return out.duplicate(true)


static func saved(id: String) -> Dictionary:
	return saved_all().get(id, {})


static func keep(laid: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	if cfg.has_section(SECTION):
		cfg.erase_section(SECTION)
	for id: String in laid:
		cfg.set_value(SECTION, id, laid[id])
	cfg.save(SETTINGS_PATH)
	_cache = laid.duplicate(true)


## Whether the player has put [param id] somewhere of their own, so its own fitting leaves it be.
static func is_laid(id: String) -> bool:
	return not saved(id).is_empty()


## Where the box people talk in has been moved to from where it stands of itself, and how big it
## is drawn: `{ "shift": Vector2, "scale": float }`.
static func words_place(screen: Vector2) -> Dictionary:
	var entry := saved(WORDS)
	if entry.is_empty():
		return { "shift": Vector2.ZERO, "scale": 1.0 }
	var home := Vector2(screen.x / 2.0, screen.y - WORDS_DROP)
	var there := Vector2(float(entry.get("x", 0.5)) * screen.x, float(entry.get("y", 1.0)) * screen.y)
	return { "shift": there - home, "scale": float(entry.get("scale", 1.0)) }


func _ready() -> void:
	name = "ScreenLayout"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar = _make_bar()
	add_child(_bar)
	_bar.hide()
	EventBus.screen_arrange_requested.connect(arrange)
	EventBus.quick_wheel_chose.connect(func(id: String) -> void:
		if id == "arrange":
			arrange()
	)
	get_viewport().size_changed.connect(_lay_all)


func is_arranging() -> bool:
	return _arranging


## Take a panel in: how it stands now is how it goes back, and whatever was laid out for it before
## is laid on it now.
func hold(id: String, control: Control) -> void:
	_held[id] = control
	_first[id] = {
		"anchors": [control.anchor_left, control.anchor_top, control.anchor_right, control.anchor_bottom],
		"offsets": [control.offset_left, control.offset_top, control.offset_right, control.offset_bottom],
		"scale": control.scale,
	}
	_lay(id)


func _lay_all() -> void:
	for id: String in _held:
		_lay(id)


func _lay(id: String) -> void:
	var control: Control = _held[id]
	var entry := saved(id)
	if entry.is_empty():
		return
	var screen := get_viewport().get_visible_rect().size
	var grown := float(entry.get("scale", 1.0))
	control.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
	if entry.has("w") and _sized(id):
		control.size = Vector2(float(entry["w"]), float(entry["h"]))
	control.scale = Vector2.ONE * grown
	var at := Vector2(float(entry.get("x", 0.0)) * screen.x, float(entry.get("y", 0.0)) * screen.y)
	control.position = _kept_on(at, control.size * grown, screen)


## A panel always keeps a corner of itself on the screen, so it can be found and dragged back.
func _kept_on(at: Vector2, extent: Vector2, screen: Vector2) -> Vector2:
	var showing := float(rules().get("keep_showing", 40))
	return Vector2(
		clampf(at.x, showing - extent.x, screen.x - showing),
		clampf(at.y, 0.0, screen.y - minf(showing, extent.y))
	)


func _sized(id: String) -> bool:
	for panel: Dictionary in rules().get("panels", []):
		if str(panel.get("id", "")) == id:
			return str(panel.get("resize", "scale")) == "size"
	return false


func _label(id: String) -> String:
	for panel: Dictionary in rules().get("panels", []):
		if str(panel.get("id", "")) == id:
			return str(panel.get("label", id))
	return id


## Begin arranging: a frame round every panel and the bar of words at the top.
func arrange() -> void:
	if _arranging or not bool(rules().get("on", true)):
		return
	_arranging = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bar.show()
	_centre_the_bar.call_deferred()
	queue_redraw()


## The bar of words stands in the middle of the screen, a little above halfway, clear of the panels
## along the edges.
func _centre_the_bar() -> void:
	_bar.reset_size()
	var screen := get_viewport().get_visible_rect().size
	_bar.position = Vector2((screen.x - _bar.size.x) / 2.0, screen.y * 0.38)


## Done: what was moved is kept.
func finish() -> void:
	if not _arranging:
		return
	_arranging = false
	_dragging = ""
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.hide()
	queue_redraw()


## Every panel where it stood before anything was laid on it, and nothing kept.
func put_back() -> void:
	keep({})
	for id: String in _held:
		var control: Control = _held[id]
		var first: Dictionary = _first[id]
		control.anchor_left = first["anchors"][0]
		control.anchor_top = first["anchors"][1]
		control.anchor_right = first["anchors"][2]
		control.anchor_bottom = first["anchors"][3]
		control.offset_left = first["offsets"][0]
		control.offset_top = first["offsets"][1]
		control.offset_right = first["offsets"][2]
		control.offset_bottom = first["offsets"][3]
		control.scale = first["scale"]
	EventBus.screen_arranged.emit()
	queue_redraw()


## Where each frame is drawn, by id: the panels' own rects, and the stand-in for the box people
## talk in.
func frames() -> Dictionary:
	var out := {}
	for id: String in _held:
		var control: Control = _held[id]
		if is_instance_valid(control):
			out[id] = control.get_global_rect()
	var screen := get_viewport().get_visible_rect().size
	var words := words_place(screen)
	var grown: float = words["scale"]
	var extent := WORDS_SIZE * grown
	var bottom_middle: Vector2 = Vector2(screen.x / 2.0, screen.y - WORDS_DROP) + words["shift"]
	out[WORDS] = Rect2(bottom_middle - Vector2(extent.x / 2.0, extent.y), extent)
	return out


func _gui_input(event: InputEvent) -> void:
	if not _arranging:
		return
	var press := event as InputEventMouseButton
	if press != null:
		if press.button_index == MOUSE_BUTTON_LEFT and press.pressed:
			_grab(press.position)
		elif press.button_index == MOUSE_BUTTON_LEFT and not press.pressed:
			_let_go()
		elif press.pressed and (press.button_index == MOUSE_BUTTON_WHEEL_UP or press.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var over := _frame_at(press.position)
			if over != "":
				grow(over, float(rules().get("scale_step", 0.1)) * (1.0 if press.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0))
		accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _dragging != "":
		drag(_dragging, motion.position - _grabbed_at, _resizing)
		accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if _arranging and event.is_action_pressed("ui_cancel"):
		finish()
		get_viewport().set_input_as_handled()


func _frame_at(point: Vector2) -> String:
	var found := ""
	var frames := frames()
	for id: String in frames:
		if (frames[id] as Rect2).has_point(point):
			found = id
	return found


func _grab(point: Vector2) -> void:
	_dragging = _frame_at(point)
	if _dragging == "":
		return
	_grabbed_at = point
	_grabbed_rect = frames()[_dragging]
	var handle := float(rules().get("handle", 14))
	_resizing = _sized(_dragging) and point.distance_to(_grabbed_rect.end) <= handle * 1.5


func _let_go() -> void:
	_dragging = ""
	_resizing = false


## Move [param id] (or, with [param resizing], size it) by [param moved] from where it was grabbed,
## and keep it.
func drag(id: String, moved: Vector2, resizing: bool = false) -> void:
	var screen := get_viewport().get_visible_rect().size
	var laid := saved_all()
	var entry: Dictionary = laid.get(id, {}).duplicate()
	var rect: Rect2 = _grabbed_rect if _dragging == id else frames()[id]
	var grown := float(entry.get("scale", _held[id].scale.x if _held.has(id) else 1.0))
	if resizing and _held.has(id):
		var least: Array = rules().get("least", [120, 24])
		var extent: Vector2 = (rect.size + moved) / grown
		entry["w"] = maxf(float(least[0]), extent.x)
		entry["h"] = maxf(float(least[1]), extent.y)
		entry["x"] = rect.position.x / screen.x
		entry["y"] = rect.position.y / screen.y
	elif id == WORDS:
		var bottom_middle := Vector2(rect.position.x + rect.size.x / 2.0, rect.end.y) + moved
		entry["x"] = clampf(bottom_middle.x / screen.x, 0.0, 1.0)
		entry["y"] = clampf(bottom_middle.y / screen.y, 0.1, 1.0)
	else:
		var at := _kept_on(rect.position + moved, rect.size, screen)
		entry["x"] = at.x / screen.x
		entry["y"] = at.y / screen.y
	if not entry.has("w") and _held.has(id) and _sized(id):
		entry["w"] = _held[id].size.x
		entry["h"] = _held[id].size.y
	entry["scale"] = grown
	laid[id] = entry
	keep(laid)
	if _held.has(id):
		_lay(id)
	EventBus.screen_arranged.emit()
	queue_redraw()


## Make [param id] and its words bigger (or smaller, below nothing) by [param by].
func grow(id: String, by: float) -> void:
	var rect: Rect2 = frames()[id]
	var screen := get_viewport().get_visible_rect().size
	var laid := saved_all()
	var entry: Dictionary = laid.get(id, {}).duplicate()
	var was := float(entry.get("scale", 1.0))
	entry["scale"] = clampf(snappedf(was + by, 0.05), float(rules().get("least_scale", 0.6)), float(rules().get("most_scale", 2.0)))
	if not entry.has("x"):
		if id == WORDS:
			entry["x"] = (rect.position.x + rect.size.x / 2.0) / screen.x
			entry["y"] = rect.end.y / screen.y
		else:
			entry["x"] = rect.position.x / screen.x
			entry["y"] = rect.position.y / screen.y
	if not entry.has("w") and _held.has(id) and _sized(id):
		entry["w"] = _held[id].size.x
		entry["h"] = _held[id].size.y
	laid[id] = entry
	keep(laid)
	if _held.has(id):
		_lay(id)
	EventBus.screen_arranged.emit()
	queue_redraw()


func _draw() -> void:
	if not _arranging:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.25))
	var font := get_theme_default_font()
	var gold := Color(0.965, 0.827, 0.443)
	var handle := float(rules().get("handle", 14))
	var frames := frames()
	for id: String in frames:
		var rect: Rect2 = frames[id]
		var lit := id == _dragging
		draw_rect(rect, Color(gold, 0.18 if lit else 0.08))
		draw_rect(rect, Color(gold, 0.95 if lit else 0.6), false, 2.0)
		draw_string(font, rect.position + Vector2(4.0, 14.0), _label(id), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, gold)
		if _sized(id):
			draw_rect(Rect2(rect.end - Vector2.ONE * handle, Vector2.ONE * handle), Color(gold, 0.9))


func _make_bar() -> PanelContainer:
	var bar := PanelContainer.new()
	bar.name = "ArrangeBar"
	var face := StyleBoxFlat.new()
	face.bg_color = Color(0.05, 0.05, 0.08, 0.9)
	face.border_color = Color(0.965, 0.827, 0.443, 0.6)
	face.set_border_width_all(1)
	face.set_corner_radius_all(6)
	face.set_content_margin_all(10)
	bar.add_theme_stylebox_override("panel", face)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)
	var words := Label.new()
	words.text = str(rules().get("bar", "Drag a panel to move it; its corner to size it; the wheel over it to grow its words."))
	words.add_theme_font_size_override("font_size", 13)
	row.add_child(words)
	var back := Button.new()
	back.name = "PutBack"
	back.text = str(rules().get("reset", "Put It All Back"))
	back.pressed.connect(put_back)
	row.add_child(back)
	var done := Button.new()
	done.name = "Done"
	done.text = str(rules().get("done", "Done"))
	done.pressed.connect(finish)
	row.add_child(done)
	return bar
