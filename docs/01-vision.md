# 01 — Vision

## What this is

A single-player tactical RPG in a persistent, hostile world. You walk the land tile by tile,
fight what finds you on a Final Fantasy Tactics–style grid, and grow characters who can die
permanently. Power is scarce, knowledge is carried rather than inherited, and the world does not
wait for you.

Built native in **Godot 4 / GDScript**, running entirely on the local machine.

## Design pillars

1. **Scarce, earned power.** Levels, classes and powers are found, not farmed. A character is
   the sum of what they personally survived.
2. **Knowledge is carried, never inherited.** Doctrine affects only the character who read it or
   was taught it. Unused, it fades. The Library is a place you walk to for a reason.
3. **Powers are discovered, not authored.** Skill trees are generated from a hidden grammar. The
   world's own power system is a thing to be catalogued and eventually understood.
4. **One-way doors.** Permadeath is real. A cleared gate reopens. There is no going back to a
   version of the world you liked better.
5. **The world runs on steps, not turns.** Walking is what advances it. Gates stir and knowledge
   decays because you moved, not because a clock ticked somewhere off-screen.
6. **Discoverability.** Abilities, gate ranks and the shape of the grammar are found in play.
   The game does not open with a manual.

## What this is deliberately not

- **Not era-based.** The source project (see [Lineage](07-lineage.md)) ran on generational eras.
  That frame is retired — see [D01](06-decisions.md). The world advances continuously.
- **Not server-backed.** Everything runs locally. No API keys, no network, works on a plane.
- **Not a simulation you watch.** You play a character in the world.

## Deferred, not abandoned

These are designed for and have seams left in the code. None are needed to play.

| Feature                                                     | Seam that exists today                                                                             |
| ----------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| LLM character minds — NPCs who decide their own goals       | `EnemyBrain` already returns a _plan_ the controller executes; intents never mutate state directly |
| Chronicles — narrative records generated from what happened | `EventBus.battle_log` already emits every meaningful event as a line                               |
| NPC society — characters living their own lives off-screen  | `Character` is fully separate from the battle `Unit` that represents it                            |
| Renown, bounties, the Masquerade                            | `Site` and `Character` both carry an open `data` / flags bag                                       |
| A server as world-authority                                 | The world is one serialisable object (`World.to_dict()`)                                           |

## Success looks like

Two people can sit down, start a world, walk it, lose a character they cared about, and want to
go again.
