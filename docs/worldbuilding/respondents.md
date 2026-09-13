# Respondents

Who answers the [Question Book](../15-the-question-book.md), and what their answers are worth.

The set is open — other people will be asked, and their answers are welcome. That is exactly why
standing has to be written down: once more than two people are answering, "it was answered" cannot
mean *whoever spoke last*.

## Standing

| Standing | What their answers do |
| --- | --- |
| `founder` | **Canon.** An answer from a founder settles the question. Two founders answering differently is `**Contested.**` and goes to the [divergence ledger](divergence-ledger.md) |
| `guest` | **Noted.** Recorded in full, quotable, and it absolutely can change a founder's mind — but it does not settle anything on its own. A founder can promote a guest answer to canon, and the entry records who did and when |

A guest contradicting a founder is not a conflict. It is a second opinion, and it gets written down
as one.

## The register

| Id | Standing | Git identities | Notes |
| --- | --- | --- | --- |
| `dougie` | founder | `DougieWilDaBeast` | |
| `doug-md` | founder | `DougMD123` | |

Add a row before that person's first note is ingested. A note from somebody with no row is flagged,
not guessed at.

## How a note gets attributed

In this order, first hit wins:

1. **A `respondent:` line in the note's front-matter.** This is the reliable one and should always
   be present.
2. **The git author of the commit that added the file**, mapped through the register above.
3. **Nothing** — the note is ingested, every answer in it is held as unattributed, and it is raised
   rather than assigned to somebody.

Front-matter wins over git on purpose. Notes often get committed by whoever is at the keyboard —
frequently Claude in a coding session — and git authorship would then quietly credit every answer to
the same person. The line in the file is what the speaker actually claimed.
