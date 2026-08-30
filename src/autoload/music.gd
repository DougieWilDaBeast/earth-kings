extends Node
## Background music (autoload: `Music`).
##
## Which scene hears which set of tracks lives in `data/music.json`; [Game]
## hands every scene change here and nothing else in the game touches a player.
## Two players are kept so one track can fade up while the last fades out.

const SILENT_DB := -80.0
const DEFAULT_FADE := 1.4
## Its own bus, so the player's volume and the crossfade never fight over the
## same number.
const BUS := "Music"
const SETTINGS_PATH := "user://settings.cfg"

## 0.0 - 1.0, what the player set. Mute is kept separate so it can be undone.
var volume: float = 0.8
var muted: bool = false

var _players: Array[AudioStreamPlayer] = []
var _active := 0
## The set currently sounding, so re-entering the same scene does not restart it.
var _set_id := ""
var _path := ""
## Set id -> the track it played last, so a battle rarely opens on the same one.
var _last_of: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _tween: Tween


func _ready() -> void:
	# Music should carry on over a paused game and through scene swaps.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_ensure_bus()
	_load_settings()
	for _i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = BUS
		player.volume_db = SILENT_DB
		add_child(player)
		_players.append(player)


func set_volume(level: float) -> void:
	volume = clampf(level, 0.0, 1.0)
	_apply_settings()
	_save_settings()


func set_muted(silent: bool) -> void:
	muted = silent
	_apply_settings()
	_save_settings()


func _ensure_bus() -> void:
	if AudioServer.get_bus_index(BUS) != -1:
		return
	var index := AudioServer.bus_count
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, BUS)
	AudioServer.set_bus_send(index, "Master")


func _apply_settings() -> void:
	var index := AudioServer.get_bus_index(BUS)
	if index == -1:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(index, muted or volume <= 0.0)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		volume = clampf(float(config.get_value("audio", "music_volume", volume)), 0.0, 1.0)
		muted = bool(config.get_value("audio", "music_muted", muted))
	_apply_settings()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "music_volume", volume)
	config.set_value("audio", "music_muted", muted)
	config.save(SETTINGS_PATH)


## Play whatever `data/music.json` gives this scene key (silence if nothing).
func for_scene(scene_key: String) -> void:
	var scenes: Dictionary = Database.music.get("scenes", {})
	play_set(str(scenes.get(scene_key, "")))


## Start a named set from `sets`; a set with several tracks picks one at random,
## never the one it just played.
func play_set(set_id: String) -> void:
	if set_id == "":
		stop()
		return
	if set_id == _set_id and _players[_active].playing:
		return
	var tracks: Array = Database.music.get("sets", {}).get(set_id, [])
	if tracks.is_empty():
		stop()
		return
	var track: Dictionary = _pick(tracks, set_id)
	var path := str(track.get("path", ""))
	if not ResourceLoader.exists(path):
		push_warning("Music: missing track '%s'" % path)
		return
	_set_id = set_id
	_path = path
	_last_of[set_id] = path
	_cross_to(path, float(track.get("volume_db", 0.0)))


func stop() -> void:
	_set_id = ""
	_path = ""
	_fade_out_all()


func _pick(tracks: Array, set_id: String) -> Dictionary:
	var last := str(_last_of.get(set_id, ""))
	var choices: Array = tracks.filter(
		func(t: Dictionary) -> bool: return str(t.get("path", "")) != last
	)
	if choices.is_empty():
		choices = tracks
	return choices[_rng.randi_range(0, choices.size() - 1)]


func _cross_to(path: String, volume_db: float) -> void:
	var stream: AudioStream = load(path)
	_make_looping(stream)
	var outgoing: AudioStreamPlayer = _players[_active]
	_reset_tween()
	_active = (_active + 1) % _players.size()
	var incoming: AudioStreamPlayer = _players[_active]
	incoming.stream = stream
	incoming.volume_db = SILENT_DB
	incoming.play()

	var fade := float(Database.music.get("fade", DEFAULT_FADE))
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(incoming, "volume_db", volume_db, fade)
	if outgoing.playing:
		_tween.tween_property(outgoing, "volume_db", SILENT_DB, fade)
		_tween.chain().tween_callback(outgoing.stop)


func _fade_out_all() -> void:
	_reset_tween()
	var player: AudioStreamPlayer = _players[_active]
	if not player.playing:
		return
	var fade := float(Database.music.get("fade", DEFAULT_FADE))
	_tween = create_tween()
	_tween.tween_property(player, "volume_db", SILENT_DB, fade)
	_tween.tween_callback(player.stop)


## A killed tween can leave a player stuck part-way through a fade, so the idle
## one is silenced outright before any new fade starts.
func _reset_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	for i in _players.size():
		if i != _active:
			_players[i].stop()


func _make_looping(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav: AudioStreamWAV = stream
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
	elif "loop" in stream:
		stream.set("loop", true)
