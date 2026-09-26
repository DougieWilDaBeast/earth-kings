#!/usr/bin/env python3
"""Draft a first pass of which Question Book ids a voice note speaks to.

    python3 tools/map_voice_note.py docs/worldbuilding/voice-notes/2026-09-24-joint-session-1.md
    python3 tools/map_voice_note.py <note> --out draft.md      # write the draft to a file
    python3 tools/map_voice_note.py <note> --dry-run           # what would be sent, nothing sent

Sends the transcript and the list of question ids to a model through the
`dougie`'s LLM gateway (see voice-notes/README.md, "A first pass by model"), then
checks every suggestion it gets back before showing it:

* the id must exist in docs/15-the-question-book.md;
* the quote must appear **word for word** in the transcript, on one speaker's
  line or a run of them. A quote the model tidied, merged or made up is
  rejected and listed as rejected, never shown as a candidate. The answer
  ledger's rule is that a quote is never edited;
* the speaker and timestamp come from the transcript line the quote was found
  on, not from the model, and a quote from a line marked [unclear] says so.

The result is a **draft for whoever runs the ingest**, never canon: the model
is a reader that points at passages, and every status in answers.md is still
written by a person reading the note whole (voice-notes/README.md, "What
happens next"). Nothing is written into docs/ unless --out says so.

Needs only the standard library, and a gateway: LLM_GATEWAY_URL (default
http://localhost:4000) and LLM_GATEWAY_KEY, from the environment or a .env at
the repo root. The default lane is `private` — the founders' own words about an
unreleased game go only to a zero-retention provider unless --lane says otherwise.
"""
import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BOOK = os.path.join(REPO, "docs", "15-the-question-book.md")
LEDGER = os.path.join(REPO, "docs", "worldbuilding", "answers.md")

QUESTION_ROW = re.compile(r"^\| ([A-Z]{2,3}\d+) \| (.+?) \| ([^|]*)\|\s*$")
LEDGER_HEADING = re.compile(r"^## ([A-Z]{2,3}\d+) — ")
LEDGER_STATUS = re.compile(r"^\*\*([A-Za-z ]+?)[.:]?\*\*")
# "[00:30] text", "[00:00:04] **ED:** text", "[01:06] [unclear] text"
LINE = re.compile(r"^\[(\d\d:\d\d(?::\d\d)?)\]\s+(?:\*\*(.+?):\*\*\s*)?(\[unclear\]\s*)?(.*)$")
KINDS = ("direct", "partial", "inferred", "contradicts")

SYSTEM = """You read transcripts of game designers answering worldbuilding questions
aloud, and point at the passages that answer questions from their question book.

Rules:
- Only point at what is actually said. If nothing in the transcript speaks to a
  question, leave that question out. Most questions will not be answered.
- "quote" must be copied character for character from ONE line of the
  transcript: same words, same order, same filler, same mistakes. Never tidy,
  shorten with "...", merge lines, or paraphrase. A short exact quote beats a
  long approximate one. Leave out the [timestamp] and the speaker label.
- "kind": "direct" if the words answer the question outright; "partial" if they
  settle part of it; "inferred" if the answer only follows from what is said;
  "contradicts" if they go against the question's current status or an answer
  given elsewhere in the same transcript.
- "care": the speaker's stake if they state it or make it plain — "H" a real
  stake, "M" a preference, "L" a shrug, "—" they hand it over, "!" a veto.
  Empty string if they do not say.
- "why": one short plain sentence, no more.

Reply with JSON only, in this shape:
{"mappings": [{"id": "LN1", "quote": "...", "kind": "direct", "care": "", "why": "..."}]}"""


# --- reading the repo -------------------------------------------------------


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def questions_in(book_text):
    """Question id -> question text, in book order."""
    out = {}
    for line in book_text.splitlines():
        m = QUESTION_ROW.match(line)
        if m:
            out[m.group(1)] = m.group(2).strip()
    return out


def statuses_in(ledger_text):
    """Question id -> the status lead of its first entry in answers.md."""
    out, current, fenced = {}, "", False
    for line in ledger_text.splitlines():
        if line.startswith("```"):
            fenced = not fenced
            continue
        if fenced:
            continue
        h = LEDGER_HEADING.match(line)
        if h:
            current = h.group(1)
            continue
        s = LEDGER_STATUS.match(line)
        if s and current:
            out.setdefault(current, s.group(1).strip())
            current = ""
    return out


def front_matter(text):
    """(fields, speakers, body) of a voice note. Speakers maps a transcript label to an id."""
    fields, speakers, body = {}, {}, text
    if text.startswith("---\n"):
        end = text.find("\n---\n", 4)
        if end != -1:
            block, body = text[4:end], text[end + 5:]
            in_speakers = False
            for raw in block.splitlines():
                if raw.startswith("speakers:"):
                    in_speakers = True
                    continue
                if in_speakers and raw.startswith(" "):
                    label, _, who = raw.strip().rpartition(":")
                    speakers[label.strip().strip('"')] = who.strip()
                    continue
                in_speakers = False
                key, _, value = raw.partition(":")
                fields[key.strip()] = value.strip()
    return fields, speakers, body


def lines_of(body):
    """Every timestamped transcript line: {at, speaker, unclear, text}."""
    out = []
    for raw in body.splitlines():
        m = LINE.match(raw.strip())
        if m:
            out.append({
                "at": m.group(1),
                "speaker": m.group(2) or "",
                "unclear": bool(m.group(3)),
                "text": m.group(4),
            })
    return out


# --- checking what comes back -----------------------------------------------


def norm(s):
    """Compare text the way a reader would: same words, whatever the quotes and spacing."""
    s = s.replace("\u2019", "'").replace("\u2018", "'").replace("\u201c", '"').replace("\u201d", '"')
    s = s.replace("\u2014", "-").replace("\u2013", "-").replace("\u2026", "...")
    return re.sub(r"\s+", " ", s).strip().casefold()


def locate(quote, lines):
    """The first transcript line (or run of one speaker's lines) holding the quote verbatim."""
    q = norm(quote.strip().strip('"').strip())
    if len(q) < 8:
        return None
    texts = [norm(l["text"]) for l in lines]
    for i, line in enumerate(lines):
        joined, unclear = "", False
        for j in range(i, len(lines)):
            if j > i and lines[j]["speaker"] != line["speaker"]:
                break
            joined = (joined + " " + texts[j]).strip()
            unclear = unclear or lines[j]["unclear"]
            if q in joined:
                # Only claim the run if the quote really starts on line i;
                # otherwise a later start holds it more tightly.
                if j > i and q in " ".join(texts[i + 1:j + 1]):
                    break
                return {"at": line["at"], "speaker": line["speaker"], "unclear": unclear}
            if len(joined) > len(q) + 2000:
                break
    return None


def parse_reply(content):
    """The model's JSON, forgiving code fences and chatter around it."""
    content = content.strip()
    fence = re.search(r"```(?:json)?\s*(.*?)```", content, re.S)
    if fence:
        content = fence.group(1).strip()
    start, end = content.find("{"), content.rfind("}")
    if start == -1 or end == -1:
        raise ValueError("no JSON object in the model's reply")
    data = json.loads(content[start:end + 1])
    items = data.get("mappings") if isinstance(data, dict) else None
    if not isinstance(items, list):
        raise ValueError("the reply has no 'mappings' list")
    return [i for i in items if isinstance(i, dict)]


def check(items, questions, lines):
    """Split the model's suggestions into (kept, rejected), each with a reason."""
    kept, rejected, seen = [], [], set()
    for item in items:
        qid = str(item.get("id", "")).strip().upper()
        quote = str(item.get("quote", "")).strip()
        if qid not in questions:
            rejected.append((item, "no question %s in the book" % (qid or "(blank)")))
            continue
        where = locate(quote, lines)
        if where is None:
            rejected.append((item, "quote is not word for word in the transcript"))
            continue
        key = (qid, norm(quote))
        if key in seen:
            continue
        seen.add(key)
        kind = str(item.get("kind", "")).strip().lower()
        kept.append({
            "id": qid,
            "quote": quote.strip('"').strip(),
            "kind": kind if kind in KINDS else "inferred",
            "care": str(item.get("care", "")).strip(),
            "why": str(item.get("why", "")).strip(),
            **where,
        })
    return kept, rejected


# --- the gateway ------------------------------------------------------------


def load_env():
    path = os.path.join(REPO, ".env")
    if not os.path.isfile(path):
        return
    for raw in read(path).splitlines():
        key, sep, value = raw.strip().partition("=")
        if sep and not key.startswith("#") and key.strip() not in os.environ:
            os.environ[key.strip()] = value.strip().strip('"').strip("'")


def ask(messages, lane, max_tokens, timeout):
    url = os.environ.get("LLM_GATEWAY_URL", "http://localhost:4000").rstrip("/")
    key = os.environ.get("LLM_GATEWAY_KEY", "")
    if not key:
        sys.exit("LLM_GATEWAY_KEY is not set (environment or .env at the repo root).")
    body = json.dumps({
        "model": lane,
        "messages": messages,
        "max_tokens": max_tokens,
        "temperature": 0,
        "response_format": {"type": "json_object"},
    }).encode("utf-8")
    req = urllib.request.Request(
        url + "/v1/chat/completions", data=body, method="POST",
        headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        sys.exit("gateway said %s: %s" % (e.code, e.read().decode("utf-8", "replace")[:600]))
    except (urllib.error.URLError, TimeoutError) as e:
        sys.exit("gateway unreachable at %s: %s — is it running?" % (url, e))
    content = ((data.get("choices") or [{}])[0].get("message") or {}).get("content") or ""
    return content, data.get("model", "?")


# --- writing the draft ------------------------------------------------------


def report(note_path, fields, speakers, kept, rejected, questions, statuses, model, lane):
    name = os.path.relpath(note_path, REPO).replace(os.sep, "/")
    who_default = fields.get("respondent", "?")
    out = [
        "# Draft mapping — `%s`" % os.path.basename(note_path),
        "",
        "> **Machine draft, not canon.** Read by `%s` on the `%s` lane, %s. Every quote below was"
        % (model, lane, time.strftime("%Y-%m-%d")),
        "> checked word for word against the transcript; the speaker and time come from the line it",
        "> was found on. What each one settles is still decided by reading the note whole — see",
        "> `docs/worldbuilding/voice-notes/README.md`, _What happens next_.",
        "",
        "Source: `%s` · %d candidate%s across %d question%s · %d rejected"
        % (name, len(kept), "" if len(kept) == 1 else "s",
           len({k["id"] for k in kept}), "" if len({k["id"] for k in kept}) == 1 else "s",
           len(rejected)),
        "",
    ]
    order = {qid: i for i, qid in enumerate(questions)}
    for qid in sorted({k["id"] for k in kept}, key=lambda q: order[q]):
        status = statuses.get(qid, "open")
        out += ["## %s — %s" % (qid, questions[qid]), "", "_Ledger now: %s_" % status, ""]
        for k in [k for k in kept if k["id"] == qid]:
            who = speakers.get(k["speaker"], k["speaker"]) if k["speaker"] else who_default
            out += [
                '> "%s"' % k["quote"],
                "> — %s, %s, [%s]%s" % (who, fields.get("recorded", "?"), k["at"],
                                        " · **[unclear] — check the audio**" if k["unclear"] else ""),
                "",
                "**Draft: %s.**%s %s" % (k["kind"], " Care `%s`." % k["care"] if k["care"] else "", k["why"]),
                "",
            ]
    if rejected:
        out += ["## Rejected by the check", "",
                "The model offered these, and they failed. Kept so a real passage it misquoted can still be found.", ""]
        for item, why in rejected:
            out.append('- `%s` — %s: "%s"' % (item.get("id", "?"), why, str(item.get("quote", ""))[:160]))
        out.append("")
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("note", help="a transcript in docs/worldbuilding/voice-notes/")
    ap.add_argument("--lane", default="private", help="gateway lane (default: private)")
    ap.add_argument("--out", help="write the draft here instead of printing it")
    ap.add_argument("--max-tokens", type=int, default=8000)
    ap.add_argument("--timeout", type=float, default=600)
    ap.add_argument("--dry-run", action="store_true", help="show what would be sent and stop")
    ap.add_argument("--reply", help="check a saved model reply (JSON) instead of asking the gateway")
    ap.add_argument("--save-reply", help="also save the model's raw reply here")
    args = ap.parse_args()

    load_env()
    questions = questions_in(read(BOOK))
    statuses = statuses_in(read(LEDGER))
    fields, speakers, body = front_matter(read(args.note))
    lines = lines_of(body)
    if not lines:
        sys.exit("no timestamped lines in %s — is it a voice-note transcript?" % args.note)

    listing = "\n".join("%s [%s] %s" % (q, statuses.get(q, "open"), t) for q, t in questions.items())
    transcript = "\n".join(
        "[%s] %s%s" % (l["at"], (l["speaker"] + ": ") if l["speaker"] else "", l["text"]) for l in lines)
    user = "QUESTIONS (id [current status] question):\n%s\n\nTRANSCRIPT:\n%s" % (listing, transcript)
    messages = [{"role": "system", "content": SYSTEM}, {"role": "user", "content": user}]

    if args.dry_run:
        print("would send %d questions and %d transcript lines (%d chars, ~%d tokens) to lane '%s'"
              % (len(questions), len(lines), len(SYSTEM) + len(user), (len(SYSTEM) + len(user)) // 4, args.lane))
        return 0

    if args.reply:
        content, model = read(args.reply), "saved reply"
    else:
        content, model = ask(messages, args.lane, args.max_tokens, args.timeout)
    if args.save_reply:
        with open(args.save_reply, "w", encoding="utf-8") as f:
            f.write(content)
    try:
        items = parse_reply(content)
    except (ValueError, json.JSONDecodeError) as e:
        sys.exit("could not read the model's reply (%s). Start of it:\n%s" % (e, content[:600]))

    kept, rejected = check(items, questions, lines)
    text = report(args.note, fields, speakers, kept, rejected, questions, statuses, model, args.lane)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(text)
        print("%d candidates, %d rejected -> %s" % (len(kept), len(rejected), args.out))
    else:
        print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
