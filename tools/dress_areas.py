#!/usr/bin/env python3
"""Dress the areas: trees, bushes, flowers, birds and bugs out of doors, furniture in the rooms.

    python3 tools/dress_areas.py                 every area with a recipe below
    python3 tools/dress_areas.py village wild_fen

What it writes goes in each area's `"dressing"` list, kept apart from the `"props"` the area's
author placed, so running it again replaces only its own work. The same area always comes out
the same (the seed is the area's id). An area's recipe can also `reshape` its open ground: the
wilds were laid out as a grid of single tufts and a checkerboard of puddles, and get patches and
ponds instead. Paths are never touched.

Nothing is put where it would stop the party reaching the way out, a door, a chest, a spot or
anyone standing in the area: every solid thing is tried against a walk from where the party
comes in, and left out if it cuts anything off. Sizes and what stands in the way come from
`data/props.json`. Standard library only.
"""

import json
import math
import random
import sys
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AREAS = ROOT / "data" / "areas"
PROPS = json.loads((ROOT / "data" / "props.json").read_text(encoding="utf-8"))
TILESETS = json.loads((ROOT / "data" / "tilesets.json").read_text(encoding="utf-8"))

# --- what grows where ---------------------------------------------------------------------------

LEAFY = ["nature/great_oak", "nature/great_oak_2", "nature/round_tree", "nature/birch",
         "nature/sycamore_tree", "nature/copse", "nature/autumn_tree"]
ORCHARD = ["nature/apple_tree", "nature/old_apple_tree", "nature/apple_tree", "nature/birch"]
PINES = ["nature/holly_tree", "nature/holly_tree", "nature/great_oak_2", "nature/birch"]
DEAD = ["nature/dead_tree", "nature/bare_tree"]
BUSHES = ["nature/briar_bush", "nature/briar_bush_2", "nature/bramble", "nature/bramble_2",
          "nature/hazel_bush", "nature/holly_tree_2", "nature/ivy", "nature/rose_stem",
          "nature/rose_stem_2"]
HEDGES = ["nature/hedge", "nature/hedge_2", "nature/hedge_3", "nature/hedge_4"]
FLOWERS = ["nature/wildflowers_blue", "nature/wildflowers_red", "nature/wildflowers_orange",
           "nature/fern", "nature/thistle", "nature/grass_tuft", "nature/grass_tuft",
           "nature/clover", "nature/clover_2", "nature/clover_3"]
DAMP = ["nature/grass_tuft", "nature/grass_tuft", "nature/fern", "nature/fern",
        "nature/thistle", "nature/mushroom_blue"]
STONY = ["nature/pebble", "nature/pebble", "nature/grass_tuft", "nature/thistle"]
SANDY = ["nature/pebble", "nature/cactus", "nature/grass_tuft"]
MUSHROOMS = ["nature/mushrooms", "nature/mushrooms_cluster", "nature/mushrooms_shelf",
             "nature/mushrooms_tall", "nature/mushroom_blue"]
CRITTERS = ["nature/butterfly", "nature/butterfly_blue", "nature/bee", "nature/snail",
            "nature/grasshopper", "nature/ants", "nature/irish_bird_3", "nature/irish_bird_4",
            "nature/sparrow", "nature/finch", "nature/irish_bird", "nature/irish_bird_2"]
WET_CRITTERS = ["nature/snail", "nature/spider", "nature/grasshopper", "nature/white_dove",
                "nature/irish_bird_3"]
DRY_CRITTERS = ["nature/ants", "nature/spider", "nature/grasshopper", "nature/sparrow"]

## Out of doors: `trees` near the edge (`edge`) and further in (`inner`), kept `gap` cells apart;
## `bushes`, `ground` cover and `mushrooms` (near trees) as shares of the free cells; a count of
## `critters`. `on` is the ground each grows on. `reshape` reworks the open ground (see below).
OUTDOORS = {
    "wild_grove": dict(trees=LEAFY, edge=0.6, inner=0.2, gap=2, bushes=BUSHES, bush=0.05,
                       ground=FLOWERS, cover=0.16, mushrooms=MUSHROOMS, shroom=0.25, critters=CRITTERS,
                       count=9, on=["grass", "meadow"], reshape=dict(kind="patches", terrain="meadow", share=0.32)),
    "wild_thicket": dict(trees=LEAFY + ["nature/autumn_tree_2"], edge=0.65, inner=0.24, gap=2,
                         bushes=BUSHES + BUSHES, bush=0.12, ground=FLOWERS, cover=0.12, mushrooms=MUSHROOMS,
                         shroom=0.3, critters=CRITTERS, count=7, on=["grass", "meadow"],
                         reshape=dict(kind="patches", terrain="meadow", share=0.4)),
    "wild_fen": dict(trees=DEAD + ["nature/round_tree", "nature/great_oak_2"], edge=0.4, inner=0.1, gap=2,
                     bushes=["nature/ivy", "nature/bramble", "nature/briar_bush_2", "nature/rose_stem"], bush=0.04,
                     ground=DAMP, cover=0.2, mushrooms=MUSHROOMS, shroom=0.2, critters=WET_CRITTERS, count=7,
                     on=["meadow", "grass"], reshape=dict(kind="ponds", terrain="water", share=0.24)),
    "wild_scarp": dict(trees=DEAD + ["nature/holly_tree"], edge=0.3, inner=0.04, gap=3,
                       bushes=["nature/briar_bush", "nature/bramble_2", "nature/thistle"], bush=0.04,
                       ground=STONY, cover=0.14, critters=DRY_CRITTERS, count=4, on=["raised", "dirt"],
                       rocks=["nature/crystal_spikes"], rock=0.012, path=["dirt"]),
    "wild_oasis": dict(trees=["nature/birch", "nature/round_tree", "nature/dead_tree"], edge=0.12, inner=0.03,
                       gap=3, near_water=True, bushes=["nature/rose_stem", "nature/hazel_bush"], bush=0.03,
                       ground=SANDY, cover=0.1, critters=DRY_CRITTERS, count=4, on=["sand"], path=["dirt"]),
    "village": dict(trees=ORCHARD + ["nature/sycamore_tree", "nature/great_oak"], edge=0.4, inner=0.0, gap=2,
                    bushes=HEDGES + ["nature/rose_stem", "nature/hazel_bush"], bush=0.025, ground=FLOWERS,
                    cover=0.12, critters=CRITTERS, count=6, on=["grass", "meadow"], keep_clear=2),
    "city": dict(trees=ORCHARD + ["nature/sycamore_tree"], edge=0.3, inner=0.0, gap=2, bushes=HEDGES, bush=0.02,
                 ground=FLOWERS, cover=0.1, critters=CRITTERS, count=4, on=["grass", "meadow"], keep_clear=2,
                 path=["dirt", "flagstone"]),
    "city_streets": dict(trees=LEAFY + ORCHARD, edge=0.0, inner=0.06, gap=3, bushes=HEDGES + ["nature/rose_stem"],
                         bush=0.02, ground=FLOWERS, cover=0.08, critters=CRITTERS + ["nature/white_dove"] * 3,
                         count=12, on=["meadow", "grass"], keep_clear=1, path=["dirt", "flagstone"]),
    "village_fen": dict(trees=DEAD + ["nature/round_tree", "nature/birch"], edge=0.35, inner=0.0, gap=2,
                        bushes=["nature/ivy", "nature/bramble"], bush=0.03, ground=DAMP, cover=0.14,
                        critters=WET_CRITTERS, count=5, on=["grass", "meadow"], keep_clear=2),
    "village_pines": dict(trees=PINES, edge=0.5, inner=0.02, gap=2, bushes=["nature/holly_tree_2", "nature/bramble"],
                          bush=0.03, ground=FLOWERS, cover=0.1, critters=CRITTERS, count=5,
                          on=["grass", "meadow"], keep_clear=2),
    "village_shore": dict(trees=["nature/birch", "nature/sycamore_tree", "nature/round_tree"], edge=0.3, inner=0.0,
                          gap=3, bushes=HEDGES, bush=0.02, ground=FLOWERS + STONY, cover=0.1,
                          critters=["nature/white_dove", "nature/sparrow", "nature/snail", "nature/irish_bird_3"],
                          count=5, on=["grass", "meadow", "sand"], keep_clear=2),
    "village_dune": dict(trees=["nature/dead_tree", "nature/birch"], edge=0.12, inner=0.0, gap=3,
                         bushes=["nature/rose_stem"], bush=0.01, ground=SANDY, cover=0.08,
                         critters=DRY_CRITTERS, count=4, on=["sand"], keep_clear=2),
    "tutorial": dict(trees=ORCHARD + LEAFY, edge=0.55, inner=0.0, gap=2, bushes=HEDGES + ["nature/hazel_bush"],
                     bush=0.03, ground=FLOWERS, cover=0.14, critters=CRITTERS, count=6, on=["grass", "meadow"],
                     keep_clear=2),
    "keep": dict(trees=LEAFY, edge=0.45, inner=0.0, gap=2, bushes=HEDGES, bush=0.02, ground=FLOWERS,
                 cover=0.1, critters=CRITTERS, count=4, on=["grass", "meadow"], keep_clear=1, path=["dirt", "flagstone"]),
    "keep_thorn": dict(trees=LEAFY + DEAD, edge=0.45, inner=0.0, gap=2, bushes=BUSHES, bush=0.04, ground=FLOWERS,
                       cover=0.1, critters=CRITTERS, count=4, on=["grass", "meadow"], keep_clear=1),
    "hut": dict(trees=LEAFY, edge=0.5, inner=0.0, gap=2, bushes=BUSHES, bush=0.05, ground=FLOWERS, cover=0.14,
                mushrooms=MUSHROOMS, shroom=0.2, critters=CRITTERS, count=4, on=["grass", "meadow"], keep_clear=1),
    "hut_orchard": dict(trees=ORCHARD, edge=0.55, inner=0.0, gap=2, bushes=["nature/apple_trellis", "nature/hazel_bush"],
                        bush=0.04, ground=FLOWERS, cover=0.14, critters=CRITTERS, count=5, on=["grass", "meadow"], keep_clear=1),
    "hut_stilt": dict(trees=DEAD + ["nature/round_tree"], edge=0.3, inner=0.0, gap=2, bushes=["nature/ivy"], bush=0.04,
                      ground=DAMP, cover=0.18, mushrooms=MUSHROOMS, shroom=0.2, critters=WET_CRITTERS, count=4,
                      on=["meadow", "grass"], keep_clear=1),
    "hut_cairn": dict(trees=DEAD, edge=0.25, inner=0.0, gap=3, bushes=["nature/briar_bush"], bush=0.03, ground=STONY,
                      cover=0.14, critters=DRY_CRITTERS, count=3, on=["dirt", "stone"], keep_clear=1, path=["dirt"]),
    "home": dict(trees=LEAFY, edge=0.5, inner=0.0, gap=2, bushes=BUSHES, bush=0.04, ground=FLOWERS, cover=0.16,
                 mushrooms=MUSHROOMS, shroom=0.2, critters=CRITTERS, count=5, on=["grass", "meadow"], keep_clear=1),
    "camp": dict(trees=LEAFY, edge=0.6, inner=0.0, gap=2, bushes=BUSHES, bush=0.04, ground=FLOWERS, cover=0.14,
                 mushrooms=MUSHROOMS, shroom=0.25, critters=CRITTERS, count=4, on=["grass", "meadow"], keep_clear=1),
    "library": dict(trees=LEAFY, edge=0.6, inner=0.0, gap=2, bushes=HEDGES, bush=0.05, ground=FLOWERS, cover=0.15,
                    critters=CRITTERS, count=4, on=["grass"], keep_clear=0, path=["flagstone"]),
    "library_cloister": dict(trees=["nature/birch", "nature/sycamore_tree"], edge=0.3, inner=0.0, gap=3, bushes=HEDGES,
                             bush=0.03, ground=FLOWERS, cover=0.18, critters=CRITTERS, count=4,
                             on=["grass", "meadow"], keep_clear=1, path=["flagstone", "dirt"]),
    "tower": dict(trees=DEAD + LEAFY, edge=0.6, inner=0.0, gap=2, bushes=BUSHES, bush=0.05, ground=FLOWERS,
                  cover=0.12, critters=CRITTERS, count=3, on=["grass"], keep_clear=0, path=["flagstone", "stone"]),
    "gate": dict(trees=DEAD, edge=0.25, inner=0.0, gap=3, bushes=["nature/briar_bush"], bush=0.03, ground=STONY,
                 cover=0.12, critters=DRY_CRITTERS, count=3, on=["grass"], keep_clear=1, path=["stone"]),
    "gate_barrow": dict(trees=DEAD + ["nature/holly_tree"], edge=0.3, inner=0.0, gap=3, bushes=BUSHES, bush=0.03,
                        ground=STONY + FLOWERS, cover=0.14, mushrooms=MUSHROOMS, shroom=0.15, critters=DRY_CRITTERS,
                        count=3, on=["grass", "meadow"], keep_clear=1, path=["stone", "dirt"]),
    "gate_drowned": dict(trees=DEAD, edge=0.2, inner=0.0, gap=3, bushes=["nature/ivy"], bush=0.03, ground=DAMP,
                         cover=0.14, critters=WET_CRITTERS, count=3, on=["grass", "sand"], keep_clear=1, path=["stone"]),
    "gate_ash": dict(trees=DEAD, edge=0.3, inner=0.0, gap=3, ground=STONY, cover=0.12, critters=["nature/spider", "nature/ants"],
                     count=2, on=["dirt"], keep_clear=1, path=["stone"]),
    "gate_dune": dict(trees=["nature/dead_tree"], edge=0.15, inner=0.0, gap=3, ground=SANDY, cover=0.1,
                      critters=DRY_CRITTERS, count=2, on=["sand"], keep_clear=1, path=["stone"]),
    "library_vault": dict(trees=[], edge=0.0, inner=0.0, gap=3, ground=STONY, cover=0.06,
                          critters=["nature/spider", "nature/snail"], count=2, on=["stone"], keep_clear=1,
                          path=["flagstone"]),
    # The Tower's walked floors (D102): bare stone, a little rubble, something small living in it.
    **{"tower_floor_%d" % n: dict(trees=[], edge=0.0, inner=0.0, gap=3, ground=STONY, cover=0.05,
                                  critters=["nature/spider", "nature/snail"], count=2, on=["stone"], keep_clear=1,
                                  path=["flagstone"]) for n in range(1, 6)},
}

## Rooms: furniture against the walls by what the room is, leaving the middle and the way in.
ROOMS = {
    "village_inn": "inn", "fen_alehouse": "inn", "shore_taphouse": "inn", "pine_longhouse": "longhouse",
    "dune_serai": "inn", "keep_hall": "hall", "thorn_hall": "hall",
}
## Per room kind: what goes along the back wall (left to right), in the back corners, down each
## side, and by the door. Each is drawn from in order and stops when the wall is full.
ROOM_KIT = {
    "inn": dict(back=["village/barrels", "sideboard", "tapestry", "sideboard", "village/barrels"],
                corners=["camp/fire_hearth", "village/log_pile"],
                sides=["writing_desk", "chair", "sofa_brown", "chair", "drawers_wood", "potted_plant", "oil_lamp"],
                door=["potted_plant", "street_lamp"]),
    "longhouse": dict(back=["tapestry", "village/barrels", "camp/fire_logs", "village/barrels", "tapestry"],
                      corners=["village/log_pile", "village/log_pile"],
                      sides=["village/bench", "village/loom", "chest", "village/bench", "drawers_wood", "oil_lamp"],
                      door=["village/hide_rack", "potted_plant"]),
    "hall": dict(back=["tapestry", "tall_clock", "tapestry", "landmark/sword_storm", "tapestry"],
                 corners=["brazier", "brazier"],
                 sides=["sofa_gold", "scroll_rack", "cabinet", "writing_desk", "drawers_red", "globe"],
                 door=["lamp_post_twin", "lamp_post_twin"]),
}

PATHS = ["dirt", "stone", "flagstone"]


def _size(art: str) -> dict:
    entry = PROPS["art"].get(art, {})
    if isinstance(entry, str):
        entry = {"kind": entry}
    out = {"scale": 1.0, "solid": False, "base": [1, 1]}
    out.update(PROPS["kinds"].get(entry.get("kind", ""), {}))
    out.update(entry)
    return out


def _walkable_terrain(name: str) -> bool:
    return bool(TILESETS["terrains"].get(name, {}).get("walkable", True))


def _cell(pair) -> tuple[int, int]:
    return int(pair[0]), int(pair[1])


class Area:
    def __init__(self, area_id: str):
        self.id = area_id
        self.path = AREAS / (area_id + ".json")
        text = self.path.read_text(encoding="utf-8")
        self.data = json.loads(text)
        # Written back the way it was written, so a diff shows only what changed.
        second = text.split("\n", 2)[1] if "\n" in text else ""
        self.indent = max(1, len(second) - len(second.lstrip(" "))) if second.startswith(" ") else (1 if second.startswith("\t") else 2)
        self.ascii = "\\u" in text
        self.rows = [list(r) for r in self.data["rows"]]
        self.h = len(self.rows)
        self.w = max(len(r) for r in self.rows)
        for r in self.rows:
            r.extend("." * (self.w - len(r)))
        self.legend = dict(self.data.get("legend", {}))
        self.symbol = {v: k for k, v in self.legend.items()}
        self.blocked: set = set()
        self.must_reach: set = set()
        self.reserved: set = set()
        self._gather()

    def terrain(self, c) -> str:
        x, y = c
        x = min(max(x, 0), self.w - 1)
        y = min(max(y, 0), self.h - 1)
        return self.legend.get(self.rows[y][x], "grass")

    def inside(self, c) -> bool:
        return 0 <= c[0] < self.w and 0 <= c[1] < self.h

    def _gather(self) -> None:
        d = self.data
        self.spawn = _cell(d.get("spawn", [0, 0]))
        stand = [self.spawn] + [_cell(e) for e in d.get("exits", [])]
        stand += [_cell(s["cell"]) for s in d.get("spots", [])]
        stand += [_cell(c["cell"]) for c in d.get("chests", [])]
        stand += [_cell(p["cell"]) for p in d.get("people", [])]
        stand += [_cell(s["cell"]) for p in d.get("people", []) for s in p.get("rounds", [])]
        stand += [_cell(s) for s in d.get("seats", [])]
        if "fire" in d:
            self.blocked.add(_cell(d["fire"]))
            self.reserved.add(_cell(d["fire"]))
        for ward in d.get("wards", []):
            self.reserved.add(_cell(ward["cell"]))
        for b in d.get("buildings", []):
            look = PROPS.get("buildings", {}).get(b.get("art", ""), {})
            size = b.get("size", look.get("size", [3, 3]))
            x0, y0 = _cell(b["cell"])
            door = _cell(b["door"]) if "door" in b else (x0 + size[0] // 2, y0 + size[1] - 1)
            for y in range(y0 - 1, y0 + size[1]):
                for x in range(x0 - 1, x0 + size[0] + 1):
                    self.reserved.add((x, y))
                    if y >= y0 and x0 <= x < x0 + size[0] and (x, y) != door:
                        self.blocked.add((x, y))
            stand.append(door)
            stand.append((door[0], door[1] + 1))
        for p in d.get("props", []):
            c = _cell(p["cell"])
            self.reserved.add(c)
            s = _size(p.get("art", ""))
            if p.get("solid", s.get("solid", False)):
                for cell in self.base(c, p.get("base", s.get("base", [1, 1]))):
                    self.blocked.add(cell)
        self.must_reach = set(stand)
        for c in stand:
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    self.reserved.add((c[0] + dx, c[1] + dy))
        # The game leaves an authored standing cell open whatever is drawn on it ([AreaMap]).
        self.blocked -= self.must_reach

    @staticmethod
    def base(c, size) -> list:
        w, d = int(size[0]), int(size[1])
        return [(c[0] + dx - (w - 1) // 2, c[1] - dy) for dy in range(max(1, d)) for dx in range(max(1, w))]

    def walkable(self, c, extra=()) -> bool:
        return self.inside(c) and c not in self.blocked and c not in extra and _walkable_terrain(self.terrain(c))

    def connected(self, extra=()) -> bool:
        if not self.walkable(self.spawn, extra):
            return False
        seen = {self.spawn}
        queue = deque([self.spawn])
        while queue:
            x, y = queue.popleft()
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if n not in seen and self.walkable(n, extra):
                    seen.add(n)
                    queue.append(n)
        return all(c in seen or not self.inside(c) for c in self.must_reach)

    def set_terrain(self, c, name: str) -> None:
        if name not in self.symbol:
            sym = next(ch for ch in "mw~#*%" if ch not in self.legend)
            self.legend[sym] = name
            self.symbol[name] = sym
        self.rows[c[1]][c[0]] = self.symbol[name]


# --- reshaping the open ground ------------------------------------------------------------------


def _noise(rng: random.Random, w: int, h: int, scale: float) -> list:
    """Smooth value noise in [0, 1], one value a cell."""
    gw, gh = int(w / scale) + 3, int(h / scale) + 3
    grid = [[rng.random() for _ in range(gw)] for _ in range(gh)]

    def smooth(t: float) -> float:
        return t * t * (3 - 2 * t)

    out = []
    for y in range(h):
        row = []
        for x in range(w):
            fx, fy = x / scale, y / scale
            ix, iy = int(fx), int(fy)
            tx, ty = smooth(fx - ix), smooth(fy - iy)
            a = grid[iy][ix] + (grid[iy][ix + 1] - grid[iy][ix]) * tx
            b = grid[iy + 1][ix] + (grid[iy + 1][ix + 1] - grid[iy + 1][ix]) * tx
            row.append(a + (b - a) * ty)
        out.append(row)
    return out


def reshape(area: Area, rule: dict, rng: random.Random, paths: list) -> None:
    kind, terrain, share = rule["kind"], rule["terrain"], float(rule["share"])
    base = "grass" if kind == "patches" else "meadow"
    if base not in area.symbol and kind == "patches":
        base = next(t for t in ("grass", "meadow") if t in area.symbol)
    noise = _noise(rng, area.w, area.h, 3.2 if kind == "patches" else 1.9)
    open_cells = [(x, y) for y in range(area.h) for x in range(area.w)
                  if area.terrain((x, y)) not in paths and area.terrain((x, y)) in (base, terrain)]
    # The open ground goes back to one kind, then the noisiest share of it becomes the other.
    for c in open_cells:
        area.set_terrain(c, base)
    ranked = sorted(open_cells, key=lambda c: -noise[c[1]][c[0]])
    wanted = int(len(open_cells) * share)
    placed = 0
    for c in ranked:
        if placed >= wanted:
            break
        if kind == "ponds":
            # Water stands back from paths and everyone who has to be reached.
            beside = [(c[0] + 1, c[1]), (c[0] - 1, c[1]), (c[0], c[1] + 1), (c[0], c[1] - 1)]
            if c in area.reserved or any(area.terrain(n) in paths for n in beside):
                continue
            area.set_terrain(c, terrain)
            if not area.connected():
                area.set_terrain(c, base)
                continue
        else:
            area.set_terrain(c, terrain)
        placed += 1


def _around(c) -> list:
    return [(c[0] + dx, c[1] + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]


# --- placing -------------------------------------------------------------------------------------


def dress_outdoors(area: Area, recipe: dict, rng: random.Random) -> list:
    out: list = []
    taken: set = set(area.reserved)
    paths = recipe.get("path", PATHS)
    grows_on = recipe.get("on", ["grass"])
    clear = int(recipe.get("keep_clear", 1))

    def near_path(c, reach: int) -> bool:
        return any(area.terrain((c[0] + dx, c[1] + dy)) in paths
                   for dx in range(-reach, reach + 1) for dy in range(-reach, reach + 1))

    def edge_distance(c) -> int:
        return min(c[0], c[1], area.w - 1 - c[0], area.h - 1 - c[1])

    def near_water(c) -> bool:
        return any(area.terrain((c[0] + dx, c[1] + dy)) == "water" for dx in (-2, -1, 0, 1, 2) for dy in (-2, -1, 0, 1, 2))

    def place(art: str, c, solid_try: bool) -> bool:
        size = _size(art)
        extra = set()
        if solid_try and size.get("solid", False):
            extra = set(area.base(c, size.get("base", [1, 1])))
            if any(not area.walkable(e) for e in extra if area.inside(e)) and c in extra and not area.walkable(c):
                return False
            if not area.connected(extra):
                return False
            area.blocked |= extra
        jitter = 10 if size["scale"] >= 2 else 14
        entry = {"art": art, "cell": [c[0], c[1]]}
        ox, oy = rng.randint(-jitter, jitter), rng.randint(-jitter // 2, jitter // 2)
        if ox or oy:
            entry["offset"] = [ox, oy]
        if rng.random() < 0.5:
            entry["flip"] = True
        out.append(entry)
        taken.add(c)
        return True

    cells = [(x, y) for y in range(area.h) for x in range(area.w)]
    rng.shuffle(cells)
    trees: list = []
    tree_arts = recipe.get("trees", [])
    for c in cells:
        if not tree_arts or c in taken or area.terrain(c) not in grows_on:
            continue
        if near_path(c, clear) or any(abs(c[0] - t[0]) < recipe["gap"] and abs(c[1] - t[1]) < recipe["gap"] for t in trees):
            continue
        chance = recipe["edge"] if edge_distance(c) <= 1 else recipe["inner"]
        if recipe.get("near_water") and near_water(c):
            chance = max(chance, 0.45)
        if rng.random() < chance and place(rng.choice(tree_arts), c, True):
            trees.append(c)

    for art in recipe.get("rocks", []):
        for c in cells:
            if c not in taken and area.terrain(c) in grows_on and not near_path(c, 1) and rng.random() < recipe.get("rock", 0):
                place(art, c, True)

    for c in cells:
        if c in taken or area.terrain(c) not in grows_on:
            continue
        if recipe.get("mushrooms") and any(abs(c[0] - t[0]) <= 1 and abs(c[1] - t[1]) <= 1 for t in trees):
            if rng.random() < recipe.get("shroom", 0):
                place(rng.choice(recipe["mushrooms"]), c, False)
                continue
        if recipe.get("bushes") and not near_path(c, max(0, clear - 1)) and rng.random() < recipe.get("bush", 0):
            if place(rng.choice(recipe["bushes"]), c, True):
                continue
        if recipe.get("ground") and rng.random() < recipe.get("cover", 0):
            place(rng.choice(recipe["ground"]), c, False)

    free = [c for c in cells if c not in taken and _walkable_terrain(area.terrain(c)) and c not in area.blocked]
    for c in free[: int(recipe.get("count", 0))]:
        place(rng.choice(recipe["critters"]), c, False)
    return out


def dress_room(area: Area, kit: dict, rng: random.Random) -> list:
    out: list = []
    w, h = area.w, area.h
    door_x = area.spawn[0]

    def put(art: str, c) -> None:
        if c in area.must_reach or c in [tuple(o["cell"]) for o in out] or not area.inside(c):
            return
        size = _size(art)
        extra = set(area.base(c, size.get("base", [1, 1]))) if size.get("solid", False) else set()
        if extra and not area.connected(extra):
            return
        area.blocked |= extra
        out.append({"art": art, "cell": [c[0], c[1]]})

    corners = list(kit["corners"])
    put(corners[0], (0, 0))
    put(corners[-1], (w - 1, 0))
    back = kit["back"]
    span = list(range(2, w - 2))
    for index, art in enumerate(back):
        if not span:
            break
        x = span[int((index + 0.5) * len(span) / len(back))]
        put(art, (x, 0))
    sides = kit["sides"]
    for index, art in enumerate(sides):
        y = 2 + index // 2 * 2
        if y >= h - 2:
            break
        put(art, (0, y) if index % 2 == 0 else (w - 1, y))
    for index, art in enumerate(kit["door"]):
        put(art, (door_x - 2 if index == 0 else door_x + 2, h - 1))
    return out


def run(area_id: str) -> None:
    area = Area(area_id)
    # A room with an `interior` is laid out by hand in tools/build_interiors.py (D81).
    if "interior" in area.data:
        print("%-18s laid out by build_interiors.py, left alone" % area_id)
        return
    rng = random.Random("earth-kings:" + area_id)
    if area_id in ROOMS:
        dressing = dress_room(area, ROOM_KIT[ROOMS[area_id]], rng)
    else:
        recipe = OUTDOORS[area_id]
        if "reshape" in recipe:
            reshape(area, recipe["reshape"], rng, recipe.get("path", PATHS))
            area.data["rows"] = ["".join(r) for r in area.rows]
            area.data["legend"] = area.legend
            if recipe["reshape"]["terrain"] not in area.data.get("layers", []):
                area.data.setdefault("layers", []).append(recipe["reshape"]["terrain"])
        dressing = dress_outdoors(area, recipe, rng)
    if not area.connected():
        sys.exit("dress_areas: %s cannot be walked through even before dressing" % area_id)
    area.data["dressing"] = []
    text = json.dumps(area.data, indent=area.indent, ensure_ascii=area.ascii)
    # One piece a line: there are hundreds, and nobody reads them one field a line.
    pad = " " * (area.indent * 2)
    pieces = (",\n").join(pad + json.dumps(d, ensure_ascii=area.ascii, separators=(", ", ": ")) for d in dressing)
    empty = '"dressing": []'
    text = text.replace(empty, '"dressing": [\n%s\n%s]' % (pieces, " " * area.indent) if dressing else empty)
    area.path.write_text(text + "\n", encoding="utf-8")
    print("%-18s %3d pieces" % (area_id, len(dressing)))


def main() -> None:
    wanted = sys.argv[1:] or sorted(list(OUTDOORS) + list(ROOMS))
    for area_id in wanted:
        if area_id not in OUTDOORS and area_id not in ROOMS:
            print("no recipe for %s" % area_id)
            continue
        run(area_id)


if __name__ == "__main__":
    main()
