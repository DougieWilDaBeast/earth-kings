extends CanvasLayer
## Between-battle conversations. Listens for [signal EventBus.dialogue_requested],
## plays the lines from `data/dialogue/<id>.json`, then reports back.

@onready var _panel: PanelContainer = %Panel
@onready var _speaker: Label = %SpeakerLabel
@onready var _body: Label = %BodyLabel

var _lines: Array = []
var _index: int = 0
var _current_id: String = ""


func _ready() -> void:
	_panel.hide()
	EventBus.dialogue_requested.connect(play)


func play(dialogue_id: String) -> void:
	_lines = Database.dialogue(dialogue_id)
	if _lines.is_empty():
		EventBus.dialogue_finished.emit(dialogue_id)
		return
	_current_id = dialogue_id
	_index = 0
	_panel.show()
	_render()


func _unhandled_input(event: InputEvent) -> void:
	if not _panel.visible:
		return
	var advance := event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton:
		advance = advance or (event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if advance:
		get_viewport().set_input_as_handled()
		_advance()


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		_panel.hide()
		EventBus.dialogue_finished.emit(_current_id)
		return
	_render()


func _render() -> void:
	var line: Dictionary = _lines[_index]
	_speaker.text = line.get("speaker", "")
	_body.text = line.get("text", "")
