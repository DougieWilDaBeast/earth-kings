# 05 — Roadmap

Shipping-first ordering: every milestone ends with something runnable. Nothing starts until the
previous milestone demonstrably works.

## M0 — Tactics core — SHIPPED

- Square grid, Dijkstra movement with per-tile cost and jump, charge-time turn order
- Abilities with min range, max range, splash, healing; facing bonuses (side 1.2×, back 1.5×)
- Enemy AI that plans a move and a target
- Directional unit art, equipment with per-facing offsets
- Wounds persisting between battles; title screen, system menu, save/load
- Headless smoke test that plays a whole battle

## M1 — Characters and progression — IN PROGRESS

- `Character` as the persistent person, distinct from the battle `Unit` ✅
- XP curve, level-ups, class choice at level 2, Training Yoke stance ✅
- Doctrine bonuses feeding derived stats ✅
- `Roster` holding the party; battles spawning from Characters and writing results back
- Permadeath wired through battle resolution
- ✅ Done when: a battle awards XP, someone levels, someone dies for good, and it survives a save

## M2 — The generated power system — IN PROGRESS

- Hidden ability grammar: themes × archetypes × rungs ✅
- Tree generation, registration into `Database`, restore-on-load ✅
- Codex understanding readout ✅
- Trees unlocking at levels 5 and 10 and feeding the battle command menu
- ✅ Done when: a character unlocks a tree nobody authored and casts it in a fight

## M3 — The world and walk mode

- `World` — ground, places, the step clock, serialisation ✅
- `WorldGen` — noise ground, scattered sites, ranked gates, seeded doctrine ✅
- Walk scene: tile-by-tile movement, camera follow, site labels, world map rendering
- Site interactions: rest, read, delve, climb
- ✅ Done when: you can walk from your starting village to the Tower and back

## M4 — Encounters and procedural battlefields

- Encounter roll driven by distance to the nearest open gate and nearest hearth
- Battlefield generation from the world terrain you were standing on
- Enemy composition scaled to party level and local danger
- ✅ Done when: walking through bad country gets you killed

## M5 — Gates and delves

- Stepping on an open gate starts a delve: a run of battles ending in its guardian
- Party HP carries across the run; clearing rewards XP, gold and sometimes a tree find
- Cleared gates shut, then eventually reopen
- ✅ Done when: an E-rank gate is survivable at level 3 and an A-rank gate is not

## M6 — The Tower

- One battle per floor, escalating; retreat allowed between floors, not during one
- Permanent floor log — the world remembers the highest floor anyone came back down from
- Fatal heights: floors well above your level do not scale down to meet you
- ✅ Done when: the Tower has killed someone who should have turned back

## M7 — The Library and doctrine

- Reading at a library; teaching party members at rest
- Entropy pass folded into world upkeep
- UI for what each character knows and what they are about to lose
- ✅ Done when: a character forgets something useful and it stings

## M8 — Fit to play

- World in the save file; new-game seed entry
- Balance pass across levels 1–10
- Headless smoke tests for world generation and a full delve
- ✅ Done when: two people can play a session without hitting a wall

## Deferred

Designed for, seams in place, not built. See [Vision](01-vision.md).

- LLM character minds and an NPC society living off-screen
- Chronicles: narrative records generated from telemetry
- Renown, bounties, the Masquerade
- A server as world-authority
- Generated tile art wired in from `art/map_kit`
