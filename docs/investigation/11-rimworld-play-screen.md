# 11 — RimWorld's play screen, for Earth Kings

`doug-md`, 2026-10-18: "take inspiration from the game rimworld on the player screen ui and see what
you can add to earth kings, what works and what doesnt work for earth kings". What RimWorld puts on
the screen while you play, piece by piece, held against what Earth Kings is: one company walking a
hostile land, fights where they are met, no colony to run and no clock ([D49](../06-decisions.md)).
Built so far: [D244](../06-decisions.md) and [D245](../06-decisions.md).

## Kept

| RimWorld | What it does there | In Earth Kings | Status |
| --- | --- | --- | --- |
| The colonist bar | A portrait of every colonist across the top, marked when they are downed, starving or about to break | The company panel under the compass: face, name, level, a health bar going green to amber to red, and a **!** beside anyone with a path or a power to take | Built ([D244](../06-decisions.md), the mark [D245](../06-decisions.md)) |
| Alerts | A short list down the side of what needs doing ("Colonist needs rescue", "Need meal source"), hover for why, click to go there | Under the company: someone badly hurt, nothing in the packs to mend with, one of yours held for ransom, a town under attack, a path or a power owed, an X on the map. Hover for the detail; press to open the party screen or set the compass on it | Built ([D245](../06-decisions.md)) |
| The resource readout | Silver, food and medicine counted at the top left | The purse, and how much food and draught is in the packs | Built ([D245](../06-decisions.md)) |
| Letters | Big events stacked as envelopes on the right (red for danger, blue for news), opened to read | The world's big moments (a gate waking, a town besieged, one of the sixteen's lights going out) kept as a short stack to read when ready, not only a line in the log that scrolls away | **Planned** |
| The inspect pane | Click anyone or anything for a small card of what it is and how it is | Click a person, band or prop on the ground for a card: who, level, faction, what they carry or want | **Planned** |
| Tooltips with sums | Hover any number to see what made it (base, gear, health) | Attack, guard and health on the party screen broken down: class, level, gear, charms, scars | **Planned** |
| Speed keys | 1 to 4 for speed and Space to pause, anywhere | The fight has T and Space; the ground could take the same keys | **Planned** |

## Cut

| RimWorld | Why not here |
| --- | --- |
| The date, hour, season and temperature | The world has no clock and moves on at milestones ([D49](../06-decisions.md)); seasons are hidden in the First Hour ([D97](../06-decisions.md)) |
| Mood and needs bars (food, rest, recreation) | Needs every few minutes are busywork in a game about dangerous choices (the games' cut list, #270, cut 3) |
| Work, Schedule and Assign tabs | There is no colony to set to work; the company walks with you |
| The Architect menu | The town of your own is built by Muck Muck for what you bring him ([D224](../06-decisions.md)), not laid out block by block |
| The Research tab | Powers are found and practised (trees, doctrine), not researched |
| Overlays (beauty, temperature, roofs) | Earth Kings has none of those systems |
| History graphs | The journal's record of the run says it in words |
| Drafting colonists to fight | The party follows its lead and every fight starts where it is met, in real time |
