extends Node
## Headless smoke test for the art pipeline around the sprite size test
## (`tools/size_test.tscn`, Tier 0 of [19 — Asset list]).
##
##   godot --headless --path . res://tests/art_smoke_test.tscn
##
## A PixelLab export is unpacked into the folders the viewer and the game read,
## whatever folders it came in, and its prompt is kept; a size nobody has made
## yet is shown as a preview and never passed off as the real thing.

const SizeTest := preload("res://tools/size_test.gd")
const DUMMY := "zz_art_test_unit"

var _failures: Array[String] = []


func _ready() -> void:
	var viewer: Node2D = SizeTest.new()
	var zip_path := OS.get_user_data_dir().path_join("art_test_export.zip")
	_pack(zip_path)

	var nothing: Array[String] = viewer.import_zip(zip_path, "", 32)
	_expect(nothing[-1].begins_with("NOT"), "an import with no unit named went ahead")

	var lines: Array[String] = viewer.import_zip(zip_path, DUMMY, 16)
	for line in lines:
		print(line)
	_expect(lines[-1].begins_with("Imported 5"), "the export did not unpack as five images: %s" % lines[-1])
	var still: Dictionary = viewer.sprite(16, DUMMY, "idle", "south")
	_expect(not still.is_empty() and not still["preview"], "an imported still was not found, or was taken for a preview")
	_expect(viewer.frames(16, DUMMY, "attack", "east").size() == 2, "an imported attack did not come back as two frames")
	var record: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		ProjectSettings.globalize_path("%s/16/%s/metadata.json" % [SizeTest.ROOT, DUMMY])))
	_expect(record is Dictionary and str(record["states"][0]["prompt"]).contains("test dummy"), "the export's prompt was not kept")

	var preview: Dictionary = viewer.sprite(32, "goblin")
	_expect(not preview.is_empty(), "no preview could be made for a goblin at 32")
	if not preview.is_empty() and not FileAccess.file_exists(ProjectSettings.globalize_path("%s/32/goblin/idle/south.png" % SizeTest.ROOT)):
		_expect(preview["preview"], "a shrunk 64 was passed off as generated art")
		_expect((preview["texture"] as Texture2D).get_size() == Vector2(32, 32), "the 32 preview is not 32 pixels")
	_expect(viewer.report().size() >= 10, "the report is missing lines")

	_remove(ProjectSettings.globalize_path("%s/16/%s" % [SizeTest.ROOT, DUMMY]))
	DirAccess.remove_absolute(zip_path)
	viewer.free()
	_finish()


## An export shaped the way PixelLab's are: rotations named for their facing,
## an animation as numbered frames under a facing folder, a metadata file, and
## something that is neither.
func _pack(path: String) -> void:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.4, 0.5, 0.6))
	var png := image.save_png_to_buffer()
	var zip := ZIPPacker.new()
	zip.open(path)
	for entry: String in [
		"character/rotations/south.png", "character/rotations/north.png", "character/rotations/east.png",
		"character/animations/slash/east/frame_000.png", "character/animations/slash/east/frame_001.png",
		"character/preview.png",
	]:
		zip.start_file(entry)
		zip.write_file(png)
		zip.close_file()
	zip.start_file("character/metadata.json")
	zip.write_file(JSON.stringify({"prompt": "a test dummy in grey"}).to_utf8_buffer())
	zip.close_file()
	zip.close()


func _remove(folder: String) -> void:
	var dir := DirAccess.open(folder)
	if dir == null:
		return
	for sub in dir.get_directories():
		_remove(folder.path_join(sub))
	for file in dir.get_files():
		dir.remove(file)
	DirAccess.remove_absolute(folder)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("art smoke test: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		print("FAIL  %s" % failure)
	print("art smoke test: FAIL")
	get_tree().quit(1)
