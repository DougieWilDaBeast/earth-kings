extends Node
## Global signal hub (autoload: `EventBus`).
##
## Systems emit and listen here instead of holding references to each other,
## so battle / world / UI stay decoupled and independently testable.

## Ask the root [Game] node to swap the active scene ("world" | "area" | "battle").
signal request_scene(scene_key: String, payload: Dictionary)
## The scene asked for is now in, and is the one being played. Anything living
## above the scene — the touch controls, for one — lays itself out from this,
## because what belongs under a thumb in the world is in the way in a fight.
signal scene_changed(scene_key: String)

signal battle_started(map_id: String)
## result: { "victory": bool, "map_id": String, "turns": int }
signal battle_finished(result: Dictionary)

signal turn_started(unit: Node)
signal turn_ended(unit: Node)
signal unit_damaged(unit: Node, amount: int)
signal unit_healed(unit: Node, amount: int)
signal unit_died(unit: Node)

signal dialogue_requested(dialogue_id: String)
## A conversation built at runtime rather than authored in a file: an array of
## `{ speaker, text }` (see [Banter]). Finishes as [signal dialogue_finished].
signal conversation_requested(lines: Array)
signal dialogue_finished(dialogue_id: String)

## A party member hit level 2 and owes the player a decision.
signal class_choice_required(character: RefCounted)
signal class_chosen(character: RefCounted)
## A character went down. outcome: { "outcome": "alive"|"captured"|"dead", "reason": String, "line": String }
signal character_fell(character: RefCounted, outcome: Dictionary)

## Ask the always-present system menu (save / load / title) to open.
signal system_menu_requested
## Ask the always-present party screen to open.
signal party_screen_requested
## Ask the always-present journal to open.
signal journal_requested
## The journal's Map was pressed: whichever ground the party is on opens the
## continent as a map, and comes back to the same spot when it is put away.
signal map_requested
## Ask the camp stash screen to open.
signal stash_requested
## Ask the Adventurers Guild screen to open on the hall the party stands in.
signal guild_requested
## Ask the always-present How to Play page to open.
signal how_to_play_requested
## One of the always-present overlays has shut itself. The `_requested` signals
## above are only the opening edge; anything that has to know whether something
## is in the way needs both.
signal overlay_closed
## A Tower chapter earned the company another seat; [param seats] can march now.
signal party_seat_opened(seats: int)
## The last of the party is gone; the run is over.
signal run_ended
## The run has reached somewhere the game may save itself (see
## `src/chronicle/run_mode.gd` for the points). [GameState] decides whether the
## mode saves there; [param note] is how the save will be remembered ("you
## rested at Oakham").
signal safe_point_reached(point: String, note: String)
## The game saved itself at [param point].
signal game_saved(point: String, note: String)
## Something the player should know about the save they just loaded: it was
## upgraded, restored from the backup, or left alone because it is newer than
## this build ([D56]). Shown as a toast by [Game].
signal save_notice(text: String)

## Something happened that a newcomer may be meeting for the first time: "step",
## "settlement", "gate", "errand"… The tip card decides whether there is anything
## to say about it (data/tips.json); nothing is owed a reply. context carries
## whatever the decision needs, such as { "danger": float, "steps": int } on a step.
signal tip_moment(kind: String, context: Dictionary)

## Tiles that have just come onto the party's map (`src/chronicle/atlas.gd`),
## so the map can fade them in rather than snap.
signal ground_revealed(cells: Array)

## Human-readable combat log line, rendered by the battle HUD.
signal battle_log(line: String)

## Overlays that swallow the game's input while they are up. Anything in this
## group answers `is_open()`.
const MODAL_OVERLAY_GROUP := "modal_overlay"

## The always-present letterbox a cutscene plays inside.
const CUTSCENE_FRAME_GROUP := "cutscene_frame"

## The scene [Game] is showing right now: the title, the walk, a fight. Only
## ever one node is in it.
const ACTIVE_SCENE_GROUP := "active_scene"
