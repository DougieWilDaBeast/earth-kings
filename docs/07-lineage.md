# 07 — Lineage

Where this game came from. Kept so the trail is not lost and so nothing already worked out gets
re-invented from scratch.

## The original: CHRONICLE

A prior project — _CHRONICLE: Generational Rule Evolution Battle Sim_, tagline _"knowledge
outlives the knower"_ — reached **v2.9** as a Python/FastAPI world simulation with an LLM layer.
Roughly 3,800 lines of Python, ~60 HTTP endpoints, 23 design docs, 60 logged decisions and a
Phaser 3 browser client.

Its own roadmap named the missing piece: an **FFT-style presentation client**, with _"Godot noted
as the native-app path."_ That is what this repo became.

A copy lives at `possible-relevant-game-material/` for reference. **It is reference material, not
a dependency** — nothing here imports from it.

### What was carried across

| From CHRONICLE                                               | Here                          |
| ------------------------------------------------------------ | ----------------------------- |
| Per-character knowledge; nothing inherited by default        | Doctrine (`doctrine.gd`)      |
| Knowledge entropy — doctrine can be forgotten                | 900-step decay                |
| Hidden ability grammar; trees generated, not authored        | `ability_grammar.gd`          |
| The Codex — cataloguing until the power system is understood | `World.codex_understanding()` |
| The Training Yoke — a self-debuff traded for growth          | `Character.yoke`              |
| Ranked gates, dungeon breaks, the Tower                      | `Site`, gate ranks E→S        |
| Permadeath as the engine of everything else                  | Pillar 4                      |
| One canonical timeline; ruin is inheritable                  | Pillar 4, no rewind           |
| Minds emit intents, only the engine mutates state            | The mind seam                 |

### What was dropped

- **Eras** ([D01](06-decisions.md)) — the generational frame the whole original was built on.
- **The server** ([D02](06-decisions.md)) — world authority moved into the client.
- **The rule/petition system** — a generation proposing one rule then ending. It belongs to the
  era frame; the Library covers the same ground for a game played from the inside.
- **The versus frame** — already retired in the original's own docs/23.

## Before CHRONICLE

The design DNA predates both projects and shows up independently across years of notes:

- **Scarce, earned power** — XP only for first clears, no farming, no level cap.
- **Information as the resource** — maps drawn as you explore, books, translated language,
  journals, fog of war, scouts who relay rather than reveal.
- **Advise, don't command** — autonomous units that keep their own judgement.
- **Deliberate unfairness as a feature** — asymmetric knowledge, one-sided pressure.
- **Permadeath with continuity** — the run survives the character.
- **One-way doors** — floors that trap everyone inside; brands that lock you out of the city.
- **Mastery through use** — any character, any weapon, improving by doing.

Each of these now has a full entry in [16 — Lineage entries](16-lineage/00-index.md): what it is,
the mechanisms worth taking, candidate answers tagged to [Question Book](15-the-question-book.md)
ids, and — the part that matters most — what **not** to take. The paragraph below is the short
version; that folder is the long one.

Acknowledged influences: _Solo Leveling_ (gates, dungeons, a summoned army), _Pick Me Up_
(rolling a character out of nothing), _Surviving the Game as a Barbarian_ (meta-knowledge as the
sharpest weapon; scarce first-clear XP), _Omniscient Reader's Viewpoint_ (the watching layer),
_The World After the Fall_ (walk forward, never reset), plus Final Fantasy Tactics for combat
presentation and Dragon Quest for the walking loop.

Named in [joint session 1](worldbuilding/voice-notes/2026-09-24-joint-session-1.md) (2026-09-24), and
none of them has a lineage entry yet: _Dungeon Settlers_ (the real-time-with-pause fight — a research
deep dive is on the roadmap), _Fire Emblem: Three Houses_ (every attack animated), _Kenshi_
(proficiency by repetition), _Dark Souls_ and _Elden Ring_ (each level costs more), _Pokémon_ (four
active moves), _My Hero Academia_'s One For All (the dead predecessors met in the mind), _Vinland
Saga_, _Naruto_ and _One Piece_ as character seeds, and _Tower of God_ again for gates as whole
worlds. _Surviving the Game as a Barbarian_ came back for first-kill experience — the same "scarce
first-clear XP" noted above.

## Reading the original

If you need detail on a deferred feature, the original's docs are the specification:

| Topic                                 | Original doc                            |
| ------------------------------------- | --------------------------------------- |
| The power system and the Codex        | `docs/16-power-system.md`               |
| Character minds — the LLM tier ladder | `docs/21-character-minds.md`            |
| Gates, monsters, the Tower            | `docs/17-world-locations.md`            |
| Society, houses, art direction        | `docs/19-society-and-fate.md`           |
| Perspective, the Masquerade           | `docs/20-perspective-and-masquerade.md` |
| Every settled decision                | `decisions/resolved.md`                 |
