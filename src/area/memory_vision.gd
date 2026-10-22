class_name MemoryVision
extends CanvasLayer
## A chapter's memory seen, not only read ([D361]; `doug-md`'s play-test 7, item 11: "the chapter
## visions shown as pictures"). Picking up a memory plays its lines in the dialogue box as before;
## behind them, from the line after the floor goes out from under the world, the ground gives way
## to the vision: a pale wash of white stone with the memory's own picture on it (A65,
## `art/visions/<memory id>.png`) slowly drawing closer, or until that is drawn, the keepsake held
## up large. On the line that ends it ("White.") the wash goes white and the picture with it, and
## the floor comes back for the lines after. The rules are `world_rules.json` → `vision`.
##
## It hears the box only through [signal EventBus.dialogue_line_shown] and
## [signal EventBus.dialogue_finished], and goes when the memory ends.

const Memories := preload("res://src/chronicle/memories.gd")
const ART_ROOT := "res://art/visions"

## Where the vision stands: "floor" before it opens, "seen" while it is up, "white" on its last
## line, "gone" after.
var stage: String = "floor"

var _scene_id: String = ""
var _opens_after: int = 1
var _ends_at: int = -1
var _rules: Dictionary = {}
var _wash: ColorRect
var _picture: TextureRect
var _fade: Tween
var _closer: Tween


## Put up over [param parent] for the memory about to play as [param scene_id], for [param lead_id].
static func open(parent: Node, memory: Dictionary, lead_id: String, scene_id: String) -> MemoryVision:
	var vision := MemoryVision.new()
	vision._set_up(memory, lead_id, scene_id)
	parent.add_child(vision)
	return vision


## The picture a memory is seen as: its own vision once drawn (A65), the keepsake until then.
static func picture_of(memory: Dictionary, lead_id: String) -> String:
	var own := "%s/%s.png" % [ART_ROOT, str(memory.get("id", ""))]
	if ResourceLoader.exists(own):
		return own
	return "%s/%s.png" % [AreaProp.ART_ROOT, Memories.art_of(memory, lead_id)]


## The line the vision ends on, by its words (`ends_on`), or -1 to last till the memory does.
static func ends_at(memory: Dictionary, rules: Dictionary) -> int:
	var scene: Array = memory.get("scene", [])
	for i in scene.size():
		if str((scene[i] as Dictionary).get("text", "")).strip_edges() == str(rules.get("ends_on", "")):
			return i
	return -1


func _set_up(memory: Dictionary, lead_id: String, scene_id: String) -> void:
	_rules = Database.world_rules.get("vision", {})
	layer = int(_rules.get("layer", 9))
	_scene_id = scene_id
	_opens_after = int(_rules.get("opens_after", 1))
	_ends_at = ends_at(memory, _rules)
	_wash = ColorRect.new()
	_wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wash.color = _colour("wash", Color(0.92, 0.89, 0.82))
	_wash.modulate.a = 0.0
	add_child(_wash)
	_picture = TextureRect.new()
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var path := picture_of(memory, lead_id)
	if ResourceLoader.exists(path):
		_picture.texture = load(path)
	_wash.add_child(_picture)
	# The keepsake is small and held up in the middle; a vision of its own fills the screen.
	var own := path.begins_with(ART_ROOT)
	var share := 1.0 if own else float(_rules.get("keepsake_height", 0.4))
	_picture.anchor_left = 0.5 - share / 2.0
	_picture.anchor_right = 0.5 + share / 2.0
	_picture.anchor_top = 0.5 - share / 2.0
	_picture.anchor_bottom = 0.5 + share / 2.0
	if own:
		_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	EventBus.dialogue_line_shown.connect(_on_line)
	EventBus.dialogue_finished.connect(_on_finished)


func _colour(key: String, otherwise: Color) -> Color:
	var parts: Array = _rules.get(key, [])
	return Color(float(parts[0]), float(parts[1]), float(parts[2])) if parts.size() >= 3 else otherwise


func _on_line(dialogue_id: String, node_id: String) -> void:
	if dialogue_id != _scene_id or not node_id.begins_with("line_"):
		return
	var at := int(node_id.trim_prefix("line_"))
	if at <= _opens_after:
		return
	if _ends_at >= 0 and at > _ends_at:
		_close()
	elif at == _ends_at:
		_go_white()
	elif stage == "floor":
		_see()


## The ground gives way to the vision, and the picture starts drawing closer.
func _see() -> void:
	stage = "seen"
	var seconds := _seconds()
	_fade_to(_wash, "modulate:a", 1.0, seconds)
	_picture.pivot_offset = _picture.size / 2.0
	if seconds > 0.0:
		_closer = create_tween()
		_closer.tween_property(_picture, "scale", Vector2.ONE * float(_rules.get("closer", 1.1)),
				float(_rules.get("closer_seconds", 20.0)))


## "White.": the wash goes white and takes the picture with it.
func _go_white() -> void:
	if stage == "floor":
		_wash.modulate.a = 1.0
	stage = "white"
	_fade_to(_wash, "color", Color.WHITE, _seconds())
	_fade_to(_picture, "modulate:a", 0.0, _seconds())


## Back on the floor.
func _close() -> void:
	if stage == "gone":
		return
	stage = "gone"
	_fade_to(_wash, "modulate:a", 0.0, _seconds())


func _on_finished(dialogue_id: String) -> void:
	if dialogue_id != _scene_id:
		return
	stage = "gone"
	queue_free()


func _seconds() -> float:
	return 0.0 if Pace.auto else float(_rules.get("fade_seconds", 0.6))


func _fade_to(node: CanvasItem, property: String, to: Variant, seconds: float) -> void:
	if seconds <= 0.0:
		node.set_indexed(property, to)
		return
	var fade := create_tween()
	fade.tween_property(node, property, to, seconds)
