#!/usr/bin/env python3
"""Draw a cave mouth: a hump of rock with a dark way in at its foot.

    python3 tools/draw_cave_mouth.py

Needs Pillow (`pip install pillow`), like tools/draw_gate.py.

Play-test 7 (doug-md): "go into a cave and it'll be a whole different area", like Pokémon's. D282 draws
the mouth in house until art request A48 is made:

- art/buildings/cave_mouth.png    64 x 64, drawn as a building (data/props.json `buildings`), its door
                                  the dark arch in the middle of its front row.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "buildings" / "cave_mouth.png"
SIZE = 64
ROCK = [(112, 108, 102), (96, 92, 88), (128, 122, 114), (84, 80, 76)]
DARK = (14, 12, 16, 255)
MOSS = (74, 96, 58)


def main() -> None:
    rng = random.Random(281)
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    # The hump: a ragged half-dome of stones, widest at the ground.
    for y in range(14, SIZE):
        t = (y - 14) / (SIZE - 14)
        half = 30 * math.sqrt(max(0.0, t)) + rng.uniform(-1.5, 1.5)
        for x in range(int(32 - half), int(32 + half)):
            shade = ROCK[(x // 5 + y // 4 + rng.randint(0, 1)) % len(ROCK)]
            if rng.random() < 0.06:
                shade = MOSS
            image.putpixel((x, y), shade + (255,))
    # Cracks between the stones.
    for _ in range(14):
        x = rng.randint(10, 54)
        y = rng.randint(20, 60)
        draw.line([(x, y), (x + rng.randint(-5, 5), y + rng.randint(2, 6))], fill=(60, 58, 56, 255))
    # The way in: a dark arch at the foot, a lip of lighter stone round it.
    draw.ellipse([20, 34, 44, 70], fill=(140, 134, 124, 255))
    draw.ellipse([23, 37, 41, 70], fill=DARK)
    draw.rectangle([23, 54, 41, 63], fill=DARK)
    image.save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
