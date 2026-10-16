#!/usr/bin/env python3
"""Record a "Who wins?" bout as clips (D180, docs/18-combat-direction.md#who-wins).

Two of the sixteen fight it out with nobody's hand on either, and Godot's movie
maker writes every frame, so the clip plays the same however slow the machine.

    python3 tools/who_wins.py ares cassius              # wide (1920x1080) and tall (1080x1920)
    python3 tools/who_wins.py ares cassius --seed 12    # another field, another fight
    python3 tools/who_wins.py --random 3                # three pairings the seed picks
    python3 tools/who_wins.py ares cassius --wide       # only the YouTube shape

The clips land in clips/ (ignored by git) as <left>_vs_<right>_s<seed>_<shape>.mp4.
Each is checked headless first: a pairing nobody wins inside the time limit is
skipped, since a clip that ends on NOBODY WINS is not one anyone finishes.

Godot is $EK_GODOT if set, else `godot` on the PATH. A machine with no screen
(a server, a cloud box) needs `xvfb-run` in front, which this adds by itself
when there is no DISPLAY. ffmpeg turns Godot's .avi into an .mp4; without it the
.avi is kept. Standard library only.
"""

import argparse
import os
import random
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCENE = "res://src/who_wins/who_wins.tscn"
SHAPES = {"wide": "1920x1080", "tall": "1080x1920"}
LEADS = ["atlas", "janus", "bellona", "cassius", "saturn", "vesta", "caesar", "iris",
         "pluto", "ceres", "cato", "juno", "ultor", "diana", "ares", "liber"]


def godot() -> str:
    found = os.environ.get("EK_GODOT") or shutil.which("godot")
    if not found:
        sys.exit("Godot 4.7 was not found. Put it on the PATH or set EK_GODOT=/path/to/godot.")
    return found


def verdict(left: str, right: str, seed: int, level: int) -> str:
    out = subprocess.run(
        [godot(), "--headless", "--path", ROOT, SCENE, "--",
         f"--left={left}", f"--right={right}", f"--seed={seed}", f"--level={level}", "--verdict"],
        capture_output=True, text=True).stdout
    found = re.search(r"who wins: .*", out)
    return found.group(0) if found else "who wins: (no answer)"


def record(left: str, right: str, seed: int, level: int, shape: str, out_dir: str) -> str:
    base = os.path.join(out_dir, f"{left}_vs_{right}_s{seed}_{shape}")
    command = [godot(), "--path", ROOT, "--write-movie", base + ".avi", "--fixed-fps", "30",
               "--resolution", SHAPES[shape], SCENE, "--",
               f"--left={left}", f"--right={right}", f"--seed={seed}", f"--level={level}", "--quit"]
    if not os.environ.get("DISPLAY") and shutil.which("xvfb-run"):
        command = ["xvfb-run", "-a", "-s", "-screen 0 1920x1920x24", command[0],
                   "--rendering-driver", "opengl3"] + command[1:]
    # The movie is the size of the game's own view, whatever the window is, so the
    # shape is set for this one run in override.cfg (read beside project.godot,
    # ignored by git) and taken away again after.
    width, height = SHAPES[shape].split("x")
    override = os.path.join(ROOT, "override.cfg")
    with open(override, "w") as f:
        f.write("[display]\n\nwindow/size/viewport_width=%s\nwindow/size/viewport_height=%s\n" % (width, height))
    try:
        subprocess.run(command, capture_output=True, text=True)
    finally:
        os.remove(override)
    if not shutil.which("ffmpeg"):
        return base + ".avi"
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", base + ".avi", "-c:v", "libx264",
                    "-pix_fmt", "yuv420p", "-crf", "20", "-c:a", "aac", base + ".mp4"], check=True)
    os.remove(base + ".avi")
    return base + ".mp4"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("left", nargs="?")
    parser.add_argument("right", nargs="?")
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument("--level", type=int, default=5)
    parser.add_argument("--random", type=int, default=0, help="record this many pairings the seed picks")
    parser.add_argument("--wide", action="store_true", help="only the wide shape")
    parser.add_argument("--tall", action="store_true", help="only the tall shape")
    parser.add_argument("--out", default=os.path.join(ROOT, "clips"))
    args = parser.parse_args()

    pairs = []
    if args.random:
        pick = random.Random(args.seed)
        for i in range(args.random):
            pairs.append((*pick.sample(LEADS, 2), args.seed + i))
    elif args.left in LEADS and args.right in LEADS and args.left != args.right:
        pairs.append((args.left, args.right, args.seed))
    else:
        sys.exit("Name two different leads (%s), or use --random N." % ", ".join(LEADS))
    shapes = [s for s in SHAPES if not (args.wide or args.tall) or getattr(args, s)]
    os.makedirs(args.out, exist_ok=True)

    for left, right, seed in pairs:
        said = verdict(left, right, seed, args.level)
        print(said)
        if "nobody" in said or "no answer" in said:
            print("  skipped: try another --seed")
            continue
        for shape in shapes:
            print("  " + os.path.relpath(record(left, right, seed, args.level, shape, args.out), ROOT))


if __name__ == "__main__":
    main()
