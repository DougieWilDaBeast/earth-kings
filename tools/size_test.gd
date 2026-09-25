extends Node2D
## The sprite size test — Tier 0 of [19 — Asset list]: 64, 32 or 16?
##
##   godot --path . res://tools/size_test.tscn                          look at it
##   godot --headless --path . res://tools/size_test.tscn -- --check    what is there, what is missing
##   godot --headless --path . res://tools/size_test.tscn -- --import=C:/Downloads/x.zip --unit=goblin --size=32
##
## Three patches of battle ground side by side, one per size, each with the same
## four units on it, drawn the way the battle draws them. Whatever PixelLab has
## made is read from `art/size_test/<size>/<unit>/<state>/<facing>.png`; the 64s
## fall back to the art already in `art/units/`. A size nobody has generated yet
## is shown as a PREVIEW — the 64 shrunk by the computer, which is not what
## PixelLab would draw at that size — and says so in red, so the layout can be
## looked at today and nobody mistakes a preview for the real thing.
##
## Keys: 1 battle scale · 2 same pixel size · 3 crowd · F facing · B big units
## larger · A attack · P portrait · +/- or wheel zoom · F12 screenshot.
##
## The importer takes a PixelLab export zip as it downloads and puts every image
## where this viewer and the game look for it, whatever folders it came in.
##
## Loaded by path, not by `class_name` ([D41]).

const ROOT := "res://art/size_test"
const SIZES := [64, 32, 16]
const UNITS := ["sworn_blade", "goblin", "club_ogre", "goblin"]
## Everyone else a crowd is made of, if they exist at that size.
const CROWD := ["sworn_blade", "goblin", "club_ogre", "longbow", "hedge_priest", "wolf", "raider"]
const FACINGS := ["south", "east", "north", "west"]
const DIRECTIONS := ["north", "south", "east", "west", "north-east", "north-west", "south-east", "south-west"]

## The battle's own numbers (`battle_grid.gd`, `unit.gd`), so this is what a
## fight would show.
const CELL := 48
const SPRITE_HEIGHT_CELLS := 1.15
const PATCH := Vector2i(6, 8)
const GAP := 40.0
const ATTACK_FPS := 10.0

enum Mode { BATTLE, PIXEL, CROWD }
const MODE_NAMES := {
	Mode.BATTLE: "battle scale — every body drawn 1.15 tiles tall, as the fight does now",
	Mode.PIXEL: "same pixel size — one art pixel is the same size everywhere; what the camera would have to do",
	Mode.CROWD: "crowd — as many bodies as the ground holds",
}

var mode: Mode = Mode.BATTLE
var facing := 0
var big_units := false
var zoom := 1.0
var show_portrait := false
var _attack_time := -1.0
## "<size>/<unit>/<state>/<facing>" -> {texture, preview}
var _cache: Dictionary = {}
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	var args := _args()
	if args.has("import"):
		var lines := import_zip(str(args["import"]), str(args.get("unit", "")), int(args.get("size", 0)), str(args.get("state", "")))
		for line in lines:
			print(line)
		get_tree().quit(0 if not lines.is_empty() and not lines[-1].begins_with("NOT") else 1)
		return
	if args.has("check"):
		for line in report():
			print(line)
		get_tree().quit(0)
		return
	if args.has("shot"):
		mode = Mode.get(str(args.get("mode", "BATTLE")).to_upper(), Mode.BATTLE)
		big_units = args.has("big")
		await get_tree().process_frame
		await get_tree().process_frame
		print("shot: %s" % _shoot(str(args["shot"]) if str(args["shot"]) != "" else "size_test"))
		get_tree().quit(0)


func _args() -> Dictionary:
	var out := {}
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var pair := arg.trim_prefix("--").split("=", true, 1)
		out[pair[0]] = pair[1] if pair.size() > 1 else ""
	return out


# --- what is on disk ---------------------------------------------------------


## The picture for [param unit] at [param size], and whether it is only a preview.
func sprite(size: int, unit: String, state: String = "idle", face: String = "south") -> Dictionary:
	var key := "%d/%s/%s/%s" % [size, unit, state, face]
	if _cache.has(key):
		return _cache[key]
	var found := {}
	var generated := _image("%s/%d/%s/%s/%s.png" % [ROOT, size, unit, state, face])
	if generated != null:
		found = {"texture": ImageTexture.create_from_image(generated), "preview": false}
	elif size == 64 and state == "idle":
		var on_disk := _image("res://art/units/%s/idle/%s.png" % [unit, face])
		if on_disk != null:
			found = {"texture": ImageTexture.create_from_image(on_disk), "preview": false}
	elif state == "idle":
		var big := _image("res://art/units/%s/idle/%s.png" % [unit, face])
		if big != null:
			found = {"texture": ImageTexture.create_from_image(_shrunk(big, size)), "preview": true}
	_cache[key] = found
	return found


## Frames of a generated animation, in order, or none.
func frames(size: int, unit: String, state: String, face: String) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	var folder := "%s/%d/%s/%s/%s" % [ROOT, size, unit, state, face]
	var dir := DirAccess.open(folder)
	if dir == null:
		return out
	var names: Array = Array(dir.get_files()).filter(func(f: String) -> bool: return f.ends_with(".png"))
	names.sort()
	for name: String in names:
		var image := _image(folder.path_join(name))
		if image != null:
			out.append(ImageTexture.create_from_image(image))
	return out


## Read straight off the disk rather than through the importer, so an image
## dropped in while the editor was closed shows up without an import.
static func _image(path: String) -> Image:
	var real := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(real):
		return null
	var image := Image.load_from_file(real)
	return image if image != null and not image.is_empty() else null


## A stand-in for art nobody has made: the 64 shrunk and its edges hardened.
## Not what PixelLab would draw — only enough to see the layout.
static func _shrunk(image: Image, size: int) -> Image:
	var copy := image.duplicate() as Image
	copy.convert(Image.FORMAT_RGBA8)
	copy.resize(size, size, Image.INTERPOLATE_LANCZOS)
	for y in size:
		for x in size:
			var c := copy.get_pixel(x, y)
			c.a = 1.0 if c.a > 0.5 else 0.0
			copy.set_pixel(x, y, c)
	return copy


## One line per size and unit: made, previewed or missing, and what else is there.
func report() -> Array[String]:
	var lines: Array[String] = ["Sprite size test — %s" % ProjectSettings.globalize_path(ROOT)]
	for size: int in SIZES:
		for unit: String in ["sworn_blade", "goblin", "club_ogre"]:
			var found := sprite(size, unit)
			var state := "missing"
			if not found.is_empty():
				state = "PREVIEW only (not generated yet)" if found["preview"] else "ready"
			var extras: Array[String] = []
			for anim: String in _states(size, unit):
				if anim != "idle":
					extras.append(anim)
			lines.append("  %2d  %-12s %s%s" % [size, unit, state, "   + " + ", ".join(extras) if not extras.is_empty() else ""])
	var portrait := _portrait()
	lines.append("  portrait     %s" % ("ready" if portrait != null else "none yet (art/size_test/portrait/sworn_blade.png)"))
	return lines


func _states(size: int, unit: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open("%s/%d/%s" % [ROOT, size, unit])
	if dir != null:
		for name in dir.get_directories():
			out.append(name)
	return out


func _portrait() -> Texture2D:
	var image := _image("%s/portrait/sworn_blade.png" % ROOT)
	return ImageTexture.create_from_image(image) if image != null else null


# --- the importer -------------------------------------------------------------


## Unpack a PixelLab export into `art/size_test/<size>/<unit>/<state>/`.
## A still named for a facing (`south.png`) is the state's rotation; numbered
## frames under a facing folder are an animation. Returns what it did; the last
## line starts "NOT" if nothing could be placed.
func import_zip(zip_path: String, unit: String, size: int, state: String = "") -> Array[String]:
	var lines: Array[String] = []
	if unit == "" or not SIZES.has(size):
		return ["NOT imported: say which unit and size — --unit=goblin --size=32"]
	var zip := ZIPReader.new()
	if zip.open(zip_path) != OK:
		return ["NOT imported: could not open %s" % zip_path]
	var base := "%s/%d/%s" % [ROOT, size, unit]
	var placed := 0
	var animation_state := state if state != "" else "attack"
	var metadata := {}
	for entry: String in zip.get_files():
		var parts := entry.split("/", false)
		if parts.is_empty():
			continue
		var file := parts[-1]
		if file == "metadata.json":
			var parsed: Variant = JSON.parse_string(zip.read_file(entry).get_string_from_utf8())
			if parsed is Dictionary:
				metadata = parsed
			continue
		if not file.to_lower().ends_with(".png"):
			continue
		var stem := file.get_basename().to_lower()
		var target := ""
		if DIRECTIONS.has(stem):
			target = "%s/%s/%s.png" % [base, state if state != "" else "idle", stem]
		else:
			for i in range(parts.size() - 2, -1, -1):
				var folder := parts[i].to_lower()
				if DIRECTIONS.has(folder):
					target = "%s/%s/%s/%s" % [base, animation_state, folder, file]
					break
		if target == "":
			lines.append("  skipped %s — not a facing or a frame of one" % entry)
			continue
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target.get_base_dir()))
		var out := FileAccess.open(ProjectSettings.globalize_path(target), FileAccess.WRITE)
		if out == null:
			lines.append("  could not write %s" % target)
			continue
		out.store_buffer(zip.read_file(entry))
		out.close()
		placed += 1
		lines.append("  %s -> %s" % [entry, target.trim_prefix("res://")])
	zip.close()
	if placed == 0:
		lines.append("NOT imported: no facing images found in %s" % zip_path.get_file())
		return lines
	_record(base, unit, size, zip_path.get_file(), metadata, state)
	lines.append("Imported %d images for %s at %d from %s" % [placed, unit, size, zip_path.get_file()])
	return lines


## The folder's `metadata.json`, as every unit folder keeps one ([19]): the
## prompt it was made from, so it can be made again.
func _record(base: String, unit: String, size: int, source: String, pixellab: Dictionary, state: String) -> void:
	var path := ProjectSettings.globalize_path(base.path_join("metadata.json"))
	var record := {"id": unit, "size_test": size, "states": []}
	if FileAccess.file_exists(path):
		var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if old is Dictionary:
			record = old
	var prompt := str(pixellab.get("prompt", pixellab.get("description", "")))
	if prompt == "":
		var original: Variant = JSON.parse_string(FileAccess.get_file_as_string(
			ProjectSettings.globalize_path("res://art/units/%s/metadata.json" % unit)))
		if original is Dictionary and not (original["states"] as Array).is_empty():
			prompt = str(original["states"][0].get("prompt", ""))
	(record["states"] as Array).append({
		"state": state if state != "" else "idle",
		"prompt": prompt,
		"size": "%dx%d" % [size, size],
		"source": source,
		"date": Time.get_date_string_from_system(),
		"pixellab": pixellab,
	})
	var out := FileAccess.open(path, FileAccess.WRITE)
	out.store_string(JSON.stringify(record, "\t"))


# --- looking at it ------------------------------------------------------------


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: mode = Mode.BATTLE
			KEY_2: mode = Mode.PIXEL
			KEY_3: mode = Mode.CROWD
			KEY_F: facing = (facing + 1) % FACINGS.size()
			KEY_B: big_units = not big_units
			KEY_A: _attack_time = 0.0
			KEY_P: show_portrait = not show_portrait
			KEY_EQUAL, KEY_KP_ADD: zoom = minf(zoom * 1.25, 4.0)
			KEY_MINUS, KEY_KP_SUBTRACT: zoom = maxf(zoom / 1.25, 0.4)
			KEY_F12: print("shot: %s" % _shoot("size_test"))
			_: return
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = minf(zoom * 1.1, 4.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = maxf(zoom / 1.1, 0.4)
		queue_redraw()


func _process(delta: float) -> void:
	if _attack_time >= 0.0:
		_attack_time += delta
		if _attack_time > 1.6:
			_attack_time = -1.0
		queue_redraw()


func _draw() -> void:
	var view := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.07, 0.08, 0.1))
	draw_string(_font, Vector2(16, 26), "Sprite size test — 64 · 32 · 16", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.95, 0.9, 0.75))
	draw_string(_font, Vector2(16, 48), "%s   ·   facing %s%s%s   ·   zoom %.1f" % [
		MODE_NAMES[mode], FACINGS[facing], "   ·   big units larger" if big_units else "",
		"   ·   attack" if _attack_time >= 0.0 else "", zoom,
	], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.75, 0.8, 0.88))
	draw_string(_font, Vector2(16, view.y - 14),
		"1 battle scale · 2 same pixel size · 3 crowd · F facing · B big units larger · A attack · P portrait · +/- zoom · F12 screenshot",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.65, 0.72))

	var patch := Vector2(PATCH) * CELL * zoom
	var total := patch.x * SIZES.size() + GAP * (SIZES.size() - 1)
	var left := maxf(16.0, (view.x - total) * 0.5)
	for i in SIZES.size():
		_draw_patch(SIZES[i], Vector2(left + i * (patch.x + GAP), 110), patch)
	if show_portrait:
		_draw_portrait(view)


func _draw_patch(size: int, at: Vector2, patch: Vector2) -> void:
	var cell := CELL * zoom
	for y in PATCH.y:
		for x in PATCH.x:
			var shade := 0.30 if (x + y) % 2 == 0 else 0.34
			draw_rect(Rect2(at + Vector2(x, y) * cell, Vector2(cell, cell)), Color(shade * 0.75, shade * 1.25, shade * 0.62))
	var previews := 0
	var missing := 0
	for spot: Array in _spots(size):
		var drawn := _draw_unit(size, spot[0], at + (Vector2(spot[1]) + Vector2(0.5, 0.5)) * cell)
		if drawn == "preview":
			previews += 1
		elif drawn == "missing":
			missing += 1
	var title := "%d × %d" % [size, size]
	var note := "made in PixelLab"
	var colour := Color(0.62, 0.92, 0.62)
	if size == 64:
		note = "the art on disk now"
	if previews > 0:
		note = "PREVIEW — shrunk from the 64, not generated"
		colour = Color(1.0, 0.45, 0.4)
	if missing > 0:
		note += " · %d missing" % missing
	draw_string(_font, at + Vector2(0, -26), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.95, 0.95, 0.95))
	draw_string(_font, at + Vector2(0, -8), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, colour)


## Where each body stands on a patch: four for the test, more for a crowd.
func _spots(size: int) -> Array:
	if mode != Mode.CROWD:
		return [[UNITS[0], Vector2i(1, 5)], [UNITS[1], Vector2i(3, 2)], [UNITS[2], Vector2i(4, 5)], [UNITS[3], Vector2i(2, 2)]]
	var out: Array = []
	var pool: Array = CROWD.filter(func(u: String) -> bool: return not sprite(size, u).is_empty())
	var i := 0
	for y in PATCH.y:
		for x in PATCH.x:
			if (x + y) % 2 == 0 and not pool.is_empty():
				out.append([pool[i % pool.size()], Vector2i(x, y)])
				i += 1
	return out


## Returns "made", "preview" or "missing".
func _draw_unit(size: int, unit: String, centre: Vector2) -> String:
	var face: String = FACINGS[facing]
	var found := sprite(size, unit, "idle", face)
	var texture: Texture2D = found.get("texture")
	if _attack_time >= 0.0 and unit == "sworn_blade":
		var attack := frames(size, unit, "attack", face)
		if not attack.is_empty():
			texture = attack[mini(int(_attack_time * ATTACK_FPS), attack.size() - 1)]
	var cell := CELL * zoom
	var shrink := 1.0
	if mode == Mode.PIXEL and texture != null:
		shrink = texture.get_size().y / 64.0
	draw_circle(centre + Vector2(2, cell * 0.18 * shrink), cell * 0.3 * shrink, Color(0, 0, 0, 0.3))
	if texture == null:
		draw_rect(Rect2(centre - Vector2(cell, cell) * 0.35, Vector2(cell, cell) * 0.7), Color(1, 0.3, 0.3, 0.6), false, 2.0)
		draw_string(_font, centre + Vector2(-cell * 0.3, 4), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.4, 0.4))
		return "missing"
	var source := texture.get_size()
	var height := cell * SPRITE_HEIGHT_CELLS
	if mode == Mode.PIXEL:
		# The 64 keeps its battle size; everything else keeps the 64's pixel size.
		height = cell * SPRITE_HEIGHT_CELLS * source.y / 64.0
	if big_units and unit == "club_ogre":
		height *= 1.6
	var drawn := source * (height / source.y)
	draw_texture_rect(texture, Rect2(centre - Vector2(drawn.x * 0.5, drawn.y * 0.5 + cell * 0.12), drawn), false)
	return "preview" if found.get("preview", false) else "made"


func _draw_portrait(view: Vector2) -> void:
	var portrait := _portrait()
	var box := Rect2(view.x - 300, view.y - 330, 280, 290)
	draw_rect(box, Color(0.1, 0.11, 0.14, 0.95))
	if portrait == null:
		draw_string(_font, box.position + Vector2(14, 30), "No portrait yet", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.9, 0.9))
		draw_string(_font, box.position + Vector2(14, 54), "art/size_test/portrait/sworn_blade.png", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.65, 0.72))
		return
	var fit := minf(250.0 / portrait.get_width(), 250.0 / portrait.get_height())
	draw_texture_rect(portrait, Rect2(box.position + Vector2(15, 15), portrait.get_size() * fit), false)
	draw_string(_font, box.position + Vector2(14, 282), "Bram — big face, small body", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 0.9, 0.9))


func _shoot(name: String) -> String:
	var folder := ProjectSettings.globalize_path("%s/shots" % ROOT)
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder.path_join("%s_%s.png" % [name, Time.get_datetime_string_from_system().replace(":", "-")])
	get_viewport().get_texture().get_image().save_png(path)
	return path
