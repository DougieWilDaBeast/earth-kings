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
| A1  | Launch the game                                                              | A map pass over a country you have never seen, camera drifting between places, a few figures walking the roads |
| A2  | Wait through the whole cinematic without touching anything                   | The title fades up part-way, then "press anything to go on"; at about twelve seconds the title card: the logo over the sixteen falling, and "Press any key" |
| A3  | Launch again and press a key or click immediately                            | Straight to the title card; another key slides the logo to the corner and the menu in down the left |
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
| B1  | New Game                                                             | Twelve heroes, gentlest first, each with its rating on the button (Steady → Ruinous) |
| B2  | Arrow through them                                                   | Portrait, warband, stats and blurb all change to match                               |
| B3  | Type `12345` in the Seed field and start                             | A run begins                                                                         |
| B4  | Note the world seed in the system menu, start again with that number | The same country, same places, same names                                            |
| B5  | Leave the Seed field empty and start twice                           | Two different countries                                                              |
| B6  | Type letters in the Seed field                                       | Treated as empty; a random country, no error                                         |
| B7  | Lose a run with the lead **dead** (Even or harder), then New Game → answer → _Show me all sixteen_ | That lead is not on the list any more |
| B8  | With every lead fallen, open _Show me all sixteen_ | "All of them have fallen." and **Begin a new sixteen**; it asks twice, then the quiz starts with everyone back |
| B8a | New Game, then answer the questions                                   | Falling sky behind; four marks at the top light one by one as each pair is settled; answers pick with the mouse, arrows or `1` / `2`; with three questions a pair, answering the same way twice skips the third |
| B9  | Start a run                                                          | The landing beat plays: a furrow in the ground, no memory, the Tower off to one side, and "A new standing quest: Ascend to heaven" |
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
| RT10 | Press **T** during the fight                                | x1 → x1.5 → x2 → x1, and the fight plays at that pace                                  |
| RT11 | Win or lose                                                 | Victory or Defeat, and after two seconds you are back where the fight started — the road, the training ground, the coliseum |
| RT12 | Fight in **Training**, then go back to the run              | **Your real party is untouched** — nothing from a training fight is written back         |
| RT13 | Let someone go down with auto-pause at its default          | The fight pauses itself: "Paused." after "_X_ is down"                                    |
| RT14 | Press **Z** twice, turn **A** off on a unit, use its skill  | When the skill comes back the fight pauses: "Paused. _X_'s _Y_ is ready."                |
| RT15 | On a phone (or touch set to On in the system menu), start a real-time fight | A column of buttons down the right: Pause, Speed, All, the four skills named for the picked fighter, Auto skills, Hold, Auto-pause |
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

## G — Gates and the Tower

| #   | Do this                                   | Expect                                                                                        |
| --- | ----------------------------------------- | --------------------------------------------------------------------------------------------- |
| G1  | Step onto an open gate                    | A fight, and the log says which floor of how many                                             |
| G2  | Win the first floor of a multi-floor gate | You are told there is more below, and the gate is **not** shut yet                            |
| G3  | Try to walk off the gate mid-delve        | You can't: "There is no way out … but through", and the step starts the next floor instead ([D35](06-decisions.md)) |
| G4  | Clear the last floor                      | The gate shuts and pays out                                                                   |
| G5  | Lose a floor                              | You are put out; the gate stays open                                                          |
| G6  | Climb a Tower floor                       | The gold is a **hoard**, not in your purse — "you are carrying N out of here, if you get out" |
| G7  | Climb a second floor without leaving      | The hoard grows, and you are warned what you stand to lose                                    |
| G8  | Walk off the Tower step                   | "You walk away from the Tower with N gold" and the purse goes up                              |
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
| D2.7 | Take **Wat**'s favour, look at the grey stone by the pond, go back to him | The stone is only there once the favour is taken; he pays 30 gold and a Hearth Coin, once |
| D2.8 | Look at a gate, the Tower, the salt hamlet's lighthouse   | The portal glows, the Tower's runes pulse, the lighthouse beam sweeps                           |
| D2.9 | Look at the world map                                     | Gates are portals, villages cottages, huts a log lodge; no cream squares behind any castle      |
| D2.10 | Walk every exit of a wild area                           | Nothing laid down blocks the road out                                                          |

## D3 — A band on the ground ([D66](06-decisions.md), [D68](06-decisions.md), [D72](06-decisions.md))

Start a run and walk until the bottom line says a band has marked the ground it can see.

| #    | Do this                                              | Expect                                                                                  |
| ---- | ---------------------------------------------------- | --------------------------------------------------------------------------------------- |
| D3.1 | Look round                                           | The band on the ground with its name over it; the cells it can see a red grid with a rim; you are not inside it |
| D3.2 | Watch it for ten seconds                             | It walks a small loop, resting at each stop, the red moving with it                      |
| D3.3 | Walk up close without entering the red               | They turn to watch you; nothing starts                                                   |
| D3.4 | Walk through long grass right up to them             | Long grass is never red; step out of it into the red and the fight opens with "Ambush!"   |
| D3.5 | Step onto a red cell                                 | Heads turn, they rush you, and the fight opens on the same ground at the same zoom, everyone where they stood; the camera draws back, the ground beyond the field dimmed |
| D3.6 | Win the fight                                        | Back on the same ground, on the spot you were seen; the band gone from the ground and the journal's map |
| D3.7 | Walk onto a tile a band on the next tile watches     | No sudden fight: the band stands at that edge of the new ground, watching                |

## D4 — The tutorial ([D73](06-decisions.md))

Delete `settings.cfg` and the save from the user folder first, to be a new player.

| #    | Do this                                               | Expect                                                                                  |
| ---- | ----------------------------------------------------- | --------------------------------------------------------------------------------------- |
| D4.1 | Open the game                                         | After the opening, "New to Earth Kings?" over the title; **Take the tour** has focus     |
| D4.2 | Close and open the game again                         | No offer the second time; **Tutorial** is in the title menu                              |
| D4.3 | Take the tour and follow every card                   | Each step ticks "done" and the next comes up; the card never sits on the conversation box |
| D4.4 | Press Esc → Save during the tour                      | "Nothing in the tutorial is saved."; Continue on the title still loads your own run      |
| D4.5 | Reach the fight step, find the sparring pair south of the square, step into their red | Before the step they are not there; then they patrol with red ground. Stepping in opens a paused fight on the village ground, the card on the left; after it, back on the same spot and the pair gone |
| D4.6 | Walk the road south out of Hearthwick                 | Back at the title, the card gone                                                        |
| D4.7 | Finish the tour and press **Start a new run**         | The questions that pick a hero; the new run saves as normal                         |
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
| J7  | Go to the Coliseum mid-run, then Back to Title and Continue | **Your real party is untouched** — same people, same HP, same gold      |
| J8  | Walk into a keep's arena, win a round, press **Take the purse and leave** | Back on the keep's street by its door, the purse added to your gold — never the title screen. The bottom-right button reads **Leave the arena**, not Back to Title |
| J9  | Send a single hero (not the company) onto the sand from a keep, then leave | Your gold is what it was plus the purse; the hero brings nothing into it |
| J10 | Save from the menu while on the sand, then load                | Your own party comes back, not the copy that was fighting           |

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
| L1  | Open the page                                                  | The Godot loading bar, then the cinematic within a few seconds; silent until the first input |
| L2  | Click anywhere on the cinematic                                | Straight to the title, and the title music starts with that click                           |
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
| P1  | Press A on the cinematic, then D-pad and A on the title                | Straight to the menu; the highlight moves with the D-pad and A presses the entry          |
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

- **W2** — the voice line at the end of the cinematic. The memo cuts off before saying what the
  voice says, so there is nothing to test.
- Anything needing the other 68 units' run cycles (**E3** will stay "slides" until that art lands).

## What a fail should include

The screen, the seed (system menu shows it), what you pressed, and what you expected instead.
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
Scenes: cinematic title character_select world area skirmish training coliseum museum credits summary,
plus the overlays party journal menu. `--scene=area` takes `--area=id`.

`.\ek.ps1 --help` prints the lot.

## Automated tests

**Back in use from 2026-09-24.** They were parked when they cost more than they caught and had
started failing on their own stale expectations. Since then every suite has been brought back to
green and run after every change: twelve suites, around 580 checks (`tools/coverage.tscn` counts
them per test).

```powershell
.\ek.ps1 test                                   # every suite, one line each
.\ek.ps1 test walk dispatch                     # only those
godot --headless --path . res://tests/walk_smoke_test.tscn -- --check=gate,tower
godot --headless --path . res://tests/world_smoke_test.tscn -- --check=fate
```

**In CI.** Every pull request and every push to `main` runs all twelve suites and a two-minute
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
saving again. It is not a suite (battle dice are unseeded, so no two soaks match), but it finds what
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
key nobody is pressing. A soak that runs clean ends with exit code 0.

**The browser build.** `tools/web_smoke.py` exports the Web preset, serves `builds/web` on a
local port and plays it in headless Chromium through `tools/web_smoke.js`: past the cinematic,
New Game, the quiz, a life, three steps on the map, the system menu's **Save Game**, then a reload
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
  `GameState.difficulty = "even"`, or account for it: Gentle is the default and gives 5×
  experience and gold, one enemy fewer, weaker foes and no permadeath.

## Completed integrations

Both previously flagged systems were integrated and verified:

- **Multi-floor delves (M5)** — `Encounter.for_gate` runs gates across scaled depth levels, shut
  only upon conquering the final floor, with intermediate floors awarding charms, doctrine, and
  branching tree unlocks (rank C+).
- **Proficiency by use (W17c)** — `src/chronicle/proficiency.gd` tracks practice through
  `skirmish.gd`, `ability_resolver.gd`, and `character.gd`, rewarding mastery titles and display on
  the party screen.
