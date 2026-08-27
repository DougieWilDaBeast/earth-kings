# 06 — Decisions

Append-only. When a design question is settled, record it here with the date and the reasoning.
Never edit a past entry — supersede it with a new one.

| #   | Decision                                                                                                     | Date       | Why                                                                                                                                                            |
| --- | ------------------------------------------------------------------------------------------------------------ | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| D01 | **Eras are retired.** The world advances by _steps_ taken while walking, not by generational eras.           | 2026-08-27 | The source project was a simulation watched in generational batches. This is a game you play from inside. A player walking the map is the only clock it needs. |
| D02 | **Native Godot, local-only.** No server, no API keys, no network for the core game.                          | 2026-08-27 | It has to be playable this weekend, on any machine, offline. The server was the thing that made the original hard to hand to someone.                          |
| D03 | **LLM minds are deferred behind a seam, not designed out.** AI returns plans; only the engine mutates state. | 2026-08-27 | Keeps the door open without paying for it now. The invariant costs nothing today and is expensive to retrofit.                                                 |
| D04 | **`Character` and `Unit` are separate types.** Characters persist; Units are battle puppets.                 | 2026-08-27 | Without this split, progression and permadeath end up tangled in the battle scene and nothing is testable headlessly.                                          |
| D05 | **Falling in battle is not death — yet.** A downed party member is dragged out at 25% max HP.                | 2026-08-27 | Inherited from the tactics core. Permadeath is a pillar, so this is a placeholder: real permadeath needs to bite somewhere. Open question below.               |
| D06 | **Skill trees are generated, never authored.** Themes × effect archetypes × rungs, from a hidden grammar.    | 2026-08-27 | Discovering a power nobody wrote is the hook. Authored trees would be finite and knowable.                                                                     |
| D07 | **Doctrine is per-character and decays.** Nothing is inherited; unused knowledge fades after 900 steps.      | 2026-08-27 | Makes the Library a destination and knowledge a resource you spend effort maintaining, rather than a checkbox.                                                 |
| D08 | **Gate rank is set by distance from the Tower**, with jitter.                                                | 2026-08-27 | Gives the map a natural difficulty gradient without hand-placing anything, and makes the Tower feel like what it is.                                           |
| D09 | **`World.rng` is the single source of world randomness.** Battle-time variance is deliberately not seeded.   | 2026-08-27 | Same seed, same world — needed for testing and for sharing a world. Reproducible damage rolls would just feel wrong.                                           |
| D10 | **Two-player means passing the pad**, one character, one world.                                              | 2026-08-27 | Cheapest thing that works this weekend. Hotseat and PvP duels are not ruled out later.                                                                         |

## Open questions

Discuss before implementing the affected component.

- **Q1 — Where does permadeath actually bite?** D05 makes falling survivable. Options: death only
  in the Tower and S-rank gates; death on a second fall in the same delve; a "grave" roll. Needs
  deciding before M5.
- **Q2 — Does the player pick their class at level 2, or is it assigned?** Currently assigned from
  the template's options. Picking is better, and costs a UI.
- **Q3 — Can the Tower be finished?** A final floor implies an ending; endless floors imply
  walking forward forever.
- **Q4 — What does a completed Codex unlock?** Reading the grammar's shape, or deliberately
  _crafting_ powers instead of discovering them.
- **Q5 — Should gates that reopen escalate in rank?** A world that is quietly getting worse is
  more interesting than one at equilibrium.
