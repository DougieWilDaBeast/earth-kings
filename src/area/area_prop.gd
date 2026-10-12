class_name AreaProp
extends AreaThing
## Something standing in an [AreaMap] that is neither a person nor a house: a
## chest, a bed, a lamp post, a pile of somebody's coin.
##
## One picture, no rotations. The node sits on the ground at the prop's base so
## the y-sorted area can put the party in front of it or behind it. A prop with
## something to say about itself can be walked up to and looked at, the same way
## a person is spoken to.

const ART_ROOT := "res://art/props"
## How far below the middle of its cell a prop's lowest pixel stands: where a person's feet are.
const GROUND := 12.0
## How much it lights up under the mouse.
const HOVER_LIFT := 0.35
## How long each frame of a prop's own animation shows: a portal's glow, a lighthouse's beam.
const FRAME_SECONDS := 0.13

var art: String = ""
## What the party makes of it, or "" for scenery nobody stops at.
var line: String = ""
## What is left to say once whatever was in it has been taken.
var spent_line: String = ""
## Coin or gear tucked into it, handed over the first time it is looked at.
var haul: Dictionary = {}
## Furniture you have to walk around rather than through.
var solid: bool = false
## Where it stands, so the area can remember it has already been emptied.
var cell: Vector2i = Vector2i.ZERO
## A flag looking at it sets, and what is said when it does: the thing somebody asked you to find.
var find_flag: String = ""
var found_line: String = ""
## A size set by the area for this one prop, or 0 for its kind's ([Database.prop_size]).
var scale_override: float = 0.0

var _sprite: Sprite2D
var _hovered: bool = false
## The drawn picture's painted part, in the node's own space, for picking it out with the mouse.
var _shape: Rect2 = Rect2(-SIZE / 2.0, -SIZE * 0.82, SIZE, SIZE)
## art id -> the part of its picture that is painted, so the empty margin is not stood on.
static var _painted: Dictionary = {}
## The prop's animation, when its art has one (<art>/frame_000.png ...), and where it is in it.
var _frames: Array[Texture2D] = []
var _frame: int = 0
var _frame_left: float = 0.0


static func create(art_id: String) -> AreaProp:
	var node := AreaProp.new()
	node._sprite = Sprite2D.new()
	node._sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node._sprite.centered = false
	node.add_child(node._sprite)
	node.set_art(art_id)
	return node


## A prop as an area's JSON describes it: a picture, and whatever it is worth
## stopping for.
static func from_entry(entry: Dictionary) -> AreaProp:
	var node := AreaProp.new()
	node._sprite = Sprite2D.new()
	node._sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node._sprite.centered = false
	node.add_child(node._sprite)
	node.scale_override = float(entry.get("scale", 0.0))
	if bool(entry.get("flip", false)):
		node._sprite.flip_h = true
	node.set_art(entry.get("art", ""))
	node.cell = entry.get("cell", Vector2i.ZERO)
	node.display_name = entry.get("name", "it")
	node.line = entry.get("line", "")
	node.spent_line = entry.get("spent_line", "")
	node.solid = AreaProp.is_solid(entry)
	node.find_flag = str(entry.get("set_flag", ""))
	node.found_line = str(entry.get("found_line", ""))
	if entry.has("gold") or entry.has("item"):
		node.haul = { "gold": int(entry.get("gold", 0)), "item": entry.get("item", "") }
	node.set_interactive(node.line != "")
	return node


## Whether a prop entry stands in the way: its own `solid`, else its kind's ([Database.prop_size]).
static func is_solid(entry: Dictionary) -> bool:
	if entry.has("solid"):
		return bool(entry["solid"])
	return bool(Database.prop_size(str(entry.get("art", ""))).get("solid", false))


static func has_art(art_id: String) -> bool:
	return art_id != "" and ResourceLoader.exists("%s/%s.png" % [ART_ROOT, art_id])


## Swap the picture in place, so a chest can be shown standing open.
func set_art(art_id: String) -> void:
	art = art_id
	var resolved_id := art_id
	if (art_id == "nature/clover" or art_id == "nature/clover_2" or art_id == "nature/seasonal_clover") and GameState.world != null:
		var s := Season.current(GameState.world)
		var seasonal_art := "nature/clover_%s" % s.get("clover", "green")
		if has_art(seasonal_art):
			resolved_id = seasonal_art
	if not has_art(resolved_id):
		push_warning("AreaProp: no art for '%s'" % resolved_id)
		return
	var texture: Texture2D = load("%s/%s.png" % [ART_ROOT, resolved_id])
	_sprite.texture = texture
	_frames = frames_of(resolved_id)
	# Each starts somewhere of its own, so two portals in one place do not pulse in step.
	_frame = randi() % maxi(1, _frames.size())
	_frame_left = FRAME_SECONDS
	set_process(not _frames.is_empty())
	var size := scale_override if scale_override > 0.0 else float(Database.prop_size(art_id)["scale"])
	var painted := painted_rect(resolved_id, texture)
	_sprite.scale = Vector2(size, size)
	# Stood on the bottom of what is painted, centred on it, so a tree three people tall
	# still has its roots where a person's feet would be.
	var middle := painted.get_center().x
	if _sprite.flip_h:
		middle = texture.get_width() - middle
	_sprite.position = Vector2(-middle * size, GROUND - painted.end.y * size)
	_shape = Rect2(Vector2(-painted.size.x * size / 2.0, GROUND - painted.size.y * size), painted.size * size)
	if _shape.size.x < SIZE * 0.6 or _shape.size.y < SIZE * 0.6:
		_shape = _shape.grow_individual(
			maxf(0.0, (SIZE * 0.6 - _shape.size.x) / 2.0), maxf(0.0, SIZE * 0.6 - _shape.size.y),
			maxf(0.0, (SIZE * 0.6 - _shape.size.x) / 2.0), 0.0)


## A prop's animation frames, in order, or none for a still picture.
static func frames_of(art_id: String) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	while true:
		var path := "%s/%s/frame_%03d.png" % [ART_ROOT, art_id, out.size()]
		if not ResourceLoader.exists(path):
			break
		out.append(load(path))
	return out


func _process(delta: float) -> void:
	# Godot turns this on for every prop; a still picture turns it straight back off.
	if _frames.is_empty():
		set_process(false)
		return
	_frame_left -= delta
	if _frame_left > 0.0:
		return
	_frame_left += FRAME_SECONDS
	_frame = (_frame + 1) % _frames.size()
	_sprite.texture = _frames[_frame]


## The part of a picture that is not empty margin.
static func painted_rect(art_id: String, texture: Texture2D) -> Rect2:
	if not _painted.has(art_id):
		var image := texture.get_image()
		var used := image.get_used_rect() if image != null else Rect2i()
		if used.size == Vector2i.ZERO:
			used = Rect2i(Vector2i.ZERO, Vector2i(texture.get_size()))
		_painted[art_id] = Rect2(used)
	return _painted[art_id]


## Float a mark over it, so a cabinet worth searching reads differently from a
## cabinet that is only furniture.
func _mark_glyph() -> String:
	return "?"


func _mark_height() -> float:
	return maxf(SIZE * 0.95, -_shape.position.y + 8.0)


func prompt() -> String:
	return "look at %s" % display_name


## The patch of the world the mouse has to be over to have picked it out.
func contains_point(point: Vector2) -> bool:
	return _shape.has_point(to_local(point))


## Light it up while the mouse is over it, so it is plain it can be clicked.
func set_hovered(on: bool) -> void:
	if on == _hovered:
		return
	_hovered = on
	_sprite.modulate = Color.WHITE.lightened(HOVER_LIFT) if on else Color.WHITE
