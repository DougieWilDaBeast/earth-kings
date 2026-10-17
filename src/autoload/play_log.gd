extends Node
## The play log (autoload: `PlayLog`): a short, timed account of what the
## player did, for a play-tester to hand over after a session.
##
## It listens on [EventBus] only and writes plain lines: the run set out, the
## places walked into, each fight and how it went, levels, saves, falls, and any
## error the engine reported. Steps are counted, not listed. The last
## [constant MAX_LINES] lines are kept in `user://earth-kings.playlog.txt`, so a
## reload of the page keeps the session before it.
##
## The system menu hands it over: Copy puts it on the clipboard, Save downloads
## it from a browser or names the file on a desktop ([D125]).

const RunMode := preload("res://src/chronicle/run_mode.gd")

const PATH := "user://earth-kings.playlog.txt"
## About 25 KB at most: small enough to paste into a chat.
const MAX_LINES := 400
## A write to `user://` is a write to the browser's storage, so it waits a little.
const FLUSH_EVERY := 5.0
## The same error over and over is one line with a count, not a page of it.
const MAX_ERRORS := 40

var _lines: PackedStringArray = []
var _steps: int = 0
var _last_place: String = ""
var _fight_began: int = -1
var _dirty: bool = false
var _since_flush: float = 0.0
var _errors_seen: Dictionary = {}

var _mutex := Mutex.new()
## Errors land here from whatever thread raised them; [method _process] takes them in.
var _caught: PackedStringArray = []


## Hands the engine's errors to the log. Godot may call it from any thread.
class Catcher extends Logger:
	var _owner: WeakRef

	func _init(owner: Node) -> void:
		_owner = weakref(owner)

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		var play_log := _owner.get_ref() as Node
		if play_log == null:
			return
		var kind := "WARNING" if error_type == ERROR_TYPE_WARNING else "ERROR"
		var what := rationale if rationale != "" else code
		play_log.call("catch", "%s %s (%s:%d %s)" % [kind, what, file.get_file(), line, function])

	func _log_message(_message: String, _error: bool) -> void:
		pass


func _ready() -> void:
	_read()
	var build := "web" if OS.has_feature("web") else OS.get_name()
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		build += ", phone"
	note("=== game opened %s · v%s · %s" % [
		Time.get_date_string_from_system(), ProjectSettings.get_setting("application/config/version", "?"), build])
	OS.add_logger(Catcher.new(self))

	EventBus.safe_point_reached.connect(_on_safe_point)
	EventBus.request_scene.connect(_on_request_scene)
	EventBus.scene_changed.connect(_on_scene_changed)
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.battle_finished.connect(_on_battle_finished)
	EventBus.levelled_up.connect(_on_levelled_up)
	EventBus.class_chosen.connect(_on_class_chosen)
	EventBus.character_fell.connect(_on_character_fell)
	EventBus.run_ended.connect(func() -> void: note("RUN OVER: the last of the party is gone"))
	EventBus.game_saved.connect(func(point: String, said: String) -> void: note("saved (%s): %s" % [point, said]))
	EventBus.save_notice.connect(func(text: String) -> void: note("save notice: %s" % text))
	EventBus.player_did.connect(_on_player_did)


func _process(delta: float) -> void:
	_mutex.lock()
	var caught := _caught
	_caught = PackedStringArray()
	_mutex.unlock()
	for line in caught:
		var count := int(_errors_seen.get(line, 0)) + 1
		_errors_seen[line] = count
		# The first time, then the tenth, the hundredth: a flood is still visible.
		if count == 1 or count == 10 or count == 100:
			if _errors_seen.size() <= MAX_ERRORS:
				note(line if count == 1 else "%s ×%d" % [line, count])
	_since_flush += delta
	if _dirty and _since_flush >= FLUSH_EVERY:
		flush()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		flush()


## One timed line. Steps walked since the last line are said first.
func note(line: String) -> void:
	_say_steps()
	_add(line)


## An error from [Catcher]; safe from any thread.
func catch(line: String) -> void:
	_mutex.lock()
	_caught.append(line)
	_mutex.unlock()


## The whole log as it stands, newest last.
func text() -> String:
	_say_steps()
	return "\n".join(_lines) + "\n"


## Puts the log on the clipboard. On a phone's browser this can be refused;
## [method save_file] is the other way out.
func copy_to_clipboard() -> void:
	DisplayServer.clipboard_set(text())


## In a browser the log downloads as a file; elsewhere it is already a file, and
## this returns where it is.
func save_file() -> String:
	flush()
	var file_name := "earth-kings-playlog-%s.txt" % Time.get_datetime_string_from_system().replace(":", "-")
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(text().to_utf8_buffer(), file_name, "text/plain")
		return file_name
	var path := ProjectSettings.globalize_path(PATH)
	if not OS.has_feature("headless") and DisplayServer.get_name() != "headless":
		OS.shell_show_in_file_manager(path)
	return path


func clear() -> void:
	_lines = PackedStringArray()
	_steps = 0
	_errors_seen.clear()
	note("=== log cleared")
	flush()


func flush() -> void:
	_since_flush = 0.0
	if not _dirty:
		return
	_dirty = false
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(text())


func _read() -> void:
	if not FileAccess.file_exists(PATH):
		return
	for line in FileAccess.get_file_as_string(PATH).split("\n", false):
		_lines.append(line)
	_trim()


func _add(line: String) -> void:
	_lines.append("%s %s" % [Time.get_time_string_from_system(), line])
	_trim()
	_dirty = true


func _trim() -> void:
	if _lines.size() > MAX_LINES:
		_lines = _lines.slice(_lines.size() - MAX_LINES)


func _say_steps() -> void:
	if _steps > 0:
		var steps := _steps
		_steps = 0
		_add("  walked %d step%s" % [steps, "" if steps == 1 else "s"])


## "Atlas L3 24/30, Bram L2 18/22"
func _party() -> String:
	var out: PackedStringArray = []
	if GameState.roster == null:
		return ""
	for who in GameState.party_characters():
		out.append("%s L%d %d/%d" % [who.display_name, who.level, who.current_hp(), who.max_hp()])
	return ", ".join(out)


func _on_safe_point(point: String, said: String) -> void:
	if point != RunMode.START:
		return
	var world_seed: int = GameState.world.world_seed if GameState.world != null else 0
	note("--- run set out: seed %d · %s · %s · %s" % [
		world_seed, RunMode.display_name(GameState.mode), Difficulty.display_name(GameState.difficulty), said])
	note("  party: %s" % _party())


func _on_request_scene(key: String, payload: Dictionary) -> void:
	var place := str(payload.get("title", ""))
	if payload.has("tower_floor"):
		place = "TOWER FLOOR %d" % int(payload["tower_floor"])
	if key != "area" or place == "":
		return
	if place != _last_place:
		_last_place = place
		note("> %s" % place)


func _on_scene_changed(key: String) -> void:
	if key != "area" and key != "skirmish" and _last_place != "[%s]" % key:
		_last_place = "[%s]" % key
		note("> %s" % _last_place)


func _on_battle_started(map_id: String) -> void:
	_fight_began = Time.get_ticks_msec()
	note("FIGHT %s · party %s" % [map_id, _party()])


func _on_battle_finished(result: Dictionary) -> void:
	var took := ""
	if _fight_began >= 0:
		took = " in %ds" % ((Time.get_ticks_msec() - _fight_began) / 1000)
		_fight_began = -1
	note("  %s%s · party %s" % ["WON" if result.get("victory", false) else "LOST", took, _party()])


func _on_levelled_up(who: RefCounted, _before: Dictionary) -> void:
	var character := who as Character
	if character != null:
		note("LEVEL %s reached L%d" % [character.display_name, character.level])


func _on_class_chosen(who: RefCounted) -> void:
	var character := who as Character
	if character != null:
		note("  %s became %s" % [character.display_name, character.class_id])


func _on_character_fell(who: RefCounted, outcome: Dictionary) -> void:
	var who_name := (who as Character).display_name if who is Character else "?"
	# What saved them (or nothing) and who did it ([D197]: `dead ()` said nobody).
	var why: Array[String] = []
	if str(outcome.get("reason", "")) != "":
		why.append(str(outcome["reason"]))
	if str(outcome.get("killer", "")) != "":
		why.append("by " + str(outcome["killer"]))
	note("FELL %s: %s (%s)" % [who_name, outcome.get("outcome", "?"), ", ".join(why) if not why.is_empty() else "nobody named"])


func _on_player_did(what: String) -> void:
	if what == "walked":
		_steps += 1
	elif what.begins_with("fight_"):
		return  # battle_finished says it, with the party
	else:
		note("  %s" % what)
