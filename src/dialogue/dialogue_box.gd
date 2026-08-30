extends CanvasLayer
## Between-battle conversations. Listens for [signal EventBus.dialogue_requested],
## walks the nodes in `data/dialogue/<id>.json` — letting the player pick replies
## and rolling the checks behind them — then reports back.

## The reply the mouse is over, picked out from the rest.
const OPTION_HOVER := Color(1.0, 0.88, 0.5)
## The reply that is never written down in a file.
const REFLECT_REPLY := "(Say nothing, and let one of your own speak.)"
## Beat between lines while the game is playing itself.
const AUTO_BEAT := 0.5
## Replies a conversation on auto may take before it is shown the door. Scripts
## are allowed to loop; a soak is not allowed to loop with them.
const AUTO_REPLY_LIMIT := 12

@onready var _panel: PanelContainer = %Panel
@onready var _portrait: TextureRect = %Portrait
@onready var _speaker: Label = %SpeakerLabel
@onready var _body: Label = %BodyLabel
@onready var _options: VBoxContainer = %Options
@onready var _hint: Label = %HintLabel

var _nodes: Dictionary = {}
var _node: Dictionary = {}
var _node_id: String = ""
var _current_id: String = ""
var _shown_options: Array = []
## Where the conversation goes once the check result on screen is dismissed.
var _pending_goto: String = ""
## Where it goes back to once the party has had its say, and whether it already has.
var _reflect_back: String = ""
var _reflected: bool = false
var _auto_wait: float = 0.0
var _auto_replies: int = 0


func _ready() -> void:
	_panel.hide()
	_panel.gui_input.connect(_on_panel_input)
	add_to_group(EventBus.MODAL_OVERLAY_GROUP)
	EventBus.dialogue_requested.connect(play)
	EventBus.conversation_requested.connect(play_lines)


func is_open() -> bool:
	return _panel.visible


func play(dialogue_id: String) -> void:
	_nodes = DialogueScript.nodes(dialogue_id)
	if _nodes.is_empty():
		EventBus.dialogue_finished.emit(dialogue_id)
		return
	_current_id = dialogue_id
	_reset()
	var opening := DialogueScript.start_id(dialogue_id)
	GameState.remember_talk(dialogue_id)
	_panel.show()
	_goto(opening)


## Play something nobody wrote down in advance, like a bit of banter on the road.
func play_lines(lines: Array) -> void:
	if lines.is_empty():
		EventBus.dialogue_finished.emit("")
		return
	_nodes = DialogueScript.nodes_from_lines(lines)
	_current_id = ""
	_reset()
	_panel.show()
	_goto(_nodes.keys()[0])


func _reset() -> void:
	_pending_goto = ""
	_reflect_back = ""
	_reflected = false
	_auto_wait = AUTO_BEAT
	_auto_replies = 0


func _unhandled_input(event: InputEvent) -> void:
	if not _panel.visible or not _shown_options.is_empty():
		return
	var advance := event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton:
		advance = advance or (event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if advance:
		get_viewport().set_input_as_handled()
		_advance()


## A click on the box itself never falls through to the scene behind it, so the
## box has to take that click as "go on" by hand.
func _on_panel_input(event: InputEvent) -> void:
	if not _shown_options.is_empty():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_panel.accept_event()
		_advance()


## While the game is playing itself, conversations answer themselves too.
func _process(delta: float) -> void:
	if not Pace.auto or not _panel.visible:
		return
	_auto_wait -= delta
	if _auto_wait > 0.0:
		return
	_auto_wait = AUTO_BEAT
	if _shown_options.is_empty():
		_advance()
		return
	_auto_replies += 1
	if _auto_replies > AUTO_REPLY_LIMIT:
		_finish()
		return
	_choose(0)


func _goto(node_id: String, effects: bool = true) -> void:
	if node_id == "" or node_id == DialogueScript.END or not _nodes.has(node_id):
		_finish()
		return
	_node_id = node_id
	_node = _nodes[node_id]
	if effects:
		DialogueScript.apply_effects(_node)
	_show(_node.get("speaker", ""), DialogueScript.text_of(_node))


func _advance() -> void:
	if _reflect_back != "":
		var back := _reflect_back
		_reflect_back = ""
		# Back to the same choices, without paying for the node a second time.
		_goto(back, false)
		return
	if _pending_goto != "":
		var target := _pending_goto
		_pending_goto = ""
		_goto(target)
		return
	_goto(_node.get("next", DialogueScript.END))


func _choose(slot: int) -> void:
	var option: Dictionary = _shown_options[slot]
	if option.get("reflect", false):
		_speak_of_the_past()
		return

	DialogueScript.apply_effects(option)
	if option.get("once", false):
		GameState.set_flag(DialogueScript.option_key(_current_id, option))
	var check: Dictionary = option.get("check", {})
	if check.is_empty():
		_goto(option.get("goto", _node.get("next", DialogueScript.END)))
		return

	var result := DialogueScript.roll(check)
	var outcome: String = "success" if result["success"] else "failure"
	DialogueScript.apply_effects(check.get(outcome + "_effects", {}))
	_pending_goto = check.get(outcome, option.get("goto", DialogueScript.END))
	_show(DialogueScript.check_title(check), DialogueScript.roll_text(result))


## One of the party looks back at the run instead of answering, then the
## conversation picks up where it stood.
func _speak_of_the_past() -> void:
	_reflected = true
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var line := Recollection.remark(GameState.world, GameState.party_characters(), rng)
	if line.is_empty():
		_goto(_node_id, false)
		return
	_reflect_back = _node_id
	_show(line["speaker"], line["text"])


func _finish() -> void:
	_node = {}
	_clear_options()
	_panel.hide()
	EventBus.dialogue_finished.emit(_current_id)


func _show(speaker: String, body: String) -> void:
	_speaker.text = speaker
	_body.text = body
	_show_portrait(speaker)
	_clear_options()
	if _pending_goto != "" or _reflect_back != "":
		_hint.text = "Click to continue"
		return

	_shown_options = DialogueScript.available_options(_node, _current_id)
	if not _shown_options.is_empty() and _party_could_reflect():
		_shown_options.append({ "text": REFLECT_REPLY, "reflect": true })
	for slot in _shown_options.size():
		_options.add_child(_option_button(slot, _shown_options[slot]))
	if _shown_options.is_empty():
		_hint.text = "Click to continue"
	else:
		_hint.text = "Click the reply you want"
		_options.get_child(0).grab_focus()


## Only once a conversation, and only when the run has given them something to
## look back on.
func _party_could_reflect() -> bool:
	if _reflected or _current_id == "":
		return false
	return Recollection.has_something_to_say(GameState.world, GameState.party_characters())


## Whoever is talking is shown as they are drawn in the world, so a line never
## comes out of a face that does not belong to it.
func _show_portrait(speaker: String) -> void:
	var face := DialogueScript.portrait(_current_id, speaker)
	_portrait.texture = face
	_portrait.visible = face != null


func _option_button(slot: int, option: Dictionary) -> Button:
	var button := Button.new()
	button.text = _option_text(option)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_color_override("font_hover_color", OPTION_HOVER)
	button.add_theme_color_override("font_focus_color", OPTION_HOVER)
	button.pressed.connect(_choose.bind(slot))
	return button


func _option_text(option: Dictionary) -> String:
	var check: Dictionary = option.get("check", {})
	if check.is_empty():
		return option.get("text", "...")
	return "[%s] %s" % [DialogueScript.check_title(check), option.get("text", "...")]


func _clear_options() -> void:
	_shown_options = []
	for child in _options.get_children():
		_options.remove_child(child)
		child.queue_free()
