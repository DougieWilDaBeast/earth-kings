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
const AreaScene := preload("res://src/area/area_scene.gd")
const SkirmishSlot := preload("res://src/skirmish/skirmish_slot.gd")

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
	_remove(ProjectSettings.globalize_path("%s/16/%s" % [SizeTest.ROOT, DUMMY]))
	var picked: Array[String] = viewer.import_zip(zip_path, DUMMY, 16, "walk", "no_such_animation")
	_expect(picked[-1].begins_with("NOT"), "frames from an animation not asked for were imported")
	picked = viewer.import_zip(zip_path, DUMMY, 16, "walk", "slash")
	_expect(viewer.frames(16, DUMMY, "walk", "east").size() == 2, "the animation asked for was not imported")
	var api_export := {"export_version": "3.1", "states": [{"character": {"prompt": "a dummy from the API"}}]}
	_expect(SizeTest.export_prompt(api_export) == "a dummy from the API", "the API export's prompt was not found")

	var preview: Dictionary = viewer.sprite(32, "goblin")
	_expect(not preview.is_empty(), "no preview could be made for a goblin at 32")
	if not preview.is_empty() and not FileAccess.file_exists(ProjectSettings.globalize_path("%s/32/goblin/idle/south.png" % SizeTest.ROOT)):
		_expect(preview["preview"], "a shrunk 64 was passed off as generated art")
		_expect((preview["texture"] as Texture2D).get_size() == Vector2(32, 32), "the 32 preview is not 32 pixels")
	_expect(viewer.report().size() >= 10, "the report is missing lines")

	_remove(ProjectSettings.globalize_path("%s/16/%s" % [SizeTest.ROOT, DUMMY]))
	DirAccess.remove_absolute(zip_path)
	viewer.free()
	_check_moves()
	_check_art_slots()
	_check_read_when_drawn()
	_finish()


## A unit with a full fight set plays each move once and then stands again; a
## fall stays down until it is stood up; a unit with none keeps its pose.
func _check_moves() -> void:
	var knight := Unit.create("ooze_knight", Unit.Team.ENEMY, Vector2i.ZERO)
	add_child(knight)
	var standing := knight.current_sprite()
	for action in Unit.ACTIONS:
		_expect(knight.action_length(action) > 0.0, "the Amber Knight has no %s frames" % action)
	_expect(not knight.run_frames.is_empty(), "the Amber Knight's walk was not taken for its run")
	knight.play("attack")
	_expect(knight.playing() == "attack" and knight.current_sprite() != standing, "a swing did not change the picture")
	knight.play("hit")
	_expect(knight.playing() == "attack", "a flinch cut a swing short")
	knight._process(knight.action_length("attack") + 0.01)
	_expect(knight.playing() == "" and knight.current_sprite() == standing, "the knight did not stand again after a swing")
	knight.play("death")
	knight._process(knight.action_length("death") + 1.0)
	_expect(knight.playing() == "death", "a fall did not stay down")
	knight.play("attack")
	_expect(knight.playing() == "death", "a fallen unit swung")
	knight.stand()
	_expect(knight.current_sprite() == standing, "standing up did not bring back the standing pose")
	knight.free()
	var plain := Unit.create(_unanimated(), Unit.Team.ENEMY, Vector2i.ZERO)
	plain.play("attack")
	_expect(plain.playing() == "", "a unit with no swing frames played one")
	plain.free()


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


## The art still to be made has somewhere to land ([D344], `data/art_slots.json`): every request
## open in docs/24 from A51 has a slot, every file a size and a place under art/, every prop a size
## of its own in props.json, and every weapon kind a held picture the fighters read.
func _check_art_slots() -> void:
	var slots: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/art_slots.json"))
	_expect(slots is Dictionary and slots.has("requests"), "data/art_slots.json does not read")
	if not slots is Dictionary:
		return
	var requests: Dictionary = slots["requests"]
	# Every request still open in docs/24 has a slot ([D369]).
	var open_rows := FileAccess.get_file_as_string("res://docs/24-art-requests.md").get_slice("\n## Open", 1).get_slice("\n## ", 0)
	var opened := 0
	for line: String in open_rows.split("\n"):
		if line.begins_with("| A"):
			var id := line.get_slice("|", 1).strip_edges()
			opened += 1
			_expect(requests.has(id), "art slots: no slot for %s, open in docs/24" % id)
	_expect(opened > 0, "art slots: docs/24 lists nothing open")
	var files := 0
	for id: String in requests:
		_expect(str(requests[id].get("shows", "")) != "", "art slots: %s does not say where it shows" % id)
		for entry: Dictionary in requests[id].get("files", []):
			var names: Array = entry.get("each", [""])
			for each: String in names:
				var to := str(entry.get("to", "")).replace("{each}", each)
				files += 1
				_expect(to.begins_with("art/"), "art slots: %s lands outside art/: %s" % [id, to])
				var size: Variant = entry.get("size", null)
				_expect(str(size) == "any" or (size is Array and (size as Array).size() == 2), "art slots: %s's %s has no size" % [id, to])
				if to.begins_with("art/props/") and to.ends_with(".png") and bool(entry.get("prop", true)):
					var art_id := to.trim_prefix("art/props/").trim_suffix(".png")
					_expect(Database.props.get("art", {}).has(art_id), "art slots: %s has no size in props.json" % art_id)
	var held: Dictionary = Database.skirmish.get("held", {})
	for kind: String in ["blade", "spear", "bow", "staff", "axe", "hammer"]:
		_expect(str(held.get(kind, {}).get("sprite_dir", "")).begins_with("res://art/units/held/"), "art slots: no held picture for a %s" % kind)
	# A keepsake lies as its lead's own picture once drawn (A58, A35), the coin pile until then (D358).
	var memories := preload("res://src/chronicle/memories.gd")
	for lead: String in ["atlas", "cato"]:
		var chapter_one: String = memories.art_of({ "chapter": "1", "art": "coin_pile" }, lead)
		var drawn := ResourceLoader.exists("res://art/props/memories/%s.png" % lead)
		_expect(chapter_one == ("memories/%s" % lead if drawn else "coin_pile"), "a chapter-one keepsake lies as %s" % chapter_one)
		var chapter_two: String = memories.art_of({ "chapter": "2", "art": "coin_pile" }, lead)
		_expect(chapter_two == "coin_pile" or chapter_two == "memories/%s_2" % lead, "a chapter-two keepsake lies as %s" % chapter_two)
	# What waits on its picture names where it lands, and something stands in for it until then ([D369]).
	var stand_ins: Dictionary = Database.props.get("stand_ins", {})
	for wanted: String in stand_ins:
		if wanted.begins_with("_"):
			continue
		_expect(AreaProp.has_art(str(stand_ins[wanted])), "stand-ins: %s stands in as %s, which has no picture" % [wanted, stand_ins[wanted]])
		_expect(Database.props.get("art", {}).has(wanted), "stand-ins: %s has no size in props.json" % wanted)
		_expect(AreaProp.has_art(AreaProp.shown(wanted)), "stand-ins: %s is drawn as nothing" % wanted)
	var landing: Dictionary = {}
	for id: String in requests:
		for entry: Dictionary in requests[id].get("files", []):
			for each: String in entry.get("each", [""]):
				landing["res://" + str(entry.get("to", "")).replace("{each}", each)] = true
	var waiting := 0
	for unit_id: String in Database.units:
		var wanted := str((Database.units[unit_id] as Dictionary).get("art_wanted", "")) if Database.units[unit_id] is Dictionary else ""
		if wanted == "":
			continue
		waiting += 1
		_expect(landing.has(wanted.get_base_dir()), "art slots: %s waits on %s, which no request lands" % [unit_id, wanted])
		_expect(ResourceLoader.exists(str(Database.units[unit_id].get("sprite_dir", "")) + "/south.png"), "art slots: %s has nothing to stand in" % unit_id)
	# Once a unit's own picture is in it is drawn with it, untinted: tried on a goblin's.
	Database.units["_drawn_test"] = { "sprite_dir": "res://art/tier1/slime/idle", "tint": "#ff0000", "art_wanted": "res://art/tier1/goblin/idle" }
	Database._take_own_pictures()
	_expect(str(Database.units["_drawn_test"]["sprite_dir"]) == "res://art/tier1/goblin/idle" and not Database.units["_drawn_test"].has("tint"),
			"art slots: a unit whose own picture is in is not drawn with it")
	Database.units.erase("_drawn_test")
	print("art slots: %d requests, %d files, each with a size and a place to land; %d units and %d props stand in until drawn" % [requests.size(), files, waiting, stand_ins.size() - 1])


## The four requests the game had nowhere to read until [D370]: the fight screen's pictures (A2),
## the animals' sets (A29), the cloud sheet (A50) and the six Second Hour pieces with nothing to stand
## in (A34). Each is read where its slot lands it, and nothing shows or stands in the way before.
func _check_read_when_drawn() -> void:
	var landing: Dictionary = {}
	var slots: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/art_slots.json"))["requests"]
	for id: String in slots:
		for entry: Dictionary in slots[id].get("files", []):
			for each: String in entry.get("each", [""]):
				landing["res://" + str(entry.get("to", "")).replace("{each}", each)] = true
	for name: String in ["slot_frame", "cooldown_sweep", "paused_banner", "speed_indicator"]:
		var path := SkirmishSlot.FIGHT_UI % name
		_expect(landing.has(path), "read when drawn: the fight screen reads %s, which no request lands" % path)
		_expect((SkirmishSlot.picture(name) != null) == ResourceLoader.exists(path), "read when drawn: %s is not read as it stands" % name)
	var cloud := Database.tileset_sheet("cloud")
	_expect(landing.has(str(cloud.get("texture_wanted", ""))), "read when drawn: the cloud sheet waits on %s, which no request lands" % cloud.get("texture_wanted", ""))
	var animals: Dictionary = Database.world_rules.get("life", {}).get("animals", {})
	_expect(not (animals.get("kinds", []) as Array).is_empty(), "read when drawn: no animals named to walk the land")
	for kind: String in animals.get("kinds", []):
		_expect(landing.has(AreaScene.animal_folder(kind)), "read when drawn: the %s walks from %s, which no request lands" % [kind, AreaScene.animal_folder(kind)])
	# An animal is drawn from its set's still and walk: tried on the goblin's.
	var animal := AreaActor.for_animal("a test", "res://art/tier1/goblin")
	_expect(animal._rotations.size() == 8 and not animal._run.get(Vector2(0, 1), []).is_empty(), "read when drawn: an animal's set is not read")
	animal.free()
	var laid := 0
	for floor in [6, 7, 8, 10]:
		var area_id := "tower_floor_%d" % floor
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/areas/%s.json" % area_id))
		var map := AreaMap.load_area(area_id)
		for prop: Dictionary in data.get("props", []):
			if not bool(prop.get("when_drawn", false)):
				continue
			laid += 1
			var art := str(prop["art"])
			var cell := Vector2i(prop["cell"][0], prop["cell"][1])
			_expect(landing.has("res://art/props/%s.png" % art), "read when drawn: %s on %s is landed by no request" % [art, area_id])
			_expect(Database.props.get("art", {}).has(art), "read when drawn: %s has no size in props.json" % art)
			var placed := map.props.any(func(p: Dictionary) -> bool: return p.get("cell") == cell and p.get("art") == art)
			_expect(placed == AreaProp.has_art(art), "read when drawn: %s on %s is %s before its picture" % [art, area_id, "laid" if placed else "missing"])
			if not placed and bool(Database.area_terrain(map.terrain_at(cell)).get("walkable", true)):
				_expect(map.is_walkable(cell), "read when drawn: %s's cell on %s is in the way while it is undrawn" % [art, area_id])
	_expect(laid >= 6, "read when drawn: only %d Second Hour pieces wait on their pictures" % laid)
	print("read when drawn: 4 fight pictures, %d animals, the cloud sheet and %d Second Hour pieces read where they land" % [
		(animals.get("kinds", []) as Array).size(), laid])


func _finish() -> void:
	if _failures.is_empty():
		print("art smoke test: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		print("FAIL  %s" % failure)
	print("art smoke test: FAIL")
	get_tree().quit(1)


## Some unit that has a standing pose and no moves yet, whichever that is as art lands.
func _unanimated() -> String:
	for id: String in Database.units:
		if str(Database.unit_template(id).get("sprite_dir", "")) != "" \
				and Database.unit_run(id, "east").is_empty() \
				and Database.unit_frames(id, "attack", "south").is_empty():
			return id
	return ""
