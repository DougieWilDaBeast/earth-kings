extends Node2D
## A band met on the ground ([D66]): where it stands in this area, who is in it, and every cell it
## can see, painted on the ground as a grid in its colours. Walk into one of those cells and it has
## seen you — the area starts the fight there ([method AreaScene._seen_by]).
##
## The world says which bands are here (`bands` in the area's payload): one camped on this tile
## stands in the open, away from where the party came in; one on the next tile whose eyes reach
## this one stands just inside the edge it watches from. Sight is the ground's own: a cell within
## `sight_base + sight_per_reach × reach` of the band, with nothing that blocks a view between
## (a tree, a house, a rock face; water does not), and not in cover (long grass, a bush).
##
## A band patrols: a small loop of stops round where it stands, a cell at a time, resting at each,
## its watched cells moving with it. The loop never brings where the party came in into sight. When
## it moves it says so ([signal moved]), and the area looks to see whether the party is now seen.
##
## On the land ([D84]) a band keeps to the tile it is on (its [member region]): it stands and
## patrols there, further afield than on a single ground, and when the continent moves it to the
## next tile it walks there across the land ([method travel]) and takes up a patrol round its new
## spot.
##
## The watch draws itself under the people (it is a child of the area's ground layers) and makes the
## band's figures for the area to stand among everyone else. Loaded by path ([D41]).

## The band has moved to another cell, and what it can see has changed with it.
signal moved

## The watched cells: a red wash that breathes, a grid over each, and a hard line round the edge of
## all of them in the band's own colours, strong enough to read under any place's light.
const Remembered := preload("res://src/chronicle/remembered.gd")

const DANGER := Color("#ff3b2f")
const WASH := 0.26
const BREATH := 0.08
const GRID := 0.35
const RIM := 0.95
const RIM_WIDTH := 3.0
## How close the party has to come before the band turns to look at it, in cells beyond its sight.
const NOTICE := 3.0
## The most of a band drawn on the ground; a bigger one is still fought in full.
const MOST_SHOWN := 6

## What the world said about the band: `cell`, `pack`, `faction`, `label`, `reach`, `where`.
var band: Dictionary = {}
## Where the band stands, and where each of its figures does (the first is the anchor).
var anchor: Vector2i = Vector2i.ZERO
var members: Array[Vector2i] = []
## Cell -> true, for every cell the band can see.
var watched: Dictionary = {}
var colour: Color = Color(0.85, 0.2, 0.2)
var sight: float = 4.0
## The figures, once made, in the order of [member members].
var figures: Array = []

## Whether the band may walk just now: the area says no while somebody is talking, a menu is open,
## or the party is on its way out.
var can_move: Callable = Callable()
## The cells the band keeps to: its tile, on the land; all of the ground, anywhere else.
var region: Rect2i = Rect2i()
## On its way to another tile, rather than patrolling.
var travelling: bool = false

var _map: AreaMap
var _clock: float = 0.0
## The patrol: its stops (the first is where it started), which it is walking to, the way there in
## pixels, and how long it rests before setting off again.
var _loop: Array[Vector2i] = []
var _stop: int = 0
var _way: Array[Vector2] = []
var _rest: float = 0.0
var _rng := RandomNumberGenerator.new()
## Where the one in front is, and the ground it has walked, for the rest to follow along.
var _lead_at: Vector2 = Vector2.ZERO
var _trail: Array[Vector2] = []
var _alert: bool = false


## `data/world_rules.json` → `ground_watch`.
static func rule(key: String, fallback: Variant) -> Variant:
	return Database.world_rules.get("ground_watch", {}).get(key, fallback)


## The band on this ground, or null when there is nowhere for it to stand. [param arrived] is where
## the party came in; [param taken] the cells somebody or something already has, which grows;
## [param land_sight] what the land adds to (or takes from) every band's sight.
static func place(map: AreaMap, band_: Dictionary, arrived: Vector2i, taken: Dictionary, land_sight: float = 0.0,
		keep_to: Rect2i = Rect2i()) -> Node2D:
	var watch: Node2D = (load("res://src/area/area_watch.gd") as GDScript).new()
	watch.name = "Watch"
	watch._map = map
	watch.region = keep_to if keep_to.size != Vector2i.ZERO else map.bounds()
	watch.band = _as_told(band_)
	watch.colour = Color(str(watch.band.get("banner", "#c0392b")))
	# The land has its say too (`sight` in its effects, D71): mist and jungle close a band's eyes in.
	watch.sight = maxf(1.0, float(rule("sight_base", 2)) + float(rule("sight_per_reach", 1.5)) * float(watch.band.get("reach", 2)) + land_sight)
	# A faction that has lost enough bands to the company looks for it (D249).
	watch.sight += Remembered.grudge_sight(GameState.world, watch.band.get("pack", []))
	var at: Vector2i = watch._where_to_stand(arrived, taken)
	if at.x < 0:
		watch.free()
		return null
	watch.anchor = at
	watch._gather(taken)
	watch._plan_the_patrol(arrived)
	watch._refresh_sight()
	return watch


## The world's word on a band (`key`, `pack`, `sight` or `reach`, `faction`, `label`, `from`) in the
## shape the watch keeps: `reach`, `banner` (the faction's colour) and `where` (`"here"`, or the
## [dx, dy] way to the tile it watches from).
static func _as_told(told: Dictionary) -> Dictionary:
	var out := told.duplicate(true)
	if not out.has("reach"):
		out["reach"] = int(told.get("sight", 2))
	if not out.has("banner"):
		out["banner"] = Faction.banner(str(told.get("faction", ""))).to_html(false)
	if not out.has("where"):
		var from: Array = told.get("from", [0, 0])
		var side := Vector2i(int(from[0]), int(from[1])) if from.size() >= 2 else Vector2i.ZERO
		out["where"] = "here" if side == Vector2i.ZERO else [side.x, side.y]
	if not out.has("cell"):
		out["cell"] = [str(told.get("key", ""))]
	return out


## Whether [param cell] hides whoever is in it: ground that is cover (`cover` on its terrain in
## `tilesets.json`, or named in `ground_watch.cover`), or a bush that can be walked through.
func in_cover(cell: Vector2i) -> bool:
	var terrain := _map.terrain_at(cell)
	if terrain in (rule("cover", ["meadow"]) as Array):
		return true
	if bool(Database.area_terrain(terrain).get("cover", false)):
		return true
	return _bush_on(cell)


## The band's figures, to stand in the area. The first carries the band's name over its head.
func make_figures(facing_towards: Vector2) -> Array:
	figures.clear()
	# Only those with a picture are drawn on the ground; the fight has everyone, drawn or not.
	var pack: Array = (band.get("pack", []) as Array).filter(
		func(id: Variant) -> bool: return Database.unit_face(str(id)) != null)
	for i in members.size():
		var unit_id := str(pack[i % pack.size()]) if not pack.is_empty() else ""
		var figure := AreaActor.for_person({ "name": str(band.get("label", "a band")), "unit": unit_id })
		figure.position = _map.centre_of(members[i])
		figure.face(facing_towards - figure.position)
		figure.set_interactive(false)
		if i == 0:
			var name_tag := Label.new()
			name_tag.text = str(band.get("label", ""))
			name_tag.add_theme_color_override("font_color", colour.lightened(0.35))
			name_tag.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
			name_tag.add_theme_constant_override("outline_size", 6)
			name_tag.add_theme_font_size_override("font_size", 15)
			name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_tag.size = Vector2(240, 22)
			name_tag.position = Vector2(-120, -AreaActor.FOOT_OFFSET * figure.body_scale - 26)
			figure.add_child(name_tag)
		figures.append(figure)
	if not figures.is_empty():
		_lead_at = figures[0].position
	return figures


## Every figure turns to the party once it is close enough to be worth a look (resting, not walking).
func keep_an_eye_on(point: Vector2) -> void:
	if not _way.is_empty():
		return
	var near := (sight + NOTICE) * AreaMap.CELL
	for figure: Node2D in figures:
		if figure.position.distance_to(point) <= near:
			figure.face(point - figure.position)


## They have seen the party: every head turns, and the one in front shouts.
func raise_the_alarm(point: Vector2, ambushed: bool = false) -> void:
	_alert = true
	_way.clear()
	for figure: Node2D in figures:
		figure.face(point - figure.position)
	# Out of cover and on them before they know it: nobody has time to shout.
	if not figures.is_empty() and not ambushed:
		figures[0].say(Remembered.shout(GameState.world, band.get("pack", []), randi()))
	_clock = 0.0
	modulate = Color(1.4, 1.1, 1.1)


## The cells a band standing on [param from] can see.
func sees_from(from: Vector2i) -> Dictionary:
	var out := {}
	var span := ceili(sight)
	for dy in range(-span, span + 1):
		for dx in range(-span, span + 1):
			var cell := from + Vector2i(dx, dy)
			if Vector2(dx, dy).length() > sight + 0.35:
				continue
			if not _map.in_bounds(cell) or not _map.is_walkable(cell):
				continue
			if cell != from and in_cover(cell):
				continue
			if not _clear_line(from, cell):
				continue
			out[cell] = true
	return out


func _process(delta: float) -> void:
	_clock += delta
	modulate = modulate.lerp(Color.WHITE, minf(1.0, delta * 2.0))
	queue_redraw()
	if (_loop.size() >= 2 or travelling) and not _alert and not figures.is_empty() \
			and (not can_move.is_valid() or bool(can_move.call())):
		_patrol(delta)


## A step of the patrol: rest, or set off for the next stop, or walk on towards it.
func _patrol(delta: float) -> void:
	if _rest > 0.0:
		_rest -= delta
		return
	if _way.is_empty() and travelling:
		travelling = false
		_plan_the_patrol(_map.cell_at(_lead_at) + Vector2i(999, 999))
		_rest = _pause()
		return
	if _way.is_empty():
		_stop = (_stop + 1) % _loop.size()
		_way = _map.find_cell_path(anchor, _loop[_stop])
		if not _way.is_empty():
			_way.remove_at(0)
		if _way.is_empty():
			_rest = _pause()
			return
	var speed := float(AreaMap.CELL) / maxf(0.1, float(rule("travel_step_seconds" if travelling else "patrol_step_seconds", 0.85)))
	var before := _lead_at
	_lead_at = _lead_at.move_toward(_way[0], speed * delta)
	if _trail.is_empty() or _trail[-1].distance_to(_lead_at) >= 6.0:
		_trail.append(_lead_at)
		if _trail.size() > 200:
			_trail = _trail.slice(_trail.size() - 200)
	_walk_the_figures(_lead_at - before, speed * delta)
	if _lead_at.is_equal_approx(_way[0]):
		_way.remove_at(0)
		var cell := _map.cell_at(_lead_at)
		if cell != anchor:
			anchor = cell
			_refresh_sight()
			moved.emit()
		if _way.is_empty():
			_rest = _pause()


## The continent has moved the band to another tile ([D84]): it sets off across the land for a spot
## in [param to] (away from [param party], whom it has not seen), and patrols there once it arrives.
func travel(to: Rect2i, party: Vector2i) -> void:
	if _alert or figures.is_empty():
		return
	region = to
	var spot := _where_to_stand(party, {})
	if spot.x < 0 and spot.y < 0:
		return
	var way := _map.find_cell_path(_map.cell_at(_lead_at), spot)
	if way.is_empty():
		return
	way.remove_at(0)
	_way = way
	_rest = 0.0
	travelling = true


## The one in front where the patrol has got to; the others along the ground it walked, a little
## under a cell apart, each facing the way it goes.
func _walk_the_figures(step: Vector2, most: float) -> void:
	figures[0].position = _lead_at
	if step.length_squared() > 0.01:
		figures[0].face(step)
	var gap := int(AreaMap.CELL * 0.8 / 6.0)
	for i in range(1, figures.size()):
		var back := _trail.size() - 1 - i * gap
		if back < 0:
			continue
		var figure: Node2D = figures[i]
		var was := figure.position
		figure.position = figure.position.move_toward(_trail[back], most * 1.2)
		if figure.position.distance_squared_to(was) > 0.01:
			figure.face(figure.position - was)


func _pause() -> float:
	var span: Variant = rule("patrol_pause", [1.5, 3.5])
	if span is Array and (span as Array).size() >= 2:
		return _rng.randf_range(float(span[0]), float(span[1]))
	return 2.0


## The loop: up to `patrol_points` stops within `patrol_reach` of where the band stands, each
## reachable, none on the way to which (or at which) the band could see where the party came in.
## Taken in order round the band, so it walks a loop. The same ground, the same band, the same loop.
func _plan_the_patrol(arrived: Vector2i) -> void:
	_loop = [anchor]
	_rng.seed = hash(str(band.get("cell", [])) + _map.id + str(anchor) + "patrol")
	var roomy := region != _map.bounds()
	var reach := int(rule("land_patrol_reach" if roomy else "patrol_reach", 3))
	var wanted := int(rule("land_patrol_points" if roomy else "patrol_points", 3))
	var clear := sight + 1.0
	var side := Vector2i.ZERO
	var where: Variant = band.get("where", "here")
	if where is Array and (where as Array).size() >= 2:
		side = Vector2i(int(where[0]), int(where[1]))
	var choices: Array[Vector2i] = []
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var cell := anchor + Vector2i(dx, dy)
			if cell == anchor or maxi(absi(dx), absi(dy)) < 2:
				continue
			if not region.has_point(cell) or not _map.is_walkable(cell) or _map.is_exit(cell) or _on_the_rim(cell):
				continue
			if not _map.building_at(cell).is_empty():
				continue
			if side != Vector2i.ZERO and not _by_the_edge(cell, side):
				continue
			if Vector2(cell - arrived).length() < clear:
				continue
			choices.append(cell)
	# Shuffled by the band's own dice, then the first few that a safe way leads to.
	for i in range(choices.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap := choices[i]
		choices[i] = choices[j]
		choices[j] = swap
	var stops: Array[Vector2i] = []
	for cell: Vector2i in choices:
		if stops.size() >= wanted:
			break
		var way := _map.find_cell_path(anchor, cell)
		if way.is_empty():
			continue
		var safe := true
		for point: Vector2 in way:
			if Vector2(_map.cell_at(point) - arrived).length() < clear:
				safe = false
				break
		if safe:
			stops.append(cell)
	var centre := Vector2(anchor)
	stops.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (Vector2(a) - centre).angle() < (Vector2(b) - centre).angle())
	_loop.append_array(stops)
	_rest = _pause()


## What the band can see from where it now stands, and the cells its figures are on.
func _refresh_sight() -> void:
	watched = sees_from(anchor)
	if not figures.is_empty():
		members.clear()
		for figure: Node2D in figures:
			members.append(_map.cell_at(figure.position))
	# Where they stand is in plain view of them, long grass or not.
	for cell: Vector2i in members:
		watched[cell] = true


func _draw() -> void:
	var wash := Color(DANGER, WASH + BREATH * sin(_clock * 2.4))
	var grid := Color(DANGER.lightened(0.35), GRID)
	var rim := Color(DANGER.lerp(colour, 0.25).lightened(0.1), RIM)
	var size := float(AreaMap.CELL)
	for cell: Vector2i in watched:
		var corner := Vector2(cell) * size
		var rect := Rect2(corner, Vector2.ONE * size)
		draw_rect(rect, wash)
		draw_rect(rect.grow(-1.0), grid, false, 1.0)
		# The edge of what they can see, where a cell they watch meets one they do not.
		if not watched.has(cell + Vector2i.UP):
			draw_line(corner, corner + Vector2(size, 0), rim, RIM_WIDTH)
		if not watched.has(cell + Vector2i.DOWN):
			draw_line(corner + Vector2(0, size), corner + Vector2(size, size), rim, RIM_WIDTH)
		if not watched.has(cell + Vector2i.LEFT):
			draw_line(corner, corner + Vector2(0, size), rim, RIM_WIDTH)
		if not watched.has(cell + Vector2i.RIGHT):
			draw_line(corner + Vector2(size, 0), corner + Vector2(size, size), rim, RIM_WIDTH)


## Nothing between [param from] and [param to] that blocks a view: a tree, a house, a rock face.
func _clear_line(from: Vector2i, to: Vector2i) -> bool:
	var span := maxi(absi(to.x - from.x), absi(to.y - from.y))
	for i in range(1, span):
		var point := Vector2i(Vector2(from).lerp(Vector2(to), float(i) / float(span)).round())
		if point != from and point != to and _blocks_sight(point):
			return false
	return true


func _blocks_sight(cell: Vector2i) -> bool:
	if _map.is_walkable(cell):
		return false
	# Open water (and every land's own liquid: bog, slime, lava) stops a walker, not a look.
	var terrain := _map.terrain_at(cell)
	return terrain != "water" and not terrain.ends_with("_liquid")


## A bush or a hedge the party can walk through: cover.
func _bush_on(cell: Vector2i) -> bool:
	for prop: Dictionary in _map.props_at(cell):
		if str(Database.prop_size(str(prop.get("art", ""))).get("kind", "")) == "bush" \
				and not AreaProp.is_solid(prop):
			return true
	return false


## Where the band stands: camped on this tile, in the open well away from where the party came in;
## watching from the next tile, just inside the edge it looks over. The same ground and the same
## band always choose the same spot.
func _where_to_stand(arrived: Vector2i, taken: Dictionary) -> Vector2i:
	var far := sight + float(rule("keep_away", 3))
	var where: Variant = band.get("where", "here")
	var side := Vector2i.ZERO
	if where is Array and (where as Array).size() >= 2:
		side = Vector2i(int(where[0]), int(where[1]))
	var middle := Vector2(region.position) + Vector2(region.size - Vector2i.ONE) * 0.5
	var aim := middle + Vector2(side) * (Vector2(region.size - Vector2i.ONE) * 0.5 - Vector2(2, 2))
	# A band an area places itself (a practice band) may name the spot it would rather stand on.
	var wanted: Variant = band.get("at", [])
	if wanted is Array and (wanted as Array).size() >= 2:
		aim = Vector2(float(wanted[0]), float(wanted[1]))
		# Its own spot matters more than distance: it only has to not be looking at the party already.
		far = sight + 1.0
	var key := str(band.get("cell", [])) + _map.id
	var choices: Array = []
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var cell := Vector2i(x, y)
			if taken.has(cell) or not _map.is_walkable(cell) or _map.is_exit(cell) or _on_the_rim(cell):
				continue
			if not _map.building_at(cell).is_empty():
				continue
			if side != Vector2i.ZERO and not _by_the_edge(cell, side):
				continue
			choices.append(cell)
	if choices.is_empty():
		return Vector2i(-1, -1)
	var best := Vector2i(-1, -1)
	var best_score := INF
	for cell: Vector2i in choices:
		var away := Vector2(cell - arrived).length()
		var score := Vector2(cell).distance_to(aim) + float(absi(hash(key + str(cell))) % 100) / 25.0
		# Too close to where the party came in counts against it more than anything else.
		if away < far:
			score += 1000.0 - away
		if _map.terrain_at(cell) in ["dirt", "stone", "flagstone", "street_paving", "yard_paving"]:
			score += 2.0
		if score < best_score:
			best_score = score
			best = cell
	return best


## The outermost ring of the ground, where walking on means walking off: nobody camps there. The
## land has no such ring.
func _on_the_rim(cell: Vector2i) -> bool:
	var whole := _map.bounds()
	if region != whole:
		return false
	return cell.x <= whole.position.x or cell.y <= whole.position.y or cell.x >= whole.end.x - 1 or cell.y >= whole.end.y - 1


func _by_the_edge(cell: Vector2i, side: Vector2i) -> bool:
	var ok := true
	if side.x < 0:
		ok = ok and cell.x <= region.position.x + 3
	elif side.x > 0:
		ok = ok and cell.x >= region.end.x - 4
	if side.y < 0:
		ok = ok and cell.y <= region.position.y + 3
	elif side.y > 0:
		ok = ok and cell.y >= region.end.y - 4
	return ok


## The band's other figures, on open cells round the anchor.
func _gather(taken: Dictionary) -> void:
	members = [anchor]
	taken[anchor] = true
	var wanted := mini(MOST_SHOWN, maxi(1, (band.get("pack", []) as Array).size()))
	for radius in range(1, 4):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if members.size() >= wanted:
					return
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var cell := anchor + Vector2i(dx, dy)
				if taken.has(cell) or not _map.in_bounds(cell) or not _map.is_walkable(cell) or _map.is_exit(cell):
					continue
				if not _map.building_at(cell).is_empty():
					continue
				members.append(cell)
				taken[cell] = true
