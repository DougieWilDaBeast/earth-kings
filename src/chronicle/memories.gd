extends RefCounted
## Chapter memories (D103, D53): every five floors a lead finds something in the
## Tower that gives a chapter of who they were back. Each is a found object lying
## on a floor (`data/memories.json`); picking it up plays a short scene and writes
## a line in the journal. Only the lead it belongs to ever finds it.
##
## What has been found is kept in the run's flags (`memory:<id>`), so it is saved
## with the run and gone with it. Loaded by path ([D41]).

const PREFIX := "memory:"


## Every memory [param lead_id] has, in chapter order.
static func of(lead_id: String) -> Array:
	return Database.memories.get(lead_id, [])


## The lead's memories lying in [param area_id] that have not been found yet.
static func lying_in(area_id: String, lead_id: String) -> Array:
	return of(lead_id).filter(func(memory: Dictionary) -> bool:
		return str(memory.get("area", "")) == area_id and not is_found(memory))


## The picture a memory lies as: the lead's own keepsake once it is drawn (A58 for chapter one,
## the same picture the opening shows falling, `art/props/memories/<lead>.png`; A35 for chapter
## two, `<lead>_2.png`), made once for both ([D358]); until then its own `art`, the coin pile.
static func art_of(memory: Dictionary, lead_id: String) -> String:
	var chapter := str(memory.get("chapter", "1"))
	var own := "memories/%s" % lead_id if chapter == "1" else "memories/%s_%s" % [lead_id, chapter]
	if AreaProp.has_art(own):
		return own
	return str(memory.get("art", "coin_pile"))


static func is_found(memory: Dictionary) -> bool:
	return GameState.has_flag(PREFIX + str(memory.get("id", "")))


## The lead's memories found so far, in chapter order.
static func found(lead_id: String) -> Array:
	return of(lead_id).filter(is_found)


static func cell_of(memory: Dictionary) -> Vector2i:
	var pair: Array = memory.get("cell", [0, 0])
	return Vector2i(int(pair[0]), int(pair[1]))


## Picked up: marked found, written in the annals, and the scene to play, as a
## conversation in the shape [method Database.register_dialogue] takes.
static func find(memory: Dictionary) -> Dictionary:
	GameState.set_flag(PREFIX + str(memory.get("id", "")))
	Annals.record(GameState.world, "%s: %s" % [str(memory.get("title", "A memory")), str(memory.get("journal", ""))])
	return { "lines": (memory.get("scene", []) as Array).duplicate(true) }
