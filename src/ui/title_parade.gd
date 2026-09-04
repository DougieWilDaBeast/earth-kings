class_name TitleParade
extends Control
## The party running along the foot of the title screen.
##
## Whoever is walking with you in the save runs past, over and over, so the
## menu is not the only thing moving. It reads the save file directly rather
## than loading it — pressing Continue is what starts a run, not looking at it.

## Frames a second for units that have a run cycle. Anything without one keeps
## its standing pose and slides, which reads as distance rather than as a bug.
const FPS := 12.0
const SPEED := 96.0
const SCALE := 2.0
const SPRITE := 64
## How far past the edge they carry on before coming round again.
const MARGIN := 140.0
## They run behind the menu, so they are kept faint.
const TINT := Color(1.0, 1.0, 1.0, 0.75)
const FOE_TINT := Color(0.9, 0.45, 0.45, 0.75)

const FOE_POOL := ["goblin", "wolf", "slime", "brigand", "ogre"]

var _runners: Array[Dictionary] = []
var _foes: Array[Dictionary] = []
var _spread := false
var _foe_timer: float = 3.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	for template_id: String in _the_band():
		_add_runner(template_id)
	set_process(not _runners.is_empty())


func _process(delta: float) -> void:
	if not _spread:
		if size.x <= 0.0:
			return
		_spread_out()
	var wrap_at := size.x + MARGIN
	var span := wrap_at + MARGIN

	_update_foes(delta)

	for runner: Dictionary in _runners:
		runner["x"] = float(runner["x"]) + SPEED * delta
		if float(runner["x"]) > wrap_at:
			runner["x"] = float(runner["x"]) - span
		runner["time"] = float(runner["time"]) + delta

		var sprite: Sprite2D = runner["sprite"]
		sprite.position = Vector2(float(runner["x"]), size.y)
		var frames: Array = runner["frames"]
		if frames.size() > 1:
			sprite.texture = frames[int(float(runner["time"]) * FPS) % frames.size()]

		# Check collision between party runner and opposing foes
		_check_clash(runner)


func _update_foes(delta: float) -> void:
	_foe_timer -= delta
	if _foe_timer <= 0.0:
		_foe_timer = randf_range(4.0, 7.0)
		_spawn_foe()

	for i in range(_foes.size() - 1, -1, -1):
		var foe: Dictionary = _foes[i]
		var sprite: Sprite2D = foe["sprite"]
		if foe.get("falling", false):
			foe["fall_time"] = float(foe["fall_time"]) + delta
			sprite.position.x += 140.0 * delta
			sprite.position.y += 180.0 * delta
			sprite.modulate.a = maxf(0.0, 1.0 - float(foe["fall_time"]) / 0.6)
			if float(foe["fall_time"]) >= 0.6:
				sprite.queue_free()
				_foes.remove_at(i)
		else:
			foe["x"] = float(foe["x"]) - (SPEED * 0.7) * delta
			sprite.position = Vector2(float(foe["x"]), size.y)
			if float(foe["x"]) < -MARGIN:
				sprite.queue_free()
				_foes.remove_at(i)


func _spawn_foe() -> void:
	var template_id: String = FOE_POOL[randi() % FOE_POOL.size()]
	var sprite_dir: String = Database.unit_template(template_id).get("sprite_dir", "")
	var west_tex: Texture2D = null
	if sprite_dir != "":
		var west_path := "%s/west.png" % sprite_dir
		if ResourceLoader.exists(west_path):
			west_tex = load(west_path)
	if west_tex == null:
		return

	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture = west_tex
	sprite.scale = Vector2(SCALE, SCALE)
	sprite.offset = Vector2(-SPRITE / 2.0, -SPRITE)
	sprite.modulate = FOE_TINT
	add_child(sprite)

	var spawn_x := size.x + MARGIN
	sprite.position = Vector2(spawn_x, size.y)
	_foes.append({
		"sprite": sprite,
		"x": spawn_x,
		"falling": false,
		"fall_time": 0.0,
	})


func _check_clash(runner: Dictionary) -> void:
	var rx: float = runner["x"]
	for foe in _foes:
		if foe.get("falling", false):
			continue
		var fx: float = foe["x"]
		if absf(rx - fx) < 42.0:
			_strike(runner, foe)
			break


func _strike(runner: Dictionary, foe: Dictionary) -> void:
	foe["falling"] = true
	foe["fall_time"] = 0.0
	var sprite: Sprite2D = runner["sprite"]
	var orig_mod := sprite.modulate
	sprite.modulate = Color(1.5, 1.4, 0.8, 1.0)
	var t := create_tween()
	t.tween_property(sprite, "modulate", orig_mod, 0.2)


## Strung out along the whole width, so the screen is never briefly empty.
func _spread_out() -> void:
	_spread = true
	var span := size.x + MARGIN * 2.0
	for i in _runners.size():
		_runners[i]["x"] = -MARGIN + span * (float(i) + 0.5) / float(_runners.size())


## Who to draw: the party in the save, or the founders if there is no save yet.
func _the_band() -> Array[String]:
	var templates: Array[String] = []
	for character in _saved_party():
		templates.append(character)
	if templates.is_empty():
		templates.assign(Roster.FOUNDING)
	return templates


## Read the roster out of the save without disturbing the running [GameState].
func _saved_party() -> Array:
	if not GameState.has_save():
		return []
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(GameState.SAVE_PATH)
	)
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var roster: Dictionary = parsed.get("roster", {})
	var party: Array = roster.get("party", [])
	var templates: Array = []
	for entry: Dictionary in roster.get("characters", []):
		if party.has(entry.get("id", "")) and not bool(entry.get("dead", false)):
			templates.append(String(entry.get("template_id", "")))
	return templates


func _add_runner(template_id: String) -> void:
	var frames := _run_frames(template_id)
	if frames.is_empty():
		return
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture = frames[0]
	sprite.scale = Vector2(SCALE, SCALE)
	# Drawn from its own feet, so the whole band stands on the same line.
	sprite.offset = Vector2(-SPRITE / 2.0, -SPRITE)
	sprite.modulate = TINT
	add_child(sprite)
	_runners.append({ "sprite": sprite, "frames": frames, "x": 0.0, "time": randf() })


## The eastward run cycle if this unit has one, else its eastward standing pose.
static func _run_frames(template_id: String) -> Array:
	var frames := Database.unit_run(template_id, "east")
	if not frames.is_empty():
		return frames
	var sprite_dir: String = Database.unit_template(template_id).get("sprite_dir", "")
	if sprite_dir == "":
		return []
	var standing := "%s/east.png" % sprite_dir
	return [load(standing)] if ResourceLoader.exists(standing) else []
