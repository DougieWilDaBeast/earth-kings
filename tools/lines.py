#!/usr/bin/env python3
"""Every line said in the game, in one place, and the tics the writers' pass (D274) took out.

    python3 tools/lines.py                 # the tics still in data/, file by file
    python3 tools/lines.py --script out.md # every line, by file, as one script to read through

A line is any string value of four words or more in data/ (maps aside) that is not a developer's
note (a key starting with `_`, or `note`/`rules`). The tics are the writers' pass's list
(docs/13, "The lines"): em-dashes in a line, and the stock phrases that read as written by a model.
Standard library only.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
SKIP_KEYS = ("note", "rules", "hint", "art", "sprite", "sprite_dir", "path", "file", "id")
TICS = {
    "em-dash": r"—",
    "its own kind of": r"\bits own (kind of|small)\b",
    "a new kind of": r"\ba new kind of\b",
    "the part nobody": r"\bthe part (nobody|no one)\b",
    "and somehow": r"\band somehow\b",
    "something about the way": r"\bsomething about the way\b",
    "I suppose (closing)": r"I suppose\.?\"?$",
}


def lines() -> list[tuple[str, str, str]]:
    out: list[tuple[str, str, str]] = []

    def walk(name: str, value: object, path: list[str]) -> None:
        if isinstance(value, dict):
            for key, item in value.items():
                if key.startswith("_") or key in SKIP_KEYS:
                    continue
                walk(name, item, path + [key])
        elif isinstance(value, list):
            for i, item in enumerate(value):
                walk(name, item, path + [str(i)])
        elif isinstance(value, str) and len(value.split()) >= 4 and not value.startswith(("res://", "art/")):
            out.append((name, "/".join(path), value))

    for file in sorted(DATA.rglob("*.json")):
        if "maps" in file.parts:
            continue
        walk(str(file.relative_to(DATA)), json.loads(file.read_text(encoding="utf-8")), [])
    return out


def main() -> int:
    every = lines()
    if len(sys.argv) > 2 and sys.argv[1] == "--script":
        with open(sys.argv[2], "w", encoding="utf-8") as out:
            out.write(f"# Every line in Earth Kings ({len(every)})\n")
            last = ""
            for name, path, text in every:
                if name != last:
                    out.write(f"\n## {name}\n\n")
                    last = name
                out.write(f"- `{path}`: {text}\n")
        print(f"{len(every)} lines written to {sys.argv[2]}")
        return 0
    found = 0
    for name, path, text in every:
        if name == "credits.json":  # names and licences, not lines
            continue
        for tic, pattern in TICS.items():
            if re.search(pattern, text):
                found += 1
                print(f"{name} {path}: {tic}: {text[:100]}")
    print(f"{len(every)} lines, {found} tics")
    return 0


if __name__ == "__main__":
    sys.exit(main())
