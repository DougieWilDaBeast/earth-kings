extends Control
## The coliseum: pick somebody, pick a card, and go out until you cannot.
##
## Two faces. Before a night starts it is a choosing screen; once [Arena] is
## open it is a between-rounds landing, showing what the last wave cost and what
## the next one pays. Everything here is separate from the run — see [Arena].

const HEADING := Color(0.965, 0.827, 0.443)
const LABEL := Color(0.66, 0.64, 0.59)
const VALUE := Color(0.90, 0.87, 0.79)
const HURT := Color(0.84, 0.55, 0.5)
const FACE := Vector2(72, 72)

## Set by [Game] before the scene enters the tree; unused here.
var boot_payload: Dictionary = {}

@onready var _headline: Label = %HeadlineLabel
@onready var _blurb: Label = %BlurbLabel
@onready var _left: VBoxContainer = %LeftColumn
@onready var _body: VBoxContainer = %Body
@onready var _actions: HBoxContainer = %Actions
@onready var _back: Button = %BackButton

var _rng := RandomNumberGenerator.new()
var _hero: String = ""
var _card: String = ""
var _wager_mult: float = 1.0


func _ready() -> void:
	_rng.randomize()
	_back.theme_type_variation = &"GrandButton"
	_back.pressed.connect(_leave)
	Sfx.attend(_back)

	if not Arena.is_open():
		_show_the_choosing()
		return
	_settle_the_round()


func _leave() -> void:
	Arena.close()
	EventBus.request_scene.emit("title", {})


# --- choosing a night ---------------------------------------------------------


func _show_the_choosing() -> void:
	_headline.text = "The Coliseum"
	_blurb.text = "Nothing you win out here follows you home. Neither does anything you lose."

	var heroes: Array = Database.heroes.keys()
	var cards: Array = Arena.cards().keys()
	if heroes.is_empty() or cards.is_empty():
		_body.add_child(_line("Nobody is fighting today.", LABEL))
		return
	_hero = heroes[0]
	_card = cards[0]

	_left.add_child(_heading("Who goes out"))
	for hero_id: String in heroes:
		_left.add_child(_picker(
			str(Database.unit_template(hero_id).get("display_name", hero_id)),
			func() -> void:
				_hero = hero_id
				_refresh_choosing()
		))
	_left.add_child(_heading("What they face"))
	for card_id: String in cards:
		_left.add_child(_picker(
			str(Arena.cards()[card_id].get("title", card_id)),
			func() -> void:
				_card = card_id
				_refresh_choosing()
		))

	_left.add_child(_heading("The Stakes"))
	var wagers := [
		["Standard Bout", 1.0],
		["Blood Wager (+50% Purse)", 1.5],
		["High Stakes (+100% Purse)", 2.0]
	]
	for w in wagers:
		_left.add_child(_picker(
			str(w[0]),
			func() -> void:
				_wager_mult = float(w[1])
				_refresh_choosing()
		))

	var begin := Button.new()
	begin.theme_type_variation = &"GrandButton"
	begin.text = "Go out"
	begin.pressed.connect(_begin)
	Sfx.attend(begin)
	_actions.add_child(begin)
	_refresh_choosing()


func _refresh_choosing() -> void:
	for child in _body.get_children():
		child.queue_free()
	var card: Dictionary = Arena.cards().get(_card, {})

	_body.add_child(_portrait_row([_hero]))
	_body.add_child(_heading(str(card.get("title", ""))))
	var blurb := _line(str(card.get("blurb", "")), VALUE)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(blurb)

	var names: Array[String] = []
	for foe_id: String in card.get("foes", []):
		names.append(str(Database.unit_template(foe_id).get("display_name", foe_id)))
	_body.add_child(_line("Out of the pens: %s" % ", ".join(names), LABEL))

	var wager_text := "Wager multiplier: %.1fx" % _wager_mult
	_body.add_child(_line(wager_text, VALUE))

	var best := Arena.best(_card)
	if best.is_empty():
		_body.add_child(_line("Nobody has lasted a round on this card yet.", LABEL))
	else:
		_body.add_child(_line(
			"Best so far: %d round%s, %d gold." % [
				int(best.get("rounds", 0)), "" if int(best.get("rounds", 0)) == 1 else "s",
				int(best.get("purse", 0)),
			], HEADING
		))


func _begin() -> void:
	Arena.open(_hero, _card, _wager_mult)
	EventBus.request_scene.emit("battle", Arena.wave(_rng))


# --- between rounds -----------------------------------------------------------


func _settle_the_round() -> void:
	var won := GameState.has_flag(Arena.VICTORY_FLAG)
	GameState.set_flag(Arena.VICTORY_FLAG, false)
	var card: Dictionary = Arena.cards().get(str(Arena.state().get("card", "")), {})
	_headline.text = str(card.get("title", "The Sand"))

	if not won:
		_show_the_loss()
		return

	var paid := Arena.won()
	_blurb.text = "The round is yours. %d gold, and the gate opens again." % paid
	_show_the_company()
	_body.add_child(_line(
		"Round %d pays %d." % [Arena.round_number(), Arena.reward(Arena.round_number())], HEADING
	))
	_body.add_child(_line("Purse so far: %d gold." % Arena.purse(), VALUE))

	var again := Button.new()
	again.theme_type_variation = &"GrandButton"
	again.text = "Round %d" % Arena.round_number()
	again.pressed.connect(func() -> void: EventBus.request_scene.emit("battle", Arena.wave(_rng)))
	Sfx.attend(again)
	_actions.add_child(again)

	var stop := Button.new()
	stop.theme_type_variation = &"GrandButton"
	stop.text = "Take the purse and stop"
	stop.pressed.connect(func() -> void:
		Arena.retire()
		Arena.close()
		EventBus.request_scene.emit("coliseum", {})
	)
	Sfx.attend(stop)
	_actions.add_child(stop)
	again.grab_focus()


func _show_the_loss() -> void:
	var lasted := Arena.round_number() - 1
	Arena.lost()
	_blurb.text = "They carry you off. %d round%s, %d gold, and the crowd already looking past you." % [
		lasted, "" if lasted == 1 else "s", Arena.purse()
	]
	_show_the_company()
	Arena.close()

	var again := Button.new()
	again.theme_type_variation = &"GrandButton"
	again.text = "Again"
	again.pressed.connect(func() -> void: EventBus.request_scene.emit("coliseum", {}))
	Sfx.attend(again)
	_actions.add_child(again)
	again.grab_focus()


func _show_the_company() -> void:
	var templates: Array[String] = []
	for character in GameState.roster.party_members():
		templates.append(character.template_id)
	_body.add_child(_portrait_row(templates))
	for character in GameState.roster.party_members():
		var whole := character.current_hp() >= character.max_hp()
		_body.add_child(_line(
			"%s — %d of %d" % [character.display_name, character.current_hp(), character.max_hp()],
			VALUE if whole else HURT
		))


# --- pieces -------------------------------------------------------------------


func _portrait_row(template_ids: Array) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	for template_id: String in template_ids:
		var face := TextureRect.new()
		face.custom_minimum_size = FACE
		face.texture = Database.unit_face(template_id)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(face)
	return row


func _picker(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(on_pressed)
	button.mouse_entered.connect(button.grab_focus)
	button.focus_entered.connect(on_pressed)
	Sfx.attend(button)
	return button


func _heading(text: String) -> Label:
	var label := _line(text, HEADING)
	label.add_theme_font_size_override("font_size", 19)
	return label


func _line(text: String, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", colour)
	return label
