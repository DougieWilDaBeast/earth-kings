extends RefCounted
## The credits, written into a list: who made the game, the engine's licence,
## and where the music, sound, art and fonts came from.
##
## Every word is in `data/credits.json`; this only lays it out. Shared by the
## credits screen off the title and the credits page of the system menu, so the
## two can never disagree. A section with `engine_components` also lists every
## third-party part Godot reports it was built with, read off the running
## engine so the list is right for whatever version ships.
##
## Loaded by path, not by `class_name` ([D41]).

const SaveFile := preload("res://src/chronicle/save_file.gd")

const PATH := "res://data/credits.json"

const HEADING := Color(0.965, 0.827, 0.443)
const NAME := Color(0.90, 0.87, 0.79)
const ROLE := Color(0.66, 0.64, 0.59)
const NOTICE := Color(0.56, 0.55, 0.52)


## The parsed credits, or an empty dictionary if the file is missing or broken.
static func read() -> Dictionary:
	var parsed: Variant = SaveFile.read(PATH)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Credits: could not read %s" % PATH)
		return {}
	return parsed


## Empties [param list] and writes the credits into it, one section after
## another, from [param credits] or, given nothing, from the file. Returns how
## many sections were written.
static func fill(list: VBoxContainer, credits: Dictionary = {}) -> int:
	if credits.is_empty():
		credits = read()
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	var sections: Array = credits.get("sections", [])
	for section: Dictionary in sections:
		list.add_child(_heading(str(section.get("heading", ""))))
		for entry: Dictionary in section.get("entries", []):
			list.add_child(_entry(entry))
		var notice := str(section.get("notice", ""))
		if notice != "":
			list.add_child(_notice(notice))
		if bool(section.get("engine_components", false)):
			for line in engine_components():
				list.add_child(_line(line, ROLE, 13))
		list.add_child(_gap())
	return sections.size()


## One line per third-party component of the running engine: its name and
## licence.
static func engine_components() -> PackedStringArray:
	var lines := PackedStringArray()
	for component: Dictionary in Engine.get_copyright_info():
		var licences := PackedStringArray()
		for part: Dictionary in component.get("parts", []):
			var licence := str(part.get("license", ""))
			if licence != "" and not licences.has(licence):
				licences.append(licence)
		lines.append("%s — %s" % [component.get("name", ""), ", ".join(licences)])
	return lines


static func _heading(text: String) -> Label:
	var label := _line(text, HEADING, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


static func _entry(entry: Dictionary) -> Control:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 0)
	var name_line := _line(str(entry.get("name", "")), NAME, 16)
	name_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	block.add_child(name_line)
	for key: String in ["role", "note"]:
		var text := str(entry.get(key, ""))
		if text == "":
			continue
		var line := _line(text, ROLE, 13)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		block.add_child(line)
	return block


static func _notice(text: String) -> Label:
	var label := _line(text, NOTICE, 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label


static func _gap() -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	return gap


static func _line(text: String, colour: Color, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", size)
	return label
