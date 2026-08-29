class_name AreaThing
extends Node2D
## Something standing in an area that the party can walk up to and deal with:
## somebody to speak to, or something to look at.
##
## The node sits at the base of whatever it draws, so the y-sorted area can put
## the party in front of it or behind it.

## Size of the patch the mouse has to be over to have picked it out.
const SIZE := 64

var display_name: String = "it"

var _mark: AreaMark
var _bubble: SpeechBubble


## Say a line out loud, over their own head. It fades on its own and nothing
## waits for it, so this is what the party use while they are walking.
func say(line: String) -> void:
	if line == "":
		return
	if not is_instance_valid(_bubble):
		_bubble = SpeechBubble.create(_mark_height() + 16.0)
		add_child(_bubble)
	_bubble.say(line)


## Float a mark over it, so what is worth stopping for can be seen from across
## the square.
func set_interactive(on: bool) -> void:
	if on == (_mark != null):
		return
	if not on:
		_mark.queue_free()
		_mark = null
		return
	_mark = AreaMark.create(_mark_glyph(), SIZE, _mark_height())
	add_child(_mark)


## Brighten the mark once the leader is close enough to act on it.
func set_mark_ready(ready: bool) -> void:
	if _mark != null:
		_mark.set_ready(ready)


## Whether walking over to it would get you anything.
func can_talk() -> bool:
	return _mark != null


## What the bottom of the screen offers to do with it.
func prompt() -> String:
	return "speak with %s" % display_name


## The patch of the world the mouse has to be over to have picked it out.
func contains_point(_point: Vector2) -> bool:
	return false


## Light it up while the mouse is over it, so it is plain it can be clicked.
func set_hovered(_on: bool) -> void:
	pass


func _mark_glyph() -> String:
	return "!"


func _mark_height() -> float:
	return AreaMark.HEIGHT
