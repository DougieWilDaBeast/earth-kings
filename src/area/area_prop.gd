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
## Share of the picture that stands above the ground line.
const FOOT := 0.82
## How much it lights up under the mouse.
const HOVER_LIFT := 0.35

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

var _sprite: Sprite2D
var _hovered: bool = false


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
	var node := create(entry.get("art", ""))
	node.cell = entry.get("cell", Vector2i.ZERO)
	node.display_name = entry.get("name", "it")
	node.line = entry.get("line", "")
	node.spent_line = entry.get("spent_line", "")
	node.solid = bool(entry.get("solid", false))
	if entry.has("gold") or entry.has("item"):
		node.haul = { "gold": int(entry.get("gold", 0)), "item": entry.get("item", "") }
	node.set_interactive(node.line != "")
	return node


static func has_art(art_id: String) -> bool:
	return art_id != "" and ResourceLoader.exists("%s/%s.png" % [ART_ROOT, art_id])


## Swap the picture in place, so a chest can be shown standing open.
func set_art(art_id: String) -> void:
	art = art_id
	if not has_art(art_id):
		push_warning("AreaProp: no art for '%s'" % art_id)
		return
	var texture: Texture2D = load("%s/%s.png" % [ART_ROOT, art_id])
	_sprite.texture = texture
	_sprite.position = Vector2(-texture.get_width() / 2.0, -texture.get_height() * FOOT)


## Float a mark over it, so a cabinet worth searching reads differently from a
## cabinet that is only furniture.
func _mark_glyph() -> String:
	return "?"


func _mark_height() -> float:
	return SIZE * 0.95


func prompt() -> String:
	return "look at %s" % display_name


## The patch of the world the mouse has to be over to have picked it out.
func contains_point(point: Vector2) -> bool:
	var local := to_local(point)
	return Rect2(-SIZE / 2.0, -SIZE * FOOT, SIZE, SIZE).has_point(local)


## Light it up while the mouse is over it, so it is plain it can be clicked.
func set_hovered(on: bool) -> void:
	if on == _hovered:
		return
	_hovered = on
	_sprite.modulate = Color.WHITE.lightened(HOVER_LIFT) if on else Color.WHITE
