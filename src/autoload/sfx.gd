extends Node
## Interface and fight sounds (autoload: `Sfx`).
##
## One-shot noises the menus make, kept apart from [Music] so a player who wants
## the score quiet can still hear that a button took the click; and the fight's
## swings, hits and spells, played by name as cues from `data/sfx.json`
## ([method cue], [D76]). Files live in `audio/sfx/`; nothing here loops.

const BUS := "Sfx"
const SETTINGS_PATH := "user://settings.cfg"
const DIR := "res://audio/sfx"
## How many can sound at once before the oldest is cut off, unless
## `data/sfx.json` asks for more (a fight is many sounds at once).
const VOICES := 4

const HOVER := "hover"
const SELECT := "select"

## 0.0 - 1.0, what the player set.
var volume: float = 0.7
var muted: bool = false

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _streams: Dictionary = {}
## When each cue last sounded, in milliseconds since start.
var _last_cued: Dictionary = {}
## How many times each cue has sounded since the game started, so a suite can
## tell a fight that was heard from one that was silent.
var counts: Dictionary = {}
## Its own dice for pitch, so a cue (whose `gap` is wall-clock time) never draws
## from the global ones a seeded fight rolls with (D180's same seed, same bout).
var _pitch_dice := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus()
	_load_settings()
	var voices := maxi(VOICES, int(Database.sfx.get("voices", VOICES)))
	for _i in voices:
		var player := AudioStreamPlayer.new()
		player.bus = BUS
		add_child(player)
		_players.append(player)


func play(sound: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream := _stream(sound)
	if stream == null:
		return
	var player: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()


## Sound one of the cues in `data/sfx.json` by name: its file at its volume, a
## pitch picked from its range, and nothing at all if the same cue sounded less
## than its `gap` ago. Returns whether it sounded. An unknown cue is silent.
func cue(cue_id: String) -> bool:
	var spec: Dictionary = Database.sfx.get("cues", {}).get(cue_id, {})
	if spec.is_empty():
		return false
	var now := Time.get_ticks_msec()
	var gap_ms := roundi(float(spec.get("gap", 0.0)) * 1000.0)
	if _last_cued.has(cue_id) and now - int(_last_cued[cue_id]) < gap_ms:
		return false
	_last_cued[cue_id] = now
	counts[cue_id] = int(counts.get(cue_id, 0)) + 1
	var span: Array = spec.get("pitch", [1.0, 1.0])
	var pitch := _pitch_dice.randf_range(float(span[0]), float(span[1])) if span.size() >= 2 else 1.0
	play(str(spec.get("file", cue_id)), float(spec.get("volume_db", 0.0)), pitch)
	return true


## Wire a button up to both noises it should make. Disabled buttons stay silent.
func attend(button: BaseButton) -> void:
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			play(HOVER)
	)
	button.pressed.connect(func() -> void: play(SELECT))


func set_volume(level: float) -> void:
	volume = clampf(level, 0.0, 1.0)
	_apply_settings()
	_save_settings()


func set_muted(silent: bool) -> void:
	muted = silent
	_apply_settings()
	_save_settings()


func _stream(sound: String) -> AudioStream:
	if _streams.has(sound):
		return _streams[sound]
	var path := "%s/%s.wav" % [DIR, sound]
	if not ResourceLoader.exists(path):
		push_warning("Sfx: no sound '%s'" % sound)
		_streams[sound] = null
		return null
	_streams[sound] = load(path)
	return _streams[sound]


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
		volume = clampf(float(config.get_value("audio", "sfx_volume", volume)), 0.0, 1.0)
		muted = bool(config.get_value("audio", "sfx_muted", muted))
	_apply_settings()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "sfx_volume", volume)
	config.set_value("audio", "sfx_muted", muted)
	config.save(SETTINGS_PATH)
