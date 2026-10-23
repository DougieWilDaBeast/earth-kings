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
const AutoRoad := preload("res://src/world/auto_road.gd")
const ScreenLayout := preload("res://src/ui/screen_layout.gd")

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
	await _check_the_box_fits_its_words()
	await _check_the_screen_arranged()
	_check_settings_are_kept()
	await _check_the_music()
	await _check_the_play_log()
	await _check_the_credits()
	await _check_tips_and_how_to_play()
	await _check_the_pad()
	await _check_the_mouse_bar()
	await _check_the_ground_is_the_game()
	await _check_a_band_on_the_ground()
	await _check_a_roadside_fight_on_the_ground()
	await _check_the_camera_at_speed()
	await _check_a_long_press()

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

	for scene_key: String in ["title", "skirmish", "world", "area"]:
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
## A finger held still asks what a thing is instead of pressing it ([D388]): the button's tip comes
## up, the scene is told where, the lift is not a press, and a finger that moves is not holding.
func _check_a_long_press() -> void:
	var asked: Array[Vector2] = []
	var listen := func(at: Vector2) -> void: asked.append(at)
	EventBus.touch_held.connect(listen)
	var button := Button.new()
	button.text = "Ask me"
	button.tooltip_text = "What this button does."
	button.position = Vector2(400, 300)
	button.size = Vector2(160, 60)
	var layer := CanvasLayer.new()
	layer.layer = 50
	layer.add_child(button)
	add_child(layer)
	await get_tree().process_frame
	var at := button.get_global_rect().get_center()
	var moved := InputEventMouseMotion.new()
	moved.position = at
	moved.global_position = at
	Input.parse_input_event(moved)
	await get_tree().process_frame
	_expect(_touch.tip_at(at) == "What this button does.", "a held finger would not read the button's tip: '%s'" % _touch.tip_at(at))

	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = at
	_touch._hold_input(down)
	_touch._hold_since -= 1000
	_touch._process(0.016)
	_expect(asked == [at], "holding a finger still did not tell the scene where (D388)")
	_expect(_touch.tip_shown() == "What this button does.", "holding a finger on a button did not show its tip (D388)")
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = at
	_touch._hold_input(up)
	var lift := InputEventMouseButton.new()
	lift.button_index = MOUSE_BUTTON_LEFT
	lift.pressed = false
	lift.position = at
	_expect(_touch._hold_input(lift), "the lift after a hold would still press what was under it (D388)")

	asked.clear()
	_touch._hold_input(down)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = at + Vector2(40, 0)
	_touch._hold_input(drag)
	_touch._hold_since -= 1000
	_touch._process(0.016)
	_expect(asked.is_empty(), "a finger that moved was taken for a hold (D388)")
	_touch._hold_input(up)
	_expect(not _touch._hold_input(lift), "a plain tap's lift was eaten as a hold's (D388)")
	_touch._hide_tip()
	EventBus.touch_held.disconnect(listen)
	layer.queue_free()
	await get_tree().process_frame


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
	_expect(not _journal.is_showing(), "a synthesised action reached a bare-letter shortcut")
	# A raw touch must fall through the letter block rather than be read as one.
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = Vector2(10, 10)
	world._unhandled_input(touch)
	_expect(not _journal.is_showing(), "a screen touch was read as a letter key")
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
			# Books and boats are hidden for the First Hour (D97), and so offered nowhere.
			[not FirstHour.hides("grimoires") and not Grimoire.offer(site).is_empty(), "for the book", "the book"],
			[not FirstHour.hides("ferries") and Ferry.is_port(GameState.world, site.cell) \
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

	# The journal at the side lets the walk go on, so the controls stay up with it (D271);
	# opened over the whole screen it takes them away like the rest.
	var was_docked: bool = JournalScreen.docked
	JournalScreen.docked = true
	EventBus.journal_requested.emit()
	await _settle()
	_expect(_journal.is_showing() and not _journal.is_open(), "the journal did not open at the side")
	_expect(root.visible, "the controls went away under the journal at the side")
	_journal.close()
	await _settle()
	JournalScreen.docked = false

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
	JournalScreen.docked = was_docked


# --- a way out without a keyboard ---------------------------------------------


## On screen at all: the journal at the side is up without holding the game (D271).
func _up(overlay: Node) -> bool:
	return overlay.is_showing() if overlay.has_method("is_showing") else overlay.is_open()


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
		_expect(not _up(overlay), "%s would not take Back for an answer" % what)

		# And a button on the screen itself, for a player who never finds Back.
		opening.emit()
		await _settle()
		var close_btn: Button = overlay.find_child("CloseButton", true, false)
		_expect(close_btn != null, "%s has no close button on it" % what)
		if close_btn != null:
			_expect(close_btn.is_visible_in_tree(), "%s's close button is not on screen" % what)
			close_btn.pressed.emit()
			await _settle()
			_expect(not _up(overlay), "%s's close button did not close it" % what)

	# The overlay's own Back sends the same thing every screen already answers.
	var back: Button = _touch.get_node("Root").find_child("BackButton", true, false)
	_expect(back != null, "the touch overlay has no Back button")

	# And a half-given order in a fight can be taken back without a right-click:
	# the overlay's Back puts a readied skill away, and with nothing readied it
	# is the menu, as it is everywhere else.
	await _enter("skirmish")
	var fight := _current_scene()
	if fight != null:
		var caster = null
		for f in fight.party_fighters():
			if not f.slots.is_empty() and str(f.slot_ability(0).get("target", "enemy")) != "self":
				caster = f
				break
		if caster != null:
			fight._select([caster])
			fight.act("slot0")
			_expect(fight.armed_slot == 0, "a skill could not be readied in the fight")
			fight._unhandled_input(_action("ui_cancel"))
			_expect(fight.armed_slot == -1, "Back did not put a readied skill away")
			_expect(not _menu.is_open(), "Back opened the menu while it had a skill to put away")
		fight._unhandled_input(_action("ui_cancel"))
		await _settle()
		_expect(_menu.is_open(), "Back with nothing readied did not bring up the menu in a fight")
		_menu.close()
		await _settle()
	_check_the_overlay_keeps_off_the_hud("skirmish")
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
		["skirmish", true, false],
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
	var payload := {}
	if scene_key == "area":
		payload = {"area_id": "village"}
	elif scene_key == "world":
		# The walk's own controls are what is checked here; left to itself the
		# continent hands straight on to the ground ([D61]).
		payload = {"walk": true}
	EventBus.request_scene.emit(scene_key, payload)
	await _settle()


## Play-test 7: "the text boxes around the text are way too big." A line said on the land is in a box
## only as tall as its lines and, when short, only as wide as its words; a long one is kept on the
## screen. The suite runs as a touchscreen, where the box used to stand 300 high whatever it said.
func _check_the_box_fits_its_words() -> void:
	await _clear_dialogue()
	var panel: Control = _dialogue.get_node("Panel")
	var screen: Rect2 = _dialogue.get_viewport().get_visible_rect()
	var widths: Array[float] = []
	for text: String in ["Something left here.", "New down, are you? Nobody climbs the Tower without the Guild's mark, and the mark is earned at a gate. Greyhollow is open and near. Shut it, then find me at the Tower's door. ".repeat(3)]:
		EventBus.conversation_requested.emit([{ "speaker": "Sennet", "text": text }])
		await _settle()
		var need := panel.get_combined_minimum_size().y
		if panel.size.y > need + 2.0:
			_failures.append("the talk box stands %d high for %d of words: \"%s\"" % [panel.size.y, need, text.left(30)])
		if not screen.grow(1.0).encloses(panel.get_global_rect()):
			_failures.append("the talk box runs off the screen: %s on %s" % [panel.get_global_rect(), screen])
		widths.append(panel.size.x)
		await _clear_dialogue()
	if widths.size() == 2 and widths[0] >= widths[1]:
		_failures.append("a short line is in as wide a box as a long one (%d, %d)" % [widths[0], widths[1]])
	# And the hint line's strip along the bottom of the ground is as long as what it says.
	var strips := 0
	for area: Node in get_tree().root.find_children("*", "", true, false):
		if not area.has_method("_fit_the_hint"):
			continue
		strips += 1
		var hint: Label = area.get("_hint")
		var said := hint.get_theme_font("font").get_string_size(hint.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
				hint.get_theme_font_size("font_size")).x
		if hint.text != "" and hint.size.x > said + 40.0:
			_failures.append("the hint strip is %d long for %d of words: \"%s\"" % [hint.size.x, said, hint.text.left(30)])
	print("talk box: %d wide for a short line, %d for a long one; %d hint strip(s) fitted" % [widths[0], widths[1], strips])


## The play screen arranged by hand ([D351], Ewan's play-test 8): every panel framed, moved where it
## is dragged, the log's box sized at its corner, the company grown with the wheel, the box people talk
## in moved, all of it kept for the next time the ground is walked, never quite off the screen, and
## put back with one press.
func _check_the_screen_arranged() -> void:
	await _clear_dialogue()
	var ground: Node = null
	for each: Node in get_tree().root.find_children("*", "", true, false):
		if each.has_method("_hold_the_panels"):
			ground = each
	_expect(ground != null and ground.get("_screen_layout") != null, "the ground has no way to arrange its panels")
	if ground == null or ground.get("_screen_layout") == null:
		return
	var layout: Control = ground._screen_layout
	layout.put_back()
	var log_label: Label = ground._log
	var was := log_label.get_global_rect()
	EventBus.screen_arrange_requested.emit()
	_expect(layout.is_arranging() and layout.get_node("ArrangeBar").visible, "asking to arrange the screen did not frame its panels")
	var frames: Dictionary = layout.frames()
	for id: String in ["place", "compass", "hud", "log", "hint", "words"]:
		_expect(frames.has(id), "no frame round the %s while arranging" % id)
	_expect(ground.get("_corner_map") == null or frames.has("map"), "no frame round the corner map while arranging")
	layout.drag("log", Vector2(200, -150))
	await _settle()
	_expect(log_label.get_global_rect().position.distance_to(was.position + Vector2(200, -150)) < 2.0,
		"the log was dragged by (200, -150) and stands at %s from %s" % [log_label.get_global_rect().position, was.position])
	var moved := log_label.get_global_rect()
	layout.drag("log", Vector2(-100, 60), true)
	await _settle()
	_expect(absf(log_label.size.x - (moved.size.x - 100.0)) < 2.0 and absf(log_label.size.y - (moved.size.y + 60.0)) < 2.0,
		"the log's corner was dragged and its box is %s from %s" % [log_label.size, moved.size])
	var hud: Control = ground._play_hud
	layout.grow("hud", 0.2)
	_expect(is_equal_approx(hud.scale.x, 1.2), "the wheel over the company did not grow it (%s)" % hud.scale)
	layout.drag("hud", Vector2(-5000, 0))
	_expect(hud.get_global_rect().end.x >= 39.0, "the company was dragged clean off the screen")
	layout.drag("words", Vector2(0, -200))
	layout.finish()
	_expect(not layout.is_arranging(), "Done did not end arranging")
	var panel: Control = _dialogue.get_node("Panel")
	EventBus.conversation_requested.emit([{ "speaker": "Sennet", "text": "Over here now." }])
	await _settle()
	var screen := panel.get_viewport().get_visible_rect().size
	_expect(absf(panel.get_global_rect().end.y - (screen.y - 14.0 - 200.0)) < 3.0,
		"the box people talk in was moved up 200 and its bottom is at %d of %d" % [panel.get_global_rect().end.y, screen.y])
	await _clear_dialogue()
	# Walked again, the ground lays its panels where they were left.
	var kept := log_label.get_global_rect()
	EventBus.request_scene.emit("world", {})
	await _settle()
	await _clear_dialogue()
	ground = _current_scene()
	if ground != null and ground.get("_log") != null:
		_expect(ground._log.get_global_rect().position.distance_to(kept.position) < 2.0 and absf(ground._log.size.x - kept.size.x) < 2.0,
			"the log was not where it was left when the ground came back: %s, left at %s" % [ground._log.get_global_rect(), kept])
		ground._screen_layout.put_back()
		await _settle()
		_expect(ground._log.get_global_rect().position.distance_to(was.position) < 2.0 and ScreenLayout.saved_all().is_empty(),
			"Put It All Back left the log at %s (it began at %s)" % [ground._log.get_global_rect().position, was.position])
	print("arranged: log moved and sized, company grown, the talk box moved, kept, and put back")


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


# --- the credits ---------------------------------------------------------------


## The credits open off the title and off the menu, say something, and Back
## takes the player out of both. The engine's licence in `data/credits.json`
## is the one Godot itself carries, word for word, as its licence asks.
func _check_the_credits() -> void:
	await _enter("title")
	var title := _current_scene()
	var credits_btn: Button = title.find_child("CreditsButton", true, false) if title != null else null
	_expect(credits_btn != null, "the title screen has no Credits entry")
	if credits_btn != null:
		credits_btn.pressed.emit()
		await _settle()
		var screen := _current_scene()
		_expect(
			screen != null and screen.name == "CreditsScreen",
			"the Credits entry did not open the credits"
		)
		if screen != null and screen.name == "CreditsScreen":
			var list: VBoxContainer = screen.find_child("CreditsList", true, false)
			_expect(list != null and list.get_child_count() > 8, "the credits screen is empty")
			screen._unhandled_input(_action("ui_cancel"))
			await _settle()
			var back := _current_scene()
			_expect(
				back != null and back.name == "TitleScreen",
				"Back did not take the credits screen to the title"
			)

	var credits: Dictionary = load("res://src/ui/credits_roll.gd").read()
	var notice := ""
	for section: Dictionary in credits.get("sections", []):
		if str(section.get("heading", "")) == "Engine":
			notice = str(section.get("notice", ""))
	_expect(
		notice.strip_edges() == Engine.get_license_text().strip_edges(),
		"the Godot licence in data/credits.json is not the engine's own text"
	)

	EventBus.system_menu_requested.emit()
	await _settle()
	var panel: Control = _menu.find_child("CreditsPanel", true, false)
	var menu_btn: Button = _menu.find_child("CreditsButton", true, false)
	_expect(panel != null and menu_btn != null, "the system menu has no credits page")
	if panel != null and menu_btn != null:
		menu_btn.pressed.emit()
		await _settle()
		_expect(panel.visible, "the menu's Credits button did not show the credits")
		_menu._unhandled_input(_action("ui_cancel"))
		await _settle()
		_expect(not panel.visible and _menu.is_open(), "Back from the menu's credits did not return to the menu")
	_menu.close()
	await _settle()


# --- settings are kept ---------------------------------------------------------


## The sound and fullscreen controls in the system menu reach the game and are
## written to settings.cfg, so they hold across a restart. The player's own
## values are put back afterwards.
func _check_settings_are_kept() -> void:
	var sfx_was := Sfx.volume
	var fullscreen_was := Pace.fullscreen
	var slider: HSlider = _menu.get_node("%SfxSlider")
	var fullscreen: Button = _menu.get_node("%FullscreenButton")

	slider.value = 0.25
	_expect(is_equal_approx(Sfx.volume, 0.25), "the sounds slider does not move the sound volume")
	fullscreen.button_pressed = not fullscreen_was
	_expect(Pace.fullscreen != fullscreen_was, "the fullscreen button does not reach the game")

	var config := ConfigFile.new()
	config.load(Pace.SETTINGS_PATH)
	_expect(
		is_equal_approx(float(config.get_value("audio", "sfx_volume", -1.0)), 0.25),
		"the sound volume is not written to settings.cfg"
	)
	_expect(
		bool(config.get_value("display", "fullscreen", fullscreen_was)) != fullscreen_was,
		"fullscreen is not written to settings.cfg"
	)

	Pace.toggle_fullscreen()
	_expect(Pace.fullscreen == fullscreen_was, "the fullscreen key does not switch it back")
	_expect(
		fullscreen.button_pressed == fullscreen_was,
		"the fullscreen button does not follow the fullscreen key"
	)
	slider.value = sfx_was


# --- the music ------------------------------------------------------------------


## Every set `data/music.json` names is there and every track in it is on disk; none
## of the fan covers is ever one of them (D100). A place's set wins over the scene's,
## a chapter one's memory over the place's while it is open, and anywhere the file
## does not list hears the scene's own (D185).
func _check_the_music() -> void:
	var music: Dictionary = Database.music
	var sets: Dictionary = music.get("sets", {})
	for table: String in ["scenes", "places", "dialogues"]:
		var named: Dictionary = music.get(table, {})
		for key: String in named:
			_expect(sets.has(str(named[key])), "music.json %s.%s names no set" % [table, key])
	for set_id: String in sets:
		for track: Dictionary in sets[set_id]:
			var path := str(track.get("path", ""))
			_expect(ResourceLoader.exists(path), "the %s music's %s is not on disk" % [set_id, path])
			_expect(not path.ends_with(".mp3"), "the %s music plays a fan cover: %s" % [set_id, path])
	# A bus made at runtime is silent in the browser build (D234): both come from the layout.
	var layout: AudioBusLayout = load("res://default_bus_layout.tres")
	for bus: String in [Music.BUS, Sfx.BUS]:
		var named_in_layout := false
		for i in range(1, 8):
			named_in_layout = named_in_layout or str(layout.get("bus/%d/name" % i)) == bus
		_expect(named_in_layout, "the %s bus is not in default_bus_layout.tres" % bus)
	Music.for_scene("area")
	EventBus.place_entered.emit("tower_floor_3")
	await _settle()
	_expect(Music.playing_set() == "tower", "a Tower floor did not hear the Tower's music (%s)" % Music.playing_set())
	Music._on_dialogue_requested("memory_atlas")
	_expect(Music.playing_set() == "memory", "a chapter one did not hear the memory theme")
	Music._on_dialogue_finished("memory_atlas")
	_expect(Music.playing_set() == "tower", "the memory theme did not give way to the floor's music again")
	EventBus.place_entered.emit("land_0_0_grassland")
	_expect(Music.playing_set() == "road", "open country did not hear the road's music (%s)" % Music.playing_set())
	EventBus.place_entered.emit("home")
	_expect(Music.playing_set() == "crater", "the crater did not hear its own music")
	Music.for_scene(_game.get("_scene_key"))
	await _settle()


# --- the play log ---------------------------------------------------------------


## What a play-tester did is written down as they do it, steps counted not
## listed, the engine's complaints included, and the menu hands it over (D125).
func _check_the_play_log() -> void:
	_expect(PlayLog.text().contains("=== game opened"), "the play log does not mark the game opening")
	for i in 3:
		EventBus.player_did.emit("walked")
	PlayLog.call("_on_battle_started", "test_map")
	PlayLog.call("_on_battle_finished", { "victory": true, "map_id": "test_map" })
	push_warning("the play log hears this")
	await _settle()
	var said := PlayLog.text()
	_expect(said.contains("walked 3 steps"), "the play log does not count steps: %s" % said.right(300))
	_expect(said.contains("FIGHT test_map") and said.contains("WON"), "the play log misses a fight and its end")
	_expect(said.contains("the play log hears this"), "the play log misses the engine's warnings")
	_expect(said.split("\n").size() <= PlayLog.MAX_LINES + 2, "the play log outgrows its cap")
	_menu.open()
	(_menu.get_node("%SaveLogButton") as Button).pressed.emit()
	_expect(FileAccess.file_exists(PlayLog.PATH), "Save play log does not leave the log in user://")
	_expect(
		FileAccess.get_file_as_string(PlayLog.PATH).contains("FIGHT test_map"),
		"the play log file is not the log"
	)
	(_menu.get_node("%CopyLogButton") as Button).pressed.emit()
	_expect((_menu.get_node("%StatusLabel") as Label).text.contains("copied"), "Copy play log says nothing")
	_menu.close()


# --- tips and how to play ------------------------------------------------------


## A tip is said once, never while the game plays itself, and not at all with
## tips off. How to Play opens over the menu and Back shuts the page, not the
## menu under it. The player's own tip record is put back afterwards.
func _check_tips_and_how_to_play() -> void:
	var tips := preload("res://src/ui/tips.gd")
	var config := ConfigFile.new()
	config.load(Pace.SETTINGS_PATH)
	var seen_was: Variant = config.get_value("tips", "seen", PackedStringArray())
	var enabled_was := tips.enabled()
	var card: Node = _game.get_node("TipCard")

	var ids := {}
	for tip: Dictionary in tips.all():
		var id := str(tip.get("id", ""))
		_expect(id != "" and not ids.has(id), "tip '%s' has no id or shares one" % id)
		ids[id] = true
		for field: String in ["when", "title", "text"]:
			_expect(str(tip.get(field, "")) != "", "tip '%s' has no %s" % [id, field])

	tips.reset()
	tips.set_enabled(true)
	card._queue.clear()
	card.dismiss()
	Pace.auto = true
	EventBus.tip_moment.emit("errand", {})
	_expect(not card.is_showing(), "a tip was shown while the game was playing itself")
	_expect(not tips.seen("errand"), "a tip was spent while the game was playing itself")
	Pace.auto = false
	EventBus.tip_moment.emit("errand", {})
	_expect(card.showing_id() == "errand", "the errand tip was not shown the first time")
	card.dismiss()
	EventBus.tip_moment.emit("errand", {})
	_expect(not card.is_showing(), "the errand tip was shown a second time")
	tips.reset()
	tips.set_enabled(false)
	EventBus.tip_moment.emit("errand", {})
	_expect(not card.is_showing(), "a tip was shown with tips switched off")

	var page: Node = _game.get_node("HowToPlay")
	EventBus.system_menu_requested.emit()
	EventBus.how_to_play_requested.emit()
	await _settle()
	_expect(page.is_open(), "How to Play did not open from the menu")
	var said: String = page.get_node("Root").find_child("Body", true, false).get_parsed_text()
	for section: Dictionary in page.sections():
		if bool(section.get("touch", false)) and not Pace.is_touch_enabled():
			continue
		_expect(said.contains(str(section["heading"])), "How to Play is missing %s" % section["heading"])
	var cancel := _action("ui_cancel")
	Input.parse_input_event(cancel)
	await _settle()
	_expect(not page.is_open(), "Back did not shut How to Play")
	_expect(_menu.is_open(), "Back shut the menu under How to Play as well")
	_menu.close()
	print("tips: %d, how to play: %d sections" % [ids.size(), page.sections().size()])

	# A phone's words ([D377]): a line written for a keyboard is said for a thumb with the touch
	# controls on, and left as it was with them off; How to Play opens on "On a phone".
	var mode_was := Pace.touch_mode
	Pace.touch_mode = "on"
	var thumb := Pad.say("WASD to walk  ·  E to talk  ·  H to hire Ganel  ·  click anyone marked  ·  P or Esc to close")
	_expect(thumb == "The stick walks  ·  Act to talk  ·  Tap to hire Ganel  ·  tap anyone marked  ·  Close shuts it",
			"a line said for a thumb read \"%s\"" % thumb)
	_expect(Pad.key("open_party") == "Party" and Pad.walk_text() == "The stick", "the touch bar's names were not used")
	for tip: Dictionary in tips.all():
		var words := str(tip.get("touch", ""))
		var check := words if words != "" else Pad.say(str(tip.get("text", "")))
		for key: String in ["WASD", "Esc ", "right-click", "Right-click", "Space ", " P ", " Q "]:
			_expect(not check.contains(key), "tip '%s' says %s on a phone: %s" % [tip["id"], key.strip_edges(), check])
	EventBus.how_to_play_requested.emit()
	await _settle()
	var phone_page: String = page.get_node("Root").find_child("Body", true, false).get_parsed_text()
	_expect(phone_page.begins_with("On a phone"), "How to Play did not open on its phone page with touch on")
	page.close()
	Pace.touch_mode = "off"
	_expect(Pad.say("WASD to walk") == "WASD to walk", "a keyboard's line was changed with touch off")
	EventBus.how_to_play_requested.emit()
	await _settle()
	_expect(not page.get_node("Root").find_child("Body", true, false).get_parsed_text().contains("On a phone"),
			"How to Play showed its phone page with touch off")
	page.close()
	Pace.touch_mode = mode_was

	tips.set_enabled(enabled_was)
	config = ConfigFile.new()
	config.load(Pace.SETTINGS_PATH)
	config.set_value("tips", "seen", seen_was)
	config.save(Pace.SETTINGS_PATH)


func _expect(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)


# --- a pad in the hands ---------------------------------------------------------


## Every verb a pad needs has a button, the hint lines say the pad's buttons
## once a pad has been touched, a menu opened under a pad has its focus on a
## button, B and Start do what Escape does, and a fight can be given an order
## without a mouse.
func _check_the_pad() -> void:
	for action: String in [
		"move_up", "move_down", "move_left", "move_right", "interact", "ui_accept", "ui_cancel",
		"open_menu", "open_party", "open_actions", "open_journal", "cycle_next", "command_wait",
		"battle_speed", "camera_zoom_in", "camera_zoom_out", "camera_recentre",
	]:
		_expect(Pad.pad_glyph(action) != "", "%s has no button on a pad" % action)
	for action: String in ["interact", "open_party", "cycle_next", "command_wait", "ui_cancel"]:
		_expect(Pad.key_text(action) != "", "%s lost its key when the pad was added" % action)

	await _enter("world")
	await _clear_dialogue()
	var world := _current_scene()
	Pad.set_using_pad(false)
	# The suite plays with the touch bar on, which says its own names ([D377]): a keyboard is asked
	# with it off.
	Pace.touch_mode = "off"
	_expect(Pad.key("interact") == "E", "the keyboard hint for interact is not E")
	Pace.touch_mode = "on"
	_expect(Pad.key("interact") == "Act", "the touch hint for interact is not Act")
	Pad.set_using_pad(true)
	_expect(Pad.key("interact") == "A", "the pad hint for interact is not A")
	if world != null:
		_expect(world._key("open_menu", "Esc") == "Start", "the walk does not say Start for the menu on a pad")
		_expect(world._key("site_hire") == "Y", "a verb with no button does not point a pad at its buttons")

	# Start opens the menu from the walk, focus lands on it, and B shuts it.
	_game._unhandled_input(_pad_button(JOY_BUTTON_START))
	await _settle()
	_expect(_menu.is_open(), "Start did not open the menu from the walk")
	var focused := get_viewport().gui_get_focus_owner()
	_expect(
		focused != null and _menu.is_ancestor_of(focused),
		"the menu opened under a pad with nothing focused"
	)
	_menu._unhandled_input(_pad_button(JOY_BUTTON_B))
	await _settle()
	_expect(not _menu.is_open(), "B did not close the menu")

	# A fight: the cursor starts on whoever is picked, and A gives the order there.
	await _enter("skirmish")
	var fight := _current_scene()
	if fight != null and not fight.selected.is_empty():
		var mover = fight.selected[0]
		fight._steer_pad_cursor(0.0)
		_expect(fight.pad_cell == mover.unit.cell, "the pad's cursor did not start on the picked fighter")
		var goal := Vector2i(-1, -1)
		for cell: Vector2i in fight.pathfinder.cells_in_range(mover.unit.cell, 1, 2):
			if fight.grid.is_walkable(cell) and fight.occupant(cell) == null:
				goal = cell
				break
		if goal != Vector2i(-1, -1):
			fight._aim_at(goal)
			fight._unhandled_input(_pad_button(JOY_BUTTON_A))
			_expect(mover.order_cell == goal and mover.order != 0, "A at the cursor gave no move order")
		# B with nothing readied is the menu, as Escape is.
		fight._unhandled_input(_pad_button(JOY_BUTTON_B))
		await _settle()
		_expect(_menu.is_open(), "B in a fight did not bring up the menu")
		_menu.close()
		await _settle()
		print("pad: an order given at the cursor")
	Pad.set_using_pad(false)
	await _enter("world")
	await _clear_dialogue()


# --- the ground is the game ----------------------------------------------------


## The planar view is where the game is played and the continent is a map kept
## in the journal ([D61]). Coming back from anywhere lands on the ground, which is the land
## ([D84]) with the town standing in its tile; the journal's map comes back to the same ground; a
## place's doings are offered and done from the ground; walking over into the next tile moves the
## party on the continent without the ground ever leaving the screen.
func _check_the_ground_is_the_game() -> void:
	var world: World = GameState.world
	var town: Site = null
	for site: Site in world.sites:
		if site.kind != Site.VILLAGE or site.data.has("ward") or Town.is_threatened(site) or Town.is_ruined(site) \
				or not Database.has_area(str(site.data.get("area", site.kind))):
			continue
		# A town stocks its tavern when somebody rests in it.
		Market.refresh(site, world)
		if not Market.hire_offer(site).is_empty():
			town = site
			break
	_expect(town != null, "no town with somebody to hire and an inside to walk")
	if town == null:
		return
	world.player_cell = town.cell
	GameState.gold = 100000
	EventBus.request_scene.emit("world", {})
	await _settle()
	await _clear_dialogue()
	var ground := _current_scene()
	_expect(ground != null and ground.get("map") is AreaMap, "coming back to the continent did not land on the ground")
	if ground == null or not ground.get("map") is AreaMap:
		return
	var area_id: String = ground.map.id
	_expect(area_id == "land" and ground.map.call("area_of", ground.map.cell_at(ground._leader.position)) == str(town.data.get("area", town.kind)),
		"the land at %s is not the town standing in its tile" % town.display_name)
	var hire: Dictionary = {}
	for each: Dictionary in ground._acts:
		if str(each.get("act", "")) == "_hire_here":
			hire = each
	_expect(not hire.is_empty(), "hiring at %s is not offered from the ground" % town.display_name)
	_expect(ground._prompt_text().contains("to hire"), "the ground's hint does not say there is somebody to hire")
	_expect(ground._act_bar != null, "a thumb has no buttons for the place's doings on the ground")
	_check_the_overlay_keeps_off_the_hud("ground")

	# The compass points at the objective (D95).
	ground._point_the_compass()
	_expect(ground._compass != null and ground._compass.has_meta("aimed"), "the ground has no compass pointing anywhere")

	# The map is the journal's, opened with M straight from the ground (D95). On the land it opens
	# over the ground, which goes on under it (D232): the same ground, the keys looking about the
	# map rather than walking, and M or Esc putting it away.
	var m := InputEventKey.new()
	m.keycode = KEY_M
	m.pressed = true
	var was_ground := ground
	ground._unhandled_input(m)
	await _settle()
	var screen: CanvasLayer = ground.get("_map_screen")
	_expect(_current_scene() == was_ground, "M on the land left the ground for a map screen")
	_expect(screen != null and screen.is_open(), "M on the land did not open the map over the ground")
	_expect(ground.get("_corner_map") != null, "the land has no map in its corner")
	if screen != null and screen.is_open():
		_expect(not (ground.get("_corner_map") as Control).visible, "the corner map stays up under the large one")
		var stood: Vector2 = ground._leader.position
		Input.action_press("move_right")
		for i in 10:
			ground._physics_process(1.0 / 60.0)
		Input.action_release("move_right")
		_expect(ground._leader.position == stood, "with the map open the keys walked the party instead of moving the map")
		screen._input(_action("ui_cancel"))
		await _settle()
		_expect(not screen.is_open(), "Esc did not put the map away")
		# A click on the corner map opens the large one; a right-click on a place offers Go here
		# and Place a marker, and a marker placed can be taken off again (D232).
		var corner: Control = ground.get("_corner_map")
		corner._click(Vector2(4.0, 4.0))
		_expect(screen.is_open(), "a click on the corner map did not open the large map")
		var big: Control = screen.get("map")
		var spot := world.player_cell + Vector2i(2, 0)
		var offered: Array[int] = big.menu_for(spot)
		_expect(offered == [big.MENU_GO, big.MENU_MARK], "a right-click on the map offers %s, not Go here and Place a marker" % [offered])
		big.choose(spot, big.MENU_MARK)
		_expect(not preload("res://src/world/markers.gd").at(spot).is_empty(), "Place a marker put no marker down")
		_expect(big.menu_for(spot).has(big.MENU_UNMARK), "a marker on the map cannot be taken off")
		big.choose(spot, big.MENU_UNMARK)
		_expect(preload("res://src/world/markers.gd").all().is_empty(), "Take the marker off left it")
		screen.close()
		await _settle()
	ground = _current_scene()
	_expect(ground != null and ground.get("map") is AreaMap and ground.map.id == area_id, "putting the map away did not come back to the same ground")
	if ground == null or not ground.get("map") is AreaMap:
		return

	# A doing asked for on the ground is done, and play comes straight back.
	if not hire.is_empty():
		var before := GameState.roster.characters.size()
		ground._do_act(hire)
		await _settle()
		await _clear_dialogue()
		ground = _current_scene()
		_expect(GameState.roster.characters.size() > before or not GameState.roster.has_room(),
			"hiring from the ground hired nobody")
		_expect(ground != null and ground.get("map") is AreaMap, "a doing on the ground did not come back to the ground")
		if ground == null or not ground.get("map") is AreaMap:
			return

	# Over into the next tile: the continent takes the step out of sight, and the land stays.
	var dir := Vector2i.ZERO
	for each: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var next := world.player_cell + each
		if world.in_bounds(next) and world.is_walkable(next) and world.prowler_watching(next) == null:
			dir = each
			break
	_expect(dir != Vector2i.ZERO, "nowhere safe to step off %s" % town.display_name)
	if dir == Vector2i.ZERO:
		return
	var from := world.player_cell
	var steps := world.steps
	var asked := _requests.size()
	var into: Vector2i = ground.map.call("slot_rect", from + dir).get_center()
	ground._leader.position = ground.map.centre_of(into)
	ground._mind_the_border()
	await _settle()
	await _clear_dialogue()
	await _settle()
	_expect(world.player_cell == from + dir, "walking over into the next tile did not move the party on the continent")
	_expect(world.steps > steps, "a step on the land did not move the world clock")
	var landed := _current_scene()
	_expect(landed == ground or _requests.slice(asked).has("skirmish") or _requests.slice(asked).has("area"),
		"a step on the land took the screen away to %s" % (landed.name if landed != null else "nothing"))
	print("ground: the map, a doing and a step on the land all keep to the land")


## A band met on the ground ([D66], [D68]): it patrols with the ground it watches painted red,
## never put down already looking at the party; a step into that red starts the real-time fight on
## that same ground, at the view it was seen in, with everyone where they stood; and afterwards play
## is back on the same spot with the band gone.
func _check_a_band_on_the_ground() -> void:
	var world: World = GameState.world
	world.prowlers.clear()
	# Open country with open country beside it, away from any place.
	var here := Vector2i(-1, -1)
	for y in range(4, world.size.y - 4):
		for x in range(4, world.size.x - 4):
			var c := Vector2i(x, y)
			if world.is_walkable(c) and world.site_at(c) == null and world.is_walkable(c + Vector2i.RIGHT) \
					and world.site_at(c + Vector2i.RIGHT) == null and world.distance_to_haven(c) > 3:
				here = c
				break
		if here.x >= 0:
			break
	_expect(here.x >= 0, "no open country to meet a band in")
	if here.x < 0:
		return
	world.player_cell = here
	var band := Prowler.create(here, ["goblin"])
	world.prowlers.append(band)
	EventBus.request_scene.emit("world", {})
	await _settle()
	await _clear_dialogue()
	var ground := _current_scene()
	_expect(ground != null and ground.get("map") is AreaMap, "the band's tile did not open on the ground")
	if ground == null or not ground.get("map") is AreaMap:
		return
	var watches: Array = ground.get("_watches")
	_expect(watches.size() == 1, "the band is not standing on the ground (%d there)" % watches.size())
	if watches.is_empty():
		return
	var ground_id: String = ground.map.id
	var on_ground: Node2D = watches[0]
	_expect(not (on_ground.watched as Dictionary).is_empty(), "the band on the ground watches nothing")
	var arrived: Vector2i = ground.map.cell_at(ground._leader.position)
	_expect(not on_ground.watched.has(arrived), "the band was put down already looking at the party")
	# It patrols (D68): give it a few seconds of the clock and the one in front has moved.
	var post: Vector2 = (on_ground.figures[0] as Node2D).position
	var patrolled := 0.0
	while patrolled < 8.0 and (on_ground.figures[0] as Node2D).position == post:
		await get_tree().create_timer(0.1).timeout
		patrolled += 0.1
	_expect((on_ground.figures[0] as Node2D).position != post, "the band stood still instead of patrolling")
	_expect(not ground._spotted, "the band's patrol walked it into sight of where the party came in")
	# The three ways of walking itself (D216): only an aggressive party turns aside for the band; a
	# passive one works its way round the band's red.
	var kept_style := Pace.auto_style
	Pace.auto_style = "aggressive"
	var aggressive_goes := AutoRoad.errand(world)
	Pace.auto_style = "mixed"
	var mixed_goes := AutoRoad.errand(world)
	_expect(Pace.AUTO_STYLES.size() == 3 and mixed_goes != band.cell, "walking itself mixed, the party still turned aside for a band")
	_expect(aggressive_goes == band.cell or Pathfinder.distance(band.cell, world.player_cell) == 0 or Pathfinder.distance(band.cell, world.player_cell) > AutoRoad.DETOUR,
			"walking itself aggressively, the party did not turn aside for the band (went for %s, band at %s)" % [aggressive_goes, band.cell])
	var red_cells: Array = (on_ground.watched as Dictionary).keys()
	var beyond: Vector2i = red_cells[0]
	for cell: Vector2i in red_cells:
		if (cell - arrived).length_squared() > (beyond - arrived).length_squared():
			beyond = cell
	beyond += Vector2i(signi(beyond.x - arrived.x), signi(beyond.y - arrived.y)) * 2
	Pace.auto_style = "passive"
	var round: Array = ground.call("_auto_way", ground.map, arrived, beyond)
	var through_red := round.any(func(p: Vector2) -> bool: return on_ground.watched.has(ground.map.cell_at(p)) and ground.map.cell_at(p) != beyond)
	var straight: Array = ground.map.find_cell_path(arrived, beyond)
	if not straight.is_empty() and not round.is_empty() and round != straight:
		_expect(not through_red, "walking itself passively, the party's way still crosses the band's red")
	Pace.auto_style = kept_style
	# A step into the red.
	var into: Vector2i = (on_ground.watched as Dictionary).keys()[0]
	var asked := _requests.size()
	ground._check_the_watch(arrived)
	ground._leader.position = ground.map.centre_of(into)
	_expect(ground._check_the_watch(into), "stepping into the red was not seen")
	# No stop before the fight (D204): it is on almost at once, with no shout to wait out and no
	# rush first. Waited on the clock, since frames run far faster than that with no screen.
	var waited := 0.0
	while waited < 3.0 and ground.get("_fight") == null:
		await get_tree().create_timer(0.05).timeout
		waited += 0.05
	_expect(waited <= 0.4, "the fight took %.2f s to start after the band saw the party (D204: no stop)" % waited)
	# Fought where it was met (D98): the same ground scene, with the fight put down on it.
	var fight: Node2D = ground.get("_fight")
	_expect(fight != null, "walking into the red did not start the fight")
	_expect(not _requests.slice(asked).has("skirmish") and _current_scene() == ground,
		"the fight changed the screen instead of being fought on the ground")
	if fight == null:
		return
	_expect(not (fight.get("ground_field") as Dictionary).is_empty(),
		"the fight was not laid out on the ground it started on")
	_expect(bool(fight.get("in_place")) and fight.get_node_or_null("Ground") == null,
		"the fight drew a second copy of the ground instead of standing on it")
	_expect(not bool(fight.get("paused")), "the fight on the ground opened paused")
	# On the open ground (D204): no box, nothing dimmed round it.
	_expect(bool(fight.grid.quiet) and not bool(fight.grid.get("_pointer_out")),
		"the fight on the ground is drawn in a box")
	var origin: Vector2i = AreaMap.to_cell(fight.get("ground_field").get("origin", [0, 0]))
	var cell_on_ground: Vector2 = fight.to_global(fight.grid.cell_to_world(Vector2i.ZERO))
	_expect(ground.map.cell_at(ground.to_local(cell_on_ground)) == origin,
		"the fight's cells are not the ground's cells")
	_expect(world.prowlers.is_empty(), "the band was still out on the continent once it was fought")
	# Over: the party walks on from the same ground, with nobody left watching.
	fight.call("emit_signal", "gone")
	await _settle()
	await _clear_dialogue()
	var after := _current_scene()
	_expect(after == ground and ground.get("_fight") == null and not bool(ground.get("_leaving")),
		"after the fight play did not carry on on the same ground")
	if after != null and after.get("map") is AreaMap:
		_expect(after.map.id == ground_id, "after the fight the ground was not the same")
		_expect((after.get("_watches") as Array).is_empty(), "the band that was fought is still standing there")
	print("band: patrolled, saw the party step in, and was fought on the same ground")


## Somebody else's fight on the road, stepped into (D207): fought on that ground where its scene is
## staged, the attackers where they stood, with no fight screen; the same for a town defended.
func _check_a_roadside_fight_on_the_ground() -> void:
	var world: World = GameState.world
	world.prowlers.clear()
	var here := Vector2i(-1, -1)
	for y in range(4, world.size.y - 4):
		for x in range(4, world.size.x - 4):
			var c := Vector2i(x, y)
			if world.is_walkable(c) and world.site_at(c) == null and world.distance_to_haven(c) > 3:
				here = c
				break
		if here.x >= 0:
			break
	if here.x < 0:
		_expect(false, "no open country for a roadside fight")
		return
	world.player_cell = here
	EventBus.request_scene.emit("world", {})
	await _settle()
	await _clear_dialogue()
	var ground := _current_scene()
	if ground == null or not ground.get("map") is AreaMap:
		_expect(false, "the roadside tile did not open on the ground")
		return
	var event := "trader_ambush"
	(ground.get("_held") as Dictionary)["roadside"] = event
	ground.call("_stage_roadside", event)
	var staged: Array = ground.get("_roadside_foes")
	_expect(not staged.is_empty(), "the roadside scene stood nobody on the ground to fight")
	# Seen coming (D216): stood well down the road, not in front of the party.
	var apart: Vector2i = (ground.get("_roadside_middle") as Vector2i) - (ground.map as AreaMap).cell_at(ground._leader.position)
	_expect(apart.length() >= 5.0, "the roadside scene was stood %.1f cells off, right in front of the party" % apart.length())
	# Counted now: the fight clears the scene away, and with it this list.
	var staged_count := staged.size()
	var asked := _requests.size()
	# Stepped into with the mouse, as on a computer ([D391]).
	var mode_was := Pace.touch_mode
	Pace.touch_mode = "off"
	Pad.set_using_pad(false)
	ground.call("_do_act", { "act": "_step_into_the_road" })
	var waited := 0.0
	while waited < 3.0 and ground.get("_fight") == null:
		await get_tree().create_timer(0.05).timeout
		waited += 0.05
	var fight: Node2D = ground.get("_fight")
	_expect(fight != null and bool(fight.get("in_place")), "stepping into the roadside fight did not fight it on the ground")
	_expect(not _requests.slice(asked).has("skirmish") and _current_scene() == ground,
		"the roadside fight changed the screen")
	if fight == null:
		Pace.touch_mode = mode_was
		return
	var foes := (fight.get("ground_field") as Dictionary).get("foes", []) as Array
	_expect(foes.size() == staged_count, "the roadside fight did not put the attackers where they stood")
	await _check_the_fight_by_mouse(fight)
	Pace.touch_mode = mode_was
	fight.call("emit_signal", "gone")
	await _settle()
	await _clear_dialogue()
	_expect(_current_scene() == ground and ground.get("_fight") == null, "after the roadside fight play did not carry on on the ground")
	print("roadside: stepped in and fought on the ground where it was staged")


## The PC pass, the fight ([D391]): on a computer a fight on the ground has its keys as buttons, each
## hover naming its key, and the walk's mouse bar steps aside for it.
func _check_the_fight_by_mouse(fight: Node2D) -> void:
	var hud: Node = fight.get("hud")
	var bar: Node = _game.get_node("MouseBar")
	await _settle()
	_expect(not bar.is_showing(), "the walk's mouse bar stayed up over a fight on the ground")
	var pause: Button = hud.mouse_button("pause")
	_expect(pause != null and pause.is_visible_in_tree(), "a fight by mouse has no Pause button")
	if pause == null:
		return
	_expect(pause.tooltip_text.ends_with("(%s)" % Pad.key_text("command_wait")), "the fight's Pause does not name its key")
	_expect(hud.mouse_button("all").tooltip_text.ends_with("(Tab)"), "the fight's All does not name Tab")
	var was: bool = fight.get("paused")
	pause.pressed.emit()
	_expect(bool(fight.get("paused")) != was, "the fight's Pause button did not pause")
	pause.pressed.emit()
	print("fight by mouse: Pause, All and the rest are buttons, each naming its key")


## The PC pass ([D390]): with the touch controls off and no pad, the walk has a mouse bar whose
## buttons do what their keys do and whose hovers name the keys; it steps aside for a screen and
## for the touch bar.
func _check_the_mouse_bar() -> void:
	var bar: Node = _game.get_node("MouseBar")
	var mode_was := Pace.touch_mode
	Pad.set_using_pad(false)
	Pace.touch_mode = "off"
	await _enter("world")
	await _clear_dialogue()
	await _settle()
	_expect(bar.is_showing(), "the mouse bar was not up on the walk with the touch controls off")
	_expect(bar.button("party") != null and bar.button("party").tooltip_text.ends_with("(P)"),
			"the mouse bar's Party does not name P")
	_expect(bar.button("journal") != null and bar.button("journal").tooltip_text.ends_with("(N)"),
			"the mouse bar's Journal does not name N")
	bar.press("journal")
	await _settle()
	_expect(_journal.is_showing(), "the mouse bar's Journal did not open the journal")
	_expect(not bar.is_showing() or not _journal.is_open(), "the mouse bar stayed over the journal")
	_journal.close()
	await _settle()
	bar.press("party")
	await _settle()
	await _settle()
	_expect(_party.is_open(), "the mouse bar's Party did not open the party screen")
	_expect(not bar.is_showing(), "the mouse bar stayed over the party screen")
	_party.close()
	await _settle()
	_expect(bar.is_showing(), "the mouse bar did not come back when the party screen shut")
	Pace.touch_mode = "on"
	await _settle()
	_expect(not bar.is_showing(), "the mouse bar was up beside the touch bar")
	Pace.touch_mode = mode_was
	# No key is a key alone ([D391]): every action the menu lets you rebind is a button on the bar
	# or has a mouse route written down.
	for entry: Dictionary in (load("res://src/ui/system_menu.gd") as GDScript).get_script_constant_map()["MAPPABLE_ACTIONS"]:
		_expect(bar.route(str(entry["action"])) != "",
				"%s (%s) can only be done with a key" % [entry["label"], entry["action"]])


## D246 (play-test 6): at 5x the camera's smoothing overshot, swung back further every frame
## ("Jumping the screen left and right") and flew off for good (a black screen). Followed back and
## forth at 5x, it stays on what it follows.
func _check_the_camera_at_speed() -> void:
	var rig: Camera2D = load("res://src/ui/camera_rig.gd").new()
	rig.set("claims_the_view", false)
	add_child(rig)
	var kept := Engine.time_scale
	Engine.time_scale = 5.0
	var worst := 0.0
	for i in 240:
		var spot := Vector2(400.0 * (1 if (i / 20) % 2 == 0 else -1), 0.0)
		rig.call("focus_on", spot)
		await get_tree().process_frame
		var at := rig.get_screen_center_position()
		worst = maxf(worst, at.length() if at.is_finite() else INF)
	# Its smoothing runs at the 1x rate whatever the pace (frames here come too fast for the overshoot
	# itself to show; the virtual-screen run in D246 is where it flew off before the fix).
	var follow := float(rig.get("follow_speed"))
	var at_pace := rig.position_smoothing_speed * Engine.time_scale
	Engine.time_scale = kept
	rig.queue_free()
	_expect(follow <= 0.0 or absf(at_pace - follow) < 0.01,
			"at 5x the camera smooths at %.1f a second, not its own %.1f: it overshoots and flies off" % [at_pace, follow])
	_expect(worst < 5000.0, "at 5x the camera swung %.0f pixels off what it follows" % worst)
	print("camera: at 5x it smooths at its own pace and kept within %.0f pixels" % worst)


func _pad_button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	return event
