class_name AreaCutscene
extends RefCounted
## Plays the beats in front of a conversation: a look at whoever you walked up
## to, a line of narration, and them closing the distance before they speak.
##
## Beats come from `data/cutscenes.json` and are deliberately few — this stages
## a meeting, it does not direct a film. Every beat is awaited in order, so a
## caller can simply `await play(id)` and then open the dialogue box.

## How fast somebody crosses the ground during a staged approach.
const WALK_SPEED := 110.0
## How long a beat holds when it does not say.
const DEFAULT_BEAT := 0.8

var _scene: Node
var _camera: CameraRig
var _frame: CutsceneLayer
var _you: AreaActor
var _them: AreaActor


static func between(scene: Node, camera: CameraRig, you: AreaActor, them: AreaActor) -> AreaCutscene:
	var cut := AreaCutscene.new()
	cut._scene = scene
	cut._camera = camera
	cut._you = you
	cut._them = them
	cut._frame = scene.get_tree().get_first_node_in_group(EventBus.CUTSCENE_FRAME_GROUP)
	return cut


func play(cutscene_id: String) -> void:
	var beats := Database.cutscene(cutscene_id)
	if beats.is_empty():
		return
	if _frame != null:
		await _frame.open()
	for beat: Dictionary in beats:
		await _run(beat)
	if _frame != null:
		await _frame.close()
	_camera.focus_on(_you.position)


func _run(beat: Dictionary) -> void:
	match beat.get("do", "wait"):
		"look":
			_camera.focus_on(_point(beat.get("at", "them")))
			await _hold(beat)
		"face":
			_actor(beat.get("who", "them")).face(
				_point(beat.get("at", "you")) - _actor(beat.get("who", "them")).position
			)
			await _hold(beat, 0.25)
		"say":
			if _frame != null:
				await _frame.say(beat.get("text", ""))
			await _hold(beat, 1.6)
		"approach":
			await _approach(_actor(beat.get("who", "them")), float(beat.get("gap", 88.0)))
		_:
			await _hold(beat)


## Walk somebody towards the other one, stopping [param gap] short. Scripted, so
## it goes straight there rather than picking its way around the scenery.
func _approach(who: AreaActor, gap: float) -> void:
	var other := _them if who == _you else _you
	var apart := who.position.distance_to(other.position)
	if apart <= gap:
		return
	var destination := other.position + (who.position - other.position).normalized() * gap
	who.face(destination - who.position)
	var tween := who.create_tween()
	tween.tween_property(who, "position", destination, (apart - gap) / WALK_SPEED)
	await tween.finished


func _hold(beat: Dictionary, fallback: float = DEFAULT_BEAT) -> void:
	var seconds := float(beat.get("time", fallback))
	if seconds <= 0.0:
		return
	await _scene.get_tree().create_timer(seconds).timeout


func _actor(who: String) -> AreaActor:
	return _you if who == "you" else _them


func _point(at: String) -> Vector2:
	match at:
		"you":
			return _you.position
		"between":
			return _you.position.lerp(_them.position, 0.5)
		_:
			return _them.position
