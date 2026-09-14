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
| `source` | **Proposed.** A work that shaped this project, offering a drafted answer with its costs already worked out. A source is not a person and cannot produce canon; a founder adopts a proposal or does not, and the entry records which |

A guest contradicting a founder is not a conflict. It is a second opinion, and it gets written down
as one.

## The register

| Id | Standing | Git identities | Notes |
| --- | --- | --- | --- |
| `dougie` | founder | `DougieWilDaBeast` | |
| `doug-md` | founder | `DougMD123` | |
| `src-watf` | source | — | *The World After the Fall* — the `PW` block, `KN1`, `FR8` |
| `src-orv` | source | — | *Omniscient Reader's Viewpoint* — `SF`, `SM5`, `NW`, `CO1` |
| `src-barbarian` | source | — | *Surviving the Game as a Barbarian* — `GT`, `LF`, `DV`, `EC3` |
| `src-fft` | source | — | *Final Fantasy Tactics* — `RU`, `LW`, `FR1`, `FR7`, `HS7` |
| `src-xcom` | source | — | *XCOM* — `BD2`, `BD8`, `SM6`–`SM8`, `MX12`, `MX19` |
| `src-bg3` | source | — | *Baldur's Gate 3* — `MX17`, `MX18`, `LP19`, `CH5`, `CH9` |
| `src-octopath` | source | — | *Octopath Traveler 2* — `SK7`, `SK8`, `DY`, `CH14`, `MX16` |
| `src-dwarf-fortress` | source | — | *Dwarf Fortress* — `HS`, `NW`, `LW8`, `FR10`, `AR8` |
| `src-mount-hua` | source | — | *Return of the Mount Hua Sect* — `KN`, `FA8`, `RU6`, `DV7` |
| `src-regressor` | source | — | *The Regressor Can Make Them All* — `MK`, `EC8`, `LP6`, `OT8` |
| `src-chronicle` | source | — | **CHRONICLE — internal.** The team's own prior project, and the only source whose design can be changed to suit the answer. Weigh its proposals knowing that |

Add a row before that person's first note is ingested. A note from somebody with no row is flagged,
not guessed at.

A `source` row has no git identity on purpose: nobody commits on a book's behalf. A proposal is
attributed by the entry it came from in [16 — Lineage entries](../16-lineage/00-index.md), and that
entry is in the repo so the reasoning can be read rather than taken on trust.

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
