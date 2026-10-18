extends RefCounted
## The world remembers ([D249], from Baldur's Gate 3 and Skyrim; Ewan's "what other games do well",
## #270 keep 6): the people who have heard what the company did say so to its face.
##
## - Anyone with a `talk` block (the Watch on the road, an innkeeper, anyone you can ask things)
##   brings up the newest deed whose word has reached their place ([Renown]: word walks, it does
##   not fly), once each, before their hello: "You're the one who shut Greyhollow." A townsperson
##   who only chats says it now and then instead of their chatter.
## - Where the company is disliked (its standing at or below `cold_at`), the same people turn it
##   away more often than not, until a coin or a word wins them round. Prices were already worse
##   there ([method Renown.price_multiplier]).
## - A faction whose own bands the company keeps beating holds a grudge: its bands see the company
##   from further off, and shout as they come. Kept on the world as `grudges`: faction id -> bands
##   beaten.
## - A later lead hears of an earlier one: a world that ends keeps a few of its lead's deeds in
##   its echo ([method keep], read by `siblings.gd`), and in the worlds after, somebody at the place
##   it happened has dreamt it, and says so once.
##
## Words and numbers are `world_rules.json` → `renown.remembered`. Loaded by path ([D41]).

const Coins := preload("res://src/chronicle/coins.gd")

## The flag a person sets once they have brought a deed up, so it is said to the company once.
const RECALLED := "recalled:"
const DREAMT := "dreamt:"


static func rules() -> Dictionary:
	return Renown.rules().get("remembered", {})


## The lines for a deed of [param kind] said in that tone, or none.
static func _lines_for(kind: String, warm: bool) -> Array:
	var entry: Dictionary = rules().get("kinds", {}).get(kind, {})
	return entry.get("warm" if warm else "cold", [])


## What was done, the way you would say it to the doer ("shut Greyhollow"), or "".
static func told(deed: Dictionary) -> String:
	if str(deed.get("told", "")) != "":
		return str(deed["told"])
	var entry: Dictionary = rules().get("kinds", {}).get(str(deed.get("kind", "")), {})
	var place := str(deed.get("place", ""))
	var said := str(entry.get("told", ""))
	if said == "" or (said.contains("{place}") and place == ""):
		return ""
	return said.format({ "place": place })


## Whether anybody could bring [param deed] up: it has lines of its own kind, or it was written
## down the way it would be said.
static func speakable(deed: Dictionary) -> bool:
	var warm := int(deed.get("weight", 0)) >= 0
	var kind := str(deed.get("kind", ""))
	var own := _lines_for(kind, warm)
	if not own.is_empty():
		return not str(own[0]).contains("{place}") or str(deed.get("place", "")) != ""
	return str(deed.get("told", "")) != "" and not _lines_for("told", warm).is_empty()


## The line [param deed] is brought up with. [param pick] chooses among the lines, so the same
## person says the same thing.
static func spoken(deed: Dictionary, pick: int) -> String:
	var warm := int(deed.get("weight", 0)) >= 0
	var lines := _lines_for(str(deed.get("kind", "")), warm)
	if lines.is_empty() or (str(lines[0]).contains("{place}") and str(deed.get("place", "")) == ""):
		lines = _lines_for("told", warm)
	if lines.is_empty():
		return ""
	return str(lines[absi(pick) % lines.size()]).format({
		"place": str(deed.get("place", "")), "told": told(deed),
	})


## The deeds the people at [param cell] could bring up, newest first.
static func heard_at(world: World, cell: Vector2i) -> Array:
	var out := Renown.heard_at(world, cell).filter(func(d: Dictionary) -> bool: return speakable(d))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("step", 0)) > int(b.get("step", 0)))
	return out


## What somebody with a `talk` block ([param who], the conversation's id) says before their hello,
## or "": the newest deed heard where the company stands that they have not brought up yet, or
## failing that, a dream of an earlier lead's. Said once: it sets its flag.
static func recall(world: World, who: String) -> String:
	if world == null:
		return ""
	var cell := world.player_cell
	for deed: Dictionary in heard_at(world, cell):
		var key := "%s%s:%d:%s" % [RECALLED, who, int(deed.get("step", 0)), str(deed.get("kind", ""))]
		if GameState.has_flag(key):
			continue
		GameState.set_flag(key)
		return spoken(deed, hash([who, deed.get("step", 0)]))
	return dream(world, cell, who)


## A townsperson who only chats, on `aside_chance` of [param roll]: the newest deed heard here,
## said instead of their chatter. Nothing is kept; it is chatter too.
static func aside(world: World, roll: float, who: String = "") -> String:
	if world == null or roll >= float(rules().get("aside_chance", 0.35)):
		return ""
	var heard := heard_at(world, world.player_cell)
	if heard.is_empty():
		return ""
	return spoken(heard[0], hash([who, heard[0].get("step", 0)]))


# --- colder where you crossed them --------------------------------------------


## Whether the people at [param cell] have heard enough against the company to turn it away.
static func is_cold(world: World, cell: Vector2i) -> bool:
	return world != null and Renown.standing(world, cell) <= int(rules().get("cold_at", -3))


## The cold shoulder, as a `talk` block's `refuse` ([Talk]): turned away on its `chance`, unless a
## coin or a word changes their mind.
static func cold_refusal() -> Dictionary:
	var cold: Dictionary = (rules().get("cold", {}) as Dictionary).duplicate(true)
	var bribe := int(cold.get("bribe", 0))
	if cold.has("bribe_q") and str(cold["bribe_q"]).contains("%s"):
		cold["bribe_q"] = str(cold["bribe_q"]) % Coins.text(bribe)
	return cold


## Whose own a band is: the faction its first fighter belongs to, beasts of the land included
## (they answer to the wild).
static func faction_of(pack: Array) -> String:
	return Faction.of(str(pack[0])) if not pack.is_empty() else Faction.FALLBACK


## A band of [param pack] beaten: its faction counts it. Returns the line for the moment the
## faction starts to hold a grudge, or "".
static func on_band_beaten(world: World, pack: Array) -> String:
	var faction := faction_of(pack)
	if faction in rules().get("no_grudge", []):
		return ""
	var count := int(world.grudges.get(faction, 0)) + 1
	world.grudges[faction] = count
	if count != int(rules().get("grudge_at", 3)):
		return ""
	return str(rules().get("grudge_line", "")).format({
		"faction": Faction.display_name(faction), "count": count,
	})


## Whether [param faction] has lost enough bands to the company to know it on sight.
static func holds_grudge(world: World, faction: String) -> bool:
	if world == null or faction in rules().get("no_grudge", []):
		return false
	return int(world.grudges.get(faction, 0)) >= int(rules().get("grudge_at", 3))


## What a band of [param pack] adds to its sight, in cells.
static func grudge_sight(world: World, pack: Array) -> float:
	return float(rules().get("grudge_sight", 1.0)) if holds_grudge(world, faction_of(pack)) else 0.0


## What a band of [param pack] shouts on seeing the company: a grudge's line, or "There!".
static func shout(world: World, pack: Array, pick: int) -> String:
	var shouts: Array = rules().get("grudge_shouts", [])
	if shouts.is_empty() or not holds_grudge(world, faction_of(pack)):
		return "There!"
	return str(shouts[absi(pick) % shouts.size()])


# --- a later lead hears -------------------------------------------------------


## What a world that ends keeps of its lead's deeds for the worlds after: the `dream_most`
## weightiest that can be told, as `{ cell, told, weight }`.
static func keep(world: World) -> Array:
	var told_ones: Array = world.deeds.filter(func(d: Dictionary) -> bool: return told(d) != "")
	told_ones.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return absi(int(a.get("weight", 0))) > absi(int(b.get("weight", 0))))
	var out: Array = []
	for deed: Dictionary in told_ones.slice(0, int(rules().get("dream_most", 6))):
		out.append({ "cell": deed.get("cell", [0, 0]), "told": told(deed), "weight": int(deed.get("weight", 0)) })
	return out


## In a later world, what somebody ([param who]) at [param cell] dreamt of an earlier lead who did
## something within `dream_reach` tiles of it, or "". Said once: it sets its flag.
static func dream(world: World, cell: Vector2i, who: String) -> String:
	var lines: Array = rules().get("dreamt", [])
	var past: Array = world.echoes.get("past", [])
	if lines.is_empty() or past.is_empty():
		return ""
	var reach := int(rules().get("dream_reach", 1))
	for index in past.size():
		var echo: Dictionary = past[index]
		var deeds: Array = echo.get("deeds", [])
		for i in deeds.size():
			var pair: Array = deeds[i].get("cell", [0, 0])
			if Pathfinder.distance(Vector2i(int(pair[0]), int(pair[1])), cell) > reach:
				continue
			var key := "%s%s:%d:%d" % [DREAMT, who, index, i]
			if GameState.has_flag(key):
				continue
			GameState.set_flag(key)
			return str(lines[absi(hash([who, index, i])) % lines.size()]).format({
				"name": str(echo.get("name", "someone")), "told": str(deeds[i].get("told", "")),
			})
	return ""
