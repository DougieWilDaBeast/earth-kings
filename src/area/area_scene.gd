extends Node2D
## Area mode: a place drawn from tilesets, seen from above, with the party
## walking around inside it.
##
## The leader answers the movement keys; everyone else walks the ground the
## leader has already covered. Leaving by the road hands play back to whatever
## scene sent us here.

const WALK_SPEED := 190.0
## How far the leader travels between breadcrumbs, and how many breadcrumbs
## each follower hangs back by.
const CRUMB_SPACING := 8.0
const CRUMB_GAP := 4
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
## Wards already leaned on and refused, so the refusal is said once.
var _shut_wards: Dictionary = {}
var _return_scene: String = "world"
## What the bottom of the screen falls back to when nobody is near.
var _idle_hint: String = HINT
## What the scene we came from needs to put itself back the way it was.
var _return_payload: Dictionary = {}
var _leaving: bool = false


func _ready() -> void:
	_return_scene = boot_payload.get("return_scene", "world")
	_return_payload = boot_payload.get("return_payload", {})
	map = AreaMap.load_area(boot_payload.get("area_id", "village"))
	if map == null:
		push_error("Area: no such area '%s'" % boot_payload.get("area_id", ""))
		EventBus.request_scene.emit(_return_scene, _return_payload)
		return

	_paint_layers()
	_light_the_place()
	_spawn_buildings()
	_spawn_props()
	_spawn_party()
	_spawn_people()
	_spawn_fire()
	_camera.frame(map.rect())
	_camera.focus_on(_leader.position, true)
	_place.text = boot_payload.get("title", map.display_name)
	_idle_hint = map.hint if map.hint != "" else HINT
	_hint.text = _idle_hint
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


## One [TileMapLayer] per sheet, bottom first. Sheets drawn at a smaller tile
## size are scaled up so every layer shares the area's cell size.
func _paint_layers() -> void:
	for index in map.layers.size():
		var sheet := Database.tileset_sheet(map.layers[index])
		if sheet.is_empty():
			push_warning("Area: %s has no sheet '%s'" % [map.id, map.layers[index]])
			continue
		var tile_set := TileForge.tile_set_for(sheet)
		if tile_set == null:
			continue

		var layer := TileMapLayer.new()
		layer.tile_set = tile_set
		var zoom := float(AreaMap.CELL) / float(sheet.get("tile_size", AreaMap.CELL))
		layer.scale = Vector2(zoom, zoom)
		# Half a cell up and left, so tile corners land on cell centres.
		layer.position = Vector2.ONE * (-AreaMap.CELL / 2.0)
		_layers.add_child(layer)
		_fill_layer(layer, sheet, index > 0)


func _fill_layer(layer: TileMapLayer, sheet: Dictionary, is_overlay: bool) -> void:
	var feature: String = sheet.get("feature", sheet.get("lower", ""))
	var feature_bit := 1 if feature == sheet.get("upper", "") else 0
	# The code a tile gets when the sheet's own terrain is nowhere near it.
	var blank := (1 - feature_bit) * 0b1111
	for y in range(0, map.height + 1):
		for x in range(0, map.width + 1):
			var code := map.corner_code(Vector2i(x, y), feature, feature_bit)
			# An upper layer with nothing of its own here lets the one below show.
			if is_overlay and code == blank:
				continue
			layer.set_cell(Vector2i(x, y), TileForge.SOURCE_ID, TileForge.atlas_coords(code))


func _spawn_party() -> void:
	_actors.y_sort_enabled = true
	var start := map.spawn
	if boot_payload.has("spawn_cell"):
		start = AreaMap.to_cell(boot_payload["spawn_cell"])
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
	if map.tint == "":
		return
	var dusk := CanvasModulate.new()
	dusk.color = Color(map.tint)
	add_child(dusk)


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
		var opened := GameState.has_flag(map.chest_flag(cell))
		var node := AreaProp.create(chest.get("opened_art", "chest_open") if opened else shut)
		node.position = map.centre_of(cell)
		_actors.add_child(node)
		_chest_props[cell] = node


func _spawn_people() -> void:
	for index in map.people.size():
		var person: Dictionary = map.people[index]
		var actor := AreaActor.for_person(person)
		actor.position = map.centre_of(AreaMap.to_cell(person.get("cell", [0, 0])))
		actor.face(Vector2(AreaMap.to_cell(person.get("facing", [0, 1]))))
		actor.set_interactive(_seated.has(index) or _has_something_to_say(person))
		actor.chatter = person.get("chatter", [])
		_actors.add_child(actor)
		_people.append(actor)
		var reach := float(person.get("wander", 0.0))
		if reach > 0.0 and not _seated.has(index):
			actor.roam(reach, _can_stand)


func _has_something_to_say(person: Dictionary) -> bool:
	return person.get("dialogue", "") != "" or person.get("cutscene", "") != ""


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
		return "Click to %s" % _nearby.prompt()
	return _idle_hint


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
		_engage(target)
		return
	_approach = target


## Steering for whatever the player clicked on: walk until it is close enough
## to deal with, then deal with it.
func _approach_step() -> Vector2:
	if not is_instance_valid(_approach) or not _approach.can_talk():
		_approach = null
		return Vector2.ZERO
	var apart := _approach.position - _leader.position
	if apart.length() > APPROACH_RANGE:
		return apart.normalized()
	var target := _approach
	_approach = null
	_engage(target)
	return Vector2.ZERO


## Soak mode: make for the way out, so a run that is playing itself never
## settles down inside a town.
func _auto_axis() -> Vector2:
	if map == null or map.exits.is_empty():
		return Vector2.ZERO
	var nearest := map.centre_of(map.exits[0])
	for cell: Vector2i in map.exits:
		var point := map.centre_of(cell)
		if _leader.position.distance_to(point) < _leader.position.distance_to(nearest):
			nearest = point
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
	_note(thing.line)
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
	if dialogue_id != "":
		EventBus.dialogue_requested.emit(dialogue_id)
		await EventBus.dialogue_finished
	elif not them.chatter.is_empty():
		them.say(them.chatter.pick_random())

	_camera.focus_on(_leader.position)
	_hold_the_town(false)
	_talking = false



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
	var axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if axis != Vector2.ZERO:
		# Taking the keys back calls off whatever the player was walking towards.
		_approach = null
	elif Pace.auto:
		axis = _auto_axis()
	elif _approach != null:
		axis = _approach_step()
	if axis == Vector2.ZERO:
		return

	var before := _leader.position
	_try_the_way(before, axis.normalized() * WALK_SPEED * delta)
	_leader.position = _slide(before, axis.normalized() * WALK_SPEED * delta)
	_leader.face(_leader.position - before)
	if _approach != null and _leader.position.is_equal_approx(before):
		# Something is in the way; the player can steer around it themselves.
		_approach = null
	_drop_crumbs()
	_camera.focus_on(_leader.position)
	_walked += before.distance_to(_leader.position)
	if _walked >= TALK_STRIDE:
		_walked = 0.0
		_road_talk()
	_arrive_at(map.cell_at(_leader.position))


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


## Walls stop the axis that runs into them, not the whole step, so a shoulder
## against a pond still slides along it.
func _slide(from: Vector2, step: Vector2) -> Vector2:
	var out := from
	if _can_stand(Vector2(from.x + step.x, out.y)):
		out.x += step.x
	if _can_stand(Vector2(out.x, from.y + step.y)):
		out.y += step.y
	return out


func _can_stand(point: Vector2) -> bool:
	return map.is_walkable(map.cell_at(point))


## Walking into a thing in the way is how you find out whether anyone with you
## can shift it. Only the party ever tries; the townsfolk walk around (see [Ward]).
func _try_the_way(from: Vector2, step: Vector2) -> void:
	for point in [Vector2(from.x + step.x, from.y), Vector2(from.x, from.y + step.y)]:
		var cell := map.cell_at(point)
		if not map.wards.has(cell) or Ward.is_open(map.id, cell):
			continue
		var outcome := Ward.force(map.id, map.wards[cell], GameState.party_characters())
		if bool(outcome["opened"]):
			_note(str(outcome["line"]))
			_shut_wards.erase(cell)
			return
		# The refusal is worth hearing once, not every frame you lean on it.
		if not _shut_wards.has(cell):
			_shut_wards[cell] = true
			_note(str(outcome["line"]))


func _drop_crumbs() -> void:
	if _followers.is_empty():
		return
	if _crumbs.is_empty() or _leader.position.distance_to(_crumbs[0]) >= CRUMB_SPACING:
		_crumbs.push_front(_leader.position)
	var needed := (_followers.size() + 1) * CRUMB_GAP
	if _crumbs.size() > needed:
		_crumbs.resize(needed)
	for index in _followers.size():
		var crumb: Vector2 = _crumbs[mini((index + 1) * CRUMB_GAP, _crumbs.size() - 1)]
		var follower := _followers[index]
		if crumb == follower.position:
			continue
		follower.face(crumb - follower.position)
		follower.position = crumb


func _arrive_at(cell: Vector2i) -> void:
	if map.is_exit(cell):
		_leave()
		return
	var door := map.door_at(cell)
	if not door.is_empty():
		_enter(door)
		return
	if map.spots.has(cell) and not _visited_spots.has(cell):
		_visited_spots[cell] = true
		_note(map.spots[cell])
	if map.chests.has(cell):
		_open_chest(cell)


## Whatever is in it is written into the area, so the same chest always holds
## the same thing — but it only holds it once.
func _open_chest(cell: Vector2i) -> void:
	var flag := map.chest_flag(cell)
	if GameState.has_flag(flag):
		return
	GameState.set_flag(flag)
	Ledger.add(GameState.ledger, "chests_opened")

	var chest: Dictionary = map.chests[cell]
	_note(chest.get("line", "A chest, and nobody watching it."))
	if _chest_props.has(cell):
		_chest_props[cell].set_art(chest.get("opened_art", "chest_open"))
	for line: String in Loot.claim(chest, GameState.roster):
		_note(line)


func _leave() -> void:
	_leaving = true
	EventBus.request_scene.emit(_return_scene, _return_payload)


## Inside is another area, and the way back out is this doorstep.
func _enter(building: Dictionary) -> void:
	var inside: String = building.get("area", "")
	if not Database.has_area(inside):
		_note("The door is shut, and stays shut.")
		return
	_leaving = true
	var doorstep := map.step_out_of(building)
	EventBus.request_scene.emit("area", {
		"area_id": inside,
		"title": building.get("name", ""),
		"return_scene": "area",
		"return_payload": {
			"area_id": map.id,
			"title": boot_payload.get("title", map.display_name),
			"return_scene": _return_scene,
			"return_payload": _return_payload,
			"spawn_cell": [doorstep.x, doorstep.y],
		},
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
	_crumbs.clear()
	_camera.focus_on(_leader.position)
	_note("%s takes the lead." % _leader.display_name)


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


func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
