extends RefCounted
## A conversation with somebody standing in an area, built from the `talk` block on their entry
## in `data/areas/*.json` instead of a file of its own: what they say when you walk up, the
## questions you can ask, what they will sell you, mending the company for a price, a favour they
## want done, and whether they want to talk to you at all.
##
## The result is an ordinary branching dialogue ([DialogueScript]), registered under an id of
## its own, so the box, the portraits, the checks and the `once` replies all work the same way.
## See `docs/04-data-formats.md` → `talk`. Loaded by path ([D41]).

const Remembered := preload("res://src/chronicle/remembered.gd")
const Coins := preload("res://src/chronicle/coins.gd")

const END := "end"
## What the party says to leave, when the block gives nothing of its own.
const GOODBYE := "Goodbye."
const MORE := ["Anything else?", "What else?", "Go on."]


## The id the conversation is registered under. Stable, so a `once` reply stays said.
static func dialogue_id(area_id: String, person: Dictionary) -> String:
	return "talk:%s:%s" % [area_id, str(person.get("name", person.get("unit", "someone")))]


## Whether this is the first time the party has spoken to them.
static func met_flag(area_id: String, person: Dictionary) -> String:
	return "met:" + dialogue_id(area_id, person)


## Build the conversation and register it. Returns its id. [param refused] decides, once per
## conversation, whether they are in a mood to talk; pass a roll so a test can pin it.
static func open(area_id: String, person: Dictionary, roll: float = -1.0) -> String:
	var id := dialogue_id(area_id, person)
	var talk: Dictionary = person.get("talk", {})
	var name_ := str(person.get("name", "Someone"))
	# The world remembers (D249): where the company is disliked, they would sooner not talk to it,
	# and what they have heard of it they say first.
	if not talk.has("refuse") and GameState.world != null \
			and Remembered.is_cold(GameState.world, GameState.world.player_cell):
		talk = talk.duplicate()
		talk["refuse"] = Remembered.cold_refusal()
	var nodes := build(name_, talk, GameState.has_flag(met_flag(area_id, person)),
		roll if roll >= 0.0 else randf(), met_flag(area_id, person), Remembered.recall(GameState.world, id))
	Database.register_dialogue(id, {
		"cast": { name_: str(person.get("unit", "")) },
		"start": "recall" if nodes.has("recall") else "door" if nodes.has("door") else "hello",
		"nodes": nodes,
	})
	return id


## The nodes themselves. Kept free of the area so it can be checked without one. [param recall] is
## what they bring up before anything else, if anything ([D249]).
static func build(name_: String, talk: Dictionary, met: bool, roll: float, met_key: String,
		recall: String = "") -> Dictionary:
	var nodes := {}
	var menu: Array = []

	var hello: Variant = talk.get("again", talk.get("hello", "...")) if met else talk.get("hello", "...")
	nodes["hello"] = { "speaker": name_, "text": hello, "set_flag": met_key, "next": "menu" }

	var asks: Array = talk.get("ask", [])
	for index in asks.size():
		var ask: Dictionary = asks[index]
		var answer_id := "ask%d" % index
		var option := _gated(ask, { "text": str(ask.get("q", "...")), "goto": answer_id })
		# Anything that pays out is said once, or the question becomes a purse.
		if ask.has("reward") or ask.has("item"):
			option["once"] = true
		if ask.has("check"):
			var check: Dictionary = (ask["check"] as Dictionary).duplicate()
			check["success"] = answer_id
			check["failure"] = answer_id + "_no"
			option.erase("goto")
			option["check"] = check
			nodes[answer_id + "_no"] = {
				"speaker": name_, "text": ask.get("no", "That's my business."), "next": "menu",
			}
		menu.append(option)
		var answer := { "speaker": name_, "text": ask.get("a", "..."), "next": "menu" }
		for key: String in ["set_flag", "clear_flag", "item"]:
			if ask.has(key):
				answer[key] = ask[key]
		if ask.has("reward"):
			answer["gold"] = int(ask["reward"])
		nodes[answer_id] = answer

	var sells: Array = talk.get("sells", [])
	if not sells.is_empty():
		menu.append({ "text": str(talk.get("shop_q", "What are you selling?")), "goto": "shop" })
		_add_shop(nodes, name_, talk, sells)

	var heal: Dictionary = talk.get("heal", {})
	if not heal.is_empty():
		_add_healing(nodes, menu, name_, heal)

	if bool(talk.get("news", false)):
		menu.append({ "text": str(talk.get("news_q", "Heard any news?")), "news": true })

	var job: Dictionary = talk.get("job", {})
	if not job.is_empty():
		_add_job(nodes, menu, name_, job)

	menu.append({ "text": str(talk.get("leave", GOODBYE)), "goto": "bye" })
	nodes["menu"] = { "speaker": name_, "text": talk.get("more", MORE), "options": menu }
	nodes["bye"] = { "speaker": name_, "text": talk.get("bye", "Mm."), "next": END }

	var refuse: Dictionary = talk.get("refuse", {})
	if not refuse.is_empty() and _refuses(refuse, roll):
		_add_refusal(nodes, name_, refuse)
	if recall != "":
		nodes["recall"] = { "speaker": name_, "text": recall, "next": "door" if nodes.has("door") else "hello" }
	return nodes


## Whether they turn you away this time: never once their `unless` flag is set, otherwise
## on their `chance` (1.0, the default, is every time).
static func _refuses(refuse: Dictionary, roll: float) -> bool:
	for key: String in DialogueScript._as_array(refuse.get("unless", [])):
		if GameState.has_flag(key):
			return false
	return roll < float(refuse.get("chance", 1.0))


## The cold shoulder, and the ways round it: a coin, a roll, or leaving them be.
static func _add_refusal(nodes: Dictionary, name_: String, refuse: Dictionary) -> void:
	var options: Array = []
	var bribe := int(refuse.get("bribe", 0))
	if bribe > 0:
		options.append({
			"text": str(refuse.get("bribe_q", "Would %s change your mind?" % Coins.text(bribe))),
			"requires_gold": bribe, "gold": -bribe, "goto": "won_over",
		})
	if refuse.has("check"):
		var check: Dictionary = (refuse["check"] as Dictionary).duplicate()
		check["success"] = "won_over"
		check["failure"] = "turned_away"
		options.append({ "text": str(refuse.get("check_q", "Hear me out.")), "check": check })
	options.append({ "text": str(refuse.get("leave", "Fair enough.")), "goto": END })
	nodes["door"] = { "speaker": name_, "text": refuse.get("text", "Not now."), "options": options }
	nodes["won_over"] = {
		"speaker": name_, "text": refuse.get("won", "...Fine. Quickly, then."),
		"set_flag": refuse.get("won_flag", []), "next": "menu",
	}
	nodes["turned_away"] = { "speaker": name_, "text": refuse.get("still_no", "No."), "next": END }


## One reply per thing for sale, priced the way the market prices it unless the block says.
static func _add_shop(nodes: Dictionary, name_: String, talk: Dictionary, sells: Array) -> void:
	var options: Array = []
	for index in sells.size():
		var ware: Dictionary = sells[index]
		var item := str(ware.get("item", ""))
		if Database.equipment_piece(item).is_empty():
			push_warning("Talk: %s sells '%s', which is not in equipment.json" % [name_, item])
			continue
		var price := price_of(ware)
		var bought_id := "bought%d" % index
		options.append(_gated(ware, {
			"text": "%s — %s" % [Gear.display_name(item), Coins.text(price)],
			"requires_gold": price, "gold": -price, "goto": bought_id,
			"once": not bool(ware.get("restock", false)),
		}))
		nodes[bought_id] = {
			"speaker": name_, "text": ware.get("line", talk.get("sold", "Pleasure doing business.")),
			"item": item, "set_flag": ware.get("set_flag", []), "next": "shop",
		}
	options.append({ "text": str(talk.get("shop_done", "That's all.")), "goto": "menu" })
	nodes["shop"] = {
		"speaker": name_, "text": talk.get("shop", "Have a look. Coin first, mind."), "options": options,
	}


## Mending the whole company for a price ([D176]): offered while anyone in it is hurt and the purse
## can pay; with nobody hurt, a look-over that costs nothing.
static func _add_healing(nodes: Dictionary, menu: Array, name_: String, heal: Dictionary) -> void:
	var price := maxi(1, roundi(float(heal.get("price", 1000)) * Difficulty.dial("price")))
	menu.append({
		"text": "%s — %s" % [str(heal.get("q", "Patch up my companions.")), Coins.text(price)],
		"requires_wounded": true, "requires_gold": price, "gold": -price, "heal": true, "goto": "healed",
	})
	menu.append({
		"text": str(heal.get("whole_q", "Can you look us over?")),
		"requires_wounded": false, "goto": "whole",
	})
	nodes["healed"] = { "speaker": name_, "text": heal.get("done", "There. Whole again."), "next": "menu" }
	nodes["whole"] = { "speaker": name_, "text": heal.get("whole", "Nobody here needs me."), "next": "menu" }


static func price_of(ware: Dictionary) -> int:
	if ware.has("price"):
		return maxi(1, roundi(float(ware["price"]) * Difficulty.dial("price")))
	return maxi(1, roundi(float(Market.price_of(str(ware.get("item", "")))) * Difficulty.dial("price")))


## A favour: asked for, taken on (its `flag`), and paid for once its `done_flag` is set by
## whatever the party finds or does elsewhere (a prop's or a spot's `set_flag`).
static func _add_job(nodes: Dictionary, menu: Array, name_: String, job: Dictionary) -> void:
	var taken := str(job.get("flag", ""))
	var done := str(job.get("done_flag", ""))
	var paid := taken + ":paid"
	if taken == "" or done == "":
		push_warning("Talk: %s has a job with no flag or done_flag" % name_)
		return
	menu.append({
		"text": str(job.get("ask", "Need a hand with anything?")),
		"requires_not": [taken], "goto": "job_offer",
	})
	menu.append({
		"text": str(job.get("report", "About that favour...")),
		"requires": [taken], "requires_not": [paid], "goto": "job_check",
	})
	nodes["job_offer"] = {
		"speaker": name_, "text": job.get("offer", "Maybe."),
		"options": [
			{ "text": str(job.get("accept", "I'll do it.")), "set_flag": taken, "goto": "job_taken" },
			{ "text": str(job.get("decline", "Not today.")), "goto": "menu" },
		],
	}
	nodes["job_taken"] = { "speaker": name_, "text": job.get("thanks", "Good."), "next": "menu" }
	nodes["job_check"] = {
		"speaker": name_, "text": job.get("waiting", "Well? Have you done it?"),
		"options": [
			{ "text": str(job.get("hand_over", "It's done.")), "requires": [done], "goto": "job_paid" },
			{ "text": str(job.get("not_yet", "Not yet.")), "requires_not": [done], "goto": "menu" },
		],
	}
	var payout := { "speaker": name_, "text": job.get("done", "Thank you."), "set_flag": paid, "next": "menu" }
	if job.has("gold"):
		payout["gold"] = int(job["gold"])
	if job.has("item"):
		payout["item"] = job["item"]
	nodes["job_paid"] = payout


## An option carries the same flag gates as the thing it came from.
static func _gated(source: Dictionary, option: Dictionary) -> Dictionary:
	for key: String in ["requires", "requires_not", "once"]:
		if source.has(key):
			option[key] = source[key]
	if source.has("cost"):
		option["requires_gold"] = int(source["cost"])
		option["gold"] = -int(source["cost"])
	return option
