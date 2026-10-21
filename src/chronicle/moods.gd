extends RefCounted
## How each of the company feels ([D279], Ewan's play-test 7: "a system where characters have
## emotions ... use inspiration from RimWorld ... so that the characters feel more life-like").
##
## A mood is a number: a base, and the thoughts each of them is carrying, each worth some mood and
## lasting so many steps (won a fight, lost one, shut a gate, climbed a floor they did or did not
## want to climb, lost a friend). Thoughts are noticed once a step from what has changed since the
## last one ([method tick]): the ledger's fights, the Tower's floor, the gates shut, who has died.
## Nothing else has to tell this about anything.
##
## The mood falls into a band (`world_rules.json` → `moods` → `bands`) that nudges how hard they fight
## ([method Character.mood_edge]), and at the bottom, now and then, one of them has had enough and
## sits out a while, away from the marching order like somebody sent on an errand ([Dispatch]).
## Loaded by path ([D41]). Pure logic: no nodes. Thoughts save on the character.

const SEEN := "moods:seen"


static func rules() -> Dictionary:
	return Database.world_rules.get("moods", {})


## The band [param character]'s mood falls in: `{ id, name, ... }`.
static func band(character: Character) -> Dictionary:
	return band_of(character.mood())


static func band_of(value: int) -> Dictionary:
	var bands: Array = rules().get("bands", [])
	for each: Dictionary in bands:
		if value < int(each.get("below", 0)):
			return each
	return bands.back() if not bands.is_empty() else {}


## The four-letter group a temper falls in, as the wanderers read it (NT, NF, SJ, SP).
static func group(character: Character) -> String:
	var code := character.temper
	if code.length() < 4:
		return "SJ"
	return ("N" + code[2]) if code[1] == "N" else ("S" + code[3])


## Give [param character] the thought [param id] from `moods.thoughts`, lasting from [param now].
## A thought already carried is refreshed, and stacks up to its `stack`.
static func think(character: Character, id: String, now: int, tokens: Dictionary = {}) -> void:
	var made: Dictionary = rules().get("thoughts", {}).get(id, {})
	if made.is_empty():
		return
	var worth := int(made.get("mood", 0))
	var by_group: Dictionary = made.get("by_group", {})
	if by_group.has(group(character)):
		worth = int(by_group[group(character)])
	if worth == 0:
		return
	var label := str(made.get("label", id))
	if worth < 0 and made.has("label_against"):
		label = str(made["label_against"])
	for key: String in tokens:
		label = label.replace("{%s}" % key, str(tokens[key]))
	var held := character.thoughts.filter(func(t: Dictionary) -> bool: return str(t.get("id", "")) == id)
	var until := now + int(made.get("lasts", 60))
	if held.size() >= int(made.get("stack", 1)):
		(held[0] as Dictionary)["until"] = until
		return
	character.thoughts.append({ "id": id, "label": label, "mood": worth, "until": until })


## What has happened since the last step, turned into thoughts for whoever was there; old
## thoughts forgotten; and anybody at the end of their rope perhaps sitting out a while. Returns
## lines worth showing.
static func tick(world: World, roster: Roster, away: Array, flags: Dictionary, ledger: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if world == null or roster == null:
		return lines
	var now := world.steps
	var gates := 0
	for site: Site in world.sites:
		if site.kind == Site.GATE and site.cleared:
			gates += 1
	var fallen: Array = []
	for character: Character in roster.characters:
		if character.status == Fate.DEAD:
			fallen.append(character.id)
	var here: Array = []
	for character: Character in roster.characters:
		here.append(character.id)
	var current := {
		"won": int(ledger.get("battles_won", 0)), "lost": int(ledger.get("battles_lost", 0)),
		"floor": world.tower_floor, "gates": gates, "fallen": fallen, "here": here, "names": _names(roster),
	}
	var seen: Variant = flags.get(SEEN)
	flags[SEEN] = current
	if not seen is Dictionary:
		return lines
	var was: Dictionary = seen
	var party := roster.party_members()
	for character: Character in party:
		character.thoughts = character.thoughts.filter(func(t: Dictionary) -> bool: return int(t.get("until", 0)) > now)
		if current["won"] > int(was.get("won", 0)):
			think(character, "won_fight", now)
		if current["lost"] > int(was.get("lost", 0)):
			think(character, "lost_fight", now)
		if current["gates"] > int(was.get("gates", 0)):
			think(character, "shut_gate", now)
		if current["floor"] > int(was.get("floor", 0)):
			think(character, "climbed", now)
		# A friend marching beside them ([D306]'s bonds), for as long as they do ([D347]).
		for other: Character in party:
			if other != character and _friends(character, other.id):
				think(character, "with_friend", now, { "name": other.display_name })
				break
	for id: String in fallen:
		if (was.get("fallen", []) as Array).has(id):
			continue
		var dead := roster.by_id(id)
		var named := { "name": dead.display_name if dead != null else "a friend" }
		for character: Character in roster.characters:
			if character.status != Fate.ALIVE or character.id == id:
				continue
			if _friends(character, id):
				think(character, "friend_fell", now, named)
			elif party.has(character):
				# Somebody they were not close to, but they saw it ([D347]).
				think(character, "saw_fall", now, named)
	# A friend gone their own way: let go, or a sellsword whose job was done ([D347]).
	for id: Variant in was.get("here", []):
		if here.has(id) or fallen.has(id):
			continue
		for character: Character in roster.characters:
			if character.status == Fate.ALIVE and _friends(character, str(id)):
				think(character, "parted", now, { "name": str((was.get("names", {}) as Dictionary).get(id, "a friend")) })
	lines.append_array(_breaks(world, roster, away, party))
	return lines


## A night's rest ([D347]): everyone marching is the better for it.
static func rested(roster: Roster, now: int) -> void:
	if roster == null:
		return
	for character: Character in roster.party_members():
		if character.is_alive():
			think(character, "rested", now)


## Whether [param character] counts [param other_id] a friend: a bond of `friend_bond` or more.
static func _friends(character: Character, other_id: String) -> bool:
	return int(character.bonds.get(other_id, 0)) >= int(rules().get("friend_bond", 3))


static func _names(roster: Roster) -> Dictionary:
	var out := {}
	for character: Character in roster.characters:
		out[character.id] = character.display_name
	return out


## Whether [param character] is low (Low, or at the end of their rope) or glad (Content, or in good
## heart): what colours what they say ([D347]). "" for steady.
static func feeling(character: Character) -> String:
	var id := str(band(character).get("id", "steady"))
	if id in ["broken", "low"]:
		return "low"
	if id in ["content", "glad"]:
		return "glad"
	return ""


## Somebody at the end of their rope may walk off and sit it out. Never the lead, and never the
## last one with the lead.
static func _breaks(world: World, roster: Roster, away: Array, party: Array) -> Array[String]:
	var lines: Array[String] = []
	var r := rules()
	for character: Character in party:
		if character.is_player or roster.party_members().size() <= 1:
			continue
		if character.mood() >= int(r.get("break_below", 20)):
			continue
		var roll := float(absi(hash([character.id, world.steps, world.world_seed])) % 1000) / 1000.0
		if roll >= float(r.get("break_chance", 0.1)):
			continue
		roster.party.erase(character.id)
		var back := world.steps + int(r.get("break_steps", 40))
		away.append({
			"id": character.id, "sulk": true, "to_name": str(r.get("break_place", "somewhere quiet")),
			"from": [world.player_cell.x, world.player_cell.y], "to": [world.player_cell.x, world.player_cell.y],
			"sent_at": world.steps, "out_at": world.steps, "back_at": back, "arrived": true,
		})
		lines.append(str(r.get("break_line", "{name} has had enough, and sits out a while.")).replace("{name}", character.display_name))
	return lines


## One line for the party screen: how they feel and why.
static func summary(character: Character) -> String:
	var mood := character.mood()
	var why: Array = character.thoughts.map(
		func(t: Dictionary) -> String: return "%s (%+d)" % [str(t.get("label", "")), int(t.get("mood", 0))])
	var said := "%s, %d" % [str(band(character).get("name", "Steady")), mood]
	return said if why.is_empty() else "%s: %s" % [said, ", ".join(why)]
