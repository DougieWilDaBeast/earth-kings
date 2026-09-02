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
## Lines of world log kept on screen. Everything still happens when it is off;
## the log is a record, not the game.
const LOG_LINES := 3
## Seconds between steps while the party is walking itself.
const AUTO_DELAY := 0.09
## How far the party will turn aside for a band while walking itself. The road
## to anywhere is thick with them, so chasing every one means never arriving.
const AUTO_DETOUR := 6

const DIRECTIONS := {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
}

## Cells tall a place is drawn, so a keep overhangs the tile it sits on.
const SITE_SCALE := 2.1
## Cells tall a person is drawn on the map.
const MARKER_SCALE := 1.2

var boot_payload: Dictionary = {}

@onready var _map: Node2D = $Map
@onready var _camera: CameraRig = $Camera2D
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
## The way the party was last walking itself, so auto does not pace on the spot.
var _auto_last: Vector2i = Vector2i.ZERO
## Map art kept between redraws, since the whole map is redrawn every step.
var _art: Dictionary = {}
## Where the camera was last time the ground was laid out (x, y, zoom).
var _last_view: Vector3 = Vector3.INF


func _ready() -> void:
	world = GameState.world
	Encounter.restock(world, world.rng)
	if world.steps == 0:
		Encounter.first_blood(world, world.rng)
	_warm_art()
	_map.draw.connect(_draw_world)
	_map.queue_redraw()
	_camera.frame(Rect2(Vector2.ZERO, Vector2(world.size) * CELL))
	_centre_camera(true)
	_refresh()

	if GameState.has_flag("last_victory"):
		_note("You are still standing.")
		# Coming through a fight together is worth something to the people who did.
		Banter.shared(GameState.party_characters(), int(Banter.rules().get("bond_per_battle", 1)))
		_talk(Banter.AFTER_BATTLE, true)
	_settle_up(GameState.has_flag("last_victory"))
	if not GameState.has_flag("seen:watched_ground"):
		GameState.set_flag("seen:watched_ground")
		_note("Red ground is being watched. Step onto it and you have been seen.")
	GameState.set_flag("last_victory", false)
	_check_party()

	if world.steps == 0 and not GameState.has_flag("seen:prologue"):
		GameState.set_flag("seen:prologue")
		EventBus.dialogue_requested.emit("prologue")


func _process(delta: float) -> void:
	_watch_the_view()
	if _busy:
		return
	if Pace.auto:
		_auto_walk(delta)
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


# --- walking itself -----------------------------------------------------------


## Soak mode: head for whatever is worth reaching and keep walking into it.
func _auto_walk(delta: float) -> void:
	_repeat_timer -= delta
	if _repeat_timer > 0.0:
		return
	_repeat_timer = AUTO_DELAY
	var direction := _auto_direction(_auto_errand())
	if direction == Vector2i.ZERO:
		return
	_auto_last = direction
	_step(direction)


## What the party walks towards when nobody is steering: a fight worth the
## detour, then the nearest gate still standing, then the Tower.
func _auto_errand() -> Vector2i:
	var target := Vector2i(-1, -1)
	var best := AUTO_DETOUR + 1
	for band: Prowler in world.prowlers:
		var reach := Pathfinder.distance(band.cell, world.player_cell)
		if reach < best:
			best = reach
			target = band.cell
	if target.x >= 0:
		return target

	best = 1 << 30
	for site in world.sites:
		if site.kind != Site.GATE or not site.open or site.cleared:
			continue
		if Pace.avoided.has(site.cell):
			continue
		var reach := Pathfinder.distance(site.cell, world.player_cell)
		if reach < best:
			best = reach
			target = site.cell
	if target.x >= 0:
		return target

	var tower := world.tower()
	if tower == null or world.tower_is_topped() or Pace.avoided.has(tower.cell):
		return Vector2i(-1, -1)
	return tower.cell


## A greedy step towards [param target]: the longer axis first, the other axis
## when that is walled, and anything at all rather than stand still.
func _auto_direction(target: Vector2i) -> Vector2i:
	var options: Array[Vector2i] = []
	if target.x >= 0:
		var apart := target - world.player_cell
		var horizontal := Vector2i(signi(apart.x), 0)
		var vertical := Vector2i(0, signi(apart.y))
		if absi(apart.x) >= absi(apart.y):
			options.append_array([horizontal, vertical])
		else:
			options.append_array([vertical, horizontal])
	for option: Vector2i in options:
		if option != Vector2i.ZERO and world.is_walkable(world.player_cell + option):
			return option

	# Walled in on the way there, so shake loose without doubling straight back.
	var loose: Array[Vector2i] = []
	for offset: Vector2i in DIRECTIONS.values():
		if world.is_walkable(world.player_cell + offset) and offset != -_auto_last:
			loose.append(offset)
	if loose.is_empty():
		return -_auto_last if world.is_walkable(world.player_cell - _auto_last) else Vector2i.ZERO
	return loose[world.rng.randi() % loose.size()]


# --- walking ------------------------------------------------------------------


func _step(direction: Vector2i) -> void:
	var target := world.player_cell + direction
	if not world.is_walkable(target):
		return

	var was_at_the_tower := _standing_at_the_tower()
	world.player_cell = target
	if was_at_the_tower and not _standing_at_the_tower():
		_carry_the_hoard_out()
	_captive_here = null
	for notice: String in world.step():
		_note(notice)
	for notice: String in Errand.on_arrive(GameState.errands, target, world):
		_note(notice)
	for notice: String in Skein.on_arrive(world, target, world.site_at(target)):
		_note(notice)
	# The country fills its empty stretches back in while you are looking away.
	if world.steps % RESTOCK_INTERVAL == 0:
		Encounter.restock(world, world.rng)
		# New bands mean new faces, and a face first loaded mid-draw comes out white.
		_warm_art()
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


func _begin_battle(meeting: Dictionary, outcome: Dictionary = {}) -> void:
	_busy = true
	if Pace.auto:
		Pace.avoided[world.player_cell] = true
	GameState.pending_outcome = outcome
	_note(meeting["title"])
	EventBus.request_scene.emit("battle", {"encounter": meeting, "return_scene": "world"})


## Nothing a fight was worth is handed over until the fight has been won. The
## scene swap is deferred, so anything written here rather than after the call
## to [method _begin_battle] would otherwise be paid out win or lose.
func _settle_up(won: bool) -> void:
	var outcome := GameState.pending_outcome
	GameState.pending_outcome = {}
	if outcome.is_empty():
		return
	if not won:
		_note(str(outcome.get("lost", "You came away with nothing.")))
		if str(outcome.get("kind", "")) == "tower" and world.tower_hoard > 0:
			_note("%d gold goes down the stair with everything else you were carrying." % world.tower_hoard)
			world.tower_hoard = 0
		if str(outcome.get("kind", "")) == "gate":
			_lose_the_ground(world.site_at(outcome.get("cell", world.player_cell)))
		return

	var party := GameState.party_characters()
	var cell: Vector2i = outcome.get("cell", world.player_cell)
	var site := world.site_at(cell)
	match str(outcome.get("kind", "")):
		"gate":
			if site == null:
				return
			if not bool(outcome.get("final", true)):
				site.data["depth"] = site.depth() + 1
				_note("%s gives up a floor. %d of %d behind you." % [
					site.display_name, site.depth(), site.floors()
				])
				for line: String in Spoils.for_gate_floor(world, site, party):
					_note(line)
			else:
				world.close_gate(site)
				for line: String in Spoils.for_gate(world, site, party):
					_note(line)
		"tower":
			world.tower_floor = int(outcome.get("floor", world.tower_floor))
			for line: String in Spoils.for_tower_floor(world, world.tower_floor, party):
				_note(line)
			if world.tower_is_topped() and not world.tower_topped:
				world.tower_topped = true
				Renown.record(
					world, Renown.TOWER_TOPPED, cell,
					int(Renown.rules().get("tower_topped", 8)), "somebody reached the top of the Tower"
				)
				_note("There are no more floors above you.")
		"siege":
			if site == null:
				return
			for line: String in Town.save(site, world):
				_note(line)
		"raid":
			if site == null:
				return
			for line: String in Town.raid(site, world, GameState.roster):
				_note(line)
		"captive":
			var freed := GameState.roster.by_id(str(outcome.get("character", "")))
			if freed == null:
				return
			Captivity.free_by_force(freed, GameState.roster)
			_note("%s walks out with you." % freed.display_name)
	_map.queue_redraw()
	_refresh()


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
	var depth := site.depth()
	var final := site.is_final_floor()
	if site.floors() > 1:
		_note("%s, floor %d of %d." % [site.label(), depth + 1, site.floors()])
		if depth > 0:
			_note("Lose down here and you come out at the mouth of it again.")
	else:
		_note("%s stands open." % site.label())

	# Shutting a gate is permanent, so it only shuts once the last floor is won.
	_begin_battle(
		Encounter.for_gate(world, site, depth, final, party, world.rng),
		{
			"kind": "gate", "cell": site.cell, "final": final,
			"lost": "%s is still standing open." % site.display_name,
		}
	)


func _climb(site: Site) -> void:
	if world.tower_is_topped():
		_note("You have already stood on the last floor.")
		return

	var next_floor := world.tower_floor + 1
	_note("The Tower opens onto floor %d of %d." % [next_floor, world.tower_floors()])
	if world.tower_hoard > 0:
		_note("You are still carrying %d gold. Lose here and it stays here." % world.tower_hoard)
	_begin_battle(
		Encounter.for_tower(world, site, next_floor, GameState.party_characters(), world.rng),
		{
			"kind": "tower", "cell": site.cell, "floor": next_floor,
			"lost": "You come back down to the floor you started on.",
		}
	)


## A delve you walk out of keeps the floors you took; a delve you lose does not.
## You are carried back to the mouth of it and it fills in behind you.
func _lose_the_ground(site: Site) -> void:
	if site == null or site.depth() <= 0:
		return
	site.data["depth"] = 0
	_note("%s closes over the way you came. You are back at the mouth of it." % site.display_name)


## Walking off the Tower's step is what banks an ascent. Nothing else does, so
## every extra floor is a decision about what you are already holding.
func _carry_the_hoard_out() -> void:
	if world.tower_hoard <= 0:
		return
	var carried := world.tower_hoard
	world.tower_hoard = 0
	GameState.gold += carried
	_note("You walk away from the Tower with %d gold." % carried)


func _standing_at_the_tower() -> bool:
	var site := world.site_at(world.player_cell)
	return site != null and site.kind == Site.TOWER


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
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		EventBus.system_menu_requested.emit()
		return
	# Before the pace keys: walking into a place is what the player came here to
	# do, and E was quietly being eaten by the speed cycle.
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_walk_into_site()
		return
	if event.is_action_pressed("battle_auto"):
		get_viewport().set_input_as_handled()
		Pace.auto = not Pace.auto
		_note("The party walks itself." if Pace.auto else "You take the party back.")
		_refresh()
		return
	if event.is_action_pressed("battle_speed"):
		get_viewport().set_input_as_handled()
		Pace.cycle_speed()
		_refresh()
		return
	match event.keycode:
		KEY_P:
			get_viewport().set_input_as_handled()
			EventBus.party_screen_requested.emit()
		KEY_N:
			get_viewport().set_input_as_handled()
			EventBus.journal_requested.emit()
		KEY_L:
			get_viewport().set_input_as_handled()
			_log.visible = not _log.visible
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


## Places big enough to walk around in have an area of the same name as their
## kind under `data/areas`; the rest are only a tile on the map.
func _area_here() -> String:
	var site := world.site_at(world.player_cell)
	if site == null:
		return ""
	var area_id: String = site.data.get("area", site.kind)
	return area_id if Database.has_area(area_id) else ""


func _walk_into_site() -> void:
	var site := world.site_at(world.player_cell)
	var area_id := _area_here()
	if area_id == "":
		# Most places on the map have no inside yet. Say so, rather than
		# swallowing the key and reading as broken.
		_note(
			"There is no way into %s." % site.display_name if site != null
			else "There is nothing here to walk into."
		)
		return
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
	_begin_battle(
		Encounter.for_siege(world, site, GameState.party_characters(), world.rng),
		{"kind": "siege", "cell": site.cell, "lost": "%s is left to them." % site.display_name}
	)


## The other thing you can do to a town. It pays better and it costs more.
func _raid_here() -> void:
	var site := world.site_at(world.player_cell)
	if site == null or not Town.is_settlement(site) or Town.is_ruined(site):
		return
	if Town.is_threatened(site):
		_note("Somebody is already sacking %s." % site.display_name)
		return
	_note("You draw on %s." % site.display_name)
	_begin_battle(
		Encounter.for_town_guard(world, site, GameState.party_characters(), world.rng),
		{"kind": "raid", "cell": site.cell, "lost": "%s drives you back out." % site.display_name}
	)


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
	_begin_battle(
		Encounter.for_captors(world, site, GameState.party_characters(), world.rng),
		{
			"kind": "captive", "cell": world.player_cell, "character": freed.id,
			"lost": "%s is still being held." % freed.display_name,
		}
	)
	_captive_here = null


# --- presentation -------------------------------------------------------------


func _centre_camera(immediate: bool = false) -> void:
	_camera.focus_on(Vector2(world.player_cell) * CELL + Vector2.ONE * CELL * 0.5, immediate)


## Two of them say something to each other. On the road it goes up over the
## party as a speech bubble and into the log, so walking is never interrupted;
## once the party has stopped, it gets the box.
func _talk(occasion: String, stopped: bool) -> void:
	if _busy:
		return
	var exchange := Banter.pick(world, GameState.party_characters(), occasion, world.rng)
	if exchange.is_empty():
		return
	# Banter is not a conversation the player asked for, so it is allowed to be
	# demoted to the log and a bubble (see [Pace]).
	if stopped and not Pace.quiet_banter:
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
	if _notices.size() > LOG_LINES:
		_notices = _notices.slice(_notices.size() - LOG_LINES)
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
	var pace := _pace_text()
	if pace != "":
		entries.append(pace)
	_party.text = "  ·  ".join(entries)


## Says out loud that the game is driving itself, so a soak is never mistaken
## for the controls having stopped answering.
func _pace_text() -> String:
	var parts: Array[String] = []
	if Pace.auto:
		parts.append("walking itself")
	if Pace.speed() != 1.0:
		parts.append("x%s" % String.num(Pace.speed(), 1).trim_suffix(".0"))
	return " ".join(parts)


## Runs inside the Map node's draw pass, so its draw_* calls are legal here.
func _draw_world() -> void:
	_draw_ground()
	_draw_watched_ground()
	_draw_places()
	_draw_errand_marks()
	_draw_bands()
	_draw_party()


## The ground is drawn to the camera, so panning or zooming has to redraw it.
## Compared rather than hooked, because the rig moves by tween as well as by key.
func _watch_the_view() -> void:
	var now := Vector3(
		_camera.get_screen_center_position().x,
		_camera.get_screen_center_position().y,
		_camera.zoom.x
	)
	if now.distance_squared_to(_last_view) < 1.0:
		return
	_last_view = now
	_map.queue_redraw()


## A single flat green for every grass tile reads as a spreadsheet. Each cell
## gets a fixed wobble in brightness and whatever its terrain grows.
##
## Only what the camera can see is drawn. The country is far too large to lay
## out in full every time somebody takes a step.
func _draw_ground() -> void:
	var seen := _cells_in_view()
	for y in range(seen.position.y, seen.end.y):
		for x in range(seen.position.x, seen.end.x):
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(cell) * CELL, Vector2.ONE * CELL)
			var terrain := world.terrain_at(cell)
			_map.draw_rect(rect, Color(terrain.get("color", "#4f7d3f")) * _shade(cell))
			_dress(cell, world.terrain_id_at(cell))


## The block of cells the camera has in front of it, clamped to the map and
## grown by a tile so nothing pops in at the edge of the screen.
func _cells_in_view() -> Rect2i:
	var span := get_viewport_rect().size / _camera.zoom
	var origin := _camera.get_screen_center_position() - span * 0.5
	var first := Vector2i((origin / CELL).floor()) - Vector2i.ONE
	var last := Vector2i(((origin + span) / CELL).ceil()) + Vector2i.ONE
	first = first.clamp(Vector2i.ZERO, world.size)
	last = last.clamp(Vector2i.ZERO, world.size)
	return Rect2i(first, last - first)


## Deterministic, so the country does not shimmer as you walk across it.
func _shade(cell: Vector2i) -> Color:
	var lift := 0.92 + float(absi(hash(cell)) % 1000) / 1000.0 * 0.16
	return Color(lift, lift, lift, 1.0)


## What grows on a tile, drawn from the cell's own hash so it stays put.
func _dress(cell: Vector2i, terrain_id: String) -> void:
	var seed_value := absi(hash(cell))
	var origin := Vector2(cell) * CELL
	match terrain_id:
		"brush":
			for i in 3:
				var at := origin + _scatter(seed_value, i)
				_map.draw_circle(at, CELL * 0.1, Color(0.18, 0.32, 0.16, 0.7))
		"crag":
			if seed_value % 2 == 0:
				var chip := origin + _scatter(seed_value, 7)
				var span := CELL * 0.17
				_map.draw_colored_polygon(
					PackedVector2Array([
						chip + Vector2(-span, span * 0.5),
						chip + Vector2(-span * 0.4, -span),
						chip + Vector2(span * 0.8, -span * 0.3),
						chip + Vector2(span * 0.3, span * 0.7),
					]),
					Color(0.42, 0.42, 0.4, 0.55)
				)
		"hill":
			# Only some of the ridge shows, or high ground reads as corduroy.
			if seed_value % 3 == 0:
				var ridge := origin + Vector2(CELL * 0.18, CELL * 0.3 + float(seed_value % 6))
				_map.draw_line(ridge, ridge + Vector2(CELL * 0.6, 0), Color(1, 1, 1, 0.08), 1.0)
		"water":
			if seed_value % 2 == 0:
				var wave := origin + _scatter(seed_value, 3)
				_map.draw_line(wave, wave + Vector2(CELL * 0.26, 0), Color(1, 1, 1, 0.14), 1.0)
		"grass":
			if seed_value % 5 == 0:
				_map.draw_circle(origin + _scatter(seed_value, 2), CELL * 0.06, Color(0.32, 0.48, 0.26, 0.55))
		"forest":
			# Denser and darker than brush, so a wood reads as somewhere to go round.
			for i in 4:
				var trunk := origin + _scatter(seed_value, i)
				_map.draw_circle(trunk, CELL * 0.13, Color(0.13, 0.26, 0.12, 0.8))
		"snow":
			if seed_value % 3 == 0:
				_map.draw_circle(origin + _scatter(seed_value, 4), CELL * 0.07, Color(1, 1, 1, 0.5))
		"sand":
			if seed_value % 2 == 0:
				var dune := origin + _scatter(seed_value, 5)
				_map.draw_line(dune, dune + Vector2(CELL * 0.3, 0), Color(1, 0.94, 0.78, 0.3), 1.0)
		"marsh":
			for i in 2:
				var tuft := origin + _scatter(seed_value, i + 2)
				_map.draw_circle(tuft, CELL * 0.08, Color(0.3, 0.38, 0.25, 0.7))
		"ocean", "lake":
			if seed_value % 4 == 0:
				var swell := origin + _scatter(seed_value, 6)
				_map.draw_line(swell, swell + Vector2(CELL * 0.3, 0), Color(1, 1, 1, 0.09), 1.0)


func _scatter(seed_value: int, index: int) -> Vector2:
	var a := float((seed_value >> (index * 3)) % 100) / 100.0
	var b := float((seed_value >> (index * 3 + 5)) % 100) / 100.0
	return Vector2(0.18 + a * 0.64, 0.18 + b * 0.64) * CELL


## Ground somebody has eyes on, in the colours of whoever is watching it.
func _draw_watched_ground() -> void:
	for band: Prowler in world.prowlers:
		var wash := Faction.banner(band.faction)
		wash.a = 0.26
		for watched: Vector2i in band.watched(world):
			_map.draw_rect(Rect2(Vector2(watched) * CELL, Vector2.ONE * CELL), wash)


func _draw_places() -> void:
	for site in world.sites:
		var art := _site_art(site)
		var centre := Vector2(site.cell) * CELL + Vector2.ONE * CELL * 0.5
		if art == null:
			_map.draw_circle(centre, CELL * 0.34, Site.COLOURS.get(site.kind, Color.WHITE))
			continue

		# Stood on the bottom edge of its tile, so the tile still reads as the
		# thing you walk onto and the building rises up behind it.
		var size := Vector2.ONE * CELL * SITE_SCALE
		var foot := Vector2(site.cell) * CELL + Vector2(CELL * 0.5, CELL * 0.95)
		_map.draw_texture_rect(
			art, Rect2(foot - Vector2(size.x * 0.5, size.y * 0.88), size), false, _site_tint(site)
		)
		if site.kind == Site.GATE and site.open:
			_map.draw_arc(centre, CELL * 0.55, 0.0, TAU, 24, Color(0.95, 0.35, 0.3, 0.9), 2.0, true)


## A place looks like what has happened to it: shut gates go dark, burnt towns
## go grey, and a town being sacked is lit by it.
func _site_tint(site: Site) -> Color:
	if site.kind == Site.GATE and site.cleared:
		return Color(0.45, 0.45, 0.5)
	if Town.is_ruined(site):
		return Color(0.42, 0.38, 0.36)
	if Town.is_threatened(site):
		return Color(1.25, 0.72, 0.55)
	return Color.WHITE


func _site_art(site: Site) -> Texture2D:
	var path := ""
	if site.kind == Site.GATE or site.kind == Site.KEEP:
		path = Faction.hold_art(str(site.data.get("faction", "")))
	if path == "":
		path = str(Site.ART.get(site.kind, ""))
	if path == "":
		return null
	if not _art.has(path):
		_art[path] = load(path) if ResourceLoader.exists(path) else null
	return _art[path]


## Everything the map is about to draw, loaded up front. A texture that first
## reaches the GPU part-way through a draw pass is drawn as a white rectangle,
## so nothing here may be loaded lazily from inside [method _draw_world].
func _warm_art() -> void:
	for site in world.sites:
		_site_art(site)
	for band: Prowler in world.prowlers:
		if not band.pack.is_empty():
			Database.unit_face(band.pack[0])
	for character in GameState.roster.characters:
		Database.unit_face(character.template_id)


## Where the errands point. Nobody drew you a map, but you know roughly.
func _draw_errand_marks() -> void:
	for errand: Dictionary in GameState.errands:
		var pair: Array = errand.get("to", [])
		if pair.size() < 2 or Errand.is_complete(errand):
			continue
		var mark := Vector2(int(pair[0]), int(pair[1])) * CELL + Vector2.ONE * CELL * 0.5
		_map.draw_arc(mark, CELL * 0.42, 0.0, TAU, 16, Color(0.95, 0.88, 0.55, 0.85), 2.0, true)


## Bands are drawn as whoever is leading them, so the country tells you what is
## in it before you are close enough to be told the hard way.
func _draw_bands() -> void:
	for band: Prowler in world.prowlers:
		var centre := Vector2(band.cell) * CELL + Vector2.ONE * CELL * 0.5
		_map.draw_circle(centre, CELL * 0.42, Faction.banner(band.faction))
		var face: Texture2D = Database.unit_face(band.pack[0]) if not band.pack.is_empty() else null
		if face == null:
			_map.draw_circle(centre, CELL * 0.26, Color(0.12, 0.08, 0.09))
			continue
		var size := Vector2.ONE * CELL * MARKER_SCALE
		_map.draw_texture_rect(face, Rect2(centre - size * Vector2(0.5, 0.78), size), false)


func _draw_party() -> void:
	var centre := Vector2(world.player_cell) * CELL + Vector2.ONE * CELL * 0.5
	_map.draw_circle(centre, CELL * 0.44, Color(0.98, 0.95, 0.85, 0.85))
	_map.draw_arc(centre, CELL * 0.44, 0.0, TAU, 24, Color(0.12, 0.1, 0.12), 2.0, true)
	var lead := GameState.roster.player()
	var face: Texture2D = Database.unit_face(lead.template_id) if lead != null else null
	if face == null:
		return
	var size := Vector2.ONE * CELL * MARKER_SCALE
	_map.draw_texture_rect(face, Rect2(centre - size * Vector2(0.5, 0.78), size), false)