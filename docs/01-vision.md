# 01 — Vision

## What this is

A single-player tactical RPG in a persistent, hostile world. You walk the land tile by tile,
fight what finds you on a tile grid, and grow characters who can die permanently. Power is scarce,
knowledge is carried rather than inherited, and the world does not wait for you.

**The premise** ([17](17-the-sixteen-worlds.md)): sixteen demigods fall from a heavenly place into
sixteen copies of Earth, one each, and forget who they were. You are one of them. Your line of
quests leads to the Tower at the centre of your world; past its top wait the other survivors, and
only one world will be left standing. **When you die, your world ends** — and you go on as another
of the sixteen, in their world, from the beginning, carrying only what you know, a ghost and a
weapon. Sixteen worlds, sixteen chances.

**The tone** is dark fantasy, getting darker as it goes ([D40](06-decisions.md)).

**The fight** is real time with pause, point-and-click on the grid, four active abilities, and
(still to come) every attack animated ([D36](06-decisions.md), [18](18-combat-direction.md)). It
replaced the turn-based charge-time fight on 2026-10-12, once both founders had played the two
([D64](06-decisions.md)).

Built native in **Godot 4 / GDScript**, running entirely on the local machine.

## The pitch

**Sixteen fell. One climbs.** ([D70](06-decisions.md))

A tactics RPG where every life is a whole world. When your lead dies, their world ends, and the next
of the sixteen begins again in theirs, knowing only what you learned ([D99](06-decisions.md)).

It is for players of tactics and roguelite games who want characters to care about (Darkest Dungeon,
Wildermyth, Battle Brothers, Hades) first; readers of tower-climb manhwa will find the Tower, gates
and ranks familiar.

## Design pillars

Four, settled at the retreat ([D99](06-decisions.md)); they replace the six written before it. Every
feature serves one of them, or is supporting, hidden or filler.

1. **One life, one world.** Death ends a world. Only knowledge, a ghost and a weapon carry to the
   next of the sixteen ([D32](06-decisions.md)). Power is scarce and earned: experience comes only
   from the first kill of each kind of enemy ([D37](06-decisions.md)), doctrine only touches the one
   who learned it, and a cleared gate never reopens.
2. **The climb.** The Tower is always in sight, and every system helps you climb or makes the climb
   mean more.
3. **The fight is where you stand.** Real time on the ground the band was met on, watch zones you
   can see, sneak or charge, pause when you choose ([D98](06-decisions.md)).
4. **Sixteen people, not sixteen skins.** Each lead has their own class, signature and memories, given
   back every five floors ([D63](06-decisions.md), [D93](06-decisions.md)).

### Working rules

Two of the old pillars are how the game is made rather than what it is:

- **Discoverability.** Abilities, gate ranks and the shape of the grammar are found in play; the game
  does not open with a manual or a wall of text. The hidden grammar of powers is a supporting feature
  until it is shown well.
- **Milestones, not steps.** The world moves on when something is done (a chapter of the Tower
  climbed, a checkpoint reached), and nothing runs against the clock ([D49](06-decisions.md)). **The
  build still runs on steps** until M18 replaces them ([agenda item 20](worldbuilding/answers.md#what-is-still-to-decide)).

**Auto** (the party walking itself) is a convenience for empty stretches: the First Hour has to play
well without it ([D99](06-decisions.md)).

## What this is deliberately not

- **Not era-based.** The source project (see [Lineage](07-lineage.md)) ran on generational eras.
  That frame is retired — see [D01](06-decisions.md). The world advances continuously.
- **Not server-backed.** Everything runs locally. No API keys, no network, works on a plane.
- **Not a simulation you watch.** You play a character in the world.

## Deferred, not abandoned

These are designed for and have seams left in the code. None are needed to play.

| Feature                                                    | Seam that exists today                                                                             |
| ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| LLM character minds — NPCs who decide their own goals      | `SkirmishBrain` already returns _choices_ the fight carries out; intents never mutate state directly |
| NPC society — characters living their own lives off-screen. **Now wanted for the fifteen** ([17](17-the-sixteen-worlds.md)) | `Character` is fully separate from the battle `Unit` that represents it                            |
| The Masquerade                                             | `Site` and `Character` both carry an open `data` / flags bag                                       |
| A server as world-authority                                | The world is one serialisable object (`World.to_dict()`)                                           |

## Success looks like

Two people can sit down, start a world, walk it, lose a character they cared about, and want to
go again.
