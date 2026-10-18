extends RefCounted
## Coins in four metals ([D253], `doug-md`'s ask, [D89] and [D177]): copper, silver, gold and
## platinum, a hundred of each to the next. Every amount of money in the game, in data and in code,
## is counted in copper; this is how it is said ("1 gold 60 silver", "8 copper"). The prices are
## docs/26, written into data by `tools/economy/to_coins.py`. Loaded by path ([D41]).

const SILVER := 100
const GOLD := 10_000
const PLATINUM := 1_000_000
## What one gold of the old purse is worth in copper (docs/26: "about 25 copper for each old gold").
const OLD_GOLD := 25

const METALS := [["platinum", PLATINUM], ["gold", GOLD], ["silver", SILVER], ["copper", 1]]
const SHORT := { "platinum": "p", "gold": "g", "silver": "s", "copper": "c" }


## [param copper] said in coins, biggest first, leaving out a metal there is none of:
## "1 gold 60 silver", "75 silver", "8 copper", "no coin".
static func text(copper: int) -> String:
	return _said(copper, false)


## The same, short, for a tight space: "1g 60s", "75s", "8c".
static func short(copper: int) -> String:
	return _said(copper, true)


static func _said(copper: int, brief: bool) -> String:
	var left := absi(copper)
	if left == 0:
		return "0c" if brief else "no coin"
	var parts: Array[String] = []
	for metal: Array in METALS:
		var count := left / int(metal[1])
		left -= count * int(metal[1])
		if count > 0:
			parts.append("%d%s" % [count, SHORT[metal[0]]] if brief else "%d %s" % [count, metal[0]])
	return ("-" if copper < 0 else "") + " ".join(parts)
