extends RefCounted
## How many can march together — D38's party growing from four to six.
##
## The company starts with four seats and earns the fifth and sixth by climbing
## the Tower: clearing a chapter's last floor opens the next seat. That reading
## is **Inferred** (agenda item 35, answering item 11) — the founders asked for
## four growing to six and left the how open — so every number is in
## `data/world_rules.json` → `party`, and so is everything said when a seat opens.
##
## The seat count lives on the [Roster] (`roster.seats`) so anything holding a
## roster can ask it without the world; [method sync] is what moves it on.
##
## Loaded by path, not by `class_name` ([D41]).


static func rules() -> Dictionary:
	return Database.world_rules.get("party", {})


## Seats a new company starts with.
static func base() -> int:
	return maxi(1, int(rules().get("seats_base", 4)))


## The most a company can ever field, whatever it has climbed. Battlefields are
## laid out for this many.
static func most() -> int:
	return maxi(base(), int(rules().get("seats_most", 6)))


## Seats earned by having won Tower floor [param floor].
static func for_floor(floor: int) -> int:
	var seats := base()
	for step: Dictionary in rules().get("seats_by_tower_floor", []):
		if floor >= int(step.get("floor", 0)):
			seats = maxi(seats, int(step.get("seats", seats)))
	return mini(seats, most())


## The floor whose win opens the next seat, or -1 when every seat is open.
static func next_floor(seats: int) -> int:
	var best := -1
	for step: Dictionary in rules().get("seats_by_tower_floor", []):
		if int(step.get("seats", 0)) > seats:
			var at := int(step.get("floor", 0))
			if best < 0 or at < best:
				best = at
	return best


## Bring [param roster]'s seats up to what the Tower says the company has
## earned. Returns how many seats opened just now (0 if none). Seats are never
## taken away: a save from before this rule keeps every member it has.
static func sync(world: World, roster: Roster) -> int:
	if world == null or roster == null:
		return 0
	var earned := maxi(for_floor(world.tower_floor), roster.party.size())
	var opened := maxi(0, earned - roster.seats)
	roster.seats = maxi(roster.seats, earned)
	return opened


## What to say when a seat opens: the lines of the moment, from data, with the
## company's own names put in.
static func opened_lines(roster: Roster, floor: int) -> Array[String]:
	var lines: Array[String] = []
	var lead := roster.player()
	var fill := {
		"lead": lead.display_name if lead != null else "The company",
		"seats": str(roster.seats),
		"seats_word": _word(roster.seats),
		"floor": str(floor),
		"filled": str(roster.party.size()),
	}
	for line: String in rules().get("opened", []):
		lines.append(line.format(fill))
	var next := next_floor(roster.seats)
	var tail: String = rules().get("next_seat", "") if next > 0 else rules().get("all_seats", "")
	if tail != "":
		lines.append(tail.format(fill.merged({ "next_floor": str(next) })))
	return lines


## One line for the party screen and the hire prompt: how full the company is
## and how the next seat is earned.
static func status_line(roster: Roster) -> String:
	var filled := roster.party.size()
	var line := "%d of %d seats filled" % [filled, roster.seats]
	if filled < roster.seats:
		line += " — hire in a village or keep"
	var next := next_floor(roster.seats)
	if next > 0:
		line += "  ·  floor %d of the Tower opens another" % next
	return line


## Said when somebody would join and every seat is taken.
static func full_line(roster: Roster) -> String:
	var next := next_floor(roster.seats)
	if next > 0:
		return str(rules().get("full", "Every seat is taken.")).format({
			"seats": str(roster.seats), "next_floor": str(next)
		})
	return str(rules().get("full_at_most", "Every seat is taken.")).format({ "seats": str(roster.seats) })


static func _word(n: int) -> String:
	const WORDS := ["no", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
	return WORDS[n] if n >= 0 and n < WORDS.size() else str(n)
