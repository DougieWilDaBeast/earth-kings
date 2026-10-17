extends Node2D
## The continent: the engine every step runs through, and the map of it.
##
## The game is played on the ground, in the planar view ([D50], [D61]). This
## scene opens three ways:
## - **Ground** (the usual): the ground has handed it a step, a place's action
##   or a return from a fight. It does what the continent does on that step —
##   bands, roadside scenes, rests, gates — out of sight, then hands play
##   straight back to the ground the party now stands on.
## - **Map** (`"map": true`, from the journal): the explored continent, to look
##   at and nothing else. Esc goes back to the ground where the party stood.
## - **Out of sight** (`"embedded": true`, [D84]): run by the game beside the land, which never
##   leaves the screen. It takes the step or does the place's doing as on the ground, then answers
##   on [signal EventBus.continent_answered] instead of handing the ground back, and goes.
## - **Walk**: the old walkable continent, kept for the suites that drive it
##   (`"walk": true`, or a scene nobody put on screen). A party walking itself
##   walks the ground like anyone else ([D94]).
##
## Every step advances the world clock, so travel is never free.

## Loaded by path: see its header for why it has no `class_name`.
const Dispatch := preload("res://src/chronicle/dispatch.gd")
const Names := preload("res://src/chronicle/names.gd")
const AutoRoad := preload("res://src/world/auto_road.gd")
const Chapters := preload("res://src/chronicle/chapters.gd")
const Guild := preload("res://src/chronicle/guild.gd")
const RunMode := preload("res://src/chronicle/run_mode.gd")
const Seats := preload("res://src/chronicle/seats.gd")
const Fall := preload("res://src/chronicle/fall.gd")
const Wanderers := preload("res://src/chronicle/wanderers.gd")
const Siblings := preload("res://src/chronicle/siblings.gd")
const Treasure := preload("res://src/chronicle/treasure.gd")
const Crossing := preload("res://src/chronicle/crossing.gd")
const WorldEnd := preload("res://src/world/world_end.gd")
const Atlas := preload("res://src/chronicle/atlas.gd")
const Biome := preload("res://src/chronicle/biome.gd")
const GroundGen := preload("res://src/area/ground_gen.gd")

const CELL := 24
## Seconds between steps while a direction is held down.
const REPEAT_DELAY := 0.11
const FIRST_REPEAT_DELAY := 0.28
## Beat between the last of the party falling and the title screen.
const RUN_OVER_DELAY := 3.0
## Steps between the country putting fresh bands out where you cannot see them.
const RESTOCK_INTERVAL := 12
## How many tiles away a band can be and still be walking on the land round the party ([D84]).
const LAND_BANDS_REACH := 2
## Lines of world log kept on screen. Everything still happens when it is off;
## the log is a record, not the game.
const LOG_LINES := 3
## Seconds between steps while the party is walking itself.
const AUTO_DELAY := 0.09
## How far the party will turn aside for a band while walking itself.
const AUTO_DETOUR := AutoRoad.DETOUR
## Seconds a tile takes to fade in when it comes onto the map.
const REVEAL_FADE := 0.45
## How dark ground drawn from somebody else's map is left: the lie of the
## land, but nothing walking on it.
const CHARTED_WASH := Color(0.03, 0.03, 0.05, 0.58)
const UNKNOWN := Color(0.02, 0.02, 0.03)

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
## Tall enough for a thumb. The action buttons are only built for touch, so
## nothing else on the map has to make room for them.
const ACTION_BUTTON_HEIGHT := 56
## How far the bottom-left text moves over to clear the touch overlay's stick.
const STICK_CLEARANCE := 220.0
## Where the top line has to stop to clear the touch overlay's bar.
const BAR_CLEARANCE := 750.0

var boot_payload: Dictionary = {}

enum View { WALK, GROUND, MAP }

## What a step on the ground hands over to be done here, by the method that
## does it, and what to press for it there: an input action, or a bare key.
## Anything not listed cannot be asked for from the ground.
const GROUND_ACTS := {
	"_step_into_the_road": "interact",
	"_walk_into_site": "interact",
	"_climb_here": "interact",
	"_enter_gate_here": "interact",
	"_ransom_here": "captive_ransom",
	"_fight_for_captive": "captive_rescue",
	"_hire_here": "site_hire",
	"_buy_here": "site_buy",
	"_next_ware": KEY_Z,
	"_errands_here": "site_errands",
	"_buy_grimoire_here": "site_grimoire",
	"_open_guild": "site_guild",
	"_defend_here": KEY_V,
	"_raid_here": KEY_K,
	"_sail_here": KEY_O,
	"_speak_with_wanderer": KEY_X,
	"_upgrade_bed_here": KEY_U,
	"_step_into_the_wild": "interact",
}
@onready var _map: Node2D = $Map
@onready var _camera: CameraRig = $Camera2D
@onready var _season_icon: TextureRect = %SeasonIcon
@onready var _place: Label = %PlaceLabel
@onready var _party: Label = %PartyLabel
@onready var _log: Label = %LogLabel
@onready var _hint: Label = %HintLabel
@onready var _actions: HFlowContainer = %ActionBar

var world: World
var _notices: Array[String] = []
var _repeat_timer: float = 0.0
var _held: Vector2i = Vector2i.ZERO
var _busy: bool = false
## Whatever the party are saying to each other as they walk, if anything.
var _bubble: SpeechBubble = null
## Someone of yours being held at the tile you are standing on.
var _captive_here: Character = null
## A scene happening in front of the party that they have not answered yet.
var _roadside_here: String = ""
## The town the party was last saved in for arriving, `{ world, cell }`, so walking in and out over
## a city's edge is one save, not one a crossing ([D197]: eleven in four minutes at Stormreach).
## Forgotten once the party is more than [constant AWAY_FROM_TOWN] tiles off, so the next coming in
## is an arrival again. Kept between scenes, since the ground asks for a fresh continent each step.
static var _saved_in_town: Dictionary = {}
const AWAY_FROM_TOWN := 3
## A secluded wilderness clearing discovered on open ground.
var _wild_here: String = ""
## A cache found on this step, for the ground to put down where it can be seen and picked up
## (Ewan's play-test 2: gold arrived with nothing on screen).
var _cache_found: Dictionary = {}
## Map art kept between redraws, since the whole map is redrawn every step.
var _art: Dictionary = {}
## Where the camera was last time the ground was laid out (x, y, zoom).
var _last_view: Vector3 = Vector3.INF
## Tiles fading onto the map, cell -> seconds of fade left.
var _fading: Dictionary = {}
var _view: View = View.WALK
## Where the party stood when this scene opened, to tell whether anything done
## here moved them.
var _entered_at: Vector2i = Vector2i(-1, -1)


func _enter_tree() -> void:
	if bool(boot_payload.get("embedded", false)):
		$Camera2D.claims_the_view = false
		$UI.visible = false


func _ready() -> void:
	world = GameState.world
	# A lead has died and ascended: this is the last look at their world (M15).
	if bool(boot_payload.get("world_ends", false)):
		EventBus.place_entered.emit("world_ends")
		_watch_it_end()
		return
	_view = _opened_as()
	_entered_at = world.player_cell
	_hold_again(boot_payload.get("held", {}))
	# Only a world nobody has stood in yet is stocked here. This scene opens again
	# on every load and after every fight; topping up then too put a fresh round
	# of bands out each time (the count jumped on Continue). After the first
	# stocking, the country refills on the step clock alone (RESTOCK_INTERVAL).
	if world.steps == 0 and world.prowlers.is_empty():
		Encounter.restock(world, world.rng)
		Encounter.first_blood(world, world.rng)
	_warm_art()
	# The ground the party stands on is always on the map ([D50]).
	Atlas.reveal_around(world, world.player_cell)
	EventBus.ground_revealed.connect(_on_ground_revealed)
	_map.draw.connect(_draw_world)
	_map.queue_redraw()
	for edge: Signal in [
		EventBus.system_menu_requested, EventBus.party_screen_requested,
		EventBus.journal_requested, EventBus.stash_requested, EventBus.guild_requested,
		EventBus.how_to_play_requested,
		EventBus.overlay_closed,
	]:
		edge.connect(_watch_overlays)
	EventBus.dialogue_requested.connect(func(_id: String) -> void: _watch_overlays())
	EventBus.dialogue_finished.connect(func(_id: String) -> void: _watch_overlays())
	EventBus.conversation_requested.connect(func(_lines: Array) -> void: _watch_overlays())
	EventBus.game_saved.connect(_on_game_saved)
	_camera.frame(Rect2(Vector2.ZERO, Vector2(world.size) * CELL))
	_centre_camera(true)
	# Picking up the pad, or putting it down, changes every key the hint line
	# names and whether the buttons under it are there at all.
	Pad.changed.connect(_say_what_can_be_done)
	var view_btn: Button = get_node_or_null("%ViewButton")
	if view_btn != null:
		# The map's only way back for a thumb. Anywhere else there is nothing
		# to switch to: the ground is the game.
		view_btn.visible = _view == View.MAP
		view_btn.text = "Back to the ground (Esc)"
		view_btn.pressed.connect(_close_map)
		Sfx.attend(view_btn)
		# The touch overlay keeps its own bar in the top right, and two things
		# in one corner means one of them cannot be pressed.
		if Pace.is_touch_enabled():
			view_btn.offset_top += TouchControls.BAR_DROP
			view_btn.offset_bottom += TouchControls.BAR_DROP
	if Pace.is_touch_enabled():
		# The stick sits in the bottom left corner, over the log and the hint
		# line, so both step out from under it.
		_log.offset_left += STICK_CLEARANCE
		_hint.offset_left += STICK_CLEARANCE
		# And the top line runs far enough right to go under the overlay's bar,
		# so it is cut where the bar starts rather than drawn beneath it.
		for line: Label in [_place, _party]:
			line.offset_right = BAR_CLEARANCE
			line.clip_text = true
	_watch_overlays()
	_refresh()

	if GameState.has_flag("last_victory"):
		_note("You are still standing.")
		# Coming through a fight together is worth something to the people who did.
		Banter.shared(GameState.party_characters(), int(Banter.rules().get("bond_per_battle", 1)))
		_talk(Banter.AFTER_BATTLE, true)
	_settle_up(GameState.has_flag("last_victory"))
	GameState.set_flag("last_victory", false)
	_check_party()

	# A new run opens on the fall: where the lead came down, and why they will
	# be walking towards the Tower (M13).
	if world.steps == 0 and not GameState.has_flag("seen:prologue"):
		GameState.set_flag("seen:prologue")
		var lead := GameState.roster.player()
		var landing := Fall.landing_dialogue(world, lead.display_name if lead != null else "The fallen", lead.template_id if lead != null else "")
		# In a world after the first, word of whoever went before (M15).
		(landing["lines"] as Array).append_array(Siblings.landing_lines(world))
		Database.register_dialogue("landing", landing)
		EventBus.dialogue_requested.emit("landing")
		if Fall.landing_note() != "":
			_note(Fall.landing_note())

	match _view:
		View.MAP:
			_open_as_map()
		View.GROUND:
			_show_the_map(false)
			_do_what_the_ground_asked()


func _process(delta: float) -> void:
	_watch_the_view()
	_fade_in(delta)
	if _busy:
		return
	if _view != View.WALK:
		return
	if Pace.auto:
		_auto_walk(delta)
		return
	if _picking_an_action():
		_held = Vector2i.ZERO
		return
	var direction := _pressed_direction()
	# A stick held to walk a menu is not walking the party behind it.
	if direction == Vector2i.ZERO or _overlay_open():
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
	var direction := AutoRoad.next_step(world)
	if direction == Vector2i.ZERO:
		return
	_step(direction)


## The next step along the way to [param target] (see [code]auto_road.gd[/code]).
func _auto_direction(target: Vector2i) -> Vector2i:
	return AutoRoad.direction(world, target)


# --- walking ------------------------------------------------------------------


func _step(direction: Vector2i) -> void:
	var target := world.player_cell + direction
	if not world.is_walkable(target):
		return
	# Between a gate's floors a step away is walking out of it, with the floors won kept; walking
	# back in goes on with the next (D115; [D35] made every step the next floor, which dropped
	# Ewan into Fenport's second floor as he tried to leave, meeting 4).
	_walk_out_of_the_gate()

	var was_at_the_tower := _standing_at_the_tower()
	var prior_region := world.region_at(world.player_cell)
	# Asked before the step: arriving can move the objective on (a town stood in).
	var goal := AutoRoad.objective(world) if Pace.auto else {}
	# Leaving the tile you were offered something on is how you turn it down.
	if _roadside_here != "":
		for line: String in Roadside.walk_by(world, world.player_cell, _roadside_here):
			_note(line)
		_roadside_here = ""
	_wild_here = ""
	world.player_cell = target
	if not _saved_in_town.is_empty() and (int(_saved_in_town["world"]) != world.get_instance_id() \
			or Pathfinder.distance(target, _saved_in_town["cell"]) > AWAY_FROM_TOWN):
		_saved_in_town = {}
	var current_region := world.region_at(target)
	if current_region != prior_region:
		_note("Entering %s." % current_region)
	if was_at_the_tower and not _standing_at_the_tower():
		_carry_the_hoard_out()
	_captive_here = null
	for notice: String in world.step():
		_note(notice)
	for notice: String in Errand.on_arrive(GameState.errands, target, world):
		_note(notice)
	for notice: String in Roadside.on_arrive(world, world.site_at(target), GameState.party_characters()):
		_note(notice)
	for notice: String in Skein.on_arrive(world, target, world.site_at(target)):
		_note(notice)
	for notice: String in Siblings.on_arrive(world, target):
		_note(notice)
	# The country fills its empty stretches back in while you are looking away.
	if world.steps % RESTOCK_INTERVAL == 0:
		Encounter.restock(world, world.rng)
		# New bands mean new faces, and a face first loaded mid-draw comes out white.
		_warm_art()
	# Out of sight the talk is the ground's to have, over the party's heads.
	if _view != View.GROUND:
		_road_talk()
	_centre_camera()
	_map.queue_redraw()

	var site := world.site_at(target)
	if site != null:
		_arrive_at(site)
	elif not _dig_for_treasure(target):
		_look_for_a_cache(target)
		_check_wild_exploration(target)
	else:
		_check_wild_exploration(target)
	_watch_check(target)
	_look_down_the_road(target)
	_hand_back_at(goal, target)
	_check_party()
	_refresh()
	EventBus.tip_moment.emit("step", {
		"danger": Encounter.chance_at(world, target), "steps": world.steps,
		"season_turned": Season.just_turned(world.steps) and not FirstHour.hides("seasons"),
	})


## A party walking itself to the objective stops there and hands the player
## back the reins, where nothing starts by itself (a town; an errand's end).
func _hand_back_at(goal: Dictionary, cell: Vector2i) -> void:
	if not Pace.auto or goal.is_empty() or not bool(goal.get("stop", false)) or goal["cell"] != cell:
		return
	# On the ground the party walks on across the tile to the Tower's door and stops there ([D197]).
	if bool(goal.get("door", false)) and _embedded():
		return
	Pace.auto = false
	_note("You have reached %s. %s to walk on by yourself." % [goal["label"], _key("battle_auto")])


## Somebody else's fight, in front of you, that you did not cause and do not
## have to take. It waits on the tile: walking off is how you refuse it.
func _look_down_the_road(cell: Vector2i) -> void:
	if _busy:
		return
	var found := Roadside.look(world, cell)
	if found == "":
		return
	_roadside_here = found
	# A party walking itself would pace straight past somebody dying.
	Pace.auto = false
	_note(Roadside.title(found))
	EventBus.conversation_requested.emit(_as_conversation(Roadside.seen(found)))


## Step in. The purse and everything after it waits on winning.
func _step_into_the_road() -> void:
	if _roadside_here == "" or _busy:
		return
	var found := _roadside_here
	_roadside_here = ""
	_begin_battle(
		Roadside.meeting(world, world.player_cell, found, GameState.party_characters(), world.rng),
		{ "kind": "roadside", "event": found, "cell": world.player_cell,
		  "lost": "You are driven off, and they finish what they started." }
	)


func _step_into_the_wild() -> void:
	if _wild_here == "" or _busy:
		return
	var area_id := _wild_here
	_wild_here = ""
	_busy = true
	EventBus.request_scene.emit("area", {
		"area_id": area_id,
		"title": "The Wilds (%s)" % world.region_at(world.player_cell),
		"return_scene": "world",
		"planar_mode": true,
	})


## What kind of place hides in what kind of country. Ordinary ground is not all
## one ground, so the way into it should not always open on the same clearing.
const WILD_AREAS := {
	"forest": ["wild_grove", "wild_thicket"],
	"brush": ["wild_thicket", "wild_grove"],
	"marsh": ["wild_fen"],
	"hill": ["wild_scarp"],
	"sand": ["wild_oasis"],
}


func _check_wild_exploration(cell: Vector2i) -> void:
	if _busy or _roadside_here != "":
		return
	var t := world.terrain_id_at(cell)
	if not WILD_AREAS.has(t):
		return
	if world.distance_to_haven(cell) <= 4:
		return
	# Deterministic tile hash so we never consume RNG and shift seeded suites
	var h := absi((cell.x * 73856093 ^ cell.y * 19349663 ^ world.world_seed)) % 100
	if h >= 6:
		return
	var pool: Array = WILD_AREAS[t]
	_wild_here = pool[h % pool.size()]
	_note(_wild_opening(t))


func _wild_opening(terrain: String) -> String:
	match terrain:
		"marsh":
			return "A line of duckboards runs off the track into the reeds."
		"hill":
			return "A goat path switches back up the rock towards the shelf."
		"brush":
			return "There is a gap in the thorn, and it has been kept open."
		"sand":
			return "A line of palms marks a hidden spring sheltered between the dunes."
	return "A sheltered path winds through the boughs into an ancient grove."


func _as_conversation(lines: Array) -> Array:
	var out: Array = []
	for line: String in lines:
		out.append({ "speaker": "", "text": line })
	return out


## Standing on the X the map pieces made ([D220]): the find, laid on the ground to be picked up when
## walking it, or paid in when not. True when there was one here.
func _dig_for_treasure(cell: Vector2i) -> bool:
	var haul := Treasure.dig(world, cell)
	if haul.is_empty():
		return false
	var said := str(haul.get("line", ""))
	if _view == View.GROUND:
		_cache_found = haul
		_note(said)
		return true
	_note(said)
	for line: String in Loot.claim(haul, GameState.roster):
		_note(line)
	return true


## Country nobody is watching still has things left lying about in it. The
## worse the ground, the better what was left behind — and the likelier its
## owner did not walk away.
func _look_for_a_cache(cell: Vector2i) -> void:
	if _busy or world.rng.randf() >= float(Loot.rules().get("cache_chance", 0.04)):
		return
	var haul := Loot.roll(world, 0.5 + Encounter.chance_at(world, cell) * 2.0)
	haul["map"] = bool(haul.get("map", false)) or Atlas.finds_map(world, cell, "cache_map_chance")
	if _view == View.GROUND:
		# On the ground it lies there to be seen and picked up, not paid in out of sight.
		_cache_found = haul
		_note("Something has been left here, and left a long while. It lies on the ground close by.")
		return
	_note("Something has been left here, and left a long while.")
	for line: String in Loot.claim(haul, GameState.roster):
		_note(line)


## The only way a fight starts in the open: somebody was watching the tile you
## just walked onto. They come off the map, because they are in front of you now.
func _watch_check(cell: Vector2i) -> void:
	# On the ground the band is standing there in front of you, with the ground
	# it watches painted red; walking into that is what starts it ([D66]).
	if _busy or _view == View.GROUND:
		return
	var band := world.prowler_watching(cell)
	if band == null:
		return
	world.prowlers.erase(band)
	_map.queue_redraw()
	var meeting := Encounter.for_band(world, band, GameState.party_characters(), world.rng)
	var terrain := world.terrain_id_at(cell)
	if terrain in ["brush", "forest", "marsh"] or band.cell == cell:
		meeting["ambush"] = true
	_begin_battle(meeting, { "kind": "band", "cell": cell })


func _begin_battle(meeting: Dictionary, outcome: Dictionary = {}, extra: Dictionary = {}) -> void:
	_busy = true
	outcome["enemies"] = meeting.get("enemies", [])
	GameState.pending_outcome = outcome
	_note(meeting["title"])
	var confrontation := Nemesis.check_confrontation(world, meeting)
	if confrontation != "":
		meeting["confrontation"] = confrontation
		_note(confrontation)
	var payload := {"encounter": meeting, "return_scene": "world"}
	payload.merge(extra, true)
	if _embedded() and not payload.has("field") and boot_payload.has("field"):
		# A gate gone into from the ground (D162): fought there, at its doorway, by whoever the
		# Guild sent along too.
		payload["field"] = _field_for_meeting(meeting, boot_payload["field"])
	if _embedded() and payload.has("field"):
		# Out of sight beside the ground: the ground fights it where it was met, with no change of
		# screen, and asks again afterwards to have it settled (step 4 of the First Hour).
		payload["in_place"] = true
		EventBus.continent_answered.emit({ "fight": payload })
		queue_free()
		return
	EventBus.request_scene.emit("skirmish", payload)


## The patch of ground the ground laid out, with what this meeting brings to it beyond the band:
## the Guild's people (D147) and, on a heart floor, the heart at the doorway.
func _field_for_meeting(meeting: Dictionary, field: Dictionary) -> Dictionary:
	var out := field.duplicate(true)
	var laid: Dictionary = meeting.get("map", {})
	var allies: Array = []
	for each: Dictionary in laid.get("allies", []):
		var ally := each.duplicate()
		ally.erase("cell")
		allies.append(ally)
	if not allies.is_empty():
		out["allies"] = allies
	if str(meeting.get("objective", "")) != Site.OBJECTIVE_HEART:
		out.erase("heart")
	return out


## Nothing a fight was worth is handed over until the fight has been won. The
## scene swap is deferred, so anything written here rather than after the call
## to [method _begin_battle] would otherwise be paid out win or lose.
func _settle_up(won: bool) -> void:
	var outcome := GameState.pending_outcome
	GameState.pending_outcome = {}
	if outcome.is_empty():
		return
	var fled := GameState.has_flag("last_fled")
	GameState.set_flag("last_fled", false)
	if fled:
		# Walked off the field: nothing won, nothing lost but whoever was left on it, and the band
		# is still out there.
		var band: Variant = outcome.get("band", null)
		if band is Prowler and not world.prowlers.has(band):
			world.prowlers.append(band)
		if Pace.auto:
			Pace.avoided[outcome.get("cell", world.player_cell)] = true
		_note("You get clear of them. They are still out there.")
		return
	for notice: String in Skein.on_battle(world, { "victory": won, "kind": str(outcome.get("kind", "")) }):
		_note(notice)
	if not won:
		# A party walking itself would walk straight back into it, for ever.
		# Only a lost fight: a won Tower floor is the way to the next one.
		if Pace.auto:
			Pace.avoided[outcome.get("cell", world.player_cell)] = true
		_note(str(outcome.get("lost", "You came away with nothing.")))
		if str(outcome.get("kind", "")) == "tower" and world.tower_hoard > 0:
			_note("%d gold goes down the stair with everything else you were carrying." % world.tower_hoard)
			world.tower_hoard = 0
		if str(outcome.get("kind", "")) == "gate":
			_lose_the_ground(world.site_at(outcome.get("cell", world.player_cell)))
		return

	var party := GameState.party_characters()
	var cell: Vector2i = outcome.get("cell", world.player_cell)
	var survivor_line := Nemesis.on_battle_won(world, outcome.get("enemies", []), cell)
	if survivor_line != "":
		_note(survivor_line)

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
				GameState.delving = [site.cell.x, site.cell.y]
				_note("Floor %d of %s waits below: E to go down, or walk away and come back later." % [
					site.depth() + 1, site.display_name
				])
			else:
				GameState.delving = []
				var was_sealed := world.tower_sealed_at >= 0
				world.close_gate(site)
				Annals.record(world, "The %s-rank gate at %s was shut forever." % [site.rank, site.display_name])
				for line: String in Spoils.for_gate(world, site, party):
					_note(line)
				for line: String in Errand.on_gate_shut(GameState.errands, site.cell, world):
					_note(line)
				for line: String in Guild.on_gate_shut(world, site):
					_note(line)
				# A gate is a seam between the sixteen worlds (D152): as it shuts, someone may be on the far side.
				var crossing := Crossing.on_gate_shut(world, site)
				if crossing != "":
					EventBus.dialogue_requested.emit(crossing)
				# A shut gate says it counted (meeting 4): the Guild's mark, or a chapter's seal broken.
				if was_sealed and not Chapters.sealed(world):
					_note("Sennet will have your name in the Guild's register: the Tower's door is open to you." \
						if world.tower_floor <= 0 else "The Tower counts it: the stair above is open again.")
				EventBus.safe_point_reached.emit.call_deferred(RunMode.GATE, "you shut %s" % site.display_name)
		"tower":
			world.tower_floor = int(outcome.get("floor", world.tower_floor))
			for line: String in Spoils.for_tower_floor(world, world.tower_floor, party):
				_note(line)
			# Tower ascents take time in the outside world: each floor advances one upkeep interval
			world.steps += World.UPKEEP_INTERVAL
			for notice: String in world._upkeep():
				_note(notice)
			if Chapters.ends_chapter(world, world.tower_floor):
				var company: Array = []
				for hero: Character in GameState.roster.characters:
					company.append(hero.template_id)
				for line: String in FirstHour.put_out_a_light(world, world.tower_floor, company):
					_note(line)
				for line: String in Chapters.turn(world, world.tower_floor):
					_note(line)
				# Once the whole fight is settled, not halfway through it.
				EventBus.safe_point_reached.emit.call_deferred(
					RunMode.CHAPTER, "chapter %d of the Tower closed" % Chapters.chapter_of(world.tower_floor)
				)
				_open_seats()
			if world.tower_is_topped() and not world.tower_topped:
				world.tower_topped = true
				var hoard := world.tower_hoard
				world.tower_hoard = 0
				GameState.gold += hoard
				Renown.record(
					world, Renown.TOWER_TOPPED, cell,
					int(Renown.rules().get("tower_topped", 8)) * 2,
					"the company conquered the pinnacle of the Tower"
				)
				Annals.record(world, "The company stood upon the summit of the Tower, claiming %d gold." % hoard)
				_note("The clouds part over the continent. You stand atop the conquered Tower! %d gold claimed from the hoard." % hoard)
				for hero: Character in party:
					hero.hearth_vigour += 8
				_celebrate_tower_conquest()
		"siege":
			if site == null:
				return
			Annals.record(world, "%s was defended against siege." % site.display_name)
			for line: String in Town.save(site, world):
				_note(line)
		"raid":
			if site == null:
				return
			Annals.record(world, "%s was raided and sacked by the company." % site.display_name)
			for line: String in Town.raid(site, world, GameState.roster):
				_note(line)
		"captive":
			var freed := GameState.roster.by_id(str(outcome.get("character", "")))
			if freed == null:
				return
			Captivity.free_by_force(freed, GameState.roster)
			Annals.record(world, "%s was freed from captivity by force." % freed.display_name)
			_note("%s walks out with you." % freed.display_name)
		"roadside":
			var lines := Roadside.saved(world, cell, str(outcome.get("event", "")), party)
			for line: String in lines:
				_note(line)
			EventBus.conversation_requested.emit(_as_conversation(lines))
		"band":
			# A torn piece of somebody's treasure map, now and then ([D220]).
			for line: String in Treasure.on_band_beaten(world, cell):
				_note(line)
	_map.queue_redraw()
	_refresh()


## A Tower chapter won may earn the company another seat (agenda item 35).
## The moment is made something of: a banner, a few lines at the fire, and
## anyone who came back from a job to a full company falls in first.
func _open_seats() -> void:
	var roster := GameState.roster
	if Seats.sync(world, roster) <= 0:
		return
	var lines := Seats.opened_lines(roster, world.tower_floor)
	for line: String in lines:
		_note(line)
	for line: String in _call_back_the_waiting():
		_note(line)
	Annals.record(world, "Floor %d of the Tower won the company a seat: %d could march together from then on." % [
		world.tower_floor, roster.seats
	])
	EventBus.party_seat_opened.emit(roster.seats)
	_show_banner(str(Seats.rules().get("banner", "")).format({ "seats": str(roster.seats) }))
	Sfx.play(Sfx.SELECT)
	EventBus.conversation_requested.emit(_as_conversation(lines))


## Companions who came back from a job to find no room have been waiting by
## the fire; a new seat is theirs before it is anyone's for hire.
func _call_back_the_waiting() -> Array[String]:
	var lines: Array[String] = []
	var roster := GameState.roster
	for character: Character in roster.characters:
		if not roster.has_room():
			break
		if character.id in roster.party or not character.is_available():
			continue
		if not Dispatch.job_for(GameState.away, character.id).is_empty():
			continue
		if roster.enlist(character.id):
			lines.append("%s has been waiting by the fire, and takes the seat." % character.display_name)
	return lines


## A line across the top of the screen that holds a beat and goes.
func _show_banner(text: String) -> void:
	if text == "":
		return
	var banner := Label.new()
	banner.text = text
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.anchor_left = 0.0
	banner.anchor_right = 1.0
	banner.anchor_top = 0.18
	banner.anchor_bottom = 0.18
	banner.offset_top = -30
	banner.offset_bottom = 30
	banner.add_theme_font_size_override("font_size", 32)
	banner.add_theme_color_override("font_color", Color(0.965, 0.827, 0.443))
	banner.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.06))
	banner.add_theme_constant_override("outline_size", 8)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.modulate.a = 0.0
	_hint.get_parent().add_child(banner)
	var tween := create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.5)
	tween.tween_interval(3.5)
	tween.tween_property(banner, "modulate:a", 0.0, 1.0)
	tween.tween_callback(banner.queue_free)


func _celebrate_tower_conquest() -> void:
	var lead := GameState.roster.player()
	var who: String = lead.display_name if lead != null else "The company"
	var lines: Array = [
		"%s stands upon the highest stone in Earth Kings." % who,
		"All %d floors of the Tower have fallen. The wind over the sea is clear." % world.tower_floors(),
		"Press E on the Tower to conclude this journey in the Museum, or walk on as an ascended champion."
	]
	for line: String in lines:
		_note(line)
	EventBus.conversation_requested.emit(_as_conversation(lines))


# --- places -------------------------------------------------------------------


func _arrive_at(site: Site) -> void:
	Ledger.record_place(GameState.ledger, site.display_name)
	if Town.is_settlement(site) and site.kind != Site.HUT and not Town.is_ruined(site):
		var first_town := not GameState.has_flag(AutoRoad.TOWN_REACHED)
		GameState.set_flag(AutoRoad.TOWN_REACHED)
		# AU (D161): the first time in, Sennet says where the Guild's mark is earned.
		var next := AutoRoad.objective(world)
		var gate := world.site_at(next.get("cell", Vector2i(-1, -1))) if first_town else null
		if gate != null and gate.kind == Site.GATE:
			var line := FirstHour.gate_line(gate.display_name)
			if line != "":
				_note("Sennet: " + line)
				EventBus.conversation_requested.emit([{ "speaker": "Sennet", "text": line }])
		if _saved_in_town.get("cell", Vector2i(-1, -1)) != site.cell or int(_saved_in_town.get("world", 0)) != world.get_instance_id():
			_saved_in_town = { "world": world.get_instance_id(), "cell": site.cell }
			EventBus.safe_point_reached.emit.call_deferred(RunMode.TOWN, "you reached %s" % site.display_name)
	# Word travels by the name people gave you, not the one you gave them.
	_note(Renown.greeting(world, site.cell, Names.known_as(world, GameState.roster.player().display_name)))
	match site.kind:
		Site.HOME:
			_sleep_at_home(site)
		Site.VILLAGE, Site.KEEP, Site.HUT:
			_rest_at(site)
		Site.LIBRARY:
			_read_at(site)
		Site.GATE:
			# The gate is gone into when asked for, with E beside it (D116): walking onto its tile, or
			# back onto it, never starts the fight. A party walking itself came here to go in: on the
			# ground it goes in from there, so the fight is fought where it stands (D162).
			if Pace.auto and not _embedded():
				_enter_gate(site)
		Site.TOWER:
			# The Guild's doorkeeper opens the register when spoken to, and the compass points at
			# him until then (D107; meeting 3: it no longer opens by itself outside the wall).
			# Standing at the Tower's foot is not going in (D95): the stair is
			# climbed when asked for. A party walking itself came here to climb.
			# A floor that is walked is walked by hand: Auto stops at the door (D102).
			var walked := Chapters.walked_floor_area(world.tower_floor + 1) != ""
			if (Pace.auto and not walked) or world.tower_is_topped() or Chapters.sealed(world):
				_climb(site)
		Site.GRAVE:
			_stand_at_grave(site)
	for line: String in Wanderers.on_arrive(world, site):
		_note(line)
	_check_for_captives(site)
	_say_what_is_new_here(site)


## Places a newcomer may never have stood in before, said out loud for whatever
## teaches them (the tip card). Nobody here knows whether anyone listens.
func _say_what_is_new_here(site: Site) -> void:
	if Town.is_settlement(site) and not Town.is_ruined(site):
		EventBus.tip_moment.emit("settlement", {})
	if Guild.has_hall(site):
		EventBus.tip_moment.emit("guild", {})
	if site.kind in [Site.GATE, Site.LIBRARY, Site.TOWER, Site.HOME]:
		EventBus.tip_moment.emit(site.kind, {})


func _stand_at_grave(site: Site) -> void:
	for line: String in Memorial.visit(site, world, GameState.party_characters()):
		_note(line)


## Anyone of yours being held here can be bought back, or taken back.
func _check_for_captives(site: Site) -> void:
	_captive_here = _captive_at(site)
	if _captive_here == null:
		return
	var price := int(_captive_here.captive.get("ransom", 0))
	_note("%s is being held here. They want %d gold." % [_captive_here.display_name, price])


func _captive_at(site: Site) -> Character:
	for character in GameState.roster.characters:
		if character.status == Fate.CAPTURED and Captivity.held_at(character) == site.cell:
			return character
	return null


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
	# Settlements talk, and some of what they say is about the others who fell.
	if site.kind != Site.HUT and randf() < float(Wanderers.pace().get("rumour_at_rest", 0.4)):
		var word := Wanderers.rumour(world)
		if word != "":
			_note(word)
			_map.queue_redraw()
	# Something out of the sky is the first thing anybody talks about (M15).
	if site.kind != Site.HUT and Siblings.heard_weapons(world).is_empty():
		var fallen := Siblings.rumour(world)
		if fallen != "":
			_note(fallen)
			_map.queue_redraw()
	if rested:
		EventBus.safe_point_reached.emit(RunMode.REST, "you rested at %s" % site.display_name)
		# A town's night is spent in the town you walked into, not at a fire somewhere else (Ewan's
		# play-test 2: arriving at Stormreach put him at a campfire that felt like another world).
		if site.kind == Site.HUT:
			_make_camp(site)
		else:
			_talk(Banter.REST, true)


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
	EventBus.safe_point_reached.emit(RunMode.REST, "you slept at %s" % site.display_name)


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


## Won a floor and stepping away: out of the gate, the floors won kept, and said so.
func _walk_out_of_the_gate() -> void:
	if GameState.delving.size() < 2:
		return
	var site := world.site_at(Vector2i(int(GameState.delving[0]), int(GameState.delving[1])))
	GameState.delving = []
	if site == null or site.kind != Site.GATE or not site.open or site.cleared:
		return
	_note("You come back out of %s with %d of %d floors behind you. E at it goes on with floor %d." % [
		site.display_name, site.depth(), site.floors(), site.depth() + 1,
	])


func _enter_gate(site: Site) -> void:
	if site.cleared:
		_note("%s is shut for good." % site.display_name)
		return
	if site.data.has("ward") and not Ward.is_site_open(site):
		var attempt := Ward.force_site(site, GameState.party_characters())
		if not attempt.get("opened", false):
			_note(attempt.get("line", "%s is sealed." % site.display_name))
			return
		if attempt.get("line", "") != "":
			_note(attempt["line"])
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
			_note("Between its floors you can walk out, and the floors you won stay won.")
	else:
		_note("%s stands open." % site.label())
	var aim := site.floor_objective()
	if aim != Site.OBJECTIVE_ROUT:
		_note("%s: %s" % [Site.objective_name(aim), Site.objective_brief(aim)])

	# Shutting a gate is permanent, so it only shuts once the last floor is won.
	var meeting := Encounter.for_gate(world, site, depth, final, party, world.rng)
	var allies := Guild.allies_for(world, site, GameState.errands, party)
	if not allies.is_empty():
		BattleMapGen.add_allies(meeting["map"], allies)
		_note(Guild.line("muster_with_you", {"count": allies.size(), "gate": site.display_name}))
	_begin_battle(
		meeting,
		{
			"kind": "gate", "cell": site.cell, "final": final,
			"lost": "%s is still standing open." % site.display_name,
		}
	)


func _climb(site: Site) -> void:
	if world.tower_is_topped():
		_note("You have already stood on the last floor.")
		return

	if Chapters.sealed(world):
		_note(Chapters.seal_line(world))
		return
	var next_floor := world.tower_floor + 1
	_note("The Tower opens onto floor %d of %d — chapter %d of %d." % [
		next_floor, world.tower_floors(), Chapters.chapter_of(next_floor), Chapters.chapters(world),
	])
	if world.tower_hoard > 0:
		_note("You are still carrying %d gold. Lose here and it stays here." % world.tower_hoard)
	# The first floors are walked: their own ground, bands watching it, and the stair up at the
	# far end, kept on the last of them by a keeper (D102).
	var walked := Chapters.walked_floor_area(next_floor)
	if walked != "":
		_busy = true
		EventBus.request_scene.emit("area", {
			"area_id": walked,
			"title": "The Tower, floor %d" % next_floor,
			"return_scene": "world",
			"tower_floor": next_floor,
			# What the floor below paid, and the floor's own line, said on the way up.
			"notes": _notices.duplicate(),
		})
		return
	_begin_battle(
		Encounter.for_tower(world, site, next_floor, GameState.party_characters(), world.rng),
		{
			"kind": "tower", "cell": site.cell, "floor": next_floor,
			"lost": "You come back down to the floor you started on.",
		}
	)


## The stair of a walked floor, climbed: straight on to the next floor while there is one walked
## above it and the stair is open (D115). Off the top of the walked floors, or with the chapter
## sealed (floor 5's keeper beaten), the party comes back out to the Tower's yard.
func _climb_on() -> void:
	var site := world.tower()
	if site == null or world.tower_is_topped() or Chapters.sealed(world):
		return
	if Chapters.walked_floor_area(world.tower_floor + 1) == "":
		return
	_climb(site)


## The gate the party stands at, gone into when asked for (D116).
func _enter_gate_here() -> void:
	var site := world.site_at(world.player_cell)
	if site != null and site.kind == Site.GATE and not _busy:
		_enter_gate(site)


## The Tower's next floor, asked for while standing at its foot.
func _climb_here() -> void:
	var site := world.site_at(world.player_cell)
	if site != null and site.kind == Site.TOWER and not _busy:
		_climb(site)


## A delve you lose gives back every floor you took. You are carried back to the
## mouth of it and it fills in behind you.
func _lose_the_ground(site: Site) -> void:
	GameState.delving = []
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

	# Whoever was sent away is on the same clock as everyone else.
	for line: String in Dispatch.walk(world, GameState.roster, GameState.away, GameState.errands):
		_note(line)

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

	_say_what_can_be_done()


## The one line at the bottom telling you what you can do where you stand.
func _prompt() -> String:
	var said: Array[String] = []
	for doing: Dictionary in _actions_here():
		said.append(str(doing["prompt"]))
	return "  ·  ".join(said)


## The line and the buttons are the same list read twice, so a phone can never
## be offered less than the keyboard is told about.
func _say_what_can_be_done() -> void:
	if _view == View.MAP:
		_open_as_map()
		return
	var doable := _actions_here()
	var said: Array[String] = []
	for doing: Dictionary in doable:
		said.append(str(doing["prompt"]))
	_hint.text = "  ·  ".join(said)
	_lay_out_actions(doable)


## Everything the party could do from the tile they are standing on: the words
## for the hint line, a short name for a button, and the thing itself. An entry
## with no name is something to know rather than something to press.
func _actions_here() -> Array[Dictionary]:
	# A path to choose or a power to take is said first, beside what the place offers, never
	# instead of it: in its place it hid the Tower's door from a lead who levelled on floor 2 and
	# had not opened the party screen (B1, meeting 4).
	var out: Array[Dictionary] = []
	var choosing := GameState.roster.awaiting_class_choice()
	var owed := _somebody_owed_a_power() if choosing == null else null
	if choosing != null:
		out.append(_doable(
			"%s is ready to choose a path — press %s." % [choosing.display_name, _key("open_party")],
			"Choose a path", _open_party
		))
	elif owed != null:
		out.append(_doable(
			"%s has %d power%s to take — press %s." % [owed.display_name, owed.rungs, "" if owed.rungs == 1 else "s", _key("open_party")],
			"Take the power", _open_party
		))
	out.append_array(_doings_here())
	return out


## What the place, or the road, offers where the party stands.
func _doings_here() -> Array[Dictionary]:
	if _captive_here != null:
		return [
			_doable(
				"%s to ransom %s for %d gold" % [
					_key("captive_ransom"), _captive_here.display_name, int(_captive_here.captive.get("ransom", 0))
				],
				"Ransom (%d gold)" % int(_captive_here.captive.get("ransom", 0)), _ransom_here
			),
			_doable("%s to take them back by force." % _key("captive_rescue"), "Take by force", _fight_for_captive),
		]

	if _roadside_here != "":
		return [
			_doable("%s to step in" % _key("interact"), "Step in", _step_into_the_road),
			_telling("walk on to leave them to it."),
		]

	if _wild_here != "":
		return [
			_doable("%s to explore the ancient grove" % _key("interact"), "Explore the grove", _step_into_the_wild),
			_telling("walk on to leave it behind"),
		]

	var site := world.site_at(world.player_cell)
	if site != null:
		if site.kind == Site.HOME:
			return _home_actions(site)
		if site.kind == Site.TOWER and world.tower_topped:
			return [
				_doable(
					"%s to ascend the throne of the Tower (Conclude Journey)" % _key("interact"),
					"Ascend the throne", _walk_into_site
				),
				_telling("walk on to keep exploring"),
			]
		var parts: Array[Dictionary] = []
		if site.kind == Site.TOWER and not world.tower_is_topped() and not Chapters.sealed(world):
			parts.append(_doable(
				"%s to climb floor %d of the Tower" % [_key("interact"), world.tower_floor + 1],
				"Climb floor %d" % (world.tower_floor + 1), _climb_here
			))
		elif site.kind == Site.TOWER and not world.tower_is_topped():
			parts.append(_telling(Chapters.seal_line(world)))
		if site.kind == Site.GATE and site.open and not site.cleared:
			parts.append(_doable(
				"%s to enter %s (rank %s)" % [_key("interact"), site.display_name, site.rank],
				"Enter %s" % site.display_name, _enter_gate_here
			))
		if site.data.has("ward") and not Ward.is_site_open(site):
			var ward: Dictionary = site.data.get("ward", {})
			parts.append(_doable(
				"%s to challenge %s" % [_key("interact"), str(ward.get("name", site.display_name))],
				"Challenge %s" % str(ward.get("name", site.display_name)), _walk_into_site
			))
		if Town.is_threatened(site):
			parts.append(_doable(
				"%s to drive them out of %s" % [_key("", "V"), site.display_name],
				"Drive them out", _defend_here
			))
		elif Town.is_settlement(site) and not Town.is_ruined(site):
			parts.append(_doable("%s to raid %s" % [_key("", "K"), site.display_name], "Raid", _raid_here))
		if _area_here() != "":
			if site.kind == Site.KEEP:
				parts.append(_doable(
					"%s to enter %s (Halls & Proving Arena)" % [_key("interact"), site.display_name],
					"Enter %s" % site.display_name, _walk_into_site
				))
			else:
				parts.append(_doable(
					"%s to walk into %s" % [_key("interact"), site.display_name],
					"Walk into %s" % site.display_name, _walk_into_site
				))
		for each: Dictionary in Wanderers.here(world, site.cell):
			var who := Wanderers.name_of(str(each["id"]))
			parts.append(_doable("X to speak with %s" % who, "Speak with %s" % who, _speak_with_wanderer))
		var errand_doing := _errand_action(site)
		if not errand_doing.is_empty():
			parts.append(errand_doing)
		if Guild.has_hall(site):
			parts.append(_doable("%s for the Adventurers Guild" % _key("site_guild"), "The Guild", _open_guild))
		var offer := Market.hire_offer(site)
		if not offer.is_empty():
			parts.append(_doable(
				"%s to hire %s (level %d, %d gold)" % [
					_key("site_hire"), offer["display_name"], offer["level"], Market.asking_hire_cost(site, world, offer)
				],
				"Hire %s (%d gold)" % [
					offer["display_name"], Market.asking_hire_cost(site, world, offer)
				], _hire_here
			))
		var ware := Market.in_hand(site)
		if ware != "":
			var ware_name: String = Database.equipment_piece(ware).get("display_name", ware)
			parts.append(_doable(
				"%s to buy %s (%d gold)" % [_key("site_buy"), ware_name, Market.asking_price(site, world, ware)],
				"Buy %s (%d gold)" % [ware_name, Market.asking_price(site, world, ware)],
				_buy_here
			))
			var shown := Market.on_show(site).size()
			if shown > 1:
				parts.append(_doable(
					"%s for the next of %d wares" % [_key("", "Z"), shown], "Next ware", _next_ware
				))
		if not FirstHour.hides("grimoires") and not Grimoire.offer(site).is_empty():
			parts.append(_doable(
				"%s for the book, unread (%d gold)" % [_key("site_grimoire"), Grimoire.price(site)],
				"The book (%d gold)" % Grimoire.price(site), _buy_grimoire_here
			))
		if not FirstHour.hides("ferries") and Ferry.is_port(world, site.cell):
			var dest := Ferry.next_port(world, site.cell)
			if dest != null:
				parts.append(_doable(
					"%s to sail to %s (%d gold)" % [_key("", "O"), dest.display_name, Ferry.fare(world, site, dest)],
					"Sail to %s (%d gold)" % [dest.display_name, Ferry.fare(world, site, dest)],
					_sail_here
				))
		if not parts.is_empty():
			return parts

	if Roadside.escorting(world):
		return [_telling(Roadside.escort_prompt(world))]

	return [
		_doable("%s for the party" % _key("open_party"), "The Party", _open_party),
		_doable("%s for the menu" % _key("open_menu", "Esc"), "Menu", _open_menu),
	]


## What to press, said for whatever is in the player's hands. On a pad, a verb
## with no button of its own is reached through the place's action buttons,
## which Y puts the focus on; on a keyboard, [param letter] is said for a verb
## that is a bare letter rather than an action.
func _key(action: String, letter: String = "") -> String:
	if Pad.using_pad:
		return Pad.key(action, "open_actions")
	var said := Pad.key_text(action) if action != "" else ""
	return said if said != "" else letter


func _doable(prompt: String, label: String, call: Callable) -> Dictionary:
	return { "prompt": prompt, "label": label, "call": call }


## Something worth saying that is not a thing to press.
func _telling(prompt: String) -> Dictionary:
	return { "prompt": prompt, "label": "", "call": Callable() }


## Anything modal takes the screen, and the action buttons must not be left
## live underneath it. Deferred, because an overlay is only actually open a
## frame after it says it wants to be.
func _watch_overlays() -> void:
	_settle_actions.call_deferred()


func _settle_actions() -> void:
	if _actions == null or not is_inside_tree():
		return
	_actions.visible = _shows_actions() and not _overlay_open()


## The buttons are a thumb's way in, and a pad's: neither has an H to press.
func _shows_actions() -> bool:
	# The map is for looking at; the place's doings are offered on the ground.
	if _view == View.MAP:
		return false
	return Pace.is_touch_enabled() or Pad.using_pad


## A pad is choosing among the place's buttons rather than walking.
func _picking_an_action() -> bool:
	var owner := get_viewport().gui_get_focus_owner()
	return owner != null and _actions != null and _actions.is_ancestor_of(owner)


## Y: put the focus on the place's first button, or take it off again.
func _toggle_action_focus() -> void:
	if _picking_an_action():
		get_viewport().gui_release_focus()
		return
	if _actions == null:
		return
	for child in _actions.get_children():
		var button := child as Button
		if button != null and not button.is_queued_for_deletion() and button.is_visible_in_tree():
			button.grab_focus()
			return


func _overlay_open() -> bool:
	for overlay in get_tree().get_nodes_in_group(EventBus.MODAL_OVERLAY_GROUP):
		if overlay.has_method("is_open") and overlay.is_open():
			return true
	return false


func _open_party() -> void:
	EventBus.party_screen_requested.emit()


func _open_guild() -> void:
	if Guild.hall_at(world, world.player_cell) == null:
		_note(Guild.line("no_hall"))
		return
	EventBus.guild_requested.emit()


func _open_menu() -> void:
	EventBus.system_menu_requested.emit()


## The buttons under the hint line. They are the only way in on a touchscreen,
## where there is no H to press, so they are built from the same list rather
## than kept in step by hand.
func _lay_out_actions(doable: Array[Dictionary]) -> void:
	if _actions == null:
		return
	for child in _actions.get_children():
		_actions.remove_child(child)
		child.queue_free()
	if not _shows_actions():
		_actions.visible = false
		return
	_actions.visible = not _overlay_open()
	for doing: Dictionary in doable:
		var label := str(doing["label"])
		var call: Callable = doing["call"]
		if label == "" or not call.is_valid():
			continue
		var button := Button.new()
		button.text = label
		# Focus is how a pad presses one; anywhere else it would only let the
		# arrow keys wander off the road and onto a button.
		button.focus_mode = Control.FOCUS_ALL if Pad.using_pad else Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(0, ACTION_BUTTON_HEIGHT)
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(call)
		Sfx.attend(button)
		_actions.add_child(button)


## A power earned and not placed does nothing at all, so it is worth saying so
## on the walk rather than only on the screen nobody has opened.
func _somebody_owed_a_power() -> Character:
	for member: Character in GameState.roster.party_members():
		if member.trees.is_empty() and member.rungs > 0:
			member.rungs = 0
		if member.rungs > 0 and not member.trees.is_empty() and not Progression.rung_options(member, world).is_empty():
			return member
	return null


## What the board where you are standing has to say, if anything.
func _errand_action(site: Site) -> Dictionary:
	if not Errand.completable_at(GameState.errands, site.cell).is_empty():
		return _doable("%s to settle an errand" % _key("site_errands"), "Settle an errand", _errands_here)
	if not Errand.board(site).is_empty():
		return _doable("%s to read the board" % _key("site_errands"), "Read the board", _errands_here)
	return {}


## Home has no board and no trader — only the bed, and what a better one costs.
func _home_actions(site: Site) -> Array[Dictionary]:
	# In the First Hour the crater is where you fell, not a bedroom to furnish ([D178]).
	if FirstHour.hides("beds"):
		return [_doable("%s for the party" % _key("open_party"), "The Party", _open_party)]
	var better := Home.next_bed(site)
	if better.is_empty():
		return [
			_telling(Home.bed_name(site)),
			_telling("there is nothing better to sleep on"),
			_doable("%s for the party" % _key("open_party"), "The Party", _open_party),
		]
	return [
		_telling(Home.bed_name(site)),
		_doable(
			"%s for %s (%d gold, +%d HP)" % [
				_key("", "U"), better.get("display_name", "a better bed").to_lower(),
				int(better.get("cost", 0)),
				int(better.get("vigour", 0)),
			],
			"%s (%d gold)" % [
				better.get("display_name", "a better bed"), int(better.get("cost", 0))
			],
			_upgrade_bed_here
		),
	]


## Said when the game saves itself somewhere worth saying it. Coming back to the
## map is too often to mention.
func _on_game_saved(point: String, _note_text: String) -> void:
	if point != RunMode.ROAD and point != RunMode.LEAVE:
		_note("The game is saved.")


## Permadeath follows the player. Companions come and go, and some of them do
## not get to see the end of it.
func _end_run() -> void:
	_busy = true
	_note("%s falls, and the story stops here." % GameState.roster.player().display_name)
	_hint.text = ""
	_lay_out_actions([])
	EventBus.run_ended.emit()
	await get_tree().create_timer(RUN_OVER_DELAY).timeout
	EventBus.request_scene.emit("summary", {})


func _unhandled_input(event: InputEvent) -> void:
	if _busy or not event.is_pressed() or event.is_echo():
		return
	# Out of sight nothing here is pressed; the boxes answer for themselves.
	if _view == View.GROUND:
		return
	if _view == View.MAP:
		_map_input(event)
		return
	if event.is_action_pressed("open_actions"):
		get_viewport().set_input_as_handled()
		_toggle_action_focus()
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		# Backing out of the place's buttons is back to walking, not the menu.
		if _picking_an_action():
			get_viewport().gui_release_focus()
		else:
			EventBus.system_menu_requested.emit()
		return
	# Before the pace keys: walking into a place is what the player came here to
	# do, and E was quietly being eaten by the speed cycle.
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if _roadside_here != "":
			_step_into_the_road()
		elif _wild_here != "":
			_step_into_the_wild()
		else:
			_walk_into_site()
		return
	if event.is_action_pressed("battle_auto"):
		get_viewport().set_input_as_handled()
		Pace.auto = not Pace.auto
		_note("The party walks itself." if Pace.auto else "You take the party back.")
		_refresh()
		# Taking the party back is taking it back to the ground.
		if not Pace.auto and _driven_by_game():
			_view = View.GROUND
			_show_the_map(false)
			_hand_back()
		return
	if event.is_action_pressed("battle_speed"):
		get_viewport().set_input_as_handled()
		Pace.cycle_speed()
		_refresh()
		return
	if event.is_action_pressed("site_guild"):
		get_viewport().set_input_as_handled()
		_open_guild()
		return
	if not event is InputEventKey:
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
		KEY_Z:
			get_viewport().set_input_as_handled()
			_next_ware()
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
		KEY_O:
			get_viewport().set_input_as_handled()
			_sail_here()
		KEY_X:
			get_viewport().set_input_as_handled()
			_speak_with_wanderer()


## One of the sixteen is standing here. Talk, and if they are willing, they
## walk on with you.
func _speak_with_wanderer() -> void:
	var standing := Wanderers.here(world, world.player_cell)
	if standing.is_empty() or _busy:
		return
	var hero_id := str(standing[0]["id"])
	var dialogue_id := Wanderers.talk(world, GameState.roster, hero_id)
	if dialogue_id == "":
		return
	EventBus.dialogue_requested.emit(dialogue_id)
	await EventBus.dialogue_finished
	# GameState settles it the moment the conversation ends; this is in case it
	# has not, and costs nothing if it has.
	Wanderers.settle(world, GameState.roster, GameState.flags)
	if bool(Wanderers.entry(world, hero_id).get("joined", false)):
		_note(Wanderers.joined_line(world, hero_id))
		_warm_art()
	_refresh()
	_say_what_can_be_done()
	_map.queue_redraw()


## Passage by sea to another port along the coast.
func _sail_here() -> void:
	var site := world.site_at(world.player_cell)
	if site == null or FirstHour.hides("ferries") or not Ferry.is_port(world, site.cell):
		return
	var dest := Ferry.next_port(world, site.cell)
	if dest == null:
		_note("No boat will take you from here.")
		return
	var outcome := Ferry.sail(world, site, dest)
	_note(str(outcome.get("line", "")))
	if outcome.get("success", false):
		for notice: String in outcome.get("notices", []):
			_note(notice)
		_arrive_at(dest)
		_centre_camera()
		_map.queue_redraw()
		_refresh()


## Places big enough to walk around in have an area of the same name as their
## kind under `data/areas`; the rest are only a tile on the map.
func _area_here() -> String:
	var site := world.site_at(world.player_cell)
	if site == null:
		return ""
	var area_id: String = site.data.get("area", site.kind)
	return area_id if Database.has_area(area_id) else ""


# --- the ground ---------------------------------------------------------------


## How this scene was asked for. Only the scene the game put on screen hands
## play to the ground; a suite driving it directly walks it as before.
func _opened_as() -> View:
	if bool(boot_payload.get("map", false)):
		return View.MAP
	if _embedded():
		return View.GROUND
	# Asked for by name: the suites that check the walk's own controls.
	if bool(boot_payload.get("walk", false)):
		return View.WALK
	if _driven_by_game():
		return View.GROUND
	return View.WALK


func _driven_by_game() -> bool:
	return is_in_group(EventBus.ACTIVE_SCENE_GROUP) or _embedded()


## Run beside the land, out of sight ([D84]).
func _embedded() -> bool:
	return bool(boot_payload.get("embedded", false))


## The map and its lines are drawn only when somebody is looking at them.
func _show_the_map(on: bool) -> void:
	_map.visible = on
	$UI.visible = on


## Whatever was waiting on the tile when the party went down to the ground,
## put back: a scene on the road nobody has answered, a way into the wilds.
func _hold_again(held: Dictionary) -> void:
	_roadside_here = str(held.get("roadside", ""))
	_wild_here = str(held.get("wild", ""))
	var site := world.site_at(world.player_cell)
	if site != null:
		_captive_here = _captive_at(site)


func _held_now() -> Dictionary:
	return { "roadside": _roadside_here, "wild": _wild_here }


## The step, or the place's action, the ground sent up — then straight back.
func _do_what_the_ground_asked() -> void:
	var step: Array = boot_payload.get("step", [])
	var act := str(boot_payload.get("act", ""))
	if step.size() == 2:
		_step(Vector2i(int(step[0]), int(step[1])))
	elif boot_payload.has("fight"):
		_fight_where_you_stand(str(boot_payload["fight"]), boot_payload.get("field", {}))
	elif bool(boot_payload.get("climb_on", false)):
		_climb_on()
	elif act != "" and GROUND_ACTS.has(act) and has_method(act):
		# Some wait on a conversation; the ground is handed back once it is over.
		await call(act)
	_hand_back()


## Back to the ground, unless something here has taken the screen: a fight, a
## night at the fire, the end of the run. A box put up here (the landing, a
## scene on the road, a word after a fight) lives above every scene, so it
## carries on over the ground.
func _hand_back() -> void:
	if _busy or _view != View.GROUND or not is_inside_tree():
		return
	if _embedded():
		_busy = true
		# A step is a return to the road, which Iron Man saves at, as it did when every step came
		# back through the map.
		GameState.reached(RunMode.ROAD, "you were on the road")
		EventBus.continent_answered.emit(_ground_payload())
		queue_free()
		return
	# A party walking itself walks the ground too, where it can be seen ([D94]).
	_go_to_ground()


## [param fresh]: what the ground is has changed (a door opened), so the spot
## the party was standing on is not where they go back to.
func _go_to_ground(fresh: bool = false) -> void:
	if _busy:
		return
	_busy = true
	EventBus.request_scene.emit("area", _ground_payload(fresh))


## The ground the party stands on. Back where they were if nothing here moved
## them; otherwise the place or the country of the tile they are on, come into
## from the side they walked in by.
func _ground_payload(fresh: bool = false) -> Dictionary:
	var back: Dictionary = boot_payload.get("back", {})
	var payload: Dictionary
	if not fresh and not back.is_empty() and world.player_cell == _entered_at:
		payload = back.duplicate(true)
	else:
		payload = _fresh_ground()
		var step: Array = boot_payload.get("step", [])
		if step.size() == 2:
			# Come into the land from somewhere that is not it (a grove's edge): at the tile's way in
			# from the side the party came.
			var slot := GroundGen.slot(world, world.player_cell)
			var side := GroundGen.side_of(-Vector2i(int(step[0]), int(step[1])))
			var entries: Dictionary = slot.get("entries", {})
			if entries.has(side):
				payload["spawn_cell"] = entries[side]
	payload["held"] = _held_now()
	if not _cache_found.is_empty():
		payload["cache"] = _cache_found
	payload["actions"] = _ground_actions(payload)
	payload["bands"] = _bands_here()
	var said: Array = []
	for line: String in _notices:
		said.append(line)
	payload["notes"] = said
	return payload


## Where the party stands, with its land beside it. Water has no land to name
## (Biome.at reads it as grassland), so it is the region alone.
func _region_title(region: String) -> String:
	if world.terrain_id_at(world.player_cell) in ["ocean", "lake", "water"]:
		return region
	return "%s  ·  %s" % [region, Biome.display_name(Biome.at(world, world.player_cell))]


## The land round the tile the party is on ([D84]); its title is the place's, if a place with an
## inside and an open door stands there, or the country's. A warded place that will not open is
## open country with the challenge offered.
func _fresh_ground() -> Dictionary:
	var region := world.region_at(world.player_cell)
	var site := world.site_at(world.player_cell)
	var area_id := _area_here()
	# The land ([D84]): one stretch of ground, the place (if there is one) standing in its tile.
	var inside_a_place := site != null and area_id != "" and (not site.data.has("ward") or Ward.is_site_open(site))
	return {
		"land": true,
		"title": site.label() if inside_a_place else _region_title(region),
		"return_scene": "world", "planar_mode": true, "inside": "site" if inside_a_place else "",
	}


## The place's doings, said for the ground: what to press, the button's name,
## and which of [constant GROUND_ACTS] it asks for. Walking into a place you
## are already standing in, and the party and the menu (the ground has its
## own), are left off.
func _ground_actions(payload: Dictionary) -> Array:
	var inside := str(payload.get("inside", ""))
	var site := world.site_at(world.player_cell)
	var out: Array = []
	for doing: Dictionary in _actions_here():
		var call: Callable = doing["call"]
		if not call.is_valid():
			if inside != "wild":
				out.append({ "prompt": str(doing["prompt"]), "label": "", "act": "", "key": "" })
			continue
		var method := str(call.get_method())
		if not GROUND_ACTS.has(method):
			# The ground has its own key for it (the party screen): said, not pressed here.
			if method == "_open_party" and str(doing["label"]) in ["Choose a path", "Take the power"]:
				out.append({ "prompt": str(doing["prompt"]), "label": "", "act": "", "key": "" })
			continue
		if method == "_walk_into_site" and inside == "site" \
				and not (site != null and site.kind == Site.TOWER and world.tower_topped):
			continue
		out.append({
			"prompt": str(doing["prompt"]), "label": str(doing["label"]),
			"act": method, "key": GROUND_ACTS[method],
		})
	return out


# --- bands on the ground -------------------------------------------------------


## Bands near enough to be on the ground in front of the party: on the land ([D84]), every band
## within [constant LAND_BANDS_REACH] tiles, each with the tile it is on, so it can be seen walking
## from one to the next.
func _bands_here() -> Array:
	var out: Array = []
	for band: Prowler in world.prowlers:
		var apart := band.cell - world.player_cell
		if maxi(absi(apart.x), absi(apart.y)) > LAND_BANDS_REACH:
			continue
		out.append({
			"key": _band_key(band), "pack": band.pack, "sight": band.sight, "reach": band.reach(world),
			"faction": band.faction, "label": band.label(),
			"from": [signi(apart.x), signi(apart.y)],
			"tile": [band.cell.x, band.cell.y],
		})
	return out


## Which band this is, the same from step to step however far it wanders: where it settled and who
## is in it.
func _band_key(band: Prowler) -> String:
	return "%d,%d|%s" % [band.home.x, band.home.y, ",".join(band.pack)]


## The party walked into a band's sight on the ground. The fight is fought
## there, on that ground, in real time ([D66]); when it is over, play comes
## back to the same spot.
func _fight_where_you_stand(key: String, field: Dictionary) -> void:
	var band: Prowler = null
	for each: Prowler in world.prowlers:
		if _band_key(each) == key:
			band = each
	if band == null or field.is_empty():
		return
	world.prowlers.erase(band)
	var meeting := Encounter.for_band(world, band, GameState.party_characters(), world.rng)
	# Out of the long grass and on them before they knew: the party has the jump.
	if bool(field.get("ambush", false)):
		meeting["ambush"] = true
	# Kept, so a party that walks off the field leaves the band where it was.
	_begin_battle(meeting, { "band": band, "kind": "band", "cell": band.cell }, {
		"live": true, "field": field,
		"return_payload": {"back": boot_payload.get("back", {})},
	})


# --- the map ------------------------------------------------------------------


## Opened from the journal: the continent as far as the company knows it, to
## look round with the movement keys and the wheel. Nothing on it is walked.
func _open_as_map() -> void:
	_camera.keyboard_pan = true
	_actions.visible = false
	_hint.text = "The map: black where the company has never been.  ·  %s to look around  ·  %s to go back" % [
		"the right stick" if Pad.using_pad else "WASD or the arrows",
		_key("ui_cancel", "Esc"),
	]


func _map_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_M):
		get_viewport().set_input_as_handled()
		_close_map()
	elif event is InputEventKey and event.keycode == KEY_N:
		get_viewport().set_input_as_handled()
		EventBus.journal_requested.emit()


func _close_map() -> void:
	if _busy or _view != View.MAP:
		return
	_busy = true
	var back: Dictionary = boot_payload.get("back", {})
	if back.is_empty():
		_busy = false
		_view = View.GROUND
		_go_to_ground()
		return
	EventBus.request_scene.emit("area", back)


func _walk_into_site() -> void:
	var site := world.site_at(world.player_cell)
	if site != null and site.kind == Site.TOWER and world.tower_topped:
		_busy = true
		_note("The company ascends the throne of the Tower, their legend etched into the stones.")
		EventBus.request_scene.emit("summary", { "ending": Museum.CONQUERED })
		return
	if site != null and site.data.has("ward") and not Ward.is_site_open(site):
		var attempt := Ward.force_site(site, GameState.party_characters())
		if not attempt.get("opened", false):
			_note(attempt.get("line", "%s is sealed." % site.display_name))
			return
		if attempt.get("line", "") != "":
			_note(attempt["line"])
	var area_id := _area_here()
	if area_id == "":
		# Most places on the map have no inside yet. Say so, rather than
		# swallowing the key and reading as broken.
		_note(
			"There is no way into %s." % site.display_name if site != null
			else "There is nothing here to walk into."
		)
		return
	if _view == View.GROUND:
		# The door is open now: the ground is the place's inside, with what it offers.
		_go_to_ground(true)
		return
	_busy = true
	EventBus.request_scene.emit("area", {
		"area_id": area_id,
		"title": site.label(),
		"return_scene": "world",
		"planar_mode": true,
	})


func _hire_here() -> void:
	var site := world.site_at(world.player_cell)
	if site == null:
		return
	var offer := Market.hire_offer(site)
	if offer.is_empty():
		return
	if not GameState.roster.has_room():
		_note(Seats.full_line(GameState.roster))
		return

	var hired := Market.hire(site, GameState.roster, world)
	if hired == null:
		_note("You cannot afford %d gold." % Market.asking_hire_cost(site, world, offer))
		return
	_note("%s falls in with you." % hired.display_name)
	_refresh()
	_say_what_can_be_done()


func _buy_here() -> void:
	var site := world.site_at(world.player_cell)
	if site == null:
		return
	var equipment_id := Market.in_hand(site)
	if equipment_id == "":
		return
	var name: String = Database.equipment_piece(equipment_id).get("display_name", equipment_id)
	if not Market.buy(site, equipment_id, GameState.roster.player(), world):
		_note("You cannot afford the %s." % name)
		return
	_note("%s takes up the %s." % [GameState.roster.player().display_name, name])
	_refresh()
	_say_what_can_be_done()


## D146: turn to the next of the wares laid out here.
func _next_ware() -> void:
	var site := world.site_at(world.player_cell)
	if site == null or Market.on_show(site).size() < 2:
		return
	Market.next_ware(site)
	_say_what_can_be_done()


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
		_say_what_can_be_done()
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
		EventBus.tip_moment.emit("errand", {})
	_map.queue_redraw()
	_refresh()
	_say_what_can_be_done()


## Buy the book without knowing what it is. That is the whole transaction.
func _buy_grimoire_here() -> void:
	var site := world.site_at(world.player_cell)
	if site == null or FirstHour.hides("grimoires") or Grimoire.offer(site).is_empty():
		return
	for line: String in Grimoire.buy_and_read(site, GameState.roster.player(), world):
		_note(line)
	_refresh()
	_say_what_can_be_done()


## Buy the next bed up and try it out, since you are already standing in it.
func _upgrade_bed_here() -> void:
	var site := world.site_at(world.player_cell)
	if site == null or site.kind != Site.HOME or FirstHour.hides("beds"):
		return
	var bought := Home.next_bed(site)
	for line: String in Home.upgrade(site):
		_note(line)
	if not bought.is_empty() and Home.bed(site) == bought:
		_sleep_at_home(site)
	_refresh()
	_say_what_can_be_done()


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
	_say_what_can_be_done()


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
		# A fight can start mid-exchange, and the map is gone before the next line.
		if not is_instance_valid(_bubble) or not is_inside_tree():
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
	var s := Season.current(world)
	# Seasons are hidden for the First Hour (D97): no clover, no season named.
	var seasons := not FirstHour.hides("seasons")
	if _season_icon != null:
		_season_icon.visible = seasons
		_season_icon.texture = Season.clover_texture(world)
		_season_icon.tooltip_text = "%s\n%s" % [Season.full_label(world), s.get("blurb", "")]
	var site := world.site_at(world.player_cell)
	var region: String = world.region_at(world.player_cell)
	var where: String = site.label() if site != null else world.terrain_at(world.player_cell).get("name", "open ground")
	var when := "  ·  %s (%s)" % [Season.label(world), s["clover_name"]] if seasons else ""
	_place.text = "%s  ·  %s%s  ·  %d gold  ·  step %d  ·  %d bands abroad" % [
		where, region, when, GameState.gold, world.steps, world.prowlers.size()
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
	_draw_fog()
	_draw_watched_ground()
	_draw_places()
	_draw_errand_marks()
	_draw_quest_markers()
	_draw_the_climb()
	_draw_wanderers()
	_draw_fallen_weapons()
	_draw_the_x()
	_draw_bands()
	_draw_party()


## The ground is drawn to the camera, so panning or zooming has to redraw it.
## Compared rather than hooked, because the rig moves by tween as well as by key.
func _watch_the_view() -> void:
	var cam_pos := _camera.get_screen_center_position()
	var cam_zoom := _camera.zoom.x
	if cam_pos.distance_squared_to(Vector2(_last_view.x, _last_view.y)) < 2.0 and absf(cam_zoom - _last_view.z) < 0.02:
		return
	_last_view = Vector3(cam_pos.x, cam_pos.y, cam_zoom)
	_map.queue_redraw()


## A single flat green for every grass tile reads as a spreadsheet. Each cell
## gets a fixed wobble in brightness and whatever its terrain grows.
##
## Only what the camera can see is drawn. The country is far too large to lay
## out in full every time somebody takes a step.
func _draw_ground() -> void:
	var seen := _cells_in_view()
	var zoom_lvl: float = _camera.zoom.x
	var dress_lod: bool = zoom_lvl >= 0.65
	var batch_runs: bool = zoom_lvl < 0.45

	if batch_runs:
		for y in range(seen.position.y, seen.end.y):
			var run_start_x := seen.position.x
			var current_terrain := world.terrain_at(Vector2i(run_start_x, y))
			var current_color := Color(current_terrain.get("color", "#4f7d3f"))
			for x in range(seen.position.x + 1, seen.end.x):
				var cell := Vector2i(x, y)
				var terrain := world.terrain_at(cell)
				var color := Color(terrain.get("color", "#4f7d3f"))
				if color != current_color:
					var rect := Rect2(
						Vector2(float(run_start_x) * CELL, float(y) * CELL),
						Vector2(float(x - run_start_x) * CELL, float(CELL))
					)
					_map.draw_rect(rect, current_color)
					run_start_x = x
					current_color = color
			var final_rect := Rect2(
				Vector2(float(run_start_x) * CELL, float(y) * CELL),
				Vector2(float(seen.end.x - run_start_x) * CELL, float(CELL))
			)
			_map.draw_rect(final_rect, current_color)
		return

	for y in range(seen.position.y, seen.end.y):
		for x in range(seen.position.x, seen.end.x):
			var cell := Vector2i(x, y)
			if not Atlas.is_charted(world, cell):
				continue
			var rect := Rect2(Vector2(cell) * CELL, Vector2.ONE * CELL)
			var terrain := world.terrain_at(cell)
			_map.draw_rect(rect, _land_colour(cell, Color(terrain.get("color", "#4f7d3f"))) * _shade(cell))
			if dress_lod and Atlas.is_explored(world, cell):
				_dress(cell, world.terrain_id_at(cell))


## The terrain's colour washed with its land's, so the snow, the blight and the
## crystal read on the map before anybody walks into them.
func _land_colour(cell: Vector2i, base: Color) -> Color:
	var land := Biome.at(world, cell)
	if land == Biome.GRASSLAND or land == Biome.FOREST:
		return base
	return base.lerp(Biome.tint(land) * Color(0.8, 0.8, 0.8), 0.55)


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


## The map is black until the party has been there ([D50]). Ground a map has
## drawn in is shown dim; ground just seen fades in. Unbroken runs of one kind
## are drawn as one rectangle, so the black of an unwalked continent is cheap.
func _draw_fog() -> void:
	var seen := _cells_in_view()
	for y in range(seen.position.y, seen.end.y):
		var run_start := seen.position.x
		var run_kind := -1
		for x in range(seen.position.x, seen.end.x + 1):
			var kind := 0
			if x < seen.end.x:
				var cell := Vector2i(x, y)
				if _fading.has(cell):
					kind = 3
				elif Atlas.is_explored(world, cell):
					kind = 0
				elif Atlas.is_charted(world, cell):
					kind = 1
				else:
					kind = 2
			else:
				kind = -2
			if kind == run_kind:
				continue
			if run_kind == 1 or run_kind == 2:
				_map.draw_rect(
					Rect2(Vector2(run_start, y) * CELL, Vector2(x - run_start, 1) * CELL),
					CHARTED_WASH if run_kind == 1 else UNKNOWN
				)
			run_start = x
			run_kind = kind
	# What is coming into sight: from black (or from the dim of a map) to clear.
	for cell: Vector2i in _fading:
		if not seen.has_point(cell):
			continue
		if not Atlas.is_explored(world, cell):
			_map.draw_rect(Rect2(Vector2(cell) * CELL, Vector2.ONE * CELL), CHARTED_WASH)
		var veil := UNKNOWN
		veil.a = clampf(float(_fading[cell]) / REVEAL_FADE, 0.0, 1.0)
		_map.draw_rect(Rect2(Vector2(cell) * CELL, Vector2.ONE * CELL), veil)


func _fade_in(delta: float) -> void:
	if _fading.is_empty():
		return
	for cell: Vector2i in _fading.keys():
		_fading[cell] = float(_fading[cell]) - delta
		if float(_fading[cell]) <= 0.0:
			_fading.erase(cell)
	_map.queue_redraw()


## New ground on the map. Ground the party saw for itself fades in; a place
## that comes into sight for the first time is said out loud.
func _on_ground_revealed(cells: Array) -> void:
	for cell: Vector2i in cells:
		_fading[cell] = REVEAL_FADE
		var site := world.site_at(cell)
		if site != null and Atlas.is_explored(world, cell) and not world.marked.has("%d,%d" % [cell.x, cell.y]) \
				and site.kind != Site.TOWER and site.kind != Site.HOME and site.kind != Site.GRAVE:
			_note(Atlas.line("seen", {"place": site.display_name}))
	# The ground has to be laid out again whether or not anything is fading.
	_map.queue_redraw()


## Ground somebody has eyes on, in the colours of whoever is watching it.
func _draw_watched_ground() -> void:
	var seen := _cells_in_view()
	for band: Prowler in world.prowlers:
		var wash := Faction.banner(band.faction)
		wash.a = 0.26
		for watched: Vector2i in band.watched(world):
			if seen.has_point(watched) and Atlas.is_explored(world, watched):
				_map.draw_rect(Rect2(Vector2(watched) * CELL, Vector2.ONE * CELL), wash)


func _draw_places() -> void:
	var seen := _cells_in_view()
	var font: Font = _hint.get_theme_font("font") if _hint != null else null
	if font == null:
		font = ThemeDB.fallback_font
	var show_names: bool = _camera.zoom.x >= 0.45

	for site in world.sites:
		if not seen.has_point(site.cell) or not Atlas.knows(world, site):
			continue
		var art := _site_art(site)
		var centre := Vector2(site.cell) * CELL + Vector2.ONE * CELL * 0.5
		if art == null:
			_map.draw_circle(centre, CELL * 0.34, Site.COLOURS.get(site.kind, Color.WHITE))
			if show_names and font != null:
				_draw_site_label(site.display_name, centre + Vector2(0, -CELL * 0.4), font)
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

		# Small legible name banner over the site
		if show_names and font != null:
			_draw_site_label(site.display_name, Vector2(foot.x, foot.y - size.y * 0.92 - 6.0), font)


func _draw_site_label(text: String, top_centre: Vector2, font: Font) -> void:
	var font_size := 11
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var badge_rect := Rect2(
		top_centre.x - text_size.x * 0.5 - 5.0,
		top_centre.y - text_size.y * 0.8 - 2.0,
		text_size.x + 10.0,
		text_size.y + 4.0
	)
	_map.draw_rect(badge_rect, Color(0.06, 0.07, 0.09, 0.82))
	_map.draw_rect(badge_rect, Color(0.85, 0.78, 0.62, 0.6), false, 1.0)
	_map.draw_string(font, Vector2(top_centre.x - text_size.x * 0.5, top_centre.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.96, 0.94, 0.88))


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
	if site.kind == Site.GATE:
		path = Site.GATE_ART[absi(site.cell.x * 31 + site.cell.y * 17) % Site.GATE_ART.size()]
	elif site.kind == Site.KEEP:
		path = Faction.hold_art(str(site.data.get("faction", "")))
	elif bool(site.data.get("city", false)):
		path = Site.CITY_ART
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
	for each: Dictionary in world.wanderers:
		Database.unit_face(str(each.get("id", "")))
	for echo: Dictionary in Siblings.past(world):
		Gear.icon(str(echo.get("weapon", {}).get("id", "")))


## Draws a glowing, pulsing destination beacon and an animated directional trail from the party.
func _draw_quest_path_and_beacon(party_pos: Vector2, target_pos: Vector2, color: Color, badge_text: String = "") -> void:
	var delta := target_pos - party_pos
	var dist := delta.length()
	if dist > CELL * 0.7:
		var dir := delta / dist
		var step_size := CELL * 1.2
		var count := int(dist / step_size)
		var tick := float(Time.get_ticks_msec()) * 0.003
		var offset := fmod(tick, 1.0) * step_size
		for i in range(count):
			var d := float(i) * step_size + offset
			if d >= dist - CELL * 0.6:
				break
			var pt := party_pos + dir * d
			var alpha_pulse := 0.6 + 0.35 * sin(tick * 3.0 + float(i) * 0.4)
			var dot_color := color
			dot_color.a = clampf(dot_color.a * alpha_pulse, 0.25, 0.95)
			_map.draw_circle(pt, CELL * 0.1, dot_color)
			# Directional chevron ticks along the trail
			if i % 3 == 1:
				var perp := Vector2(-dir.y, dir.x) * (CELL * 0.1)
				_map.draw_line(pt - perp + dir * (CELL * 0.1), pt + dir * (CELL * 0.16), dot_color, 1.5)
				_map.draw_line(pt + perp + dir * (CELL * 0.1), pt + dir * (CELL * 0.16), dot_color, 1.5)

	# Destination beacon
	var pulse := 1.0 + 0.15 * sin(float(Time.get_ticks_msec()) * 0.006)
	_map.draw_arc(target_pos, CELL * 0.65 * pulse, 0.0, TAU, 24, color, 2.5, true)
	var d := CELL * 0.26
	var diamond := PackedVector2Array([
		target_pos + Vector2(0, -d),
		target_pos + Vector2(d, 0),
		target_pos + Vector2(0, d),
		target_pos + Vector2(-d, 0),
	])
	_map.draw_colored_polygon(diamond, color.lightened(0.25))

	if badge_text != "" and _camera.zoom.x >= 0.4:
		var font: Font = _hint.get_theme_font("font") if _hint != null else null
		if font == null:
			font = ThemeDB.fallback_font
		var text_sz := font.get_string_size(badge_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
		var b_pos := target_pos + Vector2(0, -CELL * 0.8)
		var bg := Rect2(b_pos.x - text_sz.x * 0.5 - 4.0, b_pos.y - text_sz.y * 0.8 - 2.0, text_sz.x + 8.0, text_sz.y + 4.0)
		_map.draw_rect(bg, Color(0.1, 0.08, 0.02, 0.85))
		_map.draw_rect(bg, color, false, 1.0)
		_map.draw_string(font, Vector2(b_pos.x - text_sz.x * 0.5, b_pos.y), badge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.95, 0.8))


## Where the errands point. Shows target beacon and a directional trail leading from the party.
func _draw_errand_marks() -> void:
	var party_pos := Vector2(world.player_cell) * CELL + Vector2.ONE * CELL * 0.5
	for errand: Dictionary in GameState.errands:
		var pair: Array = errand.get("to", [])
		if pair.size() < 2 or Errand.is_complete(errand):
			continue
		var target_cell := Vector2i(int(pair[0]), int(pair[1]))
		var target_pos := Vector2(target_cell) * CELL + Vector2.ONE * CELL * 0.5
		_draw_quest_path_and_beacon(party_pos, target_pos, Color(1.0, 0.88, 0.35, 0.9), "ERRAND")
	# The First Hour's objective (D95), where the compass points, unless an errand above is it.
	var goal := AutoRoad.objective(world)
	if not goal.is_empty() and not GameState.errands.any(func(errand: Dictionary) -> bool:
			return AutoRoad.cell_of(errand.get("to", [])) == goal["cell"]):
		var goal_pos := Vector2(goal["cell"]) * CELL + Vector2.ONE * CELL * 0.5
		_draw_quest_path_and_beacon(party_pos, goal_pos, Color(0.95, 0.42, 0.3, 0.9), "OBJECTIVE")


## Active quest markers, escort trails, and landmarks of interest on the continent.
func _draw_quest_markers() -> void:
	var party_pos := Vector2(world.player_cell) * CELL + Vector2.ONE * CELL * 0.5

	if Roadside.escorting(world):
		var dest := Roadside.destination(world)
		if dest != null:
			var target_pos := Vector2(dest.cell) * CELL + Vector2.ONE * CELL * 0.5
			_draw_quest_path_and_beacon(party_pos, target_pos, Color(1.0, 0.85, 0.25, 0.95), "ESCORT")

	for site in world.sites:
		if not Atlas.knows(world, site):
			continue
		if Town.is_threatened(site):
			var target_pos := Vector2(site.cell) * CELL + Vector2.ONE * CELL * 0.5
			_draw_quest_path_and_beacon(party_pos, target_pos, Color(0.95, 0.35, 0.25, 0.95), "DEFEND")
		elif site.kind == Site.GATE and site.rank == "S" and not site.cleared:
			var centre := Vector2(site.cell) * CELL + Vector2.ONE * CELL * 0.5
			_map.draw_arc(centre, CELL * 0.62, 0.0, TAU, 20, Color(0.85, 0.35, 0.95, 0.8), 2.0, true)
		elif not FirstHour.hides("ferries") and Ferry.is_port(world, site.cell):
			var centre := Vector2(site.cell) * CELL + Vector2.ONE * CELL * 0.5
			_map.draw_arc(centre, CELL * 0.52, 0.0, TAU, 18, Color(0.35, 0.75, 0.95, 0.75), 1.5, true)
		elif site.kind == Site.GRAVE:
			var centre := Vector2(site.cell) * CELL + Vector2.ONE * CELL * 0.5
			_map.draw_arc(centre, CELL * 0.45, 0.0, TAU, 16, Color(0.8, 0.8, 0.85, 0.7), 1.5, true)
		elif site.data.has("thread"):
			var centre := Vector2(site.cell) * CELL + Vector2.ONE * CELL * 0.5
			_map.draw_arc(centre, CELL * 0.58, 0.0, TAU, 20, Color(0.9, 0.6, 0.3, 0.8), 2.0, true)
			_draw_quest_path_and_beacon(party_pos, centre, Color(0.9, 0.6, 0.3, 0.85), "QUEST")


## The standing quest every lead carries ([D53]): the Tower, marked for what it is.
func _draw_the_climb() -> void:
	var tower := world.tower()
	if tower == null or world.tower_topped:
		return
	var centre := Vector2(tower.cell) * CELL + Vector2.ONE * CELL * 0.5
	var pulse := 1.0 + 0.1 * sin(float(Time.get_ticks_msec()) * 0.004)
	var gold := Color(1.0, 0.86, 0.45, 0.85)
	_map.draw_arc(centre, CELL * 0.9 * pulse, 0.0, TAU, 28, gold, 2.0, true)
	if _camera.zoom.x < 0.3:
		return
	var font: Font = _hint.get_theme_font("font") if _hint != null else null
	if font == null:
		font = ThemeDB.fallback_font
	var badge := Fall.quest_badge()
	var size := font.get_string_size(badge, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
	var at := centre + Vector2(0, CELL * 1.25)
	var back := Rect2(at.x - size.x * 0.5 - 4.0, at.y - size.y * 0.8 - 2.0, size.x + 8.0, size.y + 4.0)
	_map.draw_rect(back, Color(0.1, 0.08, 0.02, 0.85))
	_map.draw_rect(back, gold, false, 1.0)
	_map.draw_string(font, Vector2(at.x - size.x * 0.5, at.y), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.95, 0.8))


## The others of the sixteen, where the company last saw them or heard of
## them. A sighting is drawn bright; a rumour, faint.
func _draw_wanderers() -> void:
	for each: Dictionary in Wanderers.known(world):
		if bool(each.get("joined", false)):
			continue
		var cell := Wanderers.cell_of(each.get("known", []))
		if cell.x < 0:
			continue
		var centre := Vector2(cell) * CELL + Vector2(CELL * 0.85, CELL * 0.1)
		var faint := bool(each.get("heard", false))
		var ring := Color(1.0, 0.84, 0.35, 0.55 if faint else 0.95)
		_map.draw_circle(centre, CELL * 0.36, Color(0.08, 0.07, 0.1, 0.8))
		_map.draw_arc(centre, CELL * 0.36, 0.0, TAU, 20, ring, 2.0, true)
		var face: Texture2D = Database.unit_face(str(each.get("id", "")))
		if face == null:
			continue
		var size := Vector2.ONE * CELL * 0.8
		_map.draw_texture_rect(face, Rect2(centre - size * 0.5, size), false, Color(1, 1, 1, 0.55 if faint else 1.0))


## Where the map pieces lead ([D220]): a red X, drawn as on any treasure map.
func _draw_the_x() -> void:
	var cell := Treasure.at(world)
	if cell.x < 0:
		return
	var centre := Vector2(cell) * CELL + Vector2.ONE * CELL * 0.5
	var reach := CELL * 0.34
	var ink := Color(0.78, 0.12, 0.1, 0.75 + 0.25 * sin(Time.get_ticks_msec() / 300.0))
	for sign_: float in [1.0, -1.0]:
		_map.draw_line(centre + Vector2(-reach, -reach * sign_), centre + Vector2(reach, reach * sign_), Color(0.08, 0.05, 0.04, 0.8), 6.0, true)
		_map.draw_line(centre + Vector2(-reach, -reach * sign_), centre + Vector2(reach, reach * sign_), ink, 3.5, true)


## A dead lead's weapon, once there is word of where it came down (M15): its
## own picture in a ring the colour of a fall.
func _draw_fallen_weapons() -> void:
	for fallen: Dictionary in Siblings.heard_weapons(world):
		var cell: Vector2i = fallen["cell"]
		var centre := Vector2(cell) * CELL + Vector2.ONE * CELL * 0.5
		var pulse := 0.75 + 0.25 * sin(Time.get_ticks_msec() / 260.0)
		_map.draw_circle(centre, CELL * 0.5, Color(0.1, 0.05, 0.04, 0.85))
		_map.draw_arc(centre, CELL * 0.5, 0.0, TAU, 24, Color(0.906, 0.447, 0.322, pulse), 2.5, true)
		var icon := Gear.icon(str(fallen["id"]))
		if icon != null:
			var size := Vector2.ONE * CELL * 0.8
			_map.draw_texture_rect(icon, Rect2(centre - size * 0.5, size), false)


## The last look at a world whose lead has died and ascended ([D32]): the
## camera rises over the whole of it and watches it go. Nothing here can be
## walked; when it is over the run is told and the next lead is chosen.
func _watch_it_end() -> void:
	_busy = true
	$UI.hide()
	_warm_art()
	_map.draw.connect(_draw_world)
	_camera.frame(Rect2(Vector2.ZERO, Vector2(world.size) * CELL))
	_centre_camera(true)
	_map.queue_redraw()
	var lead := GameState.roster.player() if GameState.roster != null else null
	var ending := WorldEnd.new()
	ending.name = "WorldEnd"
	add_child(ending)
	var tower := world.tower()
	await ending.play(
		_camera, world, tower.cell if tower != null else world.size / 2, CELL,
		lead.display_name if lead != null else "the fallen"
	)
	EventBus.request_scene.emit("summary", { "ending": Museum.FELL, "settled": true })


## Bands are drawn as whoever is leading them, so the country tells you what is
## in it before you are close enough to be told the hard way.
func _draw_bands() -> void:
	for band: Prowler in world.prowlers:
		if not Atlas.is_explored(world, band.cell):
			continue
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