#!/usr/bin/env python3
"""Party clashes and guild wars: random parties fight it out, as a table and as video (D257).

Two parties of one to four, each fighter one of the sixteen or a unit at a random level, with
real gear, a stance and a pouch of draughts per side, fight on the real skirmish with nobody's
hand on either side (docs/18-combat-direction.md#party-clashes). Godot's movie maker writes
every frame, so a video plays the same however slow the machine.

    python3 tools/party_war.py table 150               # 150 draws, each fought both ways: results.csv + .md
    python3 tools/party_war.py clashes 5 --seed 7      # five clashes in a row, one video
    python3 tools/party_war.py clashes --seeds 1005,1009   # these draws (seeds from the table)
    python3 tools/party_war.py war --seed 7            # the guild war (wars.guild_vs_empire)
    python3 tools/party_war.py all                     # the three of them

Everything lands in --out (default clips/, ignored by git). Godot is $EK_GODOT if set, else
`godot` on the PATH; with no DISPLAY it runs under `xvfb-run`. ffmpeg turns Godot's .avi into
an .mp4; without it the .avi is kept. Standard library only.
"""

import argparse
import collections
import csv
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCENE = "res://src/party_war/party_war.tscn"
SIZE = ("1920", "1080")


def godot() -> str:
    found = os.environ.get("EK_GODOT") or shutil.which("godot")
    if not found:
        sys.exit("Godot 4.7 was not found. Put it on the PATH or set EK_GODOT=/path/to/godot.")
    return found


def parse(line: str) -> dict:
    row = {}
    for part in line[len("clash: "):].split(" | "):
        key, _, value = part.partition("=")
        row[key] = value
    return row


def run_headless(extra: list) -> list:
    out = subprocess.run([godot(), "--headless", "--path", ROOT, SCENE, "--"] + extra,
                         capture_output=True, text=True).stdout
    return [parse(line) for line in out.splitlines() if line.startswith("clash: ")]


def record(name: str, extra: list, out_dir: str) -> str:
    base = os.path.join(out_dir, name)
    command = [godot(), "--path", ROOT, "--write-movie", base + ".avi", "--fixed-fps", "30",
               "--resolution", "x".join(SIZE), SCENE, "--"] + extra
    if not os.environ.get("DISPLAY") and shutil.which("xvfb-run"):
        command = ["xvfb-run", "-a", "-s", "-screen 0 1920x1080x24", command[0],
                   "--rendering-driver", "opengl3"] + command[1:]
    # The movie is the size of the game's own view, so it is set for this run in override.cfg
    # (read beside project.godot, ignored by git) and taken away after.
    override = os.path.join(ROOT, "override.cfg")
    with open(override, "w") as f:
        f.write("[display]\n\nwindow/size/viewport_width=%s\nwindow/size/viewport_height=%s\n" % SIZE)
    try:
        done = subprocess.run(command, capture_output=True, text=True)
    finally:
        os.remove(override)
    for line in done.stdout.splitlines():
        if line.startswith("clash: "):
            row = parse(line)
            print("  %s won in %ss (%s v %s)" % (row["winner"], row["seconds"], row["left_size"], row["right_size"]))
    if not shutil.which("ffmpeg"):
        return base + ".avi"
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", base + ".avi", "-c:v", "libx264",
                    "-pix_fmt", "yuv420p", "-crf", "22", "-c:a", "aac", base + ".mp4"], check=True)
    os.remove(base + ".avi")
    return base + ".mp4"


def share(won: int, of: int) -> str:
    return "%d of %d (%.0f%%)" % (won, of, 100.0 * won / of) if of else "none"


def write_table(rows: list, out_dir: str) -> str:
    fields = list(rows[0].keys())
    with open(os.path.join(out_dir, "results.csv"), "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    decided = [r for r in rows if r["winner"] != "none"]
    lines = ["# Party clashes: %d fights" % len(rows), "",
             "Drawn by `tools/party_war.py table` (D257). Left is the side that fights as the company "
             "(near-death window, friends who pull them up); right fights as the other side.", "",
             "| | |", "| --- | --- |",
             "| Left wins | %s |" % share(sum(r["winner"] == "left" for r in rows), len(rows)),
             "| Right wins | %s |" % share(sum(r["winner"] == "right" for r in rows), len(rows)),
             "| Nobody (time ran out) | %s |" % share(len(rows) - len(decided), len(rows))]
    seconds = sorted(float(r["seconds"]) for r in decided)
    if seconds:
        lines.append("| Fight length (decided) | shortest %.0fs, middle %.0fs, longest %.0fs |" % (
            seconds[0], seconds[len(seconds) // 2], seconds[-1]))
    # Each draw is fought both ways round: a party that wins both times is stronger, one that
    # wins only on the company's side was carried by it.
    pairs = collections.defaultdict(dict)
    for r in rows:
        pairs[r["seed"]][r.get("swapped", "0")] = r
    both = [p for p in pairs.values() if len(p) == 2]
    same = sum(1 for p in both if p["0"]["winner"] != "none" and
               {"left": "right", "right": "left"}.get(p["0"]["winner"]) == p["1"]["winner"])
    company = sum(1 for p in both if p["0"]["winner"] == "left" and p["1"]["winner"] == "left")
    other = sum(1 for p in both if p["0"]["winner"] == "right" and p["1"]["winner"] == "right")
    if both:
        lines += ["", "## Both ways round", "",
                  "Each draw fought twice, the second time with the parties changed round (%d draws)." % len(both), "",
                  "| | |", "| --- | --- |",
                  "| Same party won both times | %s |" % share(same, len(both)),
                  "| The company's side won both times (the side decided it) | %s |" % share(company, len(both)),
                  "| The other side won both times | %s |" % share(other, len(both)),
                  "| A draw at least once | %s |" % share(len(both) - same - company - other, len(both))]
    lines += ["", "## Bigger party", "", "| Size gap | Fights | Bigger side won |", "| --- | --- | --- |"]
    by_gap = collections.defaultdict(lambda: [0, 0])
    for r in decided:
        gap = int(r["left_size"]) - int(r["right_size"])
        if gap == 0:
            continue
        bigger = "left" if gap > 0 else "right"
        by_gap[abs(gap)][0] += 1
        by_gap[abs(gap)][1] += r["winner"] == bigger
    for gap in sorted(by_gap):
        lines.append("| %+d | %d | %s |" % (gap, by_gap[gap][0], share(by_gap[gap][1], by_gap[gap][0])))
    lines += ["", "## More levels in total", "", "| Level gap | Fights | Side with more levels won |",
              "| --- | --- | --- |"]
    bands = [(1, 5), (6, 10), (11, 20), (21, 99)]
    for low, high in bands:
        fights = won = 0
        for r in decided:
            gap = int(r["left_levels"]) - int(r["right_levels"])
            if low <= abs(gap) <= high:
                fights += 1
                won += r["winner"] == ("left" if gap > 0 else "right")
        lines.append("| %d-%d | %d | %s |" % (low, high, fights, share(won, fights)))
    lines += ["", "## Same total level, different size", "",
              "Fights where the two sides' levels add up to within 3 of each other but one side has more bodies.", ""]
    fights = won = 0
    for r in decided:
        gap = int(r["left_size"]) - int(r["right_size"])
        if gap != 0 and abs(int(r["left_levels"]) - int(r["right_levels"])) <= 3:
            fights += 1
            won += r["winner"] == ("left" if gap > 0 else "right")
    lines.append("More bodies won %s." % share(won, fights))
    # Every fighter counted once per fight: how often the side they stood on won.
    leads = {"atlas", "janus", "bellona", "cassius", "saturn", "vesta", "caesar", "iris",
             "pluto", "ceres", "cato", "juno", "ultor", "diana", "ares", "liber"}
    stance = collections.defaultdict(lambda: [0, 0])
    kind = collections.defaultdict(lambda: [0, 0])
    for r in decided:
        for side in ("left", "right"):
            for who in r[side + "_who"].split():
                unit, _level, _gear, how = who.split(":")
                won = r["winner"] == side
                for table, key in ((stance, how), (kind, "one of the sixteen" if unit in leads else "a unit")):
                    table[key][0] += 1
                    table[key][1] += won
    lines += ["", "Each fighter once per decided fight. A bigger side has more fighters and wins more, so "
              "every row sits above half; compare the rows with each other."]
    for title, table in (("Stance", stance), ("Who", kind)):
        lines += ["", "## By %s" % title.lower(), "", "| %s | Fighters | Their side won |" % title,
                  "| --- | --- | --- |"]
        for key in sorted(table):
            lines.append("| %s | %d | %s |" % (key, table[key][0], share(table[key][1], table[key][0])))
    lines += ["", "## Every fight", "", "| Seed | Swapped | Winner | Seconds | Left (unit:level:gear:stance) | Right |",
              "| --- | --- | --- | --- | --- | --- |"]
    for r in rows:
        lines.append("| %s | %s | %s | %s | %s | %s |" % (r["seed"], r.get("swapped", "0"), r["winner"], r["seconds"],
                                                       r["left_who"], r["right_who"]))
    path = os.path.join(out_dir, "results.md")
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")
    return path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("what", choices=["table", "clashes", "war", "all"])
    parser.add_argument("count", nargs="?", type=int, default=0)
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument("--seeds", default="", help="clashes: these draws (comma list) instead of count from --seed")
    parser.add_argument("--war-id", default="guild_vs_empire")
    parser.add_argument("--out", default=os.path.join(ROOT, "clips"))
    args = parser.parse_args()
    os.makedirs(args.out, exist_ok=True)
    if args.what in ("table", "all"):
        rows = run_headless(["--table=%d" % (args.count or 150), "--seed=%d" % (args.seed * 1000)])
        print(os.path.relpath(write_table(rows, args.out), ROOT))
    if args.what in ("clashes", "all"):
        if args.seeds:
            name, extra = "clashes_%s" % args.seeds.replace(",", "-"), ["--seeds=%s" % args.seeds]
        else:
            count = args.count or 5
            name, extra = "clashes_s%d_x%d" % (args.seed, count), ["--fights=%d" % count, "--seed=%d" % args.seed]
        print(os.path.relpath(record(name, extra, args.out), ROOT))
    if args.what in ("war", "all"):
        print(os.path.relpath(record("war_%s_s%d" % (args.war_id, args.seed),
                                     ["--war=%s" % args.war_id, "--seed=%d" % args.seed], args.out), ROOT))


if __name__ == "__main__":
    main()
