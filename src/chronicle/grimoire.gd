class_name Grimoire
extends RefCounted
## A book bought without knowing what is in it.
##
## Most of them are not spellbooks. Some are a useless little spell, a few are
## real doctrine, and a good number are somebody's sheep ledger. The price is
## agreed before the book is opened, which is the entire risk.

const DOCTRINE := "doctrine"
const TRIVIA := "trivia"
const DUD := "dud"


static func rules() -> Dictionary:
	return Database.grimoires


static func offer(site: Site) -> Dictionary:
	return site.data.get("grimoire", {})


## Put one on the shelf if the shelf is bare.
static func stock(site: Site, world: World) -> void:
	if not offer(site).is_empty():
		return
	var covers: Array = rules().get("covers", ["A book"])
	var patter: Array = rules().get("patter", [""])
	site.data["grimoire"] = {
		"cover": covers[world.rng.randi() % covers.size()],
		"patter": patter[world.rng.randi() % patter.size()],
		"price": int(rules().get("price_base", 90)) + world.rng.randi() % maxi(1, int(rules().get("price_spread", 70))),
	}


static func price(site: Site) -> int:
	return int(offer(site).get("price", 0))


## Pay, open it, and find out. Returns the lines worth showing, or empty if the
## shelf was bare or the purse was not deep enough.
static func buy_and_read(site: Site, reader: Character, world: World) -> Array[String]:
	var book := offer(site)
	if book.is_empty():
		return []
	var cost := int(book.get("price", 0))
	if GameState.gold < cost:
		return ["The asking price is %d gold, and you do not have it." % cost]

	GameState.gold -= cost
	site.data["grimoire"] = {}

	var lines: Array[String] = ["%s, for %d gold. %s" % [book.get("cover", "A book"), cost, book.get("patter", "")]]
	match _roll_kind(world):
		DOCTRINE:
			lines.append_array(_open_doctrine(reader, world))
		TRIVIA:
			lines.append_array(_open_trivia(world))
		_:
			lines.append_array(_open_dud(world))
	return lines


static func _roll_kind(world: World) -> String:
	var weights: Dictionary = rules().get("weights", {})
	var total := 0.0
	for key: String in weights:
		total += float(weights[key])
	if total <= 0.0:
		return DUD

	var roll := world.rng.randf() * total
	for key: String in weights:
		roll -= float(weights[key])
		if roll <= 0.0:
			return key
	return DUD


static func _open_doctrine(reader: Character, world: World) -> Array[String]:
	var unread: Array = Database.doctrine_ids().filter(
		func(id: String) -> bool: return not reader.knows(id)
	)
	# A real book they have already read is just an expensive reminder.
	if unread.is_empty():
		return ["It is sound work, and %s has read it before." % reader.display_name]

	var doctrine_id: String = unread[world.rng.randi() % unread.size()]
	Doctrine.learn(reader, doctrine_id, world.steps)
	return ["It is the real thing. %s reads %s." % [reader.display_name, Doctrine.title(doctrine_id)]]


static func _open_trivia(world: World) -> Array[String]:
	var entry := Trivia.discover(world)
	if entry.is_empty():
		return ["A small useless spell, and one you had already written down."]
	return ["Not doctrine. Something smaller.", Trivia.line(entry)]


static func _open_dud(world: World) -> Array[String]:
	var duds: Array = rules().get("duds", ["It is not a spellbook."])
	var reactions: Array = rules().get("dud_reactions", [""])
	return [
		duds[world.rng.randi() % duds.size()],
		reactions[world.rng.randi() % reactions.size()],
	]
