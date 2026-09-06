class_name Season
extends RefCounted
## The four seasons of the year, represented by the four clovers:
## - Lesser Green Clover: Spring (the thaw, budding life, awakening paths)
## - Green Clover: Summer (lush foliage, full sun, abundant roads)
## - Brown Clover: Autumn (harvest, withering boughs, turning earth)
## - Ice Clover: Winter (frost, frozen passes, severe travel)
##
## Like everything in Earth Kings, the seasons advance strictly on footsteps:
## every 900 steps is one season, four seasons make one continental year (3,600 steps).

const STEPS_PER_SEASON := 900
const SEASONS_PER_YEAR := 4
const STEPS_PER_YEAR := 3600

const SEASONS: Array[Dictionary] = [
	{
		"id": "spring",
		"index": 0,
		"display_name": "Spring",
		"clover": "lesser_green",
		"clover_name": "Lesser Green Clover",
		"texture_path": "res://art/props/nature/clover_lesser_green.png",
		"ui_texture_path": "res://art/ui/seasons/clover_lesser_green.png",
		"colour": Color(0.55, 0.82, 0.48),
		"blurb": "Tender shoots break through the thaw. The country awakens under the Lesser Green Clover.",
		"arrival": "The thaw sets in: Spring awakens under the Lesser Green Clover.",
	},
	{
		"id": "summer",
		"index": 1,
		"display_name": "Summer",
		"clover": "green",
		"clover_name": "Green Clover",
		"texture_path": "res://art/props/nature/clover_green.png",
		"ui_texture_path": "res://art/ui/seasons/clover_green.png",
		"colour": Color(0.32, 0.85, 0.35),
		"blurb": "Foliage thickens and the meadows flourish. Days are long under the Green Clover.",
		"arrival": "The sun rises high: Summer flourishes under the Green Clover.",
	},
	{
		"id": "autumn",
		"index": 2,
		"display_name": "Autumn",
		"clover": "brown",
		"clover_name": "Brown Clover",
		"texture_path": "res://art/props/nature/clover_brown.png",
		"ui_texture_path": "res://art/ui/seasons/clover_brown.png",
		"colour": Color(0.85, 0.58, 0.32),
		"blurb": "Leaves wither and the harvest turns dry. Cold winds stir under the Brown Clover.",
		"arrival": "Golden leaves fall: Autumn settles under the Brown Clover.",
	},
	{
		"id": "winter",
		"index": 3,
		"display_name": "Winter",
		"clover": "ice",
		"clover_name": "Ice Clover",
		"texture_path": "res://art/props/nature/clover_ice.png",
		"ui_texture_path": "res://art/ui/seasons/clover_ice.png",
		"colour": Color(0.55, 0.85, 1.0),
		"blurb": "Frost locks the waters and bitter chills freeze the roads. Travel is severe under the Ice Clover.",
		"arrival": "The freeze takes the land: Winter strikes under the Ice Clover.",
	},
]

static var _cached_textures: Dictionary = {}


## The season at any step count on the world clock.
static func for_step(step: int) -> Dictionary:
	var idx := maxi(0, step / STEPS_PER_SEASON) % SEASONS_PER_YEAR
	return SEASONS[idx]


## The active season for the current world state.
static func current(world: World) -> Dictionary:
	if world == null:
		return SEASONS[0]
	return for_step(world.steps)


## Which season index (0: Spring, 1: Summer, 2: Autumn, 3: Winter).
static func index(world: World) -> int:
	if world == null:
		return 0
	return maxi(0, world.steps / STEPS_PER_SEASON) % SEASONS_PER_YEAR


## Continental year (starts at 1).
static func year(world: World) -> int:
	if world == null:
		return 1
	return (maxi(0, world.steps) / STEPS_PER_YEAR) + 1


## Steps walked into the current season (0 to 899).
static func step_in_season(world: World) -> int:
	if world == null:
		return 0
	return maxi(0, world.steps) % STEPS_PER_SEASON


## Steps remaining before the season turns.
static func steps_remaining(world: World) -> int:
	if world == null:
		return STEPS_PER_SEASON
	return STEPS_PER_SEASON - step_in_season(world)


## Short label: "Year 1, Spring".
static func label(world: World) -> String:
	var s := current(world)
	return "Year %d, %s" % [year(world), s["display_name"]]


## Full status label: "Year 1, Spring · Lesser Green Clover".
static func full_label(world: World) -> String:
	var s := current(world)
	return "Year %d, %s · %s" % [year(world), s["display_name"], s["clover_name"]]


## Cached Texture2D for the active season's clover.
static func clover_texture(world: World) -> Texture2D:
	var s := current(world)
	var path: String = s.get("ui_texture_path", "")
	if not _cached_textures.has(path):
		_cached_textures[path] = load(path)
	return _cached_textures.get(path)


## Texture2D for a specific clover key: "green", "lesser_green", "brown", "ice".
static func texture_by_key(clover_key: String) -> Texture2D:
	for s: Dictionary in SEASONS:
		if s["clover"] == clover_key:
			var path: String = s["ui_texture_path"]
			if not _cached_textures.has(path):
				_cached_textures[path] = load(path)
			return _cached_textures.get(path)
	return null


## Checks if the world clock just completed a season transition at [param step].
static func just_turned(step: int) -> bool:
	return step > 0 and (step % STEPS_PER_SEASON == 0)
