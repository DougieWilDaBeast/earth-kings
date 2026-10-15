#!/usr/bin/env python3
"""Draw the Tower's yard: plain sandstone paving, a kerb round it, and the lawn outside.

    python3 tools/draw_yard.py

Needs Pillow (`pip install pillow`), like tools/draw_road.py.

The yard at the Tower's foot (data/areas/tower.json) was paved in the battle ground's ornate purple
and gold flags, edged with grey boulders on bright yellow grass. That busy floor fought the people,
the rune stones and the Tower for the eye, so you could not see where to go. D133 draws it in house,
in the 24 x 8 layout every PixelLab "godot" sheet shares (src/area/tile_forge.gd):

- art/tilesets/yard/yard_paving.png: big pale sandstone flags in courses, worn, where a corner is
  paving; a dark lawn with a ragged edge where it is not;
- art/tilesets/yard/yard_kerb.png: a border of long dark kerbstones with a lit top and a shadow;
  see-through elsewhere.

and lays the yard in them: `f` paving, `s` the kerb, `.` the lawn, and the Tower's footing (`A`,
rock faces with grass round them) in the Tower's own coursed masonry (D129's `tower_wall`).
"""

from __future__ import annotations

import json
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "tilesets" / "yard"
AREA = ROOT / "data" / "areas" / "tower.json"
T = 64

WANG = {
    0b0000: (20, 2), 0b0001: (0, 0), 0b0010: (1, 0), 0b0011: (4, 0), 0b0100: (0, 5), 0b0101: (0, 2),
    0b0111: (4, 2), 0b1000: (1, 5), 0b1010: (1, 2), 0b1011: (3, 2), 0b1100: (4, 5), 0b1101: (4, 1),
    0b1110: (3, 1), 0b1111: (12, 3),
}

SAND = [(178, 164, 136), (170, 156, 128), (184, 171, 143), (164, 150, 124)]
SAND_JOINT = (104, 94, 78)
SAND_LIGHT = (200, 188, 160)
LAWN = [(58, 92, 46), (52, 84, 42), (64, 100, 50)]
BLADE = (84, 124, 60)
LAWN_EDGE = (40, 64, 34)
KERB = [(92, 88, 96), (84, 80, 88), (98, 94, 102)]
KERB_TOP = (140, 136, 142)
KERB_JOINT = (46, 44, 52)


def grain(seed: int) -> list[list[float]]:
    rng = random.Random(seed)
    return [[rng.random() for _ in range(T)] for _ in range(T)]


def shade(colour: tuple, amount: float) -> tuple:
    return tuple(max(0, min(255, int(c + amount))) for c in colour)


def corners(code: int, x: int, y: int) -> float:
    nw, ne, sw, se = (code >> 3) & 1, (code >> 2) & 1, (code >> 1) & 1, code & 1
    u, v = (x + 0.5) / T, (y + 0.5) / T
    return nw * (1 - u) * (1 - v) + ne * u * (1 - v) + sw * (1 - u) * v + se * u * v


def sand_pixel(x: int, y: int, noise) -> tuple:
    """Courses twenty-one pixels high (three to a tile), flags of two lengths, staggered."""
    course = y * 3 // T
    ly = y - course * T // 3
    length = 32 if course % 2 == 0 else 21
    offset = 0 if course != 1 else 10
    bx = (x + offset) % T
    lx = bx % length
    stone = (bx // length) + course * 3
    if lx == 0 or ly == 0:
        return SAND_JOINT
    if ly == 1 or lx == 1:
        return SAND_LIGHT
    base = SAND[stone % len(SAND)]
    return shade(base, (noise[y][x] - 0.5) * 14)


def lawn_pixel(x: int, y: int, noise) -> tuple:
    if noise[y][x] > 0.86 and noise[(y + 1) % T][x] > 0.3:
        return BLADE
    return LAWN[int(noise[x][y] * len(LAWN)) % len(LAWN)]


def draw_paving(code: int, noise, wobble) -> Image.Image:
    im = Image.new("RGBA", (T, T))
    px = im.load()
    for y in range(T):
        for x in range(T):
            here = corners(code, x, y) + (wobble[y][x] - 0.5) * 0.18
            if here >= 0.5:
                px[x, y] = sand_pixel(x, y, noise) + (255,)
            elif here >= 0.44:
                px[x, y] = LAWN_EDGE + (255,)
            else:
                px[x, y] = lawn_pixel(x, y, noise) + (255,)
    return im


def draw_kerb(code: int, noise) -> Image.Image:
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    px = im.load()
    for y in range(T):
        for x in range(T):
            here = corners(code, x, y)
            if here >= 0.5:
                if here < 0.56:
                    colour = KERB_JOINT
                elif here < 0.64:
                    colour = KERB_TOP
                else:
                    block = ((x + (y // 16) * 11) // 24)
                    colour = KERB_JOINT if (x + (y // 16) * 11) % 24 == 0 or y % 16 == 0 else shade(KERB[block % len(KERB)], (noise[y][x] - 0.5) * 12)
                px[x, y] = colour + (255,)
            elif here >= 0.4:
                px[x, y] = (20, 18, 16, int(120 * (here - 0.4) / 0.1))
    return im


def sheet_of(draw) -> Image.Image:
    sheet = Image.new("RGBA", (24 * T, 8 * T), (0, 0, 0, 0))
    for code, (cx, cy) in WANG.items():
        sheet.paste(draw(code), (cx * T, cy * T))
    return sheet


def lay_the_yard() -> None:
    """Point tower.json's layers and legend at the new sheets, in place, keeping the file's layout."""
    text = AREA.read_text()
    old_layers = '"layers": [\n    "flagstone",\n    "stone",\n    "crag"\n  ]'
    if old_layers in text:
        text = text.replace(old_layers, '"layers": [\n    "yard_paving",\n    "yard_kerb",\n    "tower_wall"\n  ]', 1)
    for key, old, new in ((".", "grass", "yard_lawn"), ("s", "stone", "yard_kerb"), ("f", "flagstone", "yard_paving"), ("A", "crag", "tower_wall")):
        text = text.replace('"%s": "%s"' % (key, old), '"%s": "%s"' % (key, new), 1)
    AREA.write_text(text)
    area = json.loads(text)
    assert area["layers"][:2] == ["yard_paving", "yard_kerb"], area["layers"]


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    noise = grain(11)
    wobble = grain(12)
    sheet_of(lambda code: draw_paving(code, noise, wobble)).save(OUT / "yard_paving.png")
    sheet_of(lambda code: draw_kerb(code, noise)).save(OUT / "yard_kerb.png")
    lay_the_yard()
    print("wrote art/tilesets/yard/yard_paving.png, yard_kerb.png; laid data/areas/tower.json")


if __name__ == "__main__":
    main()
