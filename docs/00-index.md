# Earth Kings — Design Package

The working documentation for the game. Read in order; each doc is short on purpose.

| #   | Doc                                | What it answers                                                 |
| --- | ---------------------------------- | --------------------------------------------------------------- |
| 01  | [Vision](01-vision.md)             | What this is, what it is deliberately not, what is deferred     |
| 02  | [Design](02-design.md)             | The loop and every system in it                                 |
| 03  | [Architecture](03-architecture.md) | Where code lives, how it talks, where the seams are             |
| 04  | [Data formats](04-data-formats.md) | Every JSON schema, so content can be added without reading code |
| 05  | [Roadmap](05-roadmap.md)           | Milestones and honest status                                    |
| 06  | [Decisions](06-decisions.md)       | What was decided, when, and why — append-only                   |
| 07  | [Lineage](07-lineage.md)           | Where this came from, so the trail is not lost                  |

## Working rules

1. **Content lives in `data/`, never in code.** A new gate, class, doctrine or unit is a JSON edit.
2. **Systems talk through `EventBus`.** No system holds a reference to another.
3. **Every milestone ends playable.** Nothing starts until the previous thing runs.
4. **Update `06-decisions.md` when a design question is settled.** Future-you will not remember why.
5. **Docs describe what exists.** Planned work belongs in the roadmap, marked as planned.
