extends Control
## The map of the continent drawn over the ground ([D232]): small in a corner of the screen while
## walking, or large when opened with M or from the journal. Either way the party keeps walking
## under it.
##
## `doug-md`, play-test 3: "a small square map in the corner with north, east, south and west on its
## sides"; play-test 4: "when I open my map I can click on where I want to go on the map. Right-click
## it, and the option will come up, go to location or waypoint marker", "you should be able to take
## out your map and your characters don't stop there; they keep walking", "the compass system should
## be incorporated on top of the map also. It's at waypoints. And you click to go there."
##
## What it shows: the ground the company has seen (black where it never has, dimmed where only a map
## it carries drew it in), the places it knows, open gates ringed red, bands in sight, the party,
## the markers ([code]src/world/markers.gd[/code]) and the thing being followed, with a line to it.
## The corner map keeps the party in the middle and points at the followed thing from its edge when
## it is off the map, like the compass's needle.
##
## Clicks: on a marker, go there; right-click anywhere, "Go here" / "Place a marker" / "Take the
## marker off". On the corner map a left click anywhere else opens the large map; on the large map
## dragging moves it and the wheel zooms.
##
## Loaded by path, not by `class_name` ([D41]).

## Something worth a line in the log ("Marker 2 placed on the map.").
signal said(line: String)
## The corner map was clicked somewhere with nothing on it: open the large map.
signal open_requested

const Markers := preload("res://src/world/markers.gd")
const AutoRoad := preload("res://src/world/auto_road.gd")
const Biome := preload("res://src/chronicle/biome.gd")
const Atlas := preload("res://src/chronicle/atlas.gd")
const Dispatch := preload("res://src/chronicle/dispatch.gd")

const UNKNOWN := Color(0.035, 0.035, 0.05)
const FRAME := Color(0.98, 0.86, 0.52, 0.9)
const BACKING := Color(0.04, 0.04, 0.06, 0.82)
const PARTY := Color(0.98, 0.95, 0.85)
## Somebody of the company's out on a mission ([D300]).
const SENT := Color(0.55, 0.8, 0.98)
const GOAL := Color(1.0, 0.82, 0.3)
const MARKER := Color(0.98, 0.78, 0.25)
const GOING := Color(0.45, 0.9, 0.55)
const GATE_RING := Color(0.95, 0.35, 0.3, 0.95)
const BAND := Color(0.85, 0.22, 0.2)
const LETTERS := Color(0.95, 0.93, 0.88)
## How dark ground drawn from somebody else's map is left (as on the old map, [D50]).
const CHARTED := 0.45
## Pixels a cell is drawn at, at most and at least, on the large map.
const ZOOM_MOST := 30.0
const ZOOM_LEAST := 5.0
## A click this close to a marker's pin is a click on the marker.
const PIN_REACH := 12.0
## How far a press may move before it is a drag, not a click.
const DRAG_START := 6.0

const MENU_GO := 0
const MENU_MARK := 1
const MENU_UNMARK := 2

## The large map (dragged, zoomed, names on places) or the corner one.
var full := false
## Pixels a cell is drawn at.
var cell_px := 12.0
## The cell in the middle of the view; the corner map keeps it on the party.
var centre := Vector2.ZERO
var follow_party := true

var _art: Dictionary = {}
var _menu: PopupMenu
var _menu_cell := Vector2i(-1, -1)
var _pressed_at := Vector2.INF
var _dragging := false
var _drawn := ""
var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_font = ThemeDB.fallback_font
	_menu = PopupMenu.new()
	_menu.id_pressed.connect(_on_menu)
	add_child(_menu)
	recentre()


## Back over the party.
func recentre() -> void:
	var world: World = GameState.world
	if world != null:
		centre = Vector2(world.player_cell) + Vector2(0.5, 0.5)
	follow_party = true
	queue_redraw()


## Move the large map by [param cells].
func pan(cells: Vector2) -> void:
	if cells == Vector2.ZERO:
		return
	follow_party = false
	var world: World = GameState.world
	centre += cells
	if world != null:
		centre = centre.clamp(Vector2.ZERO, Vector2(world.size))
	queue_redraw()


## Zoom in ([param steps] above 0) or out, about [param at] (a point in this control).
func zoom(steps: float, at: Vector2 = Vector2.INF) -> void:
	var before := cell_px
	cell_px = clampf(cell_px * pow(1.2, steps), ZOOM_LEAST, ZOOM_MOST)
	if at != Vector2.INF and before != cell_px:
		var offset := (at - size * 0.5)
		centre += offset / before - offset / cell_px
		follow_party = false
	queue_redraw()


## The cell under [param point] (in this control).
func cell_at(point: Vector2) -> Vector2i:
	var where := centre + (point - size * 0.5) / cell_px
	return Vector2i(floori(where.x), floori(where.y))


## Where the middle of [param cell] is drawn.
func point_of(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5) - centre) * cell_px + size * 0.5


func _process(_delta: float) -> void:
	var world: World = GameState.world
	if world == null or not is_visible_in_tree():
		return
	if follow_party:
		centre = Vector2(world.player_cell) + Vector2(0.5, 0.5)
	# Drawn again only when something it shows has changed.
	var now := "%s|%s|%s|%s|%d|%s|%.2f" % [
		world.player_cell, GameState.flags.get(Markers.FLAG, []), GameState.flags.get(Markers.FOLLOWED, ""),
		centre, world.steps, size, cell_px,
	]
	if now != _drawn:
		_drawn = now
		queue_redraw()


# --- clicks ---------------------------------------------------------------------


func _gui_input(event: InputEvent) -> void:
	var world: World = GameState.world
	if world == null:
		return
	var button := event as InputEventMouseButton
	if button != null:
		if button.button_index == MOUSE_BUTTON_WHEEL_UP and button.pressed and full:
			zoom(1.0, button.position)
			accept_event()
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN and button.pressed and full:
			zoom(-1.0, button.position)
			accept_event()
		elif button.button_index == MOUSE_BUTTON_RIGHT and button.pressed:
			accept_event()
			open_menu(cell_at(button.position), button.global_position)
		elif button.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			if button.pressed:
				_pressed_at = button.position
				_dragging = false
			else:
				if not _dragging and _pressed_at != Vector2.INF:
					_click(button.position)
				_pressed_at = Vector2.INF
				_dragging = false
		return
	var motion := event as InputEventMouseMotion
	if motion != null and full and _pressed_at != Vector2.INF:
		if not _dragging and motion.position.distance_to(_pressed_at) > DRAG_START:
			_dragging = true
		if _dragging:
			pan(-motion.relative / cell_px)
			accept_event()


## A left click: on a marker it is "go there"; on the corner map anywhere else it opens the large
## map.
func _click(point: Vector2) -> void:
	var pin := marker_near(point)
	if pin.x >= 0:
		said.emit(Markers.go_to(GameState.world, pin))
		queue_redraw()
		return
	if not full:
		open_requested.emit()


## The marker whose pin is under [param point], or (-1, -1).
func marker_near(point: Vector2) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := PIN_REACH
	for each: Dictionary in Markers.all():
		var d := (_pin_head(each["cell"])).distance_to(point)
		if d < best_d:
			best_d = d
			best = each["cell"]
	return best


## The right-click menu for [param cell], opened at [param screen_point].
func open_menu(cell: Vector2i, screen_point: Vector2) -> void:
	var world: World = GameState.world
	if world == null or not world.in_bounds(cell):
		return
	_menu_cell = cell
	_menu.clear()
	var site := world.site_at(cell)
	if site != null and Atlas.knows(world, site):
		_menu.add_separator(site.display_name)
	_menu.add_item("Go here", MENU_GO)
	if Markers.at(cell).is_empty() or bool(Markers.at(cell)["go"]):
		_menu.add_item("Place a marker", MENU_MARK)
	if not Markers.at(cell).is_empty():
		_menu.add_item("Take the marker off", MENU_UNMARK)
	_menu.reset_size()
	_menu.popup(Rect2i(Vector2i(screen_point), Vector2i.ZERO))


## What the menu would offer on [param cell], for the suites: the item ids in order.
func menu_for(cell: Vector2i) -> Array[int]:
	open_menu(cell, Vector2.ZERO)
	var ids: Array[int] = []
	for i in _menu.item_count:
		if not _menu.is_item_separator(i):
			ids.append(_menu.get_item_id(i))
	_menu.hide()
	return ids


func choose(cell: Vector2i, id: int) -> void:
	_menu_cell = cell
	_on_menu(id)


func _on_menu(id: int) -> void:
	var world: World = GameState.world
	if world == null or _menu_cell.x < 0:
		return
	match id:
		MENU_GO:
			said.emit(Markers.go_to(world, _menu_cell))
		MENU_MARK:
			said.emit(Markers.place(world, _menu_cell))
		MENU_UNMARK:
			Markers.remove(_menu_cell)
			said.emit("The marker is taken off the map.")
	queue_redraw()


# --- drawing --------------------------------------------------------------------


func _draw() -> void:
	var world: World = GameState.world
	draw_rect(Rect2(Vector2.ZERO, size), UNKNOWN)
	if world == null:
		return
	var half := size * 0.5 / cell_px
	var first := Vector2i((centre - half).floor()) - Vector2i.ONE
	var last := Vector2i((centre + half).ceil()) + Vector2i.ONE
	first = first.clamp(Vector2i.ZERO, world.size)
	last = last.clamp(Vector2i.ZERO, world.size)
	_draw_ground(world, first, last)
	_draw_places(world, first, last)
	_draw_bands(world)
	var goal := AutoRoad.objective(world) if not GameState.rehearsing else {}
	_draw_goal(world, goal)
	_draw_markers()
	_draw_sent(world)
	_draw_party(world)
	if not full:
		_draw_frame()


func _draw_ground(world: World, first: Vector2i, last: Vector2i) -> void:
	var cell_size := Vector2.ONE * (cell_px + 0.6)
	for y in range(first.y, last.y):
		for x in range(first.x, last.x):
			var cell := Vector2i(x, y)
			var seen := Atlas.is_explored(world, cell)
			if not seen and not Atlas.is_charted(world, cell):
				continue
			var colour := _land_colour(world, cell)
			if not seen:
				colour = colour.darkened(1.0 - CHARTED)
			draw_rect(Rect2(point_of(cell) - Vector2.ONE * cell_px * 0.5, cell_size), colour)


## The terrain's colour washed with its land's, as the old map drew it, so snow and blight read
## before they are walked into; and a fixed wobble a cell, so grass is not one flat green.
func _land_colour(world: World, cell: Vector2i) -> Color:
	var base := Color(world.terrain_at(cell).get("color", "#4f7d3f"))
	var land := Biome.at(world, cell)
	if land != Biome.GRASSLAND and land != Biome.FOREST:
		base = base.lerp(Biome.tint(land) * Color(0.8, 0.8, 0.8), 0.55)
	var lift := 0.92 + float(absi(hash(cell)) % 1000) / 1000.0 * 0.16
	return Color(base.r * lift, base.g * lift, base.b * lift)


func _draw_places(world: World, first: Vector2i, last: Vector2i) -> void:
	var view := Rect2i(first, last - first)
	var names := full and cell_px >= 13.0
	for site: Site in world.sites:
		if not view.has_point(site.cell) or not Atlas.knows(world, site):
			continue
		var at := point_of(site.cell)
		var art := _site_art(site) if cell_px >= 9.0 else null
		if art != null:
			var tall := cell_px * (2.1 if full else 1.8)
			var foot := at + Vector2(0, cell_px * 0.45)
			draw_texture_rect(art, Rect2(foot - Vector2(tall * 0.5, tall * 0.88), Vector2(tall, tall)), false,
				Color(0.55, 0.55, 0.6) if site.kind == Site.GATE and site.cleared else Color.WHITE)
		else:
			var dot := maxf(2.5, cell_px * (0.42 if site.kind != Site.TOWER else 0.6))
			draw_circle(at, dot + 1.0, Color(0.05, 0.05, 0.06))
			draw_circle(at, dot, Site.COLOURS.get(site.kind, Color.WHITE))
		if site.kind == Site.GATE and site.open and not site.cleared:
			draw_arc(at, maxf(4.0, cell_px * 0.62), 0.0, TAU, 20, GATE_RING, 1.5, true)
		if names:
			_label(site.display_name, at + Vector2(0, -cell_px * 1.75), 11)


func _draw_bands(world: World) -> void:
	for band: Prowler in world.prowlers:
		if not Atlas.is_explored(world, band.cell):
			continue
		var at := point_of(band.cell)
		if not Rect2(Vector2.ZERO, size).has_point(at):
			continue
		draw_circle(at, maxf(2.5, cell_px * 0.28), Color(0.05, 0.03, 0.03))
		draw_circle(at, maxf(2.0, cell_px * 0.22), Faction.banner(band.faction).lerp(BAND, 0.5))


## The thing being followed: ringed, a line drawn to it from the party, and on the corner map a
## needle at the edge when it is off the map (the compass, on the map).
func _draw_goal(world: World, goal: Dictionary) -> void:
	if goal.is_empty():
		return
	var target: Vector2i = goal["cell"]
	var from := point_of(world.player_cell)
	var to := point_of(target)
	var box := Rect2(Vector2.ZERO, size).grow(-10.0)
	if box.has_point(to):
		if target != world.player_cell:
			_dashes(from, to, Color(GOAL, 0.8))
		draw_arc(to, maxf(5.0, cell_px * 0.75), 0.0, TAU, 24, GOAL, 2.0, true)
		return
	var way := (to - from).normalized()
	if way == Vector2.ZERO:
		return
	# Where the line from the party leaves the box: the needle sits there.
	var reach := INF
	for axis in 2:
		if absf(way[axis]) > 0.0001:
			var edge := box.end[axis] if way[axis] > 0.0 else box.position[axis]
			reach = minf(reach, (edge - from[axis]) / way[axis])
	var tip := from + way * reach
	_dashes(from, tip - way * 10.0, Color(GOAL, 0.55))
	var side := Vector2(-way.y, way.x)
	draw_colored_polygon(PackedVector2Array([tip, tip - way * 11.0 + side * 6.0, tip - way * 11.0 - side * 6.0]), GOAL)


func _draw_markers() -> void:
	var placed := 0
	for each: Dictionary in Markers.all():
		var go := bool(each["go"])
		if not go:
			placed += 1
		var cell: Vector2i = each["cell"]
		var foot := point_of(cell)
		var head := _pin_head(cell)
		var colour := GOING if go else MARKER
		draw_colored_polygon(PackedVector2Array([foot, head + Vector2(-4.5, 2.0), head + Vector2(4.5, 2.0)]), colour.darkened(0.25))
		draw_circle(head, 6.0, Color(0.06, 0.05, 0.04))
		draw_circle(head, 5.0, colour)
		if not go:
			_label_plain(str(placed), head + Vector2(-3.0, 4.0), 9, Color(0.1, 0.08, 0.05))


## The company's own people out on missions ([D294], [D300]: "of course" the band sent out is seen):
## a small face where each job is on its road now, with a line to where it is going.
func _draw_sent(world: World) -> void:
	if GameState.roster == null:
		return
	for job: Dictionary in GameState.away:
		var cell := Dispatch.where_now(job, world)
		if cell == Vector2i(-1, -1):
			continue
		var at := point_of(cell)
		if not Rect2(Vector2.ZERO, size).has_point(at):
			continue
		var heading: Variant = job.get("meet", [world.player_cell.x, world.player_cell.y]) \
				if bool(job.get("arrived", false)) else job.get("to")
		if heading is Array and (heading as Array).size() >= 2 and not bool(job.get("waiting", false)):
			_dashes(at, point_of(Vector2i(int(heading[0]), int(heading[1]))), Color(SENT, 0.45))
		var ring := maxf(4.0, cell_px * 0.36)
		draw_circle(at, ring + 1.5, Color(0.08, 0.07, 0.08))
		draw_circle(at, ring, SENT)
		var who := GameState.roster.by_id(str(job.get("id", "")))
		var face: Texture2D = Database.unit_face(who.template_id) if who != null else null
		if face != null:
			var tall := ring * 2.4
			draw_texture_rect(face, Rect2(at - Vector2(tall * 0.5, tall * 0.7), Vector2(tall, tall)), false)


func _pin_head(cell: Vector2i) -> Vector2:
	return point_of(cell) + Vector2(0, -11.0)


func _draw_party(world: World) -> void:
	var at := point_of(world.player_cell)
	var ring := maxf(6.0, cell_px * 0.5)
	draw_circle(at, ring + 1.5, Color(0.08, 0.07, 0.08))
	draw_circle(at, ring, PARTY)
	var lead := GameState.roster.player() if GameState.roster != null else null
	var face: Texture2D = Database.unit_face(lead.template_id) if lead != null else null
	if face != null:
		var tall := ring * 2.4
		draw_texture_rect(face, Rect2(at - Vector2(tall * 0.5, tall * 0.7), Vector2(tall, tall)), false)


## The corner map's frame, with north, east, south and west on its four sides.
func _draw_frame() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FRAME, false, 2.0)
	var mid := size * 0.5
	for each: Array in [["N", Vector2(mid.x, 9.0)], ["S", Vector2(mid.x, size.y - 9.0)],
			["W", Vector2(9.0, mid.y)], ["E", Vector2(size.x - 9.0, mid.y)]]:
		var at: Vector2 = each[1]
		draw_circle(at, 8.0, BACKING)
		_label_plain(str(each[0]), at + Vector2(-4.0, 4.5), 12, LETTERS)


func _dashes(from: Vector2, to: Vector2, colour: Color) -> void:
	var length := from.distance_to(to)
	if length < 1.0:
		return
	var way := (to - from) / length
	var at := 0.0
	while at < length:
		draw_line(from + way * at, from + way * minf(at + 5.0, length), colour, 1.5, true)
		at += 9.0


func _label(text: String, centre_top: Vector2, font_size: int) -> void:
	var span := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var box := Rect2(centre_top.x - span.x * 0.5 - 4.0, centre_top.y - span.y + 2.0, span.x + 8.0, span.y + 2.0)
	draw_rect(box, Color(0.06, 0.07, 0.09, 0.82))
	draw_string(_font, Vector2(box.position.x + 4.0, centre_top.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.96, 0.94, 0.88))


func _label_plain(text: String, at: Vector2, font_size: int, colour: Color) -> void:
	draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)


## The picture a place is drawn with on the map, as the old map chose it ([D50]).
func _site_art(site: Site) -> Texture2D:
	var path := ""
	if site.kind == Site.GATE:
		path = Site.GATE_ART[absi(site.cell.x * 31 + site.cell.y * 17) % Site.GATE_ART.size()]
	elif site.kind == Site.KEEP:
		path = Faction.hold_art(str(site.data.get("faction", "")))
	elif bool(site.data.get("city", false)):
		path = Site.CITY_ART
	elif site.kind == Site.WILD:
		# A hamlet or a caravan is drawn as one, not as a standing stone (D333).
		path = str(Database.area(str(site.data.get("area", ""))).get("map_art", ""))
	if path == "":
		path = str(Site.ART.get(site.kind, ""))
	if path == "":
		return null
	if not _art.has(path):
		_art[path] = load(path) if ResourceLoader.exists(path) else null
	return _art[path]
