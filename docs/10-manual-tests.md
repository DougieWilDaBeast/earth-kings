# 10 — Manual tests

The smoke tests in `tests/` cover logic, data and persistence. They cannot see the screen, hear
the speakers, or press a key. Everything below needs a person.

Run the game with:

```
& "C:\Dev\Godot_v4.7.2-stable_win64_console.exe" --path c:\Dev\earth-kings
```

Mark each line **pass**, **fail** or **not reached**. A fail is worth more than a note — say what
you saw, on which screen, and what you had done just before.

---

## A — Boot and menus

| #   | Do this                                                                      | Expect                                                                                                         |
| --- | ---------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| A1  | Launch the game                                                              | Straight onto the title card: the logo over the sixteen falling, and "Press any key" ("Tap to begin" on a phone); no map pass or second title before it ([D87](06-decisions.md)) |
| A2  | Press a key or click on the title card                                       | The logo slides to the corner and the menu in down the left |
| A4  | Hover each menu entry with the mouse                                         | A soft tick on each one, and the keyboard highlight follows the mouse                                          |
| A5  | Click an entry                                                               | A firmer click, distinct from the hover                                                                        |
| A6  | Sit on the title screen                                                      | Quiet music, sixteen streaks falling towards the world, the Tower's light pulsing on the horizon; nothing runs along the bottom |
| A7  | Look at the crest above the title with a save present                        | It is the face of the character you are actually playing, not always the swordsman; Continue's line names them |
| A7a | Title → **Extras**, then `Esc`                                              | Training Ground, Coliseum, Museum, Credits and Back in place of the main list; `Esc` (or Back) returns to it with Extras chosen |
| A7b | Resize the window, very wide and very tall, on the card and on the menu      | Nothing is cut off: the logo stays inside the screen and the menu keeps clear of the land at the bottom |
| A8  | Delete `%APPDATA%\Godot\app_userdata\...\earth-kings.save.json` and `earth-kings.save.bak.json` beside it, and relaunch | Continue is greyed out; the founders run along the bottom instead                                              |
| A9  | In game, `Esc` → drag **Sounds** down, then hover a button                   | The tick is quieter; at the far left it is gone, and the music is unchanged                                    |
| A10 | Press `F11`, then quit and relaunch                                          | Fullscreen, and still fullscreen after the relaunch; the menu button reads "Fullscreen: on"                    |
| A11 | Press `F11` again, or click the menu's fullscreen button                     | Back to a window, and the button follows                                                                       |
| A12 | Title → **How to Play**, scroll, press a section button, then `Esc`          | Seven sections from walking to the party screen; the button jumps there; `Esc` shuts the page and the keyboard is back on the menu |
| A13 | In game, `Esc` → **How to Play**, then `Esc`                                 | The page opens over the menu; `Esc` shuts the page and leaves the menu open                                    |
| A14 | Start a run with tips reset (`Esc` → **Reset tips**) and walk a few steps    | A small card under the top bar about walking, then one about the clock; it fades on its own and never stops a key |
| A15 | Walk into a village, a fight and a gate; press **Got it** and **No more tips** | One card per first meeting, never twice; after **No more tips** none come, and the menu reads "Tips: off"      |
| A16 | Press `Q` with tips reset                                                    | No card while the game plays itself; the tips are still owed when you take the party back                      |
| A17 | Save twice, cut the save file in half in a text editor, relaunch and Continue | The run comes back as of the save before; a line at the top says it was restored from the backup             |
| A18 | Set `"version"` in the save to `99`, relaunch and Continue                   | Nothing loads; a line at the top says the save is from a newer version; the file is unchanged                  |
| A19 | Title → **Credits**; scroll with the wheel and with `W` / `S`, then `Esc`    | The founders, Godot's licence, music, sound, art, fonts and tools; `Esc` (or **Back to Title**) returns to the title |
| A20 | In game, `Esc` → **Credits**, then `Esc`                                      | The same credits in the menu; `Esc` goes back to the menu, not out of it                                       |

## B — Starting a run

| #   | Do this                                                              | Expect                                                                               |
| --- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| B0  | New Game, answer the questions and begin                             | The opening plays ([25](25-the-opening.md)): thirteen shots with narration, your lead the one who lands; click or Space moves on a shot, Esc skips to the landing |
| B1  | New Game                                                             | Twelve heroes, gentlest first, each with its rating on the button (Steady → Ruinous) |
| B2  | Arrow through them                                                   | Portrait, warband, stats and blurb all change to match                               |
| B3  | Type `12345` in the Seed field and start                             | A run begins                                                                         |
| B4  | Note the world seed in the system menu, start again with that number | The same country, same places, same names                                            |
| B5  | Leave the Seed field empty and start twice                           | Two different countries                                                              |
| B6  | Type letters in the Seed field                                       | Treated as empty; a random country, no error                                         |
| B7  | Lose a run with the lead **dead** (Even or harder), then New Game → answer → _Show me all sixteen_ | That lead is not on the list any more |
| B8  | With every lead fallen, open _Show me all sixteen_ | "All of them have fallen." and **Begin a new sixteen**; it asks twice, then the quiz starts with everyone back |
| B8a | New Game, then answer the questions                                   | Falling sky behind; four marks at the top light one by one as each pair is settled; answers pick with the mouse, arrows or `1` / `2`; with three questions a pair, answering the same way twice skips the third |
| B9  | Start a run                                                          | The landing beat plays: a crater in the land you are standing on, no memory, Sky with Atlas, Bram pulling the lead out and pointing to Stormreach, the Tower off to one side, and "A new standing quest: Ascend to heaven". The compass points at Stormreach, 12 to 16 tiles off ([D101](06-decisions.md)) |
| B10 | Start twice with the same seed and lead, then with another lead      | The same crater both times; another lead lands somewhere else. Either way, the crater is **Where You Fell**, your Home, with the bed to upgrade |
| B11 | Press **N** → **Quests & the Fallen**                                | "Ascend to heaven" at the top with the Tower's floor; errands below; "N more carry the mark somewhere out there" |
| B12 | Rest at villages, or ask an innkeeper for news, until one of the others is mentioned | A line naming them and a place; a faint face on the map there, and a line under **The others who fell** |
| B13 | Walk to where one of them stands                                     | "_Name_, _title_, is here. They carry the mark you share." and **X to speak with** them; inside the place, they stand near the way in |
| B14 | Speak with them, ask them to walk with you                           | An Outward temper joins the first time (party room permitting); an Inward one says "Not yet" until the second meeting |

## C — The world map

| #   | Do this                                                                | Expect                                                                                       |
| --- | ---------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| C1  | Look at the whole map                                                  | **No white squares** anywhere — every castle, hut, grave, band and party marker is drawn art |
| C2  | Walk about for a hundred steps, watching new bands appear              | Still no white squares as bands spawn                                                        |
| C3  | Read the top-left and bottom-left text                                 | Small, out of the way, not covering the country                                              |
| C4  | Press **L**                                                            | The world log disappears; press again and it comes back                                      |
| C5  | Walk onto a village or keep and press **E**                            | You walk inside                                                                              |
| C6  | Walk onto a **library, hut, gate, Tower or your Home** and press **E** | You walk inside — all five have interiors now                                                |
| C7  | Press **E** on open ground                                             | "There is nothing here to walk into", not silence                                            |
| C8  | Press **N**                                                            | The Journal opens                                                                            |
| C9  | Open the map from the journal, put the pointer near one side and zoom all the way out with the wheel | The view moves one way only and settles; it never swings back and forth |
| C10 | Return to the title from a run                                 | The marker sits beside the chosen entry (New Game when there is no save), not beside Continue |

## D — The five new interiors

Walk each one end to end. For **library, hut, gate, tower, home**:

| #   | Do this                         | Expect                                                                    |
| --- | ------------------------------- | ------------------------------------------------------------------------- |
| D1  | Look at the floor               | Readable, not near-black, and the floor runs continuously to the door     |
| D2  | Walk to the exit                | You come back out onto the world map where you left it                    |
| D3  | Stand near each person          | They mutter to themselves in a speech bubble; background folk have no "!" |
| D4  | Open every chest                | Gold, and sometimes an item, each only once                               |
| D5  | Press **E** on the marked spots | A line of description                                                     |
| D6  | Walk into the props             | Nothing traps you in a corner or blocks the only route out                |

## E — Battle

| #   | Do this                                                                                         | Expect                                                                    |
| --- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| E1  | Move your lead several tiles                                                                    | They **run** — legs moving — rather than sliding                           |
| E2  | Move him around a corner                                                                        | He turns to face each leg of the path as he takes it, not only at the end |
| E3  | Move any other unit                                                                             | They slide as before, standing pose, no flicker or blank sprite           |
| E4  | Reach level 2 and pick a class                                                                  | Skills on the fighter's card in the next fight, not one                   |
| E5  | Walk into a band on the road, then win                                                          | Back on the road; the party carries its wounds (**P**), and anyone met for the first time has a page in the journal |
| E6  | Use the same move about twelve times across several fights                                      | "_X_ is practised with _Y_ now." and it starts hitting a little harder    |
| E7  | Check a healer's Mend after heavy use                                                           | Heals more than it did at the start of the run                            |
| E8  | Kill a kind of enemy nobody has killed before                                                   | "_X_ learns from the _Y_." and experience; the next one of that kind gives none |
| E9  | Fight the same kind five times with someone who never lands the blow                            | On the fifth, "_Z_ has helped with enough _Y_ kills to learn from them."  |
| E10 | Beat a gate's guardian or the Tower's apex fighter                                              | Everyone still standing "learns from" it, not only the killer             |
| E11 | Open **P** → Practice after a few fights                                                        | An **Arms** line for the weapon in hand, and **Learned from** listing the kinds, with assists part-way |
| E12 | Take an errand, then **P** → a companion → Practice → **Send**                                  | They leave the cards; the header says "1 away"; an **Away** line counts the steps                |
| E13 | Walk until they are due                                                                         | Notices on the map: word from the place, maybe a meeting on the road, then "is back with the company" |
| E14 | Try to send the lead, or the last companion beside them                                         | No button, and a line saying why                                                                |
| E14b | With a gate broken open or a town under siege, ask a village host for news while the board is empty | The news ends "…It is on the board.", and the board has that job; asking again does not post it twice |
| E15 | Look at who is for hire in a village near a keep, then one far from any                          | Mostly full names (Octavia, Cassius) near the keep; mostly short ones (Tavi, Cass) far out; each "of" a real place |
| E16 | Shut a gate, walk to a village that has heard, then open the journal                             | The greeting calls you "_Name_ the Gate-Shutter"; the journal shows it under **Known As**          |
| E17 | Press **Q** on the road and let the party walk itself into a fight                                | The fight starts running at once, never pauses itself, ends, and the walk goes on              |
| E18 | Read village boards until one posts a **Bounty**                                                  | "Bounty: _a creature_", a line about where it prowls, and gold — not a blank card               |
| E19 | Press **Q** on the map somewhere a lake or cliff stands between the party and the nearest gate     | The party walks round it and gets there, rather than pacing in front of it                     |

## E2 — The fight (real time, M11)

Every fight: walk into a band, a gate or the Tower. Or Title → **Training** → pick an enemy →
**Fight this**, or from the bench: `godot --path . res://tests/bench.tscn -- --scene=skirmish --play`.

| #    | Do this                                                     | Expect                                                                                   |
| ---- | ----------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| RT1  | Open the fight                                              | It starts **paused**, the whole field is visible above three party cards                 |
| RT2  | Right-click the ground with someone selected, still paused  | A line to where they are going; nothing moves until **Space**                            |
| RT3  | Press **Space**                                             | Everyone moves at once. Melee close in; ranged units keep their distance                 |
| RT4  | Right-click an enemy                                        | The selected unit goes after that enemy and nobody else                                  |
| RT5  | Select a unit, press **Q**, left-click an enemy             | A red range shows first; the unit walks into reach, a cast bar fills, the skill lands, and its card counts the cooldown down |
| RT6  | Press **A** on a unit                                       | "auto" leaves its card, and it stops using skills on its own                             |
| RT7  | Press **H** on a unit                                       | "hold": it stops walking to fights and only hits what is already in reach              |
| RT8  | Let a party member drop                                     | "is down — 12 seconds", a red ring counting down under them                              |
| RT9  | Right-click the downed ally with another selected           | They walk over, kneel, and after two seconds the ally is back up at a quarter of their health |
| RT10 | Press **T** during the fight                                | x1 → x2 → x3 → x5 → x1, and the fight plays at that pace ([D189](06-decisions.md))      |
| RT11 | Win or lose                                                 | Victory or Defeat, and after two seconds you are back where the fight started — the road, the training ground, the coliseum |
| RT12 | Fight in **Training**, then go back to the run              | **Your real party is untouched** — nothing from a training fight is written back         |
| RT13 | Let someone go down with auto-pause at its default          | The fight pauses itself: "Paused." after "_X_ is down"                                    |
| RT14 | Press **Z** twice, turn **A** off on a unit, use its skill  | When the skill comes back the fight pauses: "Paused. _X_'s _Y_ is ready."                |
| RT15 | On a phone (or touch set to On in the system menu), start a real-time fight | A column of buttons down the right: Pause, Speed, All, the four skills named for the picked fighter, Auto skills, Hold, Auto-pause |
| RT15b | On a phone held upright, walk a Tower floor, then start a fight | The ground fills the screen top to bottom; the bar sits under the place name and compass, the stick and buttons above the log, the log wraps inside the screen, and the fight's button column is under the bar ([D163](06-decisions.md)) |
| RT15c | On a phone, press itch's full-screen button (the phone turns on its side); open the menu, then start a fight on the ground | The menu fits the screen, its rows scroll, and Close shows at the bottom; the fight's buttons sit in columns above Act, Back and Next, none under them; turning the phone mid-fight moves them ([D240](06-decisions.md)). `tests/sideways_shot.tscn -- --size=844x390` checks the same |
| RT15d | On a phone held upright, open the party screen (P), each of its three pages, then the journal (N) | Nothing runs off either side: the roster sits above the open character with Strongbox and Close in the top row; the journal's list sits above the page and its ribbons wrap onto two rows ([D241](06-decisions.md)). `tests/sideways_shot.tscn -- --size=390x844` checks the same |
| RT16 | Tap a fighter, then tap an enemy, then tap empty ground     | Picked; goes after that enemy; walks to the spot. Tapping a companion picks them instead of ordering |
| RT17 | Tap a skill button, then its target; tap a skill button twice | It is cast at the target; tapped twice, it is put away again                            |
| RT18 | Look at the party cards; hover one                          | A ✦ line of passives under each name; hovering the card lists what each one does          |
| RT19 | Hover an enemy                                              | A panel top right: health, its role (Charger, Skirmisher, Mender, Brawler) and its passives |
| RT20 | Watch a few blows land                                      | Numbers jump off whoever is hit and they flash; a critical is a big gold number, a short freeze and a shake |
| RT21 | Use a skill and watch its tile on the card                  | A dark wedge winds away clockwise with the seconds on it; the tile flashes when it is back. Clicking a tile picks that fighter and readies the skill |
| RT22 | Let a party member's near-death run out with nobody helping | Their card shows the chance a grace saves them; sometimes "Pulled clear!" or "The charm holds!" and they are back up at a quarter health, otherwise they fall |
| RT23 | The same on the road, with a charm on them                  | If the charm saves them it is gone from them afterwards; if nothing does, they are taken or dead for good (or pulled clear on Gentle) and leave the party when the fight ends |
| RT24 | Win with someone still down in their twelve seconds         | "_X_ is carried off the field."; back on the road they are alive on one hit point          |
| RT25 | Fight a gate floor whose objective is the keeper or the heart | The objective is said in the log; downing the keeper, or standing a party member on the marked heart, wins at once |
| RT26 | Get ambushed on the road (brush, forest or marsh)          | "Ambush!" in the log; the party moves before the enemy does                               |
| RT27 | Press **Esc** mid-fight, wait, close the menu; press **N** | The clock does not run while the menu is open; **N** opens the journal                    |
| RT28 | Drink a draught on the road, then check the stash          | It is gone from the stores; in training the stores are untouched                           |
| RT29 | Fight brigands and an archer                                | Brigands sprint in with "Charge!"; the archer "falls back" when someone closes in       |
| RT30 | Hold the left button and drag across two or more of the party | A gold box follows the mouse; letting go picks everyone it touched, never an enemy. With **Shift** they are added to who was picked. A box over empty ground changes nothing |
| RT31 | Leave Auto Skill on and watch a card's energy pips          | They drain as skills go off; at empty the card says "tired", only basic attacks follow, and skills come back once the pips reach half |
| RT32 | Fight a pig warlock or legion magus; Shield Bash it mid-cast | Its Pyre or Thunderhead winds up for 2.5–3 s; the bash pops "Interrupted!", stars circle its head and the spell never lands |
| RT33 | Hurt someone, then click Herbs on their card                | A pink bar fills for 1.5 s while they stand still; a stun pops "steady" instead; then they mend and the count drops |
| RT34 | Let brigands swing at a shield bearer from the front        | Now and then "Blocked" and no damage; never from behind |
| RT35 | Press **Q** on the road, let it walk into a fight, then press **Q** mid-fight | "You take the party back."; the fight pauses for your first order and Q did not ready a skill |
| RT36 | Look at the skill tiles on a card with long names (Shield Bash, Warding Touch) | Each name fits its tile, shrunk or on two lines; none is cut off |
| RT37 | Fight with the sound on: swing, shoot, use a skill with a wind-up, block with a shield bearer, stun, drink a draught, win and lose | Each is heard: swings and twangs, thumps on a hit and a crack on a critical, a clang on a block, a rising hum then a burst, a chime on a heal, gulps, a low fall when one of yours goes down, a fanfare or a sinking chord at the end; a crowd swinging is a clatter, not a roar ([D76](06-decisions.md)) |
| RT38 | In a fight, click the gold word beside a fighter's name; then pick someone and press **O F B G H** in turn | The word steps Own way, Close in, Keep away, Guard, Hold and round; each key sets its stance, said over their head and in the log; Close in walks off after foes, Keep away steps back, Guard walks back to the leader, Hold stands; the next fight opens with the same words; press **Q** and the words grey out ([D209](06-decisions.md)) |
| RT39 | Meet a band of three or more on the ground and hang back a moment before closing | They walk up in a shape round their boss (three a wedge, four a diamond), "falls in" over the ones moving to their slots, the shape facing you; once any of them is on you they fight as before ([D315](06-decisions.md)) |
| RT40 | Meet a band on the land with some coin in the purse; right-click beyond the field's edge with everyone picked | "Making for the edge of the field. Whatever is dropped in the running stays dropped."; each who reaches it loses a tenth of their health ("… gets clear, with a parting blow for it"), never falling; once all are clear the purse is a tenth lighter and the band is still out there ([D319](06-decisions.md)) |
| RT41 | In a fight with two or more of the company, let one go down and give the others no orders | The nearest one says "goes to" and kneels by them; the rest turn on the foe nearest the fallen; they are back up in a few seconds (D326) |
| RT42 | In a fight, pick one of the company, hold the middle button still, point at Stance and let go; then at Eat | Their stance moves on one; they reach for the least food in the pouch that mends them (D326) |

## F — Party menu (**P**)

Two panes: the party as a column of cards down the left, and one of them at a time opened out on
the right under Gear, Powers and Practice. Every target is sized for a thumb.

| #   | Do this                                                | Expect                                                                                                |
| --- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| F1  | Open it                                                | A card a person: face, name, level and calling, and a health bar that is green, amber or red          |
| F2  | Press a card, anywhere on it                           | The right-hand pane opens that person; the card is the only one with a lit edge                       |
| F3  | Tab through the cards with a keyboard                  | The pane follows the focus — keyboard and thumb point at the same card                                 |
| F4  | Press ^ / v beside a card                              | They swap places in the marching order; the arrows are dead at the top and bottom of the line          |
| F5  | Look at a card for somebody owed a class or a power    | An amber edge and one line saying which                                                                |
| F6  | Gear page, look at any row in the packs                | `Atk 29 » 31` and `Grd 12`, each coloured on its own — armour that buys guard with attack says both     |
| F7  | Open the lead's gear page carrying nothing             | Worn names the blade their template came issued with, not "nothing" — and the swaps are measured against it |
| F8  | Equip that piece                                       | The numbers land where the row said they would, and what they were carrying goes into the packs — **nothing is destroyed** |
| F9  | Give a longbow ranger a Sworn Blade piece              | "wrong hands" in the summary, and a visibly worse change than giving it to the swordsman               |
| F10 | Press **Optimise**                                     | The best piece in the packs goes on in one press; the button then greys out                            |
| F11 | Press **Optimise** with nothing better in the packs    | Already greyed, and says so when held                                                                  |
| F12 | Stow a piece                                           | They carry nothing; the piece is in the packs                                                          |
| F13 | Food and physic, on somebody unhurt                    | "Nothing to mend."                                                                                     |
| F14 | Powers page at level 5                                 | A tree block: name, theme, and three rungs marked • taken / ◊ locked                                    |
| F15 | Powers page below level 5                              | Told which level the first path arrives at                                                             |
| F16 | Powers page with a power owed                          | The next rung of every uncovered tree becomes a **Take** button                                         |
| F17 | Practice page                                          | What they have read, every move with its proficiency, and who they can teach                           |
| F18 | Level somebody to 2                                    | A path to choose, on the card and at the head of the pane, until it is answered                        |
| F19 | Save, quit, load                                       | Gear, packs, practice, trees and the marching order all exactly as they were                           |
| F20 | Shut a gate, then open the party screen                | A **Send** button beside every card but the lead's; it opens "Send … on a mission": **Meet me at** (press it to cycle the towns you know), the gates and errands ([D300](06-decisions.md)) |
| F21 | Send someone to a gate to meet you at a town, and walk elsewhere | The map shows their face on the road with a line ahead of it; when they are back, "A crow finds the company: … are back at …"; walk to that town and they fall in ([D300](06-decisions.md)) |

## G — Gates and the Tower

| #   | Do this                                   | Expect                                                                                        |
| --- | ----------------------------------------- | --------------------------------------------------------------------------------------------- |
| G1  | Stand beside an open gate and press **E** | The hint said "E to enter Greyhollow (rank E)"; a fight, and the log says which floor of how many. Walking onto the gate's tile starts nothing ([D116](06-decisions.md)) |
| G2  | Win the first floor of a multi-floor gate | You are told there is more below, and the gate is **not** shut yet                            |
| G3  | Step away from the gate between its floors | You walk out; the floors won are kept, and E at the gate again goes on with the next ([D115](06-decisions.md)) |
| G4  | Clear the last floor                      | The gate shuts and pays out                                                                   |
| G5  | Lose a floor                              | You are put out; the gate stays open                                                          |
| G5a | Before any gate is shut, stand at the Tower's door | "Nobody climbs without the Guild's mark", no climb offered; Sennet opens the Guild's board ([D101](06-decisions.md)) |
| G5b | Climb floor 1 to 5                        | The floor's own ground, not a fight screen: bands with red ground, fought where you meet them; the compass points at the stair; on or beside the stair the prompt says "E to climb to floor N", and E goes straight to the next floor, not out to the yard ([D102](06-decisions.md), [D114](06-decisions.md), [D115](06-decisions.md)) |
| G5c | On floor 5, walk at the stair             | The keeper of the fifth floor fights you; losing to it with Atlas alone can end the run        |
| G5d | As Atlas, step on the glint by the wall on floor 5 | "Chapter one: The Weight" plays; the journal's Quests page shows it under _What has come back_; it is never found again, and another lead never sees it ([D103](06-decisions.md)). The same as Cato, Janus, Bellona, Cassius, Saturn, Pluto, Ultor or Liber finds their own keepsake and chapter one there ([D135](06-decisions.md), [D138](06-decisions.md), [28](28-the-first-hour.md#the-chapter-ones)) |
| G5e | Beat the floor 5 keeper                   | Chapter one closes and the party is back in the Tower's yard in Stormreach; the door climbs on from the highest floor reached ([D115](06-decisions.md)) |
| G6  | New Game on a fresh install                        | No quiz: Atlas lands, after the opening, on the First Hour setting; after his world ends the quiz picks the next lead ([D104](06-decisions.md), [D106](06-decisions.md)) |
| G6a | Lose a fight with the lead                         | The death screen has **Ascend** selected; Reload is one step to the right ([D105](06-decisions.md)) |
| G6b | Auto from the crater                               | Walking into Stormreach, Sennet says the mark is earned at a gate and names Greyhollow; the compass names Greyhollow and Auto walks there, not to the Tower's door ([D161](06-decisions.md)) |
| G6c | Stand at the runes under the Tower                 | The hint says how to climb (or why the stair is shut); the Tower rises tall over the door; from the crater a tall shape stands on the screen's edge towards it ([D108](06-decisions.md)) |
| G6d | On floor 5 as Atlas, before the buckle             | The compass says "Something glints" and points at it; once picked up it points at the stair ([D107](06-decisions.md)) |
| G6e | Die as Atlas, Ascend, answer the quiz              | The opening plays again, shorter: Atlas grey in the ring, his world going dark, "Fifteen are still standing", then the new lead lands ([D135](06-decisions.md)) |
| G6f | Shut Elderford (north of the city), then die and Ascend | The register listed Greyhollow and Elderford; in the next crater Bram dreams of somebody who shut Elderford and went up ([D147](06-decisions.md)) |
| G6g | Auto on floor 5 as Atlas | Auto walks to the buckle before the stair; at the keeper the fight opens paused, "Auto stops here: this fight is yours."; win it and Auto walks on ([D150](06-decisions.md)) |
| G6  | Climb a Tower floor                       | The gold is a **hoard**, not in your purse — "you are carrying N out of here, if you get out" |
| G7  | Climb a second floor without leaving      | The hoard grows, and you are warned what you stand to lose                                    |
| G8  | Walk off the Tower step                   | "You walk away from the Tower with N silver" (or gold) and the purse goes up                              |
| G9  | Lose a floor while holding a hoard        | The hoard is gone                                                                             |
| G10 | Win floor 5                               | "Chapter 1 of the Tower is behind you", the census ("sixteen still stand"), news of gates opening, and "The stair above is sealed" |
| G11 | Step onto the Tower again                 | The seal line, and no fight                                                                   |
| G12 | Shut a gate (or save a town), then come back | "The Tower opens onto floor 6 of 10 — chapter 2 of 2", and the fight starts                 |
| G13 | Step onto a gate whose objective is _Reach the heart_ | The log names it; a lilac cell sits behind the enemy line; standing on it wins the floor with enemies still up |
| G14 | Reach the last floor of a _Slay the keeper_ gate | Felling the guardian ends the fight at once, and the gate shuts                     |
| G15 | Stand on a village or keep and press **Y** | The Guild hall: every gate not yet shut, worst first, with state, floors, objective and bearing |
| G16 | Take a contract on an open gate, then shut that gate | The job log shows "shut …"; shutting it pays the contract on top of the gate's own spoils |
| G17 | Walk into a village or keep and talk to the Guild clerk | The same Guild hall opens; closing it gives control back |
| G18 | With an S-rank gate open, walk on until an upkeep passes, then open the Guild at the nearest hall | "The Guild is raising a muster…" in the log; the muster's strength at the top of the hall |
| G19 | **Stand with them**, then walk into that gate | "N of the muster go into … beside you"; blue-ringed allies on the back row fight with you |
| G20 | Stand with a muster, then send a companion on it from the Practice page | They wait at the hall ("waiting with the muster"); when it goes in they come back paid, or roll for their life |
| G21 | Climb past floor 10 (floor 11, then 12) | Each floor is a run of chambers of its own, bigger than floors 1 to 10, the stair at the far end and a band in every chamber but the first; floor 12 says another company is on it, and they fight beside you ([D307](06-decisions.md)) |
| G22 | Climb to floor 25 | People stand by the way in and talk: they live here and are not going higher; no company fights beside you on it ([D307](06-decisions.md)) |
| G23 | On floor 25, hurt, speak to the first and the second person by the way in | The first offers *Let us rest here* for 1,500 copper and mends everyone; the second sells bread, herbs and a red draught at half again the Market's price, and again after you buy ([D317](06-decisions.md)) |
| G24 | At the Tower's foot, look at the sword in the floor; then look again | One pull: one time in six the lightning goes out and a Silver Blade is handed to whoever gains most; else the stone keeps it; the second look says you have had your pull, and a new run is a new throw ([D318](06-decisions.md)) |

## D2 — Towns, wilds and the people in them ([D62](06-decisions.md))

Walk **the ford village** first, then any other village, a wild area and a gate.

| #    | Do this                                                   | Expect                                                                                         |
| ---- | --------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| D2.1 | Look round                                                | Houses drawn as houses, about three tiles wide; trees about three people tall; birds, mushrooms and bugs small |
| D2.2 | Walk behind a house and behind a tree                     | You pass behind them, not over them; you cannot walk through a tree trunk, a well or a lamp post |
| D2.3 | Walk into a house with no inside                          | A line of its own ("Closed. A note on the door…"), not a blank refusal                          |
| D2.4 | Speak to **Hesk the Stallholder**, ask a question, then buy a loaf | The question is answered; the loaf costs gold and goes in the packs; the loaf is then gone from the list |
| D2.5 | Speak to **the fox in a stolen hat**                      | It will not talk; toss it a coin and it will, and it stays willing next time                   |
| D2.6 | Speak to **Dunmore the Smith** a few times                | Sometimes he is too busy; working the bellows (a Might roll) can win him over                   |
| D2.7 | Take **Wat**'s favour, look at the grey stone by the pond, go back to him | The stone is only there once the favour is taken; he pays 7 silver 50 copper and a Hearth Coin, once |
| D2.8 | Look at a gate, the Tower, the salt hamlet's lighthouse   | The portal glows, the Tower's runes pulse, the lighthouse beam sweeps                           |
| D2.9 | Look at the world map                                     | Gates are portals, villages cottages, huts a log lodge; no cream squares behind any castle      |
| D2.10 | Walk every exit of a wild area                           | Nothing laid down blocks the road out                                                          |
| D2.11 | In Stormreach's streets, find **Muck Muck** by the ruined bathhouse and ask why everyone asks him | He is the builder they come to whenever something needs building ([D176](06-decisions.md)) |
| D2.12 | Get someone hurt, then find **Sinner** at the old shrine and ask her to patch up your companions | 10 silver is taken and everyone's health is full; asked again with nobody hurt, she only looks you over, free |
| D2.13 | Walk into the wind scarp and up to one of its shelves | The shelf's edge has a dark rim and a shadow below it; the lead stops at it ("The shelf is too high to climb here. Find a slope."); at a slope they walk up; off any edge they drop down, and the followers file to the slope ([D308](06-decisions.md)) |
| D2.14 | In any wild, walk its open ground off the straight ways and stand on the three places its story is told (near what it speaks of) | Each page is said once; the third says the whole story ("The ancient grove: a woodcutter came forty days ...") and the annals carry it; walking the pages again says the lines but writes nothing ([D314](06-decisions.md)) |
| D2.15 | Rest at a village, then walk into a wild you have not cleared, with fewer than three errands | On the way in: "Something keeps the hush wood. Clear it, and the host at ... will pay to hear it. It is among your errands."; the errand points at the wild and is handed back at that village; the village's board never posts the same wild ([D316](06-decisions.md)) |

## D3 — A band on the ground ([D66](06-decisions.md), [D68](06-decisions.md), [D72](06-decisions.md))

Start a run and walk until the bottom line says a band has marked the ground it can see.

| #    | Do this                                              | Expect                                                                                  |
| ---- | ---------------------------------------------------- | --------------------------------------------------------------------------------------- |
| D3.1 | Look round                                           | The band on the ground with its name over it; the cells it can see a red grid with a rim; you are not inside it |
| D3.2 | Watch it for ten seconds                             | It walks a small loop, resting at each stop, the red moving with it                      |
| D3.3 | Walk up close without entering the red               | They turn to watch you; nothing starts                                                   |
| D3.4 | Walk through long grass right up to them             | Long grass is never red; step out of it into the red and the fight opens with "Ambush!"   |
| D3.5 | Step onto a red cell                                 | "… have seen you!" and the fight is on at once ([D204](06-decisions.md)), on the same ground at the same zoom, everyone where they stood, the band closing in fighting; no box and nothing dimmed. Move the pointer well away from the fight: a faint edge shows where the company can get clear |
| D3.6 | Win the fight                                        | Back on the same ground, on the spot you were seen; the band gone from the ground and the journal's map |
| D3.7 | Walk towards a band two tiles away                   | It is already on the land, patrolling its own patch, before you reach it ([D84](06-decisions.md)) |
| D3.8 | Meet a scene on the road ("A cart has been stopped…") and step in | The fight is on the road where the scene stands, the attackers where they were; no fight screen ([D207](06-decisions.md)) |
| D3.10 | Walk the First Hour's road from the crater to the first gate | Two or three bands camped a little off the road on the way, some of them brigands, none on the cobbles or at a town's gate ([D215](06-decisions.md)) |
| D3.11 | Walk the roads a few tiles out from a town for a while | Now and then "The Watch is fighting on the road ahead": two watchmen back to back with brigands or wolves round them. Step in and they fight beside you, then pay you; walk on and it costs a little renown ([D215](06-decisions.md)) |
| D3.12 | Look along the road, and climb to floor 2 or above | A company of two or three climbers walking the road, who talk ("Another one for the Tower?"); on some floors a company resting by the stair ([D215](06-decisions.md)) |
| D3.13 | Esc → the menu's **Auto: Mixed** button, pressed three times | Aggressive, Passive, Mixed in turn, each with a line on what it does; the choice is kept after the game is closed; the top bar says "Auto: Aggressive" (or the rest) while Auto is on ([D216](06-decisions.md)) |
| D3.14 | Switch Auto on near a band, once in each style | Aggressive turns aside and walks into its red; Mixed walks its way and fights only if seen; Passive walks round the red ([D216](06-decisions.md)) |
| D3.15 | Walk the road until a roadside scene comes up (with Auto on, too) | Its title in the log and the scene standing well down the road; no box, and Auto keeps walking. Close to it, what is happening there in the log and "E to step in, or walk on by" ([D216](06-decisions.md)) |
| D3.16 | Fight a band at 5×, changing the speed during the fight | The view stays on the fight, no jumping side to side, and never goes black ([D246](06-decisions.md)) |
| D3.17 | Watch two melee fighters meet on a diagonal | One of them swings; they do not step sideways together over and over ([D246](06-decisions.md)) |
| D3.18 | Walk into a town with lots to do, then watch the log | The line along the bottom stays one line (ending in "…" if it is long); log lines go after about eight seconds; neither runs over the other ([D246](06-decisions.md)) |
| D3.19 | Press E at a gate six or more levels above the company | A line saying how strong its keepers are; E again within four seconds goes in. Auto never goes in ([D246](06-decisions.md)) |
| D3.20 | Climb to a floor with a company resting on it, and fight a band near them | They sit round a fire; when the fight starts near them, "… join the fight." and they fight beside you ([D246](06-decisions.md)) |
| D3.21 | Walk to the first gate and press E beside it | No fight at the doorway: a floor of rock chambers opens, the gate's own look, bands standing in the chambers past the first, the compass on the way down; one line in the log about the red ground ([D248](06-decisions.md)) |
| D3.22 | On a gate of two floors or more, fight through to the far end and press E at the way down | The floor is paid out and the next floor opens straight away; walk back out of its doorway and you are at the gate, and E goes on from the floor reached |
| D3.23 | On a gate's last floor, walk to the way down before the keeper falls | "The way down will not open while its keeper stands"; the compass points at the keeper; beat it and E at the way down shuts the gate |
| D3.24 | Lose a fight inside a gate | Back outside at its mouth with the floors filled in; going in again, its first floor's bands stand again |
| D3.25 | Walk into Stormreach for the first time (Sennet's line), then on a touchscreen | The box at the bottom is only as tall as Sennet's lines and no wider than it needs; a one-line remark is a small box; the hint strip is as long as its line ([D259](06-decisions.md)) |
| D3.26 | Walk the land until "Something has been left here", and look at what lies ahead | Coin alone is a coin pile; a blade, bow or staff is a sword lying there; anything else a strongbox ([D259](06-decisions.md)) |
| D3.27 | Stand out of a band's red with it a few strides off, and press G | The bottom line says "G: strike first"; the lead turns to it and glows for a moment, then the fight is on: "First strike!" over the lead and a big hit on the nearest of them before they move ([D300](06-decisions.md)) |
| D3.28 | With Auto on, walk into a band two levels over you | No stop and no paused fight: "A hard one. Auto fights on" and the fight runs; Q takes the party back. A gate's fight still stops ([D300](06-decisions.md)) |
| D3.29 | Meet your first band of a new run with tips on | No tip card over the fight; the fight tips come up once it is over ([D300](06-decisions.md)) |
| D3.30 | Go into gates of rank C and up until one says "read … from outside. Inside, it is …" | Its label on the map gave the lower rank before; after, the true one ([D302](06-decisions.md)) |
| D3.31 | Go into gates until one says it "was a double gate", then walk back to its doorway | Its rank climbed one; "The way out is shut"; beat its keeper and the way out is open again ([D302](06-decisions.md)) |
| D3.32 | In a world after a lead has fallen, go into gates of rank C and up until one says "Something of a burned world holds …" | The map label and the keeper's fight name Demon King <the fallen lead>; the keeper wears their face and stands at or over the level they fell at; shutting it says what came through goes back to ash ([D304](06-decisions.md)) |
| D3.33 | Shut a double gate, then stand on open ground and press E | "the Gate Key" came out of the shut gate; the bottom line offers to turn it here; a gate of the shut gate's rank opens where you stand, open and walkable, and the key is gone ([D304](06-decisions.md)) |
| D3.34 | With three or more walking, open the party sheet (P) on the lead and tap *Formation* until it says *Column*, then walk up open ground | The followers file in behind the lead, a short step apart, facing the way the lead faces; through a door they fall back into a trail ([D305](06-decisions.md)) |
| D3.35 | Set *Formation: Diamond* and walk onto red ground a few strides from a band | Before anyone is in reach, the companions walk to their places round the lead ("falls in"), the mender behind; once a blow is traded everyone fights as their doctrine and stance say ([D305](06-decisions.md)) |
| D3.36 | Win three fights with the same company, then open the party sheet | One card says *leads the fights (3 won)*, not always the lead's; on the lead's sheet *Formation: Auto* names the shape they call for and whose call it is ([D306](06-decisions.md)) |
| D3.37 | Fight a band with a mender or an archer in it, and watch the leader's target | "Get the healer!" or "On the archer!" over the leader's head and in the log, once; the one named backs off for a moment and a foe steps in front of them ([D306](06-decisions.md)) |
| D3.38 | Watch a band of three or more patrol on open ground, then along a path through trees | In the open they walk as a wedge or a diamond round the one in front, facing the way they go; through the trees they file behind it; the fight opens with them in their shape ([D320](06-decisions.md)) |
| D3.39 | On the land hold the middle button still a moment; point at each of Eat, Formation and Party in turn and let go; then hold and drag | A ring opens round the pointer; Eat feeds the worst hurt food first, Formation says the next shape, Party opens the party screen; a drag still moves the camera and no ring opens (D326) |
| D3.40 | Send a companion on an errand with a town to meet in; open the party screen and the map; then press Let go beside another companion twice | Under the cards and beside the face on the map: tiles off and "back in about N steps"; Let go asks "Sure?", then the companion is gone and does not come back to the fire (D326) |
| D3.9 | Climb past floor 5 (floor 6 on)                      | A Tower floor you walk, laid out like one of floors 1 to 4, with two bands of the floor's own foes (named "Floor 6 — Cohort of …"); stepping into their red fights them on the floor; the stair climbs on ([D207](06-decisions.md)) |

## D4 — Atlas's last stand ([D191](06-decisions.md), once the tutorial of [D73](06-decisions.md))

Delete `settings.cfg`, `earth-kings.sixteen.json` and the save from the user folder first, to be a new player.

| #    | Do this                                               | Expect                                                                                  |
| ---- | ----------------------------------------------------- | --------------------------------------------------------------------------------------- |
| D4.1 | Open the game and press **New Game**                  | No offer over the title; New Game opens Hearthwick as Atlas, the card saying "The last day of Atlas's world", no **End tutorial** button |
| D4.2 | Follow every card                                     | Each step ticks "done" and the next comes up; the card never sits on the conversation box |
| D4.3 | Press Esc → Save during it                            | "Nothing in the tutorial is saved."; Continue on the title still loads your own run      |
| D4.4 | Reach the fight step, find the sparring pair south of the square, step into their red | Before the step they are not there; then they patrol with red ground. Stepping in opens a fight on the village ground, the card on the left; after it, back on the same spot and the pair gone |
| D4.5 | Walk the road south out of Hearthwick                 | Back at the title, the card gone; New Game starts the last stand again                  |
| D4.6 | Reach the last card, _The gate in the hills breaks_   | A band from the broken gate (the Frostbitten and two ice wolves) stands where the sparring pair stood, its red ground showing; no **Skip this step** |
| D4.7 | Step into the band's red                              | The card moves left; the company is down within seconds; the screen goes black and Atlas's fall is told, ending "Fifteen are left." and **Choose who comes next** |
| D4.8 | Press **Choose who comes next**, answer, pick         | The quiz never deals Atlas; the whole opening plays, its ending shot "Atlas fell in Hearthwick…", his ghost at the fire; you land on the road to the great city |
| D4.9 | Back at the title, press **Atlas's Last Stand**       | It plays again with **End tutorial** on the card; at the end, **Back to the title**, and nothing more is written down |
| D4.10 | Delete `earth-kings.sixteen.json` only, then **New Game** | "You've played Atlas's last stand before. Play it again, or skip it?"; **Skip it** goes to the quiz with Atlas fallen; **Back** closes the card |
| D4.11 | Count the cards from New Game to the doomed fight | Seven: walking, talking, buying, a favour, your company, the sparring fight, the gate in the hills ([D300](06-decisions.md)) |
## D5 — One land ([D84](06-decisions.md))

Start a run (not the tutorial) and walk.

| #    | Do this                                               | Expect                                                                                   |
| ---- | ----------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| D5.1 | Walk in one direction for a minute                    | The ground runs on with no edge, fade or pause; the place line at the top changes as you cross into new country, and the light turns with the land |
| D5.2 | Walk towards a village you can see on the map         | You see it from outside, standing in the land; walk straight in, and the bottom line offers hire, buy and the board |
| D5.2a | Stand in a market town with gold, press **Z** twice, then **B** | The bottom line names a different ware each time, "Z for the next of 3 wares"; B buys the one named ([D146](06-decisions.md)) |
| D5.3 | Walk to the coast or a mountain                       | Water or rock fills the tile; you cannot walk onto it                                     |
| D5.4 | Find a band (the bottom line names it) and stand still | It patrols its patch, further than a small loop; take a few steps across a tile edge and sometimes it sets off and walks to the next patch, its red going with it |
| D5.5 | Go into a house, open the journal's map, and fight    | Each time you come back exactly where you stood on the land                                |
| D5.6 | Open a chest in a village, leave, come back           | It is still open                                                                          |
| D5.7 | Click open ground a little way off, then click behind a house | The party walks there, round the house; pressing a key takes over at once ([D178](06-decisions.md)) |
| D5.8 | Walk across several tiles of the land | No stutter as you cross from one tile into the next |
| D5.9 | Look round any tile of open country, then walk up to a bird | Birds, butterflies and bugs about; the bird takes off as you come close, its shadow under it, and comes down a few cells away ([D179](06-decisions.md)) |
| D5.10 | Walk the road from the crater towards the city | Now and then two of the Watch walk it, saying a word at each end; click one to talk |
| D5.11 | Click the ground a few cells off, then click somewhere else before arriving | A gold pin where you clicked and a dotted line marching to it along the way; it moves to the new click, and is gone when you get there ([D189](06-decisions.md)) |
| D5.12 | Stand still near a bird for half a minute | Now and then it goes up on its own, flies a loop and lands somewhere else, without you coming near |
| D5.13 | Walk into Ada's bakery door (shut) and keep pushing | The shut door says its line once; the play log has the door once, not forty times |
| D5.14 | With a party of four or five above level 6, climb a Tower floor past 5 | Each band is five or six foes at about your level; the fights take a while and hurt ([D189](06-decisions.md), walked since [D207](06-decisions.md)) |
| D5.15 | In a fight you can win, let one of the party go down, get them back up, and win | At the end: "… will carry a scar from that … +3 health for good"; their journal page shows Scars 1, +3 health ([D218](06-decisions.md)) |
| D5.16 | Shut three gates of the same faction (the same keeper at the far side) | By the third at the latest, "{keeper} falls, and what it guarded falls with it: …" and the prize is worn or packed; a miss before says what it carries ([D219](06-decisions.md)) |
| D5.17 | Beat bands on the land until "a scrap of map … 1 of 3", then two more | "The 3 scraps fit. An X, … leagues …": a red X on the map (M), "The X on your map" in the quest list (L); walk there and a find is dug up, gear in it ([D220](06-decisions.md)) |
| D5.25 | Level someone to 2 and open their page (P) to choose a path; hover the **?** on a card, then press it | A box with the path in more words: what kind of fighter, what it grows, each starting move and what it does; pressing opens the same words on the card ([D237](06-decisions.md)) |
| D5.18 | Walk the land and look at the top right | A small square map with N, E, S and W on its sides, you in the middle, and an arrow at its edge (or a ring) for what the compass follows ([D232](06-decisions.md)) |
| D5.19 | Press M on the land, with Auto on | The map opens over the ground and the party keeps walking under it; WASD moves the map, not the party; M or Esc puts it away |
| D5.20 | Right-click open ground on the map, Go here | A green pin there, a dotted line to it, Auto turns on and the party walks there, past any band; on arriving Auto hands back and the pin is gone |
| D5.21 | Right-click, Place a marker; then press L | A numbered gold pin; L steps the compass onto "Marker 1"; click the pin to walk to it; right-click it to take it off |
| D5.22 | Walk out of a village along the land | A two-cell dirt track of pale packed earth runs off towards the next village; every other way across a tile is a narrow footpath ([D233](06-decisions.md)) |
| D5.23 | Follow a track to where three ways meet, and press E by the signpost | "A signpost." and, for each way, the nearest village or the Tower and how many tiles |
| D5.24 | On the road from the crater, walk off it into a band's red with two of the Watch close by | "The Watch see it start, and come running": two of the Watch fight beside you; won, they thank you and pay a bounty in gold ([D236](06-decisions.md)) |
| D5.26 | Walk the ground towards a town you have not seen (Coldrun from Stormreach) | It shows on the map (M) early, but "… comes into sight." is said only once it is about on screen, a tile off ([D238](06-decisions.md)) |
| D5.27 | Walk into a land you have not been in, then open the journal (J), Quests | "A new page in the journal: ..."; under _The lands_ its page, up to five lines with boxes; walk five tiles of it, stand at a ring of stones or a cairn there, beat two bands on it (and a place or gate if it lists one): each line says so as it is crossed off, and the last turns up its trinket in a box, carried on the page ([D239](06-decisions.md)) |
| D5.28 | Finish the bog's page (Heron Stilts), then walk at a pool on the bog's ground | The party walks through the pool instead of round it ([D239](06-decisions.md)) |
| D5.30 | Walk the ground with two or three in the company, one of them hurt | Under the compass, top left: a row each (face, name, level, health bar: green, amber under 60%, red under 30%) and the gold; press it and the party screen opens; it hides while talking and in a fight ([D244](06-decisions.md)) |
| D5.31 | Let one of the company drop under half health with nothing in the packs, and level someone to 2 | Under the company: "! … is badly hurt" in red, "! Nothing in the packs to mend with", "! … has a path to choose" in gold, and a ! beside their name; hover one for more; press the path's and the party screen opens ([D245](06-decisions.md)) |
| D5.32 | Walk the road from the crater to Stormreach and on to the Tower | No door: the city's south gate stands open ahead and its streets carry on from the land, two tiles by two inside its wall (the high street, market, tavern, Guild hall, toll house, Muck Muck and Sinner). Out of the north gate the Tower stands on its own just past the wall ([D247](06-decisions.md)) |
| D5.33 | Walk into the Gilded Flagon in Stormreach (or the Oasis Serai) | Behind the taproom a passage, a kitchen with an oven, and two or three bedrooms with a bed each ([D242](06-decisions.md)) |
| D5.34 | Ask Marta (or the innkeep) for a room, pay 10 silver | "Room two is yours for the night"; a gold pin on its bed, a dotted line to it, "Your room" under it, and the compass says Your room |
| D5.35 | E by another bed, then by yours | "Somebody else's room"; then a short dark, everyone patched up and "+4 health", a save; the pin is gone |
| D5.36 | Shut Greyhollow and talk to someone there with things to say; later, once word has walked to the city (a tile every 14 steps), the Watch or the innkeep in Stormreach | Before their hello: "You're the one who shut Greyhollow..." (or one like it), once; talk again and it is not said ([D249](06-decisions.md)) |
| D5.37 | Beat three bands of legionnaires on the land, then walk into a fourth's sight | After the third: "The Heart Empire have lost 3 bands to you now..."; the fourth sees you a cell further and shouts "That's them!" (or one like it), not "There!" |
| D5.38 | Raid a village, then walk into it and talk to someone with things to say | They bring up the burning, then turn you away more often than not; 4 silver or Hear me out gets you in |
| D5.39 | With Bellona walking with you, stand on the Tower's floor 5, then rest and sit by her at the fire | She tells of the gate she shut and asks for two things; the journal's quests page lists "Bellona's: Twenty" under _Their own_ ([D250](06-decisions.md)) |
| D5.40 | Stop for somebody on the road, then shut a gate, sitting by her at the fire after each | She says the twenty is given; after the gate, she finishes it, and "+2 guard, for good"; the journal says finished |
| D5.41 | Shut a gate, walk into Stormreach with 1 gold 50 silver and talk to Muck Muck | "Could you build something for us?" says the crater is your ground; "Build a smithy at the crater (75 silver)" and the same for an infirmary ([D251](06-decisions.md)) |
| D5.42 | Pay for both, then walk back to the crater | A stone smithy top left with Hald at the anvil, a whitewashed infirmary top right with Ness; the trees that stood there are gone. Hald sells gear, Ness mends for 6 silver 50 copper |
| D5.43 | Pay Muck Muck for the wall (1 gold 25 silver) and walk back | A timber wall round the crater with its gate south, two houses at the bottom corners, a well and two settlers; one of them has news |
| D5.44 | Walk into the Gilded Flagon with 60 silver and ask Marta "Let us keep room two for good" | 60 silver goes; room two is pinned "Your room" with the line to its bed, and she no longer sells a night ([D252](06-decisions.md)) |
| D5.45 | Sleep in room two, walk out and back in | Everyone patched up and a save; room two is still pinned as yours, with nothing to pay |
| D5.46 | Ask Steward Hobb (by the Margrave's hall) about the narrow house without a room, then with one and 2 gold 25 silver; then walk in at its door off the east street | First he says to take a room; then it sells for 2 gold 25 silver. The door, shut before, opens on your house: a hearth, your bed (sleep: everyone patched up, +6 health, a save) and the strongbox |
| D5.47 | Start a new game and look at the purse under the compass, then open the party screen (P) | "60 silver" in both; no amount anywhere says "gold" unless it is gold coins ([D253](06-decisions.md)) |
| D5.48 | Buy a loaf from Hesk, then win a fight and open a chest | The loaf costs copper ("20 copper"); the fight and the chest pay in silver ("17 silver 50 copper.") and the purse goes up by it |
| D5.49 | Load a save made before this build | It loads; the purse is 25 copper for each gold it had (250 gold becomes 62 silver 50 copper) |
| D5.50 | Climb as Atlas past floor 5 and walk floors 6 to 10 | Each floor is its own place (6 a long red gallery, 7 a watchtower stair, 8 bricked doors and a ruined square, 9 a walled yard with a well, 10 an antechamber before the last stair), two bands on each, the stair up at the top; none is a copy of floors 1 to 4 ([D254](06-decisions.md)) |
| D5.51 | On floor 6 as Atlas, follow the compass to "Something glints" (bottom left of the gallery) and step on it | A torn page corner; Atlas's chapter two, "The Last Page", plays, and the journal's quests page has a new line under _What has come back_; a lead other than Atlas, Iris or Juno sees nothing glint on floor 6 |
| D5.52 | Step into the Keeper of the Tenth's ground on floor 10 | It speaks before the fight ("Ten floors, Atlas…" on a first life) and fights with a goblin and an archer beside it; winning and taking the stair ends chapter two |
| D5.53 | With Pluto walking with you, stand on floor 5, sit by him at the fire; put down ten of one kind of foe, sit by him again; climb to floor 7 and sit by him | He opens "One at a Time" and the journal's quests page lists it; after the ten he says he knows how they move; on floor 7 he counts the company up the stair and "+1 attack and +1 guard, for good" ([D256](06-decisions.md)) |
| D5.54 | With Cassius and Caesar both walking with you past floor 5, lose a fight, then win the arena tournament, sitting by Cassius after each | His ending is the one with Caesar cheering loudest; a world where Caesar has fallen ends it with the handshake he never gave |
| D5.55 | Open the journal's quests page after floor 5 with four of the sixteen walking with you, sitting by each | Each has a story of their own, with its own title and two asks, none the same as Bellona's "Twenty" |
| D5.56 | Turn Auto on at the Tower's door at under 90% health, then again on floor 2 once hurt under 60% | At the door the party walks off to the nearest village to rest first; on floor 2 it walks back out the way in, rests, and comes back up to floor 2, not floor 1 ([D258](06-decisions.md)) |
| D5.57 | Go into a gate on snow, then one on ash, then a rank C gate's second floor | Snow ground with ice for walls; ash with lava; the C gate's second floor a different kind from its first ([D261](06-decisions.md)) |
| D5.58 | On a gate's first floor, walk past a band to the way down; then put the band down | "The way down will not open while anything on this floor still stands"; once it is down, the way down opens. Auto walks to each band in turn |
| D5.59 | Shut a gate, walk out, and walk back past it | "Folk ... come running as it falls, cheering"; the gate lies broken in its mouth and three folk stand there thanking you |
| D5.60 | Rest at a village a few times, then walk to the standing stone the host spoke of | "The host speaks of … It is marked on your map"; a standing stone appears on the map; E there walks into the wild place, which says what it keeps once, and the journal's annals have it ([D309](06-decisions.md)) |
| D5.61 | Hear of a wild place at rest, then rest again and read the board | *What keeps the hush wood* is on the board, paid for the walk; take it, clear the band by the wild's far chest, come back: "is settled" and the coin ([D310](06-decisions.md)) |
| D5.62 | In a world after a fall, climb as far as the dead lead did and walk to the crater | Half the time "Something was on it before the dust settled": a band stands over the crater; walking onto it says it will take a fight; beat the band and the weapon lies free; lose and another band is on it ([D311](06-decisions.md)) |
| D5.63 | On the wind scarp, stand on the bare earth below a shelf and click on the shelf; then turn Auto on | The party walks to the nearest slope and up it, never straight at the shelf; Auto makes for the way out by the slopes; a click on a shelf with no slope says "There is no way up to there from here." once ([D312](06-decisions.md)) |
| D5.64 | On the wind scarp, draw the guard into a fight at a shelf's edge; kick one of them off it, and have one kick you from below | Kicked off the edge: the body slides down a tile, "Off the edge", a tenth of its health gone, flat for a moment; kicked at the shelf from below: "Pinned", nobody goes up; the guard walks to the slopes to reach you, never straight up ([D313](06-decisions.md)) |
| D5.65 | Walk onto a cloud peak on the map (crag); climb the three heights by their slopes; walk at the clouds by the summit; draw the guard into a fight at the summit's edge and kick one of them towards the cloud | Three heights, each climbed only at a slope; the summit is snow, the clouds below it pale and drifting; walking at the clouds stops at the edge with "Below the edge there is only cloud" once; the foe kicked into the cloud says "Into the clouds" and is gone, counted as a kill ([D321](06-decisions.md)) | |
| D5.66 | Carry a Whetstone and two Bitter Herbs; open the party screen on someone with a weapon and lay the Keen Rune; start a fight and look at their card; lay a second rune on the same weapon | The Keen Rune goes on, the Whetstone and herbs are gone from the packs, the card shows the rune among their passives, and the second rune takes the first one's place | D327 |

## H — Conversation and the camp

| #   | Do this                                                          | Expect                                                                                  |
| --- | ---------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| H1  | Walk the road for a few hundred steps                            | Party banter in the log and in a bubble over the marker, varied, not the same two lines |
| H2  | Rest until you reach the camp, and press **E** on each companion | A different exchange each time, and only one each per fire                              |
| H3  | System menu → toggle **Chatter**                                 | It reads "Chatter: in the log"                                                          |
| H4  | Walk and rest again with Chatter off                             | Banter still happens, but in the log and bubbles — the dialogue box never opens for it  |
| H5  | Talk to a townsfolk NPC with Chatter off                         | The dialogue box **does** open — authored conversation is never demoted                 |
| H6  | Visit a grave                                                    | Something is said about who is buried there                                             |
| H7  | Quit and relaunch                                                | The Chatter setting is remembered                                                       |

## I — Journal (**N**)

| #   | Do this                                                          | Expect                                                             |
| --- | ---------------------------------------------------------------- | ------------------------------------------------------------------ |
| I1  | Open it at the very start of a run, then go to **Bestiary**      | It opens at **The Company**; the Bestiary is empty, and says so    |
| I2  | Fight a goblin, then open it                                     | A goblin page, mostly question marks                               |
| I3  | Look at Reach / Guard / Constitution before doing anything to it | All `?`                                                            |
| I4  | Be hit by one                                                    | Reach fills in                                                     |
| I5  | Hit one                                                          | Guard fills in                                                     |
| I6  | Kill one                                                         | Constitution fills in                                              |
| I7  | Watch one cast something                                         | That ability is named; the rest stay "something you have not seen" |
| I8  | Fight in the Training Ground, then check                         | **Nothing** was written down                                       |
| I9  | Start a new game and read the landing                            | A journal comes down in the furrow with the lead, blank but for their name ([D67](06-decisions.md)) |
| I10 | Open it                                                          | A leather book, two parchment pages, a coloured ribbon per tab; the open ribbon stands taller |
| I11 | On **The Company**, press each companion on the left page        | Their sheet on the right: face, level and path, health and experience bars, attributes with what a level adds, the path's growth bars, what they carry, their powers, what they have learned from |
| I12 | Open it with someone owed a path or a power                      | A red box on their sheet says so; **Choose it** shuts the book and opens the party screen at that choice |

## I2 — Growing ([D67](06-decisions.md))

| #   | Do this                                                          | Expect                                                             |
| --- | ---------------------------------------------------------------- | ------------------------------------------------------------------ |
| GR1 | Win the first fight of a run                                     | The one who levelled flickers gold where they stand, with a ring and "Level N" rising off them; a small line at the top right says "<name> reached level N" and fades by itself. Nothing covers the fight ([D77](06-decisions.md)) |
| GR2 | Reach level 2 with the lead                                      | The line at the top right adds "a path to choose (P)"; P opens the party screen at the choice |
| GR3 | On the party screen, look at the path cards                      | A card per class in its own colour, with growth bars, its powers' themes and what it starts with; the tabs above are greyed |
| GR4 | Press **Walk this path**                                         | Chosen in one click; a line at the top right in the class's colour says whose way it is now |
| GR5 | Reach level 5 and open the Powers page                           | The tree as three stones: the first glows gold; pressing it fills it in the class's colour and the next one glows |
| GR6 | Level up during a real-time fight                                | Only the gold flicker and the line at the top right; the fight runs on, and nothing takes a click |

## J — Coliseum

| #   | Do this                                                     | Expect                                                                  |
| --- | ----------------------------------------------------------- | ----------------------------------------------------------------------- |
| J1  | Title → Coliseum                                            | Champion list, four cards, and the best night recorded per card         |
| J2  | Pick and Go out                                             | A fight on the sand                                                     |
| J3  | Win                                                         | Round cleared, purse paid, and a choice: next round or take the purse   |
| J4  | Take the next round wounded                                 | You are **not** fully healed — wounds carry between rounds              |
| J5  | Lose a round                                                | "They carry you off", the rounds and purse are recorded, and it is over |
| J6  | Retire with a purse, then look at the card again            | The best night shows your run                                           |
| J7  | Go to the Coliseum mid-run, then Back to Title and Continue | **Your real party is untouched** — same people, same HP, same purse     |
| J8  | Walk into a keep's arena, win a round, press **Take the purse and leave** | Back on the keep's street by its door, the purse added to yours — never the title screen. The bottom-right button reads **Leave the arena**, not Back to Title |
| J9  | Send a single hero (not the company) onto the sand from a keep, then leave | Your purse is what it was plus the winnings; the hero brings nothing into it |
| J10 | Save from the menu while on the sand, then load                | Your own party comes back, not the copy that was fighting           |
| J11 | `godot --path . res://src/party_war/party_war.tscn -- --fights=2 --seed=7` | A card with both sides (faces, levels, gear, stances, pouch), FIGHT!, rosters down both edges, words over heads, the log along the bottom, K.O.! and a banner; then the second clash, then it closes ([D257](06-decisions.md)) |
| J12 | The same with `--war=guild_vs_empire --seed=1` | "GUILD WAR", twelve against fourteen on a wide field, Dirte among the Empire; the rosters fit down each edge |
| J13 | `python3 tools/party_war.py table 20 --seed 1 --out /tmp/pw` | `results.csv` and `results.md` in /tmp/pw: 40 fights, each draw both ways round, with the size, level and stance tables |

## K — Museum

| #   | Do this                         | Expect                                                                 |
| --- | ------------------------------- | ---------------------------------------------------------------------- |
| K1  | Title → Museum with no history  | "Nothing here yet"                                                     |
| K2  | With a run in progress          | It is at the front, marked "Still out there"                           |
| K3  | Let a run end, then open it     | The finished run is listed with the date and its whole company         |
| K4  | Click a journey                 | Faces, callings, levels, who died, and the run's numbers               |
| K5  | Start a new run and check again | The old company is **still there** — starting over does not erase them |

## L — The browser build

Export with `godot --headless --path . --export-release Web builds/web/index.html` (or take the
`web` zip from the `release` workflow), serve the folder (`python3 -m http.server -d builds/web`)
and open `http://localhost:8000/` in Chrome or Firefox. `tools/web_smoke.py` plays L1–L5 by itself.

| #   | Do this                                                        | Expect                                                                                      |
| --- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| L1  | Open the page                                                  | The Godot loading bar, then the title card within a few seconds; silent until the first input |
| L2  | Click anywhere on the title card                               | The menu slides in, and the title music starts with that click                              |
| L3  | Look at the title menu                                         | No **Quit** — a page cannot close its own tab, so the browser build leaves it out            |
| L4  | New Game → a life → walk a few steps → `Esc` → **Save Game**   | "Progress saved."                                                                            |
| L5  | Reload the page, go on to the title                            | **Continue** is lit and puts you back where you saved (the save lives in the browser's IndexedDB) |
| L6  | `Esc` → **Fullscreen**, then `Esc` in the browser              | The page goes fullscreen; the browser's own `Esc` brings it back and the button follows       |
| L7  | Close the tab, open the page again in a private window         | No save — private windows forget IndexedDB, so Continue is greyed out                         |
| L8  | Training Ground → **Fight this**, read the clock line and the party cards | No empty boxes where a character should be (the browser has no fallback font — see the roadmap's Launch readiness) |

## P — Controller

Plug in an Xbox or PlayStation pad before launching. A is Cross, B Circle, X Square, Y Triangle.

| #   | Do this                                                                | Expect                                                                                    |
| --- | ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| P1  | Press A on the title card, then D-pad and A on the menu                | The menu slides in; the highlight moves with the D-pad and A presses the entry            |
| P2  | New Game → answer the quiz and pick a hero with the pad only           | Every answer, hero and the Start button reachable; B goes back a screen                   |
| P3  | On the road, touch the stick, then press a key                         | The hint line says "A to …" after the stick, "E to …" after the key                        |
| P4  | Walk with the left stick, then the D-pad                               | One tile per press, a run when held                                                       |
| P5  | Stand in a village, press Y                                            | The place's buttons appear with the first one highlighted; the party does not walk        |
| P6  | D-pad along them, A on Hire or Buy, then B                             | It hires or buys; B puts the highlight away and the stick walks again                     |
| P7  | Press Start, then B; press Back, then Back again                       | Menu opens and closes; the party screen opens and closes                                  |
| P8  | In the party screen, D-pad down the cards and over to the pages        | The page follows the card; every button can be reached and pressed; the page scrolls      |
| P9  | Press X on the road                                                    | The Journal opens; B shuts it                                                             |
| P10 | In a fight, touch the stick                                            | A cursor starts on the picked fighter and walks the board                                 |
| P11 | Stick to an empty tile, A; then to an enemy, A                         | The fighter walks there; then goes after that enemy                                       |
| P12 | Y, then A on a foe in reach; Y again, then B                           | A skill is readied and cast at the cursor; B puts a readied skill away, and with none, opens the menu |
| P13 | RB with two fighters up, X, LB                                         | Next fighter; pause; speed changes                                                        |
| P14 | Right stick, LT, RT, R3                                                | The view slides, zooms out, zooms in, and comes back                                      |
| P15 | Training Ground → real-time skirmish, with the pad                     | X starts it; stick moves a cursor; A on ground moves, on a foe attacks; Y readies a skill |
| P16 | Menu → Controls; A on Interact, then press X on the pad                | The row reads "E  ·  X"; it survives a relaunch; Reset puts back "E  ·  A"                |
| P17 | Open the menu with Start during a fight, close it                      | The command menu has its highlight back                                                   |

---

## Known to be untestable here

- **W2** — the voice line at the end of the cinematic. The line is chosen (Bram's "Give me your hand.",
  [D328](06-decisions.md)) but not built yet, so there is nothing to test.
- Anything needing the other 68 units' run cycles (**E3** will stay "slides" until that art lands).

## What a fail should include

The screen, the seed (system menu shows it), what you pressed, and what you expected instead.
The system menu's **Copy play log** (or **Save play log**, which downloads it) hands over a timed
account of the session: every place, fight, level, save and fall, and any error the game hit.
A screenshot of a white square or a broken layout is worth a paragraph of description.

**And the log.** Every play writes one, with every warning and script error in it and the run's
seed at the top. `.\ek.ps1 logs` prints the end of the last one and says where it is; the file
itself is `%APPDATA%\Godot\app_userdata\Earth Kings\logs\godot.log`, and the few plays before it
sit beside it with the date in the name. On Android it is in the app's private storage, readable from a debug build
with `adb shell run-as <package> cat files/logs/godot.log` (logging is switched on for phones too).
A tester who is not at your desk can zip that folder and send it.

---

## The bench

Rather than starting a run and playing to the point of concern, boot straight into it.
`ek.ps1` wraps it; `--play` and `--shot` need a real renderer, so it drops `--headless` for those.

```powershell
.\ek.ps1 --scene=world --at=gate --level=6 --gold=800 --play   # hands-on, at that point
.\ek.ps1 --scene=party --level=6 --stores=steel_blade,halo_robe --shot
.\ek.ps1 --list=sites            # sites areas units abilities equipment heroes classes
.\ek.ps1 test                    # every smoke suite, one line each
```

State flags: `--seed --hero --level --gold --at --steps --floor --hoard --stores --equip --hurt`,
`--owed=path|power`, `--levelup`, `--choose=CLASS`, `--take`, and `--tab=NAME` for the journal ([D67](06-decisions.md)).
Scenes: title character_select world area skirmish training coliseum museum credits summary,
plus the overlays party journal menu. `--scene=area` takes `--area=id`.

`.\ek.ps1 --help` prints the lot.

## Automated tests

**Back in use from 2026-09-24.** They were parked when they cost more than they caught and had
started failing on their own stale expectations. Since then every suite has been brought back to
green and run after every change: thirteen suites, around 580 checks (`tools/coverage.tscn` counts
them per test).

```powershell
.\ek.ps1 test                                   # every suite, one line each
.\ek.ps1 test walk dispatch                     # only those
godot --headless --path . res://tests/walk_smoke_test.tscn -- --check=gate,tower
godot --headless --path . res://tests/world_smoke_test.tscn -- --check=fate
```

**In CI.** Every pull request and every push to `main` runs all thirteen suites and a two-minute
soak on seed 77, headless on Linux against the official Godot 4.7.2 build
(`.github/workflows/smoke.yml`). Both go through `./ek.sh`, the Linux and macOS twin of
`.\ek.ps1 test`, so a red check can be reproduced locally with the same command:

```bash
./ek.sh test                 # every suite
./ek.sh test walk seams      # only those
./ek.sh soak 120             # the soak CI runs
./ek.sh ledger               # the Question Book and answers.md agree
```

`ek.sh` is stricter than `ek.ps1` in one way: a suite that prints a `SCRIPT ERROR` fails even when
it exits 0, because Godot carries on past a script error and the exit code alone misses it. The
soak fails on a `SCRIPT ERROR`, a non-zero exit (`STUCK` is 2), or a save that does not come back
the same file. `ledger` runs `tools/question_report.tscn`, which fails on any drift between the
Question Book and the answer ledger — an answer to a question that does not exist, or a lineage
source marked as settling one — so a docs-only change to the worldbuilding is checked too.

`--check=` runs only the named checks of the three suites that have them (`walk`, `world`,
`seams`); a name the suite does not have fails and lists the ones it does. Every check in all three
passes run on its own.

**The soak.** `tools/soak.tscn` lets the whole game play itself on autoplay at ×4 for as long as
you give it, prints where the run has got to every thirty seconds, and ends by saving, loading and
saving again. It also prints its five longest frames with what was happening (a step on the land,
a fight starting, a scene changing), so lag has a name (D122). It is not a suite (battle dice are unseeded, so no two soaks match), but it finds what
no suite is looking for — its first runs found bounty errands that could not be posted, autoplay
pacing in front of a wall forever, autoplay never climbing past the Tower's first floor, a fight
that ignored Auto switched on from the touch controls, road chatter crashing when a fight started
mid-line, and saves that changed every time they were loaded. Run one
after anything that touches the walk, the save or autoplay:

```powershell
godot --headless --path . res://tools/soak.tscn -- --seconds=300 --seed=77
```

Look for `SCRIPT ERROR`, steps that rise with no fights (autoplay has nowhere to go) and
`the same file: false`. Steps and log lines that stop moving for thirty seconds with autoplay on end
the soak with `STUCK … in Skirmish` or similar and exit code 2 — something is waiting on a
key nobody is pressing. A lead who dies is not stuck: the game waits on the run summary for the
next lead to be chosen, so the soak prints `RUN OVER at step N`, stops walking there and goes on to
the save check. Since the First Hour was made harder ([D187](06-decisions.md)) a lone Atlas can fall
in an early fight on seed 77 now and then. A soak that runs clean ends with exit code 0.

**The browser build.** `tools/web_smoke.py` exports the Web preset, serves `builds/web` on a
local port and plays it in headless Chromium through `tools/web_smoke.js`: past the title card,
**Not now** to the tour, New Game, the quiz, a life, Esc past the opening, three steps on the
ground, the system menu's **Save Game**, then a reload
and **Continue**. It fails on any console error, page error or failed request, a screen that never
comes, or a save that never reaches IndexedDB, and prints the `.pck` and `.wasm` sizes and the load
times. Screenshots land in `builds/web_smoke/`. It needs Node with the `playwright` npm package and
a Chromium it can launch, so it is not in CI; run it before a release tag or after touching
`export_presets.cfg`:

```bash
EK_GODOT=~/godot/godot python3 tools/web_smoke.py              # export, then play
python3 tools/web_smoke.py --no-export                         # play what is in builds/web
```

The menu click for **Save Game** is the one step that is not a key press (the menu opens with
nothing focused), so it moves if the system menu's layout does.

Still open:

- **Seeded tests pin step counts and cell positions**, so W12's bigger world will invalidate
  `walk`, `world` and `skein` wholesale. Budget the rewrite with that work, not before it.
- **Nothing compares the screen.** The bench photographs any scene (`--shot`), and a real renderer
  can run headless under Xvfb on Linux, but nothing compares a photograph against a stored
  reference yet.
- **Difficulty leaks into assertions.** Anything checking enemy counts or experience has to pin
  `GameState.difficulty = "even"`, or account for it: First Hour is the default ([D104](06-decisions.md))
  and gives 3× experience and gold, foes three levels down, one fewer and softer, and permadeath. The fight suite
  pins Story (`gentle`), the setting it was written against.

## Completed integrations

Both previously flagged systems were integrated and verified:

- **Multi-floor delves (M5)** — `Encounter.for_gate` runs gates across scaled depth levels, shut
  only upon conquering the final floor, with intermediate floors awarding charms, doctrine, and
  branching tree unlocks (rank C+).
- **Proficiency by use (W17c)** — `src/chronicle/proficiency.gd` tracks practice through
  `skirmish.gd`, `ability_resolver.gd`, and `character.gd`, rewarding mastery titles and display on
  the party screen.
