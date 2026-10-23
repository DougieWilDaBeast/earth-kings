# Earth Kings

<!-- Shared context for any coding agent (Claude Code, OpenCode, Aider).
     CLAUDE.md imports this file. Keep it short; the docs hold the detail. -->

## What this is
A tactical RPG in a persistent, hostile world, by two founders (`dougie`, `doug-md`). Walk a
generated map tile by tile, fight on a tactics grid, grow characters who can die for good. Start at
[docs/00-index.md](docs/00-index.md); the roadmap's **Next steps** in
[docs/05-roadmap.md](docs/05-roadmap.md) is the current focus.

## Stack
- Godot 4.7, GDScript. No .NET, no plugins, no build step.
- Content is JSON in `data/`; saves are JSON in `user://`.
- Python 3 only for tools in `tools/` (standard library unless the file says otherwise).

## Commands
- Run: open `project.godot` in Godot and press F5.
- Test: `.\ek.ps1 test` (Windows) or `./ek.sh test` (Linux/macOS): thirteen headless suites.
  One suite: `./ek.sh test walk`. One check: `godot --headless --path . res://tests/walk_smoke_test.tscn -- --check=gate`.
- Soak: `./ek.sh soak 120` — the game plays itself on seed 77, as the lead the quiz deals from it, then saves, loads and saves again.
- Ledger: `./ek.sh ledger` — the Question Book and `answers.md` agree (run after any worldbuilding edit).
- Dress: `python3 tools/dress_areas.py [area ...]` — rewrites an area's scenery (`dressing`) after its
  layout, people or props change; sizes live in `data/props.json`.
- Clips: `python3 tools/who_wins.py ares cassius` — two of the sixteen fight it out as a "who wins?" show,
  recorded wide and tall into `clips/` (needs ffmpeg; docs/18, "Who wins?").
- Party clashes: `python3 tools/party_war.py all` — random parties of one to four and a guild war,
  as a results table and as video in `clips/` (docs/18, "Party clashes").
- Plan table: `python3 tools/plan_table.py compare 100` — the party clashes with and without a small
  model's fight plans (written offline by `make`; docs/investigation/12, D322).
- CI runs all three on every pull request (`.github/workflows/smoke.yml`). Keep it green.

## Rules
The working rules in [docs/00-index.md](docs/00-index.md#working-rules) bind every change:
1. Content lives in `data/`, never in code.
2. Systems talk through `EventBus`; no system holds a reference to another.
3. Every milestone ends playable.
4. A settled design question gets a numbered entry in `docs/06-decisions.md` (append-only).
5. Docs describe what exists; planned work goes in the roadmap, marked planned.

And for the worldbuilding ledger (`docs/worldbuilding/`):
- **A quote is never edited.** Voice-note transcripts stay exactly as spoken.
- Only a founder settles a question. A source, a draft or a model can propose; it cannot answer.
- Anything inferred is written `**Inferred.**` and goes back to the founders to confirm.

## Art requests
Only `dougie` generates art (PixelLab). When a change needs art that does not exist yet, add a row to
**Open** in [docs/24-art-requests.md](docs/24-art-requests.md) in the same change — what it is, size
and look, and where it goes — and tell `doug-md` there is art for `dougie` to make. Finished art arrives
in `DROP-ZONE/<request id>/`; moving it into `art/` closes the row.

Commits: `feat(M14): …`, `fix: …`, `docs: …`, `tools: …` — the milestone in brackets when there is one.
Update the docs a change touches in the same commit.

Work is tracked as GitHub issues ([docs/32](docs/32-the-pipeline.md#the-inbox)): open one for any new piece of work,
and say "Closes #n" in the PR (or "docs-only", or "No issue: why"); the `plan` check fails a PR without it.

Every PR keeps the docs current in the same PR, not a later one:
- **`docs/06-decisions.md`** ([D139](docs/06-decisions.md)): a numbered entry for anything it settles (next free D number from main).
- **The agenda** (`docs/worldbuilding/answers.md#what-is-still-to-decide`): a row for anything `**Inferred.**`.
- **The numbered doc it touches**, and the roadmap's **Next steps**; for First Hour work,
  [docs/28](docs/28-the-first-hour.md), including any build pushed to itch (commit, time, what it carried).

