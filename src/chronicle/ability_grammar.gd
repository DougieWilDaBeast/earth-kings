class_name AbilityGrammar
extends RefCounted
## The hidden grammar powers are generated from, rather than authored.
##
## A tree is a theme crossed with a few effect archetypes at rising intensity.
## Absurd results are permitted output, not a bug — the world is allowed to be
## strange. What the world has *catalogued* of this grammar is the Codex.

const THEMES := {
	"edge": { "name": "Edge", "words": ["Keening", "Sundering", "Cleaving", "Whetted"], "archetypes": ["blow", "reach", "sweep"] },
	"ember": { "name": "Ember", "words": ["Guttering", "Kindled", "Roaring", "Ashen"], "archetypes": ["burst", "reach", "loose"] },
	"storm": { "name": "Storm", "words": ["Gathering", "Breaking", "Riven", "Thunderstruck"], "archetypes": ["burst", "loose", "sweep"] },
	"hunt": { "name": "Hunt", "words": ["Patient", "Loosed", "Unerring", "Cornered"], "archetypes": ["loose", "reach", "blow"] },
	"iron": { "name": "Iron", "words": ["Unyielding", "Hammered", "Cold", "Anvil-Borne"], "archetypes": ["blow", "sweep", "reach"] },
	"vigil": { "name": "Vigil", "words": ["Waking", "Watchful", "Sleepless", "Dawnward"], "archetypes": ["blow", "rally", "sweep"] },
	"hearth": { "name": "Hearth", "words": ["Banked", "Warm", "Mending", "Homeward"], "archetypes": ["mend", "rally", "reach"] },
	"mourning": { "name": "Mourning", "words": ["Quiet", "Grieving", "Remembered", "Unspoken"], "archetypes": ["mend", "burst", "rally"] },
	"wind": { "name": "Wind", "words": ["Drifting", "Swift", "Howling", "Scattering"], "archetypes": ["loose", "sweep", "reach"] },
}

const NOUNS := ["Blow", "Arc", "Ward", "Answer", "Rite", "Verse", "Step", "Oath", "Mark"]

const ARCHETYPES := {
	"blow": { "target": "enemy", "min_range": 1, "range": 1, "splash": 0, "power": 1.45 },
	"reach": { "target": "enemy", "min_range": 1, "range": 2, "splash": 0, "power": 1.2 },
	"loose": { "target": "enemy", "min_range": 2, "range": 4, "splash": 0, "power": 1.15 },
	"burst": { "target": "enemy", "min_range": 1, "range": 3, "splash": 1, "power": 0.95 },
	"sweep": { "target": "enemy", "min_range": 1, "range": 1, "splash": 1, "power": 0.9 },
	"mend": { "target": "ally", "min_range": 0, "range": 3, "splash": 0, "heal": true, "power": 20 },
	"rally": { "target": "ally", "min_range": 1, "range": 2, "splash": 1, "heal": true, "power": 12 },
}

## Rungs of a tree, weakest first. Later rungs cost more levels to reach.
const RUNG_SCALERS := [0.85, 1.0, 1.25]


## Build a new tree in [param theme]. The returned dict carries the full ability
## definitions so a save file can restore the world's powers exactly.
## [param understanding] is the world's Codex share: the better the grammar is
## catalogued, the more the world can get out of it.
static func generate_tree(theme: String, rng: RandomNumberGenerator, understanding: float = 0.0) -> Dictionary:
	var theme_data: Dictionary = THEMES.get(theme, THEMES["edge"])
	var words: Array = theme_data["words"]
	var tree_id := "%s_%06x" % [theme, rng.randi() & 0xFFFFFF]
	var mastery := 1.0 + understanding * float(
		Database.world_rules.get("codex", {}).get("power_per_understanding", 0.2)
	)

	var abilities: Dictionary = {}
	var order: Array = []
	var pool: Array = theme_data.get("archetypes", ARCHETYPES.keys())
	for rung in RUNG_SCALERS.size():
		var archetype_id: String = pool[rng.randi() % pool.size()]
		var archetype: Dictionary = ARCHETYPES[archetype_id].duplicate()
		var ability_id := "%s_r%d" % [tree_id, rung]
		var word: String = words[rng.randi() % words.size()]
		var noun: String = NOUNS[rng.randi() % NOUNS.size()]

		archetype["display_name"] = "%s %s" % [word, noun]
		archetype["description"] = "A %s power, catalogued rung %d." % [theme_data["name"].to_lower(), rung + 1]
		archetype["power"] = _scaled_power(archetype, RUNG_SCALERS[rung] * mastery)
		archetype["theme"] = theme
		abilities[ability_id] = archetype
		order.append(ability_id)

	return {
		"id": tree_id,
		"display_name": "%s of the %s" % [words[rng.randi() % words.size()], theme_data["name"]],
		"theme": theme,
		"abilities": order,
		"definitions": abilities,
	}


## Themes a character is compatible with; falls back to the whole grammar so a
## classless character can still be handed something.
static func themes_for(character: Character) -> Array:
	var themes: Array = character.class_data().get("themes", [])
	if themes.is_empty():
		themes = THEMES.keys()
	return themes


static func _scaled_power(archetype: Dictionary, scaler: float) -> float:
	var power := float(archetype["power"]) * scaler
	# Healing is expressed in flat HP, so keep it a whole number.
	return roundf(power) if archetype.get("heal", false) else snappedf(power, 0.05)
