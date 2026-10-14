#!/usr/bin/env python3
"""Lay out the insides of the inns and halls: walls, floor, rugs, light, furniture and who stands where.

    python3 tools/build_interiors.py                 every room below
    python3 tools/build_interiors.py village_inn     just that one

`doug-md` (2026-10-13): the insides were "very bare every time I walk into it". They were the
street's flagstones with furniture round the edge. Each room here is laid out by hand: a back wall
standing up with what hangs on it, the side and front walls, a floor of its own, a hearth or a
fire, a bar or a high seat, tables in the middle, rugs, and light where the fire and candles are.

The room's own words (its `spots`), its `talk`, its chests' contents and everything else in the
area file are kept; only where things stand is rewritten, so the same room always comes out the
same. Nothing is placed where it would stop the party reaching the door, a chest, a spot or
anybody in the room: the tool walks the room after laying it out and stops if anything is cut
off. The pictures are stand-ins from tools/draw_interiors.py. Standard library only.
"""

from __future__ import annotations

import json
import sys
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AREAS = ROOT / "data" / "areas"
PROPS = json.loads((ROOT / "data" / "props.json").read_text(encoding="utf-8"))

# Raise a picture so it hangs on the back wall's face, or sit a two-cell piece across both cells.
ON_WALL = [0, 18]
ON_WALL_HIGH = [0, 6]
TWO = [32, 0]
TWO_ON_WALL = [32, 18]

# Each room: its size (walls included) and door, what it is built of, its rugs and light, and
# where every piece stands. People, spots and chests are given in the order the area file lists
# them, so their words and wares stay with them.
ROOMS: dict[str, dict] = {
    "village_inn": dict(
        size=(15, 11), door=7, floor="oak", wall="timber", tint="#efdcc4",
        rugs=[(2, 1, 4, 3, "#7a2e2a", "#c9a45f"), (3, 5, 8, 3, "#3b4a6b", "#b89a5a")],
        glows=[(3.5, 1, 4.5, "#ff9a40", 0.5), (4, 6, 2, "#ffcf80", 0.25), (9, 6, 2, "#ffcf80", 0.25),
               (12, 3, 2.5, "#ffcf80", 0.2)],
        props=[
            ("interior/fireplace", 3, 0, TWO_ON_WALL), ("village/log_pile", 1, 1, None),
            ("interior/shelf_bottles", 11, 0, TWO_ON_WALL), ("tapestry", 7, 0, ON_WALL_HIGH),
            ("interior/banner_red", 5, 0, ON_WALL), ("interior/banner_red", 9, 0, ON_WALL),
            ("interior/keg_rack", 13, 1, None), ("village/barrels", 11, 1, None),
            ("interior/bar_counter", 12, 3, None),
            ("sofa_brown", 2, 3, None), ("interior/stool", 5, 3, None),
            ("interior/table_round", 4, 6, None), ("interior/stool", 3, 6, None), ("interior/stool", 5, 6, None),
            ("interior/table_round", 9, 6, None), ("interior/stool", 8, 6, None), ("interior/stool", 10, 6, None),
            ("interior/table_long", 2, 8, TWO), ("interior/bench_low", 2, 9, TWO),
            ("interior/table_long", 11, 8, TWO), ("interior/bench_low", 11, 9, TWO),
            ("interior/crates", 13, 9, None), ("village/barrels", 1, 9, None),
            ("interior/candelabra", 13, 5, None), ("potted_plant", 5, 9, None),
        ],
        people=[(10, 2), (6, 4), (8, 8)], spots=[(7, 5), (3, 4)], chests=[(13, 7)],
    ),
    "fen_alehouse": dict(
        size=(15, 11), door=7, floor="dark", wall="damp", tint="#c4d4bc",
        rugs=[(5, 5, 5, 3, "#3c4a34", "#8a9a6a")],
        glows=[(2, 2, 3, "#ffb060", 0.35), (10, 2, 3, "#c0ffb0", 0.18), (7, 6, 2, "#ffcf80", 0.22)],
        props=[
            ("interior/ship_bell", 9, 0, ON_WALL), ("interior/shelf_bottles", 11, 0, TWO_ON_WALL),
            ("interior/shelf_bottles", 4, 0, TWO_ON_WALL), ("interior/banner_green", 7, 0, ON_WALL),
            ("brazier", 2, 2, None), ("village/barrels", 1, 1, None),
            ("interior/bar_counter", 11, 3, None), ("interior/keg_rack", 13, 1, None), ("interior/crates", 13, 2, None),
            ("interior/table_round", 7, 6, None), ("interior/stool", 6, 6, None), ("interior/stool", 8, 6, None),
            ("interior/table_round", 3, 7, None), ("interior/stool", 2, 7, None), ("interior/stool", 4, 7, None),
            ("interior/table_round", 11, 7, None), ("interior/stool", 10, 7, None), ("interior/stool", 12, 7, None),
            ("interior/bench_low", 2, 4, TWO), ("village/trough", 13, 9, None), ("interior/crates", 1, 9, None),
            ("village/log_pile", 12, 9, None), ("oil_lamp", 5, 9, None),
        ],
        people=[(9, 2), (5, 4), (10, 5)], spots=[(7, 5), (9, 1)], chests=[(2, 3)],
    ),
    "city_tavern": dict(
        size=(21, 13), door=10, floor="oak", wall="stone", tint="#f2dcbc",
        rugs=[(2, 2, 6, 3, "#7a2e2a", "#c9a45f"), (8, 5, 8, 4, "#3b4a6b", "#b89a5a")],
        glows=[(4.5, 1, 5, "#ff9a40", 0.5), (6, 6, 2, "#ffcf80", 0.25), (12, 6, 2, "#ffcf80", 0.25),
               (5, 8, 2, "#ffcf80", 0.22), (16, 3, 3, "#ffcf80", 0.2), (19, 6, 2, "#ffcf80", 0.25)],
        props=[
            ("interior/fireplace", 4, 0, TWO_ON_WALL), ("village/log_pile", 2, 1, None),
            ("interior/slate_board", 10, 0, ON_WALL_HIGH), ("interior/banner_red", 8, 0, ON_WALL),
            ("interior/banner_red", 12, 0, ON_WALL), ("interior/shelf_bottles", 15, 0, TWO_ON_WALL),
            ("interior/keg_rack", 18, 1, None), ("village/barrels", 19, 3, None),
            ("interior/bar_counter", 15, 3, None), ("interior/bar_counter", 17, 3, None),
            ("interior/stool", 14, 4, None), ("interior/stool", 16, 4, None),
            ("sofa_brown", 2, 3, None),
            ("interior/table_round", 6, 6, None), ("interior/stool", 5, 6, None), ("interior/stool", 7, 6, None),
            ("interior/table_round", 12, 6, None), ("interior/stool", 11, 6, None), ("interior/stool", 13, 6, None),
            ("interior/table_round", 5, 8, None), ("interior/stool", 6, 8, None),
            ("interior/table_round", 9, 8, None),
            ("interior/table_long", 15, 9, TWO), ("interior/bench_low", 15, 10, TWO),
            ("interior/crates", 19, 11, None), ("interior/amphorae", 1, 11, None),
            ("interior/candelabra", 19, 6, None), ("potted_plant", 1, 6, None),
        ],
        people=[(15, 2), (6, 3), (13, 8), (4, 8), (17, 8), (9, 9)], spots=[(10, 6), (4, 3)], chests=[(18, 10)],
    ),
    "pine_longhouse": dict(
        size=(17, 11), door=8, floor="pine", wall="log", tint="#f0dcc0",
        rugs=[(6, 3, 5, 5, "#5a3a26", "#b07a40")],
        glows=[(8, 5, 5, "#ff9a40", 0.5), (2, 2, 2, "#ffcf80", 0.2), (14, 2, 2, "#ffcf80", 0.2)],
        props=[
            ("interior/axe_rack", 12, 0, ON_WALL), ("interior/axe_rack", 4, 0, ON_WALL),
            ("tapestry", 8, 0, ON_WALL_HIGH), ("interior/banner_green", 6, 0, ON_WALL),
            ("interior/banner_green", 10, 0, ON_WALL), ("strongbox", 2, 1, None),
            ("camp/fire_logs", 8, 5, None),
            ("interior/table_long", 3, 4, TWO), ("interior/bench_low", 3, 5, TWO), ("interior/bench_low", 3, 3, TWO),
            ("interior/table_long", 12, 4, TWO), ("interior/bench_low", 12, 5, TWO), ("interior/bench_low", 12, 3, TWO),
            ("interior/table_long", 3, 8, TWO), ("interior/bench_low", 3, 9, TWO),
            ("interior/table_long", 12, 8, TWO), ("interior/bench_low", 12, 9, TWO),
            ("village/log_pile", 15, 1, None), ("village/loom", 1, 6, None), ("village/hide_rack", 15, 6, None),
            ("village/barrels", 1, 9, None), ("interior/keg_rack", 15, 9, None), ("oil_lamp", 6, 9, None),
            ("oil_lamp", 10, 9, None),
        ],
        people=[(8, 2), (6, 6), (13, 6)], spots=[(8, 7), (12, 1)], chests=[(2, 2)],
    ),
    "shore_taphouse": dict(
        size=(15, 11), door=7, floor="drift", wall="boards", tint="#d4dce0",
        rugs=[(3, 5, 9, 3, "#2c4a5a", "#c8b080")],
        glows=[(7, 1, 3, "#ffb060", 0.3), (4, 6, 2, "#ffcf80", 0.22), (10, 6, 2, "#ffcf80", 0.22)],
        props=[
            ("interior/shelf_bottles", 3, 0, TWO_ON_WALL), ("interior/shelf_bottles", 10, 0, TWO_ON_WALL),
            ("interior/banner_blue", 7, 0, ON_WALL), ("brazier", 7, 1, None),
            ("interior/bar_counter", 3, 3, None), ("interior/keg_rack", 1, 1, None), ("village/barrels", 3, 1, None),
            ("village/barrels", 13, 3, None), ("interior/crates", 12, 1, None), ("interior/crates", 11, 1, None),
            ("interior/table_round", 4, 6, None), ("interior/stool", 3, 6, None), ("interior/stool", 5, 6, None),
            ("interior/table_round", 10, 6, None), ("interior/stool", 9, 6, None), ("interior/stool", 11, 6, None),
            ("interior/table_long", 11, 8, TWO), ("interior/bench_low", 11, 9, TWO),
            ("interior/slate_board", 5, 9, None), ("interior/crates", 1, 9, None), ("village/trough", 1, 7, None),
            ("oil_lamp", 9, 9, None),
        ],
        people=[(5, 2), (7, 4), (9, 8)], spots=[(7, 5), (5, 8)], chests=[(13, 2)],
    ),
    "dune_serai": dict(
        size=(15, 11), door=7, floor="tile", wall="adobe", tint="#f0d4a8",
        rugs=[(1, 2, 4, 4, "#8a2a24", "#e0b060"), (10, 2, 4, 4, "#28406a", "#e0b060"),
              (6, 7, 3, 3, "#6a3a1a", "#e0b060"), (5, 1, 5, 2, "#7a2a50", "#e0b060")],
        glows=[(7, 5, 3.5, "#ffe0a0", 0.25), (3, 3, 2.5, "#ffb060", 0.25), (11, 3, 2.5, "#ffb060", 0.25)],
        props=[
            ("interior/amphorae", 1, 1, None), ("interior/amphorae", 13, 1, None),
            ("interior/banner_red", 4, 0, ON_WALL), ("interior/banner_red", 10, 0, ON_WALL),
            ("tapestry", 7, 0, ON_WALL_HIGH), ("oil_lamp", 6, 1, None), ("oil_lamp", 8, 1, None),
            ("village/fountain", 7, 5, None),
            ("sofa_gold", 2, 3, None), ("interior/cushions", 3, 5, None), ("interior/low_table", 3, 4, None),
            ("sofa_gold", 12, 3, None), ("interior/cushions", 11, 5, None), ("interior/low_table", 11, 4, None),
            ("potted_plant", 1, 8, None), ("potted_plant", 13, 8, None), ("interior/amphorae", 13, 9, None),
            ("interior/cushions", 2, 9, None), ("interior/low_table", 11, 8, None),
        ],
        people=[(7, 2), (4, 7), (10, 6)], spots=[(7, 3), (2, 2)], chests=[(12, 2)],
    ),
    "keep_hall": dict(
        size=(17, 11), door=8, floor="flag", wall="stone", tint="#dcd4cc",
        rugs=[(7, 2, 3, 8, "#7a1e22", "#c9a45f")],
        glows=[(3, 1, 3, "#ff9a40", 0.4), (13, 1, 3, "#ff9a40", 0.4), (8, 5, 3, "#ffcf80", 0.18)],
        props=[
            ("interior/banner_red", 5, 0, ON_WALL), ("interior/banner_blue", 7, 0, ON_WALL),
            ("interior/banner_red", 9, 0, ON_WALL), ("interior/banner_blue", 11, 0, ON_WALL),
            ("interior/fireplace", 2, 0, TWO_ON_WALL), ("interior/fireplace", 13, 0, TWO_ON_WALL),
            ("sofa_gold", 8, 1, None), ("brazier", 6, 1, None), ("brazier", 10, 1, None),
            ("interior/table_long", 4, 5, TWO), ("interior/bench_low", 4, 6, TWO), ("interior/bench_low", 4, 4, TWO),
            ("interior/table_long", 11, 5, TWO), ("interior/bench_low", 11, 6, TWO), ("interior/bench_low", 11, 4, TWO),
            ("interior/sword_rack", 15, 3, None), ("tall_clock", 15, 6, None), ("interior/bookshelf", 1, 4, None),
            ("interior/candelabra", 6, 8, None), ("interior/candelabra", 10, 8, None),
            ("interior/crates", 15, 9, None), ("village/barrels", 1, 9, None), ("scroll_rack", 1, 7, None),
        ],
        people=[(8, 2), (4, 8), (13, 8), (10, 2), (6, 3), (10, 3)], spots=[(8, 5), (11, 2)], chests=[(2, 2)],
    ),
    "thorn_hall": dict(
        size=(17, 11), door=8, floor="flag", wall="stone", tint="#d8d0d8",
        rugs=[(6, 3, 5, 3, "#2c4a2c", "#b0a060"), (7, 6, 3, 4, "#2c4a2c", "#b0a060")],
        glows=[(12, 2, 3, "#ffe0a0", 0.35), (4, 2, 3, "#ffe0a0", 0.3), (8, 4, 3, "#ffcf80", 0.15)],
        props=[
            ("interior/muster_board", 8, 0, TWO_ON_WALL), ("interior/banner_green", 5, 0, ON_WALL),
            ("interior/banner_green", 11, 0, ON_WALL), ("interior/sword_rack", 13, 0, ON_WALL),
            ("interior/axe_rack", 3, 0, ON_WALL),
            ("interior/candelabra", 12, 1, None), ("interior/candelabra", 13, 2, None),
            ("interior/candelabra", 4, 1, None), ("brazier", 15, 1, None),
            ("writing_desk", 8, 2, None), ("chair", 8, 1, None),
            ("interior/table_long", 3, 5, TWO), ("interior/bench_low", 3, 6, TWO),
            ("interior/table_long", 12, 5, TWO), ("interior/bench_low", 12, 6, TWO),
            ("interior/bench_low", 3, 8, TWO), ("interior/bench_low", 12, 8, TWO),
            ("interior/bookshelf", 15, 4, None), ("cabinet", 1, 4, None), ("drawers_red", 1, 7, None),
            ("interior/crates", 15, 9, None), ("village/barrels", 1, 9, None),
        ],
        people=[(8, 3), (4, 3), (13, 6)], spots=[(8, 4), (12, 3)], chests=[(2, 2)],
    ),
}


def solid(art: str, entry: dict) -> bool:
    if "solid" in entry:
        return bool(entry["solid"])
    found = PROPS["art"].get(art, {})
    if isinstance(found, str):
        found = {"kind": found}
    kind = PROPS["kinds"].get(found.get("kind", ""), {})
    return bool(found.get("solid", kind.get("solid", False)))


def base(art: str) -> tuple[int, int]:
    found = PROPS["art"].get(art, {})
    if isinstance(found, str):
        found = {"kind": found}
    kind = PROPS["kinds"].get(found.get("kind", ""), {})
    b = found.get("base", kind.get("base", [1, 1]))
    return int(b[0]), int(b[1])


def footprint(art: str, cell: tuple[int, int]) -> list[tuple[int, int]]:
    w, d = base(art)
    return [(cell[0] + dx - (w - 1) // 2, cell[1] - dy) for dy in range(max(1, d)) for dx in range(max(1, w))]


def build(area_id: str) -> None:
    room = ROOMS[area_id]
    path = AREAS / f"{area_id}.json"
    text = path.read_text(encoding="utf-8")
    data = json.loads(text)
    w, h = room["size"]
    door = room["door"]

    rows = []
    for y in range(h):
        row = ""
        for x in range(w):
            wall = y == 0 or y == h - 1 or x == 0 or x == w - 1
            row += "." if (not wall or (y == h - 1 and x == door)) else "#"
        rows.append(row)
    data["rows"] = rows
    data["legend"] = {".": "floor", "#": "wall"}
    data["layers"] = []
    data["spawn"] = [door, h - 2]
    data["exits"] = [[door, h - 1]]
    data["tint"] = room["tint"]
    data["interior"] = {
        "floor": room["floor"], "wall": room["wall"],
        "rugs": [{"rect": [x, y, rw, rh], "colour": c, "trim": t} for x, y, rw, rh, c, t in room["rugs"]],
        "glows": [{"cell": [x, y], "radius": r, "colour": c, "strength": s} for x, y, r, c, s in room["glows"]],
    }
    props = []
    for art, x, y, offset in room["props"]:
        entry: dict = {"art": art, "cell": [x, y]}
        if offset:
            entry["offset"] = list(offset)
        props.append(entry)
    data["props"] = props
    data["dressing"] = []
    for what, listed, placed in (("people", data.get("people", []), room["people"]),
                                 ("spots", data.get("spots", []), room["spots"]),
                                 ("chests", data.get("chests", []), room["chests"])):
        if len(listed) > len(placed):
            sys.exit("build_interiors: %s has %d %s and places for %d; give the rest somewhere to stand"
                     % (area_id, len(listed), what, len(placed)))
    for person, cell in zip(data.get("people", []), room["people"]):
        person["cell"] = list(cell)
    for spot, cell in zip(data.get("spots", []), room["spots"]):
        spot["cell"] = list(cell)
    for chest, cell in zip(data.get("chests", []), room["chests"]):
        chest["cell"] = list(cell)

    # Walk the room: everything worth reaching must be reachable from the door.
    blocked = set()
    for entry in props:
        if solid(entry["art"], entry):
            blocked |= set(footprint(entry["art"], tuple(entry["cell"])))

    def walkable(c: tuple[int, int]) -> bool:
        x, y = c
        return 0 <= x < w and 0 <= y < h and rows[y][x] == "." and c not in blocked

    start = (door, h - 2)
    seen = {start}
    todo = deque([start])
    while todo:
        x, y = todo.popleft()
        for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if n not in seen and walkable(n):
                seen.add(n)
                todo.append(n)
    problems = []
    for what, cells in (("door", [(door, h - 1)]), ("spot", room["spots"]), ("chest", room["chests"])):
        for c in cells:
            if c not in seen and not (what == "door" and walkable(c)):
                problems.append("%s at %s" % (what, c))
    for c in room["people"]:
        if not walkable(c):
            problems.append("person standing in something at %s" % (c,))
        elif not any(n in seen for n in ((c[0] + 1, c[1]), (c[0] - 1, c[1]), (c[0], c[1] + 1), (c[0], c[1] - 1), c)):
            problems.append("person nobody can reach at %s" % (c,))
    if problems:
        sys.exit("build_interiors: %s cannot be walked: %s" % (area_id, ", ".join(problems)))

    indent = "\t" if '\n\t"' in text else 4
    out = json.dumps(data, indent=indent, ensure_ascii=False)
    path.write_text(out + "\n", encoding="utf-8")
    print("%-16s %2d x %-2d %2d pieces, %d rugs" % (area_id, w, h, len(props), len(room["rugs"])))


def main() -> None:
    for area_id in sys.argv[1:] or list(ROOMS):
        if area_id not in ROOMS:
            print("no room called %s" % area_id)
            continue
        build(area_id)


if __name__ == "__main__":
    main()
