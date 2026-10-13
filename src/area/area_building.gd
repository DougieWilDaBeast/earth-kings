class_name AreaBuilding
extends Node2D
## A house standing on an [AreaMap]: roof seen from above, a front wall with
## lit windows, a chimney, and one door. The node sits at the front wall so the
## y-sorted area can put the party in front of the house or behind it.

## Roof, wall and trim by the way a house was put up. A building names one with
## its `"style"`; anything else is a plastered cottage.
const STYLES := {
	"thatch": { "roof": "#8a6a33", "ridge": "#5e4720", "wall": "#a08a6a", "shade": "#6a5540" },
	"tile": { "roof": "#8a4136", "ridge": "#6a2f27", "wall": "#7a6650", "shade": "#4b3d2e" },
	"slate": { "roof": "#4e5560", "ridge": "#343a44", "wall": "#6f6b63", "shade": "#453f39" },
	"board": { "roof": "#5c6248", "ridge": "#3d4231", "wall": "#6d6350", "shade": "#42392d" },
}
const DOOR := Color("#2a1c13")
const LINTEL := Color("#c9a45f")
const SHADOW := Color(0, 0, 0, 0.25)
const WINDOW := Color("#f0c268")
const WINDOW_FRAME := Color("#2f2418")
const SMOKE := Color(0.82, 0.82, 0.86, 0.22)
## How far the roof hangs past the walls, and how tall the front wall reads.
const EAVES := 8.0
const FRONT_WALL := 22.0
## Window size, and how far apart windows are allowed to sit.
const WINDOW_SIZE := Vector2(20.0, 13.0)
const WINDOW_SPACING := 74.0

var _body: Rect2
var _door_x: float = 0.0
var _roof: Color = Color.WHITE
var _ridge: Color = Color.WHITE
var _wall: Color = Color.WHITE
var _shade: Color = Color.WHITE
## Whether the windows are lit and the chimney is drawing.
var _lived_in: bool = true
## The building's own picture, when it has one; otherwise the house is drawn by hand.
var _picture: Sprite2D = null


static func create(building: Dictionary) -> AreaBuilding:
	var node := AreaBuilding.new()
	var rect := AreaMap.footprint(building)
	var door: Vector2i = building["door"]
	node.position = Vector2(rect.position.x, rect.end.y) * AreaMap.CELL
	node._body = Rect2(
		0.0, -rect.size.y * AreaMap.CELL, rect.size.x * AreaMap.CELL, rect.size.y * AreaMap.CELL
	)
	node._door_x = (door.x - rect.position.x) * AreaMap.CELL
	var style: Dictionary = STYLES.get(building.get("style", "tile"), STYLES["tile"])
	node._roof = Color(style["roof"])
	node._ridge = Color(style["ridge"])
	node._wall = Color(style["wall"])
	node._shade = Color(style["shade"])
	node._lived_in = bool(building.get("lived_in", true))
	var art_id := str(building.get("art", ""))
	var look := Database.building_art(art_id)
	# Most buildings are under art/buildings; one may name another picture (a portal as a door).
	var path := str(look.get("path", "res://art/buildings/%s.png" % art_id))
	if not look.is_empty() and ResourceLoader.exists(path):
		node._add_picture(load(path), float(building.get("scale", look.get("scale", 3.0))), bool(building.get("flip", false)))
	return node


## The house as drawn: stood on its footprint's front edge and centred on it. The picture shows
## the front and the roof, so it rises past the footprint's back row, the way a house would.
func _add_picture(texture: Texture2D, size: float, flip: bool) -> void:
	var painted := AreaProp.painted_rect("buildings/" + texture.resource_path, texture)
	_picture = Sprite2D.new()
	_picture.texture = texture
	_picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_picture.centered = false
	_picture.flip_h = flip
	_picture.scale = Vector2(size, size)
	var middle := texture.get_width() - painted.get_center().x if flip else painted.get_center().x
	_picture.position = Vector2(_body.size.x / 2.0 - middle * size, 6.0 - painted.end.y * size)
	add_child(_picture)


func _draw() -> void:
	if _picture != null:
		# Only a soft shadow at its feet; the picture is the house.
		draw_rect(Rect2(Vector2(_body.position.x + 6.0, -10.0), Vector2(_body.size.x - 4.0, 16.0)), SHADOW)
		return
	draw_rect(Rect2(_body.position + Vector2(6, 8), _body.size), SHADOW)
	draw_rect(_body, _wall)
	draw_rect(Rect2(_body.position.x, -FRONT_WALL, _body.size.x, FRONT_WALL), _shade)

	var roof := Rect2(_body.position, Vector2(_body.size.x, _body.size.y - FRONT_WALL)).grow(EAVES)
	_draw_roof(roof)
	_draw_chimney(roof)
	_draw_windows()
	_draw_door()


## Courses laid from the ridge down, so a roof reads as thatch or tile rather
## than a flat block of colour.
func _draw_roof(roof: Rect2) -> void:
	draw_rect(roof, _roof)
	draw_rect(roof, _ridge, false, 2.0)
	var ridge_y := roof.get_center().y
	draw_line(Vector2(roof.position.x, ridge_y), Vector2(roof.end.x, ridge_y), _ridge, 3.0)
	var offset := 10.0
	while offset < roof.size.y / 2.0:
		for y: float in [ridge_y - offset, ridge_y + offset]:
			draw_line(Vector2(roof.position.x + 3.0, y), Vector2(roof.end.x - 3.0, y), _ridge, 1.0)
		offset += 10.0


func _draw_chimney(roof: Rect2) -> void:
	var stack := Rect2(
		roof.position + Vector2(roof.size.x * 0.18, roof.size.y * 0.22), Vector2(16, 20)
	)
	draw_rect(stack, _shade)
	draw_rect(stack, _ridge, false, 2.0)
	if not _lived_in:
		return
	var mouth := stack.get_center() - Vector2(0, stack.size.y * 0.6)
	for puff in 3:
		draw_circle(mouth - Vector2(puff * 5.0, puff * 9.0), 6.0 + puff * 3.0, SMOKE)


## Shutters along the front, lit if anybody is home, spaced so a long wall gets
## more of them than a narrow one.
func _draw_windows() -> void:
	var count := maxi(1, floori(_body.size.x / WINDOW_SPACING))
	var glass := WINDOW if _lived_in else DOOR
	for index in count:
		var centre_x := _body.size.x * (index + 0.5) / count
		if absf(centre_x - (_door_x + AreaMap.CELL * 0.5)) < AreaMap.CELL * 0.6:
			continue
		var pane := Rect2(Vector2(centre_x - WINDOW_SIZE.x / 2.0, -FRONT_WALL + 5.0), WINDOW_SIZE)
		draw_rect(pane.grow(2.0), WINDOW_FRAME)
		draw_rect(pane, glass)
		draw_line(
			Vector2(pane.get_center().x, pane.position.y),
			Vector2(pane.get_center().x, pane.end.y),
			WINDOW_FRAME,
			1.0
		)


## The way in is the brightest thing on the house.
func _draw_door() -> void:
	var doorway := Rect2(
		_door_x + AreaMap.CELL * 0.25, -FRONT_WALL - 12.0, AreaMap.CELL * 0.5, FRONT_WALL + 12.0
	)
	if _lived_in:
		draw_rect(doorway.grow(6.0), Color(WINDOW, 0.18))
	draw_rect(doorway, DOOR)
	draw_rect(Rect2(doorway.position - Vector2(0, 4), Vector2(doorway.size.x, 4)), LINTEL)
	draw_rect(
		Rect2(doorway.position.x - 4.0, doorway.end.y - 3.0, doorway.size.x + 8.0, 5.0), LINTEL
	)
