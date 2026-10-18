extends RefCounted
## The party's map of the continent ([D50]): black until somebody has been
## there, filled in as the party walks, and inked in further by maps — a
## Guild hall's map of its own country, a fragment found in a chest, a place a
## rumour names.
##
## Two layers live on [World], one bit a tile:
## - **explored** — ground the party has seen with its own eyes. Drawn in full.
## - **charted** — ground somebody else drew for you. Drawn dim: the lie of the
##   land, and nothing walking on it.
## And a set of **marked** places, drawn wherever they are, because somebody
## told you where they stand.
##
## Every number is in `world_rules.atlas` and the Guild's price in
## `data/guild.json` → `map`. Rolls for found maps come from a hash of the
## world, never from its dice, so a seeded run is not shifted by them.
##
## Loaded by path, not by `class_name` ([D41]).

const Coins := preload("res://src/chronicle/coins.gd")


static func rules() -> Dictionary:
	return Database.world_rules.get("atlas", {})


static func line(key: String, tokens: Dictionary = {}) -> String:
	return str(rules().get("lines", {}).get(key, key)).format(tokens)


static func sight() -> int:
	return int(rules().get("sight", 4))


# --- the layers ---------------------------------------------------------------


static func _bytes_for(world: World) -> int:
	return (world.size.x * world.size.y + 7) / 8


## Both layers sized to the world. A world made before there was a map comes
## out with nothing seen; [method World.from_dict] decides what an old save gets.
static func ensure(world: World) -> void:
	var wanted := _bytes_for(world)
	if world.explored.size() != wanted:
		world.explored = PackedByteArray()
		world.explored.resize(wanted)
	if world.charted.size() != wanted:
		world.charted = PackedByteArray()
		world.charted.resize(wanted)


static func _index(world: World, cell: Vector2i) -> int:
	if not world.in_bounds(cell):
		return -1
	return cell.y * world.size.x + cell.x


## Bit [param cell] of the explored layer, or the charted one.
static func _bit(world: World, cell: Vector2i, seen: bool) -> bool:
	var index := _index(world, cell)
	if index < 0:
		return false
	var byte := index / 8
	if seen:
		return byte < world.explored.size() and (world.explored[byte] >> (index % 8)) & 1 == 1
	return byte < world.charted.size() and (world.charted[byte] >> (index % 8)) & 1 == 1


## Sets the bit; true when it was not set before. Written straight into the
## world's own array, so nothing hangs on whether a packed array is a copy.
static func _set_bit(world: World, cell: Vector2i, seen: bool) -> bool:
	if _bit(world, cell, seen):
		return false
	var index := _index(world, cell)
	var mask := 1 << (index % 8)
	if seen:
		world.explored[index / 8] = world.explored[index / 8] | mask
	else:
		world.charted[index / 8] = world.charted[index / 8] | mask
	return true


static func is_explored(world: World, cell: Vector2i) -> bool:
	return _bit(world, cell, true)


## Explored, or drawn on a map the party carries.
static func is_charted(world: World, cell: Vector2i) -> bool:
	return _bit(world, cell, true) or _bit(world, cell, false)


## Share of the continent the party has seen for itself, 0.0–1.0.
static func share_explored(world: World) -> float:
	ensure(world)
	var count := 0
	for byte in world.explored:
		while byte:
			count += byte & 1
			byte >>= 1
	return float(count) / float(maxi(1, world.size.x * world.size.y))


## Everything within [param radius] of [param centre] is seen. Returns how many
## tiles were new, and tells the map (by [signal EventBus.ground_revealed]) so it
## can fade them in.
static func reveal_around(world: World, centre: Vector2i, radius: int = -1) -> int:
	return _paint(world, centre, sight() if radius < 0 else radius, true)


## Everything within [param radius] of [param centre] is drawn in, dim.
static func chart_around(world: World, centre: Vector2i, radius: int) -> int:
	return _paint(world, centre, radius, false)


static func _paint(world: World, centre: Vector2i, radius: int, seen: bool) -> int:
	ensure(world)
	var fresh: Array = []
	var reach := radius * radius + radius
	for y in range(centre.y - radius, centre.y + radius + 1):
		for x in range(centre.x - radius, centre.x + radius + 1):
			var cell := Vector2i(x, y)
			if not world.in_bounds(cell):
				continue
			var d := cell - centre
			if d.x * d.x + d.y * d.y > reach:
				continue
			var already := is_charted(world, cell)
			if _set_bit(world, cell, seen) and (seen or not already):
				fresh.append(cell)
	if not fresh.is_empty():
		EventBus.ground_revealed.emit(fresh)
	return fresh.size()


## Every tile seen: a save from before there was a map keeps the map it had.
static func explore_everything(world: World) -> void:
	ensure(world)
	world.explored.fill(255)


# --- places -------------------------------------------------------------------


static func _key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


## Whether the party knows [param site] is there: it has seen the tile, a map
## or a rumour marked it, or it is the kind of place anyone knows — the Tower is
## seen from everywhere, and home is home. A place a story is pulling the party
## towards, or a town under siege, is known because somebody came to say so.
static func knows(world: World, site: Site) -> bool:
	if site == null:
		return false
	if site.kind in rules().get("always_known", [Site.TOWER, Site.HOME]):
		return true
	if world.marked.has(_key(site.cell)) or is_explored(world, site.cell):
		return true
	return site.data.has("thread") or Town.is_threatened(site)


## Put [param site] on the map. True when it was not there before.
static func mark(world: World, site: Site) -> bool:
	if site == null or knows(world, site):
		return false
	world.marked[_key(site.cell)] = true
	return true


static func mark_cell(world: World, cell: Vector2i) -> bool:
	return mark(world, world.site_at(cell))


## Mark every place [param text] names. Returns the names newly marked.
static func hear_of(world: World, text: String) -> Array[String]:
	var named: Array[String] = []
	for site: Site in world.sites:
		if site.display_name != "" and text.contains(site.display_name) and mark(world, site):
			named.append(site.display_name)
	return named


# --- maps ---------------------------------------------------------------------


static func guild_terms() -> Dictionary:
	return Database.guild.get("map", {})


static func guild_map_price() -> int:
	return Difficulty.scaled(int(guild_terms().get("price", 1200)), "price")


static func guild_map_bought(hall: Site) -> bool:
	return hall != null and bool(hall.data.get("map_bought", false))


## The hall's map of its own country: the lie of the land around it, and the
## places the clerk thinks worth inking in. Returns { ok, line }.
static func buy_guild_map(world: World, hall: Site) -> Dictionary:
	var terms := guild_terms()
	var lines: Dictionary = terms.get("lines", {})
	if hall == null:
		return {"ok": false, "line": ""}
	if guild_map_bought(hall):
		return {"ok": false, "line": str(lines.get("already", "")).format({"hall": hall.display_name})}
	var price := guild_map_price()
	if GameState.gold < price:
		return {"ok": false, "line": str(lines.get("poor", "")).format({"price": Coins.text(price)})}
	GameState.gold -= price
	hall.data["map_bought"] = true
	var radius := int(terms.get("radius", 18))
	var drawn := chart_around(world, hall.cell, radius)
	var marked := _mark_near(world, hall.cell, radius, terms.get("marks", []), int(terms.get("max_marks", 5)), hall)
	var said := str(lines.get("bought", "")).format({
		"hall": hall.display_name, "price": Coins.text(price),
		"places": str(lines.get("marked", "")).format({"places": _list(marked)}) if not marked.is_empty()
			else str(lines.get("nothing_marked", "")),
	})
	if drawn == 0 and marked.is_empty():
		said = str(lines.get("nothing_new", "")).format({"hall": hall.display_name})
	return {"ok": true, "line": said, "marked": marked}


## The nearest places of the kinds in [param kinds] (in that order of interest)
## within [param radius], up to [param most] of them, marked.
static func _mark_near(world: World, centre: Vector2i, radius: int, kinds: Array, most: int, skip: Site) -> Array[String]:
	var near: Array = []
	for site: Site in world.sites:
		if site == skip or knows(world, site) or not kinds.has(site.kind):
			continue
		var d := site.cell - centre
		if d.x * d.x + d.y * d.y > radius * radius:
			continue
		near.append(site)
	near.sort_custom(func(a: Site, b: Site) -> bool:
		var ka := kinds.find(a.kind)
		var kb := kinds.find(b.kind)
		if ka != kb:
			return ka < kb
		return Pathfinder.distance(a.cell, centre) < Pathfinder.distance(b.cell, centre)
	)
	var marked: Array[String] = []
	for site: Site in near.slice(0, most):
		mark(world, site)
		marked.append(site.display_name)
	return marked


## A roll from the world and [param salt], not from its dice.
static func _roll(world: World, salt: Variant) -> float:
	return float(absi(hash([salt, world.steps, world.world_seed])) % 1000) / 1000.0


## Whether a find with this [param odds_key] (`world_rules.atlas`) holds a map.
static func finds_map(world: World, salt: Variant, odds_key: String) -> bool:
	if world == null:
		return false
	return _roll(world, [salt, odds_key]) < float(rules().get(odds_key, 0.0))


## Somebody's old map, folded small: a stretch of country somewhere else, and a
## place on it. Returns the lines worth showing.
static func read_fragment(world: World, salt: Variant = 0) -> Array[String]:
	var lines: Array[String] = []
	if world == null:
		return lines
	var kinds: Array = rules().get("fragment_marks", [Site.GATE, Site.LIBRARY, Site.KEEP, Site.VILLAGE])
	var unknown: Array = world.sites.filter(
		func(s: Site) -> bool: return kinds.has(s.kind) and not knows(world, s) and not s.cleared
	)
	var radius := int(rules().get("fragment_radius", 7))
	if unknown.is_empty():
		lines.append(line("fragment_stale"))
		return lines
	var pick: Site = unknown[int(_roll(world, [salt, "pick"]) * 1000.0) % unknown.size()]
	chart_around(world, pick.cell, radius)
	mark(world, pick)
	lines.append(line("fragment", {
		"place": pick.display_name,
		"bearing": Roadside.bearing(world.player_cell, pick.cell),
		"region": world.region_at(pick.cell),
	}))
	return lines


# --- walking itself -----------------------------------------------------------


const _STEPS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]


## The nearest tile the party could walk to that it has never seen, or (-1, -1)
## when every reachable tile has been seen. For a party walking itself with
## nowhere it knows of to go.
static func frontier(world: World, from: Vector2i) -> Vector2i:
	ensure(world)
	var seen: Dictionary = {from: true}
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for offset: Vector2i in _STEPS:
			var next := cell + offset
			if seen.has(next) or not world.is_walkable(next):
				continue
			if not is_explored(world, next):
				return next
			seen[next] = true
			queue.append(next)
	return Vector2i(-1, -1)


# --- saving -------------------------------------------------------------------


## A layer as a short string: deflated, then base64. 128 by 128 is 2 KB raw
## and a few hundred bytes like this.
static func encode(bits: PackedByteArray) -> String:
	if bits.is_empty():
		return ""
	return Marshalls.raw_to_base64(bits.compress(FileAccess.COMPRESSION_DEFLATE))


static func decode(text: String, world: World) -> PackedByteArray:
	if text == "":
		return PackedByteArray()
	var packed := Marshalls.base64_to_raw(text)
	var bits := packed.decompress(_bytes_for(world), FileAccess.COMPRESSION_DEFLATE)
	return bits if bits.size() == _bytes_for(world) else PackedByteArray()


static func _list(names: Array[String]) -> String:
	if names.size() <= 1:
		return "".join(names)
	return "%s and %s" % [", ".join(names.slice(0, names.size() - 1)), names[-1]]
