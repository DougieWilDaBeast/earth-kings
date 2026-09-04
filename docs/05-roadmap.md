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

## M1 — Characters and progression — SHIPPED

- `Character` as the persistent person, distinct from the battle `Unit` ✅
- XP curve, level-ups, class choice at level 2, Training Yoke stance ✅
- Doctrine bonuses feeding derived stats ✅
- `Roster` holding the party; battles spawning from Characters and writing results back ✅
- Permadeath wired through battle resolution via [`Fate`](02-design.md) ✅
- XP awarded to whoever landed the killing blow ✅

## M2 — The generated power system — SHIPPED

- Hidden ability grammar: themes × archetypes × rungs ✅
- Tree generation, registration into `Database`, restore-on-load ✅
- Codex understanding readout ✅
- Trees unlocking at levels 5 and 10, feeding the battle command menu ✅
- Archetypes weighted per theme, so a knight's trees come out sharp ✅
- Throwaway foes scale with `raise_quietly` and never pollute the world's tree registry ✅

## M3 — The world and walk mode — SHIPPED

- `World` — ground, places, the step clock, serialisation ✅
- `WorldGen` — noise ground, scattered sites, gates ranked E–S, seeded doctrine ✅
- Walk scene: tile-by-tile movement with hold-to-repeat, camera follow, map rendering ✅
- Site interactions: rest, read, delve, climb ✅
- Live readout of where you are and how dangerous it is ✅

## M4 — Encounters and procedural battlefields — SHIPPED

- Encounter roll driven by distance to the nearest open gate and nearest hearth ✅
  (measured: 37% in a gate's mouth, 1% at the starting village)
- Battlefield generation from the world terrain you were standing on ✅
- Enemy composition and levels scaled to party level and local danger ✅

## M5 — Gates and delves — SHIPPED

- Stepping on an open gate fights its garrison and its guardian ✅
- Clearing shuts the gate and pays out; the world reopens gates over time ✅
- Multi-floor delves: a gate's rank sets how many fights deep it goes, retreating keeps the floors
  you took and losing gives them back ✅
- Floor delve rewards: charm finds, generated skill tree discoveries on deep delves (rank C+), and written doctrine ✅

## M6 — The Tower — SHIPPED

- One battle per floor, escalating and never scaling down to meet you ✅
  (measured: floor 1 fields level 5, floor 6 fields level 15)
- Permanent floor log on the world ✅
- Floor rewards: gold every floor, doctrine every third, a new tree every fourth ✅
- A reason to stop: a floor's gold goes into `world.tower_hoard`, not the purse. It is banked by
  walking off the Tower and lost by losing a floor, so every extra climb is a decision about what
  you are already carrying ✅
- The Spire Apex: Floor 10 climax battle, hoard claiming, ascension vigour, and conclusion in the Museum ([D25](06-decisions.md)) ✅

## M7 — The Library and doctrine — SHIPPED

- Reading at a library; per-character knowledge ✅
- Entropy pass folded into walking ✅
- Teaching between party members, on the party screen ✅
- Each character's shelf shown, with anything close to fading marked ✅

## M8 — Fit to play — PARTIAL

- World in the save file, verified by a round-trip test ✅
- A real class picker on the party screen ✅
- Party screen: class choice, teaching, the Training Yoke, the Codex readout ✅
- The run ends when the party is gone ([D13](06-decisions.md)) ✅
- Every run generates its own world, with the seed readable from the menu ✅
- A seed can be typed in on the character select, so a country can be gone back to ✅
- **Remaining:** a balance pass across levels 1–10, now that abilities and gear have grown
- ✅ Done when: two people can play a session without hitting a wall

## Deferred

Designed for, seams in place, not built. See [Vision](01-vision.md).

- LLM character minds and an NPC society living off-screen
- Chronicles: narrative records generated from telemetry
- Renown, bounties, the Masquerade
- A server as world-authority
- Generated tile art wired in from `art/map_kit`
