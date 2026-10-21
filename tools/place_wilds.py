#!/usr/bin/env python3
"""Put the wild places on the one world's map (D309): places worth going to.

    python3 tools/place_wilds.py            rewrite the `wild` sites in data/world_map.json
    python3 tools/place_wilds.py --dry      say where they would go, write nothing

The founders (D287): places worth going to, with loot, a quest or a story in each. The wilds
(the ancient grove, the thorn thicket, the drowned fen, the quiet oasis, the wind scarp) were only
stumbled on, one tile in sixteen, with no way to aim for one. This puts `per_world` of them on the
map as sites of kind `wild`: on ground of their own kind (forest and brush for the grove and the
thicket, marsh for the fen, sand for the oasis, hill for the scarp, and since D321 crag for the
cloud peak; since D329 the hamlets on grass, wood and sand), never within `clear` tiles of
another place and `apart` tiles of each other, dealt from the map's own seed so the same map gets
the same wilds. A run finds one by walking onto it, or hears of it at rest in a settlement
(src/chronicle/wilds.gd), which marks it on the map. Every other site on the map is left as it is.
Standard library only.
"""
from __future__ import annotations

import json
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAP = ROOT / "data" / "world_map.json"

PER_WORLD = 12
CLEAR = 5
APART = 12
LEGEND = {".": "grass", ",": "brush", "^": "hill", "A": "crag", "~": "water", "#": "wall", "=": "road",
          "o": "ocean", "l": "lake", "s": "sand", "w": "snow", "f": "forest", "b": "marsh"}
AREAS = {"forest": ["wild_grove", "wild_thicket"], "brush": ["wild_thicket", "wild_grove"],
         "marsh": ["wild_fen"], "sand": ["wild_oasis"], "hill": ["wild_scarp"]}
NAMES = {
    "wild_grove": ["the ancient grove", "the mossed grove", "the hush wood"],
    "wild_thicket": ["the thorn thicket", "the briar maze", "the snare thicket"],
    "wild_fen": ["the drowned fen", "the black fen", "the reed hollow"],
    "wild_oasis": ["the quiet oasis", "the palm spring", "the hidden well"],
    "wild_scarp": ["the wind scarp", "the high shelf", "the gull scarp"],
    "wild_peak": ["the cloud peak", "the white horn"],
    "hamlet_fold": ["Ewe's Hollow", "Lambsend"],
    "hamlet_mill": ["Millrace", "the Wheelwater"],
    "hamlet_salt": ["Saltcote", "the Brine Huts"],
}
# D321: the mountains' own wild, the cloud peak, on crag, dealt after the twelve with a deal of its own
# so the twelve stand where they stood.
PEAKS = 2
# D329: the hamlets, a few crofts each with folk, a want and a trouble, dealt last with a deal of their
# own, each on its own ground, so everything before them stands where it stood.
HAMLETS = {"hamlet_fold": ["grass"], "hamlet_mill": ["forest", "brush"], "hamlet_salt": ["sand"]}
HAMLETS_EACH = 2
# Out past what the crater's first sight takes in, so a hamlet is come upon, not seen from the start.
HOME_CLEAR = 24
# How many of each kind the map gets, in the order they are dealt.
DEAL = ["wild_scarp", "wild_grove", "wild_fen", "wild_oasis", "wild_thicket", "wild_scarp",
        "wild_grove", "wild_fen", "wild_oasis", "wild_thicket", "wild_scarp", "wild_grove"]


def far(cell: tuple, others: list, at_least: int) -> bool:
    return all(max(abs(cell[0] - o[0]), abs(cell[1] - o[1])) >= at_least for o in others)


def main() -> None:
    dry = "--dry" in sys.argv
    data = json.loads(MAP.read_text(encoding="utf-8"))
    tiles = data["tiles"]
    kept = [s for s in data["sites"] if s.get("kind") != "wild"]
    taken = [tuple(s["cell"]) for s in kept]
    rng = random.Random(int(data.get("from_seed", 1)) + 309)
    by_area: dict[str, list] = {}
    for y, row in enumerate(tiles):
        for x, symbol in enumerate(row):
            terrain = LEGEND.get(symbol, "grass")
            for area in AREAS.get(terrain, []):
                by_area.setdefault(area, []).append((x, y))
    for cells in by_area.values():
        rng.shuffle(cells)
    placed: list[dict] = []
    used_names: dict[str, int] = {}
    for area in DEAL[:PER_WORLD]:
        for cell in by_area.get(area, []):
            if 2 <= cell[0] < len(tiles[0]) - 2 and 2 <= cell[1] < len(tiles) - 2 \
                    and far(cell, taken, CLEAR) and far(cell, [tuple(p["cell"]) for p in placed], APART):
                index = used_names.get(area, 0)
                names = NAMES[area]
                if index >= len(names):
                    break
                used_names[area] = index + 1
                placed.append({
                    "broken": False, "cell": [cell[0], cell[1]], "cleared": False,
                    "data": {"area": area}, "display_name": names[index], "kind": "wild",
                    "open": False, "opened_at": 0, "rank": "",
                })
                break
    peaks = [(x, y) for y, row in enumerate(tiles) for x, symbol in enumerate(row) if LEGEND.get(symbol) == "crag"]
    random.Random(int(data.get("from_seed", 1)) + 321).shuffle(peaks)
    for index in range(PEAKS):
        for cell in peaks:
            if 2 <= cell[0] < len(tiles[0]) - 2 and 2 <= cell[1] < len(tiles) - 2 \
                    and far(cell, taken, CLEAR) and far(cell, [tuple(p["cell"]) for p in placed], APART):
                placed.append({
                    "broken": False, "cell": [cell[0], cell[1]], "cleared": False,
                    "data": {"area": "wild_peak"}, "display_name": NAMES["wild_peak"][index], "kind": "wild",
                    "open": False, "opened_at": 0, "rank": "",
                })
                break
    rng = random.Random(int(data.get("from_seed", 1)) + 329)
    home = [tuple(s["cell"]) for s in kept if s.get("kind") == "home"]
    for index in range(HAMLETS_EACH):
        for area, grounds in HAMLETS.items():
            cells = [(x, y) for y, row in enumerate(tiles) for x, symbol in enumerate(row)
                     if LEGEND.get(symbol, "grass") in grounds]
            rng.shuffle(cells)
            for cell in cells:
                if 2 <= cell[0] < len(tiles[0]) - 2 and 2 <= cell[1] < len(tiles) - 2 \
                        and far(cell, taken, CLEAR) and far(cell, [tuple(p["cell"]) for p in placed], APART) \
                        and far(cell, home, HOME_CLEAR):
                    placed.append({
                        "broken": False, "cell": [cell[0], cell[1]], "cleared": False,
                        "data": {"area": area}, "display_name": NAMES[area][index], "kind": "wild",
                        "open": False, "opened_at": 0, "rank": "",
                    })
                    break
    for place in placed:
        print("%-20s %-13s at %s" % (place["display_name"], place["data"]["area"], place["cell"]))
    print("%d wild places" % len(placed))
    if dry:
        return
    data["sites"] = kept + placed
    MAP.write_text(json.dumps(data, indent="\t", ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
    print("wrote", MAP.relative_to(ROOT))


if __name__ == "__main__":
    main()
