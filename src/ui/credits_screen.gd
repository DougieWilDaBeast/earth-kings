extends Control
## The credits, off the title screen. A long scroll of `data/credits.json`
## ([code]credits_roll.gd[/code]); Back, Escape or a phone's back key returns
## to the title.

const CreditsRoll := preload("res://src/ui/credits_roll.gd")

## How far one press of up or down moves the scroll, in pixels.
const STEP := 48

## Set by [Game] before the scene enters the tree; unused here.
var boot_payload: Dictionary = {}

@onready var _scroll: ScrollContainer = %Scroll
@onready var _list: VBoxContainer = %CreditsList
@onready var _back: Button = %BackButton


func _ready() -> void:
	_back.theme_type_variation = &"GrandButton"
	_back.pressed.connect(leave)
	Sfx.attend(_back)
	CreditsRoll.fill(_list)
	_back.grab_focus()


## Back to the title screen.
func leave() -> void:
	EventBus.request_scene.emit("title", {})


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		leave()


# Ahead of the GUI, which would otherwise spend up and down hunting for a
# second button to focus.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		_scroll.scroll_vertical += STEP
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		get_viewport().set_input_as_handled()
		_scroll.scroll_vertical -= STEP
