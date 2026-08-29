extends Node2D
## Walk mode: the world, a party moving across it one tile at a time, and
## everything that interrupts them.
##
## Every step advances the world clock, so travel is never free.

const CELL := 24
## Seconds between steps while a direction is held down.
const REPEAT_DELAY := 0.11
const FIRST_REPEAT_DELAY := 0.28
## Beat between the last of the party falling and the title screen.
const RUN_OVER_DELAY := 3.0
## Steps between the country putting fresh bands out where you cannot see them.
const RESTOCK_INTERVAL := 12

const DIRECTIONS := {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
}

const SITE_COLOURS := {
	Site.TOWER: Color(0.92, 0.85, 0.45),
	Site.KEEP: Color(0.72, 0.74, 0.82),
	Site.VILLAGE: Color(0.55, 0.78, 0.55),
	Site.LIBRARY: Color(0.55, 0.7, 0.95),
	Site.GATE: Color(0.85, 0.35, 0.35),
	Site.HUT: Color(0.78, 0.66, 0.48),
	Site.GRAVE: Color(0.62, 0.62, 0.66),
	Site.HOME: Color(0.96, 0.6, 0.35),
}

var boot_payload: Dictionary = {}

@onready var _map: Node2D = $Map
@onready var _camera: Camera2D = $Camera2D
@onready var _place: Label = %PlaceLabel
@onready var _party: Label = %PartyLabel
@onready var _log: Label = %LogLabel
@onready var _hint: Label = %HintLabel

var world: World
var _notices: Array[String] = []
var _repeat_timer: float = 0.0
var _held: Vector2i = Vector2i.ZERO
var _busy: bool = false
## Whatever the party are saying to each other as they walk, if anything.
var _bubble: SpeechBubble = null
## Someone of yours being held at the tile you are standing on.
var _captive_here: Character = null


func _ready() -> void:
	world = GameState.world
	Encounter.restock(world, world.rng)
	_map.draw.connect(_draw_world)
	_map.queue_redraw()
	_centre_camera()
	_refresh()

	if GameState.has_flag("last_victory"):
		_note("You are still standing.")
		# Coming through a fight together is worth something to the people who did.
		Banter.shared(GameState.party_characters(), int(Banter.rules().get("bond_per_battle", 1)))
		_talk(Banter.AFTER_BATTLE, true)
	if not GameState.has_flag("seen:watched_ground"):
		GameState.set_flag("seen:watched_ground")
		_note("Red ground is being watched. Step onto it and you have been seen.")
	GameState.set_flag("last_victory", false)
	_check_party()


func _process(delta: float) -> void:
	if _busy:
		return
	var direction := _pressed_direction()
	if direction == Vector2i.ZERO:
		_held = Vector2i.ZERO
		return

	if direction != _held:
		_held = direction
		_repeat_timer = FIRST_REPEAT_DELAY
		_step(direction)
		return

	_repeat_timer -= delta
	if _repeat_timer <= 0.0:
		_repeat_timer = REPEAT_DELAY
		_step(direction)


func _pressed_direction() -> Vector2i:
	for action: String in DIRECTIONS:
		if Input.is_action_pressed(action):
			return DIRECTIONS[action]
	return Vector2i.ZERO


# --- walking ------------------------------------------------------------------


func _step(direction: Vector2i) -> void:
	var target := world.player_cell + direction
	if not world.is_walkable(target):
		return

	world.player_cell = target
	_captive_here = null
	for notice: String in world.step():
		_note(notice)
	for notice: String in Errand.on_arrive(GameState.errands, target, world):
		_note(notice)
	# The country fills its empty stretches back in while you are looking away.
	if world.steps % RESTOCK_INTERVAL == 0:
		Encounter.restock(world, world.rng)
	_road_talk()
	_centre_camera()
	_map.queue_redraw()

	var site := world.site_at(target)
	if site != null:
		_arrive_at(site)
	else:
		_look_for_a_cache(target)
	_watch_check(target)
	_check_party()
	_refresh()


## Country nobody is watching still has things left lying about in it. The
## worse the ground, the better what was left behind — and the likelier its
## owner did not walk away.
func _look_for_a_cache(cell: Vector2i) -> void:
	if _busy or world.rng.randf() >= float(Loot.rules().get("cache_chance", 0.04)):
		return
	_note("Something has been left here, and left a long while.")
	for line: String in Loot.claim(Loot.roll(world, 0.5 + Encounter.chance_at(world, cell) * 2.0), GameState.roster):
		_note(line)


## The only way a fight starts in the open: somebody was watching the tile you
## just walked onto. They come off the map, because they are in front of you now.
func _watch_check(cell: Vector2i) -> void:
	if _busy:
		return
	var band := world.prowler_watching(cell)
	if band == null:
		return
	world.prowlers.erase(band)
	_map.queue_redraw()
	_begin_battle(Encounter.for_band(world, band, GameState.party_characters(), world.rng))


func _begin_battle(meeting: Dictionary) -> void:
	_busy = true
	_note(meeting["title"])
	EventBus.request_scene.emit("battle", {"encounter": meeting, "return_scene": "world"})


# --- places -------------------------------------------------------------------


func _arrive_at(site: Site) -> void:
	Ledger.record_place(GameState.ledger, site.display_name)
	_note(Renown.greeting(world, site.cell, GameState.roster.player().display_name))
	match site.kind:
		Site.HOME:
			_sleep_at_home(site)
		Site.VILLAGE, Site.KEEP, Site.HUT:
			_rest_at(site)
		Site.LIBRARY:
			_read_at(site)
		Site.GATE:
			_enter_gate(site)
		Site.TOWER:
			_climb(site)
		Site.GRAVE:
			_stand_at_grave(site)
	_check_for_captives(site)


func _stand_at_grave(site: Site) -> void:
	for line: String in Memorial.visit(site, world, GameState.party_characters()):
		_note(line)


## Anyone of yours being held here can be bought back, or taken back.
func _check_for_captives(site: Site) -> void:
	for character in GameState.roster.characters:
		if character.status != Fate.CAPTURED:
			continue
		if Captivity.held_at(character) != site.cell:
			continue
		_captive_here = character
		var price := int(character.captive.get("ransom", 0))
		_note("%s is being held here. They want %d gold." % [character.display_name, price])
		return


func _rest_at(site: Site) -> void:
	if Town.is_ruined(site):
		_note("%s is a burnt shell. Nothing is traded here now." % site.display_name)
		return
	if Town.is_threatened(site):
		_note("%s is being sacked as you walk in. There is no resting here." % site.display_name)
		return

	var rested := GameState.party_is_wounded()
	if rested:
		GameState.heal_party()
		_note("You rest at %s. Everyone is patched up." % site.display_name)
	else:
		_note("%s is quiet." % site.display_name)
	Banter.shared(GameState.party_characters(), int(Banter.rules().get("bond_per_rest", 1)))
	if not rested:
		_talk(Banter.REST, true)
	if site.kind != Site.HUT:
		Market.refresh(site, world)
	Errand.refresh(site, world)
	Grimoire.stock(site, world)
	if rested:
		_make_camp(site)


## A rest that was needed is a night, and a night is spent at the fire, where
## the party can finally look at each other.
func _make_camp(site: Site) -> void:
	_busy = true
	EventBus.request_scene.emit("area", {
		"area_id": "camp",
		"title": "%s — the fire" % site.display_name,
		"return_scene": "world",
	})


## Your own roof. Nothing is sold here and nothing waits here — you sleep, and
## the bed you sleep on is the one thing about the party you can build.
func _sleep_at_home(site: Site) -> void:
	for line: String in Home.sleep(site, GameState.roster):
		_note(line)


func _read_at(site: Site) -> void:
	Grimoire.stock(site, world)
	for line: String in Trivia.maybe_discover(world, "discovery_chance_library"):
		_note(line)

	var doctrine_id: String = site.data.get("doctrine", "")
	if doctrine_id == "":
		_note("The shelves at %s are bare." % site.display_name)
		return

	var learned := false
	for character in GameState.party_characters():
		if Doctrine.learn(character, doctrine_id, world.steps):
			_note("%s reads %s." % [character.display_name, Doctrine.title(doctrine_id)])
			learned = true
			break
	if not learned:
		_note("Everyone here has already read %s." % Doctrine.title(doctrine_id))


func _enter_gate(site: Site) -> void:
	if site.cleared:
		_note("%s is shut for good." % site.display_name)
		return
	if not site.open:
		_note("%s is shut." % site.label())
		return

	var party := GameState.party_characters()
	_note("%s stands open." % site.label())
	_begin_battle(Encounter.for_gate(world, site, 0, true, party, world.rng))
	# Shutting a gate is permanent; nothing behind it comes back.
	world.close_gate(site)
	for line: String in Spoils.for_gate(world, site, party):
		_note(line)


func _climb(site: Site) -> void:
	if world.tower_is_topped():
		_note("You have already stood on the last floor.")
		return

	var next_floor := world.tower_floor + 1
	_note("The Tower opens onto floor %d of %d." % [next_floor, world.tower_floors()])
	world.tower_floor = next_floor
	_begin_battle(Encounter.for_tower(world, site, next_floor, GameState.party_characters(), world.rng))
	for line: String in Spoils.for_tower_floor(world, next_floor, GameState.party_characters()):
		_note(line)

	if world.tower_is_topped():
		world.tower_topped = true
		Renown.record(
			world, Renown.TOWER_TOPPED, site.cell,
			int(Renown.rules().get("tower_topped", 8)), "somebody reached the top of the Tower"
		)
		_note("There are no more floors above you.")


# --- party --------------------------------------------------------------------


func _check_party() -> void:
	for character in GameState.roster.party_members():
		for forgotten: String in Doctrine.decay(character, world.steps):
			_note("%s can no longer recall %s." % [character.display_name, Doctrine.title(forgotten)])

	# Nobody waits forever for their friends.
	for character in GameState.roster.characters:
		if Captivity.is_overdue(character, world):
			if Captivity.resolve_deadline(character, world) == Captivity.SOLD:
				_note("%s was sold on. They are not coming back." % character.display_name)
			else:
				_note("%s is still being held, and the price has gone up." % character.display_name)

	if GameState.roster.run_is_over():
		_end_run()
		return

	_hint.text = _prompt()


## The one line at the bottom telling you what you can do where you stand.
func _prompt() -> String:
	var choosing := GameState.roster.awaiting_class_choice()
	if choosing != null:
		return "%s is ready to choose a path — press P." % choosing.display_name

	if _captive_here != null:
		return "R to ransom %s for %d gold  ·  F to take them back by force." % [
			_captive_here.display_name, int(_captive_here.captive.get("ransom", 0))
		]

	var site := world.site_at(world.player_cell)
	if site != null:
		if site.kind == Site.HOME:
			return _home_prompt(site)
		var parts: Array[String] = []
		if Town.is_threatened(site):
			parts.append("V to drive them out of %s" % site.display_name)
		elif Town.is_settlement(site) and not Town.is_ruined(site):
			parts.append("K to raid %s" % site.display_name)
		if _area_here() != "":
			parts.append("E to walk into %s" % site.display_name)
		var errand_line := _errand_prompt(site)
		if errand_line != "":
			parts.append(errand_line)
		var offer := Market.hire_offer(site)
		if not offer.is_empty():
			parts.append("H to hire %s (level %d, %d gold)" % [
				offer["display_name"], offer["level"], Market.asking_hire_cost(site, world, offer)
			])
		var goods := Market.wares(site)
		if not goods.is_empty():
			parts.append("B to buy %s (%d gold)" % [
				Database.equipment_piece(goods[0]).get("display_name", goods[0]),
				Market.asking_price(site, world, goods[0]),
			])
		if not Grimoire.offer(site).is_empty():
			parts.append("G for the book, unread (%d gold)" % Grimoire.price(site))
		if not parts.is_empty():
			return "  ·  ".join(parts)

	return "P for the party  ·  Esc for the menu"


## What the board where you are standing has to say, if anything.
func _errand_prompt(site: Site) -> String:
	if not Errand.completable_at(GameState.errands, site.cell).is_empty():
		return "J to settle an errand"
	if not Errand.board(site).is_empty():
		return "J to read the board"
	return ""


## Home has no board and no trader — only the bed, and what a better one costs.
func _home_prompt(site: Site) -> String:
	var better := Home.next_bed(site)
	if better.is_empty():
		return "%s  ·  there is nothing better to sleep on  ·  P for the party" % Home.bed_name(site)
	return "%s  ·  U for %s (%d gold, +%d HP)" % [
		Home.bed_name(site),
		better.get("display_name", "a better bed").to_lower(),
		int(better.get("cost", 0)),
		int(better.get("vigour", 0)),
	]


## Permadeath follows the player. Companions come and go, and some of them do
## not get to see the end of it.
func _end_run() -> void:
	_busy = true
	_note("%s falls, and the story stops here." % GameState.roster.player().display_name)
	_hint.text = ""
	EventBus.run_ended.emit()
	await get_tree().create_timer(RUN_OVER_DELAY).timeout
	EventBus.request_scene.emit("summary", {})


func _unhandled_input(event: InputEvent) -> void:
	if _busy or not event.is_pressed() or event.is_echo() or not event is InputEventKey:
		return
	match event.keycode:
		KEY_P:
			get_viewport().set_input_as_handled()
			EventBus.party_screen_requested.emit()
		KEY_H:
			get_viewport().set_input_as_handled()
			_hire_here()
		KEY_B:
			get_viewport().set_input_as_handled()
			_buy_here()
		KEY_J:
			get_viewport().set_input_as_handled()
			_errands_here()
		KEY_G:
			get_viewport().set_input_as_handled()
			_buy_grimoire_here()
		KEY_R:
			get_viewport().set_input_as_handled()
			_ransom_here()
		KEY_F:
			get_viewport().set_input_as_handled()
			_fight_for_captive()
		KEY_U:
			get_viewport().set_input_as_handled()
			_upgrade_bed_here()
		KEY_V:
			get_viewport().set_input_as_handled()
			_defend_here()
		KEY_K:
			get_viewport().set_input_as_handled()
			_raid_here()
		KEY_E:
			get_viewport().set_input_as_handled()
			_walk_into_site()


## Places big enough to walk around in have an area of the same name as their
## kind under `data/areas`; the rest are only a tile on the map.
func _area_here() -> String:
	var site := world.site_at(world.player_cell)
	if site == null:
		return ""
	var area_id: String = site.data.get("area", site.kind)
	return area_id if Database.has_area(area_id) else ""


func _walk_into_site() -> void:
	var area_id := _area_here()
	if area_id == "":
		return
	var site := world.site_at(world.player_cell)
	_busy = true
	EventBus.request_scene.emit("area", {
		"area_id": area_id,
		"title": site.label(),
		"return_scene": "world",
	})


func _hire_here() -> void:
	var site := world.site_at(world.player_cell)
	if site == null:
		return
	var offer := Market.hire_offer(site)
	if offer.is_empty():
		return
	if GameState.roster.party.size() >= Roster.MAX_PARTY:
		_note("You have nobody to spare a place for.")
		return

	var hired := Market.hire(site, GameState.roster, world)
	if hired == null:
		_note("You cannot afford %d gold." % Market.asking_hire_cost(site, world, offer))
		return
	_note("%s falls in with you." % hired.display_name)
	_refresh()
	_hint.text = _prompt()


func _buy_here() -> void:
	var site := world.site_at(world.player_cell)
	if site == null:
		return
	var goods := Market.wares(site)
	if goods.is_empty():
		return

	var equipment_id: String = goods[0]
	var name: String = Database.equipment_piece(equipment_id).get("display_name", equipment_id)
	if not Market.buy(site, equipment_id, GameState.roster.player(), world):
		_note("You cannot afford the %s." % name)
		return
	_note("%s takes up the %s." % [GameState.roster.player().display_name, name])
	_refresh()
	_hint.text = _prompt()


## Answer the raid on somebody else's town. Winning is the whole reward, and it
## is the fastest way to be known for something.
func _defend_here() -> void:
	var site := world.site_at(world.player_cell)
	if site == null or not Town.is_threatened(site):
		return
	_note("You put yourself between %s and the people taking it apart." % site.display_name)
	_begin_battle(Encounter.for_siege(world, site, GameState.party_characters(), world.rng))
	for line: String in Town.save(site, world):
		_note(line)
	_refresh()


## The other thing you can do to a town. It pays better and it costs more.
func _raid_here() -> void:
	var site := world.site_at(world.player_cell)
	if site == null or not Town.is_settlement(site) or Town.is_ruined(site):
		return
	if Town.is_threatened(site):
		_note("Somebody is already sacking %s." % site.display_name)
		return
	_note("You draw on %s." % site.display_name)
	_begin_battle(Encounter.for_town_guard(world, site, GameState.party_characters(), world.rng))
	for line: String in Town.raid(site, world, GameState.roster):
		_note(line)
	_refresh()


## The board: settle what you have finished, or take what is pinned to it.
func _errands_here() -> void:
	var site := world.site_at(world.player_cell)
	if site == null:
		return

	var finished := Errand.completable_at(GameState.errands, site.cell)
	if not finished.is_empty():
		for line: String in Errand.turn_in(GameState.errands, finished, world):
			_note(line)
		_refresh()
		_hint.text = _prompt()
		return

	var taken := Errand.accept(site, GameState.errands, world)
	if taken.is_empty():
		if GameState.errands.size() >= Errand.max_accepted():
			_note("You have as much to be getting on with as you can carry.")
		else:
			_note("Nothing is pinned to the board at %s." % site.display_name)
	else:
		_note("%s asks: %s" % [taken["giver"], taken["title"]])
		_note(Errand.detail(taken))
	_map.queue_redraw()
	_refresh()
	_hint.text = _prompt()


## Buy the book without knowing what it is. That is the whole transaction.
func _buy_grimoire_here() -> void:
	var site := world.site_at(world.player_cell)
	if site == null or Grimoire.offer(site).is_empty():
		return
	for line: String in Grimoire.buy_and_read(site, GameState.roster.player(), world):
		_note(line)
	_refresh()
	_hint.text = _prompt()


## Buy the next bed up and try it out, since you are already standing in it.
func _upgrade_bed_here() -> void:
	var site := world.site_at(world.player_cell)
	if site == null or site.kind != Site.HOME:
		return
	var bought := Home.next_bed(site)
	for line: String in Home.upgrade(site):
		_note(line)
	if not bought.is_empty() and Home.bed(site) == bought:
		_sleep_at_home(site)
	_refresh()
	_hint.text = _prompt()


func _ransom_here() -> void:
	if _captive_here == null:
		return
	var price := int(_captive_here.captive.get("ransom", 0))
	if not Captivity.ransom(_captive_here, GameState.roster):
		_note("They want %d gold and you do not have it." % price)
		return
	_note("%s is bought back for %d gold." % [_captive_here.display_name, price])
	_captive_here = null
	_refresh()
	_hint.text = _prompt()


## The other way to get someone back. Surviving it is the price.
func _fight_for_captive() -> void:
	if _captive_here == null:
		return
	var freed := _captive_here
	var site := world.site_at(world.player_cell)
	_note("You come for %s the hard way." % freed.display_name)
	_begin_battle(Encounter.for_captors(world, site, GameState.party_characters(), world.rng))
	Captivity.free_by_force(freed, GameState.roster)
	_captive_here = null
	_refresh()


# --- presentation -------------------------------------------------------------


func _centre_camera() -> void:
	_camera.position = Vector2(world.player_cell) * CELL + Vector2.ONE * CELL * 0.5
	_camera.enabled = true


## Two of them say something to each other. On the road it goes up over the
## party as a speech bubble and into the log, so walking is never interrupted;
## once the party has stopped, it gets the box.
func _talk(occasion: String, stopped: bool) -> void:
	if _busy:
		return
	var exchange := Banter.pick(world, GameState.party_characters(), occasion, world.rng)
	if exchange.is_empty():
		return
	if stopped:
		EventBus.conversation_requested.emit(exchange)
		return
	for line: String in Banter.as_lines(exchange):
		_note(line)
	_speak_bubbles(exchange)


## One bubble over the party's marker at a time, since out here the whole band
## is a single dot on the map.
func _speak_bubbles(exchange: Array) -> void:
	if is_instance_valid(_bubble):
		_bubble.queue_free()
	_bubble = SpeechBubble.create(CELL * 0.5)
	_map.add_child(_bubble)
	_follow_party()
	for line: Dictionary in exchange:
		if not is_instance_valid(_bubble):
			return
		_bubble.say("%s: %s" % [line.get("speaker", ""), line.get("text", "")])
		await get_tree().create_timer(SpeechBubble.time_for(line.get("text", ""))).timeout


func _follow_party() -> void:
	if is_instance_valid(_bubble):
		_bubble.position = Vector2(world.player_cell) * CELL + Vector2.ONE * CELL * 0.5


func _road_talk() -> void:
	if world.steps % maxi(1, int(Banter.rules().get("road_interval", 12))) != 0:
		return
	if world.rng.randf() >= float(Banter.rules().get("road_chance", 0.4)):
		return
	_talk(Banter.ROAD, false)


func _note(line: String) -> void:
	_notices.append(line)
	if _notices.size() > 4:
		_notices = _notices.slice(_notices.size() - 4)
	_log.text = "\n".join(_notices)


func _refresh() -> void:
	_follow_party()
	var site := world.site_at(world.player_cell)
	var where: String = site.label() if site != null else world.terrain_at(world.player_cell).get("name", "open ground")
	_place.text = "%s  ·  %s  ·  %d gold  ·  step %d  ·  %d bands abroad" % [
		where, str(world.player_cell), GameState.gold, world.steps, world.prowlers.size()
	]

	var entries: Array[String] = []
	for character in GameState.roster.party_members():
		entries.append("%s L%d %d/%d" % [
			character.display_name, character.level, character.current_hp(), character.max_hp()
		])
	for errand: Dictionary in GameState.errands:
		entries.append(Errand.summary(errand))
	_party.text = "  ·  ".join(entries)


## Runs inside the Map node's draw pass, so its draw_* calls are legal here.
func _draw_world() -> void:
	for y in world.size.y:
		for x in world.size.x:
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(cell) * CELL, Vector2.ONE * CELL)
			_map.draw_rect(rect, Color(world.terrain_at(cell).get("color", "#4f7d3f")))

	# Ground somebody has eyes on. Walk onto it and the fight has already started.
	for band: Prowler in world.prowlers:
		for watched: Vector2i in band.watched(world):
			_map.draw_rect(
				Rect2(Vector2(watched) * CELL, Vector2.ONE * CELL), Color(0.85, 0.18, 0.18, 0.3)
			)

	for site in world.sites:
		var centre := Vector2(site.cell) * CELL + Vector2.ONE * CELL * 0.5
		var colour: Color = SITE_COLOURS.get(site.kind, Color.WHITE)
		_map.draw_rect(Rect2(Vector2(site.cell) * CELL, Vector2.ONE * CELL), Color(0, 0, 0, 0.45))
		_map.draw_circle(centre, CELL * 0.34, colour)
		if site.kind == Site.GATE and site.open:
			_map.draw_arc(centre, CELL * 0.48, 0.0, TAU, 20, colour, 2.0, true)
		if site.kind == Site.GRAVE:
			_map.draw_line(centre + Vector2(0, -CELL * 0.3), centre + Vector2(0, CELL * 0.3), Color(0.15, 0.15, 0.18), 2.0)
			_map.draw_line(centre + Vector2(-CELL * 0.2, -CELL * 0.1), centre + Vector2(CELL * 0.2, -CELL * 0.1), Color(0.15, 0.15, 0.18), 2.0)
		if site.kind == Site.HOME:
			var roof := Color(0.22, 0.13, 0.1)
			_map.draw_line(centre + Vector2(-CELL * 0.3, -CELL * 0.02), centre + Vector2(0, -CELL * 0.34), roof, 2.0)
			_map.draw_line(centre + Vector2(0, -CELL * 0.34), centre + Vector2(CELL * 0.3, -CELL * 0.02), roof, 2.0)

	# Where the errands point. Nobody drew you a map, but you know roughly.
	for errand: Dictionary in GameState.errands:
		var pair: Array = errand.get("to", [])
		if pair.size() < 2 or Errand.is_complete(errand):
			continue
		var mark := Vector2(int(pair[0]), int(pair[1])) * CELL + Vector2.ONE * CELL * 0.5
		_map.draw_arc(mark, CELL * 0.42, 0.0, TAU, 16, Color(0.95, 0.88, 0.55, 0.85), 2.0, true)

	for band: Prowler in world.prowlers:
		var camp := Vector2(band.cell) * CELL + Vector2.ONE * CELL * 0.5
		_map.draw_circle(camp, CELL * 0.3, Color(0.85, 0.22, 0.22))
		_map.draw_arc(camp, CELL * 0.3, 0.0, TAU, 20, Color(0.2, 0.05, 0.05), 2.0, true)

	var player := Vector2(world.player_cell) * CELL + Vector2.ONE * CELL * 0.5
	_map.draw_circle(player, CELL * 0.3, Color(0.98, 0.95, 0.85))
	_map.draw_arc(player, CELL * 0.3, 0.0, TAU, 20, Color(0.1, 0.1, 0.12), 2.0, true)