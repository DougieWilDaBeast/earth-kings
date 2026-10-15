#!/usr/bin/env python3
"""Draw the Tower's door, and the lit rune stones that lead the eye up the yard to it.

    python3 tools/draw_tower.py

Needs Pillow (`pip install pillow`), like tools/draw_walls.py.

Meeting 3 (2026-10-15) found nobody gets into the Tower: the door was a small dark tower picture
blown up four times over, standing in front of a shaft of wall stone, and nothing on screen said
"this is the way in". Until `dougie` makes the Tower in PixelLab (docs/24-art-requests.md, A9) this
draws it in house, at the art's own pixel size (64 to a cell, nothing scaled up), out of the same
blue-grey stone as the town walls the stand-in shaft is built from (src/area/area_spire.gd), so the
door and the shaft read as one building. The runes are the one cold, bright colour in the yard,
so the eye goes to them.

Writes:
- art/props/landmark/tower_door.png        320 x 400: the Tower's foot with its door, five cells
  wide, the stair inside it going up into the dark
- art/props/landmark/tower_door/frame_*.png  the same, the runes breathing (AreaProp plays them)
- art/props/landmark/rune_stone.png        64 x 64: a flagstone with a lit rune cut into it
- art/props/landmark/rune_stone/frame_*.png  the same, breathing
- art/ui/far_tower.png                      80 x 320: the Tower seen from miles off, for the
  edge of the screen on the road (src/ui/far_tower.gd): the same stone and runes, lit at its door
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "props" / "landmark"

RGB = tuple[int, int, int]

# The town walls' stone (art/props/walls/stone_run.png), darkest to lightest.
INK: RGB = (19, 14, 35)
STONE = [(22, 18, 38), (37, 45, 62), (45, 55, 73), (65, 75, 96), (80, 89, 112), (108, 121, 149),
         (112, 125, 154), (150, 166, 196)]
MORTAR: RGB = (28, 26, 46)
HOLLOW: RGB = (10, 8, 22)
# The runes: the one cold, bright colour in the yard.
RUNE_DIM: RGB = (40, 120, 150)
RUNE_LIT: RGB = (150, 250, 255)
RUNE_CORE: RGB = (236, 255, 255)

W, H = 320, 400
FRAMES = 8

# Rune shapes, 5 x 7, drawn as strokes: (x0, y0, x1, y1) on a 4 x 6 grid.
GLYPHS: list[list[tuple[int, int, int, int]]] = [
    [(2, 0, 2, 6), (0, 2, 2, 0), (2, 0, 4, 2)],             # an arrow up
    [(0, 0, 0, 6), (0, 0, 4, 3), (4, 3, 0, 6)],             # a thorn
    [(2, 0, 2, 6), (0, 3, 4, 3)],                           # a cross
    [(0, 6, 2, 0), (2, 0, 4, 6), (1, 3, 3, 3)],             # a peak
    [(0, 0, 4, 6), (4, 0, 0, 6)],                           # an x
    [(0, 0, 0, 6), (4, 0, 4, 6), (0, 3, 4, 3)],             # a ladder
    [(2, 0, 2, 6), (2, 2, 4, 0), (2, 2, 0, 0)],             # a fork
    [(0, 6, 0, 0), (0, 0, 4, 0), (4, 0, 4, 3), (4, 3, 0, 3)],  # a flag
]


def mix(a: RGB, b: RGB, t: float) -> RGB:
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))  # type: ignore[return-value]


def glow_at(frame: int, phase: float = 0.0) -> float:
    """How lit the runes are on [frame], 0.45 to 1: a slow breath."""
    return 0.45 + 0.55 * (0.5 + 0.5 * math.sin((frame / FRAMES + phase) * math.tau))


def rune(d: ImageDraw.ImageDraw, x: int, y: int, which: int, colour: RGB, size: int = 1) -> None:
    for x0, y0, x1, y1 in GLYPHS[which % len(GLYPHS)]:
        d.line([(x + x0 * size, y + y0 * size), (x + x1 * size, y + y1 * size)], fill=colour, width=size)


def bricks(d: ImageDraw.ImageDraw, box: tuple[int, int, int, int], rng: random.Random,
           light_left: bool = True, course: int = 16, shade: float = 0.0) -> None:
    """Courses of the wall stone, the top edge of each brick catching the light."""
    x0, y0, x1, y1 = box
    d.rectangle(box, fill=MORTAR)
    row = 0
    y = y0
    while y < y1:
        off = 0 if row % 2 == 0 else -14
        x = x0 + off
        while x < x1:
            bw = rng.choice([26, 28, 30, 32])
            bx0, bx1 = max(x0, x + 1), min(x1, x + bw - 1)
            by0, by1 = y + 1, min(y1, y + course - 1)
            if bx1 - bx0 >= 3 and by1 - by0 >= 3:
                base = STONE[3] if rng.random() < 0.55 else STONE[4]
                base = mix(base, STONE[1], shade)
                d.rectangle((bx0, by0, bx1, by1), fill=base)
                d.line([(bx0, by0), (bx1, by0)], fill=mix(STONE[5], STONE[2], shade))
                if light_left:
                    d.line([(bx0, by0), (bx0, by1)], fill=mix(STONE[5], STONE[2], shade * 0.8))
                d.line([(bx0, by1), (bx1, by1)], fill=STONE[2])
                # A chip or a crack here and there.
                if rng.random() < 0.18:
                    cx = rng.randint(bx0 + 2, max(bx0 + 2, bx1 - 3))
                    d.point((cx, by0 + 2), fill=STONE[2])
                    d.point((cx + 1, by0 + 3), fill=STONE[2])
            x += bw
        y += course
        row += 1


def pointed_arch(cx: int, top: int, spring: int, bottom: int, half: int) -> list[tuple[int, int]]:
    """The outline of a pointed arch: straight jambs from [bottom] up to [spring], then two
    arcs meeting at [top]."""
    pts: list[tuple[int, int]] = [(cx - half, bottom), (cx - half, spring)]
    rise = spring - top
    steps = 24
    for i in range(1, steps + 1):
        t = i / steps
        # Each side is an arc centred on the far jamb: the classic two-centred arch.
        ang = math.asin(min(1.0, t * rise / (2 * half))) if half else 0
        x = cx - half + (2 * half) * (1 - math.cos(ang))
        y = spring - t * rise
        pts.append((round(min(x, cx)), round(y)))
    pts.append((cx, top))
    right = [(2 * cx - x, y) for x, y in reversed(pts)]
    return pts + right


def draw_door(frame: int) -> Image.Image:
    rng = random.Random(9)
    lit = glow_at(frame)
    rune_col = mix(RUNE_DIM, RUNE_LIT, lit)
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx = W // 2
    ground = H - 1

    # The face of the foot between the buttresses, with a stepped gable on top.
    face_top = 70
    gable = [(60, face_top + 26), (60, face_top), (100, face_top), (100, face_top - 22), (130, face_top - 22),
             (130, face_top - 44), (190, face_top - 44), (190, face_top - 22), (220, face_top - 22),
             (220, face_top), (260, face_top), (260, face_top + 26)]
    mask = Image.new("L", (W, H), 0)
    md = ImageDraw.Draw(mask)
    md.polygon(gable + [(260, ground - 30), (60, ground - 30)], fill=255)
    face = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bricks(ImageDraw.Draw(face), (60, face_top - 44, 260, ground - 30), rng)
    im.paste(face, (0, 0), mask)
    d.line(gable, fill=INK, width=2)
    # A cap stone along each step of the gable.
    for (ax, ay), (bx, by) in zip(gable, gable[1:]):
        if ay == by:
            d.rectangle((ax - 2, ay - 4, bx + 2, ay), fill=STONE[6], outline=INK)

    # The buttresses: taller than the face, lit on their left, each with runes stacked up it.
    for side in (-1, 1):
        bx0 = 8 if side < 0 else W - 72
        bx1 = bx0 + 64
        top = 18
        bricks(d, (bx0, top + 20, bx1, ground - 26), rng, light_left=side < 0, shade=0.0 if side < 0 else 0.25)
        # The pinnacle.
        d.polygon([(bx0, top + 20), (bx0 + 32, top - 14), (bx1, top + 20)], fill=STONE[4], outline=INK)
        d.line([(bx0 + 2, top + 19), (bx0 + 32, top - 11)], fill=STONE[6])
        d.rectangle((bx0 - 3, top + 18, bx1 + 3, top + 24), fill=STONE[6], outline=INK)
        d.rectangle((bx0, top + 20, bx1, ground - 26), outline=INK)
        # A sunk panel down its middle, runes cut into it.
        px0, px1 = bx0 + 20, bx1 - 20
        d.rectangle((px0, top + 40, px1, ground - 60), fill=HOLLOW, outline=INK)
        for i, y in enumerate(range(top + 50, ground - 74, 26)):
            phase_col = mix(RUNE_DIM, RUNE_LIT, glow_at(frame, 0.12 * i))
            rune(d, px0 + 6, y, i + (3 if side > 0 else 0), phase_col, 2)
        # Its foot, stepping out.
        d.rectangle((bx0 - 6, ground - 30, bx1 + 6, ground - 14), fill=STONE[3], outline=INK)
        d.line([(bx0 - 5, ground - 29), (bx1 + 5, ground - 29)], fill=STONE[6])

    # The opening: a pointed arch, the stair going up inside it into the dark.
    half, spring, apex, sill = 58, 190, 104, ground - 34
    outline = pointed_arch(cx, apex, spring, sill, half)
    hole = Image.new("L", (W, H), 0)
    ImageDraw.Draw(hole).polygon(outline, fill=255)
    inside = Image.new("RGBA", (W, H), HOLLOW + (255,))
    idr = ImageDraw.Draw(inside)
    # The stair, step on step, narrowing and darkening as it climbs, lit from below by the runes.
    steps = 14
    for i in range(steps):
        t = i / steps
        y1 = sill - round(i * (sill - spring + 30) / steps)
        y0 = y1 - 7
        inset = round(t * 30)
        tread = mix(mix(STONE[5], RUNE_LIT, 0.25 * lit), HOLLOW, t ** 0.7)
        riser = mix(STONE[2], HOLLOW, t ** 0.6)
        idr.rectangle((cx - half + inset, y0, cx + half - inset, y1), fill=riser)
        idr.line([(cx - half + inset, y0), (cx + half - inset, y0)], fill=tread)
    # The walls of the stairwell, in shadow, and light falling down the middle.
    idr.polygon([(cx - half, sill), (cx - half, apex), (cx - half + 30, spring - 30), (cx - half + 30, sill)],
                fill=mix(HOLLOW, STONE[1], 0.5))
    idr.polygon([(cx + half, sill), (cx + half, apex), (cx + half - 30, spring - 30), (cx + half - 30, sill)],
                fill=mix(HOLLOW, STONE[1], 0.3))
    im.paste(inside, (0, 0), hole)

    # The arch's stones, each with a rune, lit.
    band = pointed_arch(cx, apex - 16, spring, sill, half + 16)
    ring = Image.new("L", (W, H), 0)
    rd = ImageDraw.Draw(ring)
    rd.polygon(band, fill=255)
    rd.polygon(outline, fill=0)
    stones = Image.new("RGBA", (W, H), STONE[6] + (255,))
    sd = ImageDraw.Draw(stones)
    # Joints between the voussoirs, radiating from the arch's middle.
    for k in range(-9, 10):
        ang = k / 9 * (math.pi * 0.62)
        x = cx + math.sin(ang) * 200
        y = spring - math.cos(ang) * 200
        sd.line([(cx, spring + 40), (x, y)], fill=INK)
    for y in range(spring + 20, sill, 22):
        sd.line([(0, y), (W, y)], fill=INK)
    im.paste(stones, (0, 0), ring)
    d.line(band + [band[0]], fill=INK, width=2)
    d.line(outline, fill=INK, width=2)
    # Runes along the arch, one to a stone.
    for i, k in enumerate(range(-8, 9, 2)):
        ang = k / 9 * (math.pi * 0.5)
        r_x = cx + math.sin(ang) * (half + 6) - 4
        r_y = (spring - 40) - math.cos(ang) * ((spring - apex) * 0.95) + 8
        if k == 0:
            r_y = apex - 9
        rune(d, round(r_x), round(r_y), i, rune_col)
    for i, y in enumerate(range(spring + 4, sill - 10, 22)):
        rune(d, cx - half - 12, y + 6, i + 2, rune_col)
        rune(d, cx + half + 8, y + 6, i + 5, rune_col)

    # The Tower's mark over the door: a ring with a stair climbing through it.
    mx, my, mr = cx, 66, 20
    d.ellipse((mx - mr - 4, my - mr - 4, mx + mr + 4, my + mr + 4), fill=STONE[6], outline=INK, width=2)
    d.ellipse((mx - mr, my - mr, mx + mr, my + mr), fill=HOLLOW)
    d.ellipse((mx - mr + 3, my - mr + 3, mx + mr - 3, my + mr - 3), outline=rune_col, width=2)
    for i in range(4):
        sx = mx - 10 + i * 5
        sy = my + 8 - i * 5
        d.line([(sx, sy), (sx + 5, sy)], fill=mix(rune_col, RUNE_CORE, lit))
        d.line([(sx + 5, sy), (sx + 5, sy - 5)], fill=mix(rune_col, RUNE_CORE, lit))

    # The threshold: three steps spilling out of the door onto the yard.
    for i, (w, h) in enumerate([(150, 10), (132, 10), (116, 12)]):
        y1 = ground - i * 10
        y0 = y1 - h
        d.rectangle((cx - w // 2, y0, cx + w // 2, y1), fill=STONE[3], outline=INK)
        d.line([(cx - w // 2 + 1, y0 + 1), (cx + w // 2 - 1, y0 + 1)], fill=mix(STONE[6], RUNE_LIT, 0.35 * lit))

    # Glow: the runes and the doorway throw a cold light round themselves.
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    a = round(70 * lit)
    gd.ellipse((cx - half - 10, sill - 60, cx + half + 10, ground + 20), fill=RUNE_LIT + (a,))
    gd.ellipse((mx - mr - 14, my - mr - 14, mx + mr + 14, my + mr + 14), fill=RUNE_LIT + (round(a * 0.7),))
    glow = glow.filter(ImageFilter.GaussianBlur(10))
    # Stepped, so the light is pixel art too, not a smear.
    alpha = glow.getchannel("A").point(lambda v: 0 if v < 10 else (34 if v < 26 else 60))
    glow.putalpha(ImageChops.multiply(alpha, im.getchannel("A")))
    out = Image.alpha_composite(im, glow)
    return out


def draw_rune_stone(frame: int) -> Image.Image:
    """A flagstone set into the yard, seen at the art's slant, with a lit arrow cut into it
    pointing on up the yard, its light spilling round it."""
    lit = glow_at(frame)
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # The stone: a flattened octagon lying on the ground.
    box = [(6, 38), (14, 30), (50, 30), (58, 38), (58, 48), (50, 56), (14, 56), (6, 48)]
    d.polygon(box, fill=STONE[2], outline=INK)
    d.line([(7, 38), (14, 31), (50, 31)], fill=STONE[5])
    d.line([(14, 55), (50, 55), (57, 48)], fill=STONE[1])
    # The groove, then the arrow lit in it, squashed to lie flat.
    col = mix(RUNE_DIM, RUNE_LIT, lit)
    core = mix(col, RUNE_CORE, lit * 0.7)
    d.polygon([(32, 33), (45, 42), (38, 42), (38, 53), (26, 53), (26, 42), (19, 42)], fill=HOLLOW)
    d.polygon([(32, 35), (42, 41), (36, 41), (36, 51), (28, 51), (28, 41), (22, 41)], fill=col)
    d.line([(32, 37), (32, 49)], fill=core, width=2)
    # Its light, stepped.
    glow = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((0, 24, 64, 62), fill=RUNE_LIT + (round(120 * lit),))
    glow = glow.filter(ImageFilter.GaussianBlur(5))
    alpha = glow.getchannel("A").point(lambda v: 0 if v < 14 else (40 if v < 40 else 70))
    glow.putalpha(alpha)
    return Image.alpha_composite(glow, im)


def draw_far_tower() -> Image.Image:
    """The Tower from miles off: a shaft stepping in as it climbs, a band of runes at every step,
    lit windows low down, the door a cold light at its foot, and the top gone into the sky."""
    w, h = 80, 320
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx = w // 2
    foot = h - 1
    storey = 12
    half = 30.0
    y = foot - 22
    level = 0
    rng = random.Random(4)
    # The foot: wider, with the door in it.
    d.rectangle((cx - 38, foot - 22, cx + 38, foot), fill=STONE[3], outline=INK)
    d.line([(cx - 37, foot - 21), (cx + 37, foot - 21)], fill=STONE[6])
    d.rectangle((cx - 37, foot - 20, cx - 30, foot - 1), fill=STONE[4])
    d.rectangle((cx + 30, foot - 20, cx + 37, foot - 1), fill=STONE[2])
    d.polygon([(cx - 7, foot), (cx - 7, foot - 12), (cx, foot - 19), (cx + 7, foot - 12), (cx + 7, foot)], fill=RUNE_LIT,
              outline=INK)
    d.line([(cx, foot - 15), (cx, foot - 1)], fill=RUNE_CORE)
    while y > 0:
        hw = round(half)
        top = y - storey
        d.rectangle((cx - hw, top, cx + hw, y), fill=STONE[3])
        d.line([(cx - hw, top), (cx - hw, y)], fill=STONE[5])
        d.line([(cx + hw - 3, top), (cx + hw - 3, y)], fill=STONE[2])
        d.line([(cx + hw - 2, top), (cx + hw, y)], fill=STONE[1])
        d.line([(cx - hw, y), (cx + hw, y)], fill=STONE[2])
        # Brick joints.
        for x in range(cx - hw + (4 if level % 2 else 10), cx + hw - 3, 12):
            d.line([(x, top + 1), (x, y - 1)], fill=STONE[2])
        if level % 2 == 1:
            for x in range(cx - hw + 7, cx + hw - 6, 11):
                if rng.random() < 0.7:
                    lit = y > h * 0.5
                    d.rectangle((x, top + 3, x + 2, top + 7), fill=(240, 194, 104) if lit else HOLLOW)
        level += 1
        if level % 5 == 0:
            # A ledge and a band of runes, and the shaft steps in.
            d.rectangle((cx - hw - 2, top - 3, cx + hw + 2, top), fill=STONE[6], outline=INK)
            for x in range(cx - hw + 3, cx + hw - 2, 5):
                d.point((x, top + 3), fill=RUNE_LIT)
                d.point((x + 1, top + 4), fill=RUNE_LIT)
            half = max(10.0, half - 3.5)
        y = top
    # The outline, then the top fading into the sky.
    a = im.getchannel("A")
    edge = a.filter(ImageFilter.MaxFilter(3))
    ink = Image.new("RGBA", (w, h), INK + (255,))
    ink.putalpha(ImageChops.subtract(edge, a))
    im = Image.alpha_composite(ink, im)
    fade = Image.new("L", (w, h), 255)
    fd = ImageDraw.Draw(fade)
    for yy in range(h):
        t = yy / (h * 0.55)
        fd.line([(0, yy), (w, yy)], fill=round(255 * min(1.0, max(0.0, t)) ** 0.8))
    im.putalpha(ImageChops.multiply(im.getchannel("A"), fade))
    return im


def save(name: str, draw) -> None:
    folder = OUT / name
    folder.mkdir(parents=True, exist_ok=True)
    for f in range(FRAMES):
        draw(f).save(folder / ("frame_%03d.png" % f))
    # The still is the brightest moment, for the editor and anything that shows one picture.
    draw(FRAMES // 4).save(OUT / ("%s.png" % name))
    print("wrote art/props/landmark/%s.png and %d frames" % (name, FRAMES))


if __name__ == "__main__":
    save("tower_door", draw_door)
    save("rune_stone", draw_rune_stone)
    draw_far_tower().save(ROOT / "art" / "ui" / "far_tower.png")
    print("wrote art/ui/far_tower.png")
