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

Transcribe however suits — a local `whisper`, phone dictation, or typing it out. What matters is
that the words are the spoken ones.

## Naming

`YYYY-MM-DD-<respondent>-<topic>.md` — e.g. `2026-09-14-dougie-gates-and-the-tower.md`. The topic is
only for finding it again later; a note is never expected to stay on topic.

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
