extends RefCounted
## What people are called, and what they get called — [D39].
##
## Names are regional and in a Roman and Greek register (`data/names.json`).
## Near a keep, where the nobility sit, people carry the strong, full form of a
## name; farther out, ordinary people carry a shortened stem of one. Everyone
## is also *of* somewhere, and the somewhere is the nearest real place.
##
## And everybody has a name they earned. For the lead it comes from what they
## have done that the country is still talking about, and it is how places that
## have heard of them speak of them (see [Renown]).
##
## Loaded by path, not by `class_name` ([D41]).


static func _data() -> Dictionary:
	return Database.names


## A person met at [param cell]: "Octavia of Greyford" near a keep, "Tavi of
## Fenreach" out in the fens.
static func person(world: World, cell: Vector2i, rng: RandomNumberGenerator) -> String:
	var strong: Dictionary = _data().get("strong", {})
	if strong.is_empty():
		return WorldGen.person_name(rng)
	var keys: Array = strong.keys()
	var full: String = keys[rng.randi() % keys.size()]
	var given := full
	if rng.randf() >= nobility(world, cell):
		var stems: Array = strong[full]
		if not stems.is_empty():
			given = str(stems[rng.randi() % stems.size()])
	return "%s of %s" % [given, home_of(world, cell, rng)]


## The chance somebody at [param cell] carries the strong form of their name:
## high beside a keep, falling away to almost nothing a long way from one.
static func nobility(world: World, cell: Vector2i) -> float:
	var reach := float(_data().get("noble_range", 10))
	var near := float(_data().get("noble_share", 0.8))
	var far := float(_data().get("far_share", 0.1))
	var distance := 9999
	for keep in world.sites_of_kind(Site.KEEP):
		distance = mini(distance, Pathfinder.distance(cell, keep.cell))
	var closeness := 1.0 - clampf(float(distance) / maxf(1.0, reach), 0.0, 1.0)
	return lerpf(far, near, closeness)


## The nearest settlement to [param cell], or a made-up spot if there is none.
static func home_of(world: World, cell: Vector2i, rng: RandomNumberGenerator) -> String:
	var best: Site = null
	for site in world.sites:
		if site.kind != Site.VILLAGE and site.kind != Site.KEEP and site.kind != Site.HUT:
			continue
		if best == null or Pathfinder.distance(cell, site.cell) < Pathfinder.distance(cell, best.cell):
			best = site
	return best.display_name if best != null else WorldGen.wild_name(rng)


# --- earned names --------------------------------------------------------------


## Kills of one kind it takes before the country names you for hunting it.
const HUNTER_AT := 10


## What the lead has come to be called, or "" if nothing they have done yet is
## worth a name. The biggest thing wins: the Tower over gates, gates over towns,
## towns over a long habit of killing one kind of thing.
static func earned_title(world: World) -> String:
	var counts := {}
	for deed: Dictionary in world.deeds:
		var kind := str(deed.get("kind", ""))
		counts[kind] = int(counts.get(kind, 0)) + 1
	if int(counts.get(Renown.TOWER_TOPPED, 0)) > 0:
		return "Spire-Climber"
	if int(counts.get(Renown.GATE_SHUT, 0)) >= 2:
		return "Gate-Shutter"
	if int(counts.get(Renown.TOWN_RAIDED, 0)) > int(counts.get(Renown.TOWN_SAVED, 0)):
		return "the Sacker of Towns"
	if int(counts.get(Renown.TOWN_SAVED, 0)) >= 1:
		return "Shield of the Villages"
	if int(counts.get(Renown.GATE_SHUT, 0)) == 1:
		return "Gate-Shutter"
	return _hunter_title(world)


## "Goblin Hunter" — for whatever the company has put down most, once it is a lot.
static func _hunter_title(world: World) -> String:
	var most := ""
	var most_felled := 0
	for kind: String in world.journal:
		var felled := int(world.journal[kind].get("felled", 0))
		if felled > most_felled:
			most_felled = felled
			most = kind
	if most == "" or most_felled < HUNTER_AT:
		return ""
	return "%s Hunter" % str(Database.unit_template(most).get("display_name", most))


## The lead's name as the country says it: "Bram the Gate-Shutter",
## "Goblin Hunter Sera", or just the name.
static func known_as(world: World, name: String) -> String:
	var title := earned_title(world)
	if title == "":
		return name
	if title.ends_with("Hunter"):
		return "%s %s" % [title, name]
	if title.begins_with("the "):
		return "%s %s" % [name, title]
	return "%s the %s" % [name, title]
