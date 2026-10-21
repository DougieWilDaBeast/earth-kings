#!/usr/bin/env python3
"""Draw the sheet that lifts a rise of ground above the land round it.

    python3 tools/draw_rises.py

Needs Pillow (`pip install pillow`), like tools/draw_edges.py.

Ewan's play-test 7 (2026-10-18): "the world is very flat ... you need to be able to tier it in
heights. It would make paths environment look way better." D328 lays rises of a land's own floor
on the generated ground (src/area/ground_gen.gd) and this sheet draws them over that floor, the
way the edge sheets lie over the next land's: see-through on top but for a little light, an
outline round the sides, and a face of rock below the south edge with its shadow at the foot.
So one sheet serves every land. Writes art/tilesets/rise.png (1536 x 512, the 24 x 8 layout every
PixelLab "godot" sheet shares, src/area/tile_forge.gd) and the `rise` entry in data/tilesets.json.
Drawn in house until art request A55 is made.
"""

from __future__ import annotations

import json
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "tilesets" / "rise.png"
TILESETS = ROOT / "data" / "tilesets.json"
T = 64
# How far the face drops below the edge of the rise, in pixels.
FACE = 28
SHADOW = 7

WANG = {
    0b0000: (20, 2), 0b0001: (0, 0), 0b0010: (1, 0), 0b0011: (4, 0), 0b0100: (0, 5), 0b0101: (0, 2),
    0b0111: (4, 2), 0b1000: (1, 5), 0b1010: (1, 2), 0b1011: (3, 2), 0b1100: (4, 5), 0b1101: (4, 1),
    0b1110: (3, 1), 0b1111: (12, 3),
}
ROCK = [(118, 104, 88), (104, 92, 78), (130, 116, 98), (92, 82, 70)]


def corners(code: int, x: float, y: float) -> float:
    nw, ne, sw, se = (code >> 3) & 1, (code >> 2) & 1, (code >> 1) & 1, code & 1
    u = min(1.0, max(0.0, (x + 0.5) / T))
    v = min(1.0, max(0.0, (y + 0.5) / T))
    return nw * (1 - u) * (1 - v) + ne * u * (1 - v) + sw * (1 - u) * v + se * u * v


def shade(colour: tuple, amount: float) -> tuple:
    return tuple(max(0, min(255, int(c + amount))) for c in colour)


def draw_tile(code: int, wobble: list, grain: list) -> Image.Image:
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    px = im.load()
    for y in range(T):
        for x in range(T):
            jitter = (wobble[y][x] - 0.5) * 0.12
            here = corners(code, x, y) + jitter
            if here >= 0.5:
                below = corners(code, x, y + 2) + jitter
                if below < 0.5:
                    # The lip of the rise, caught by the light.
                    px[x, y] = (236, 226, 196, 150)
                elif here < 0.56:
                    px[x, y] = (40, 34, 28, 110)
                else:
                    px[x, y] = (255, 246, 214, 44)
                continue
            # Below the edge: rock face, then the shadow it throws.
            for d in range(1, FACE + SHADOW + 1):
                if corners(code, x, y - d) + (wobble[max(0, y - d)][x] - 0.5) * 0.12 >= 0.5:
                    if d <= FACE:
                        rock = ROCK[(x // 4 + (y - d) // 7 + int(grain[y][x] * 1.6)) % len(ROCK)]
                        rock = shade(rock, -d * 1.8 + (grain[y][x] - 0.5) * 18)
                        if (y + x // 9) % 7 == 0:
                            rock = shade(rock, -22)
                        if d > FACE - 3:
                            rock = shade(rock, -34)
                        px[x, y] = rock + (255,)
                    else:
                        px[x, y] = (12, 10, 14, int(90 * (1 - (d - FACE) / (SHADOW + 1))))
                    break
    return im


def main() -> None:
    rng = random.Random(282)
    wobble = [[rng.random() for _ in range(T)] for _ in range(T)]
    grain = [[rng.random() for _ in range(T)] for _ in range(T)]
    sheet = Image.new("RGBA", (24 * T, 8 * T), (0, 0, 0, 0))
    for code, (cx, cy) in WANG.items():
        sheet.paste(draw_tile(code, wobble, grain), (cx * T, cy * T))
    sheet.save(OUT)
    tilesets = json.loads(TILESETS.read_text())
    tilesets["terrains"]["rise"] = {"display_name": "higher ground", "walkable": True}
    tilesets["sheets"]["rise"] = {
        "_comment": "D328: a rise of any land's floor, drawn in house (tools/draw_rises.py); see-through on top, a rock face below its south edge.",
        "texture": "res://art/tilesets/rise.png",
        "tile_size": T,
        "lower": "none",
        "upper": "rise",
        "feature": "rise",
    }
    TILESETS.write_text(json.dumps(tilesets, indent="\t", ensure_ascii=False) + "\n")
    print("wrote art/tilesets/rise.png")


if __name__ == "__main__":
    main()
