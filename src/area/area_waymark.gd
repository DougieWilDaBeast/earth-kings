extends Node2D
## Where a click on the ground sent the party ([D189]): a pin stuck in the spot, and a dotted line
## from the leader's feet to it along the way they will walk. Gone when they get there or the
## walk is called off (`doug-md`, play-test 4: "it should showcase where you've clicked, maybe
## with a sort of pin ... draw a small line from the character to the pin").
##
## Drawn under the people, over the ground. Loaded by path ([D41]).

const LINE := Color(1.0, 0.86, 0.42, 0.75)
const PIN := Color(1.0, 0.82, 0.3)
const SHADOW := Color(0.05, 0.04, 0.08, 0.55)
## Dots and gaps along the line, in ground pixels.
const DASH := 7.0
const GAP := 6.0
const PIN_HEIGHT := 26.0

var _from: Vector2 = Vector2.ZERO
var _way: Array[Vector2] = []
var _clock: float = 0.0


## The leader stands at [param from] and is walking [param way] (empty: no pin).
func show_way(from: Vector2, way: Array[Vector2]) -> void:
	var was := not _way.is_empty()
	_from = from
	_way = way.duplicate()
	if was or not _way.is_empty():
		queue_redraw()


func _process(delta: float) -> void:
	if _way.is_empty():
		return
	_clock += delta
	queue_redraw()


func _draw() -> void:
	if _way.is_empty():
		return
	# The line, marching towards the pin.
	var points: Array[Vector2] = [_from]
	points.append_array(_way)
	var offset := fmod(_clock * 18.0, DASH + GAP)
	var carried := -offset
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var length := a.distance_to(b)
		if length < 0.5:
			continue
		var along := (b - a) / length
		var at := carried
		while at < length:
			var start := maxf(at, 0.0)
			var end := minf(at + DASH, length)
			if end > start:
				draw_line(a + along * start, a + along * end, LINE, 2.5)
			at += DASH + GAP
		carried = at - length
	# The pin: a shadow on the ground, a stem, and a head that bobs.
	var spot: Vector2 = _way.back()
	var bob := sin(_clock * 4.0) * 3.0
	draw_set_transform(spot, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 9.0, SHADOW)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var head := spot + Vector2(0, -PIN_HEIGHT + bob)
	draw_line(spot, head, SHADOW, 3.0)
	draw_line(spot, head, PIN, 1.5)
	draw_circle(head, 6.5, SHADOW)
	draw_circle(head, 5.0, PIN)
	draw_circle(head + Vector2(-1.5, -1.5), 1.6, Color(1, 1, 1, 0.8))
