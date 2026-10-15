#!/usr/bin/env python3
"""Draw Greyhollow's gate as a standing doorway of rune stones with the gate's light in it.

    python3 tools/draw_gate.py

Needs Pillow (`pip install pillow`), like tools/draw_road.py.

The first gate (Greyhollow, data/areas/gate_barrow.json) was a ring of rune stones lying flat on
the ground round a swirl, seen from straight above, while everything round it (the standing stones,
the people, the Tower) is seen from the front: it read as a pattern on the paving, not a way in.
D141 draws it in house as the barrows' own kind of door, two standing stones and a lintel (a
trilithon), runes cut down both uprights, and the gate's light turning in the doorway:

- art/props/landmark/gate_barrow.png             160 x 112, at scale 1 (one pixel to a pixel, like
  the ground under it), standing across the three cells it is set on, low enough to stand whole
  in the plaza's top row;
- art/props/landmark/gate_barrow/frame_000..007.png  the light turning and the runes pulsing
  (AreaProp plays them).

and sets the barrow gate's area to it (gate_barrow.json: Greyhollow, and any barrow gate after
it). The other gates keep their PixelLab pictures.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "props" / "landmark"
AREA = ROOT / "data" / "areas" / "gate_barrow.json"
W, H = 160, 112
FRAMES = 8

STONE = [(104, 108, 118), (96, 100, 110), (110, 114, 124)]
STONE_LIT = (150, 154, 162)
STONE_DARK = (62, 64, 74)
STONE_SHADOW = (44, 46, 56)
MOSS = (78, 96, 62)
RUNE = (120, 220, 255)
RUNE_HOT = (226, 250, 255)
DEEP = (18, 26, 62)
MID = (52, 96, 170)
LIGHT = (130, 210, 250)
CORE = (236, 250, 255)

# The uprights and the lintel, as boxes (x0, y0, x1, y1), bottom of the picture is the ground.
LEFT = (16, 24, 48, 104)
RIGHT = (112, 24, 144, 104)
LINTEL = (6, 6, 154, 28)
DOOR = (48, 28, 112, 104)

GLYPHS = [
    [((2, 0), (2, 6)), ((2, 0), (0, 2)), ((2, 0), (4, 2))],
    [((0, 0), (4, 6)), ((4, 0), (0, 6))],
    [((2, 0), (0, 3)), ((0, 3), (2, 6)), ((2, 6), (4, 3)), ((4, 3), (2, 0))],
    [((0, 0), (0, 6)), ((0, 3), (4, 0)), ((0, 3), (4, 6))],
]


def inside(box: tuple, x: int, y: int) -> bool:
    return box[0] <= x < box[2] and box[1] <= y < box[3]


def shade(colour: tuple, amount: float) -> tuple:
    return tuple(max(0, min(255, int(c + amount))) for c in colour)


def mix(a: tuple, b: tuple, t: float) -> tuple:
    t = max(0.0, min(1.0, t))
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def _segment_distance(x: float, y: float, a: tuple, b: tuple) -> float:
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    t = 0.0 if dx == dy == 0 else max(0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(x - (ax + t * dx), y - (ay + t * dy))


def stone_pixel(box: tuple, x: int, y: int, noise, rng_cracks: set) -> tuple:
    """A rough-dressed stone: lit on its left face and top, dark down its right, moss at the foot."""
    x0, y0, x1, y1 = box
    # A slightly ragged outline: the corners knocked off.
    if (x - x0 < 3 or x1 - 1 - x < 3) and (y - y0 < 3):
        return None
    if (x, y) in rng_cracks:
        return STONE_SHADOW
    n = noise[y % 64][x % 64]
    if y - y0 < 3:
        return STONE_LIT
    if x - x0 < 3:
        return shade(STONE_LIT, -10 + n * 10)
    if x1 - 1 - x < 5:
        return STONE_DARK
    if box != LINTEL and y1 - y < 7 and n > 0.55:
        return MOSS
    return shade(STONE[int(noise[x % 64][y % 64] * 3) % 3], (n - 0.5) * 14 - (y - y0) * 0.08)


def runes(box: tuple, light: float):
    """Glyphs cut down the middle of an upright; yields (x, y, colour)."""
    x0, y0, x1, y1 = box
    cx = (x0 + x1) // 2 - 4
    for i, glyph in enumerate(GLYPHS[:3]):
        gy = y0 + 12 + i * 24
        for y in range(gy - 2, gy + 16):
            for x in range(cx - 2, cx + 12):
                d = min(_segment_distance((x - cx) / 2, (y - gy) / 2, a, b) for a, b in glyph) * 2
                if d < 1.0:
                    yield x, y, mix(RUNE, RUNE_HOT, light - 0.4)
                elif d < 2.6:
                    yield x, y, None if light < 0.2 else ("glow", (1 - (d - 1) / 1.6) * (0.25 + 0.5 * light))


def doorway(x: int, y: int, phase: float) -> tuple:
    """The light in the door: a spiral turning about the door's middle, bright at its heart."""
    cx, cy = (DOOR[0] + DOOR[2]) / 2, (DOOR[1] + DOOR[3]) / 2 + 6
    dx, dy = (x - cx) / ((DOOR[2] - DOOR[0]) / 2), (y - cy) / ((DOOR[3] - DOOR[1]) / 2)
    r = math.hypot(dx, dy)
    a = math.atan2(dy, dx)
    arm = 0.5 + 0.5 * math.sin(a * 2 + r * 7.0 - phase)
    v = (1 - min(1.0, r)) * 0.85 + arm * 0.35
    # Four bands only, like a palette; a checker between bands so the steps are dithered.
    level = v * 4 + (0.25 if (x + y) % 2 else -0.25)
    if level > 3.4:
        return CORE
    if level > 2.5:
        return LIGHT
    if level > 1.5:
        return MID
    return DEEP


def gate(frame: int) -> Image.Image:
    rng = random.Random(7)
    noise = [[rng.random() for _ in range(64)] for _ in range(64)]
    cracks: set = set()
    for _ in range(9):
        x, y = rng.randrange(10, 150), rng.randrange(8, 96)
        for _step in range(rng.randrange(4, 9)):
            cracks.add((x, y))
            x += rng.choice((-1, 0, 1))
            y += 1
    phase = frame / FRAMES * math.tau
    light = 0.55 + 0.45 * math.sin(phase)
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    # The shadow the stones throw on the ground, and the light spilling out of the door onto it.
    for y in range(96, H):
        for x in range(W):
            ex = (x - W / 2) / (W / 2 - 4)
            ey = (y - 104) / 8
            if ex * ex + ey * ey <= 1:
                px[x, y] = (20, 22, 30, 110)
            if DOOR[0] - 6 <= x < DOOR[2] + 6 and y >= 102 and (x + y) % 2 == 0:
                px[x, y] = LIGHT + (int(70 + 50 * light),)
    for y in range(DOOR[1], DOOR[3]):
        for x in range(DOOR[0], DOOR[2]):
            px[x, y] = doorway(x, y, phase) + (255,)
    for box in (LEFT, RIGHT, LINTEL):
        for y in range(box[1], box[3]):
            for x in range(box[0], box[2]):
                c = stone_pixel(box, x, y, noise, cracks)
                if c is not None:
                    px[x, y] = c + (255,)
    # The lintel's shadow on the light under it.
    for x in range(DOOR[0], DOOR[2]):
        for y in range(LINTEL[3], LINTEL[3] + 3):
            r, g, b, a = px[x, y]
            px[x, y] = (r // 2, g // 2, b // 2, a)
    for box in (LEFT, RIGHT):
        for x, y, c in runes(box, light):
            if c is None:
                continue
            if isinstance(c, tuple) and c and c[0] == "glow":
                r, g, b, a = px[x, y]
                px[x, y] = mix((r, g, b), RUNE, c[1]) + (a,)
            else:
                px[x, y] = c + (255,)
    return im


def set_in_area() -> None:
    text = AREA.read_text()
    text = text.replace('"art": "landmark/gate_stones"', '"art": "landmark/gate_barrow"', 1)
    AREA.write_text(text)


def main() -> None:
    gate(2).save(OUT / "gate_barrow.png")
    frames = OUT / "gate_barrow"
    frames.mkdir(exist_ok=True)
    for i in range(FRAMES):
        gate(i).save(frames / ("frame_%03d.png" % i))
    set_in_area()
    print("wrote art/props/landmark/gate_barrow (+ %d frames); set Greyhollow's gate to it" % FRAMES)


if __name__ == "__main__":
    main()
