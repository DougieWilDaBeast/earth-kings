extends RefCounted
## The climbers' stone at the Tower's door (play-test 7, call BR3): the leads who climbed before, from
## every world of the sixteen that has ended, highest first, and this lead while they climb. Words in
## `data/world_rules.json` → `climbers_stone`. Loaded by path ([D41]).

const Sixteen := preload("res://src/chronicle/sixteen.gd")


static func rules() -> Dictionary:
	return Database.world_rules.get("climbers_stone", {})


## What the stone says, a line a name, for [param world] with [param lead] climbing it; the worlds
## that ended are [param past] (Sixteen.worlds() when not given).
static func lines(world: World, lead: Character, past: Variant = null) -> Array[String]:
	var ended: Array = Sixteen.worlds() if past == null else past
	var words := rules()
	var out: Array[String] = [str(words.get("heading", ""))]
	if str(words.get("top", "")) != "":
		out.append(str(words["top"]))
	var fallen := ended.duplicate()
	fallen.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("floor", 0)) > int(b.get("floor", 0)))
	var named := 0
	for gone: Dictionary in fallen:
		var name_ := str(gone.get("name", ""))
		if name_ == "":
			continue
		var floor_ := int(gone.get("floor", 0))
		var line := str(words.get("fallen" if floor_ > 0 else "not_up", "{name}")).format({ "name": name_, "floor": floor_ })
		out.append(line)
		named += 1
	if lead != null and world != null and world.tower_floor > 0:
		out.append(str(words.get("living", "{name}")).format({ "name": lead.display_name, "floor": world.tower_floor }))
		named += 1
	if named == 0:
		out.append(str(words.get("none", "")))
	return out
