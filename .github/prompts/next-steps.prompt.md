---
description: Build the next phase of Earth Kings — Guild, gate objectives, musters, the fallen
agent: agent
---

Read [AGENTS.md](../../AGENTS.md) and the working rules in
[docs/00-index.md](../../docs/00-index.md#working-rules). Implement **Phase ${input:phase:0-6}** of the
plan below, and only that phase. Read every file named for the phase before editing.

Rules:
- Content goes in `data/`; systems talk through `EventBus`; new chronicle helpers are loaded by path
  (D41); JSON is read through `SaveFile.read` (D42); GDScript uses tabs.
- Anything invented is written **Inferred.** and added as a row to the agenda in
  `docs/worldbuilding/answers.md` — never marked answered. Only a founder settles.
- Update the docs the change touches in the same commit: `feat(M14): …`, `feat(M15): …`, `docs: …`.
- After each change run that suite (`.\ek.ps1 test <suite>`, or
  `godot --headless --path . res://tests/<suite>_smoke_test.tscn -- --check=<name>`). At the end of
  the phase run `.\ek.ps1 test`, `.\ek.ps1 soak 120`, `.\ek.ps1 ledger`. Report what passed and
  what is left. Ask before deleting files or pushing.

## The plan

Founder-answered and buildable now: the Adventurers Guild and S-rank musters (`DV2`, `OT8`, D35,
[17](../../docs/17-the-sixteen-worlds.md#gates)), gate objectives without timers (timers are agenda
item 14, deferred), and passing dead leads to the quiz and picker (D43, D44).

**Phase 0 — Housekeeping.** DROP-ZONE empty (anything already ingested goes to the gitignored
`.art_stage/` archive). Roadmap "Next steps" free of passed deadlines.

**Phase 1 — Founder briefing sheet** (after 2–6). A sheet in `docs/worldbuilding/` linked from the
agenda: for each open Section 1 item, the options, what each costs in the build, and the default.
Tables only — never `## XX9 — ` headings. Agenda rows for every **Inferred** rule the build made.
Run `.\ek.ps1 ledger`.

**Phase 2 — Gate objectives, untimed.** `data/objectives.json` (`rout` default, `guardian` = the
boss falls, final floor only; `heart` = a party unit reaches a marked cell). Chosen from the gate's
cell hash, never `world.rng`; `site.data["objective"]`, old saves fall back to `rout`. Through
`Encounter.for_gate` → battle payload → `Battle._check_victory`; HUD line; named in `_enter_gate` and
`Site.label()`. Tests in `battle_smoke_test`, `walk_smoke_test --check=gate`, `seams_smoke_test`.

**Phase 3 — Allies in the turn-based battle.** `Unit.Team.ALLY` and `Unit.hostile_to()`; allies act
like enemies under `EnemyBrain`, earn no XP/journal/Fate/ledger; the party falling loses the fight.
Distinct tint. Check `allies` in `battle_smoke_test`.

**Phase 4 — The Adventurers Guild.** `src/chronicle/guild.gd` + `data/guild.json`. `register(world)`
lists open and brewing gates by rank with objective and bearing. Gate contracts are `GATE`-kind
errands paid when the gate shuts; `Dispatch` refuses them. `site_guild` action at keeps and villages
that are not ruined → `EventBus.guild_requested` → `src/ui/guild_screen.tscn` (modal overlay group,
`is_open()`, `Sfx.attend`). A Guild clerk in keep and village interiors opens the same screen.
Check `guild` in `walk_smoke_test`; `_check_content`; `.\ek.ps1 test area`.

**Phase 5 — S-rank musters** (needs 3 and 4). An S-rank gate opening raises a muster at the nearest
standing keep or village (`world.musters`, saved). Strength grows each upkeep (`guild.muster` in
`data/world_rules.json`). Join from the Guild screen: every floor fields allies. Unjoined and strong
enough, it goes in alone — **Inferred**: a win shuts the gate (Annals, News, no renown, not a chapter
key), a loss breaks it. `Chapters` must not softlock. `Dispatch` can send a companion to a muster.
Checks `muster` in `walk_smoke_test` and in `dispatch_smoke_test`.

**Phase 6 — The fallen.** `src/chronicle/sixteen.gd` keeps `user://earth-kings.sixteen.json`
(`fallen_tempers`, `fallen_heroes`; test-overridable path). `run_summary` records the lead on
`Museum.FELL` while tallying; `Database.hero_temper()`; `Museum` gains `lead_id`/`lead_temper`.
New Game passes the fallen to the quiz, the quiz forwards fallen heroes to the picker, which hides
them; when nobody is left, offer **Begin a new sixteen** (confirm, then wipe). Extend
`_check_fallen_quiz`.
