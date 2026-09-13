# 13 — Heroes & Tempers

Sixteen starting characters, one per temper. The player does not browse them: they answer four
questions, and the four answers name the life they are about to live. The other fifteen are people
in the world.

Supersedes [11 — Hero Backstories](11-character-backstories.md), which describes the twelve heroes
this replaces. Those twelve are still playable while the sixteen are written.

## The four questions

One per preference pair, so sixteen answers map exactly onto sixteen characters. The questions
live in `data/tempers.json` under `quiz` and are asked by `src/ui/temper_quiz.gd`.

| Axis | The question is about | Letters |
| --- | --- | --- |
| E / I | Where the thinking happens | **Outward** — counts on the room · **Inward** — counts on themselves |
| S / N | What gets trusted | **Ground-read** — the track, the weather, the wound · **Sky-read** — the shape of the thing |
| T / F | How it gets decided | **Cold-eyed** — by weight · **Warm-handed** — by who it lands on |
| J / P | How the road gets walked | **Set** — decides early and holds · **Loose** — decides late and keeps moving |

The in-world name leads everywhere it is shown. The four-letter code appears as a subtitle and as
the key in `data/tempers.json`; **the test it comes from is never named in shipped text.**

## What a temper is worth

Every character carries exactly four leans, one per letter, so nobody is strictly stronger than
anybody else — the sixteen are sixteen mixes of one budget. Values live in `tempers.json` under
`leans` and are meant to be argued with.

| Letter | What it does | Where it happens |
| --- | --- | --- |
| **E** | Bonds start a step warmer; hires cost 15% less | `Banter.initial_bond`, `Market.asking_hire_cost` |
| **I** | Doctrine fades at 1125 steps instead of 900 | `Doctrine.fade_after` |
| **S** | Weapon proficiency arrives 25% sooner | `Proficiency.rank` |
| **N** | Reads generated trees as if the Codex were 25% further along | `Progression` |
| **T** | +5% damage dealt | `Character.attack` |
| **F** | Rescue grace +4pp per ally standing, cap +8pp | `Fate.graces_for` |
| **J** | Opens a battle with +20 charge time | `TurnManager.setup` |
| **P** | +1 move point | `Character.move_points` |

## The screen

`New Game` goes to `temper_quiz`, not to the picker. The quiz asks its four questions, then reveals
the character: portrait, name, title, temper and code, warband, whatever authored history has been
cast on them, and their stats.

**A temper with nobody written for it is an ordinary state, not a bug.** The sixteen slots exist in
`tempers.json` from the start and fill in one at a time; an unwritten slot says so and offers the
full roster instead. `Show me all sixteen` reaches the old picker at any point, which is also how
the whole roster gets tested.

## The sixteen

`hero` is blank until that character is written. Run `--list=tempers` for the live state.

| Code | Temper | Character |
| --- | --- | --- |
| INTJ | The Long Plan | — |
| INTP | The Open Question | — |
| ENTJ | The Marshal | — |
| ENTP | The Contrary | — |
| INFJ | The Quiet Cause | — |
| INFP | The Kept Flame | — |
| ENFJ | The Gatherer | — |
| ENFP | The Spark | — |
| ISTJ | The Ledger | — |
| ISFJ | The Keeper | — |
| ESTJ | The Straight Road | — |
| ESFJ | The Full Table | — |
| ISTP | The Steady Hand | — |
| ISFP | The Own Path | — |
| ESTP | The First Move | — |
| ESFP | The Bright Hour | — |

## Writing one

Four sittings of four, grouped so each sitting contrasts with itself: **NT** (INTJ, INTP, ENTJ,
ENTP), **NF**, **SJ**, **SP**. Each character ships as one bundle:

- `data/heroes.json` — id, `title`, `temper`, `difficulty`, `origin`, `blurb`, `companions`
- `data/units.json` — stats, `abilities`, `classes`, `color`, `sprite_dir`
- `data/areas/<area>.json` — a `people[]` entry where they stand when somebody else is the lead
- `data/dialogue/heroes/<id>.json` — what they say, including what it takes to join
- this document — an entry in the shape `docs/11` uses
- `data/tempers.json` — `types["XXXX"].hero`

Two rules:

1. **Show the type, never state it.** The character reads as their temper through what they do and
   refuse to do. The four letters are a subtitle, not a description.
2. **Art before identity.** Twenty-eight unit sprite directories already exist. Give each new
   character an existing body and nothing waits on art.

Their five history fields — background, grudge, hearth, creed, oath — stay blank. Those are
written separately and cast late; see [14 — Lore Pools](14-lore-pools.md). A character has to read
as themselves before any of it is attached.
