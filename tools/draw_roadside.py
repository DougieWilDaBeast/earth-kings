#!/usr/bin/env python3
"""Draw the roadside scenes' props: the stopped cart, the burning wagon, the toll rope.

    python3 tools/draw_roadside.py

Needs Pillow (`pip install pillow`), like tools/draw_road.py.

The three roadside scenes (data/roadside.json) stopped the player with text and nothing on screen,
so D121 hid them in the First Hour until they were drawn. D131 stages them on the ground: the cart
and the people round it stand a few cells ahead before anyone speaks. This draws what they stand
round, in house, from the village cart (art/props/village/cart.png) where it can:

- art/props/roadside/cart_stopped.png      96 x 64: the cart slewed across the road, a wheel off
  and lying beside it
- art/props/roadside/wagon_burnt.png       64 x 112: the cart charred black, and frames
  wagon_burnt/frame_000..003.png with the fire on it flickering (AreaProp plays them)
- art/props/roadside/toll_rope.png         128 x 64: two stakes and a rope sagging across the road,
  rags tied on it
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
CART = ROOT / "art" / "props" / "village" / "cart.png"
OUT = ROOT / "art" / "props" / "roadside"

WOOD = (112, 74, 42)
WOOD_DARK = (74, 46, 26)
WOOD_LIGHT = (146, 102, 60)
ROPE = (176, 150, 96)
ROPE_DARK = (122, 100, 60)
RAGS = [(150, 40, 36), (196, 172, 84), (64, 92, 140)]
INK = (30, 22, 18)
FLAME = [(255, 236, 140), (255, 180, 60), (232, 104, 36), (168, 52, 28)]


def bounds(im: Image.Image) -> tuple[int, int, int, int]:
    return im.getbbox() or (0, 0, im.width, im.height)


def cart_stopped(cart: Image.Image) -> Image.Image:
    """The cart turned a little across the road, one wheel off it and lying flat beside."""
    out = Image.new("RGBA", (96, 64), (0, 0, 0, 0))
    body = cart.rotate(-14, resample=Image.NEAREST, expand=True)
    bx, by, bx2, by2 = bounds(body)
    body = body.crop((bx, by, bx2, by2))
    out.alpha_composite(body, (6, 64 - body.height - 2))
    # The wheel lying in the grass: an ellipse of rim and spokes.
    px = out.load()
    cx, cy, rx, ry = 78, 52, 12, 6
    for y in range(64):
        for x in range(96):
            d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            if 0.62 <= d <= 1.0:
                px[x, y] = (WOOD_DARK if d > 0.86 else WOOD) + (255,)
            elif d < 0.62:
                ang = math.atan2((y - cy) / ry, (x - cx) / rx)
                if abs(math.sin(ang * 3)) < 0.22 or d < 0.06:
                    px[x, y] = WOOD_LIGHT + (255,)
    return out


def charred(cart: Image.Image) -> Image.Image:
    """The cart burnt: every colour pulled down to soot, with embers in the grain."""
    out = cart.copy()
    px = out.load()
    rng = random.Random(7)
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            v = (r + g + b) // 3
            dark = (int(v * 0.32) + 8, int(v * 0.26) + 6, int(v * 0.24) + 6)
            if rng.random() < 0.05:
                dark = FLAME[2] if rng.random() < 0.6 else FLAME[1]
            px[x, y] = dark + (a,)
    return out


def fire(frame: int) -> Image.Image:
    """Flames over the wagon bed, flickering frame to frame, smoke above them."""
    out = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    px = out.load()
    rng = random.Random(100 + frame)
    for x in range(10, 52):
        base_h = 18 + 10 * math.sin((x + frame * 5) * 0.35) + rng.uniform(-3, 3)
        base_h *= 1.0 - abs(x - 32) / 40
        for y in range(64):
            up = 63 - y
            if up > base_h:
                continue
            t = up / max(1.0, base_h)
            colour = FLAME[min(3, int(t * 4))] if t < 0.96 else FLAME[3]
            px[x, y] = colour + (255,)
    # Smoke: a few soft grey puffs drifting up.
    for i in range(4):
        sx = 24 + i * 6 + frame * 2 % 6
        sy = 18 - i * 4 - frame
        for y in range(max(0, sy - 5), min(64, sy + 5)):
            for x in range(max(0, sx - 6), min(64, sx + 6)):
                if (x - sx) ** 2 + (y - sy) ** 2 <= 25 and px[x, y][3] == 0:
                    px[x, y] = (70, 66, 64, 110)
    return out


def wagon_burnt(cart: Image.Image, frame: int) -> Image.Image:
    """The fire behind and above the charred bed, so the cart stands in front of its own flames."""
    out = Image.new("RGBA", (64, 112), (0, 0, 0, 0))
    out.alpha_composite(fire(frame), (-4, 18))
    out.alpha_composite(charred(cart), (0, 48))
    return out


def toll_rope() -> Image.Image:
    out = Image.new("RGBA", (128, 64), (0, 0, 0, 0))
    px = out.load()
    # Two stakes, leaning a little, with a lit edge.
    for sx in (10, 114):
        for y in range(14, 62):
            lean = (62 - y) // 12 * (1 if sx < 64 else -1)
            for dx in range(-3, 3):
                x = sx + dx + lean
                colour = WOOD_LIGHT if dx == -3 else (WOOD_DARK if dx == 2 else WOOD)
                px[x, y] = colour + (255,)
        for dx in range(-4, 4):
            px[sx + dx, 13] = INK + (255,)
    # The rope sagging between them, two pixels thick, and rags knotted on it.
    for x in range(12, 117):
        t = (x - 12) / 104
        y = int(18 + 14 * math.sin(math.pi * t))
        px[x, y] = ROPE + (255,)
        px[x, y + 1] = ROPE_DARK + (255,)
        if x in (36, 64, 92):
            rag = RAGS[(x // 28) % len(RAGS)]
            for ry in range(2, 10):
                for rx in range(-2, 3 - ry // 4):
                    px[x + rx, y + ry] = rag + (255,)
    return out


def main() -> None:
    cart = Image.open(CART).convert("RGBA")
    OUT.mkdir(parents=True, exist_ok=True)
    cart_stopped(cart).save(OUT / "cart_stopped.png")
    wagon_burnt(cart, 0).save(OUT / "wagon_burnt.png")
    frames = OUT / "wagon_burnt"
    frames.mkdir(exist_ok=True)
    for i in range(4):
        wagon_burnt(cart, i).save(frames / ("frame_%03d.png" % i))
    toll_rope().save(OUT / "toll_rope.png")
    print("wrote art/props/roadside/cart_stopped.png, wagon_burnt.png (+4 frames), toll_rope.png")


if __name__ == "__main__":
    main()
