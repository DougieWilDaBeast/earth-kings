extends Node
## Where the Question Book stands, and whether it still agrees with the answer ledger.
##
##   godot --headless --path . res://tools/question_report.tscn
##
## Prints coverage per part, everything still waiting on a yes, everything that
## trailed off, and — the part that matters — any drift between the two files.
## Drift is an error: the book and the ledger must not disagree about which
## questions exist, or an answer can quietly attach to nothing.

const BOOK := "res://docs/15-the-question-book.md"
const LEDGER := "res://docs/worldbuilding/answers.md"
const NOTES_DIR := "res://docs/worldbuilding/voice-notes"
## Where recordings land before anyone has written them down (see docs/09).
const DROP_ZONE := "res://DROP-ZONE"
const AUDIO := ["m4a", "mp3", "wav", "ogg", "aac"]

## Status leads the ledger may use, in the order they are reported.
const STATUSES := [
	"Answered", "Partly answered", "Inferred", "Contested", "Blocked", "Noted", "Proposed",
]

## A source is not a person. It can draft an answer; it cannot settle one.
const SOURCE_PREFIX := "src-"

var _errors: Array[String] = []
## Question id -> whether a lineage source spoke to it.
var _sourced: Dictionary = {}
## Question id -> how many separate proposals it carries.
var _proposals: Dictionary = {}


func _ready() -> void:
	var book := _read(BOOK)
	if book == "":
		_fail("the question book is missing at %s" % BOOK)
		_finish()
		return

	var questions := _questions_in(book)        # id -> part heading
	var links := _links_in(book)                # id -> Array[id]
	var answers := _answers_in(_read(LEDGER))   # id -> status

	_report_coverage(questions, answers)
	_report_waiting(answers)
	_check_drift(questions, links, answers)
	_report_notes()
	_finish()


# --- reading the two files ----------------------------------------------------


func _read(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


## Every question id in the book, mapped to the part it sits in. Ids in the
## "Bears on" column are not questions, so only the first cell counts.
func _questions_in(text: String) -> Dictionary:
	var found: Dictionary = {}
	var part := "(no part)"
	var row := RegEx.create_from_string("^\\|\\s*([A-Z]{2}\\d{1,2})\\s*\\|")
	var fenced := false
	for line in text.split("\n"):
		if line.begins_with("```"):
			fenced = not fenced
			continue
		if fenced:
			continue
		if line.begins_with("## "):
			part = line.substr(3).strip_edges()
			continue
		var m := row.search(line)
		if m == null:
			continue
		var id := m.get_string(1)
		if found.has(id):
			_fail("question %s is listed twice in the book" % id)
			continue
		found[id] = part
	return found


## The "Bears on" column: id -> the ids it bears on.
func _links_in(text: String) -> Dictionary:
	var out: Dictionary = {}
	var row := RegEx.create_from_string(
		"^\\|\\s*([A-Z]{2}\\d{1,2})\\s*\\|.*\\|\\s*([A-Z0-9,\\s]*)\\s*\\|\\s*$"
	)
	var fenced := false
	for line in text.split("\n"):
		if line.begins_with("```"):
			fenced = not fenced
			continue
		if fenced:
			continue
		var m := row.search(line)
		if m == null:
			continue
		var targets: Array[String] = []
		for raw in m.get_string(2).split(",", false):
			var id := raw.strip_edges()
			if id != "":
				targets.append(id)
		if not targets.is_empty():
			out[m.get_string(1)] = targets
	return out


## Ledger entries: "## SK6 — …" followed by a "**Status.**" lead.
func _answers_in(text: String) -> Dictionary:
	var out: Dictionary = {}
	if text == "":
		return out
	var heading := RegEx.create_from_string("^##\\s+([A-Z]{2}\\d{1,2})\\s+—")
	# The period may sit inside or outside the bold — both get written by hand.
	var lead := RegEx.create_from_string("^\\*\\*([A-Za-z ]+?)[.:]?\\*\\*")
	var current := ""
	# The heading this line sits under, which — unlike `current` — survives the
	# status line, so a second proposal in the same entry still has an owner.
	var entry := ""
	# The ledger documents its own format in a fenced example. A worked example
	# is not an answer, so fenced regions are skipped everywhere.
	var fenced := false
	for line in text.split("\n"):
		if line.begins_with("```"):
			fenced = not fenced
			continue
		if fenced:
			continue
		if line.begins_with("**Proposed") and entry != "":
			_proposals[entry] = int(_proposals.get(entry, 0)) + 1
		var h := heading.search(line)
		if h != null:
			# An entry that never declared a status is the dangerous case: an
			# unconfirmed inference would vanish from the report and read as
			# settled. Say so rather than dropping it.
			if current != "":
				_fail("%s has no status line, so it counts as nothing" % current)
			current = h.get_string(1)
			entry = current
			continue
		if line.contains("`" + SOURCE_PREFIX) and entry != "":
			_sourced[entry] = true
		if current == "":
			continue
		var l := lead.search(line)
		if l != null:
			var status := l.get_string(1).strip_edges()
			if status not in STATUSES:
				_fail("%s carries unknown status '%s'" % [current, status])
			# The one rule this file exists to protect: a lineage source drafts,
			# it never decides. Canon has to come from somebody who can be asked.
			if status == "Answered" and _sourced.get(current, false):
				_fail("%s is answered by a source; only a founder can settle a question" % current)
			out[current] = status
			current = ""
	if current != "":
		_fail("%s has no status line, so it counts as nothing" % current)
	return out


# --- what it prints -----------------------------------------------------------


func _report_coverage(questions: Dictionary, answers: Dictionary) -> void:
	var parts: Array[String] = []
	var per_part: Dictionary = {}
	for id: String in questions:
		var part: String = questions[id]
		if not per_part.has(part):
			per_part[part] = {"total": 0}
			parts.append(part)
		per_part[part]["total"] += 1
		var status: String = answers.get(id, "")
		if status != "":
			per_part[part][status] = int(per_part[part].get(status, 0)) + 1

	print("")
	print("THE QUESTION BOOK")
	print("")
	for part: String in parts:
		var row: Dictionary = per_part[part]
		var total: int = row["total"]
		var settled: int = int(row.get("Answered", 0))
		var moved := 0
		for status: String in STATUSES:
			moved += int(row.get(status, 0))
		var bits: Array[String] = []
		for status: String in STATUSES:
			var n: int = int(row.get(status, 0))
			if n > 0:
				bits.append("%d %s" % [n, status.to_lower()])
		print("  %-46s %3d/%-3d answered%s" % [
			part.substr(0, 46), settled, total,
			"   (" + ", ".join(bits) + ")" if not bits.is_empty() else "",
		])
		if moved > total:
			_fail("%s has more answers than questions" % part)

	var answered := 0
	for id: String in answers:
		if answers[id] == "Answered":
			answered += 1
	print("")
	print("  %d questions, %d answered, %d still open" % [
		questions.size(), answered, questions.size() - answers.size(),
	])


func _report_waiting(answers: Dictionary) -> void:
	var inferred: Array[String] = []
	var blocked: Array[String] = []
	var contested: Array[String] = []
	for id: String in answers:
		match answers[id]:
			"Inferred": inferred.append(id)
			"Blocked": blocked.append(id)
			"Contested": contested.append(id)
	inferred.sort()
	blocked.sort()
	contested.sort()
	print("")
	var proposed: Array[String] = []
	var argued: Array[String] = []
	for id: String in answers:
		if answers[id] != "Proposed":
			continue
		if int(_proposals.get(id, 1)) > 1:
			argued.append(id)
		else:
			proposed.append(id)
	proposed.sort()
	argued.sort()
	print("")
	print("  proposals to decide on   %d" % proposed.size())
	print("  proposals that disagree  %s" % (", ".join(argued) if not argued.is_empty() else "none"))
	print("")
	print("  waiting on a yes   %s" % (", ".join(inferred) if not inferred.is_empty() else "none"))
	print("  trailed off        %s" % (", ".join(blocked) if not blocked.is_empty() else "none"))
	print("  contested          %s" % (", ".join(contested) if not contested.is_empty() else "none"))


func _report_notes() -> void:
	var notes := 0
	var dir := DirAccess.open(NOTES_DIR)
	if dir != null:
		for file in dir.get_files():
			if file.ends_with(".md") and file != "README.md":
				notes += 1
	print("  transcripts        %d" % notes)

	# A recording nobody has written down yet is invisible work: it holds
	# answers that cannot reach the ledger. Say how much is waiting.
	var waiting: Array[String] = []
	var drop := DirAccess.open(DROP_ZONE)
	if drop != null:
		for file in drop.get_files():
			if file.get_extension().to_lower() in AUDIO:
				waiting.append(file)
	if waiting.is_empty():
		return
	waiting.sort()
	print("")
	print("  %d recording(s) in DROP-ZONE with no transcript yet:" % waiting.size())
	for file in waiting:
		print("    %s" % file)


# --- drift --------------------------------------------------------------------


func _check_drift(questions: Dictionary, links: Dictionary, answers: Dictionary) -> void:
	for id: String in answers:
		if not questions.has(id):
			_fail("the ledger answers %s, which is not a question in the book" % id)
	for id: String in links:
		for target: String in links[id]:
			if not questions.has(target):
				_fail("%s bears on %s, which does not exist" % [id, target])
			elif target == id:
				_fail("%s bears on itself" % id)


func _fail(message: String) -> void:
	_errors.append(message)


func _finish() -> void:
	print("")
	if _errors.is_empty():
		print("  no drift.")
		get_tree().quit(0)
		return
	for error in _errors:
		print("  DRIFT  %s" % error)
	print("")
	print("  %d problem(s)." % _errors.size())
	get_tree().quit(1)
