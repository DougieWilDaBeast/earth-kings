class_name Roster
extends RefCounted
## Everyone the player has. Characters stay on the roster after they die or are
## taken — losing someone should leave a gap you can see, not a silent deletion.

## Who the game starts you with; the first is yours.
const FOUNDING := ["bram", "sera", "toln"]
## Most that can be taken into a single fight.
const MAX_PARTY := 4

var characters: Array[Character] = []
## Character ids currently marching, in order.
var party: Array = []


static func found(lead_id: String = "") -> Roster:
	var roster := Roster.new()
	var band := _band(lead_id)
	for i in band.size():
		var character := Character.create(band[i], "", i == 0)
		roster.characters.append(character)
		roster.party.append(character.id)
	return roster


## Who rides out on day one: the chosen lead and whoever still follows them, or
## the founding three when nobody has chosen.
static func _band(lead_id: String) -> Array:
	var hero := Database.hero(lead_id)
	if hero.is_empty():
		return FOUNDING
	var band := [lead_id]
	band.append_array(hero.get("companions", []))
	return band


func add(character: Character) -> Character:
	characters.append(character)
	return character


func by_id(character_id: String) -> Character:
	for character in characters:
		if character.id == character_id:
			return character
	return null


func player() -> Character:
	for character in characters:
		if character.is_player:
			return character
	return characters[0] if not characters.is_empty() else null


func party_members() -> Array[Character]:
	var out: Array[Character] = []
	for character_id: String in party:
		var character := by_id(character_id)
		if character != null:
			out.append(character)
	return out


## Party members who can actually fight right now.
func fit_to_fight() -> Array[Character]:
	return party_members().filter(func(c: Character) -> bool: return c.is_available())


## Anyone lost to death or capture is quietly taken off the marching order.
func drop_the_lost() -> Array[Character]:
	var lost: Array[Character] = []
	for character in party_members():
		if character.is_lost():
			party.erase(character.id)
			lost.append(character)
	return lost


func enlist(character_id: String) -> bool:
	if party.size() >= MAX_PARTY or character_id in party:
		return false
	var character := by_id(character_id)
	if character == null or not character.is_available():
		return false
	party.append(character_id)
	return true


## Part ways. The player cannot walk out on their own run.
func dismiss(character_id: String) -> bool:
	var character := by_id(character_id)
	if character == null or character.is_player or character_id not in party:
		return false
	party.erase(character_id)
	return true


func rest() -> void:
	for character in party_members():
		if character.is_alive():
			character.hp = -1


func is_wounded() -> bool:
	return party_members().any(func(c: Character) -> bool: return c.is_wounded())


## The run belongs to the player character. Companions come and go — some do not
## get to see the end of it — but the story only stops when *they* do.
func run_is_over() -> bool:
	var lead := player()
	return lead == null or lead.is_lost()


func awaiting_class_choice() -> Character:
	for character in party_members():
		if character.pending_class_choice:
			return character
	return null


func to_dict() -> Dictionary:
	return {
		"characters": characters.map(func(c: Character) -> Dictionary: return c.to_dict()),
		"party": party,
	}


static func from_dict(payload: Dictionary) -> Roster:
	var roster := Roster.new()
	for entry: Dictionary in payload.get("characters", []):
		roster.characters.append(Character.from_dict(entry))
	roster.party = payload.get("party", [])
	return roster
