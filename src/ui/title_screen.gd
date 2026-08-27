extends Control
## Boot menu: start a fresh run or continue from the save in `user://`.

## Set by [Game] before the scene enters the tree; unused here.
var boot_payload: Dictionary = {}

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_continue_button.disabled = not GameState.has_save()
	_continue_button.pressed.connect(_on_continue_pressed)
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_quit_button.pressed.connect(func() -> void: get_tree().quit())
	if _continue_button.disabled:
		_new_game_button.grab_focus()
	else:
		_continue_button.grab_focus()


func _on_continue_pressed() -> void:
	if GameState.load_save():
		EventBus.request_scene.emit("world", {})


func _on_new_game_pressed() -> void:
	GameState.new_game()
	EventBus.request_scene.emit("world", {})
