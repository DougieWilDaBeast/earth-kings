class_name AreaCutscene
extends RefCounted
## Plays the beats in front of a conversation: a look at whoever you walked up
## to, a line of narration, and them closing the distance before they speak.
##
## Beats come from `data/cutscenes.json` and are deliberately few — this stages
## a meeting, it does not direct a film. Every beat is awaited in order, so a
## caller can simply `await play(id)` and then open the dialogue box.

signal cutscene_skipped
signal beat_done

## How fast somebody crosses the ground during a staged approach.
const WALK_SPEED := 110.0
## How long a beat holds when it does not say.
const DEFAULT_BEAT := 0.8

var _scene: Node
var _camera: CameraRig
var _frame: CutsceneLayer
var _you: AreaActor
var _them: AreaActor
var _skipped: bool = false
var _active_tween: Tween = null


static func between(scene: Node, camera: CameraRig, you: AreaActor, them: AreaActor) -> AreaCutscene:
	var cut := AreaCutscene.new()
	cut._scene = scene
	cut._camera = camera
	cut._you = you
	cut._them = them
	cut._frame = scene.get_tree().get_first_node_in_group(EventBus.CUTSCENE_FRAME_GROUP)
	return cut


func skip() -> void:
	if _skipped:
		return
	_skipped = true
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
		_active_tween = null
	cutscene_skipped.emit()
	beat_done.emit()


func play(cutscene_id: String) -> void:
	var beats := Database.cutscene(cutscene_id)
	if beats.is_empty():
		return
	_skipped = false
	var on_skip := func() -> void:
		skip()
	if _frame != null and is_instance_valid(_frame):
		_frame.skip_requested.connect(on_skip)
		await _frame.open()

	for i in range(beats.size()):
		if not is_instance_valid(_scene) or not _scene.is_inside_tree() or not is_instance_valid(_you):
			break
		if _skipped:
			_fast_forward(beats.slice(i))
			break
		await _run(beats[i])

	if _frame != null and is_instance_valid(_frame):
		if _frame.skip_requested.is_connected(on_skip):
			_frame.skip_requested.disconnect(on_skip)
		await _frame.close()
	if is_instance_valid(_camera) and is_instance_valid(_you):
		_camera.focus_on(_you.position)


func _fast_forward(remaining_beats: Array) -> void:
	if not is_instance_valid(_you):
		return
	for beat: Dictionary in remaining_beats:
		match beat.get("do", "wait"):
			"face":
				var act := _actor(beat.get("who", "them"))
				if is_instance_valid(act):
					act.face(_point(beat.get("at", "you")) - act.position)
			"approach":
				var who := _actor(beat.get("who", "them"))
				if is_instance_valid(who):
					var other := _them if who == _you else _you
					if is_instance_valid(other):
						var gap := float(beat.get("gap", 88.0))
						var apart := who.position.distance_to(other.position)
						if apart > gap:
							var destination := other.position + (who.position - other.position).normalized() * gap
							who.position = destination
							who.face(destination - who.position)


func _run(beat: Dictionary) -> void:
	if _skipped or not is_instance_valid(_scene) or not _scene.is_inside_tree() or not is_instance_valid(_you):
		return
	match beat.get("do", "wait"):
		"look":
			if is_instance_valid(_camera):
				_camera.focus_on(_point(beat.get("at", "them")))
			await _hold(beat)
		"face":
			var act := _actor(beat.get("who", "them"))
			if is_instance_valid(act):
				act.face(_point(beat.get("at", "you")) - act.position)
			await _hold(beat, 0.25)
		"say":
			if _frame != null and is_instance_valid(_frame):
				await _frame.say(beat.get("text", ""))
			await _hold(beat, 1.6)
		"approach":
			var act := _actor(beat.get("who", "them"))
			if is_instance_valid(act):
				await _approach(act, float(beat.get("gap", 88.0)))
		_:
			await _hold(beat)


## Walk somebody towards the other one, stopping [param gap] short. Scripted, so
## it goes straight there rather than picking its way around the scenery.
func _approach(who: AreaActor, gap: float) -> void:
	if not is_instance_valid(who) or not is_instance_valid(_you):
		return
	var other := _them if who == _you else _you
	if not is_instance_valid(other):
		return
	var apart := who.position.distance_to(other.position)
	if apart <= gap:
		return
	var destination := other.position + (who.position - other.position).normalized() * gap
	who.face(destination - who.position)
	if _skipped:
		who.position = destination
		return

	var duration := (apart - gap) / WALK_SPEED
	var tween := who.create_tween()
	_active_tween = tween
	tween.tween_property(who, "position", destination, duration)

	var finished := false
	var on_done := func() -> void:
		if not finished:
			finished = true
			beat_done.emit()

	var on_skip := func() -> void:
		if not finished:
			finished = true
			if tween != null and tween.is_valid():
				tween.kill()
			if is_instance_valid(who):
				who.position = destination
			beat_done.emit()

	cutscene_skipped.connect(on_skip, CONNECT_ONE_SHOT)
	tween.finished.connect(on_done, CONNECT_ONE_SHOT)
	await beat_done
	if cutscene_skipped.is_connected(on_skip):
		cutscene_skipped.disconnect(on_skip)
	_active_tween = null


func _hold(beat: Dictionary, fallback: float = DEFAULT_BEAT) -> void:
	if _skipped or not is_instance_valid(_scene) or not _scene.is_inside_tree():
		return
	var seconds := float(beat.get("time", fallback))
	if seconds <= 0.0:
		return
	var tree := _scene.get_tree()
	if tree == null:
		return
	var timer := tree.create_timer(seconds)
	var timed_out := false
	var on_timeout := func() -> void:
		if not timed_out:
			timed_out = true
			beat_done.emit()
	var on_skip := func() -> void:
		if not timed_out:
			timed_out = true
			beat_done.emit()
	cutscene_skipped.connect(on_skip, CONNECT_ONE_SHOT)
	timer.timeout.connect(on_timeout, CONNECT_ONE_SHOT)
	await beat_done
	if cutscene_skipped.is_connected(on_skip):
		cutscene_skipped.disconnect(on_skip)


func _actor(who: String) -> AreaActor:
	return _you if who == "you" else _them


func _point(at: String) -> Vector2:
	var you_pos := _you.position if is_instance_valid(_you) else Vector2.ZERO
	var them_pos := _them.position if is_instance_valid(_them) else you_pos
	match at:
		"you":
			return you_pos
		"between":
			return you_pos.lerp(them_pos, 0.5)
		_:
			return them_pos
