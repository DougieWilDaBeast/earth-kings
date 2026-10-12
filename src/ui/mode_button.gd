extends Button
## Classic or Iron Man, picked with the lead ([D51]). Each press moves to the
## next mode in `data/world_rules.json` → `modes`; the blurb says what it means.
## Used wherever a new game is begun: the quiz and the picker.

const RunMode := preload("res://src/chronicle/run_mode.gd")


func _ready() -> void:
	theme_type_variation = &"GrandButton"
	pressed.connect(_cycle)
	Sfx.attend(self)
	_show()


func _cycle() -> void:
	GameState.mode = RunMode.cycle(GameState.mode)
	_show()


func _show() -> void:
	text = "Mode: %s" % RunMode.display_name(RunMode.valid(GameState.mode))
	tooltip_text = RunMode.blurb(RunMode.valid(GameState.mode))
