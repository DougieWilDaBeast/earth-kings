extends RefCounted
## A company of three for the checks that need more than the lead: the lead a
## run starts with (Roster.FIRST_LEAD, Atlas) and two more of the sixteen who
## have joined. A run starts with the lead alone, so a check that sends someone
## away, loses someone or fields a party asks for this instead.
##
## Loaded by path, not by `class_name` ([D41]).

## Who joins, in order, after the lead.
const JOINED := ["juno", "cato"]


## A fresh roster led by [param lead] with [param joined] marching behind.
static func found(lead: String = Roster.FIRST_LEAD, joined: Array = JOINED) -> Roster:
	return join(Roster.found(lead), joined)


## [param roster] with [param joined] added to it and to the marching order.
static func join(roster: Roster, joined: Array = JOINED) -> Roster:
	for id: String in joined:
		var character := roster.add(Character.create(id))
		roster.party.append(character.id)
	return roster
