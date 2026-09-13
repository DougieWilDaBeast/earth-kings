# Running the World Charter Interview

Two people, answering [288 questions](../12-world-charter-interview.md) separately, then
reconciling. This file is the procedure. It exists because the hard part is not the questions —
it is what you do with two different sets of answers without one person quietly losing.

## The one rule

**Answer alone.** No discussion, no "what did you put", no reading ahead in the other sheet. An
agreement you both arrived at independently is load-bearing world. An agreement produced by one
person talking first is a preference with a witness.

## The tags, and why they matter more than the answers

Every answer carries a care tag, not a confidence rating:

| Tag | Means | What it does in reconciliation |
| --- | --- | --- |
| `H` | I have a real stake in this | Conflicts here are the world's actual design work |
| `M` | A preference | Yields to an `H` without argument |
| `L` | A shrug | Yields to anything |
| `—` | I do not care, you decide | **Hands the decision over.** Not a vote, a transfer |
| `!` | Veto — I would stop working on this | Ends the discussion. **Three for the whole interview** |

The tags are what make this finishable. Two people can disagree on two hundred things and still
converge in an afternoon if only fifteen of them are `H` against `H`.

## Schedule

Five sittings, ninety minutes each, no more. Fatigue produces canon nobody believes.

| # | Solo pass | Then, together |
| --- | --- | --- |
| 1 | **Part 0 (Frame) + Part V (Boundaries)** — 18 questions | Merge immediately. If the frames are incompatible, stop. Everything downstream is wasted until they are not |
| 2 | **Part I — Physical** (~70) | Merge |
| 3 | **Part II — Mental** (~60) | Merge |
| 4 | **Part III — Cultural** (~120) | Merge — split over two sittings if needed |
| 5 | **Part IV — Seams** (12) | Merge, then canonise everything |

Part 0 first is not a formality. FR4 ("what does _Earth Kings_ mean") and BN1 ("what must never be
true") decide dozens of later answers on their own, and you want them decided before either of you
has invested a Saturday in a cosmology.

## The merge session

Go question by question, in ID order. Read both answers aloud before discussing either. Classify:

- **AGREED** — same answer, or trivially the same. Copy it to the world bible. Move on in ten
  seconds. Most of the interview will be this, and that is the interview working.
- **COMPATIBLE** — different answers that are both true. Two peoples, two regions, two eras, or
  one is a belief and the other a fact. **Try this before every fork.** A world where the coast
  and the interior disagree about what a gate is, is richer than a world where one of you won.
- **FORK** — genuinely cannot both be true. Goes in the [ledger](divergence-ledger.md).
- **OPEN** — both tagged `L` or `—`, or both wrote `?`. **Leave it open.** Do not invent an answer
  to avoid a blank. An unanswered question is a door; a bored answer is a wall.

### Resolving a fork

In order. Stop at the first rule that applies.

1. **A veto ends it.** No appeal, no trade.
2. **Higher care tag wins.** `H` beats `M` beats `L` beats `—`.
3. **Can it be both?** Region, people, era, or fact-versus-belief. Prefer this to any tiebreak.
4. **Whose pillar is it?** Whoever holds the [design pillar](../01-vision.md#design-pillars) the
   question touches decides. Scarce power, one-way doors, discoverability — these are already
   settled and a world answer that guts one of them loses to the pillar, not to a person.
5. **Does it change anything within a month?** If neither answer alters a JSON file, a line of
   dialogue, or a rule before then, it is OPEN. Defer it. It will be easier later, when the game
   has an opinion.
6. **Coin.** Genuinely. And the loser's version gets written into the world as something a
   character *believes* — which is how you get an in-world argument for free.

Record every fork in the ledger even after it is resolved, including the version that lost. The
losing answers are the best source of heresies, rumours, unreliable books and factional
propaganda this project will ever have. Nothing here gets thrown away, it gets demoted to
somebody's opinion.

## Canonising

Nothing is canon until it is written outside this folder.

| Kind of answer | Where it goes |
| --- | --- |
| A plain fact about the world | `docs/13-world-bible.md`, one line, stated flat |
| Anything that changes a rule or a system | A numbered `D` entry in [06 — Decisions](../06-decisions.md), with the date and the reasoning — that file is append-only and is where this is looked up |
| Anything that becomes content | A task against `data/` — factions, doctrine, areas, dialogue, memorials. Working rule 1: content lives in `data/`, never in code |
| A losing fork | Stays in the ledger, flagged as a candidate belief, rumour or false doctrine |
| Open | Stays in the ledger as open. Revisit at the next milestone, not sooner |

Write the bible in **statements, not options**: "Gates are wounds, not doors; nobody opens them on
purpose" — not "gates are probably wounds". If the sentence needs a hedge, it is not canon yet.

## What to do when you disagree about disagreeing

BN7 asks whether you would still want to build the other person's world if it won every
disagreement. If either answer to that is no, the ledger cannot fix it and neither can this
document — that is a conversation about the project, not about the world, and it is better had
once, early, than in fragments across two hundred merge decisions.
