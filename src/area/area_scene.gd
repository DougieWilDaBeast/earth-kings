extends Node2D
## Area mode: a place drawn from tilesets, seen from above, with the party
## walking around inside it.
##
## The leader answers the movement keys; everyone else walks the ground the
## leader has already covered. Leaving by the road hands play back to whatever
## scene sent us here.
##
## This is where the game is played ([D50], [D61]). Walking off the edge of the
## ground hands the step to the continent, which does everything a step does
## out of sight and hands back the next ground. A place's own doings (hire, buy,
## the board, a ransom) are sent the same way and come straight back here.

const Guild := preload("res://src/chronicle/guild.gd")
const Wanderers := preload("res://src/chronicle/wanderers.gd")
const Siblings := preload("res://src/chronicle/siblings.gd")
const Atlas := preload("res://src/chronicle/atlas.gd")
const Talk := preload("res://src/dialogue/talk.gd")
const GroundPainter := preload("res://src/area/ground_painter.gd")
const AreaWatch := preload("res://src/area/area_watch.gd")
const Biome := preload("res://src/chronicle/biome.gd")

const WALK_SPEED := 190.0
## Breadcrumb trail recording spacing and following parameters.
const CRUMB_SPACING := 6.0
const FOLLOWER_DISTANCE := 24.0
## How close counts as arrived. Without it followers twitch on the spot, and
## re-face themselves off sub-pixel deltas, which reads as the sprite flickering.
const FOLLOW_DEADZONE := 2.0
## How close the leader has to stand before somebody is worth speaking to.
const TALK_RANGE := 110.0
## How close the leader walks before starting on somebody they were clicked at.
const APPROACH_RANGE := 88.0
## How far the party walks between chances of somebody saying something.
const TALK_STRIDE := 700.0
const HINT := "WASD to walk  ·  click anyone or anything marked to speak to it or look at it  ·  Tab to take the lead with someone else  ·  P for the party  ·  doors open as you reach them  ·  follow the road out to leave"

## Set by [Game] before the scene enters the tree.
var boot_payload: Dictionary = {}

@onready var _layers: Node2D = $Layers
@onready var _actors: Node2D = $Actors
@onready var _camera: CameraRig = $Camera2D
@onready var _place: Label = %PlaceLabel
@onready var _hint: Label = %HintLabel
@onready var _log: Label = %LogLabel

var map: AreaMap
var _leader: AreaActor
var _followers: Array[AreaActor] = []
## One actor per entry in `map.people`, in the same order.
var _people: Array[AreaActor] = []
## Everything standing about that is worth stopping to look at.
var _things: Array[AreaProp] = []
## Party member per seated person, by their index in `map.people`.
var _seated: Dictionary = {}
## Whoever is walking, as the roster knows them.
var _leader_character: Character
## Who or what the leader is standing close enough to deal with, or null.
var _nearby: AreaThing = null
## What the mouse is over, and what the leader was told to walk over to.
var _hovered: AreaThing = null
var _approach: AreaThing = null
var _approach_path: Array[Vector2] = []
var _approach_index: int = 0
var _auto_exit_path: Array[Vector2] = []
var _auto_exit_index: int = 0
var _talking: bool = false
## Held while it plays; a director that only exists as a temporary is collected
## the moment it finishes and never hands control back.
var _cutscene: AreaCutscene
var _crumbs: Array[Vector2] = []
## How far the leader has walked since the last time anybody spoke up.
var _walked: float = 0.0
## Held while an exchange is playing over their heads.
var _chatting: bool = false
var _notes: Array[String] = []
var _visited_spots: Dictionary = {}
## cell -> the [AreaProp] drawn for the chest there, so it can be shown opened.
var _chest_props: Dictionary = {}
## cell -> the [AreaProp] drawn for the ward obstacle there.
var _ward_props: Dictionary = {}
## Wards already leaned on and refused, so the refusal is said once.
var _shut_wards: Dictionary = {}
var _return_scene: String = "world"
## What the bottom of the screen falls back to when nobody is near.
var _idle_hint: String = HINT
## What the scene we came from needs to put itself back the way it was.
var _return_payload: Dictionary = {}
var _leaving: bool = false
var _planar_mode: bool = false
## What the continent says can be done where the party stands, for the hint
## line, the keys and the buttons: `{ prompt, label, act, key }`.
var _acts: Array = []
## Whatever was waiting on the tile above, carried there and back unchanged.
var _held: Dictionary = {}
## The buttons for [member _acts], for a thumb or a pad. Built in code.
var _act_bar: HFlowContainer = null
## What the land does to whoever walks this ground (see [method Biome.effects]);
## the neutral one for a place that is not open country.
var _land: Dictionary = {}
## How far the party has walked since the land last had its say.
var _weathered: float = 0.0
## Party members the land has already been said to be wearing down, so it is
## said once a ground.
var _told_of: Dictionary = {}
## Bands standing on this ground: `{ data, actors, watch, at }`, where `watch`
## Bands standing on this ground, and the ground they watch ([AreaWatch], D66, D68).
var _watches: Array = []
## The cell the leader last stood on, so a step into a watched cell is a step, not where they
## were put down; (-99, -99) until they have been anywhere.
var _last_cell: Vector2i = Vector2i(-99, -99)
## Seen, and on the way to the fight.
var _spotted: bool = false


func _ready() -> void:
	_return_scene = boot_payload.get("return_scene", "world")
	_return_payload = boot_payload.get("return_payload", {})
	_planar_mode = bool(boot_payload.get("planar_mode", false))
	_acts = boot_payload.get("actions", [])
	_held = boot_payload.get("held", {})
	map = AreaMap.load_area(boot_payload.get("area_id", "village"))
	if map == null:
		push_error("Area: no such area '%s'" % boot_payload.get("area_id", ""))
		EventBus.request_scene.emit(_return_scene, _return_payload)
		return

	_land = Biome.effects(str(Database.area(map.id).get("biome", "")))
	EventBus.area_note.connect(_note)
	_paint_layers()
	_light_the_place()
	_spawn_buildings()
	_spawn_props()
	_spawn_party()
	_admit_the_others()
	_admit_the_ghosts()
	_spawn_people()
	_post_the_watch()
	_spawn_fire()
	_camera.frame(map.rect())
	_camera.focus_on(_leader.position, true)
	_place.text = boot_payload.get("title", map.display_name)
	_idle_hint = map.hint if map.hint != "" else HINT
	_hint.text = _prompt_text()
	Pad.changed.connect(_on_pad_changed)
	EventBus.map_requested.connect(_open_the_map)
	_lay_out_acts()
	for line: String in boot_payload.get("notes", []):
		_note(line)
	_open_on(map.opening)


## The cutscene a place plays the moment you walk into it, before you are given
## the keys back.
func _open_on(cutscene_id: String) -> void:
	if cutscene_id == "" or Database.cutscene(cutscene_id).is_empty():
		return
	_talking = true
	_hold_the_town(true)
	var them: AreaActor = _people[0] if not _people.is_empty() else _leader
	_cutscene = AreaCutscene.between(self, _camera, _leader, them)
	await _cutscene.play(cutscene_id)
	_cutscene = null
	_hold_the_town(false)
	_talking = false


# --- building -----------------------------------------------------------------


## One [TileMapLayer] per sheet, bottom first (see [GroundPainter]).
func _paint_layers() -> void:
	GroundPainter.paint(map, _layers)


func _spawn_party() -> void:
	_actors.y_sort_enabled = true
	var start := map.spawn
	if boot_payload.has("spawn_cell"):
		start = AreaMap.to_cell(boot_payload["spawn_cell"])
	if not map.is_walkable(start):
		for radius in range(1, 6):
			var found := false
			for dy in range(-radius, radius + 1):
				for dx in range(-radius, radius + 1):
					var cand := start + Vector2i(dx, dy)
					if map.is_walkable(cand):
						start = cand
						found = true
						break
				if found:
					break
			if found:
				break
	var members := GameState.party_characters()
	for index in members.size():
		if index > 0 and index <= map.seats.size():
			_take_a_seat(members[index], map.seats[index - 1])
			continue
		var actor := AreaActor.for_character(members[index])
		actor.position = map.centre_of(start)
		_actors.add_child(actor)
		if index == 0:
			_leader = actor
			_leader_character = members[index]
		else:
			_followers.append(actor)
	if _leader != null and not _followers.is_empty():
		_reseed_crumbs()
		for i in _followers.size():
			_followers[i].position = _point_along_trail((i + 1) * FOLLOWER_DISTANCE)


## Around a fire nobody trails the leader: they are already sitting down, and
## they are worth walking over to.
func _take_a_seat(character: Character, seat: Vector2i) -> void:
	var facing := map.fire - seat
	_seated[map.people.size()] = character
	map.people.append({
		"name": character.display_name,
		"unit": character.template_id,
		"cell": [seat.x, seat.y],
		"facing": [signi(facing.x), signi(facing.y)],
	})


## Somewhere that is not at noon: the whole canvas is tinted, and only the fire
## pushes back against it.
func _light_the_place() -> void:
	_fog_the_place()
	if map.tint == "":
		return
	var dusk := CanvasModulate.new()
	dusk.color = Color(map.tint)
	add_child(dusk)


const FOG_SHADER := """
shader_type canvas_item;
uniform float thickness = 0.5;
uniform vec4 colour : source_color = vec4(0.82, 0.84, 0.9, 1.0);
void fragment() {
	vec2 from_middle = (UV - vec2(0.5)) * vec2(1.6, 1.0);
	float far = smoothstep(0.12, 0.62, length(from_middle));
	COLOR = vec4(colour.rgb, far * thickness);
}
"""


## Mist and jungle close in round the party: the screen fogs towards its edges,
## so what is coming is seen late (`fog` in the land's effects).
func _fog_the_place() -> void:
	var thickness := float(_land.get("fog", 0.0))
	if thickness <= 0.0:
		return
	var layer := CanvasLayer.new()
	layer.name = "Fog"
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = FOG_SHADER
	var paint := ShaderMaterial.new()
	paint.shader = shader
	paint.set_shader_parameter("thickness", clampf(thickness, 0.0, 0.9))
	if map.tint != "":
		paint.set_shader_parameter("colour", Color(map.tint).lightened(0.3))
	veil.material = paint
	layer.add_child(veil)
	add_child(layer)
	# Under the hint line and the log, which have to stay readable.
	var ui := get_node_or_null("UI")
	if ui != null:
		move_child(layer, ui.get_index())


func _spawn_fire() -> void:
	if map.fire.x < 0:
		return
	var fire := AreaFire.new()
	fire.position = map.centre_of(map.fire)
	_actors.add_child(fire)


func _spawn_buildings() -> void:
	_actors.y_sort_enabled = true
	for building: Dictionary in map.buildings:
		_actors.add_child(AreaBuilding.create(building))


## Dressing, plus a picture for every chest. Anything with something to say
## about itself is marked, so it can be walked up to and looked at. A chest
## already emptied on an earlier visit is standing open when you walk back in.
func _spawn_props() -> void:
	_actors.y_sort_enabled = true
	for prop: Dictionary in map.props:
		var art: String = prop.get("art", "")
		if not AreaProp.has_art(art):
			continue
		var node := AreaProp.from_entry(prop)
		node.position = map.centre_of(prop["cell"])
		# A nudge off the middle of its cell, so a wood does not stand in rows.
		var nudge: Array = prop.get("offset", [])
		if nudge.size() >= 2:
			node.position += Vector2(float(nudge[0]), float(nudge[1]))
		if not node.haul.is_empty() and GameState.has_flag(map.prop_flag(node.cell)):
			node.line = node.spent_line
			node.haul = {}
			node.set_interactive(node.line != "")
		_actors.add_child(node)
		if node.can_talk():
			_things.append(node)

	for cell: Vector2i in map.chests:
		var chest: Dictionary = map.chests[cell]
		var shut: String = chest.get("art", "chest")
		var is_stash := bool(chest.get("stash", false))
		var opened := not is_stash and GameState.has_flag(map.chest_flag(cell))
		var node := AreaProp.create(chest.get("opened_art", "chest_open") if opened else shut)
		node.position = map.centre_of(cell)
		node.cell = cell
		node.line = chest.get("line", "")
		if is_stash:
			node.display_name = "strongbox"
			node.set_interactive(true)
			_things.append(node)
		_actors.add_child(node)
		_chest_props[cell] = node

	# Props representing obstacle wards (cuttable trees, locked gates, etc.)
	for cell: Vector2i in map.wards:
		var ward: Dictionary = map.wards[cell]
		var prop_art := str(ward.get("prop", ""))
		if prop_art == "":
			if ward.get("kind", "") == "tree" or str(ward.get("name", "")).to_lower().contains("tree"):
				prop_art = "nature/sycamore_tree"
			elif ward.get("kind", "") == "gate" or str(ward.get("name", "")).to_lower().contains("gate"):
				prop_art = "village/log_pile"
		if prop_art != "" and AreaProp.has_art(prop_art):
			var opened := Ward.is_open(map.id, cell)
			var art_to_use := str(ward.get("cleared_art", "")) if opened and ward.has("cleared_art") else prop_art
			var node := AreaProp.create(art_to_use)
			node.position = map.centre_of(cell)
			node.cell = cell
			node.display_name = str(ward.get("name", "obstacle"))
			node.solid = not opened
			if opened and not ward.has("cleared_art"):
				node.visible = false
			else:
				node.line = "examine"
				node.set_interactive(not opened)
				_things.append(node)
			_actors.add_child(node)
			_ward_props[cell] = node


## Any of the sixteen standing at the place on the map this area is the inside
## of are standing in it too, a little way in from where the party arrives.
func _admit_the_others() -> void:
	var world: World = GameState.world
	if world == null or _return_scene != "world":
		return
	var site := world.site_at(world.player_cell)
	if site == null or str(site.data.get("area", site.kind)) != map.id:
		return
	var offsets: Array[Vector2i] = [Vector2i(2, -2), Vector2i(-2, -2), Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, -3)]
	var placed := 0
	for each: Dictionary in Wanderers.here(world, site.cell):
		var hero_id := str(each["id"])
		var spot := _free_spot_near(map.spawn + offsets[placed % offsets.size()])
		placed += 1
		map.people.append({
			"name": Wanderers.name_of(hero_id),
			"unit": hero_id,
			"cell": [spot.x, spot.y],
			"facing": [0, 1],
			"wanderer": hero_id,
			"wander": 1.5,
		})


## Leads who died in the worlds before this one sit at any fire the company
## sits at, once their news has come through (M15, [D33]): in a seat nobody
## took, or across the fire from the way in.
func _admit_the_ghosts() -> void:
	var world: World = GameState.world
	if world == null or map.fire.x < 0 or _return_scene != "world":
		return
	var free_seats: Array[Vector2i] = []
	var taken := maxi(0, GameState.party_characters().size() - 1)
	for i in range(taken, map.seats.size()):
		free_seats.append(map.seats[i])
	for index: int in Siblings.ghosts(world):
		var echo: Dictionary = Siblings.past(world)[index]
		var spot: Vector2i = free_seats.pop_front() if not free_seats.is_empty() \
			else _free_spot_near(map.fire + Vector2i(0, -2))
		map.people.append({
			"name": Siblings.ghost_name(world, index),
			"unit": str(echo.get("hero", "")),
			"cell": [spot.x, spot.y],
			"facing": [map.fire.x - spot.x, map.fire.y - spot.y],
			"ghost": index,
		})


func _free_spot_near(cell: Vector2i) -> Vector2i:
	for radius in range(0, 6):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var cand := cell + Vector2i(dx, dy)
				if map.is_walkable(cand):
					return cand
	return map.spawn


func _spawn_people() -> void:
	for index in map.people.size():
		var person: Dictionary = map.people[index]
		var actor := AreaActor.for_person(person)
		actor.position = map.centre_of(AreaMap.to_cell(person.get("cell", [0, 0])))
		actor.face(Vector2(AreaMap.to_cell(person.get("facing", [0, 1]))))
		actor.set_interactive(_seated.has(index) or _has_something_to_say(person))
		actor.chatter = person.get("chatter", [])
		if person.has("ghost"):
			# The same face as in life, with the fire showing through it.
			actor.modulate = Color(0.72, 0.86, 1.0, 0.55)
		_actors.add_child(actor)
		_people.append(actor)
		var reach := float(person.get("wander", 0.0))
		if reach > 0.0 and not _seated.has(index):
			actor.roam(reach, _can_stand)


func _has_something_to_say(person: Dictionary) -> bool:
	return person.get("dialogue", "") != "" or person.get("cutscene", "") != "" \
		or bool(person.get("guild", false)) or person.get("wanderer", "") != "" \
		or person.has("talk") \
		or person.has("ghost")


## The town holds its breath while a conversation or a cutscene is running.
func _hold_the_town(on: bool) -> void:
	for actor: AreaActor in _people:
		actor.hold_still(on)


# --- talking ------------------------------------------------------------------


## Everybody worth speaking to and everything worth looking at.
func _targets() -> Array[AreaThing]:
	var out: Array[AreaThing] = []
	for actor in _people:
		if actor.can_talk():
			out.append(actor)
	for thing in _things:
		if thing.can_talk():
			out.append(thing)
	return out


## Whatever the leader is standing nearest to, close enough to deal with.
func _refresh_prompt() -> void:
	var closest: AreaThing = null
	var best := TALK_RANGE
	for target in _targets():
		var apart := _leader.position.distance_to(target.position)
		if apart <= best:
			best = apart
			closest = target
	if closest != _nearby:
		if is_instance_valid(_nearby):
			_nearby.set_mark_ready(false)
		_nearby = closest
		if _nearby != null:
			_nearby.set_mark_ready(true)
	_hint.text = _prompt_text()


func _prompt_text() -> String:
	if _hovered != null:
		return "Click to %s" % _hovered.prompt()
	if _nearby != null:
		if Pad.using_pad:
			return "%s to %s" % [Pad.key("interact"), _nearby.prompt()]
		return "Click to %s" % _nearby.prompt()
	var here := _acts_text()
	if here != "":
		return here
	return _pad_hint() if Pad.using_pad else _idle_hint


func _on_pad_changed() -> void:
	_hint.text = _prompt_text()


## The idle line, said for a pad. A place's own line is written for the
## keyboard (it is data), so on a pad the buttons are said here instead.
func _pad_hint() -> String:
	return "%s to walk  ·  %s to speak to or look at whoever is marked  ·  %s to take the lead with someone else  ·  %s for the party  ·  %s for the journal  ·  follow the road out to leave" % [
		Pad.walk_text(), Pad.key("interact"), Pad.key("cycle_next"),
		Pad.key("open_party"), Pad.key("open_journal"),
	]


## What is under the mouse worth stopping for, or null. Whatever stands
## furthest down the screen is in front, so it wins an overlap.
func _target_at(point: Vector2) -> AreaThing:
	var found: AreaThing = null
	for target in _targets():
		if not target.contains_point(point):
			continue
		if found == null or target.position.y > found.position.y:
			found = target
	return found


func _hover_at(point: Vector2) -> void:
	var target := _target_at(point)
	if target == _hovered:
		return
	if is_instance_valid(_hovered):
		_hovered.set_hovered(false)
	_hovered = target
	if _hovered != null:
		_hovered.set_hovered(true)
	Input.set_default_cursor_shape(
		Input.CURSOR_POINTING_HAND if _hovered != null else Input.CURSOR_ARROW
	)
	_hint.text = _prompt_text()


## Click something within reach and the party deals with it at once; click one
## across the square and the leader walks over first.
func _click_target(target: AreaThing) -> void:
	if _leader.position.distance_to(target.position) <= TALK_RANGE:
		_approach = null
		_approach_path.clear()
		_engage(target)
		return
	_approach = target
	_approach_path = map.find_path(_leader.position, target.position)
	_approach_index = 0
	if _approach_path.size() > 1 and _leader.position.distance_to(_approach_path[0]) < 20.0:
		_approach_index = 1


## Steering for whatever the player clicked on: walk until it is close enough
## to deal with, then deal with it.
func _approach_step() -> Vector2:
	if not is_instance_valid(_approach) or not _approach.can_talk():
		_approach = null
		_approach_path.clear()
		return Vector2.ZERO
	var apart := _approach.position - _leader.position
	if apart.length() <= APPROACH_RANGE:
		var target := _approach
		_approach = null
		_approach_path.clear()
		_engage(target)
		return Vector2.ZERO

	if not _approach_path.is_empty() and _approach_index < _approach_path.size():
		var waypoint := _approach_path[_approach_index]
		if _leader.position.distance_to(waypoint) < 16.0:
			_approach_index += 1
			if _approach_index < _approach_path.size():
				waypoint = _approach_path[_approach_index]
		return (waypoint - _leader.position).normalized()

	return apart.normalized()


## Soak mode: make for the way out, so a run that is playing itself never
## settles down inside a town.
func _auto_axis() -> Vector2:
	if map == null or map.exits.is_empty():
		return Vector2.ZERO
	if _auto_exit_path.is_empty() or _auto_exit_index >= _auto_exit_path.size():
		var nearest := map.exits[0]
		var best_dist := _leader.position.distance_to(map.centre_of(nearest))
		for exit_cell in map.exits:
			var d := _leader.position.distance_to(map.centre_of(exit_cell))
			if d < best_dist:
				best_dist = d
				nearest = exit_cell
		_auto_exit_path = map.find_cell_path(map.cell_at(_leader.position), nearest)
		_auto_exit_index = 0
		if _auto_exit_path.size() > 1 and _leader.position.distance_to(_auto_exit_path[0]) < 20.0:
			_auto_exit_index = 1

	if not _auto_exit_path.is_empty() and _auto_exit_index < _auto_exit_path.size():
		var waypoint := _auto_exit_path[_auto_exit_index]
		if _leader.position.distance_to(waypoint) < 16.0:
			_auto_exit_index += 1
			if _auto_exit_index < _auto_exit_path.size():
				waypoint = _auto_exit_path[_auto_exit_index]
		return (waypoint - _leader.position).normalized()

	var nearest := map.centre_of(map.exits[0])
	var apart := nearest - _leader.position
	return apart.normalized() if apart.length() > 4.0 else Vector2.ZERO


## A person is spoken to; anything else is looked at.
func _engage(target: AreaThing) -> void:
	if target is AreaProp:
		_examine(target as AreaProp)
		return
	var index := _people.find(target as AreaActor)
	if index >= 0:
		_speak_to(index)


## Stopping at something: what the party makes of it, and whatever was tucked
## into it — which is only ever there the first time.
func _examine(thing: AreaProp) -> void:
	_leader.face(thing.position - _leader.position)
	if map.wards.has(thing.cell):
		_try_the_ward(thing.cell)
		return
	_note(thing.line)
	if thing.find_flag != "" and not GameState.has_flag(thing.find_flag):
		GameState.set_flag(thing.find_flag)
		if thing.found_line != "":
			_note(thing.found_line)
	if map.chests.has(thing.cell) and bool(map.chests[thing.cell].get("stash", false)):
		EventBus.stash_requested.emit()
		return
	if thing.haul.is_empty():
		return
	GameState.set_flag(map.prop_flag(thing.cell))
	for line: String in Loot.claim(thing.haul, GameState.roster):
		_note(line)
	thing.haul = {}
	thing.line = thing.spent_line
	thing.set_interactive(thing.line != "")
	if not thing.can_talk():
		if _nearby == thing:
			_nearby = null
		if _hovered == thing:
			_hovered = null
		_things.erase(thing)


## Walk up to somebody and the camera takes a moment over the meeting before
## either of you says a word.
func _speak_to(index: int) -> void:
	_talking = true
	_hold_the_town(true)
	if _seated.has(index):
		await _talk_around_the_fire(index)
		_camera.focus_on(_leader.position)
		_hold_the_town(false)
		_talking = false
		return

	var person: Dictionary = map.people[index]
	var them := _people[index]
	_leader.face(them.position - _leader.position)
	them.face(_leader.position - them.position)

	var cutscene_id: String = person.get("cutscene", "")
	var seen := "seen:cut:%s" % cutscene_id
	if cutscene_id != "" and (bool(person.get("repeat", false)) or not GameState.has_flag(seen)):
		GameState.set_flag(seen)
		_cutscene = AreaCutscene.between(self, _camera, _leader, them)
		await _cutscene.play(cutscene_id)
		_cutscene = null

	var dialogue_id: String = person.get("dialogue", "")
	var wanderer: String = person.get("wanderer", "")
	if person.has("ghost"):
		await _sit_with_the_ghost(int(person["ghost"]))
	elif wanderer != "":
		await _speak_to_the_fallen(index, wanderer)
	elif dialogue_id != "":
		EventBus.dialogue_requested.emit(dialogue_id)
		await EventBus.dialogue_finished
	elif bool(person.get("guild", false)) and Guild.hall_at(GameState.world, GameState.world.player_cell) != null:
		if not them.chatter.is_empty():
			them.say(them.chatter.pick_random())
		EventBus.guild_requested.emit()
		await EventBus.overlay_closed
	elif person.has("talk"):
		var talk_id: String = Talk.open(map.id, person)
		EventBus.dialogue_requested.emit(talk_id)
		await EventBus.dialogue_finished
	elif not them.chatter.is_empty():
		them.say(them.chatter.pick_random())

	_camera.focus_on(_leader.position)
	_hold_the_town(false)
	_talking = false



## One of the sixteen, met inside. If they agree to walk with you they step out
## of the crowd: the party picks them up on the way back out.
func _speak_to_the_fallen(index: int, hero_id: String) -> void:
	var dialogue_id := Wanderers.talk(GameState.world, GameState.roster, hero_id)
	if dialogue_id == "":
		return
	EventBus.dialogue_requested.emit(dialogue_id)
	await EventBus.dialogue_finished
	Wanderers.settle(GameState.world, GameState.roster, GameState.flags)
	if not bool(Wanderers.entry(GameState.world, hero_id).get("joined", false)):
		return
	_note(Wanderers.joined_line(GameState.world, hero_id))
	_people[index].set_interactive(false)
	_people[index].visible = false
	_nearby = null
	_hovered = null


## A dead lead's ghost, across the fire: as much of their journal as they will
## share tonight.
func _sit_with_the_ghost(index: int) -> void:
	var dialogue_id := Siblings.ghost_talk(GameState.world, index)
	if dialogue_id == "":
		return
	EventBus.dialogue_requested.emit(dialogue_id)
	await EventBus.dialogue_finished


## Two of your own, across the fire. What they find to say depends on what they
## have been through together, and saying it moves that on a notch ([Banter]).
func _talk_around_the_fire(index: int) -> void:
	var them: Character = _seated[index]
	_leader.face(_people[index].position - _leader.position)
	_camera.focus_on(_leader.position.lerp(_people[index].position, 0.5))

	var exchange := Banter.between(
		GameState.world, _leader_character, them, Banter.REST, GameState.world.rng
	)
	if exchange.is_empty():
		# Nothing left between the two of them, so they fall back on the run itself.
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var alone := Recollection.remark(GameState.world, [them], rng)
		if alone.is_empty():
			_note("%s watches the fire, and lets it be." % them.display_name)
			return
		exchange = [alone]

	var id := "camp:%s" % them.id
	if Pace.quiet_banter:
		# Said over their heads instead of over the screen.
		for line: Dictionary in exchange:
			_note("%s: %s" % [line.get("speaker", ""), line.get("text", "")])
		_people[index].say(str(exchange[-1].get("text", "")))
	else:
		Database.register_dialogue(id, Banter.as_dialogue(exchange, _leader_character, them))
		EventBus.dialogue_requested.emit(id)
		await EventBus.dialogue_finished
	# One thing each per fire, so the night is not talked in circles.
	_seated.erase(index)
	_people[index].set_interactive(false)
	_people[index].set_mark_ready(false)
	_people[index].set_hovered(false)
	_nearby = null
	_hovered = null


# --- walking ------------------------------------------------------------------


func _physics_process(delta: float) -> void:
	if _leaving or _leader == null or _talking or _overlay_open():
		return
	_refresh_prompt()
	if _check_the_watch(map.cell_at(_leader.position)):
		return
	if _picking_an_act():
		return
	# Before the early-out below: the party has to keep closing the gap after the
	# player lets go of the keys, or everyone freezes mid-stride where they stood.
	_settle_followers(delta)
	var axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if axis != Vector2.ZERO:
		# Taking the keys back calls off whatever the player was walking towards.
		_approach = null
		_approach_path.clear()
	elif Pace.auto:
		axis = _auto_axis()
	elif _approach != null:
		axis = _approach_step()
	if axis == Vector2.ZERO:
		return

	var before := _leader.position
	var stride := axis.normalized() * _walk_speed() * delta
	_try_the_way(before, stride)
	_leader.position = _slide(before, stride)
	var moved := _leader.position - before
	if moved.length_squared() > 0.01:
		_leader.face(moved)
	if _approach != null and _leader.position.is_equal_approx(before):
		# Something is in the way; the player can steer around it themselves.
		_approach = null
		_approach_path.clear()
	_drop_crumbs()
	_camera.focus_on(_leader.position)
	_walked += before.distance_to(_leader.position)
	_weather(before.distance_to(_leader.position))
	if _walked >= TALK_STRIDE:
		_walked = 0.0
		_road_talk()
	_arrive_at(map.cell_at(_leader.position))


## Bog and snow drag at the feet; open ground does not.
func _walk_speed() -> float:
	return WALK_SPEED * clampf(float(_land.get("slow", 1.0)), 0.3, 1.5)


## The cold, the heat or the ooze, wearing at whoever walks this ground without
## the gear to keep it off. Never down past `floor` of anyone's health: walking
## wears the party down for the fight, it does not kill (`data/biomes.json` →
## `hazards`).
func _weather(walked: float) -> void:
	var hazard := str(_land.get("hazard", ""))
	if hazard == "" or walked <= 0.0:
		return
	var rules: Dictionary = Database.biomes.get("hazards", {})
	_weathered += walked
	if _weathered < float(rules.get("stride", 640)):
		return
	_weathered = 0.0
	var told: Dictionary = rules.get(hazard, {})
	for member: Character in GameState.party_characters():
		if Biome.spared(member, hazard):
			continue
		var low := ceili(float(member.max_hp()) * float(rules.get("floor", 0.25)))
		var now := member.current_hp()
		if now <= low:
			continue
		member.hp = maxi(low, now - maxi(1, roundi(float(member.max_hp()) * float(rules.get("share", 0.04)))))
		if not _told_of.has(member.display_name):
			_told_of[member.display_name] = true
			_note(str(told.get("line", "%s is worn down by the land.")) % member.display_name)


## Two of the party say something to each other as they walk. It plays over
## their heads and is gone in a few seconds; nobody has to stop for it.
func _road_talk() -> void:
	if _chatting or _talking or _leaving or _followers.is_empty():
		return
	var world := GameState.world
	if world == null:
		return
	if world.rng.randf() >= float(Banter.rules().get("road_chance", 0.4)):
		return
	var exchange := Banter.pick(world, GameState.party_characters(), Banter.ROAD, world.rng)
	if not exchange.is_empty():
		_speak_bubbles(exchange)


## Line after line, each over whoever said it, the next one waiting only as
## long as the last takes to read.
func _speak_bubbles(exchange: Array) -> void:
	_chatting = true
	for line: Dictionary in exchange:
		var text: String = line.get("text", "")
		var speaker := _actor_named(line.get("speaker", ""))
		if speaker == null or text == "":
			continue
		speaker.say(text)
		await get_tree().create_timer(SpeechBubble.time_for(text)).timeout
		if not is_inside_tree() or _leaving:
			break
	_chatting = false


func _actor_named(who: String) -> AreaActor:
	if _leader != null and _leader.display_name == who:
		return _leader
	for follower in _followers:
		if follower.display_name == who:
			return follower
	return null


const BODY_RADIUS := 14.0


## Walls stop the axis that runs into them, not the whole step, so a shoulder
## against a pond still slides along it.
func _slide(from: Vector2, step: Vector2) -> Vector2:
	var out := from
	if _can_stand(Vector2(from.x + step.x, out.y)):
		out.x += step.x
	elif absf(step.y) > 0.001 and _can_stand(Vector2(from.x, out.y + step.y)):
		pass
	else:
		# Horizontal blocked; attempt subtle corner nudge up/down to slide smoothly around corners
		for nudge in [2.0, 4.0, 6.0, 8.0, 10.0]:
			if _can_stand(Vector2(from.x + step.x, out.y + nudge)):
				out.y += minf(absf(step.x), nudge)
				out.x += step.x
				break
			elif _can_stand(Vector2(from.x + step.x, out.y - nudge)):
				out.y -= minf(absf(step.x), nudge)
				out.x += step.x
				break

	if _can_stand(Vector2(out.x, from.y + step.y)):
		out.y += step.y
	elif absf(step.x) > 0.001 and _can_stand(Vector2(out.x + step.x, from.y)):
		pass
	else:
		# Vertical blocked; attempt subtle corner nudge left/right to slide smoothly around corners
		for nudge in [2.0, 4.0, 6.0, 8.0, 10.0]:
			if _can_stand(Vector2(out.x + nudge, from.y + step.y)):
				out.x += minf(absf(step.y), nudge)
				out.y += step.y
				break
			elif _can_stand(Vector2(out.x - nudge, from.y + step.y)):
				out.x -= minf(absf(step.y), nudge)
				out.y += step.y
				break

	return out


func _can_stand(point: Vector2) -> bool:
	if not map.is_walkable(map.cell_at(point)):
		return false
	# Ensure characters cannot penetrate walls or clip through diagonal wall corners
	for offset in [Vector2(-BODY_RADIUS, 0), Vector2(BODY_RADIUS, 0), Vector2(0, -BODY_RADIUS), Vector2(0, BODY_RADIUS),
				   Vector2(-BODY_RADIUS * 0.707, -BODY_RADIUS * 0.707), Vector2(BODY_RADIUS * 0.707, -BODY_RADIUS * 0.707),
				   Vector2(-BODY_RADIUS * 0.707, BODY_RADIUS * 0.707), Vector2(BODY_RADIUS * 0.707, BODY_RADIUS * 0.707)]:
		if not map.is_walkable(map.cell_at(point + offset)):
			return false
	return true


func _try_the_ward(cell: Vector2i) -> bool:
	if not map.wards.has(cell):
		return false
	if Ward.is_open(map.id, cell):
		return true
	var outcome := Ward.force(map.id, map.wards[cell], GameState.party_characters())
	_note(str(outcome["line"]))
	if bool(outcome["opened"]):
		_shut_wards.erase(cell)
		map.update_cell_solid(cell, false)
		map._blocked.erase(cell)
		Sfx.play(Sfx.SELECT)
		if _ward_props.has(cell):
			var prop: AreaProp = _ward_props[cell]
			var ward: Dictionary = map.wards[cell]
			prop.solid = false
			prop.set_interactive(false)
			if _things.has(prop):
				_things.erase(prop)
			if ward.has("cleared_art"):
				prop.set_art(ward["cleared_art"])
			else:
				var tw := create_tween()
				tw.tween_property(prop, "modulate:a", 0.0, 0.35)
				tw.tween_callback(func() -> void: prop.hide())
		return true
	return false


## Walking into a thing in the way is how you find out whether anyone with you
## can shift it. Only the party ever tries; the townsfolk walk around (see [Ward]).
func _try_the_way(from: Vector2, step: Vector2) -> void:
	for point in [Vector2(from.x + step.x, from.y), Vector2(from.x, from.y + step.y)]:
		var cell := map.cell_at(point)
		if not map.wards.has(cell) or Ward.is_open(map.id, cell):
			continue
		var opened := _try_the_ward(cell)
		if not opened and not _shut_wards.has(cell):
			_shut_wards[cell] = true


func _point_along_trail(target_dist: float) -> Vector2:
	if _crumbs.is_empty() or _leader == null:
		return _leader.position if _leader != null else Vector2.ZERO
	var prev := _leader.position
	var dist_so_far := 0.0
	for crumb in _crumbs:
		var seg_len := prev.distance_to(crumb)
		if dist_so_far + seg_len >= target_dist:
			var remain := target_dist - dist_so_far
			var t := remain / seg_len if seg_len > 0.001 else 0.0
			return prev.lerp(crumb, t)
		dist_so_far += seg_len
		prev = crumb
	return _crumbs.back()


func _drop_crumbs() -> void:
	if _followers.is_empty() or _leader == null:
		return
	if _crumbs.is_empty() or _leader.position.distance_to(_crumbs[0]) >= CRUMB_SPACING:
		_crumbs.push_front(_leader.position)
	var max_len := float(_followers.size() + 2) * FOLLOWER_DISTANCE
	var accum := 0.0
	var prev := _leader.position
	for i in _crumbs.size():
		accum += prev.distance_to(_crumbs[i])
		prev = _crumbs[i]
		if accum >= max_len:
			_crumbs.resize(i + 1)
			break


## Walk everyone up the trail the leader left. Runs every frame whether or not
## the player is holding a key. Follows along the polyline path smoothly.
func _settle_followers(delta: float) -> void:
	if _followers.is_empty() or _leader == null:
		return
	for index in _followers.size():
		var follower := _followers[index]
		var target_dist := float(index + 1) * FOLLOWER_DISTANCE
		var target_pos := _point_along_trail(target_dist)
		var to_target := target_pos - follower.position
		var far := to_target.length()

		if far <= FOLLOW_DEADZONE:
			# When settled, face along the trail towards the member ahead
			var ahead_dist := maxf(0.0, target_dist - 10.0)
			var ahead_pos := _point_along_trail(ahead_dist)
			var trail_dir := ahead_pos - follower.position
			if trail_dir.length_squared() > 1.0:
				follower.face(trail_dir)
			continue

		if far > FOLLOW_DEADZONE + 2.0:
			follower.face(to_target)

		var speed_mult := 1.35 if far > FOLLOWER_DISTANCE * 1.5 else (1.15 if far > FOLLOWER_DISTANCE else 1.0)
		var step := to_target.normalized() * (_walk_speed() * speed_mult * delta)
		if step.length() > far:
			step = to_target
		follower.position = _slide(follower.position, step)


func _arrive_at(cell: Vector2i) -> void:
	if map.is_exit(cell) or _is_edge_cell(cell):
		_handle_exit(cell)
		return
	var door := map.door_at(cell)
	if not door.is_empty():
		_enter(door)
		return
	if map.spots.has(cell) and not _visited_spots.has(cell):
		_visited_spots[cell] = true
		_note(map.spots[cell])
		if map.spot_flags.has(cell):
			GameState.set_flag(map.spot_flags[cell])
	if map.chests.has(cell):
		_open_chest(cell)


func _is_edge_cell(cell: Vector2i) -> bool:
	if not _planar_mode or _return_scene != "world":
		return false
	return cell.x <= 0 or cell.x >= map.width - 1 or cell.y <= 0 or cell.y >= map.height - 1


func _cardinal_direction_of(cell: Vector2i) -> Vector2i:
	if cell.y <= 1:
		return Vector2i.UP
	if cell.y >= map.height - 2:
		return Vector2i.DOWN
	if cell.x <= 1:
		return Vector2i.LEFT
	if cell.x >= map.width - 2:
		return Vector2i.RIGHT
	return Vector2i.ZERO


func _nearest_edge(cell: Vector2i) -> Vector2i:
	var apart := {
		Vector2i.UP: cell.y, Vector2i.DOWN: map.height - 1 - cell.y,
		Vector2i.LEFT: cell.x, Vector2i.RIGHT: map.width - 1 - cell.x,
	}
	var best := Vector2i.DOWN
	for dir: Vector2i in apart:
		if int(apart[dir]) < int(apart[best]):
			best = dir
	return best


func _direction_name(dir: Vector2i) -> String:
	match dir:
		Vector2i.UP: return "north"
		Vector2i.DOWN: return "south"
		Vector2i.LEFT: return "west"
		Vector2i.RIGHT: return "east"
	return "forward"


func _handle_exit(cell: Vector2i) -> void:
	if _leaving:
		return
	var dir := _cardinal_direction_of(cell)
	# On the ground every road leads somewhere on the continent: out the way it
	# points, rather than back up to a view nobody plays in.
	if dir == Vector2i.ZERO and _planar_mode and _return_scene == "world":
		dir = _nearest_edge(cell)
	if _planar_mode and GameState.world != null and dir != Vector2i.ZERO:
		var target_world := GameState.world.player_cell + dir
		if not GameState.world.in_bounds(target_world):
			_note("The continent drops away into endless mist. You cannot pass further %s." % _direction_name(dir))
			return
		if not GameState.world.is_walkable(target_world):
			var tid := GameState.world.terrain_id_at(target_world)
			if tid == "ocean" or tid == "water" or tid == "lake":
				_note("Deep waters stretch out to the %s. You cannot cross without a ship or ferry." % _direction_name(dir))
			elif tid == "crag" or tid == "mountain":
				_note("Steep mountain crags and sheer rock faces rise to the %s. You cannot pass." % _direction_name(dir))
			else:
				_note("The terrain to the %s is impassable." % _direction_name(dir))
			return
		_step_to_adjacent_planar_area(dir, target_world, cell)
		return

	_leave()


## The step is the continent's to take: bands, scenes on the road, rests and
## gates all happen there. It hands back the ground the party walks into, or a
## fight, or the fire.
func _step_to_adjacent_planar_area(dir: Vector2i, _target_world: Vector2i, from_cell: Vector2i) -> void:
	_leaving = true
	# If the step comes to nothing, back a little way in from the edge.
	var back := _here_payload()
	var inward := map.cell_at(_leader.position) - dir * 2
	back["spawn_cell"] = [inward.x, inward.y]
	EventBus.request_scene.emit("world", {
		"step": [dir.x, dir.y],
		"from_cell": [from_cell.x, from_cell.y],
		"held": _held,
		"back": back,
	})


## This ground as it is, to come back to: the same place, where the leader stands.
func _here_payload() -> Dictionary:
	var here := boot_payload.duplicate(true)
	for key: String in ["notes", "actions", "held"]:
		here.erase(key)
	if _leader != null:
		var cell := map.cell_at(_leader.position)
		here["spawn_cell"] = [cell.x, cell.y]
	return here


# --- bands, and the ground they watch (D66, D68) ---------------------------------


## Every band the world says is here, standing where it camps (or at the edge it watches from),
## patrolling its loop, with what it can see painted red ([AreaWatch]).
func _post_the_watch() -> void:
	var bands: Array = boot_payload.get("bands", [])
	if bands.is_empty() or _leader == null:
		return
	var arrived := map.cell_at(_leader.position)
	var taken := _cells_spoken_for(arrived)
	for band: Dictionary in bands:
		var watch: Node2D = AreaWatch.place(map, band, arrived, taken, float(_land.get("sight", 0)))
		if watch == null:
			continue
		_layers.add_child(watch)
		for figure: Node2D in watch.make_figures(_leader.position):
			_actors.add_child(figure)
		watch.can_move = func() -> bool: return not (_talking or _leaving or _spotted or _overlay_open())
		watch.moved.connect(_on_band_moved.bind(watch))
		_watches.append(watch)
	if not _watches.is_empty():
		_note("%s — the ground it can see is marked. Step onto it and it fights you, here." % _watches[0].band.get("label", "A band"))
		EventBus.tip_moment.emit("ground_watch", {})


## Where nobody from a band may stand: where the party is, the ways out, doors, chests, spots,
## seats and everyone who lives here.
func _cells_spoken_for(arrived: Vector2i) -> Dictionary:
	var taken := {}
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			taken[arrived + Vector2i(dx, dy)] = true
	for cell: Vector2i in map.exits:
		taken[cell] = true
	for cell: Vector2i in map.spots:
		taken[cell] = true
	for cell: Vector2i in map.chests:
		taken[cell] = true
	for cell: Vector2i in map.seats:
		taken[cell] = true
	for building: Dictionary in map.buildings:
		taken[building["door"]] = true
		taken[building["door"] + Vector2i.DOWN] = true
	for person: Dictionary in map.people:
		taken[AreaMap.to_cell(person.get("cell", [0, 0]))] = true
	return taken


## The leader's step onto [param cell]: into a watched cell, and the band has seen them. Only a
## step counts — where the party was put down is not walking into anybody — and never while the
## party is walking itself (out on the continent, where it is jumped the old way).
func _check_the_watch(cell: Vector2i) -> bool:
	if _watches.is_empty():
		return false
	for watch: Node2D in _watches:
		watch.keep_an_eye_on(_leader.position)
	if cell == _last_cell:
		return false
	var came_from := _last_cell
	_last_cell = cell
	if came_from == Vector2i(-99, -99) or _spotted or _leaving or _talking or Pace.auto:
		return false
	for watch: Node2D in _watches:
		if watch.watched.has(cell):
			_seen_by(watch, came_from)
			return true
	return false


## A patrolling band has walked somewhere it can see the party from: seen, as surely as walking in.
func _on_band_moved(watch: Node2D) -> void:
	if _leader == null or _spotted or _leaving or _talking or Pace.auto:
		return
	if watch.watched.has(map.cell_at(_leader.position)):
		_seen_by(watch, Vector2i(-1, -1))


## Seen. Every head turns, the one in front shouts, the field is taken from where everyone stands,
## the band rushes in, and the fight opens on this ground at this view ([D66]). Bursting out of
## cover at them is an ambush.
func _seen_by(watch: Node2D, came_from: Vector2i) -> void:
	_spotted = true
	_leaving = true
	_talking = true
	_approach = null
	_approach_path.clear()
	_hold_the_town(true)
	var ambush: bool = map.in_bounds(came_from) and watch.in_cover(came_from)
	watch.raise_the_alarm(_leader.position, ambush)
	var many := (watch.band.get("pack", []) as Array).size() > 1
	if ambush:
		_note("Out of the long grass and on %s before they know it." % str(watch.band.get("label", "them")))
	else:
		_note("%s %s seen you!" % [str(watch.band.get("label", "Something")), "have" if many else "has"])
		# A beat for the shout to be read before they come; an ambush gives them none.
		await get_tree().create_timer(float(AreaWatch.rule("spotted_seconds", 0.5))).timeout
	if not is_inside_tree():
		return
	# Where everyone stood when they were seen is where the fight is laid out, so it is taken
	# before the band closes in.
	var field := _field_for(watch, ambush)
	await _charge(watch)
	if not is_inside_tree():
		return
	EventBus.request_scene.emit("world", {
		"fight": str(watch.band.get("key", "")),
		"field": field,
		"held": _held,
		"back": _here_payload(),
	})


## The band rushes the party: part of the way, facing them, so the fight opening is something
## seen happen rather than a cut.
func _charge(watch: Node2D) -> void:
	var figures: Array = watch.figures
	if figures.is_empty() or _leader == null:
		return
	var rush := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var share := float(AreaWatch.rule("charge_share", 0.55))
	for figure: Node2D in figures:
		var towards := _leader.position - figure.position
		figure.face(towards)
		rush.tween_property(figure, "position", figure.position + towards * share, float(AreaWatch.rule("charge_seconds", 0.45)))
	_leader.face((figures[0] as Node2D).position - _leader.position)
	await rush.finished


## The patch of this ground the fight is fought on: everyone in it, with room round them, cut to
## the ground's edges; and the view the ground was seen in, for the fight to open on.
func _field_for(watch: Node2D, ambush: bool) -> Dictionary:
	var party: Array = []
	for actor: AreaActor in [_leader] + _followers:
		var c := map.cell_at(actor.position)
		party.append([c.x, c.y])
	var foes: Array = []
	for figure: Node2D in watch.figures:
		var c := map.cell_at(figure.position)
		foes.append([c.x, c.y])
	var margin := int(AreaWatch.rule("field_margin", 3))
	var smallest := _pair_rule("field_smallest", Vector2i(16, 11))
	var largest := _pair_rule("field_largest", Vector2i(26, 16))
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-1, -1)
	for pair: Array in party + foes:
		lo = Vector2i(mini(lo.x, int(pair[0])), mini(lo.y, int(pair[1])))
		hi = Vector2i(maxi(hi.x, int(pair[0])), maxi(hi.y, int(pair[1])))
	lo -= Vector2i.ONE * margin
	hi += Vector2i.ONE * margin
	var size := (hi - lo + Vector2i.ONE).clamp(smallest, largest)
	size = Vector2i(mini(size.x, map.width), mini(size.y, map.height))
	var centre := (lo + hi) / 2
	var origin := (centre - size / 2).clamp(Vector2i.ZERO, Vector2i(map.width, map.height) - size)
	var seen_at := _camera.get_screen_center_position()
	return {
		"area_id": map.id, "origin": [origin.x, origin.y], "size": [size.x, size.y],
		"party": party, "foes": foes, "title": boot_payload.get("title", map.display_name),
		"ambush": ambush,
		# The camera as it was, in ground pixels: the fight opens on exactly this, then draws back.
		"view": { "centre": [seen_at.x, seen_at.y], "zoom": _camera.zoom.x },
	}


func _pair_rule(key: String, fallback: Vector2i) -> Vector2i:
	var value: Variant = AreaWatch.rule(key, [])
	return Vector2i(int(value[0]), int(value[1])) if value is Array and (value as Array).size() >= 2 else fallback


# --- the place's doings, and the map --------------------------------------------


## The journal's Map: the continent, and back to this spot after.
func _open_the_map() -> void:
	if _leaving or not is_inside_tree():
		return
	_leaving = true
	var back := _here_payload()
	back["held"] = _held
	back["actions"] = _acts
	EventBus.request_scene.emit("world", { "map": true, "back": back })


func _acts_text() -> String:
	var said: Array[String] = []
	for each: Dictionary in _acts:
		said.append(str(each.get("prompt", "")))
	return "  ·  ".join(said)


## The doing a key asks for here, or an empty dictionary. Interact is the
## place's only while there is nobody close enough to speak to.
func _act_for(event: InputEvent) -> Dictionary:
	if not event.is_pressed() or event.is_echo():
		return {}
	for each: Dictionary in _acts:
		var key: Variant = each.get("key", "")
		if str(each.get("act", "")) == "":
			continue
		if key is String and str(key) != "":
			if event.is_action_pressed(str(key)) and not (str(key) == "interact" and _nearby != null):
				return each
		elif (key is int or key is float) and event is InputEventKey and event.keycode == int(key):
			return each
	return {}


func _do_act(each: Dictionary) -> void:
	if _leaving or _talking:
		return
	_leaving = true
	EventBus.request_scene.emit("world", {
		"act": str(each.get("act", "")),
		"held": _held,
		"back": _here_payload(),
	})


## A thumb or a pad has no H to press, so the place's doings are buttons too,
## the same list the hint line reads.
func _lay_out_acts() -> void:
	if not (Pace.is_touch_enabled() or Pad.using_pad):
		return
	var pressable: Array = _acts.filter(func(each: Dictionary) -> bool: return str(each.get("label", "")) != "")
	if pressable.is_empty():
		return
	_act_bar = HFlowContainer.new()
	_act_bar.anchor_left = 0.5
	_act_bar.anchor_right = 0.5
	_act_bar.anchor_top = 1.0
	_act_bar.anchor_bottom = 1.0
	_act_bar.offset_left = -320.0
	_act_bar.offset_right = 320.0
	_act_bar.offset_top = -300.0
	_act_bar.offset_bottom = -120.0
	_act_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_act_bar.alignment = FlowContainer.ALIGNMENT_CENTER
	_act_bar.add_theme_constant_override("h_separation", 8)
	_act_bar.add_theme_constant_override("v_separation", 8)
	_hint.get_parent().add_child(_act_bar)
	for each: Dictionary in pressable:
		var button := Button.new()
		button.text = str(each["label"])
		button.focus_mode = Control.FOCUS_ALL if Pad.using_pad else Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(0, 56)
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_do_act.bind(each))
		Sfx.attend(button)
		_act_bar.add_child(button)


func _picking_an_act() -> bool:
	var owner := get_viewport().gui_get_focus_owner()
	return owner != null and _act_bar != null and _act_bar.is_ancestor_of(owner)


## Whatever is in it is written into the area, so the same chest always holds
## the same thing — but it only holds it once.
func _open_chest(cell: Vector2i) -> void:
	var chest: Dictionary = map.chests[cell]
	if bool(chest.get("stash", false)):
		_note(chest.get("line", "The strongbox travels with you. Whatever nobody is carrying ends up in it."))
		EventBus.stash_requested.emit()
		return
	var flag := map.chest_flag(cell)
	if GameState.has_flag(flag):
		return
	GameState.set_flag(flag)
	Ledger.add(GameState.ledger, "chests_opened")

	_note(chest.get("line", "A chest, and nobody watching it."))
	if _chest_props.has(cell):
		_chest_props[cell].set_art(chest.get("opened_art", "chest_open"))
	var haul := chest.duplicate()
	haul["map"] = Atlas.finds_map(GameState.world, flag, "chest_map_chance")
	for line: String in Loot.claim(haul, GameState.roster):
		_note(line)


func _leave() -> void:
	_leaving = true
	EventBus.request_scene.emit(_return_scene, _return_payload)


## Inside is another area, and the way back out is this doorstep.
func _enter(building: Dictionary) -> void:
	var inside: String = building.get("area", "")
	if inside == "coliseum":
		_leaving = true
		var doorstep := map.step_out_of(building)
		var outside := boot_payload.duplicate(true)
		outside.erase("notes")
		outside["spawn_cell"] = [doorstep.x, doorstep.y]
		EventBus.request_scene.emit("coliseum", {
			"live_run": true,
			"return_scene": "area",
			"return_payload": outside,
		})
		return
	if not Database.has_area(inside):
		var shut: Variant = building.get("shut", "The door is shut, and stays shut.")
		_note(str(shut.pick_random()) if shut is Array and not shut.is_empty() else str(shut))
		return
	_leaving = true
	var doorstep := map.step_out_of(building)
	# The way back out is this ground as it was, so the street still knows it
	# is part of the continent and what the place offers.
	var outside := boot_payload.duplicate(true)
	outside.erase("notes")
	outside["spawn_cell"] = [doorstep.x, doorstep.y]
	EventBus.request_scene.emit("area", {
		"area_id": inside,
		"title": building.get("name", ""),
		"return_scene": "area",
		"return_payload": outside,
	})


## Hand the reins to the next of the party; the two of them trade places so
## whoever is walking is always the one out in front.
func _cycle_leader() -> void:
	if _followers.is_empty():
		return
	var next: AreaActor = _followers.pop_front()
	var front := _leader.position
	_leader.position = next.position
	next.position = front
	_followers.append(_leader)
	_leader = next
	for c: Character in GameState.party_characters():
		if c.display_name == _leader.display_name:
			_leader_character = c
			break
	_reseed_crumbs()
	_camera.focus_on(_leader.position)
	_note("%s takes the lead." % _leader.display_name)


func _reseed_crumbs() -> void:
	if _followers.is_empty() or _leader == null:
		return
	_crumbs.clear()
	var points: Array[Vector2] = [_leader.position]
	for follower in _followers:
		points.append(follower.position)
	for seg in range(points.size() - 1):
		var p0: Vector2 = points[seg]
		var p1: Vector2 = points[seg + 1]
		var seg_len := p0.distance_to(p1)
		var steps_count := maxi(1, roundi(seg_len / CRUMB_SPACING))
		for step in range(steps_count):
			var t := float(step) / float(steps_count)
			_crumbs.append(p0.lerp(p1, t))
	_crumbs.append(points.back())


func _note(line: String) -> void:
	if line == "":
		return
	_notes.append(line)
	if _notes.size() > 3:
		_notes = _notes.slice(_notes.size() - 3)
	_log.text = "\n".join(_notes)


func _overlay_open() -> bool:
	for overlay in get_tree().get_nodes_in_group(EventBus.MODAL_OVERLAY_GROUP):
		if overlay.is_open():
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_mouse_input(event)
		return
	var asked := _act_for(event)
	if not asked.is_empty() and not _leaving and not _talking:
		get_viewport().set_input_as_handled()
		_do_act(asked)
		return
	if event.is_action_pressed("open_actions") and _act_bar != null:
		get_viewport().set_input_as_handled()
		_toggle_act_focus()
		return
	# Ahead of the pace keys, which used to share E with it.
	if event.is_action_pressed("interact") and _nearby != null and not _talking:
		get_viewport().set_input_as_handled()
		_engage(_nearby)
		return
	if event.is_action_pressed("battle_auto"):
		get_viewport().set_input_as_handled()
		Pace.auto = not Pace.auto
		return
	if event.is_action_pressed("battle_speed"):
		get_viewport().set_input_as_handled()
		Pace.cycle_speed()
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		EventBus.system_menu_requested.emit()
	elif event.is_action_pressed("open_party"):
		get_viewport().set_input_as_handled()
		EventBus.party_screen_requested.emit()
	elif event is InputEventKey and event.is_pressed() and not event.is_echo() \
			and event.keycode == KEY_N:
		get_viewport().set_input_as_handled()
		EventBus.journal_requested.emit()
	elif event.is_action_pressed("cycle_next") and not _leaving:
		get_viewport().set_input_as_handled()
		_cycle_leader()


## Picking something out of the square and dealing with it is done with the
## mouse; the keys are only there for anybody who would rather not use it.
func _mouse_input(event: InputEvent) -> void:
	if _leaving or _leader == null or _talking or _overlay_open():
		return
	if event is InputEventMouseMotion:
		_hover_at(get_global_mouse_position())
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var target := _target_at(get_global_mouse_position())
	if target == null:
		return
	get_viewport().set_input_as_handled()
	_click_target(target)


## Y: onto the place's first button, or off again.
func _toggle_act_focus() -> void:
	if _picking_an_act():
		get_viewport().gui_release_focus()
		return
	for child in _act_bar.get_children():
		var button := child as Button
		if button != null and button.is_visible_in_tree():
			button.grab_focus()
			return


func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
