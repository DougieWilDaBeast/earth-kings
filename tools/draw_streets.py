#!/usr/bin/env python3
"""Draw the great city's paving, the same sandstone as the Tower's yard, and lay the city in it.

    python3 tools/draw_streets.py

Needs Pillow (`pip install pillow`), like tools/draw_road.py.

Stormreach's gate ward (data/areas/city.json) and its streets (city_streets.json) were paved in the
battle ground's ornate cream, gold and blue flags, the floor D133 took out of the Tower's yard: loud
enough that the stalls, the people and the way on were hard to pick out. D135 draws the city's
paving in house from the yard's own flags (tools/draw_yard.py), as a sheet in the 24 x 8 layout
every PixelLab "godot" sheet shares (src/area/tile_forge.gd):

- art/tilesets/yard/street_paving.png: the sandstone flags where a corner is paving, with a worn
  kerb where they meet the dirt or the grass; see-through elsewhere, so the ground under shows.

and points both areas' `flagstone` layer and legend at it. The city and the Tower's yard are one
stone now, as they are one place. The first gate's plaza (Greyhollow, `gate_barrow.json`) was broken
grey rock ringed with yellow grass, which read as a crag rather than a way in; it is paved in the same
stone, the road's last stop before the Tower.
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import draw_yard  # noqa: E402  (the yard's flags, kerb colours and sheet layout)

ROOT = Path(__file__).resolve().parent.parent
AREAS = [ROOT / "data" / "areas" / "city.json", ROOT / "data" / "areas" / "city_streets.json"]
# The first gate (Greyhollow, D101) stands on the road out of the city: its plaza is the same stone.
GATE = ROOT / "data" / "areas" / "gate_barrow.json"
T = draw_yard.T


def draw_street(code: int, noise, wobble) -> Image.Image:
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    px = im.load()
    for y in range(T):
        for x in range(T):
            here = draw_yard.corners(code, x, y) + (wobble[y][x] - 0.5) * 0.1
            if here >= 0.58:
                px[x, y] = draw_yard.sand_pixel(x, y, noise) + (255,)
            elif here >= 0.5:
                # The kerb: a lit top and a dark foot, where the paving stops.
                px[x, y] = (draw_yard.KERB_TOP if here >= 0.54 else draw_yard.KERB_JOINT) + (255,)
            elif here >= 0.42:
                px[x, y] = (20, 18, 16, int(110 * (here - 0.42) / 0.08))
    return im


def lay(path: Path) -> None:
    text = path.read_text()
    text = text.replace('    "flagstone",\n', '    "street_paving",\n', 1)
    text = text.replace('"o": "flagstone"', '"o": "street_paving"', 1)
    path.write_text(text)


def lay_gate(path: Path) -> None:
    text = path.read_text()
    text = text.replace('    "stone",\n', '    "street_paving",\n', 1)
    text = text.replace('"s": "stone"', '"s": "street_paving"', 1)
    path.write_text(text)


def main() -> None:
    out = draw_yard.OUT
    out.mkdir(parents=True, exist_ok=True)
    noise = draw_yard.grain(11)
    wobble = draw_yard.grain(13)
    draw_yard.sheet_of(lambda code: draw_street(code, noise, wobble)).save(out / "street_paving.png")
    for path in AREAS:
        lay(path)
    lay_gate(GATE)
    print("wrote art/tilesets/yard/street_paving.png; laid city.json, city_streets.json and gate_barrow.json")


if __name__ == "__main__":
    main()
