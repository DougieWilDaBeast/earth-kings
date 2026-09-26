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
- Soak: `./ek.sh soak 120` — the game plays itself on seed 77, then saves, loads and saves again.
- CI runs both on every pull request (`.github/workflows/smoke.yml`). Keep it green.

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

Commits: `feat(M14): …`, `fix: …`, `docs: …`, `tools: …` — the milestone in brackets when there is one.
Update the docs a change touches in the same commit.

## LLM usage in this repo
Optional, and only in tooling: **the game itself never calls a model** (D03 defers LLM minds
behind a seam). Tools that do go through `dougie`'s gateway (`LLM_GATEWAY_URL` +
`LLM_GATEWAY_KEY`, OpenAI-compatible) by lane name — `cheap`, `code`, `strong`, `private` —
never a provider or model ID.

- **The founders' words — voice notes, `answers.md`, the question book — go to `private` only.**
  They are two people's unreleased thinking, and free tiers may train on what they are sent.
- Code, logs and `data/` JSON may go to any lane.
- `tools/map_voice_note.py` drafts which questions a voice note speaks to, and rejects any quote
  that is not word for word in the transcript. Its output is a draft for the ingest, never canon.
