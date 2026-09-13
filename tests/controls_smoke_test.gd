extends Node
## Guards the controls, on a touchscreen and off it.
##
## Every claim here is one that has already been got wrong once. The walk scene
## dropped every input that was not a key, so the on-screen buttons did nothing.
## The overlay went away when a screen opened and never came back when it shut.
## It sat on top of the fight's own commands. Screens had no way out but a key a
## phone does not have. None of it showed up in a test, because none of it was
## in one.
##
## Boots the real [Game] with the touch controls forced on and drives it the way
## a thumb would.
##
##   godot --headless --path . res://tests/controls_smoke_test.tscn

const SEED := 20260827
## The layout is anchored, so the corners only mean anything at a real size.
const WINDOW := Vector2i(1280, 720)
## Frames to let a deferred layout or a scene swap land.
const SETTLE := 6

var _failures: Array[String] = []
var _game: Node
var _touch: TouchControls
var _journal: Node
var _party: PartyScreen
var _stash: Node
var _menu: Node
var _dialogue: Node
## Scenes the game asked for, so a request can be seen as well as followed.
var _requests: Array[String] = []


func _ready() -> void:
	get_window().size = WINDOW
	Pace.touch_mode = "on"
	Pace.auto = false
	GameState.new_game(SEED)
	EventBus.request_scene.connect(
		func(key: String, _payload: Dictionary) -> void: _requests.append(key)
	)

	_game = load("res://src/main.tscn").instantiate()
	add_child(_game)
	await _settle()
	_touch = _game.get_node("TouchControls")
	_journal = _game.get_node("JournalScreen")
	_party = _game.get_node("PartyScreen")
	_stash = _game.get_node("StashScreen")
	_menu = _game.get_node("SystemMenu")
	_dialogue = _game.get_node("DialogueBox")

	await _check_nothing_opens_itself()
	await _enter("world")
	await _clear_dialogue()
	_check_touch_reaches_the_game()
	_check_every_verb_has_a_button()
	await _check_the_controls_come_back()
	await _check_everything_closes_without_a_key()
	_check_the_overlay_keeps_off_the_hud("world")
	_check_the_party_screen()
	await _check_the_overlay_reads_the_scene()

	if _failures.is_empty():
		print("controls smoke test: PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			print("FAIL: %s" % failure)
		get_tree().quit(1)


# --- nothing opens itself -----------------------------------------------------


## The complaint that started this suite: a screen standing in front of the game
## before the player has touched anything.
##
## The dialogue box is the one thing allowed to speak first — the prologue and
## the cutscene a place opens on are both written down, and both are meant to.
## Nothing else may put itself in the way, in any scene, on a new run or a
## loaded one.
func _check_nothing_opens_itself() -> void:
	_expect(not _anything_open(), "something was already open on the first frame")

	for scene_key: String in ["title", "battle", "world", "area"]:
		await _enter(scene_key)
		_check_only_the_written_word_speaks("entering the %s scene" % scene_key)
	await _clear_dialogue()

	# "Loading the game" is as often a save as a new run, and a save carries
	# state a fresh world does not.
	GameState.save()
	_expect(GameState.has_save(), "the run would not save, so loading cannot be checked")
	_expect(GameState.load_save(), "the saved run would not load")
	await _enter("world")
	_check_only_the_written_word_speaks("loading a saved run")
	await _clear_dialogue()


func _check_only_the_written_word_speaks(when: String) -> void:
	for overlay in get_tree().get_nodes_in_group(EventBus.MODAL_OVERLAY_GROUP):
		if overlay == _dialogue or overlay.is_in_group(EventBus.CUTSCENE_FRAME_GROUP):
			continue
		_expect(
			not overlay.is_open(),
			"%s stood in front of the game by itself on %s" % [overlay.name, when]
		)


# --- touch reaches the game ---------------------------------------------------


## The walk scene threw away every event that was not a key, so the overlay —
## which speaks in actions — was talking to nobody.
func _check_touch_reaches_the_game() -> void:
	var world := _current_scene()
	_expect(world != null, "the walk scene is not up")
	if world == null:
		return

	# Back, as the overlay's own button sends it.
	world._unhandled_input(_action("ui_cancel"))
	_expect(_menu.is_open(), "a synthesised ui_cancel never reached the walk scene")
	_menu.close()

	# Act, likewise. Standing at home, stepping in asks for the interior.
	var before := _requests.size()
	world._unhandled_input(_action("interact"))
	_expect(
		_requests.size() > before or world._busy,
		"a synthesised interact never reached the walk scene"
	)
	world._busy = false

	# And the other way: the bare-letter shortcuts still want a real key, or
	# every action sent would trip whichever letter it landed on.
	_expect(not _journal.is_open(), "a synthesised action reached a bare-letter shortcut")
	# A raw touch must fall through the letter block rather than be read as one.
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = Vector2(10, 10)
	world._unhandled_input(touch)
	_expect(not _journal.is_open(), "a screen touch was read as a letter key")
	_expect(not _party.is_open(), "a screen touch was read as a letter key")


# --- every verb has a button --------------------------------------------------


## Hire, buy, the board, the book and the boat were letter keys with nothing on
## screen. Whatever the hint line offers, a thumb must be able to reach.
func _check_every_verb_has_a_button() -> void:
	var world := _current_scene()
	if world == null:
		return
	var checked := 0
	var stood_at := GameState.world.player_cell
	for site: Site in GameState.world.sites:
		GameState.world.player_cell = site.cell
		var doable: Array[Dictionary] = world._actions_here()
		var line: String = world._prompt()

		for doing: Dictionary in doable:
			var prompt := str(doing["prompt"])
			_expect(
				line.contains(prompt),
				"'%s' is offered as a button but never said in the hint line" % prompt
			)
			if str(doing["label"]) != "":
				var call: Callable = doing["call"]
				_expect(call.is_valid(), "the '%s' button is wired to nothing" % doing["label"])

		for owed: Array in [
			[not Market.hire_offer(site).is_empty(), "to hire", "hiring"],
			[not Market.wares(site).is_empty(), "to buy", "buying"],
			[not Grimoire.offer(site).is_empty(), "for the book", "the book"],
			[Ferry.is_port(GameState.world, site.cell) \
					and Ferry.next_port(GameState.world, site.cell) != null, "to sail", "sailing"],
		]:
			if not bool(owed[0]):
				continue
			checked += 1
			_expect(
				_has_button_saying(doable, str(owed[1])),
				"%s is offered on the keyboard at %s but has no button" % [owed[2], site.display_name]
			)
	print("verbs: checked %d site offers across %d places" % [checked, GameState.world.sites.size()])
	GameState.world.player_cell = stood_at


func _has_button_saying(doable: Array[Dictionary], phrase: String) -> bool:
	for doing: Dictionary in doable:
		if str(doing["prompt"]).contains(phrase):
			var call: Callable = doing["call"]
			return str(doing["label"]) != "" and call.is_valid()
	return false


# --- the controls come back ---------------------------------------------------


## The overlay listened for screens opening and never for them closing, so the
## first menu a player opened took the controls away for good.
func _check_the_controls_come_back() -> void:
	var root: Control = _touch.get_node("Root")
	_expect(root.visible, "the controls are not up in the walk scene to begin with")

	for screen: Array in [
		[EventBus.party_screen_requested, _party, "the party screen"],
		[EventBus.journal_requested, _journal, "the journal"],
		[EventBus.stash_requested, _stash, "the strongbox"],
		[EventBus.system_menu_requested, _menu, "the menu"],
	]:
		var opening: Signal = screen[0]
		var overlay: Node = screen[1]
		var what: String = screen[2]

		opening.emit()
		await _settle()
		_expect(overlay.is_open(), "%s did not open when asked" % what)
		_expect(not root.visible, "the controls stayed up underneath %s" % what)

		overlay.close()
		await _settle()
		_expect(not overlay.is_open(), "%s did not close" % what)
		_expect(root.visible, "the controls never came back after %s shut" % what)


# --- a way out without a keyboard ---------------------------------------------


## Escape was the only way out of most of these, and a phone has no Escape.
func _check_everything_closes_without_a_key() -> void:
	for screen: Array in [
		[EventBus.party_screen_requested, _party, "the party screen"],
		[EventBus.journal_requested, _journal, "the journal"],
		[EventBus.stash_requested, _stash, "the strongbox"],
		[EventBus.system_menu_requested, _menu, "the menu"],
	]:
		var opening: Signal = screen[0]
		var overlay: Node = screen[1]
		var what: String = screen[2]

		opening.emit()
		await _settle()
		overlay._unhandled_input(_action("ui_cancel"))
		await _settle()
		_expect(not overlay.is_open(), "%s would not take Back for an answer" % what)

		# And a button on the screen itself, for a player who never finds Back.
		opening.emit()
		await _settle()
		var close_btn: Button = overlay.find_child("CloseButton", true, false)
		_expect(close_btn != null, "%s has no close button on it" % what)
		if close_btn != null:
			_expect(close_btn.is_visible_in_tree(), "%s's close button is not on screen" % what)
			close_btn.pressed.emit()
			await _settle()
			_expect(not overlay.is_open(), "%s's close button did not close it" % what)

	# The overlay's own Back sends the same thing every screen already answers.
	var back: Button = _touch.get_node("Root").find_child("BackButton", true, false)
	_expect(back != null, "the touch overlay has no Back button")

	# And a half-given battle order can be taken back without a right-click.
	await _enter("battle")
	var battle := _current_scene()
	if battle != null:
		var cancel: Button = battle.hud.find_child("CancelButton", true, false)
		_expect(cancel != null, "the fight has no cancel button")
		if cancel != null:
			_expect(
				not cancel.visible,
				"the fight offers cancel with nothing half-given to cancel"
			)
			battle.phase = battle.Phase.PICK_MOVE
			_expect(cancel.visible, "the fight hid cancel while an order was half given")
			battle.phase = battle.Phase.COMMAND
	_check_the_overlay_keeps_off_the_hud("battle")
	await _enter("world")
	await _clear_dialogue()


# --- the overlay keeps off the HUD --------------------------------------------


## The overlay is a layer above every scene's own buttons, so anything of its
## own laid over one of theirs cannot be pressed at all.
func _check_the_overlay_keeps_off_the_hud(where: String) -> void:
	if get_viewport().get_visible_rect().size != Vector2(WINDOW):
		# Geometry only means something at the size the anchors were drawn for.
		return
	var scene := _current_scene()
	if scene == null:
		return
	for mine: Button in _visible_buttons(_touch):
		for theirs: Button in _visible_buttons(scene):
			_expect(
				not mine.get_global_rect().intersects(theirs.get_global_rect()),
				"in the %s scene the overlay's %s covers the %s" % [where, mine.name, theirs.name]
			)


func _visible_buttons(under: Node) -> Array[Button]:
	var out: Array[Button] = []
	for node in under.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.is_visible_in_tree():
			out.append(button)
	return out


# --- the overlay reads the scene ----------------------------------------------


## A stick under the thumb is right on the road and wrong everywhere else: over
## a fight it covers the commands, and over a menu it covers the menu.
func _check_the_overlay_reads_the_scene() -> void:
	var root: Control = _touch.get_node("Root")
	var steer: Control = _touch.get_node("Root").find_child("Steer", true, false)
	var cluster: Control = _touch.get_node("Root").find_child("Cluster", true, false)

	for expected: Array in [
		["title", false, false],
		["cinematic", false, false],
		["battle", true, false],
		["world", true, true],
		["area", true, true],
	]:
		var scene_key: String = expected[0]
		await _enter(scene_key)
		await _clear_dialogue()
		_expect(
			root.visible == bool(expected[1]),
			"the overlay is %s in the %s scene" % [
				"up" if root.visible else "gone", scene_key
			]
		)
		_expect(
			steer.visible == bool(expected[2]) and cluster.visible == bool(expected[2]),
			"the stick is %s in the %s scene" % [
				"out" if steer.visible else "away", scene_key
			]
		)
		if bool(expected[1]):
			_check_the_overlay_keeps_off_the_hud(scene_key)


# --- the party screen ---------------------------------------------------------


## One card each, every card pressable, and every page able to build for
## anybody. The old screen put everyone's whole sheet on one scroll; this one
## has three pages that can each be wrong on their own.
func _check_the_party_screen() -> void:
	for item: String in ["steel_blade", "padded_coat", "travel_bread"]:
		GameState.stores.append(item)
	_party.open()

	var party := GameState.roster.party_members()
	var cards := _party._roster_list.get_child_count()
	_expect(cards == party.size(), "%d in the party but %d cards" % [party.size(), cards])
	for card in _party._roster_list.get_children():
		_expect(
			not (card as Control).find_children("*", "Button", true, false).is_empty(),
			"a party card is not pressable"
		)

	for member: Character in party:
		_party._show_character(member)
		for page in [PartyScreen.Page.GEAR, PartyScreen.Page.POWERS, PartyScreen.Page.PRACTICE]:
			_party._turn_to(page)
			_expect(
				_party._head.get_child_count() > 0,
				"%s's page %d built no heading" % [member.display_name, page]
			)

		# What the equip screen promises is what the fight will actually give.
		for equipment_id: String in Gear.offers(member):
			var promised := _party._attack_with(member, equipment_id)
			var carried := Gear.bonus(equipment_id, member)
			_expect(
				promised == member.attack() + int(carried.get("attack", 0)),
				"the equip screen promises %s an attack the fight would not give" % member.display_name
			)
			break
	_party.close()
	print("party screen: %d cards, three pages each" % cards)


# --- plumbing -----------------------------------------------------------------


func _enter(scene_key: String) -> void:
	var payload := {"area_id": "village"} if scene_key == "area" else {}
	EventBus.request_scene.emit(scene_key, payload)
	await _settle()


## Anything the scene opened of its own accord, answered, so the next check
## starts from a clear screen.
func _clear_dialogue() -> void:
	for _i in 40:
		if not _dialogue.is_open():
			break
		_dialogue._advance()
	await _settle()


func _current_scene() -> Node:
	var container: Node = _game.get_node("CurrentScene")
	return container.get_child(0) if container.get_child_count() > 0 else null


func _anything_open() -> bool:
	for overlay in get_tree().get_nodes_in_group(EventBus.MODAL_OVERLAY_GROUP):
		if overlay.has_method("is_open") and overlay.is_open():
			return true
	return false


func _action(action_name: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = true
	event.strength = 1.0
	return event


func _settle() -> void:
	for _i in SETTLE:
		await get_tree().process_frame


func _expect(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)
