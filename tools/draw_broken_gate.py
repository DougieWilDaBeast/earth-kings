#!/usr/bin/env python3
"""Draw a shut gate as a broken one, lying on the ground where it stood.

    python3 tools/draw_broken_gate.py

Needs Pillow (`pip install pillow`), like tools/draw_gate.py.

Play-test 7 (doug-md): "when you defeat a gate or shut a gate, then it should turn off and break apart
and be lying on the floor." D261 draws it in house until art request A38 is made: the dark gate's
picture (art/props/landmark/gate_dark.png) with its light gone out, cracked down the middle, the two
halves fallen outwards onto their sides, and rubble between them:

- art/props/landmark/gate_broken.png    64 x 64, drawn at the portal kind's size (data/props.json).

A shut gate's mouth shows it in place of the gate it was (src/area/ground_gen.gd).
"""

from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "art" / "props" / "landmark" / "gate_dark.png"
OUT = ROOT / "art" / "props" / "landmark" / "gate_broken.png"
SIZE = 64
RUBBLE = [(78, 80, 92), (64, 66, 76), (96, 98, 110), (52, 54, 62)]


def dead(image: Image.Image) -> Image.Image:
    """The gate with its light out: no colour, darker."""
    alpha = image.getchannel("A")
    grey = ImageEnhance.Color(image).enhance(0.05)
    grey = ImageEnhance.Brightness(grey).enhance(0.85)
    grey.putalpha(alpha)
    return grey


def main() -> None:
    gate = dead(Image.open(SOURCE).convert("RGBA"))
    w, h = gate.size
    left = gate.crop((0, 0, w // 2, h))
    right = gate.crop((w // 2, 0, w, h))
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    # Each half falls outwards and lies low, its foot where it stood.
    fallen_left = left.rotate(84, expand=True, resample=Image.NEAREST)
    fallen_right = right.rotate(-80, expand=True, resample=Image.NEAREST)
    for piece, x, lift in ((fallen_left, 0, 4), (fallen_right, None, 1)):
        piece.thumbnail((SIZE // 2 + 2, SIZE // 2))
        left_x = SIZE - piece.width if x is None else x
        out.alpha_composite(piece, (left_x, SIZE - piece.height - lift))
    rng = random.Random(7)
    for _ in range(46):
        x = rng.randint(20, SIZE - 21)
        y = rng.randint(SIZE - 16, SIZE - 3)
        size = rng.choice((1, 2, 2, 3))
        colour = rng.choice(RUBBLE) + (255,)
        for dx in range(size):
            for dy in range(size):
                if 0 <= x + dx < SIZE and 0 <= y + dy < SIZE:
                    out.putpixel((x + dx, y + dy), colour)
    out.save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
