#!/usr/bin/env python3
"""Draw the keeper of the Tower's fifth floor, the Warden, in house.

    python3 tools/draw_keeper.py

Needs Pillow (`pip install pillow`), like tools/draw_road.py.

The First Hour ended on a slime: the fifth floor was kept by `king_slime` and two `blue_slime`, which
docs/22 flags as dev-only (P6, Dragon Quest lineage), so no public build can end on them. Will's AK
(2026-10-15, "All recommended") makes the keeper the game's own figure now, drawn in house, and the
creatives' meeting gave it its nature: a person who keeps the floor and would let the lead stay at
the top of it, if they stopped climbing. D156 draws it: the Warden of the Fifth, armoured in the
Tower's own grey stone with its runes lit down the breastplate, a heavy slate cloak, a tall helm
with a dark red crest and a cold T of light for a face, and a long glaive. Its big move shows before it lands: the skill is a
long wind-up, the glaive raised and its blade filling with the runes' light, then the slam.

Writes art/big/tower_warden/ in the layout PixelLab's 96-pixel characters use (art/big/king_slime):

- idle/<eight headings>.png                     the standing pose
- walk/<south|north|east|west>/frame_000..007   a heavy step
- attack/<heading>/frame_000..005               a swing of the glaive
- skill/<heading>/frame_000..009                the wind-up, glowing, then the slam
- hit/<heading>/frame_000..002                  a flinch
- death/<heading>/frame_000..007                down on one knee, the glaive falls, the light goes out

Headings: the south, north and east views are drawn; west is east turned round; the diagonals stand
as the nearer of south or north, turned to their side.
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "big" / "tower_warden"
S = 96

CLOAK = ((44, 46, 60), (62, 66, 84), (28, 29, 40))
ARMOUR = ((116, 120, 132), (164, 168, 178), (74, 76, 88))
HELM = ((126, 130, 142), (176, 180, 190), (78, 80, 92))
LEATHER = ((74, 56, 42), (98, 76, 56), (48, 36, 28))
BOOT = ((40, 38, 46), (58, 56, 66), (26, 24, 30))
POLE = ((70, 56, 44), (96, 78, 60), (44, 34, 28))
STEEL = ((176, 184, 198), (222, 228, 236), (112, 118, 132))
RUNE = (120, 220, 255)
RUNE_HOT = (226, 250, 255)
OUTLINE = (16, 14, 22)
PLUME = ((122, 34, 40), (162, 52, 56), (78, 20, 28))


def shade(colour: tuple, amount: float) -> tuple:
    return tuple(max(0, min(255, int(v + amount))) for v in colour)


class Canvas:
    """Parts drawn in order, each shaded on its own edges (lit up and left, dark down and right)."""

    def __init__(self) -> None:
        self.px: dict[tuple[int, int], tuple] = {}

    def part(self, cells: set, colours: tuple, gradient: float = 18.0) -> None:
        base, lit, dark = colours
        if not cells:
            return
        top = min(y for _x, y in cells)
        tall = max(1, max(y for _x, y in cells) - top)
        for x, y in cells:
            if not (0 <= x < S and 0 <= y < S):
                continue
            # Lighter at the top of a part, darker at its foot, in steps of two pixels so it reads as
            # pixel shading rather than a smooth ramp.
            step = ((y - top) // 2 * 2) / tall
            c = shade(base, (0.5 - step) * gradient)
            if (x - 1, y) not in cells or (x, y - 1) not in cells:
                c = lit
            elif (x + 1, y) not in cells or (x, y + 1) not in cells:
                c = dark
            self.px[(x, y)] = c

    def flat(self, cells, colour: tuple) -> None:
        for x, y in cells:
            if 0 <= x < S and 0 <= y < S:
                self.px[(x, y)] = colour

    def image(self, flash: float = 0.0, alpha: float = 1.0) -> Image.Image:
        im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        p = im.load()
        filled = set(self.px)
        # A one-pixel dark outline round the whole figure, as the PixelLab sprites have.
        for x, y in list(filled):
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if (nx, ny) not in filled and 0 <= nx < S and 0 <= ny < S:
                    p[nx, ny] = OUTLINE + (int(255 * alpha),)
        for (x, y), c in self.px.items():
            if flash > 0:
                c = tuple(int(v + (255 - v) * flash) for v in c)
            p[x, y] = tuple(c) + (int(255 * alpha),)
        return im


def rect(x0, y0, x1, y1) -> set:
    return {(x, y) for y in range(int(y0), int(y1)) for x in range(int(x0), int(x1))}


def ellipse(cx, cy, rx, ry) -> set:
    out = set()
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1:
                out.add((x, y))
    return out


def poly(points) -> set:
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    out = set()
    for y in range(int(min(ys)), int(max(ys)) + 1):
        for x in range(int(min(xs)), int(max(xs)) + 1):
            cx, cy = x + 0.5, y + 0.5
            inside = False
            j = len(points) - 1
            for i in range(len(points)):
                xi, yi = points[i]
                xj, yj = points[j]
                if (yi > cy) != (yj > cy) and cx < (xj - xi) * (cy - yi) / (yj - yi) + xi:
                    inside = not inside
                j = i
            if inside:
                out.add((x, y))
    return out


def line(x0, y0, x1, y1, width: float = 1.0) -> set:
    out = set()
    steps = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
    r = width / 2
    for i in range(steps + 1):
        t = i / steps
        x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        for yy in range(int(y - r) - 1, int(y + r) + 2):
            for xx in range(int(x - r) - 1, int(x + r) + 2):
                if (xx + 0.5 - x) ** 2 + (yy + 0.5 - y) ** 2 <= r * r + 0.25:
                    out.add((xx, yy))
    return out


def glaive(c: Canvas, hx: float, hy: float, angle: float, side: int, glow: float) -> None:
    """The glaive held at (hx, hy), `angle` degrees from straight up (positive leans to `side`)."""
    a = math.radians(angle) * side
    dx, dy = math.sin(a), -math.cos(a)
    tip = (hx + dx * 42, hy + dy * 42)
    butt = (hx - dx * 14, hy - dy * 14)
    c.part(line(butt[0], butt[1], tip[0], tip[1], 2.2), POLE, 0)
    c.part(rect(butt[0] - 1, butt[1] - 1, butt[0] + 2, butt[1] + 2), ARMOUR, 0)
    # The blade: a long curved head, its belly on the outer side of the haft, its point running on.
    nx, ny = -dy * side, dx * side
    back, belly = [], []
    for i in range(9):
        s = i / 8
        along = -4 + s * 24
        bulge = math.sin(s * math.pi) * 9
        back.append((tip[0] + dx * along + nx * (s * 2), tip[1] + dy * along + ny * (s * 2)))
        belly.append((tip[0] + dx * along + nx * (2 + bulge), tip[1] + dy * along + ny * (2 + bulge)))
    c.part(poly(back + belly[::-1]), STEEL, 10)
    edge = set()
    for (x0, y0), (x1, y1) in zip(belly, belly[1:]):
        edge |= line(x0, y0, x1, y1, 1.0)
    if glow > 0:
        colour = tuple(int(STEEL[1][i] + (RUNE[i] - STEEL[1][i]) * glow) for i in range(3))
        c.flat(edge, RUNE_HOT if glow > 0.8 else colour)
        if glow > 0.5:
            # The light spilling off the blade.
            halo = set()
            for x, y in edge:
                halo |= {(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)}
            c.flat({p for p in halo if p not in c.px}, RUNE)
    else:
        c.flat(edge, STEEL[1])
    # The collar where the head meets the haft, and the hook on its back.
    c.part(rect(tip[0] - 2, tip[1] - 1, tip[0] + 3, tip[1] + 2), ARMOUR, 0)
    c.part(line(tip[0] - nx * 1, tip[1] - ny * 1, tip[0] - nx * 5 + dx * 3, tip[1] - ny * 5 + dy * 3, 1.6), STEEL, 0)


def runes_down(c: Canvas, x: int, y0: int, y1: int, light: float) -> None:
    colour = RUNE_HOT if light > 0.8 else RUNE
    for y in range(y0, y1, 5):
        c.flat({(x, y), (x, y + 1), (x - 1, y + 2), (x + 1, y + 2)}, colour)


def plume(c: Canvas, x: float, top: float, sweep: int) -> None:
    """A crest of dark red hair over the helm, swept back."""
    cells = set()
    for i in range(10):
        cells |= line(x + sweep * i * 0.6, top + i * 0.5, x + sweep * (i * 0.6 + 2), top + 3 + i * 0.9, 2.0)
    c.part(cells, PLUME, 14)


def figure(view: str, pose: dict) -> Image.Image:
    """One frame. `view` is south, north or east; `pose` moves the parts."""
    c = Canvas()
    bob = pose.get("bob", 0)
    kneel = pose.get("kneel", 0)
    y = lambda v: v + bob + kneel  # noqa: E731  (everything above the legs sinks as it kneels)
    step = pose.get("step", 0)
    angle = pose.get("angle", -8)
    glow = pose.get("glow", 0.0)
    visor = pose.get("visor", 1.0)
    lean = pose.get("lean", 0)
    legs = max(2, 12 - kneel)
    lit_visor = RUNE_HOT if visor > 0.5 else RUNE

    if view == "east":
        L = lean
        c.part(rect(44 + step, 90 - legs, 50 + step, 90), BOOT, 8)
        c.part(rect(49 - step, 90 - legs, 55 - step, 90), BOOT, 8)
        # The cloak hangs behind, ragged at the hem.
        hem = [(53 - i * 3, y(84) + (i % 2) * 2) for i in range(7)]
        cloak = poly([(41 + L, y(42)), (50 + L, y(42))] + hem + [(33, y(78))])
        c.part(cloak, CLOAK, 22)
        c.flat(({(38, yy) for yy in range(y(56), y(82))} | {(43, yy) for yy in range(y(60), y(84))}) & cloak, CLOAK[2])
        c.part(poly([(47 + L, y(44)), (59 + L, y(44)), (58 + L, y(64)), (48 + L, y(64))]), ARMOUR)
        c.flat({(x, y(53)) for x in range(48 + L, 58 + L)} | {(x, y(59)) for x in range(48 + L, 58 + L)}, ARMOUR[2])
        runes_down(c, 55 + L, y(45), y(62), glow)
        c.part(rect(46 + L, y(64), 59 + L, y(67)), LEATHER, 0)
        c.part(poly([(46 + L, y(67)), (59 + L, y(67)), (60 + L, y(77)), (45 + L, y(77))]), ARMOUR)
        c.flat({(52 + L, yy) for yy in range(y(68), y(77))}, ARMOUR[2])
        c.part(rect(46 + L, y(39), 57 + L, y(45)), ARMOUR[::-1][:1] + ARMOUR[1:], 0)
        c.part(ellipse(51 + L, y(46), 8, 6), ARMOUR)
        helm = poly([(46 + L, y(26)), (49 + L, y(21)), (55 + L, y(21)), (58 + L, y(26)), (59 + L, y(40)), (45 + L, y(40))])
        c.part(helm, HELM)
        plume(c, 51 + L, y(15), -1)
        if visor > 0:
            c.flat(rect(54 + L, y(30), 59 + L, y(32)) | rect(57 + L, y(32), 59 + L, y(36)), lit_visor)
        c.part(poly([(55 + L, y(50)), (61 + L, y(50)), (62 + L, y(62)), (57 + L, y(62))]), ARMOUR)
        glaive(c, 61 + L, y(61), angle, 1, glow)
        c.part(ellipse(61 + L, y(61), 3, 3), LEATHER, 0)
    elif view == "south":
        up_l = 2 if step > 0 else 0
        up_r = 2 if step < 0 else 0
        c.part(rect(41, 90 - legs - up_l, 47, 90 - up_l), BOOT, 8)
        c.part(rect(50, 90 - legs - up_r, 56, 90 - up_r), BOOT, 8)
        hem = [(29 + i * 4, y(83) + (i % 2) * 2) for i in range(10)]
        c.part(poly([(34, y(42)), (62, y(42))] + hem[::-1]), CLOAK, 22)
        c.flat({(33, yy) for yy in range(y(56), y(82))} | {(63, yy) for yy in range(y(56), y(82))}, CLOAK[2])
        c.part(poly([(37, y(44)), (59, y(44)), (56, y(64)), (40, y(64))]), ARMOUR)
        c.flat({(x, y(53)) for x in range(39, 58)} | {(x, y(59)) for x in range(40, 57)}, ARMOUR[2])
        runes_down(c, 48, y(46), y(62), glow)
        c.part(rect(39, y(64), 58, y(67)), LEATHER, 0)
        c.flat(rect(46, y(64), 51, y(67)), STEEL[0])
        c.part(poly([(38, y(67)), (59, y(67)), (61, y(78)), (36, y(78))]), ARMOUR)
        c.flat({(48, yy) for yy in range(y(68), y(78))} | {(42, yy) for yy in range(y(69), y(78))} | {(54, yy) for yy in range(y(69), y(78))}, ARMOUR[2])
        c.part(rect(42, y(39), 55, y(45)), ARMOUR, 0)
        c.part(ellipse(35, y(46), 8, 6), ARMOUR)
        c.part(ellipse(61, y(46), 8, 6), ARMOUR)
        c.flat({(x, y(50)) for x in range(28, 43)} & ellipse(35, y(46), 8, 6), ARMOUR[2])
        c.flat({(x, y(50)) for x in range(54, 69)} & ellipse(61, y(46), 8, 6), ARMOUR[2])
        helm = poly([(41, y(26)), (44, y(20)), (52, y(20)), (55, y(26)), (56, y(40)), (40, y(40))])
        c.part(helm, HELM)
        plume(c, 47, y(14), 0)
        if visor > 0:
            c.flat(rect(42, y(29), 54, y(31)) | rect(47, y(31), 49, y(37)), lit_visor)
        c.part(poly([(59, y(50)), (65, y(50)), (64, y(64)), (59, y(64))]), ARMOUR)
        c.part(rect(58, y(62), 65, y(66)), LEATHER, 0)
        c.part(poly([(31, y(50)), (37, y(50)), (36, y(60)), (32, y(60))]), ARMOUR)
        glaive(c, 33, y(62), angle, -1, glow)
        c.part(ellipse(33, y(62), 3, 3), LEATHER, 0)
    else:  # north: the back, the cloak over everything, the glaive on its right (our right)
        up_l = 2 if step > 0 else 0
        up_r = 2 if step < 0 else 0
        c.part(rect(41, 90 - legs - up_l, 47, 90 - up_l), BOOT, 8)
        c.part(rect(50, 90 - legs - up_r, 56, 90 - up_r), BOOT, 8)
        glaive(c, 63, y(62), angle, 1, glow)
        hem = [(28 + i * 4, y(85) + (i % 2) * 2) for i in range(11)]
        c.part(poly([(33, y(40)), (63, y(40))] + hem[::-1]), CLOAK, 26)
        c.flat({(37, yy) for yy in range(y(58), y(84))} | {(59, yy) for yy in range(y(58), y(84))} | {(44, yy) for yy in range(y(64), y(85))}, CLOAK[2])
        # The Tower's mark worked into the cloak: three strokes, lit as the runes are.
        mark = RUNE if glow > 0.2 else CLOAK[1]
        c.flat(line(48, y(52), 48, y(68), 1) | line(43, y(57), 48, y(52), 1) | line(53, y(57), 48, y(52), 1), mark)
        c.part(ellipse(35, y(44), 8, 6), ARMOUR)
        c.part(ellipse(61, y(44), 8, 6), ARMOUR)
        helm = poly([(41, y(26)), (44, y(20)), (52, y(20)), (55, y(26)), (56, y(41)), (40, y(41))])
        c.part(helm, HELM)
        plume(c, 47, y(14), 0)
        c.part(poly([(59, y(48)), (65, y(48)), (65, y(62)), (60, y(62))]), ARMOUR)
        c.part(ellipse(63, y(62), 3, 3), LEATHER, 0)
    im = c.image(pose.get("flash", 0.0), pose.get("alpha", 1.0))
    if pose.get("mark", 0) > 0:
        # The mark on the floor where the slam will land: a ring of the runes' light.
        p = im.load()
        cx, cy = (78, 88) if view == "east" else (48, 92) if view == "south" else (48, 86)
        ring = pose["mark"]
        for yy in range(S):
            for xx in range(S):
                d = math.hypot((xx - cx) / 1.0, (yy - cy) * 2.2)
                if abs(d - 12) < 1.2 and p[xx, yy][3] == 0:
                    p[xx, yy] = RUNE + (int(200 * ring),)
    return im


# Each move as a list of poses.
def walk() -> list[dict]:
    return [{"step": s, "bob": b} for s, b in ((2, 0), (3, -1), (2, 0), (0, 0), (-2, 0), (-3, -1), (-2, 0), (0, 0))]


def attack() -> list[dict]:
    return [{"angle": a, "lean": l, "bob": b} for a, l, b in ((-8, 0, 0), (-40, -1, 0), (-70, -2, -1), (30, 1, 0), (95, 2, 1), (40, 1, 0))]


def skill() -> list[dict]:
    """The wind-up the keeper teaches with: slow, glowing, a mark on the floor, then the slam."""
    out = []
    for i in range(6):
        out.append({"angle": -8 - i * 14, "lean": -min(i, 2), "glow": i / 5, "mark": i / 5, "bob": -1 if i % 2 else 0})
    out.append({"angle": 20, "lean": 1, "glow": 1.0, "mark": 1.0})
    out.append({"angle": 100, "lean": 3, "glow": 1.0, "mark": 1.0, "bob": 2})
    out.append({"angle": 100, "lean": 3, "glow": 0.6, "flash": 0.2, "bob": 2})
    out.append({"angle": 40, "lean": 1, "glow": 0.2})
    return out


def hit() -> list[dict]:
    return [{"flash": 0.6, "lean": -2}, {"flash": 0.25, "lean": -1}, {}]


def death() -> list[dict]:
    return [
        {"flash": 0.5, "lean": -2},
        {"kneel": 3, "angle": 10},
        {"kneel": 6, "angle": 30, "visor": 0.6},
        {"kneel": 8, "angle": 60, "visor": 0.4},
        {"kneel": 9, "angle": 85, "visor": 0.2},
        {"kneel": 10, "angle": 95, "visor": 0.0, "alpha": 0.85},
        {"kneel": 10, "angle": 95, "visor": 0.0, "alpha": 0.6},
        {"kneel": 10, "angle": 95, "visor": 0.0, "alpha": 0.35},
    ]


def view_for(heading: str) -> tuple[str, bool]:
    """The drawn view for a heading and whether it is turned round (mirrored)."""
    return {
        "south": ("south", False), "north": ("north", False), "east": ("east", False), "west": ("east", True),
        "south-east": ("south", False), "south-west": ("south", True),
        "north-east": ("north", False), "north-west": ("north", True),
    }[heading]


def frame(heading: str, pose: dict) -> Image.Image:
    view, mirror = view_for(heading)
    im = figure(view, pose)
    return im.transpose(Image.FLIP_LEFT_RIGHT) if mirror else im


def save(path: Path, im: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)


def main() -> None:
    for heading in ("south", "north", "east", "west", "south-east", "south-west", "north-east", "north-west"):
        save(OUT / "idle" / ("%s.png" % heading), frame(heading, {}))
    moves = {"walk": walk(), "attack": attack(), "skill": skill(), "hit": hit(), "death": death()}
    for state, poses in moves.items():
        for heading in ("south", "north", "east", "west"):
            for i, pose in enumerate(poses):
                save(OUT / state / heading / ("frame_%03d.png" % i), frame(heading, pose))
    print("wrote art/big/tower_warden/ (idle x 8, %s)" % ", ".join("%s %d" % (k, len(v)) for k, v in moves.items()))


if __name__ == "__main__":
    main()
