class_name DialogueScript
extends RefCounted
## Branching conversation data: nodes, the replies the player can pick, and the
## skill checks some of those replies hide behind.
##
## A dialogue file is either a flat `lines` array (no choices) or a `nodes`
## object; both are normalised here into the same node shape:
## `{ speaker, text, next, options }`.

## Node id that closes the conversation.
const END := "end"
const DIE_SIDES := 20

## Check name -> how it reads on screen. The stat behind each is [method _skill_value].
const SKILLS := {
	"might": "Might",
	"guard": "Guard",
	"wits": "Wits",
	"renown": "Renown",
}

## Line list -> the variant said last time, so the same wording never comes up twice running.
static var _last_variant: Dictionary = {}


static func nodes(dialogue_id: String) -> Dictionary:
	var data := Database.dialogue(dialogue_id)
	if data.has("nodes"):
		return data["nodes"]
	return nodes_from_lines(data.get("lines", []))


## Where a conversation opens. A file with an `again` node uses it for everyone
## who has already been spoken to once, so a second visit is a second scene.
static func start_id(dialogue_id: String) -> String:
	var data := Database.dialogue(dialogue_id)
	if data.has("again") and GameState.times_told(dialogue_id) > 0 and nodes(dialogue_id).has(data["again"]):
		return data["again"]
	if data.has("start"):
		return data["start"]
	var ids := nodes(dialogue_id).keys()
	return ids[0] if not ids.is_empty() else END


## What a node says. Writing `text` as a list gives one beat several ways of
## being said and picks a fresh one each time it comes round.
static func text_of(node: Dictionary) -> String:
	var text: Variant = node.get("text", "")
	if not text is Array:
		return str(text)
	var lines: Array = text
	if lines.is_empty():
		return ""
	var key := hash(lines)
	var index := randi() % lines.size()
	if lines.size() > 1 and index == int(_last_variant.get(key, -1)):
		index = (index + 1) % lines.size()
	_last_variant[key] = index
	return str(lines[index])


## Speaker name -> the unit template they are drawn as, so the face in the box
## is the one standing in front of you.
static func cast(dialogue_id: String) -> Dictionary:
	return Database.dialogue(dialogue_id).get("cast", {})


## The forward-facing sprite of whoever is talking, or null when the line comes
## from nobody in particular — narration, or the result of a check. Roadside
## banter names no cast, so the roster is asked who goes by that name.
static func portrait(dialogue_id: String, speaker: String) -> Texture2D:
	var unit_id: String = cast(dialogue_id).get(speaker, "")
	if unit_id == "" and speaker != "":
		for character: Character in GameState.roster.characters:
			if character.display_name == speaker:
				unit_id = character.template_id
				break
	return Database.unit_face(unit_id)


## Replies whose flag and gold requirements the party currently meets, less any
## marked `once` that have already been said.
static func available_options(node: Dictionary, dialogue_id: String = "") -> Array:
	var out: Array = []
	for option: Dictionary in node.get("options", []):
		if not _requirements_met(option):
			continue
		if option.get("once", false) and GameState.has_flag(option_key(dialogue_id, option)):
			continue
		out.append(option)
	return out


## Where a `once` reply is written down once it has been used. Keyed by what it
## says, so shuffling a file's replies does not forget which were taken.
static func option_key(dialogue_id: String, option: Dictionary) -> String:
	return "said:%s:%d" % [dialogue_id, hash(option.get("text", ""))]


## Roll a d20 for the best-suited party member. A natural 20 always lands, a
## natural 1 never does.
static func roll(check: Dictionary) -> Dictionary:
	var skill: String = check.get("skill", "might")
	var dc := int(check.get("dc", 10))
	var champion := best_for(skill)
	var bonus := 0
	var who := "The party"
	if champion != null:
		bonus = _skill_value(champion, skill) / 2
		who = champion.display_name
	var die := randi_range(1, DIE_SIDES)
	var success := die == DIE_SIDES or (die != 1 and die + bonus >= dc)
	return {
		"skill": skill,
		"dc": dc,
		"who": who,
		"die": die,
		"bonus": bonus,
		"total": die + bonus,
		"success": success,
	}


static func check_title(check: Dictionary) -> String:
	var skill: String = check.get("skill", "might")
	return "%s check — DC %d" % [SKILLS.get(skill, skill.capitalize()), int(check.get("dc", 10))]


static func roll_text(result: Dictionary) -> String:
	var verdict: String = "Success" if result["success"] else "Failure"
	return "%s rolls %d + %d = %d.  %s." % [
		result["who"], result["die"], result["bonus"], result["total"], verdict
	]


## The party member with the highest value in [param skill].
static func best_for(skill: String) -> Character:
	var best: Character = null
	for character: Character in GameState.party_characters():
		if best == null or _skill_value(character, skill) > _skill_value(best, skill):
			best = character
	return best


## Flags set or cleared and gold gained or spent by a node or a reply.
static func apply_effects(source: Dictionary) -> void:
	for key: String in _as_array(source.get("set_flag", [])):
		GameState.set_flag(key)
	for key: String in _as_array(source.get("clear_flag", [])):
		GameState.flags.erase(key)
	var gold := int(source.get("gold", 0))
	if gold != 0:
		GameState.gold = maxi(0, GameState.gold + gold)


static func _skill_value(character: Character, skill: String) -> int:
	match skill:
		"guard":
			return character.defense()
		"wits":
			return character.speed()
		"renown":
			return character.level * 2 + Renown.notoriety(GameState.world, GameState.world.player_cell)
		_:
			return character.attack()


static func _requirements_met(option: Dictionary) -> bool:
	for key: String in _as_array(option.get("requires", [])):
		if not GameState.has_flag(key):
			return false
	for key: String in _as_array(option.get("requires_not", [])):
		if GameState.has_flag(key):
			return false
	return GameState.gold >= int(option.get("requires_gold", 0))


## Turn a flat list of `{ speaker, text }` into the same node shape a branching
## file produces, so anything built at runtime plays through the same box.
static func nodes_from_lines(lines: Array) -> Dictionary:
	var spoken := lines.filter(_speaker_is_here)
	var out: Dictionary = {}
	for i in spoken.size():
		var line: Dictionary = spoken[i]
		out["line_%d" % i] = {
			"speaker": line.get("speaker", ""),
			"text": line.get("text", ""),
			"next": "line_%d" % (i + 1) if i + 1 < spoken.size() else END,
		}
	return out


## A line tagged with `who` belongs to that unit; nobody speaks a run they are
## not on. Untagged lines are narration and are always heard.
static func _speaker_is_here(line: Dictionary) -> bool:
	var who: String = line.get("who", "")
	if who == "":
		return true
	return GameState.roster.characters.any(
		func(c: Character) -> bool: return c.template_id == who and not c.is_lost()
	)


static func _as_array(value: Variant) -> Array:
	if value is Array:
		return value
	if value is String and value != "":
		return [value]
	return []
