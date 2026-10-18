#!/usr/bin/env python3
"""Lay out the Tower's floors 6 to 10, the Second Hour (D196, D254).

    python3 tools/build_tower_floors.py          write data/areas/tower_floor_6.json ... _10.json

Each floor is built from the rooms the chapter twos name (D182; the drafts are in the project's
shared files, `story/chapter-two/`): 6 a long gallery, a stair landing and a cold storeroom; 7 the
watchtower stair and a dry cistern; 8 a hall of bricked doors and a ruined square; 9 a walled yard
with a well and a post, a cold barracks hearth and a dead tree's roots; 10 the foot of the last
stair, kept by the Keeper of the Tenth, and the keeper's antechamber. Every floor keeps floors 1 to
5's frame: 26 by 18, the way in at the bottom (12, 17), the stair up at the top (12, 0), the party
put down at (12, 15). Each lead's chapter-two keepsake lies in its room (`KEEPSAKES`, read by
tools/chapter_twos.py). Bands are the plan's: on the floor they are restocked with the floor's own
foes (src/chronicle/tower_floors.gd), all but the keeper. The tool walks each floor and stops if the
stair, a keepsake, a spot or a band cannot be reached from the way in. Pieces are stand-ins until
drawn (docs/24, A34 and A35). Standard library only.
"""
from __future__ import annotations

import json
import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from build_interiors import footprint, solid  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
AREAS = ROOT / "data" / "areas"

TOP = "AAAAAAAAAAAAffAAAAAAAAAAAA"
FOOT = [
    "AAAAAAAAAAsssssssAAAAAAAAA",
    "AAAAAAAAAAsssssssAAAAAAAAA",
    "AAAAAAAAAAssffsssAAAAAAAAA",
    "AAAAAAAAAAAAffAAAAAAAAAAAA",
]
NECK = "AAAAAAAAAAAssssAAAAAAAAAAA"
STAIR = [("tower_inside/stair_up", 12, 1, {}), ("tower_inside/stair_up", 13, 1, {"flip": True}),
         ("tower_inside/rune_a", 11, 0, {}), ("tower_inside/rune_b", 14, 0, {})]
DOWN = [("lamp_globe", 10, 15, {}), ("lamp_globe", 16, 15, {})]


def band(floor: int, letter: str, at: tuple, pack: list, label: str, level: int, **more) -> dict:
    key = "tower%d_%s" % (floor, letter)
    out = {"key": key, "pack": pack, "label": label, "faction": "", "at": list(at), "reach": 2,
           "level": level, "held": True}
    out.update(more)
    out["requires_not"] = "done:" + key
    out["done_flag"] = "done:" + key
    return out


FLOORS: dict[int, dict] = {
    6: dict(
        tint="#8a8fa8",
        hint="WASD to walk  ·  the stair up is north, through the long gallery",
        rows=[TOP,
              "AAAAAAAAAssffssAAAAAAAAAAA",
              "AAAAAAAAAssssssAAAAAAAAAAA",
              "AAAAAAAAAssssssAAAAAAAAAAA",
              "AAAAAAAAAAAssssAAAAAAAAAAA",
              "AssssssssssssssssssssssssA",
              "AffffffffffffffffffffffffA",
              "AssssssssssssssssssssssssA",
              "AAAAsAAAAAAssssAAAAAAAsAAA",
              "AssssssssAAssssAAssssssssA",
              "AssssssssAAssssAAssssssssA",
              "AssssssssAAssssAAssssssssA",
              "AssssssssAAssssAAssssssssA",
              NECK] + FOOT,
        props=STAIR + DOWN + [
            ("interior/banner_blue", 4, 4, {"offset": [0, 18]}), ("interior/banner_red", 8, 4, {"offset": [0, 18]}),
            ("interior/banner_blue", 17, 4, {"offset": [0, 18]}), ("interior/banner_red", 21, 4, {"offset": [0, 18]}),
            ("lamp_globe", 1, 5, {}), ("lamp_globe", 24, 5, {}),
            ("tower_inside/stair_up", 2, 9, {}), ("tower_inside/rune_c", 7, 9, {}),
            ("interior/crates", 18, 9, {}), ("interior/crates", 19, 9, {}), ("village/barrels", 24, 9, {}),
            ("interior/shelf_bottles", 22, 9, {}), ("village/barrels", 24, 12, {}),
        ],
        spots=[
            ((12, 13), "The gallery's runner is worn pale down the middle, by feet that all went the same way."),
            ((5, 11), "A landing, and a stair from it that goes down two steps and stops at a wall. Somebody bricked it up from this side."),
            ((20, 12), "A storeroom, cold enough for your breath to show. The crates are empty, and stacked as if somebody meant to come back for them."),
        ],
        keepsakes={"atlas": (3, 11), "iris": (6, 7), "juno": (21, 11)},
        bands=lambda: [
            band(6, "a", (5, 7), ["goblin", "wolf"], "In the long gallery", 5),
            band(6, "b", (20, 7), ["goblin", "brigand_archer"], "Across the gallery", 5),
        ],
    ),
    7: dict(
        tint="#8d8aa0",
        hint="WASD to walk  ·  the stair up is north  ·  a watchtower's stair climbs the west wall",
        rows=[TOP,
              "AsssAAsssssffsssssAAAAAAAA",
              "AsssAAssssssssssssAAAAAAAA",
              "AsssssssssssssssssAAAAAAAA",
              "AsssAAssssssssssssAAAAAAAA",
              "AsssAAAAAAAssssAAAAAAAAAAA",
              "AsssAAAAAAAssssAAAAAAAAAAA",
              "AsssAAAAAAAssssAAsssssssAA",
              "AsssAAAAAAAsssssssffffssAA",
              "AsssAAAAAAAssssAAsffffssAA",
              "AsssAAAAAAAssssAAsffffssAA",
              "AsssAAAAAAAssssAAsssssssAA",
              "AssssssssssssssAAAAAAAAAAA",
              NECK] + FOOT,
        props=STAIR + DOWN + [
            ("tower_inside/stair_up", 2, 3, {}), ("tower_inside/rune_a", 1, 0, {}),
            ("brazier", 7, 1, {}), ("brazier", 17, 1, {}),
            ("tower_inside/rune_c", 22, 6, {}), ("nature/pebble", 19, 9, {"offset": [4, 3]}),
            ("nature/pebble", 21, 8, {"offset": [-5, 2]}), ("lamp_globe", 23, 11, {}),
        ],
        spots=[
            ((2, 6), "A watchtower's stair, cut into the wall and broken at the top. From up there you could see a long way down a road."),
            ((20, 10), "A cistern, dry as bone. The marks of the waterline are still on the stone, a long way above your head."),
        ],
        keepsakes={"bellona": (2, 1), "ultor": (2, 11), "ceres": (21, 9)},
        bands=lambda: [
            band(7, "a", (12, 3), ["goblin", "wolf"], "At the head of the floor", 6),
            band(7, "b", (19, 8), ["brigand_archer", "wolf"], "In the cistern", 6),
        ],
    ),
    8: dict(
        tint="#928a9e",
        hint="WASD to walk  ·  the stair up is north, past the bricked doors",
        rows=[TOP,
              "AsssssssssssffsssssssssssA",
              "AssssssssssssssssssssssssA",
              "AssssssssssssssssssssssssA",
              NECK,
              "AAAAAssssssssssssssssAAAAA",
              "AAAAAssssssssssssssssAAAAA",
              "AAAAAssssssssssssssssAAAAA",
              "AAAAAssssssssssssssssAAAAA",
              "AAAAAssssssssssssssssAAAAA",
              "AAAAAssssssssssssssssAAAAA",
              "AAAAAssssssssssssssssAAAAA",
              "AAAAAssssssssssssssssAAAAA",
              NECK] + FOOT,
        props=STAIR + DOWN + [
            ("tower_inside/rune_c", 3, 0, {}), ("tower_inside/rune_a", 8, 0, {}),
            ("tower_inside/rune_b", 18, 0, {}), ("tower_inside/rune_c", 23, 0, {}),
            ("village/fountain", 8, 8, {}), ("village/market_stall", 17, 6, {}),
            ("nature/pebble", 10, 10, {"offset": [6, -4]}), ("nature/pebble", 15, 11, {"offset": [-3, 5]}),
            ("nature/pebble", 6, 6, {"offset": [2, 2]}), ("lamp_post_twin", 19, 11, {}),
        ],
        spots=[
            ((3, 1), "A doorway, bricked up. The mortar is newer than the wall round it."),
            ((8, 1), "Another door, bricked. Somebody has scratched a mark in the bricks, at a child's height."),
            ((18, 1), "A bricked door. Put your ear to it and there is nothing; not even an echo."),
            ((12, 9), "A square with no sky over it: stalls, a dry fountain, bunting rotted to threads. A festival was here once."),
        ],
        keepsakes={"janus": (21, 2), "cassius": (7, 11), "caesar": (18, 11)},
        bands=lambda: [
            band(8, "a", (6, 2), ["goblin", "brigand_archer"], "Under the bricked doors", 6),
            band(8, "b", (16, 9), ["wolf", "goblin"], "In the ruined square", 6),
        ],
    ),
    9: dict(
        tint="#8a8e98",
        hint="WASD to walk  ·  the stair up is north, through the walled yard",
        rows=[TOP,
              "AAAAAAAAAssffssAAAAAAAAAAA",
              "AAAAAAAAAssssssAAAAAAAAAAA",
              "AAAAAAAAAssssssAAAAAAAAAAA",
              NECK,
              "AssssAsssssssssssssAsssssA",
              "AssssAsssssssssssssAsssssA",
              "AssssAsssssssssssssAsssssA",
              "AssssssssssssssssssssssssA",
              "AssssAsssssssssssssAsssssA",
              "AssssAsssssssssssssAsssssA",
              "AssssAsssssssssssssAsssssA",
              NECK,
              NECK] + FOOT,
        props=STAIR + DOWN + [
            ("village/well", 10, 6, {}), ("village/signpost", 15, 6, {}),
            ("bed_2", 1, 5, {}), ("bed_2", 1, 11, {}), ("camp/fire_dark", 3, 7, {}),
            ("nature/dead_tree", 23, 6, {}), ("nature/pebble", 22, 10, {"offset": [3, -2]}),
            ("lamp_globe", 6, 11, {}), ("lamp_globe", 18, 11, {}),
        ],
        spots=[
            ((12, 7), "A yard with a wall round it, and a ring in the wall where something was chained."),
            ((3, 10), "A barracks: two cots, and a hearth that went out a long time ago. It is colder by it than away from it."),
            ((22, 9), "A dead tree, indoors. Its roots have lifted the floor."),
        ],
        keepsakes={"liber": (11, 7), "ares": (16, 7), "vesta": (4, 9), "diana": (22, 8)},
        bands=lambda: [
            band(9, "a", (8, 10), ["wolf", "goblin"], "In the walled yard", 7),
            band(9, "b", (17, 10), ["brigand_archer", "goblin"], "By the yard wall", 7),
        ],
    ),
    10: dict(
        tint="#9a86a0",
        hint="WASD to walk  ·  the stair up is north, past the Keeper of the Tenth",
        rows=[TOP,
              "AAAAAsssssssffsssssssAAAAA",
              "AAAAAssssssssssssssssAAAAA",
              "AAAAAssssssssssssssssAAAAA",
              "AAAAAssssssssssssssssAAAAA",
              NECK,
              "AAAAssssssssssssssssssAAAA",
              "AAAAssssssssssssssssssAAAA",
              "AAAAssssssssssssssssssAAAA",
              "AAAAssssssssssssssssssAAAA",
              "AAAAssssssssssssssssssAAAA",
              "AAAAssssssssssssssssssAAAA",
              "AAAAssssssssssssssssssAAAA",
              NECK] + FOOT,
        props=STAIR + DOWN + [
            ("tower_inside/rune_c", 6, 0, {}), ("tower_inside/rune_a", 19, 0, {}),
            ("brazier", 10, 2, {}), ("brazier", 15, 2, {}),
            ("interior/banner_red", 6, 5, {"offset": [0, 18]}), ("interior/banner_red", 19, 5, {"offset": [0, 18]}),
            ("interior/candelabra", 5, 6, {}), ("interior/candelabra", 20, 6, {}),
            ("interior/bench_low", 6, 10, {}), ("interior/bench_low", 19, 10, {}),
            ("tower_inside/rune_b", 8, 12, {}),
        ],
        spots=[
            ((12, 11), "An antechamber, with benches along the walls, as if the climb up the Tower were a thing you waited your turn for."),
            ((8, 3), "The foot of the last stair of the chapter. The steps are worn hollow in the middle."),
        ],
        keepsakes={"cato": (6, 8), "saturn": (7, 3), "pluto": (11, 1)},
        bands=lambda: [
            band(10, "keeper", (12, 4), ["tenth_keeper", "goblin", "brigand_archer"], "The Keeper of the Tenth", 12,
                 boss=True, lost="The Keeper of the Tenth lets you go back down. It counts you as you go."),
            band(10, "a", (17, 9), ["wolf", "brigand_archer"], "In the antechamber", 8),
        ],
    ),
}


def build(floor: int) -> None:
    spec = FLOORS[floor]
    rows = spec["rows"]
    assert len(rows) == 18 and all(len(r) == 26 for r in rows), "floor %d is not 26 by 18" % floor
    path = AREAS / ("tower_floor_%d.json" % floor)
    props = []
    for art, x, y, more in spec["props"]:
        entry = {"art": art, "cell": [x, y]}
        entry.update(more)
        props.append(entry)
    bands = spec["bands"]()
    data = {
        "display_name": "floor %d of the Tower" % floor,
        "_doc": "D254: the Second Hour's floor %d, laid out by tools/build_tower_floors.py; change it there." % floor,
        "layers": ["tower_slab", "tower_runner", "tower_wall"],
        "legend": {"s": "tower_slab", "f": "tower_runner", "A": "tower_wall"},
        "tint": spec["tint"],
        "hint": spec["hint"],
        "spawn": [12, 15],
        "exits": [[12, 17], [13, 17]],
        "stairs": [[12, 0], [13, 0]],
        "spots": [{"cell": list(c), "line": line} for c, line in spec["spots"]],
        "props": props,
        "bands": bands,
        "rows": rows,
        "dressing": [],
    }

    blocked = set()
    for entry in props:
        if solid(entry["art"], entry):
            blocked |= set(footprint(entry["art"], tuple(entry["cell"])))

    def open_cell(c: tuple) -> bool:
        x, y = c
        return 0 <= x < 26 and 0 <= y < 18 and rows[y][x] != "A" and c not in blocked

    seen = {(12, 15)}
    todo = deque(seen)
    while todo:
        x, y = todo.popleft()
        for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if n not in seen and (open_cell(n) or n in ((12, 0), (13, 0), (12, 17), (13, 17))):
                seen.add(n)
                todo.append(n)
    problems = []
    wanted = [("stair", (12, 0)), ("way in", (12, 17))]
    wanted += [("keepsake of %s" % k, c) for k, c in spec["keepsakes"].items()]
    wanted += [("spot", c) for c, _ in spec["spots"]]
    wanted += [("band %s" % b["key"], tuple(b["at"])) for b in bands]
    for what, c in wanted:
        if c not in seen or (c in blocked):
            problems.append("%s at %s" % (what, c))
    if problems:
        sys.exit("build_tower_floors: floor %d cannot be walked: %s" % (floor, ", ".join(problems)))
    path.write_text(json.dumps(data, indent=4, ensure_ascii=False) + "\n", encoding="utf-8")
    print("floor %-3d %d pieces, %d bands, keepsakes for %s" % (floor, len(props), len(bands), ", ".join(spec["keepsakes"])))


KEEPSAKES = {lead: (floor, cell) for floor, spec in FLOORS.items() for lead, cell in spec["keepsakes"].items()}

if __name__ == "__main__":
    for floor in FLOORS:
        build(floor)
