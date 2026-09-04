class_name Annals
extends RefCounted
## The Chronicle: narrative historical annals compiled from run telemetry.
##
## Records milestone events (first blood, fallen companions, gates shut,
## classes sworn, trees uncovered, spires conquered) into a persistent
## illustrated chronicle of the journey.


static func record(world: World, text: String) -> void:
	if world == null or text == "":
		return
	world.annals.append({
		"step": world.steps,
		"region": world.region_at(world.player_cell),
		"text": text,
	})


static func entries(world: World) -> Array:
	if world == null:
		return []
	return world.annals
