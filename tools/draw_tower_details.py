#!/usr/bin/env python3
"""Draw the Tower's stair up and its lit runes, and set them on floors 1 to 5.

    python3 tools/draw_tower_details.py

Needs Pillow (`pip install pillow`), like tools/draw_road.py.

Meeting 4 (D123) asked for floors that read as a Tower, "stair up the side, lit runes". D129 drew
the slabs, walls and runner; the stair was still only the runner running off the top of the map,
and nothing on the walls glowed. D132 draws them in house:

- art/props/tower_inside/stair_up.png      64 x 96: one half of a flight of stone steps climbing
  into the dark, a balustrade on its outer side (the other half is the same picture flipped); it
  stands on the cells in front of the stair, so the flight fills the end of the hall
- art/props/tower_inside/rune_<a|b|c>.png  64 x 64: a glyph cut into a dark plaque, lit from
  inside, and frames rune_<x>/frame_000..007.png with the light swelling and fading (AreaProp
  plays them)

and sets them on every floor: the stair on the cells just in front of the floor's stair cells, a rune either side of it, and
runes along the walls by rule (a wall cell whose face shows, the cell south of it walkable, no
nearer than RUNE_GAP cells to another rune). Floors that already carry them are left alone.
"""

from __future__ import annotations

import json
import math
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "props" / "tower_inside"
AREAS = ROOT / "data" / "areas"
FLOORS = [AREAS / ("tower_floor_%d.json" % n) for n in range(1, 6)]
RUNE_GAP = 5
FRAMES = 8

STONE = [(150, 144, 138), (138, 132, 126), (126, 120, 115)]
RISER = (84, 78, 80)
EDGE = (176, 170, 160)
RAIL = (70, 66, 82)
RAIL_LIGHT = (104, 100, 120)
RAIL_DARK = (40, 38, 50)
PLAQUE = (44, 42, 56)
PLAQUE_RIM = (96, 92, 112)
GLOW = (120, 220, 255)
GLOW_HOT = (226, 250, 255)

# Each glyph is strokes on a 9 x 9 grid: ((x0, y0), (x1, y1)).
GLYPHS = {
    "a": [((4, 0), (4, 8)), ((1, 2), (7, 2)), ((1, 2), (4, 6)), ((7, 2), (4, 6))],
    "b": [((1, 0), (1, 8)), ((7, 0), (7, 8)), ((1, 4), (7, 4)), ((4, 1), (4, 7))],
    "c": [((4, 0), (0, 4)), ((0, 4), (4, 8)), ((4, 8), (8, 4)), ((8, 4), (4, 0)), ((4, 2), (4, 6))],
}


def stair_up() -> Image.Image:
    """The left half of the flight: treads narrowing and darkening as they climb, rail on the left."""
    w, h = 64, 96
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = out.load()
    rng = random.Random(3)
    steps = 9
    y = h
    for i in range(steps):
        tread = max(5, 11 - i)
        riser = max(2, 4 - i // 3)
        dark = 1.0 - i / (steps + 2)
        for yy in range(y - tread - riser, y):
            if yy < 0:
                continue
            on_riser = yy >= y - riser
            for x in range(w):
                if on_riser:
                    c = RISER
                elif yy == y - tread - riser:
                    c = EDGE
                else:
                    c = STONE[(x // 13 + i) % len(STONE)]
                    if rng.random() < 0.06:
                        c = tuple(v - 14 for v in c)
                px[x, yy] = tuple(int(v * dark) for v in c) + (255,)
        y -= tread + riser
    # The dark the stair climbs into, above the last tread.
    for yy in range(0, max(0, y)):
        for x in range(w):
            px[x, yy] = (18, 16, 24, 255)
    # Balustrade: a stone rail down the outer side, lit on top, posts every few steps.
    for yy in range(h):
        for x in range(0, 9):
            c = RAIL_LIGHT if x in (0, 1) else (RAIL_DARK if x == 8 else RAIL)
            px[x, yy] = c + (255,)
    for post_y in range(h - 4, 0, -18):
        for yy in range(post_y - 6, post_y):
            for x in range(0, 11):
                px[x, yy] = (RAIL_LIGHT if yy == post_y - 6 else RAIL) + (255,)
    return out


def _segment_distance(x: float, y: float, a: tuple, b: tuple) -> float:
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    t = 0.0 if dx == dy == 0 else max(0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(x - (ax + t * dx), y - (ay + t * dy))


def rune(glyph: str, light: float) -> Image.Image:
    """A plaque with a glyph cut in it; `light` from 0 (dim) to 1 (full) sets the glow."""
    out = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    px = out.load()
    left, top, size = 18, 18, 28
    strokes = [((left + 3 + a[0] * 2.5, top + 3 + a[1] * 2.5), (left + 3 + b[0] * 2.5, top + 3 + b[1] * 2.5)) for a, b in GLYPHS[glyph]]
    for y in range(64):
        for x in range(64):
            d = min(_segment_distance(x + 0.5, y + 0.5, a, b) for a, b in strokes)
            inside = left <= x < left + size and top <= y < top + size
            if inside:
                rim = x in (left, left + size - 1) or y in (top, top + size - 1)
                c = PLAQUE_RIM if rim else PLAQUE
                a = 255
                if d < 1.2:
                    c = GLOW_HOT if light > 0.55 else GLOW
                    c = tuple(int(v * (0.55 + 0.45 * light)) for v in c)
                elif d < 3.0:
                    k = (1 - (d - 1.2) / 1.8) * (0.35 + 0.5 * light)
                    c = tuple(int(c[i] + (GLOW[i] - c[i]) * k) for i in range(3))
                px[x, y] = c + (a,)
            else:
                # A soft halo spilling onto the wall round the plaque.
                ox = max(left - x, 0, x - (left + size - 1))
                oy = max(top - y, 0, y - (top + size - 1))
                o = math.hypot(ox, oy)
                if o < 8:
                    alpha = int((1 - o / 8) * 90 * light)
                    if alpha > 4:
                        px[x, y] = GLOW + (alpha,)
    return out


def light_at(frame: int) -> float:
    return 0.55 + 0.45 * math.sin(frame / FRAMES * math.tau)


def draw() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    stair_up().save(OUT / "stair_up.png")
    for glyph in GLYPHS:
        rune(glyph, 1.0).save(OUT / ("rune_%s.png" % glyph))
        frames = OUT / ("rune_%s" % glyph)
        frames.mkdir(exist_ok=True)
        for i in range(FRAMES):
            rune(glyph, light_at(i)).save(frames / ("frame_%03d.png" % i))


def rune_cells(rows: list[str], stairs: list[list[int]]) -> list[tuple[int, int]]:
    """Wall cells whose face shows, spaced out; the two beside the stair first."""
    h, w = len(rows), len(rows[0])
    stair = {tuple(s) for s in stairs}
    xs = sorted(s[0] for s in stairs)
    sy = stairs[0][1]
    chosen = [(xs[0] - 1, sy), (xs[-1] + 1, sy)]
    chosen = [c for c in chosen if 0 <= c[0] < w and rows[c[1]][c[0]] == "A"]
    for y in range(h - 1):
        for x in range(w):
            if (x, y) in stair or rows[y][x] != "A" or rows[y + 1][x] == "A":
                continue
            if all(max(abs(x - cx), abs(y - cy)) >= RUNE_GAP for cx, cy in chosen):
                chosen.append((x, y))
    return chosen


def entry(art: str, cell: tuple[int, int], extra: str = "") -> str:
    return '    {\n      "art": "%s",\n      "cell": [\n        %d,\n        %d\n      ]%s\n    },\n' % (art, cell[0], cell[1], extra)


def place() -> int:
    placed = 0
    for path in FLOORS:
        text = path.read_text()
        if "tower_inside/" in text:
            continue
        area = json.loads(text)
        rows, stairs = area["rows"], area["stairs"]
        added = ""
        for i, s in enumerate(sorted(stairs)):
            flip = ',\n      "flip": true' if i % 2 == 1 else ""
            added += entry("tower_inside/stair_up", (s[0], s[1] + 1), flip)
        for i, cell in enumerate(rune_cells(rows, stairs)):
            added += entry("tower_inside/rune_%s" % "abc"[i % 3], cell)
            placed += 1
        marker = '"props": [\n'
        assert marker in text, path
        path.write_text(text.replace(marker, marker + added, 1))
        json.loads(path.read_text())
    return placed


def main() -> None:
    draw()
    n = place()
    print("wrote art/props/tower_inside/ (stair, 3 runes x %d frames); set %d runes on the floors" % (FRAMES, n))


if __name__ == "__main__":
    main()
