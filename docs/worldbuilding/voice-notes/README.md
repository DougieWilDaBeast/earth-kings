# Voice notes

Transcribed voice notes, kept exactly as spoken. A transcript here gets read against every question
in [15 — The Question Book](../../15-the-question-book.md); what it settles lands in
[answers.md](../answers.md).

## The recording goes in DROP-ZONE first

Two places, because they hold two different things — the same flow
[09 — Wishlist](../../09-wishlist.md) already used for the first batch of memos:

| Where | What | Read by |
| --- | --- | --- |
| [`DROP-ZONE/`](../../../DROP-ZONE) | The recording, as recorded | Nobody. Audio cannot be read against questions |
| here | The transcript of it | The ingest loop |

Record, drop the audio in `DROP-ZONE/`, and transcribe it into a `.md` here. The report
(`res://tools/question_report.tscn`) lists every recording that has no transcript yet, so a memo
cannot sit there quietly holding eighty answers nobody has read.

Transcribe however suits — phone dictation, typing it out, or the script in this repo:

```
pip install faster-whisper
python3 tools/transcribe_voice_notes.py --respondent doug-md --recorded 2026-09-13
```

It reads everything in `DROP-ZONE/`, writes one transcript per recording straight into this folder
with the front matter already filled in, seeds the model with the world's own proper nouns so
"the Codex" does not come back as "the codecs", and marks anything it was unsure of `[unclear]`.
It needs no ffmpeg, but it does fetch the model from `huggingface.co` on first run, so it has to be
run somewhere that host is reachable.

What matters either way is that the words are the spoken ones.

## Naming

`YYYY-MM-DD-<respondent>-<topic>.md` — e.g. `2026-09-14-dougie-gates-and-the-tower.md`. The topic is
only for finding it again later; a note is never expected to stay on topic. A joint session is
`YYYY-MM-DD-joint-session-<n>.md`.

## Front matter

Two lines at the top, then the transcript:

```
---
respondent: dougie
recorded: 2026-09-14
---

So the thing about gates, right, I keep coming back to — they're not doors. Sorry, let me
start again...
```

`respondent` must match an id in [respondents.md](../respondents.md). It is what decides whether an
answer is canon or a note, so it matters more than it looks.

### A note with two voices

A joint session — both founders on one call — is still one note, but every answer in it belongs to
whoever said it. Name everyone in `respondent`, and map each label the transcriber used to an id:

```
---
respondent: dougie, doug-md
speakers:
  "Douglas, Will": dougie
  "ED": doug-md
recorded: 2026-09-24
---
```

Quotes taken from it are attributed line by line, to the speaker, never to the note. Where one
founder proposes and the other agrees, the entry quotes both — an agreement is only worth recording
if the reader can see who moved. The first one is
[2026-09-24-joint-session-1.md](2026-09-24-joint-session-1.md), from a Teams call whose `.vtt`
transcript was dropped straight into `DROP-ZONE/` — a call transcript needs no transcription
pass, only the front matter.

## Leave it messy

**Do not tidy the transcript.** Keep the false starts, the "sorry, scratch that", the sentence that
trails off, the bit where you answer a question from twenty minutes ago. All of it is signal:

- A trailing-off answer becomes `**Blocked.**` with a specific follow-up question, rather than being
  silently rounded up into something you did not say.
- Doubling back later in the same note is how a `**Partly answered.**` becomes `**Answered.**`.
- Two vague passages in different notes often turn out to settle a third question between them. That
  only works if both were kept whole.

Filler words cost nothing. A cleaned-up paraphrase loses the thing that made it worth recording.

## What happens next

The note is read whole before anything is mapped — people answer the question they were asked ten
minutes ago, and the last sentence of a ramble is often the real answer to its first. Then:
direct answers are written down as canon; anything inferred or assembled from several passages is
written as provisional and comes back to you as a short list to confirm; anything that contradicts
an earlier answer is raised rather than overwritten.

### A first pass by model

Optional, for whoever runs the ingest. With `dougie`'s LLM gateway running:

```
python3 tools/map_voice_note.py docs/worldbuilding/voice-notes/<note>.md --out draft.md
```

It sends the transcript and every question id to a model on the gateway's `private` lane
(zero-retention; nothing the founders say goes to a free tier) and writes a draft: which questions
each passage seems to speak to, as _direct_, _partial_, _inferred_ or _contradicts_, next to the
question's current status in [answers.md](../answers.md). Every quote in it has been checked **word
for word** against the transcript, and the speaker and timestamp are taken from the line it was
found on, never from the model. A quote the model tidied or invented is listed under _Rejected_
rather than shown. `--dry-run` shows the size of what would be sent without sending it.

The draft is a pointer, not a reading. It does not replace reading the note whole, it cannot write
a status, and its _care_ guesses are guesses — a tag only counts when it was said.

