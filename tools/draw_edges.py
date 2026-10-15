#!/usr/bin/env python3
"""Draw the sheets that blend one land into the next where two tiles of the land meet.

    python3 tools/draw_edges.py

Needs Pillow (`pip install pillow`), like tools/draw_road.py.

Ewan's second play-test (2026-10-15) found the lands "in squares": every tile of the land is one
land's ground to its very edge, so snow stops on a ruler line against grass. D128 blends the two
over a few cells either side of the seam (src/area/ground_gen.gd lays the neighbour's floor into
the band), and these sheets draw it: one per land's floor, that floor alone on the corners where it
lies and see-through everywhere else, so it lies over the other land's ground as the road does.

Each sheet is made from the land's own ground sheet: its plain floor tile, cut to the shape of the
corners with a worn, uneven edge. Writes art/tilesets/edges/edge_<floor>.png (1536 x 512, the
24 x 8 layout every PixelLab "godot" sheet shares, src/area/tile_forge.gd) and the matching
`edge_<floor>` entries in data/tilesets.json.
"""

from __future__ import annotations

import json
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "tilesets" / "edges"
TILESETS = ROOT / "data" / "tilesets.json"
BIOMES = ROOT / "data" / "biomes.json"
T = 64

# Corner code (NW*8 + NE*4 + SW*2 + SE) -> where it sits on the sheet (tile_forge.gd).
WANG = {
    0b0000: (20, 2), 0b0001: (0, 0), 0b0010: (1, 0), 0b0011: (4, 0), 0b0100: (0, 5), 0b0101: (0, 2),
    0b0111: (4, 2), 0b1000: (1, 5), 0b1010: (1, 2), 0b1011: (3, 2), 0b1100: (4, 5), 0b1101: (4, 1),
    0b1110: (3, 1), 0b1111: (12, 3),
}


def noise(seed: int) -> list[list[float]]:
    """Smooth noise that repeats every 64 pixels, for an uneven edge."""
    rng = random.Random(seed)
    g = 8
    lattice = [[rng.random() for _ in range(g)] for _ in range(g)]
    out = [[0.0] * T for _ in range(T)]
    for y in range(T):
        for x in range(T):
            fx, fy = x / T * g, y / T * g
            x0, y0 = int(fx) % g, int(fy) % g
            x1, y1 = (x0 + 1) % g, (y0 + 1) % g
            tx, ty = fx - int(fx), fy - int(fy)
            tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
            a = lattice[y0][x0] + (lattice[y0][x1] - lattice[y0][x0]) * tx
            b = lattice[y1][x0] + (lattice[y1][x1] - lattice[y1][x0]) * tx
            out[y][x] = a + (b - a) * ty
    return out


def floor_tile(sheet: dict) -> Image.Image:
    """The land's plain floor: the all-upper tile of its ground sheet, at 64 pixels."""
    path = ROOT / str(sheet["texture"]).removeprefix("res://")
    size = int(sheet.get("tile_size", T))
    cx, cy = WANG[0b1111]
    tile = Image.open(path).convert("RGBA").crop((cx * size, cy * size, (cx + 1) * size, (cy + 1) * size))
    return tile.resize((T, T), Image.NEAREST) if size != T else tile


def draw_tile(code: int, floor: Image.Image, wobble, speckle) -> Image.Image:
    nw, ne, sw, se = (code >> 3) & 1, (code >> 2) & 1, (code >> 1) & 1, code & 1
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    src = floor.load()
    px = im.load()
    for y in range(T):
        for x in range(T):
            u, v = (x + 0.5) / T, (y + 0.5) / T
            here = nw * (1 - u) * (1 - v) + ne * u * (1 - v) + sw * (1 - u) * v + se * u * v
            here += (wobble[y][x] - 0.5) * 0.45
            # A ragged fringe of single pixels rather than a hard line.
            if here < 0.38 or (here < 0.56 and speckle[y][x] > (here - 0.38) / 0.18):
                continue
            px[x, y] = src[x, y]
    return im


def main() -> None:
    tilesets = json.loads(TILESETS.read_text())
    sheets = tilesets["sheets"]
    lands = json.loads(BIOMES.read_text())["biomes"]
    OUT.mkdir(parents=True, exist_ok=True)
    wobble = noise(5)
    rng = random.Random(9)
    speckle = [[rng.random() for _ in range(T)] for _ in range(T)]
    done = set()
    for land in lands.values():
        floor_name = str(land["ground"]["floor"])
        if floor_name in done:
            continue
        done.add(floor_name)
        base = sheets[str(land["layers"][0])]
        floor = floor_tile(base)
        sheet = Image.new("RGBA", (24 * T, 8 * T), (0, 0, 0, 0))
        for code, (cx, cy) in WANG.items():
            sheet.paste(draw_tile(code, floor, wobble, speckle), (cx * T, cy * T))
        name = "edge_%s" % floor_name
        sheet.save(OUT / ("%s.png" % name))
        sheets[name] = {
            "_comment": "D128: %s where one land runs into the next, drawn in house (tools/draw_edges.py); see-through off it." % floor_name,
            "texture": "res://art/tilesets/edges/%s.png" % name,
            "tile_size": T,
            "lower": "none",
            "upper": floor_name,
            "feature": floor_name,
        }
    TILESETS.write_text(json.dumps(tilesets, indent="\t", ensure_ascii=False) + "\n")
    print("wrote %d edge sheets to art/tilesets/edges/" % len(done))


if __name__ == "__main__":
    main()
